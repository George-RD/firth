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

    deepseek.py PROMPT DIR ROUND

writes into DIR (which must not already hold `answer-ROUND.md`):

- `answer-ROUND.md`, the reply's `message.content`, byte for byte;
- `response-ROUND.json`, the whole API reply, `thinking` included (kept, never
  scored or shown to the scorer);
- `request-ROUND.json`, what was sent (the proxy adds the key; no key is ever
  in it), and each attempt's outcome.

A reply that is not a complete answer is never kept as one. If `done_reason`
is not `stop` (for example `length`, a cut-off), the round writes no answer,
records the reply, and exits 2: the sample is void as the pre-registration
says. Only a request that failed before any reply (a network error or an HTTP
5xx) is sent again, at most `TRIES` times in all, and every attempt is
recorded, so no complete answer is ever asked for twice.

`deepseek.py --self-test` runs the driver against planted replies, with no
network.
"""
from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

URL = "https://ollama.com/api/chat"
MODEL = "deepseek-v4.1-flash"
TRIES = 3
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
    out = [{"role": "user", "content": prompt.read_text()}]
    for k in range(1, rnd):
        out.append({"role": "assistant", "content": (d / f"answer-{k}.md").read_text()})
        out.append({"role": "user", "content": (d / f"repair-{k}.md").read_text()})
    return out


def run(prompt: Path, d: Path, rnd: int, send=post, sleep=time.sleep) -> int:
    if (d / f"answer-{rnd}.md").exists():
        raise SystemExit(f"{d}/answer-{rnd}.md already exists; a round is asked once")
    body = {"model": MODEL, "messages": messages(prompt, d, rnd), "stream": False}
    attempts = []
    reply = None
    for i in range(TRIES):
        try:
            status, text = send(body)
        except OSError as e:  # no reply at all: safe to send again
            attempts.append({"error": repr(e)})
            sleep(2 ** (i + 1))
            continue
        attempts.append({"status": status})
        if status >= 500:
            sleep(2 ** (i + 1))
            continue
        reply = text
        break
    (d / f"request-{rnd}.json").write_text(json.dumps({"body": body, "attempts": attempts}, indent=1))
    if reply is None:
        print(f"no reply after {len(attempts)} attempts", file=sys.stderr)
        return 3
    (d / f"response-{rnd}.json").write_text(reply)
    if attempts[-1]["status"] != 200:
        print(f"HTTP {attempts[-1]['status']}: {reply[:300]}", file=sys.stderr)
        return 3
    r = json.loads(reply)
    if r.get("model") != MODEL or not r.get("done") or r.get("done_reason") != "stop":
        print(f"not a complete answer: model {r.get('model')!r}, done {r.get('done')!r}, "
              f"done_reason {r.get('done_reason')!r}; no answer kept", file=sys.stderr)
        return 2
    (d / f"answer-{rnd}.md").write_text(r["message"]["content"])
    return 0


def self_test() -> None:
    import tempfile
    def reply(content, reason="stop", model=MODEL):
        return json.dumps({"model": model, "message": {"role": "assistant", "content": content,
                                                        "thinking": "t"},
                           "done": True, "done_reason": reason, "eval_count": 3})
    def scripted(*outcomes):
        sent = []
        def send(body):
            sent.append(body)
            o = outcomes[len(sent) - 1]
            if isinstance(o, Exception):
                raise o
            return o
        return send, sent
    with tempfile.TemporaryDirectory() as t:
        d = Path(t)
        p = d / "prompt.md"
        p.write_text("Write `main`.")
        # A complete reply is kept byte for byte; thinking is not in the answer.
        send, sent = scripted((200, reply("```firth\nmain\n```\n")))
        assert run(p, d, 1, send, lambda s: None) == 0
        assert (d / "answer-1.md").read_text() == "```firth\nmain\n```\n"
        assert sent[0]["messages"] == [{"role": "user", "content": "Write `main`."}]
        # A round is asked once.
        try:
            run(p, d, 1, send, lambda s: None)
            raise AssertionError("asked a round twice")
        except SystemExit:
            pass
        # Round 2 resends the conversation with the repair file as the next turn.
        (d / "repair-1.md").write_text("Feedback round 1 of 1: fix it.")
        send, sent = scripted(OSError("reset"), (502, "bad gateway"), (200, reply("fixed")))
        assert run(p, d, 2, send, lambda s: None) == 0
        assert [m["role"] for m in sent[2]["messages"]] == ["user", "assistant", "user"]
        assert sent[2]["messages"][2]["content"] == "Feedback round 1 of 1: fix it."
        req = json.loads((d / "request-2.json").read_text())
        assert [list(a) for a in req["attempts"]] == [["error"], ["status"], ["status"]], req
        # Planted: a cut-off reply (done_reason "length") is not kept as an answer.
        (d / "repair-2.md").write_text("again")
        send, _ = scripted((200, reply("half an answ", reason="length")))
        assert run(p, d, 3, send, lambda s: None) == 2
        assert not (d / "answer-3.md").exists() and (d / "response-3.json").exists()
        # Planted: another model's reply is not kept either.
        send, _ = scripted((200, reply("x", model="deepseek-v4-pro:0813")))
        assert run(p, d, 3, send, lambda s: None) == 2 and not (d / "answer-3.md").exists()
        # A 4xx is an answer from the server, not a lost request: not resent.
        send, sent = scripted((400, "bad request"), (200, reply("never")))
        assert run(p, d, 3, send, lambda s: None) == 3 and len(sent) == 1
        # Three failed sends end the round with no answer.
        send, sent = scripted(OSError("a"), OSError("b"), OSError("c"))
        assert run(p, d, 3, send, lambda s: None) == 3 and len(sent) == TRIES
        assert not (d / "answer-3.md").exists()
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
