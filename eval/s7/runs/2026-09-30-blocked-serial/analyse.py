#!/usr/bin/env python3
"""Run 14's pre-registered analysis (preregistration.md): run 13's, with run 14's early look.

Usage, from eval/s7: python3 runs/2026-09-30-blocked-serial/analyse.py [--self-test | --early-look]

The driver runs this file, in this run directory, once it has copied every
session's samples from the shared folder into `arm-a/` and `arm-b/`. The
tests, the counted and start-order sets, the co-primary rule and the
secondaries are run 13's (`../2026-09-30-check-forms/analyse.py`), applied
to this directory. Run 14 changes two things:

- The early look counts rule voids of any cause among the first 10 arm B
  samples in start order (run 13 counted audit voids only), and stops at 6.
- It adds the reports run 14 pre-registers: voids by cause per arm, context
  compactions per sample (secondary 5, a covariate) and calls the hook
  stopped (secondary 6), each per arm and without a test.

`void.md` and `final.md` are written by `session.py` (`write_void`,
`write_toolchain`, `write_final`); the self-test runs its writers into this
file's readers, end to end.
"""
import contextlib
import importlib.util
import io
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ARMS = {"A": HERE / "arm-a", "B": HERE / "arm-b"}


def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


r13 = _load("run13_analyse", HERE.parent / "2026-09-30-check-forms" / "analyse.py")
CAUSES, EARLY_LOOK, EARLY_LIMIT = r13.CAUSES, r13.EARLY_LOOK, r13.EARLY_LIMIT
samples, void_kind, void_causes, early_window = r13.samples, r13.void_kind, r13.void_causes, r13.early_window


def rule_void(d):
    return void_kind(d) == "rule"


def early_stop(arm_dir, look=EARLY_LOOK, limit=EARLY_LIMIT):
    """None until the first `look` arm B samples started (toolchain voids left
    out) all have final.md; then True when `limit` or more are rule voids of
    any cause. It reads void status only."""
    first = early_window(arm_dir, look)
    if first is None:
        return None
    return sum(rule_void(d) for d in first) >= limit


def early_look(arms):
    first = early_window(arms["B"])
    if first is None:
        return (f"arm B: the look is not taken yet: the first {EARLY_LOOK} samples started "
                "(toolchain voids left out) are not all there with final.md")
    kinds = [f"rule ({', '.join(void_causes(d))})" if rule_void(d) else "valid" for d in first]
    return (f"arm B: {sum(rule_void(d) for d in first)} rule voids of the first {len(first)} started "
            f"(toolchain voids left out): " + ", ".join(f"{d.name} {k}" for d, k in zip(first, kinds))
            + f"; stop at {EARLY_LIMIT} of {EARLY_LOOK}: " + ("STOP" if early_stop(arms["B"]) else "continue"))


def by_cause(arm_dir):
    out = {c: 0 for c in CAUSES}
    out["toolchain"] = 0
    for d in samples(arm_dir):
        if void_kind(d) == "toolchain":
            out["toolchain"] += 1
        elif rule_void(d):
            for c in void_causes(d):
                out[c] += 1
    return out


def per_sample(arm_dir, name, key):
    vals = []
    for d in samples(arm_dir):
        f = d / name
        if f.is_file():
            v = json.loads(f.read_text()).get(key, 0)
            vals.append(len(v) if isinstance(v, list) else int(v))
    return vals


def run14_reports(arms):
    lines = []
    for arm, path in arms.items():
        c = by_cause(path)
        lines.append(f"Voids by cause, arm {arm} (a sample can have several): "
                     + ", ".join(f"{k} {v}" for k, v in c.items()))
    for arm, path in arms.items():
        comp = per_sample(path, "context-seen.json", "compactions")
        lines.append(f"Secondary 5: arm {arm} compactions per sample: total {sum(comp)} over {len(comp)} "
                     f"samples, {sum(x > 0 for x in comp)} compacted")
    for arm, path in arms.items():
        blocked = per_sample(path, "transcript.json", "blocked_calls")
        lines.append(f"Secondary 6: arm {arm} calls the hook stopped: total {sum(blocked)} over "
                     f"{len(blocked)} samples, {sum(x > 0 for x in blocked)} samples with one or more")
    return "\n".join(lines)


def analysis(arms):
    """Run 13's analysis on `arms`, then run 14's reports, as text."""
    saved = r13.ARMS
    r13.ARMS = arms
    out = io.StringIO()
    try:
        argv, sys.argv = sys.argv, [sys.argv[0]]
        with contextlib.redirect_stdout(out):
            r13.main()
    finally:
        r13.ARMS, sys.argv = saved, argv
    return out.getvalue() + run14_reports(arms)


