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

- `answer-ROUND.md`, the reply's `message.content`, byte for byte;
- `response-ROUND.json`, the whole API reply, `thinking` included (kept, never
  scored or shown to the scorer);
- `request-ROUND.json`, what was sent (the proxy adds the key; no key is ever
  in it), and the request's outcome.

A round is asked exactly once. `request-ROUND.json` is created before the
request is sent, and a round whose request file exists is refused, whatever
happened to it. Only a complete reply is kept as an answer. A reply cut off
at the length limit (`done_reason` `length`) writes no answer and exits 2:
the model answered, and the round is scored as a failed answer. Anything else
that is not a complete answer exits 3 and voids the sample: a request that
failed (a network error, which may come after the server answered, or any
HTTP status other than 200), a reply that is not a chat reply (not JSON, or
no string `message.content`), another model's name, or a `done_reason` other
than `stop` or `length`. Either way the round records what came back and is
never asked again, so no answer is ever asked for twice.

`python3 deepseek.py --self-test` runs the driver against planted replies, with no
network.
"""
from __future__ import annotations

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


def messages(prompt: Path, d: Path, rnd: int) -> list[dict]:
    def text(path: Path) -> str:  # byte for byte: no newline translation
        with path.open(encoding="utf-8", newline="") as f:
            return f.read()
    out = [{"role": "user", "content": text(prompt)}]
    for k in range(1, rnd):
        out.append({"role": "assistant", "content": text(d / f"answer-{k}.md")})
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
    try:
        status, reply = send(body)
    except OSError as e:  # the server may have answered: never sent again
        record["outcome"] = {"error": repr(e)}
        status, reply = None, None
    else:
        record["outcome"] = {"status": status}
    (d / f"request-{rnd}.json").write_text(json.dumps(record, indent=1))
    if reply is not None:
        (d / f"response-{rnd}.json").write_text(reply)
    if status != 200:
        print(f"request failed ({record['outcome']}); the round is void", file=sys.stderr)
        return 3
    try:
        r = json.loads(reply)
        content = r["message"]["content"]
        model, done, reason = r.get("model"), r.get("done"), r.get("done_reason")
    except (ValueError, KeyError, TypeError, AttributeError) as e:
        print(f"not a chat reply ({e!r}); the round is void", file=sys.stderr)
        return 3
    if model != MODEL or done is not True or not isinstance(content, str):
        print(f"not a complete answer from {MODEL}: model {model!r}, done {done!r}; "
              "the round is void", file=sys.stderr)
        return 3
    if reason == "length":
        print("the reply was cut off at the length limit; no answer kept", file=sys.stderr)
        return 2
    if reason != "stop":
        print(f"done_reason {reason!r}; the round is void", file=sys.stderr)
        return 3
    (d / f"answer-{rnd}.md").write_text(content, encoding="utf-8", newline="")
    return 0


def self_test() -> None:
    import tempfile
    def reply(content, reason="stop", model=MODEL, done=True):
        return json.dumps({"model": model, "message": {"role": "assistant", "content": content,
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
        assert json.loads((d / "request-1.json").read_text())["outcome"] == {"status": 200}
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
    for planted, code in (((200, reply("half an answ", reason="length")), 2),   # a cut-off reply
                          ((200, reply("x", model="deepseek-v4-pro:0813")), 3),  # another model
                          ((200, reply("x", reason="load")), 3),                 # not stop or length
                          ((200, reply("x", done=False)), 3),                    # not done
                          ((200, reply("x", done=1)), 3),                        # done, not true
                          ((200, "<html>bad gateway</html>"), 3),                # not JSON
                          ((200, json.dumps({"model": MODEL, "done": True,       # no message
                                             "done_reason": "stop"})), 3),
                          ((200, reply(None)), 3),                               # null content
                          ((200, "[]"), 3),                                      # not an object
                          (OSError("reset"), 3),                                 # no reply seen
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
            assert "outcome" in json.loads((d / "request-1.json").read_text()), planted
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
