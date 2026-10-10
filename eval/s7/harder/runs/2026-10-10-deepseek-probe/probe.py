#!/usr/bin/env python3
"""Check that ollama.com reads a long prompt to `deepseek-v4.1-flash` whole,
through the scored tier's driver (`deepseek.py`, `post`).

The prompt puts a codeword first, then the three MVP documents a Firth author
is given (`docs/getting-started.md`, `docs/firth-agent-guide.md`,
`examples/programs/README.md`) twice, and asks for the codeword last. It holds
no task. A server that cut the prompt to fit a shorter context would drop the
start, and the reply would not be the codeword. Prints the prompt's length in
characters, the reply, `done_reason` and `prompt_eval_count`, and exits 1 unless
the reply is the codeword, complete, from `deepseek-v4.1-flash`:

    python3 probe.py > probe.out
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
HARDER = HERE.parents[1]
ROOT = HARDER.parents[2]
sys.path.insert(0, str(HARDER))

import deepseek  # noqa: E402

DOCS = ["docs/getting-started.md", "docs/firth-agent-guide.md", "examples/programs/README.md"]


def main() -> int:
    docs = "".join((ROOT / p).read_text() for p in DOCS) * 2
    text = ("The codeword is HELIOTROPE-47. Remember it.\n\n" + docs
            + "\n\nWhat was the codeword given at the very start of this message? Reply with the codeword only.")
    print(f"prompt characters\t{len(text)}")
    try:
        status, reply = deepseek.post({"model": deepseek.MODEL,
                                       "messages": [{"role": "user", "content": text}], "stream": False})
    except OSError as e:
        print(f"probe failed: no reply ({e!r})", file=sys.stderr)
        return 1
    print(f"HTTP status\t{status}")
    try:
        r = json.loads(reply)
        content = r["message"]["content"]
    except (ValueError, KeyError, TypeError, AttributeError) as e:
        print(f"probe failed: not a chat reply ({e!r}): {reply[:300]}", file=sys.stderr)
        return 1
    print(f"model\t{r.get('model')}")
    print(f"reply\t{content}")
    print(f"done_reason\t{r.get('done_reason')}")
    print(f"prompt_eval_count\t{r.get('prompt_eval_count')}")
    if (status != 200 or r.get("model") != deepseek.MODEL or r.get("done") is not True
            or r.get("done_reason") != "stop"
            or not isinstance(content, str) or content.strip() != "HELIOTROPE-47"):
        print("probe failed: the prompt was not read whole", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
