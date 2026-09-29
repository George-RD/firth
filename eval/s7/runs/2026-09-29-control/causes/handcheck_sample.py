#!/usr/bin/env python3
"""Print the random sample of failing answers labelled by hand in handcheck.md.

Usage, from eval/s7: python3 runs/2026-09-29-control/causes/handcheck_sample.py [--compare]

Fifteen failing first answers and fifteen failing final answers, drawn with a
fixed seed from units.json, shown as Jev saw them (jev_causes.state) but
without Jev's label, so the hand labels were written blind to it.
With --compare, reads the hand labels from handcheck.md and prints each
beside Jev's label from jev.json, and the agreement.
"""
import json
import random
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import jev_causes  # noqa: E402


def sample():
    rows = [r for r in json.loads((HERE / "units.json").read_text()) if not r["passed"]]
    rng = random.Random(20260929)
    return (rng.sample([r for r in rows if r["round"] == 1], 15)
            + rng.sample([r for r in rows if r["round"] == 3], 15))


def hand_labels(text):
    """{number: (sample, round, task, label)} from handcheck.md's table."""
    out = {}
    for line in text.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 5 and cells[0].isdigit():
            out[int(cells[0])] = (cells[1], int(cells[2]), cells[3], cells[4])
    return out


def compare():
    hand = hand_labels((HERE / "handcheck.md").read_text())
    jev = {(a["sample"], a["round"], a["task"]): a
           for a in json.loads((HERE / "jev.json").read_text())["answers"]}
    rows = sample()
    assert sorted(hand) == list(range(1, len(rows) + 1)), "handcheck.md must label every row"
    agree = {1: 0, 3: 0}
    for i, r in enumerate(rows, 1):
        key = (r["sample"], r["round"], r["task"])
        assert hand[i][:3] == key, (i, hand[i], key)
        j = jev[key]
        same = j["label"] == hand[i][3]
        agree[r["round"]] += same
        print(f"{i:2d} {r['sample']:4s} {r['round']} {r['task']:15s} hand {hand[i][3]:18s} "
              f"jev {j['label']:18s} {j['confidence']:.2f} {'agree' if same else 'DIFFER'}")
    for n in (1, 3):
        print(f"round {n}: {agree[n]} of 15 agree")
    print(f"all: {agree[1] + agree[3]} of {len(rows)} agree")


if __name__ == "__main__" and "--compare" in sys.argv:
    compare()
elif __name__ == "__main__":
    for i, r in enumerate(sample(), 1):
        print(f"##### {i}. {r['sample']} round {r['round']} {r['task']}")
        print(jev_causes.state(r)[:2600])
        print()
