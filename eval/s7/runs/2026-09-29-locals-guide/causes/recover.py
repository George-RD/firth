#!/usr/bin/env python3
"""How many of run 11's failing final answers the checker's own edits recover.

Usage, from eval/s7:
  python3 runs/2026-09-29-locals-guide/causes/recover.py --firth CHECKOUT [--jobs 4] > OUT.json
  python3 runs/2026-09-29-locals-guide/causes/recover.py --self-test

For every counted sample's failing final answer (results-3.json) that the
checker refuses, this applies, mechanically, each edit the checker's hints
spell out ("write `A` in place of `B`") and checks again. `B` is matched
token by token (the hint prints it on one line), and where it occurs more
than once the occurrence nearest the diagnostic's `line`/`column` is used,
as an author reading `at: line L, column C` would; an equally near second
occurrence is ambiguous and not applied. It then checks again, repeating while new edits appear
(at most eight rounds). It does nothing an author could not have done by
following the hint word for word, and it reads no answer's meaning. Answers
that then check are scored with CHECKOUT's harness (all cases, hidden ones
included). The result is a measurement for that checker: answers the hints
would have recovered had the author applied them, not an estimate.

Run it with the pinned checker (`5d09e25`, what the authors saw) and with
a later one (main) to see what a diagnostic change adds.
"""
import argparse
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from recheck import diagnostics  # noqa: E402
from causes import counted, passed  # noqa: E402

EDIT = re.compile(r"write `([^`]+)` in place of `([^`]+)`")


def edits(diags):
    """(new, old, line, column) for every edit the hints and messages in `diags` spell out."""
    out = []
    for d in diags:
        for text in (d.get("hint") or "", d.get("message") or ""):
            out += [(m[1], m[2], d.get("line"), d.get("column")) for m in EDIT.finditer(text)]
    return out


def offset(src, line, column):
    """The character offset of a 1-based line and column (column counted as the checker does)."""
    lines = src.split("\n")
    if not line or line > len(lines):
        return None
    return sum(len(x) + 1 for x in lines[:line - 1]) + max(0, (column or 1) - 1)


def apply(src, pairs):
    """`src` with each edit applied whose place is unambiguous; and how many were."""
    n = 0
    for new, old, line, column in pairs:
        if " ".join(new.split()) == " ".join(old.split()):
            continue
        spans = [m.span() for m in re.finditer(r"\s+".join(map(re.escape, old.split())), src)]
        if len(spans) > 1:
            at = offset(src, line, column)
            if at is None:
                continue
            dist = sorted((min(abs(a - at), abs(b - at)) if not a <= at <= b else 0, (a, b))
                          for a, b in spans)
            if dist[0][0] == dist[1][0]:
                continue
            spans = [dist[0][1]]
        if len(spans) == 1:
            a, b = spans[0]
            src, n = src[:a] + new + src[b:], n + 1
    return src, n


def check(firth, src):
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "answer.firth"
        path.write_text(src, encoding="utf-8")
        r = subprocess.run([sys.executable, "tools/loop/firth_run.py", "check", str(path)],
                           cwd=firth, capture_output=True, text=True, timeout=300)
    return diagnostics(r.stdout if r.returncode == 0 else r.stderr)


def follow(firth, src, diags):
    """Apply the hints' edits until none applies; return (source, edits applied, diags)."""
    applied = 0
    for _ in range(8):
        new, n = apply(src, edits(diags))
        if not n:
            break
        src, applied = new, applied + n
        diags = check(firth, src)
        if not diags:
            break
    return src, applied, diags


def score(firth, sols, jobs):
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "solutions.json"
        path.write_text(json.dumps(sols))
        r = subprocess.run([sys.executable, "eval/s7/harness.py", "score", "--lang", "firth",
                            "--tier", "mvp", str(path), "--jobs", str(jobs)],
                           cwd=firth, capture_output=True, text=True, check=True)
    return json.loads(r.stdout)["tasks"]


def self_test():
    hint = ("These are the values `prim seq-int.push` takes, in another order. To push them in "
            "its order, write `result n 10 prim mod` in place of `n 10 prim mod result`.")
    pairs = edits([{"hint": hint, "line": 1, "column": 60}])
    assert pairs == [("result n 10 prim mod", "n 10 prim mod result", 1, 60)], pairs
    src = ": f ( n:Int result:Seq Int -- r:Seq Int ) locals { n result } { n 10 prim mod result prim seq-int.push } ;"
    fixed, n = apply(src, pairs)
    assert n == 1 and "result n 10 prim mod prim seq-int.push" in fixed
    # The old text split over two lines still matches, token by token.
    split = src.replace("prim mod result", "prim mod\n  result")
    assert apply(split, pairs)[1] == 1
    # Two occurrences: the one nearest the diagnostic's position is edited.
    twice = ": g ( n:Int result:Seq Int -- r:Seq Int ) locals { n result } { n 10 prim mod result drop\n n 10 prim mod result prim seq-int.push } ;"
    fixed, n = apply(twice, [(*pairs[0][:2], 2, 2)])
    assert n == 1 and fixed.endswith("result n 10 prim mod prim seq-int.push } ;"), fixed
    # Planted: two occurrences and no position is ambiguous, and is not applied.
    assert apply(twice, [(*pairs[0][:2], None, None)]) == (twice, 0)
    # Planted: a hint with no edit sentence gives no edit.
    assert edits([{"hint": "Check the argument order (`swap` exchanges the top two values)."}]) == []
    print("self-test ok")


def main():
    if "--self-test" in sys.argv:
        return self_test()
    cli = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    cli.add_argument("--firth", type=Path, required=True)
    cli.add_argument("--jobs", type=int, default=4)
    a = cli.parse_args()
    head = subprocess.run(["git", "rev-parse", "--short=7", "HEAD"], cwd=a.firth,
                          capture_output=True, text=True).stdout.strip()
    todo = []
    for arm, d in counted():
        sols = json.loads((d / "solutions-3.json").read_text())
        res = json.loads((d / "results-3.json").read_text())["tasks"]
        for task, t in res.items():
            if not passed(t) and task in sols:
                todo.append((arm, f"{arm}{d.name.rsplit('-', 1)[1]}", task, sols[task]))
    check(a.firth, todo[0][3])  # one serial check first, so a cold build is not raced

    def one(item):
        arm, sample, task, src = item
        diags = check(a.firth, src)
        if not diags:
            return {"arm": arm, "sample": sample, "task": task, "refused": False}
        fixed, n, after = follow(a.firth, src, diags)
        return {"arm": arm, "sample": sample, "task": task, "refused": True,
                "first_code": diags[0]["code"], "edits_offered": bool(edits(diags)),
                "edits_applied": n, "checks_after": not after,
                "codes_after": [x["code"] for x in after], "fixed": fixed if n else None,
                "sha256": hashlib.sha256(src.encode()).hexdigest()}

    with ThreadPoolExecutor(a.jobs) as pool:
        rows = list(pool.map(one, todo))
    fixed = [r for r in rows if r.get("checks_after") and r["edits_applied"]]
    if fixed:
        by_sample = {}  # one solutions file per sample, since task ids repeat across samples
        for r in fixed:
            by_sample.setdefault(r["sample"], {})[r["task"]] = r["fixed"]
        for sample, sols in by_sample.items():
            res = score(a.firth, sols, a.jobs)
            for r in fixed:
                if r["sample"] == sample:
                    r["passes_after"] = passed(res[r["task"]])
    json.dump({"checker": head, "answers": rows}, sys.stdout, indent=1, ensure_ascii=False)
    print()


if __name__ == "__main__":
    main()
