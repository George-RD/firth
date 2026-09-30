#!/usr/bin/env python3
"""Run 13's pre-registered tests (preregistration.md, "Outcomes").

Usage, from eval/s7: python3 runs/2026-09-30-check-forms/analyse.py [--self-test | --early-look]

The primary and the start-order analysis are co-primary: a gain is claimed
only when both are significant (`gain_claimed`). `--early-look` applies the
pre-registered early feasibility look to arm B's void status.

A sample counts when its directory has results-1.json and results-3.json and
no void.md; the counted samples of an arm are its first 40 non-void ones by
start order. A void sample's void.md starts with `toolchain:` or `rule:`, the
kind of void; the start-order analysis keeps rule voids, scored on their
third answer like every other sample, and drops toolchain ones. The driver
writes final.md in a sample's directory once the audit and the scans have
run on its complete log after its third answer was scored, so its validity
is final. A task passes when every case passes. The exact one-sided
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


# The validity rules a rule void can break (preregistration.md, "Validity of a sample").
CAUSES = ("audit", "agent-files", "context", "answers")


def void_kind(d):
    """None for a valid sample, else `toolchain` or `rule`: void.md starts `toolchain:` or `rule:`."""
    v = d / "void.md"
    if not v.is_file():
        return None
    words = v.read_text().split()
    kind = words[0].rstrip(":") if words else ""
    if kind not in ("toolchain", "rule"):
        raise ValueError(f"{v}: must start with `toolchain:` or `rule:`")
    if kind == "rule":
        void_causes(d)
    return kind


def void_causes(d):
    """The rules a rule void broke: void.md starts `rule: <causes>:`, the
    causes comma-separated from CAUSES, then the reason."""
    v = d / "void.md"
    head = v.read_text().split(":", 2)
    causes = head[1].split(",") if len(head) == 3 else []
    causes = [c.strip() for c in causes]
    if not causes or any(c not in CAUSES for c in causes):
        raise ValueError(f"{v}: a rule void starts `rule: <causes>:` with causes from {', '.join(CAUSES)}")
    return causes


def started(arm_dir, n=N_PER_ARM):
    """The first n samples by start order, rule voids kept, toolchain voids left
    out (preregistration.md, co-primary 2)."""
    return [d for d in samples(arm_dir) if void_kind(d) != "toolchain"][:n]


def final_passed(d):
    """Tasks passed by a sample's third answer. Every started sample, void or
    not, gets both feedback rounds (preregistration.md, "Author"), so a rule
    void without a scored third answer is a protocol error, not a zero."""
    f = d / "results-3.json"
    if not f.is_file():
        raise ValueError(f"{d}: no results-3.json; every started sample is scored on its third answer")
    return passed(f)


def opposed(primary, start_order):
    """Secondary 4's B minus A total points the other way from the primary's."""
    return primary * start_order < 0


def gain_claimed(p_primary, p_start_order, alpha=0.05):
    """Run 13's co-primary rule: a gain is claimed only when the primary and
    the start-order analysis are each significant, arm B greater."""
    return p_primary < alpha and p_start_order < alpha


EARLY_LOOK, EARLY_LIMIT = 10, 6  # preregistration.md, "Early feasibility look"


def early_window(arm_dir, look=EARLY_LOOK):
    """The first `look` samples started in the arm, toolchain voids left out,
    or None while any sample up to the last of them lacks final.md: until
    then a sample's kind of void, or whether it is void, can still change."""
    first = []
    for d in samples(arm_dir):
        if not (d / "final.md").is_file():
            return None
        if void_kind(d) != "toolchain":
            first.append(d)
            if len(first) == look:
                return first
    return None


def audit_void(d):
    """A rule void the audit found, whatever else it broke."""
    return void_kind(d) == "rule" and "audit" in void_causes(d)


def early_stop(arm_dir, look=EARLY_LOOK, limit=EARLY_LIMIT):
    """None until the look can be taken (early_window); then True when `limit`
    or more of those samples are audit voids. Context voids alone are not
    counted (secondary 5 reports them). It reads void status only, never a
    score, and once every sample in the window is final the reading cannot
    change."""
    first = early_window(arm_dir, look)
    if first is None:
        return None
    return sum(audit_void(d) for d in first) >= limit


