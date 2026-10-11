#!/usr/bin/env python3
"""Ask DeepSeek v4.1 Flash for one round of a harder-tier answer, through
ollama.com's chat API (`todo.s7-harder-task-tier`: DeepSeek joins the scored
tier only, billed to the connected ollama.com key).

A Sonnet author is a sub-agent that reads its prompt and writes
`answer-<n>.md`. DeepSeek has no tools, so this driver is its hands: it sends
the same prompt text as the user turn and keeps the reply's text, untouched, as
`answer-<n>.md`. In a feedback round the conversation so far is sent again
(prompt, answer 1, ...) with `repair-<n-1>.md` as the next user turn, the same
text a Sonnet author reads.

    python3 deepseek.py PROMPT DIR ROUND

writes into DIR (which must not already hold `request-ROUND.json`):

- `answer-ROUND.md`, the reply's `message.content`, byte for byte, or
  `cut-ROUND.md` instead when the reply was cut off at the length limit;
- `response-ROUND.json`, the whole API reply, `thinking` included (kept, never
  scored or shown to the scorer). The reply is streamed, and its chunks are
  joined into the one reply a non-streamed request gives (`join`);
- `request-ROUND.json`, what was sent (the proxy adds the key; no key is ever
  in it), and the outcome: the HTTP status or error, the verdict (`result`:
  `answer`, `cut-off` or `void`) and why.

A round is asked exactly once. `request-ROUND.json` is created before the
request is sent, and a round whose request file exists is refused, whatever
happened to it. Only a complete reply is kept as an answer. A reply cut off
at the length limit (`done_reason` `length`) writes no answer and exits 2:
the model answered, and the round is scored as a failed answer; its text is
kept as `cut-ROUND.md` and resent as the model's turn in a feedback round.
Anything else that is not a complete answer exits 3 and voids the sample: a
request that failed (a network error, which may come after the server
answered, a body cut short or not UTF-8, or any HTTP status other than 200), a
reply that is not a chat reply (not JSON, or no string `message.content`), a
message whose role is not `assistant`, text that cannot be written as UTF-8
(a lone surrogate), another model's name, `done` not `true`, or a
`done_reason` other than `stop` or `length`. Either way the round records what came back and is
never asked again, so no answer is ever asked for twice.

`python3 deepseek.py --self-test` runs the driver against planted replies, and
`join` against planted streams, with no network.
"""
from __future__ import annotations

import http.client
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

URL = "https://ollama.com/api/chat"
MODEL = "deepseek-v4.1-flash"
TIMEOUT = 3600


def post(body: dict) -> tuple[int, str]:
    """Send one request. A streamed reply (`"stream": true`) is read line by
    line and joined (`join`) into the one reply a non-streamed request would
    give. The reply is streamed because a request that sends no response
    bytes for about 30 seconds is cut with HTTP 502 "upstream request failed"
    while the model is still thinking (measured on 11 October 2026, during
    the scored run: `runs/2026-10-11-scored/probes.log`); streamed chunks keep
    the connection busy."""
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            if not body.get("stream"):
                return r.status, r.read().decode()
            return r.status, join([line.decode() for line in r])
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(errors="replace")


def join(lines: list[str]) -> str:
    """The streamed chunks (one JSON object per line) joined into one reply:
    `message.content` and `message.thinking` are the chunks' text in order,
    and every other field is the last chunk's (`done`, `done_reason`, the
    token counts). Each chunk must be a chat chunk from the same model and
    role, only the last may be `done` (each other one's `done` is `false`),
    and at least one must carry `content`. Anything else (a line that is not
    a JSON object, an `error` chunk, a chunk after the done one, mixed models
    or roles, no chunks) is returned as the raw text, which `run` cannot read
    as one chat reply and so voids; a stream that ends before its done chunk
    joins to a reply whose `done` is not `true`, which `run` voids too."""
    raw = "".join(lines)
    chunks = []
    for line in lines:
        if not line.strip():
            continue
        try:
            chunk = json.loads(line)
        except ValueError:
            return raw
        if not isinstance(chunk, dict) or "error" in chunk or not isinstance(chunk.get("message"), dict):
            return raw
        chunks.append(chunk)
    if not chunks or any(c.get("done", False) is not False for c in chunks[:-1]):
        return raw
    # As in a non-streamed reply, where `run` reads `message.content`.
    if not any("content" in c["message"] for c in chunks):
        return raw
    first = chunks[0]
    if any(c.get("model") != first.get("model") or c["message"].get("role") != first["message"].get("role")
           for c in chunks):
        return raw
    parts = {"content": [], "thinking": []}
    for c in chunks:
        for k in parts:
            if k not in c["message"]:
                continue
            v = c["message"][k]
            if not isinstance(v, str):
                return raw
            parts[k].append(v)
    reply = dict(chunks[-1])
    reply["message"] = {"role": first["message"].get("role"), "content": "".join(parts["content"]),
                        "thinking": "".join(parts["thinking"])}
    return json.dumps(reply)


