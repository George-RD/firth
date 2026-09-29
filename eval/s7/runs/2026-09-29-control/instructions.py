#!/usr/bin/env python3
"""Recover what each run 10 author was told, from its raw log.

Usage, from eval/s7:
  python3 runs/2026-09-29-control/instructions.py LOGDIR   (writes instructions.json)
  python3 runs/2026-09-29-control/instructions.py --check  (reads instructions.json)
  python3 runs/2026-09-29-control/instructions.py --self-test

LOGDIR holds the raw author logs named <agent id>.output; driver/ids.txt maps
arm and sample to agent id. Every text message an author received is kept
verbatim. The eval session's own messages (the dispatch and the two feedback
rounds) are then reduced to templates by replacing the arm's worktree, arm
commit and sample number with placeholders; --check fails unless both arms
received the same templates, in the same order, apart from voided samples
that stopped early. Harness messages (hand-back reminders, nudges, compaction
summaries) are listed separately, since the eval session did not write them.
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "instructions.json"
ARMS = {"A": ("/home/user/firth-r8", "4c379e0"), "B": ("/home/user/firth-v9", "8ea4a1d")}
OURS = ("You are the author in a programming evaluation.",
        "The coordinator sent a message while you were working:\nFeedback round ")


def messages(log):
    for line in open(log):
        e = json.loads(line)
        m = e.get("message") or {}
        if m.get("role") != "user":
            continue
        c = m["content"]
        for t in [c] if isinstance(c, str) else [x["text"] for x in c if x.get("type") == "text"]:
            yield e.get("timestamp"), t


def template(text, arm, sample):
    root, commit = ARMS[arm]
    t = text.replace(root, "{WORKTREE}").replace(commit, "{COMMIT}")
    return re.sub(rf"haiku-firth-{sample}/", "haiku-firth-{N}/", t)


def build(logdir):
    out = []
    for line in (HERE / "driver" / "ids.txt").read_text().splitlines():
        arm, sample, aid = line.split()[:3]
        ours, harness = [], []
        for ts, text in messages(Path(logdir) / f"{aid}.output"):
            (ours if text.startswith(OURS) else harness).append({"at": ts, "text": text})
        for m in ours:
            m["template"] = template(m["text"], arm, sample)
        void = (HERE / ARMS[arm][1] / f"haiku-firth-{sample}" / "void.md").is_file()
        out.append({"arm": arm, "sample": int(sample), "agent": aid, "void": void,
                    "eval_session": ours, "harness": harness})
    return out


def check(rows):
    """Distinct template sequences per arm; fails if the arms differ."""
    seqs = {"A": set(), "B": set()}
    for r in rows:
        seq = tuple(m["template"] for m in r["eval_session"])
        if r["void"] and len(seq) < 3:
            continue  # stopped before all three instructions were sent
        seqs[r["arm"]].add(seq)
    ok = len(seqs["A"]) == 1 and seqs["A"] == seqs["B"] and len(next(iter(seqs["A"]))) == 3
    return ok, {k: len(v) for k, v in seqs.items()}


def self_test():
    rows = json.loads(OUT.read_text())
    assert check(rows)[0], "committed evidence should pass"
    planted = json.loads(json.dumps(rows))
    b = next(r for r in planted if r["arm"] == "B" and not r["void"])
    b["eval_session"][1]["template"] += " Hint: use dip."
    assert not check(planted)[0], "an arm-specific word must fail the check"
    planted = json.loads(json.dumps(rows))
    next(r for r in planted if not r["void"])["eval_session"].pop()
    assert not check(planted)[0], "a missing round must fail the check"
    print("self-test ok")


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    if sys.argv[1:] == ["--check"]:
        rows = json.loads(OUT.read_text())
    else:
        rows = build(sys.argv[1])
        OUT.write_text(json.dumps(rows, indent=1, ensure_ascii=False) + "\n")
    ok, n = check(rows)
    print(f"authors {len(rows)}; distinct instruction sequences per arm {n}; "
          f"harness messages {sum(len(r['harness']) for r in rows)}")
    if not ok:
        sys.exit("FAIL: the arms did not receive the same instructions")
    for m in next(r for r in rows if not r["void"])["eval_session"]:
        print("---\n" + m["template"])


if __name__ == "__main__":
    main()