def status_leaks(arm_dir):
    """Samples of an arm whose context scan flagged the harness's `task_status`
    line naming another author, and how many of them are void
    (preregistration.md, secondary 5)."""
    hit = []
    for d in samples(arm_dir):
        f = d / "context-seen.json"
        items = json.loads(f.read_text()).get("injected", []) if f.is_file() else []
        if any(i.get("cross_sample") and i.get("kind") == "attachment:task_status" for i in items):
            hit.append(d)
    return len(hit), sum(void_kind(d) is not None for d in hit)


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
    # Planted: 44 started samples with a rule void (scored 7 on its third
    # answer, 0 on its second) and a toolchain void. The start-order set keeps
    # the rule void, scored on its third answer, drops the toolchain void, and
    # stops at 40; a started sample with no third answer is refused.
    with tempfile.TemporaryDirectory() as tmp:
        arm = Path(tmp)
        for i in range(1, 45):
            d = arm / f"haiku-firth-{i}"
            d.mkdir()
            for r in (1, 3):
                (d / f"results-{r}.json").write_text(json.dumps({"tasks": {"t": {"cases": [{"pass": False}]}}}))
        (arm / "haiku-firth-2" / "results-3.json").write_text(json.dumps(
            {"tasks": {f"t{k}": {"cases": [{"pass": True}]} for k in range(7)}}))
        (arm / "haiku-firth-2" / "results-2.json").write_text(json.dumps(
            {"tasks": {"t": {"cases": [{"pass": False}]}}}))
        (arm / "haiku-firth-2" / "void.md").write_text("rule: audit: Bash `ls`\n")
        (arm / "haiku-firth-3" / "void.md").write_text("toolchain: lake exit 1\n")
        got = started(arm)
        assert len(got) == 40 and got[1].name == "haiku-firth-2"
        assert "haiku-firth-3" not in [d.name for d in got] and got[-1].name == "haiku-firth-41"
        assert final_passed(got[1]) == 7 and final_passed(got[0]) == 0
        assert len(counted(arm)) == 40 and "haiku-firth-2" not in [d.name for d in counted(arm)]
        (arm / "haiku-firth-5" / "results-3.json").unlink()
        (arm / "haiku-firth-5" / "void.md").write_text("rule: audit: Bash `ls`\n")
        try:
            final_passed(arm / "haiku-firth-5")
            raise AssertionError("a void without a third answer was scored")
        except ValueError:
            pass
        (arm / "haiku-firth-5" / "void.md").unlink()
        for bad in ("because\n", "rule: Bash `ls`\n", "rule: grep: Bash `ls`\n"):
            (arm / "haiku-firth-4" / "void.md").write_text(bad)
            try:
                started(arm)
                raise AssertionError(f"an unmarked void was accepted: {bad!r}")
            except ValueError:
                pass
    # Planted: the early look fires at 6 rule voids of the first 10 started,
    # not at 5, and not on toolchain voids; it is not taken before 10 have
    # started, or while any sample up to the 10th lacks final.md.
    with tempfile.TemporaryDirectory() as tmp:
        arm = Path(tmp)
        for i in range(1, 13):
            (arm / f"haiku-firth-{i}").mkdir()
            (arm / f"haiku-firth-{i}" / "final.md").write_text("final\n")
        for i in (1, 2, 3, 4, 5):
            (arm / f"haiku-firth-{i}" / "void.md").write_text("rule: audit: Bash `ls`\n")
        assert early_stop(arm) is False
        (arm / "haiku-firth-6" / "void.md").write_text("toolchain: lake exit 1\n")
        assert early_stop(arm) is False
        (arm / "haiku-firth-11" / "void.md").write_text("rule: context: task_status\n")
        assert early_stop(arm) is False, "a context void is not counted"
        (arm / "haiku-firth-11" / "void.md").write_text("rule: context, audit: task_status; Bash `ls`\n")
        assert early_stop(arm) is True
        (arm / "haiku-firth-4" / "final.md").unlink()
        assert early_stop(arm) is None, "a sample in the window is not final"
        (arm / "haiku-firth-4" / "final.md").write_text("final\n")
        (arm / "haiku-firth-12" / "final.md").unlink()
        assert early_stop(arm) is True, "a later sample's finality does not matter"
        (arm / "haiku-firth-12").joinpath("final.md").write_text("final\n")
        for i in (10, 12):
            for f in (arm / f"haiku-firth-{i}").iterdir():
                f.unlink()
            (arm / f"haiku-firth-{i}").rmdir()
        assert early_stop(arm) is None, "fewer than 10 non-toolchain starts"
    # Planted: a task_status leak is counted, and whether it voided the
    # sample; another cross-sample kind and an unflagged status are not.
    with tempfile.TemporaryDirectory() as tmp:
        arm = Path(tmp)
        for i, items, void in ((1, [{"kind": "attachment:task_status", "cross_sample": True}], True),
                               (2, [{"kind": "attachment:task_status", "cross_sample": True}], False),
                               (3, [{"kind": "attachment:file", "cross_sample": True}], False),
                               (4, [{"kind": "attachment:task_status"}], False)):
            d = arm / f"haiku-firth-{i}"
            d.mkdir()
            (d / "context-seen.json").write_text(json.dumps({"injected": items}))
            if void:
                (d / "void.md").write_text("rule: context: task_status\n")
        assert status_leaks(arm) == (2, 1), status_leaks(arm)
    # Planted: the co-primary rule needs both tests.
    assert gain_claimed(0.01, 0.04)
    assert not gain_claimed(0.01, 0.06) and not gain_claimed(0.2, 0.01)
    # Planted: a primary gain with a start-order loss is opposed; same signs are not.
    assert opposed(12, -3) and opposed(-2, 5)
    assert not opposed(12, 3) and not opposed(12, 0) and not opposed(0, -4)
    run11.self_test()


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    if sys.argv[1:] == ["--early-look"]:
        first = early_window(ARMS["B"])
        if first is None:
            print(f"arm B: the look is not taken yet: the first {EARLY_LOOK} samples started "
                  "(toolchain voids left out) are not all there with final.md")
            return None
        kinds = [(void_kind(d) and f"{void_kind(d)} ({', '.join(void_causes(d))})"
                  if void_kind(d) == "rule" else "valid") for d in first]
        print(f"arm B: {sum(audit_void(d) for d in first)} audit voids of the first {len(first)} started "
              f"(toolchain voids left out): " + ", ".join(f"{d.name} {k}" for d, k in zip(first, kinds))
              + f"; stop at {EARLY_LIMIT} of {EARLY_LOOK}: " + ("STOP" if early_stop(ARMS["B"]) else "continue"))
        return None
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
    u, p_primary = mann_whitney_greater(col(b, 2), col(a, 2))
    print(f"\nPrimary: tasks passed after round 2, B > A: sums A {sum(col(a, 2))} "
          f"B {sum(col(b, 2))}; U_B = {u}, one-sided exact p = {p_primary:.4f}")
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
    st = {arm: [final_passed(d) for d in started(path)] for arm, path in ARMS.items()}
    u, p_start = mann_whitney_greater(st["B"], st["A"])
    print(f"Co-primary (start order): tasks passed by the first {N_PER_ARM} started samples per arm, rule "
          f"voids scored on their third answer, B > A: sums A {sum(st['A'])} B {sum(st['B'])}; "
          f"U_B = {u}, one-sided exact p = {p_start:.4f}")
    if opposed(sum(col(b, 2)) - sum(col(a, 2)), sum(st["B"]) - sum(st["A"])):
        print("The start-order analysis points the other way from the primary.")
    print("Gain claimed (both co-primaries significant, B > A): "
          + ("yes" if gain_claimed(p_primary, p_start) else "no"))
    for arm, path in ARMS.items():
        kinds = [void_kind(d) for d in samples(path)]
        print(f"Voids, arm {arm}: {kinds.count('rule')} rule and {kinds.count('toolchain')} "
              f"toolchain of {len(kinds)} started")
    for arm, path in ARMS.items():
        n, void = status_leaks(path)
        print(f"Secondary 5: arm {arm} samples shown another author's task_status: {n}, "
              f"of them void: {void}")
    ay, by = sum(x > 0 for x in col(a, 2)), sum(x > 0 for x in col(b, 2))
    print(f"Reported only: samples passing >= 1 task after round 2: A {ay}/{len(a)} B {by}/{len(b)}; "
          f"one-sided Fisher p = {fisher_greater(by, len(b), ay, len(a)):.4f}")


if __name__ == "__main__":
    main()