def text(path: Path) -> str:
    """A file's text byte for byte: no newline translation."""
    with path.open(encoding="utf-8", newline="") as f:
        return f.read()


def write(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8", newline="")


def messages(prompt: Path, d: Path, rnd: int) -> list[dict]:
    """The conversation so far: the prompt, then each earlier round's reply
    (`answer-<k>.md`, or `cut-<k>.md` when that reply was cut off) and its
    feedback (`repair-<k>.md`)."""
    out = [{"role": "user", "content": text(prompt)}]
    for k in range(1, rnd):
        prior = d / f"answer-{k}.md"
        if not prior.exists():
            prior = d / f"cut-{k}.md"
        out.append({"role": "assistant", "content": text(prior)})
        out.append({"role": "user", "content": text(d / f"repair-{k}.md")})
    return out


def run(prompt: Path, d: Path, rnd: int, send=post) -> int:
    body = {"model": MODEL, "messages": messages(prompt, d, rnd), "stream": True}
    record = {"body": body}
    try:
        # Created before the request is sent: a round is asked once, whatever happened to it.
        with open(d / f"request-{rnd}.json", "x") as f:
            f.write(json.dumps(record, indent=1))
    except FileExistsError:
        raise SystemExit(f"{d}/request-{rnd}.json already exists; a round is asked once")

    def done(result: str, why: str, code: int) -> int:
        # The round's verdict is recorded with what was sent: "answer",
        # "cut-off" or "void", and why.
        record["outcome"]["result"], record["outcome"]["why"] = result, why
        write(d / f"request-{rnd}.json", json.dumps(record, indent=1))
        if code:
            print(f"{why}; {'the round is void' if result == 'void' else 'no answer kept'}",
                  file=sys.stderr)
        return code

    try:
        status, reply = send(body)
    except (OSError, ValueError, http.client.HTTPException) as e:  # the server may have answered: never sent again
        record["outcome"] = {"error": repr(e)}
        return done("void", f"the request failed ({e!r})", 3)
    record["outcome"] = {"status": status}
    write(d / f"response-{rnd}.json", reply)
    if status != 200:
        return done("void", f"HTTP status {status}", 3)
    try:
        r = json.loads(reply)
        message = r["message"]
        content, role = message["content"], message.get("role")
        model, finished, reason = r.get("model"), r.get("done"), r.get("done_reason")
    except (ValueError, KeyError, TypeError, AttributeError) as e:
        return done("void", f"not a chat reply ({e!r})", 3)
    if model != MODEL or finished is not True or role != "assistant" or not isinstance(content, str):
        return done("void", f"not a complete answer from {MODEL}: model {model!r}, "
                            f"done {finished!r}, role {role!r}", 3)
    try:
        content.encode("utf-8")
    except UnicodeEncodeError as e:  # a lone surrogate from a JSON escape cannot be kept byte for byte
        return done("void", f"the reply's text is not UTF-8 ({e!r})", 3)
    if reason == "length":
        # Scored as a failed answer; the cut text is kept, apart from any
        # answer, so a feedback round can resend it as the model's turn.
        write(d / f"cut-{rnd}.md", content)
        return done("cut-off", "the reply was cut off at the length limit", 2)
    if reason != "stop":
        return done("void", f"done_reason {reason!r}", 3)
    write(d / f"answer-{rnd}.md", content)
    return done("answer", "a complete answer", 0)


def join_problems(joiner) -> list[str]:
    """What `joiner` gets wrong on planted streams. `join` gives none; each
    mutant in the self-test gives at least one."""
    def chunk(content="", thinking=None, done=False, model=MODEL, role="assistant", **last):
        m = {"role": role, "content": content}
        if thinking is not None:
            m["thinking"] = thinking
        return json.dumps({"model": model, "message": m, "done": done, **last}) + "\n"
    end = dict(done=True, done_reason="stop", prompt_eval_count=22632, eval_count=9)
    def joined(lines):
        try:
            return json.loads(joiner(lines))
        except ValueError:
            return None
    def reply_of(lines):
        """`run`'s reading of the joined text: (content, role, model, done,
        done_reason), or None where `run` voids the round as not a chat reply."""
        r = joined(lines)
        try:
            m = r["message"]
            return m["content"], m.get("role"), r.get("model"), r.get("done"), r.get("done_reason")
        except (KeyError, TypeError):
            return None
    out = []
    whole = [chunk(thinking="Let me "), chunk(thinking="think."), chunk("```firth\r\n"),
             chunk("main\n```\n"), chunk(**end)]
    r = joined(whole)
    if reply_of(whole) != ("```firth\r\nmain\n```\n", "assistant", MODEL, True, "stop"):
        out.append(f"a whole stream joins to {reply_of(whole)!r}")
    if not r or r.get("prompt_eval_count") != 22632 or r["message"].get("thinking") != "Let me think.":
        out.append("the joined reply loses the last chunk's counts or the thinking")
    # Field by field: a non-streamed reply and the stream of the same reply
    # (as the API sends it: text in the chunks, counts and timings in the
    # done one) give the same record.
    timings = dict(created_at="2026-10-11T05:00:00Z", total_duration=5, load_duration=1,
                   prompt_eval_duration=2, eval_duration=3)
    reply = {"model": MODEL, "message": {"role": "assistant", "content": "```firth\r\nmain\n```\n",
                                         "thinking": "Let me think."}, **end, **timings}
    stream = [json.loads(line) for line in whole[:-1]] + [
        {"model": MODEL, "message": {"role": "assistant", "content": ""}, **end, **timings}]
    for c in stream[:-1]:
        c["created_at"] = timings["created_at"]
    if joined([json.dumps(c) + "\n" for c in stream]) != reply:
        out.append("the joined stream differs from the non-streamed reply")
    if reply_of([chunk("ma"), chunk("in", done=True, done_reason="length")]) != (
            "main", "assistant", MODEL, True, "length"):
        out.append("a stream cut off at the length limit does not join to a length reply")
    # Each of these must not join to a complete answer from the scored model.
    for why, lines in (("a stream that ends before its done chunk", whole[:-1]),
                       ("an error chunk mid-stream", whole[:2] + ['{"error": "upstream"}\n'] + whole[2:]),
                       ("a line that is not JSON", whole[:2] + ["data: x\n"] + whole[2:]),
                       ("a chunk after the done one", whole + [chunk("more")]),
                       ("a chunk from another model", whole[:2] + [chunk("x", model="deepseek-v4-pro")] + whole[2:]),
                       ("a chunk in another role", whole[:2] + [chunk("x", role="user")] + whole[2:]),
                       ("a chunk whose content is not text", whole[:2] + [chunk(None)] + whole[2:]),
                       ("a chunk before the last whose done is not false",
                        whole[:2] + [chunk("x", done=1)] + whole[2:]),
                       ("a stream with no content field", [
                           json.dumps({"model": MODEL, "message": {"role": "assistant", "thinking": "t"},
                                       "done": d, **(end if d else {})}) + "\n" for d in (False, True)]),
                       ("no chunks", [])):
        got = reply_of(lines)
        if got is not None and got[2:] == (MODEL, True, "stop") and got[1] == "assistant":
            out.append(f"{why} joins to a complete answer")
    return out


def asks_streamed(runner) -> bool:
    """Whether `runner` (`run`, or a mutant of it) asks for a streamed reply."""
    import tempfile
    sent = []
    def send(body):
        sent.append(body)
        return 500, ""
    with tempfile.TemporaryDirectory() as t:
        p = Path(t) / "prompt.md"
        p.write_text("Write `main`.")
        runner(p, Path(t), 1, send)
    return len(sent) == 1 and sent[0].get("stream") is True


def self_test() -> None:
    import tempfile
    def reply(content, reason="stop", model=MODEL, done=True, role="assistant"):
        return json.dumps({"model": model, "message": {"role": role, "content": content,
                                                        "thinking": "t"},
                           "done": done, "done_reason": reason, "eval_count": 3})
    def scripted(*outcomes):
        sent = []
        def send(body):
            sent.append(body)
            o = outcomes[len(sent) - 1]
            if isinstance(o, Exception):
                raise o
            return o
        return send, sent
    def refused(p, d, rnd):
        send, sent = scripted((200, reply("again")))
        try:
            run(p, d, rnd, send)
        except SystemExit:
            return sent == []
        return False
    with tempfile.TemporaryDirectory() as t:
        d = Path(t)
        p = d / "prompt.md"
        p.write_text("Write `main`.")
        # A complete reply is kept byte for byte; thinking is not in the answer.
        send, sent = scripted((200, reply("```firth\r\nmain\n```\n")))
        assert run(p, d, 1, send) == 0
        assert (d / "answer-1.md").read_bytes() == b"```firth\r\nmain\n```\n"
        assert sent[0]["messages"] == [{"role": "user", "content": "Write `main`."}]
        # Streamed, so a long think is not cut at the ~30 s idle limit.
        assert sent[0]["stream"] is True
        assert json.loads((d / "request-1.json").read_text())["outcome"] == {
            "status": 200, "result": "answer", "why": "a complete answer"}
        # A round is asked once.
        assert refused(p, d, 1)
        # Round 2 resends the conversation with the repair file as the next turn.
        (d / "repair-1.md").write_text("Feedback round 1 of 1: fix it.")
        send, sent = scripted((200, reply("fixed")))
        assert run(p, d, 2, send) == 0 and len(sent) == 1
        assert [m["role"] for m in sent[0]["messages"]] == ["user", "assistant", "user"]
        assert sent[0]["messages"][2]["content"] == "Feedback round 1 of 1: fix it."
        # The earlier answer is resent as it came, carriage return included.
        assert sent[0]["messages"][1]["content"] == "```firth\r\nmain\n```\n"
    with tempfile.TemporaryDirectory() as t:
        d = Path(t)
        p = d / "prompt.md"
        p.write_text("Write `main`.")
        # A cut-off round keeps its text apart from any answer, and the
        # feedback round resends it as the model's turn.
        send, sent = scripted((200, reply("### task: a\n```firth\nma", reason="length")))
        assert run(p, d, 1, send) == 2 and not (d / "answer-1.md").exists()
        assert (d / "cut-1.md").read_text() == "### task: a\n```firth\nma"
        (d / "repair-1.md").write_text("Your reply was cut off.")
        send, sent = scripted((200, reply("fixed")))
        assert run(p, d, 2, send) == 0
        assert [m["content"] for m in sent[0]["messages"]] == [
            "Write `main`.", "### task: a\n```firth\nma", "Your reply was cut off."]
    for planted, code in (((200, reply("half an answ", reason="length")), 2),   # a cut-off reply
                          ((200, reply("x", model="deepseek-v4-pro:0813")), 3),  # another model
                          ((200, reply("x", reason="load")), 3),                 # not stop or length
                          ((200, reply("x", done=False)), 3),                    # not done
                          ((200, reply("x", done=1)), 3),                        # done, not true
                          ((200, "<html>bad gateway</html>"), 3),                # not JSON
                          ((200, json.dumps({"model": MODEL, "done": True,       # no message
                                             "done_reason": "stop"})), 3),
                          ((200, reply(None)), 3),                               # null content
                          ((200, reply("x", role="user")), 3),                   # not the model's turn
                          ((200, reply("a\ud800b")), 3),                         # a lone surrogate
                          ((200, reply("a\ud800b", reason="length")), 3),        # also when cut off
                          (UnicodeDecodeError("utf-8", b"\xff", 0, 1, "bad"), 3),  # body not UTF-8
                          ((200, "[]"), 3),                                      # not an object
                          (OSError("reset"), 3),                                 # no reply seen
                          (http.client.IncompleteRead(b"{\"mo"), 3),             # body cut short
                          ((502, "bad gateway"), 3),                             # a 5xx
                          ((400, "bad request"), 3)):                            # a 4xx
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            p = d / "prompt.md"
            p.write_text("Write `main`.")
            send, sent = scripted(planted, (200, reply("never")))
            # Planted: none of these is kept as an answer or sent again, and
            # the void round cannot be asked again.
            assert run(p, d, 1, send) == code and len(sent) == 1, planted
            assert not (d / "answer-1.md").exists(), planted
            outcome = json.loads((d / "request-1.json").read_text())["outcome"]
            assert outcome["result"] == ("cut-off" if code == 2 else "void"), planted
            assert (d / "cut-1.md").exists() == (code == 2), planted
            assert refused(p, d, 1), planted
    assert join_problems(join) == [], join_problems(join)
    # Planted: joiners that drop the last chunk, ignore its done_reason, drop
    # the thinking, drop the prompt token count (the pre-reg's prompt check
    # reads it), keep only the fields `run` reads, or keep the chunks after a
    # done one are each caught.
    def drops_last(lines):
        return join(lines[:-1])
    def says_stop(lines):
        r = json.loads(join(lines))
        return json.dumps({**r, "done_reason": "stop"}) if isinstance(r, dict) else join(lines)
    def no_thinking(lines):
        r = json.loads(join(lines))
        if isinstance(r, dict) and isinstance(r.get("message"), dict):
            r["message"].pop("thinking", None)
        return json.dumps(r)
    def drops_counts(lines):
        r = json.loads(join(lines))
        if isinstance(r, dict):
            r.pop("prompt_eval_count", None)
        return json.dumps(r)
    def scored_fields_only(lines):
        r = json.loads(join(lines))
        if isinstance(r, dict):
            r = {k: v for k, v in r.items() if k in ("model", "message", "done", "done_reason",
                                                     "prompt_eval_count", "eval_count")}
        return json.dumps(r)
    def keeps_after_done(lines):
        cut = next((i for i, l in enumerate(lines) if '"done": true' in l), len(lines) - 1)
        return join(lines[:cut + 1])
    for mutant in (drops_last, says_stop, no_thinking, drops_counts, scored_fields_only,
                   keeps_after_done):
        assert join_problems(mutant) != [], mutant.__name__
    # Planted: this file's own code with one check undone. Each needle is
    # split so that only the line it names matches.
    source = Path(__file__).read_text(encoding="utf-8")
    def mutant(old, new):
        assert source.count(old) == 1, old
        m = {"__name__": "deepseek_mutant"}
        exec(compile(source.replace(old, new), __file__, "exec"), m)
        return m
    # `join` that lets a non-final chunk's `done` be anything but `true`, or
    # joins a stream with no `content` field to an empty answer, is caught.
    assert join_problems(mutant('c.get("done", False) ' + "is not False", 'c.get("done") ' + "is True")["join"])
    assert join_problems(mutant('if not any("content" in c["message"] ' + "for c in chunks):",
                                'if not any("content" in c["message"] ' + "for c in []):")["join"])
    # Streamed, so a long think is not cut at the ~30 s idle limit; `run` with
    # the request reverted to non-streamed is caught.
    assert asks_streamed(run)
    assert not asks_streamed(mutant('"stream": ' + "True}", '"stream": ' + "False}")["run"])
    print("self-test ok")


def main(argv: list[str]) -> int:
    if argv == ["--self-test"]:
        self_test()
        return 0
    if len(argv) != 3:
        raise SystemExit(__doc__)
    return run(Path(argv[0]), Path(argv[1]), int(argv[2]))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
