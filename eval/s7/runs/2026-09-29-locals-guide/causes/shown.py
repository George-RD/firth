#!/usr/bin/env python3
"""Were the checker's edits in run 11's feedback, and did authors apply them?

Usage, from eval/s7:
  python3 runs/2026-09-29-locals-guide/causes/shown.py > runs/2026-09-29-locals-guide/causes/shown.txt
  python3 runs/2026-09-29-locals-guide/causes/shown.py --self-test

Reads only what the authors were shown (`repair-1.md`, `repair-2.md`, written
by the harness from the pinned checker) and what they wrote next
(`solutions-2.json`, `solutions-3.json`), for the counted samples.

1. For each failing final answer to which the pinned checker offers an edit
   (`recovered-5d09e25.json`), what the feedback on that task said in each
   round: an edit ("write `A` in place of `B`"), an error with no edit, a
   wrong value, or nothing (the visible example passed).
2. For each task section of a feedback file that shows an edit, whether the
   next answer applied it: compared with the answer the feedback was about,
   the next answer has fewer occurrences of `B` and more of `A` (each matched
   token by token). The pinned hints give no line, and a short `B` can
   correctly remain elsewhere, so the counts are compared rather than
   requiring `B` gone; an `A` already present does not count unless its
   count rises. That is a mechanical reading; an answer that rewrote the word
   some other way counts as not applied.
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from causes import counted  # noqa: E402

EDIT = re.compile(r"write `([^`]+)` in place of `([^`]+)`")


def sections(md):
    """{task: text} for each `## task` section of a feedback file."""
    return {m[1]: m[2] for m in re.finditer(r"(?ms)^## (\S+)\n(.*?)(?=^## |\Z)", md)}


def kind(text):
    if text is None:
        return "nothing (example passed)"
    if EDIT.search(text):
        return "edit"
    if "the run failed" in text:
        return "error, no edit"
    return "wrong value"


def occurrences(text, answer):
    """How often `text` occurs in `answer`, matched token by token."""
    return len(re.findall(r"\s+".join(map(re.escape, text.split())), answer))


def applied(new, old, before, after):
    """The edit `old` -> `new` was made between the answers `before` and `after`:
    `old` occurs fewer times and `new` more times."""
    return (occurrences(old, after) < occurrences(old, before)
            and occurrences(new, after) > occurrences(new, before))


def self_test():
    md = ("intro\n## a\nOn the example, the run failed:\nhint: write `x y` in place of `y x`.\n"
          "## b\nOn the example, it returned [1] instead of [2]\n")
    s = sections(md)
    assert kind(s["a"]) == "edit" and kind(s["b"]) == "wrong value" and kind(None).startswith("nothing")
    assert kind("On the example, the run failed:\nhint: Check the order.") == "error, no edit"
    before = ": f y x prim + ;"
    assert applied("x y", "y x", before, ": f x y prim + ;")
    # `y x` correctly remains elsewhere; the edit was still made: applied.
    assert applied("x y", "y x", ": f y x prim + y x drop drop ;", ": f x y prim + y x drop drop ;")
    # Planted: `x y` was already there before the feedback and the edit was not made.
    assert not applied("x y", "y x", ": f x y drop y x prim + ;", ": f x y drop y x prim + ;")
    # Planted: `x y` added elsewhere while every `y x` stays is not applied.
    assert not applied("x y", "y x", before, ": f x y drop y x prim + ;")
    # Planted: rewritten some other way is not applied.
    assert not applied("x y", "y x", before, ": f y x swap prim + ;")
    print("self-test ok")


def main():
    if "--self-test" in sys.argv:
        return self_test()
    dirs = {f"{arm}{d.name.rsplit('-', 1)[1]}": d for arm, d in counted()}
    rec = json.loads((HERE / "recovered-5d09e25.json").read_text())["answers"]
    seen, passes = Counter(), Counter()
    for r in rec:
        if not r.get("edits_offered"):
            continue
        d = dirs[r["sample"]]
        k = tuple(kind(sections((d / f"repair-{n}.md").read_text()).get(r["task"])) for n in (1, 2))
        seen[(r["arm"], k)] += 1
        passes[(r["arm"], k)] += bool(r.get("passes_after"))
    print("1. Failing final answers with an edit offered (pinned checker), by what the")
    print("   feedback on that task showed in round 1 and round 2")
    for arm in "AB":
        for k, n in sorted(((k, n) for (a, k), n in seen.items() if a == arm), key=lambda x: -x[1]):
            print(f"   {arm}  {n:3d}  pass after the edit {passes[(arm, k)]:2d}  {k[0]} / {k[1]}")
    never = sum(n for (a, k), n in seen.items() if "edit" not in k)
    print(f"   no edit shown in either round: {never} of {sum(seen.values())}, "
          f"of which pass after the edit: {sum(n for (a, k), n in passes.items() if 'edit' not in k)}")
    print()
    print("2. Feedback task sections showing an edit, and whether the next answer applied it")
    shown, taken, samples = Counter(), Counter(), {"A": set(), "B": set()}
    for arm, d in counted():
        for n in (1, 2):
            cur = json.loads((d / f"solutions-{n}.json").read_text())
            nxt = json.loads((d / f"solutions-{n + 1}.json").read_text())
            for task, text in sections((d / f"repair-{n}.md").read_text()).items():
                e = EDIT.search(text)
                if not e:
                    continue
                shown[arm] += 1
                samples[arm].add(d.name)
                taken[arm] += task in nxt and applied(e[1], e[2], cur.get(task, ""), nxt[task])
    for arm in "AB":
        print(f"   {arm}  shown {shown[arm]:3d} (in {len(samples[arm])} samples)  applied {taken[arm]:3d}")


if __name__ == "__main__":
    main()
