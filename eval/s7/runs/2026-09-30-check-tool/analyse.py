#!/usr/bin/env python3
"""Run 12's pre-registered tests (preregistration.md, "Outcomes").

Usage, from eval/s7: python3 runs/2026-09-30-check-tool/analyse.py [--self-test]

A sample counts when its directory has results-1.json and results-3.json and
no void.md; the counted samples of an arm are its first 20 non-void ones by
start order. A task passes when every case passes. The exact one-sided
Mann-Whitney and Fisher tests are run 11's (`../2026-09-29-locals-guide/
analyse.py`), whose self-test checks them against brute-force enumeration.
"""
import importlib.util
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ARMS = {"A": HERE / "arm-a", "B": HERE / "arm-b"}
_spec = importlib.util.spec_from_file_location(
    "run11_analyse", HERE.parent / "2026-09-29-locals-guide" / "analyse.py")
run11 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(run11)
N_PER_ARM = run11.N_PER_ARM
counted, extra, voided, ready, passed = (run11.counted, run11.extra, run11.voided,
                                         run11.ready, run11.passed)
mann_whitney_greater, fisher_greater = run11.mann_whitney_greater, run11.fisher_greater
# What the checker says when it refuses a program, as the harness keeps it in a
# case's error (`compact`): the first diagnostic's code, or the count of them.
REFUSED = ("code: ", "The checker found")


def refused(task):
    """The answer to this task was refused by the checker (a trap or a wrong
    value is not a refusal)."""
    return any(str(c.get("error") or "").startswith(REFUSED) for c in task.get("cases", []))


def clean_share(results, solutions):
    """Share of the tasks a sample answered whose final answer the checker accepts."""
    tasks = json.loads(results.read_text())["tasks"]
    answered = [t for t in json.loads(solutions.read_text()) if t in tasks]
    return sum(not refused(tasks[t]) for t in answered) / len(answered) if answered else 0.0


def check_calls(transcript):
    """Checker runs in a sample's audited log (arm B), by answer file."""
    calls = json.loads(transcript.read_text())["tool_calls"]
    out = {}
    for c in calls:
        if "check" in c:
            out[c["check"]] = out.get(c["check"], 0) + 1
    return out


def self_test():
    # Refusal read from the results agrees with a fresh check of every counted
    # final answer of run 11 (causes/rechecked.json): 800 of 800.
    import hashlib
    run = HERE.parent / "2026-09-29-locals-guide"
    rechecked = json.loads((run / "causes" / "rechecked.json").read_text())["answers"]
    agree = total = 0
    for arm in ("arm-a", "arm-b"):
        for d in counted(run / arm):
            res = json.loads((d / "results-3.json").read_text())["tasks"]
            for t, src in json.loads((d / "solutions-3.json").read_text()).items():
                if t in res:
                    total += 1
                    agree += refused(res[t]) == bool(rechecked[hashlib.sha256(src.encode()).hexdigest()])
    assert (agree, total) == (800, 800), (agree, total)
    # Planted: a trap and a wrong value are not refusals; a checker code is.
    assert not refused({"cases": [{"error": "trap index-out-of-range\n..."}, {"error": None}]})
    assert refused({"cases": [{"error": "code: firth.syntax.unexpected-token\n..."}]})
    assert refused({"cases": [{"error": "The checker found 2 errors, one for each word"}]})
    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        t = Path(tmp) / "transcript.json"
        t.write_text(json.dumps({"tool_calls": [{"tool": "Bash", "check": "answer-1.md"},
                                                {"tool": "Read"}, {"tool": "Bash", "check": "answer-1.md"},
                                                {"tool": "Bash", "check": "answer-2.md"}]}))
        assert check_calls(t) == {"answer-1.md": 2, "answer-2.md": 1}
    run11.self_test()


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    dirs = {arm: counted(path) for arm, path in ARMS.items()}
    why = ready(dirs)
    if why:
        sys.exit(why)
    rows = {arm: [(d.name, passed(d / "results-1.json"), passed(d / "results-3.json"),
                   clean_share(d / "results-3.json", d / "solutions-3.json"),
                   check_calls(d / "transcript.json"))
                  for d in ds] for arm, ds in dirs.items()}
    for arm, rs in rows.items():
        print(f"arm {arm}: {len(rs)} counted samples")
        for name, first, final, clean, calls in rs:
            runs = " ".join(f"{k.split('.')[0]} {v}" for k, v in sorted(calls.items())) or "none"
            print(f"  {name:15} first {first:2}  final {final:2}  final answers checking {clean:.2f}  "
                  f"checker runs: {runs}")
        for name, scores in voided(ARMS[arm]):
            shown = " / ".join("-" if x is None else str(x) for x in scores)
            print(f"  {name:15} VOID, not counted; passes by round {shown}")
        for d in extra(ARMS[arm]):
            print(f"  {d.name:15} started after the 20th counted sample, not counted")
    a, b = rows["A"], rows["B"]
    col = lambda rs, i: [r[i] for r in rs]  # noqa: E731
    u, p = mann_whitney_greater(col(b, 2), col(a, 2))
    print(f"\nPrimary: tasks passed after round 2, B > A: sums A {sum(col(a, 2))} "
          f"B {sum(col(b, 2))}; U_B = {u}, one-sided exact p = {p:.4f}")
    runs = sorted(sum(c.values()) for c in col(b, 4))
    print(f"Secondary 1: checker runs per arm B sample: median {runs[len(runs) // 2]}, "
          f"range {runs[0]} to {runs[-1]}, total {sum(runs)} (arm A: {sum(sum(c.values()) for c in col(a, 4))})")
    u, p = mann_whitney_greater(col(b, 3), col(a, 3))
    print(f"Secondary 2: share of final answers the checker accepts, B > A: mean A "
          f"{sum(col(a, 3)) / len(a):.2f} B {sum(col(b, 3)) / len(b):.2f}; U_B = {u}, "
          f"one-sided exact p = {p:.4f}")
    u, p = mann_whitney_greater(col(b, 1), col(a, 1))
    print(f"Secondary 3: tasks passed in the first answer, B > A: sums A {sum(col(a, 1))} "
          f"B {sum(col(b, 1))}; U_B = {u}, one-sided exact p = {p:.4f}")
    ay, by = sum(x > 0 for x in col(a, 2)), sum(x > 0 for x in col(b, 2))
    print(f"Reported only: samples passing >= 1 task after round 2: A {ay}/{len(a)} B {by}/{len(b)}; "
          f"one-sided Fisher p = {fisher_greater(by, len(b), ay, len(a)):.4f}")


if __name__ == "__main__":
    main()