def self_test():
    import tempfile
    session = _load("run14_session", HERE / "session.py")
    # session.py's writers into these readers: a void over two rounds with
    # three causes, merged into one header; a toolchain void; a valid sample.
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        session.write_void(d, ["audit"], 1, "2026-10-01T10:11:12Z", ["off the list: Glob"])
        session.write_void(d, ["context", "agent-files"], 2, "2026-10-01T10:21:22Z", [])
        session.write_final(d, "2026-10-01T10:31:32Z")
        assert void_kind(d) == "rule" and void_causes(d) == ["audit", "agent-files", "context"], \
            (d / "void.md").read_text()
        assert "round 1 at" in (d / "void.md").read_text() and "off the list" in (d / "void.md").read_text()
        (d / "void.md").unlink()
        session.write_toolchain(d, "lake: exit 1", "2026-10-01T10:41:42Z")
        assert void_kind(d) == "toolchain" and (d / "final.md").read_text().startswith("toolchain: stopped")
    # End to end on synthetic samples: 50 started per arm, arm B passing more.
    # Arm B's first 10 hold 5 rule voids (one of them context only), then 6.
    with tempfile.TemporaryDirectory() as tmp:
        arms = {"A": Path(tmp) / "arm-a", "B": Path(tmp) / "arm-b"}
        tasks = [f"t{i}" for i in range(20)]

        def sample(arm, n, final, void=None):
            d = arms[arm] / f"haiku-firth-{n}"
            d.mkdir(parents=True)
            for r, k in ((1, max(final - 3, 0)), (2, max(final - 1, 0)), (3, final)):
                (d / f"results-{r}.json").write_text(json.dumps({"tasks": {
                    t: {"cases": [{"pass": i < k, "error": None if i < k else "code: firth.x"}]}
                    for i, t in enumerate(tasks)}}))
                (d / f"solutions-{r}.json").write_text(json.dumps({t: "src" for t in tasks}))
            calls = [{"tool": "Bash", "check": "answer-1.md"}] * (3 if arm == "B" else 0)
            (d / "transcript.json").write_text(json.dumps({"tool_calls": calls, "blocked_calls": n % 2}))
            (d / "context-seen.json").write_text(json.dumps({"injected": [], "compactions": [{}] * (arm == "B")}))
            if void:
                session.write_void(d, void, 1, "2026-10-01T10:00:00Z", [])
            session.write_final(d, "2026-10-01T11:00:00Z")

        for n in range(1, 51):
            sample("A", n, 5 + n % 3)
            sample("B", n, 9 + n % 4, [["audit"], ["context"], ["agent-files", "audit"], ["audit"],
                                        ["context"]][n - 1] if n <= 5 else None)
        look = early_look(arms)
        assert early_stop(arms["B"]) is False and "5 rule voids" in look and "continue" in look, look
        session.write_void(arms["B"] / "haiku-firth-6", ["context"], 2, "2026-10-01T12:00:00Z", [])
        look = early_look(arms)
        assert early_stop(arms["B"]) is True and "6 rule voids" in look and "STOP" in look, look
        (arms["B"] / "haiku-firth-7" / "final.md").unlink()
        assert early_stop(arms["B"]) is None and "not taken yet" in early_look(arms)
        session.write_final(arms["B"] / "haiku-firth-7", "2026-10-01T12:10:00Z")
        text = analysis(arms)
        assert "arm A: 40 counted samples" in text and "arm B: 40 counted samples" in text, text
        assert "Gain claimed (both co-primaries significant, B > A): yes" in text, text
        assert "Voids by cause, arm B (a sample can have several): audit 3, agent-files 1, context 3" in text, text
        assert "Secondary 5: arm B compactions per sample: total 50 over 50 samples, 50 compacted" in text, text
        assert "Secondary 6: arm A calls the hook stopped: total 25 over 50 samples" in text, text
        assert r13.ARMS == {"A": r13.HERE / "arm-a", "B": r13.HERE / "arm-b"}, "run 13's ARMS restored"
    # Planted: run 13's early look (audit voids only) would not stop here.
    with tempfile.TemporaryDirectory() as tmp:
        arm = Path(tmp)
        for n in range(1, 11):
            d = arm / f"haiku-firth-{n}"
            d.mkdir()
            if n <= 6:
                session.write_void(d, ["context"], 1, "2026-10-01T10:00:00Z", [])
            session.write_final(d, "2026-10-01T11:00:00Z")
        assert early_stop(arm) is True and r13.early_stop(arm) is False
    print("run 14 analyse.py self-test: ok")


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    if sys.argv[1:] == ["--early-look"]:
        print(early_look(ARMS))
        return None
    print(analysis(ARMS))


if __name__ == "__main__":
    main()
