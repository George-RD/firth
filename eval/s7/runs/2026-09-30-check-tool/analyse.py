#!/usr/bin/env python3
"""Run 12's pre-registered tests (preregistration.md, "Outcomes").

Usage, from eval/s7: python3 runs/2026-09-30-check-tool/analyse.py [--self-test]

A sample counts when its directory has results-1.json and results-3.json and
no void.md; the counted samples of an arm are its first 40 non-void ones by
start order. A void sample's void.md starts with `toolchain:` or `rule:`, the
kind of void; the start-order analysis keeps rule voids and drops toolchain
ones. A task passes when every case passes. The exact one-sided
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
N_PER_ARM = 40  # preregistration.md, "Sample size"
passed, samples, voided = run11.passed, run11.samples, run11.voided


def counted(arm_dir, n=N_PER_ARM):
    return run11.counted(arm_dir, n)


def extra(arm_dir, n=N_PER_ARM):
    return run11.extra(arm_dir, n)


def ready(dirs, n=N_PER_ARM):
    return run11.ready(dirs, n)


def void_kind(d):
    """None for a valid sample, else `toolchain` or `rule`: void.md starts `toolchain:` or `rule:`."""
    v = d / "void.md"
    if not v.is_file():
        return None
    words = v.read_text().split()
    kind = words[0].rstrip(":") if words else ""
    if kind not in ("toolchain", "rule"):
        raise ValueError(f"{v}: must start with `toolchain:` or `rule:`")
    return kind


def started(arm_dir, n=N_PER_ARM):
    """The first n samples by start order, rule voids kept, toolchain voids left
    out (preregistration.md, secondary 4)."""
    return [d for d in samples(arm_dir) if void_kind(d) != "toolchain"][:n]


def last_passed(d):
    """Tasks passed by the latest answer a sample had scored; 0 if none was."""
    for r in (3, 2, 1):
        if (d / f"results-{r}.json").is_file():
            return passed(d / f"results-{r}.json")
    return 0


def opposed(primary, start_order):
    """Secondary 4's B minus A total points the other way from the primary's."""
    return primary * start_order < 0


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
    # Planted: 44 started samples with a rule void (scored 7 in round 2) and a
    # toolchain void. The start-order set keeps the rule void, scored on its
    # latest answer, drops the toolchain void, and stops at 40.
    with tempfile.TemporaryDirectory() as tmp:
        arm = Path(tmp)
        for i in range(1, 45):
            d = arm / f"haiku-firth-{i}"
            d.mkdir()
            for r in (1, 3):
                (d / f"results-{r}.json").write_text(json.dumps({"tasks": {"t": {"cases": [{"pass": False}]}}}))
        (arm / "haiku-firth-2" / "results-3.json").unlink()
        (arm / "haiku-firth-2" / "results-2.json").write_text(json.dumps(
            {"tasks": {f"t{k}": {"cases": [{"pass": True}]} for k in range(7)}}))
        (arm / "haiku-firth-2" / "void.md").write_text("rule: Bash `ls`\n")
        (arm / "haiku-firth-3" / "void.md").write_text("toolchain: lake exit 1\n")
        got = started(arm)
        assert len(got) == 40 and got[1].name == "haiku-firth-2"
        assert "haiku-firth-3" not in [d.name for d in got] and got[-1].name == "haiku-firth-41"
        assert last_passed(got[1]) == 7 and last_passed(got[0]) == 0
        assert len(counted(arm)) == 40 and "haiku-firth-2" not in [d.name for d in counted(arm)]
        (arm / "haiku-firth-4" / "void.md").write_text("because\n")
        try:
            started(arm)
            raise AssertionError("an unmarked void was accepted")
        except ValueError:
            pass
    # Planted: a primary gain with a start-order loss is opposed; same signs are not.
    assert opposed(12, -3) and opposed(-2, 5)
    assert not opposed(12, 3) and not opposed(12, 0) and not opposed(0, -4)
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
            print(f"  {d.name:15} started after the {N_PER_ARM}th counted sample, not counted")
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
    st = {arm: [last_passed(d) for d in started(path)] for arm, path in ARMS.items()}
    u, p = mann_whitney_greater(st["B"], st["A"])
    print(f"Secondary 4: tasks passed by the first {N_PER_ARM} started samples per arm, rule "
          f"voids scored on their latest answer, B > A: sums A {sum(st['A'])} B {sum(st['B'])}; "
          f"U_B = {u}, one-sided exact p = {p:.4f}")
    if opposed(sum(col(b, 2)) - sum(col(a, 2)), sum(st["B"]) - sum(st["A"])):
        print("Secondary 4 points the other way from the primary: the primary is not read as a gain.")
    for arm, path in ARMS.items():
        kinds = [void_kind(d) for d in samples(path)]
        print(f"Voids, arm {arm}: {kinds.count('rule')} rule and {kinds.count('toolchain')} "
              f"toolchain of {len(kinds)} started")
    ay, by = sum(x > 0 for x in col(a, 2)), sum(x > 0 for x in col(b, 2))
    print(f"Reported only: samples passing >= 1 task after round 2: A {ay}/{len(a)} B {by}/{len(b)}; "
          f"one-sided Fisher p = {fisher_greater(by, len(b), ay, len(a)):.4f}")


if __name__ == "__main__":
    main()
