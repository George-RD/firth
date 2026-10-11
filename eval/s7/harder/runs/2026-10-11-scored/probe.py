#!/usr/bin/env python3
"""The health probe run before each DeepSeek sample (coordinator's decision of
11 October 2026, during the run). It is not a sample and carries no author
context: one tiny chat request to the scored model, with a fixed prompt.
Appends one line to probes.log: time, HTTP status, done_reason and the start of
the reply. Exit 0 only when the API answered 200 with a complete chat reply
from the scored model (the checks `deepseek.py` applies: `done` true,
`done_reason` stop, role assistant, string content). A failed request is
logged too, then exits 1.

`python3 probe.py --self-test` checks the verdict against planted replies,
with no network."""
import json, sys, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent))
import deepseek  # noqa: E402

BODY = {"model": deepseek.MODEL, "stream": False,
        "messages": [{"role": "user", "content": "Reply with the single word: ok"}]}


def verdict(status, text) -> tuple[bool, object, str]:
    """(healthy, done_reason, reply text) for one response."""
    try:
        reply = json.loads(text)
        message = reply["message"]
        done, content = reply.get("done_reason"), message.get("content")
        ok = (status == 200 and reply.get("model") == deepseek.MODEL and reply.get("done") is True
              and done == "stop" and message.get("role") == "assistant" and isinstance(content, str))
        return ok, done, content if isinstance(content, str) else repr(content)
    except (ValueError, KeyError, TypeError, AttributeError):
        return False, None, text


def self_test() -> None:
    def r(**k):
        base = {"model": deepseek.MODEL, "done": True, "done_reason": "stop",
                "message": {"role": "assistant", "content": "ok"}}
        base.update(k)
        return json.dumps(base)
    assert verdict(200, r())[0]
    # Planted: each of these must not pass as healthy.
    for status, text in ((200, json.dumps({"done_reason": "stop"})), (200, r(model="other")),
                         (200, r(done=False)), (200, r(done_reason="length")),
                         (200, r(message={"role": "user", "content": "ok"})),
                         (200, r(message={"role": "assistant", "content": None})),
                         (200, r(message="ok")), (200, "[]"), (200, "<html>"), (502, r())):
        assert not verdict(status, text)[0], text
    print("self-test ok")


def main() -> int:
    try:
        status, text = deepseek.post(BODY)
    except Exception as e:  # logged, never raised: a failed probe still leaves its line
        status, text = None, f"{type(e).__name__}: {e}"
    ok, done, content = verdict(status, text)
    line = {"at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "status": status,
            "done_reason": done, "reply": str(content)[:80], "ok": ok,
            "before": sys.argv[1] if len(sys.argv) > 1 else None}
    with open(HERE / "probes.log", "a") as f:
        f.write(json.dumps(line) + "\n")
    print(json.dumps(line))
    return 0 if ok else 1


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        sys.exit(0)
    sys.exit(main())
