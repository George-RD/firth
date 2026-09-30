#!/usr/bin/env python3
"""Counterfactual: run 11's final answers refused because a `locals` block has no braced body.

Usage, from eval/s7:
  python3 runs/2026-09-29-locals-guide/causes/locals_body.py --firth CHECKOUT > locals-body.json
  python3 runs/2026-09-29-locals-guide/causes/locals_body.py --self-test

A21 and B21 wrote every word as `locals { a b } body ;`, with no braces around
the body, in all three rounds. The checker says only "Unexpected `a`,
expected `{`" with the generic hint "A definition looks like ...". This takes
every counted failing final answer whose first error is that one, wraps each
unbraced `locals` body in braces up to the end of its word (the only reading
the grammar allows), checks it and scores it with CHECKOUT's harness. It is a
hand-made counterfactual, not scored as part of the run: it measures how many
of those answers the brace mistake alone was hiding.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from causes import counted, passed  # noqa: E402
from recover import check, score  # noqa: E402

UNBRACED = re.compile(r"locals\s*\{[^{}]*\}(?!\s*\{)")


def brace(src):
    """`src` with every unbraced `locals` body wrapped in braces. The body runs to
    the end of the group the block sits in: the `]` or `}` that closes it, or the
    word's final `;`."""
    while True:
        m = UNBRACED.search(src)
        if not m:
            return src
        depth, i = 0, m.end()
        while i < len(src):
            ch = src[i]
            if ch in "[{":
                depth += 1
            elif ch in "]}":
                if depth == 0:
                    break
                depth -= 1
            elif ch == ";" and depth == 0:
                break
            i += 1
        body = src[m.end():i]
        src = src[:m.end()] + " {" + body.rstrip() + " }" + body[len(body.rstrip()):] + src[i:]


def self_test():
    src = (": f\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n"
           "  locals { a b }\n  a b prim +;\n\n: g ( x:Int -- y:Int ) locals { x } { x } ;\n")
    got = brace(src)
    assert "locals { a b } {\n  a b prim + };" in got, got
    assert ": g ( x:Int -- y:Int ) locals { x } { x } ;" in got
    # Inside a quotation, the body ends at the quotation's closing bracket.
    inner = ": k ( x:Int -- y:Int ) locals { x } { x 0 prim < [ x locals { v }\n v ] [ x ] if } ;\n"
    assert "[ x locals { v } {\n v } ] [ x ] if } ;" in brace(inner), brace(inner)
    # An already braced body is left alone, and so is a nested braced block.
    ok = ": h ( x:Int -- y:Int ) locals { x } { x locals { y } { y } } ;\n"
    assert brace(ok) == ok
    print("self-test ok")


def main():
    if "--self-test" in sys.argv:
        return self_test()
    cli = argparse.ArgumentParser()
    cli.add_argument("--firth", type=Path, required=True)
    a = cli.parse_args()
    rows = []
    for arm, d in counted():
        sols = json.loads((d / "solutions-3.json").read_text())
        res = json.loads((d / "results-3.json").read_text())["tasks"]
        for task, t in res.items():
            err = next((c.get("error") or "" for c in t["cases"] if not c["pass"]), "")
            if passed(t) or not re.search(r"Unexpected `[^`]+`, expected `\{`", err):
                continue
            fixed = brace(sols[task])
            after = check(a.firth, fixed)
            rows.append({"arm": arm, "sample": f"{arm}{d.name.rsplit('-', 1)[1]}", "task": task,
                         "checks_after": not after,
                         "codes_after": [x["code"] for x in after], "fixed": fixed})
    by_sample = {}
    for r in rows:
        if r["checks_after"]:
            by_sample.setdefault(r["sample"], {})[r["task"]] = r["fixed"]
    for sample, sols in by_sample.items():
        res = score(a.firth, sols, 4)
        for r in rows:
            if r["sample"] == sample and r["checks_after"]:
                r["passes_after"] = passed(res[r["task"]])
    head = subprocess.run(["git", "rev-parse", "--short=7", "HEAD"], cwd=a.firth,
                          capture_output=True, text=True).stdout.strip()
    json.dump({"checker": head, "answers": rows}, sys.stdout, indent=1, ensure_ascii=False)
    print()


if __name__ == "__main__":
    main()
