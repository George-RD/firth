#!/usr/bin/env python3
"""What sits behind B4's syntax errors: recheck its final answers without the parentheses.

Usage, from eval/s7:
    python3 runs/2026-09-29-control/causes/b4_parens.py --firth /path/to/checkout-at-8ea4a1d
    python3 runs/2026-09-29-control/causes/b4_parens.py --self-test

A syntax error ends the parse, so the checker reports nothing else for that
answer and "single-family" is true of every syntax failure by construction.
B4 wrote all 20 final answers with parentheses around conditions, which the
parser refuses. This removes each parenthesised group that is not a stack
effect `(forall ...)` or a comment `(* ... *)`, keeping what was inside, and
rechecks the edited answer with `recheck.py`'s checker. The edit is a
counterfactual: hand-made, not scored, and not something B4 wrote.
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import causes  # noqa: E402
import recheck  # noqa: E402

PARENS = re.compile(r"\((?!forall\b|\*)([^()\n]*)\)")


def unparen(src):
    return PARENS.sub(lambda m: m[1].strip(), src)


def report(firth):
    sols = json.loads((HERE.parent / "8ea4a1d/haiku-firth-4/solutions-3.json").read_text())
    out = Counter()
    for task, src in sols.items():
        edited = unparen(src)
        diags = [d for d in recheck.check(firth, edited) if not d.get("assumes")]
        fams = sorted({causes.family(d["code"]) for d in diags})
        key = "checks" if not diags else " + ".join(fams)
        out[key] += 1
        print(f"  {task:15s} {key}")
    print(f"\nB4's {len(sols)} final answers with the parentheses removed "
          f"(counterfactual, hand-edited, not scored):")
    for k, v in out.most_common():
        print(f"  {v:3d}  {k}")


def self_test():
    src = ": w\n  (forall ρ; ρ i:Int -- ρ b:Bool)\n  (* note *)\n  (i 1 prim <) [ (i) ] [ i ] if ;"
    assert unparen(src) == (": w\n  (forall ρ; ρ i:Int -- ρ b:Bool)\n  (* note *)\n"
                            "  i 1 prim < [ i ] [ i ] if ;"), unparen(src)
    print("self-test ok")


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        self_test()
    else:
        report(Path(sys.argv[sys.argv.index("--firth") + 1]))
