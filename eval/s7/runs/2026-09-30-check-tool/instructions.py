#!/usr/bin/env python3
"""Recover what each run 12 author was told, and check it against the templates.

Usage, from eval/s7:
  python3 runs/2026-09-30-check-tool/instructions.py LOGDIR   (writes instructions.json)
  python3 runs/2026-09-30-check-tool/instructions.py --check  (reads instructions.json)
  python3 runs/2026-09-30-check-tool/instructions.py --self-test

As run 11's `instructions.py`, whose reader this uses: every text message an
author received is kept verbatim, and the eval session's own messages are
reduced to templates. Run 12's arms are told different things on purpose
(arm B may run the checker), so --check fails unless each author received
exactly its own arm's three templates in `instructions-templates.json`, in
order, apart from void samples that stopped early.
"""
import importlib.util
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "instructions.json"
TEMPLATES = json.loads((HERE / "instructions-templates.json").read_text())
_spec = importlib.util.spec_from_file_location(
    "run11_instructions", HERE.parent / "2026-09-29-locals-guide" / "instructions.py")
run11 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(run11)
ARMS = {"A": "arm-a", "B": "arm-b"}


def build(logdir):
    out = []
    for line in (HERE / "driver" / "ids.txt").read_text().splitlines():
        arm, sample, aid = line.split()[:3]
        ours, harness = [], []
        for ts, text in run11.messages(Path(logdir) / f"{aid}.output"):
            (ours if text.startswith(run11.OURS) else harness).append({"at": ts, "text": text})
        for m in ours:
            m["template"] = run11.template(m["text"], arm, sample)
        void = (HERE / ARMS[arm] / f"haiku-firth-{sample}" / "void.md").is_file()
        out.append({"arm": arm, "sample": int(sample), "agent": aid, "void": void,
                    "eval_session": ours, "harness": harness})
    return out


def check(rows):
    """The authors whose instructions are not their arm's templates."""
    wrong = []
    for r in rows:
        seq = [m["template"] for m in r["eval_session"]]
        want = TEMPLATES[r["arm"]]
        if seq != want and not (r["void"] and seq == want[:len(seq)]):
            wrong.append(f"{r['arm']}{r['sample']}")
    return wrong


def self_test():
    # run 11's template() names arms by run 11's directories, which run 12 reuses.
    assert run11.ARMS == ARMS
    rows = [{"arm": arm, "sample": 1, "void": False,
             "eval_session": [{"template": t} for t in TEMPLATES[arm]]} for arm in ARMS]
    assert check(rows) == []
    # Planted: an arm A author shown arm B's first instruction, a word added
    # to a feedback round, and a missing round in a counted sample.
    swapped = json.loads(json.dumps(rows))
    swapped[0]["eval_session"][0]["template"] = TEMPLATES["B"][0]
    assert check(swapped) == ["A1"]
    added = json.loads(json.dumps(rows))
    added[1]["eval_session"][2]["template"] += " Hint: use dip."
    assert check(added) == ["B1"]
    short = json.loads(json.dumps(rows))
    short[0]["eval_session"].pop()
    assert check(short) == ["A1"]
    short[0]["void"] = True
    assert check(short) == []
    # The templates really differ between arms, only by the tool sentences.
    assert all(a != b for a, b in zip(TEMPLATES["A"], TEMPLATES["B"]))
    assert all("check --lang firth" in t for t in TEMPLATES["B"])
    assert not any("check --lang firth" in t for t in TEMPLATES["A"])
    print("self-test ok")


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    if sys.argv[1:] == ["--check"]:
        rows = json.loads(OUT.read_text())
    else:
        rows = build(sys.argv[1])
        OUT.write_text(json.dumps(rows, indent=1, ensure_ascii=False) + "\n")
    wrong = check(rows)
    print(f"authors {len(rows)}; harness messages {sum(len(r['harness']) for r in rows)}")
    if wrong:
        sys.exit(f"FAIL: not their arm's instructions: {', '.join(wrong)}")


if __name__ == "__main__":
    main()
