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
  scored or shown to the scorer);
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

`python3 deepseek.py --self-test` runs the driver against planted replies, with no
network.
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
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return r.status, r.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(errors="replace")


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
    body = {"model": MODEL, "messages": messages(prompt, d, rnd), "stream": False}
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
