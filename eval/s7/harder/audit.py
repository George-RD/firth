#!/usr/bin/env python3
"""Audit a harder-tier author's transcript: `audit_subagent.py`, with this
tier's feedback.

The audit is the MVP tier's, call for call: the author may read its prompt
and its `repair-<n>.md`, write its `answer-<n>.md`, and hand back, and every
kept file must be what it wrote or was shown. The one difference is the
feedback it rebuilds to compare with each kept `repair-<n>.md`: this tier's
(`tier.repair` over `--set`), not the MVP tier's.

    audit.py LOG.jsonl --set calibration --prompt P --dir D --rounds R --lang L > transcript.json
"""
from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
import audit_subagent  # noqa: E402
import tier  # noqa: E402


def main() -> int:
    args = sys.argv[1:]
    if "--set" not in args or args.index("--set") + 1 >= len(args):
        raise SystemExit("audit.py needs --set NAME")
    i = args.index("--set")
    name = args[i + 1]
    if name not in tier.SETS:
        raise SystemExit(f"unknown set {name!r}; one of {sorted(tier.SETS)}")
    del args[i:i + 2]
    if any(a in args for a in ("--check-cmd", "--shell-forms", "--run14-forms", "--hook-log")):
        raise SystemExit("this tier's authors have no tools beyond reading and writing their own files")
    tasks = list(tier.SETS[name])
    # audit_subagent rebuilds feedback with the MVP tier's repair; this tier's
    # authors were shown tier.repair over this set.
    audit_subagent.repair = lambda sols, res, lang, _tasks: tier.repair(sols, res, lang, tasks)
    sys.argv = [sys.argv[0], *args]
    return audit_subagent.main()


if __name__ == "__main__":
    raise SystemExit(main())
