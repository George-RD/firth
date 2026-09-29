#!/usr/bin/env python3
"""Count run 11's answers refused only because of todo.closed-effect-under-locals.

Usage, from the repository root of the pinned worktree:
  python3 eval/s7/runs/2026-09-29-locals-guide/closed_effect.py            (writes closed-effect.txt)
  python3 eval/s7/runs/2026-09-29-locals-guide/closed_effect.py --self-test

A word whose effect has no row variable takes the whole stack, so calling it
inside a `locals` block while a later-used local is live is refused with
`firth.type.word-input-mismatch` even when the author pushed exactly its
inputs (meta/todos/todo.closed-effect-under-locals.md). A refused answer is
a candidate when one of its errors is that code, the callee is a word of the
answer whose declared effect has no `forall` (a closed effect) and the
calling word uses `locals`. It is
counted when the program checks once every such callee's effect is opened
(`(a -- b)` becomes `(forall ρ; ρ a -- ρ b)`, repeated while new candidates
appear): then the live locals were the only extra values. A candidate whose
program still fails after opening is listed as "other errors too".
Opening an effect never changes what a correct program computes, so a
counted answer's remaining failure, if any, is in its results, not its types.
"""
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE))
from analyse import ARMS, counted  # noqa: E402

CODE = "firth.type.word-input-mismatch"
CALL = re.compile(r"`([^`\s]+)` in `([^`\s]+)` (?:needs|takes)")


def closed_callees(error, src):
    """(caller, callee) for each input mismatch at a call of a closed-effect word
    of `src`. `error` is the harness's text or the checker's raw output."""
    if CODE not in error:
        return set()
    return {(caller, callee) for callee, caller in CALL.findall(error)
            if open_effect(src, callee) is not None}


def uses_locals(src, word):
    m = re.search(rf"(?m)^:\s*{re.escape(word)}\s(.*?);\s*$", src, re.S)
    return bool(m and "locals" in m.group(1))


def open_effect(src, word):
    """`src` with `word`'s effect given a row variable, or None if it has one."""
    m = re.search(rf"(?m)^(:\s*{re.escape(word)}\s+)\(([^)]*)\)", src)
    if not m or "forall" in m.group(2) or " -- " not in m.group(2):
        return None
    ins, outs = m.group(2).split(" -- ", 1)
    return src[:m.start(2)] + f"forall ρ; ρ {ins.strip()} -- ρ {outs.strip()}" + src[m.end(2):]


def check(src):
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "answer.firth"
        path.write_text(src, encoding="utf-8")
        run = subprocess.run([sys.executable, str(ROOT / "tools/loop/firth_run.py"), "check",
                              str(path)], capture_output=True, text=True, cwd=ROOT)
    out = run.stdout.strip() or run.stderr.strip()  # a refusal is reported on stderr
    res = json.loads(out.splitlines()[-1])
    if "toolchain" in str(res.get("error", "")):
        sys.exit(f"toolchain failure: {res['error']}")
    return res


def classify(src, error):
    """None if not a candidate, else 'counted' or 'other errors too'."""
    pairs = {p for p in closed_callees(error, src) if uses_locals(src, p[0])}
    if not pairs:
        return None
    for _ in range(8):
        for _, callee in pairs:
            src = open_effect(src, callee) or src
        res = check(src)
        if res.get("status") == "success":
            return "counted"
        more = {p for p in closed_callees(str(res.get("error", "")), src)
                if uses_locals(src, p[0])}
        if not more:
            return "other errors too"
        pairs = more
    return "other errors too"


def failing_error(task):
    return next((c.get("error", "") for c in task.get("cases", []) if not c.get("pass")), "")


def main():
    lines, totals = [], {}
    for arm, path in ARMS.items():
        for d in counted(path):
            for rnd in (1, 2, 3):
                res = json.loads((d / f"results-{rnd}.json").read_text())["tasks"]
                sols = json.loads((d / f"solutions-{rnd}.json").read_text())
                for task, t in res.items():
                    if t.get("pass") or task not in sols:
                        continue
                    kind = classify(sols[task], failing_error(t))
                    if kind:
                        totals[(arm, rnd, kind)] = totals.get((arm, rnd, kind), 0) + 1
                        lines.append(f"{arm}{d.name.rsplit('-', 1)[1]} answer-{rnd} {task}: {kind}")
    out = ["Closed-effect-under-locals refusals in counted samples (closed_effect.py)", ""]
    out += lines + [""]
    for arm in ARMS:
        for rnd in (1, 2, 3):
            out.append(f"arm {arm} answer-{rnd}: counted {totals.get((arm, rnd, 'counted'), 0)}, "
                       f"other errors too {totals.get((arm, rnd, 'other errors too'), 0)}")
    (HERE / "closed-effect.txt").write_text("\n".join(out) + "\n")
    print("\n".join(out))


def self_test():
    h = ": h ( a:Int b:Int -- r:Int ) prim + ;\n"
    ok = h + ": g ( x:Int n:Int -- r:Int ) locals { x n } { x n h } ;\n"
    refused = h + ": g ( x:Int n:Int -- r:Int s:Int ) locals { x n } { x 1 h n } ;\n"
    nested = h + ": g ( x:Int n:Int -- r:Int ) locals { x n } { x locals { y } { y n h } } ;\n"
    # Planted: an author's own extra value, not a live local; opening h does not save it.
    junk = h + ": g ( x:Int n:Int -- r:Int ) locals { x n } { 5 x n h } ;\n"
    assert check(ok).get("status") == "success"
    for src, want in ((refused, "counted"), (nested, "counted"), (junk, "other errors too")):
        res = check(src)
        assert res.get("status") != "success", src
        got = classify(src, str(res.get("error", "")))
        assert got == want, (src, got, res)
    # Planted: the same refusal outside `locals` is not a candidate.
    assert classify(h + ": g ( x:Int -- r:Int ) x x 1 h ;\n", "code: firth.type.word-input-mismatch\n"
                    "word: g\nmessage: `h` in `g` needs Int Int on top of the stack\n") is None
    # Planted: an open-effect callee is not a candidate.
    assert classify(h.replace("( a:Int b:Int -- r:Int )", "( forall ρ; ρ a:Int b:Int -- ρ r:Int )")
                    + nested.split("\n", 1)[1], "code: firth.type.word-input-mismatch\n"
                    "word: g\nmessage: `h` in `g` needs Int Int on top of the stack\n") is None
    print("self-test ok")


if __name__ == "__main__":
    self_test() if sys.argv[1:] == ["--self-test"] else main()
