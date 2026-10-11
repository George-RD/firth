#!/usr/bin/env python3
"""The health probe run before each DeepSeek sample (coordinator's decision of
11 October 2026, during the run). It is not a sample and carries no author
context: one tiny chat request to the scored model, with a fixed prompt.
Appends one line to probes.log: time, HTTP status, done_reason and the start of
the reply. Exit 0 when the API answered 200 with a complete reply."""
import json, sys, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent))
import deepseek  # noqa: E402

body = {"model": deepseek.MODEL, "stream": False,
        "messages": [{"role": "user", "content": "Reply with the single word: ok"}]}
status, text = deepseek.post(body)
try:
    reply = json.loads(text)
    done, content = reply.get("done_reason"), reply.get("message", {}).get("content", "")
except ValueError:
    done, content = None, text
ok = status == 200 and done == "stop"
line = {"at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "status": status,
        "done_reason": done, "reply": content[:80], "ok": ok, "before": sys.argv[1] if len(sys.argv) > 1 else None}
with open(HERE / "probes.log", "a") as f:
    f.write(json.dumps(line) + "\n")
print(json.dumps(line))
sys.exit(0 if ok else 1)
