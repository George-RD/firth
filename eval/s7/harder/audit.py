#!/usr/bin/env python3
"""Audit a harder-tier author's transcript: `audit_subagent.py`, with this
tier's feedback.

The audit is the MVP tier's, call for call: the author may read its prompt
and its `repair-<n>.md`, write its `answer-<n>.md`, and hand back, and every
kept file must be what it wrote or was shown. Two things it rebuilds are this
tier's, not the MVP tier's: the feedback compared with each kept
`repair-<n>.md` (`tier.repair` over `--set`), and the solutions compared with
each kept `solutions-<n>.json` (`tier.take`: a later round takes only the
tasks the earlier round's feedback listed, where the MVP audit takes every
task in the answer).

    audit.py LOG.jsonl --set calibration --prompt P --dir D --rounds R --lang L > transcript.json
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
import audit_subagent  # noqa: E402
import tier  # noqa: E402


def solutions_mismatch(kept: Path, tasks: list) -> list[str]:
    """Each kept solutions-N.json that is not what `tier.take` builds from
    answer-N.md and, after round 1, the kept solutions and results of round
    N-1. The walk is `audit_subagent.solutions_mismatch`'s: a missing file is
    listed and the walk goes on."""
    bad: list[str] = []
    prev: dict | None = None
    last = max(audit_subagent.numbered(kept, "answer", "md") + audit_subagent.numbered(kept, "solutions", "json"),
               default=0)
    for n in range(1, last + 1):
        sol, answer = kept / f"solutions-{n}.json", kept / f"answer-{n}.md"
        after = None
        if n > 1:
            res = kept / f"results-{n - 1}.json"
            if not res.is_file():
                bad.append(f"{res}: missing, so round {n}'s feedback, and what it may take, is not known")
            else:
                after = (prev or {}, json.loads(res.read_text()))
        if not answer.is_file():
            bad.append(f"{answer}: missing")
            prev = json.loads(sol.read_text()) if sol.is_file() else prev
            continue
        if n > 1 and after is None:
            prev = json.loads(sol.read_text()) if sol.is_file() else prev
            continue
        want, _ = tier.take(answer.read_text(), tasks, after)
        if sol.is_file():
            got = json.loads(sol.read_text())
            if got != want:
                diff = sorted(k for k in set(got) | set(want) if got.get(k) != want.get(k))
                bad.append(f"{sol}: not the answers taken by this tier's rule (tasks {', '.join(diff)[:200]})")
            prev = got
        else:
            bad.append(f"{sol}: missing, so what was scored is not kept")
            prev = want
    return bad


def main() -> int:
    args = sys.argv[1:]
    if "--set" not in args or args.index("--set") + 1 >= len(args):
        raise SystemExit("audit.py needs --set NAME")
    i = args.index("--set")
    name = args[i + 1]
    if name not in tier.SETS:
        raise SystemExit(f"unknown set {name!r}; one of {sorted(tier.SETS)}")
    del args[i:i + 2]
    # Only these options pass through. Any other, however spelt (`--check-cmd=X`,
    # an abbreviation argparse would expand), could turn on an allowance this
    # tier's authors do not have, so it is refused.
    allowed = ("--prompt", "--dir", "--kept", "--rounds", "--lang")
    for a in args:
        if a.startswith("-") and a.split("=", 1)[0] not in allowed:
            raise SystemExit(f"{a}: this tier's audit takes only {', '.join(allowed)}; its authors "
                             "have no tools beyond reading and writing their own files")
    tasks = list(tier.SETS[name])
    # audit_subagent rebuilds feedback with the MVP tier's repair; this tier's
    # authors were shown tier.repair over this set.
    audit_subagent.repair = lambda sols, res, lang, _tasks: tier.repair(sols, res, lang, tasks)
    # and builds each round's solutions by the MVP rule; this tier's are built by tier.take.
    audit_subagent.solutions_mismatch = lambda kept: solutions_mismatch(kept, tasks)
    sys.argv = [sys.argv[0], *args]
    return audit_subagent.main()


if __name__ == "__main__":
    raise SystemExit(main())
