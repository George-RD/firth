#!/usr/bin/env python3
"""Run 13 as it stopped: a description, not the pre-registered tests.

Usage, from eval/s7:
  python3 runs/2026-09-30-check-forms/describe.py
  python3 runs/2026-09-30-check-forms/describe.py --self-test

Run 13 stopped at its pre-registered early look (7 audit voids in the first
10 arm B samples; `analyse.py --early-look`), so `analyse.py` refuses to run
and there is no primary result. As the pre-registration asks of a stopped
run, this prints every sample's scores and no test. It also prints each arm B
audit void's refused calls, grouped by cause, and two counterfactuals that
are hand-set, not scored:

- Reads of the harness's `tool-results` files allowed. The harness saves a
  long tool output there and tells the author the path. The write-up checks
  from the raw logs that each such file held that author's own check output;
  this script cannot, since the logs are not in the repository.
- Refused calls blocked before they run instead of voiding the sample
  afterwards. No sample is then an audit void; what is left is its other
  causes.

The refused Bash calls are found again here from `bash-calls.json`, which
keeps every command verbatim, with the audit's own pattern
(`audit_subagent.check_command`, `--shell-forms`), and checked against the
count in the audit's `transcript.json`.
"""
import importlib.util
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1]))
from audit_subagent import check_command  # noqa: E402

_spec = importlib.util.spec_from_file_location("run13_analyse", HERE / "analyse.py")
run13 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(run13)

# Where the pinned worktree was during authoring (pinned.txt).
WORKTREE = Path("/home/user/firth-r13")
HARNESS = WORKTREE / "eval/s7/harness.py"
RUN = WORKTREE / "eval/s7/runs/2026-09-30-check-forms"
TOOL_RESULTS = re.compile(r"/root/\.claude/projects/(?:[^/]+/)+tool-results/[^/]+\.txt")


def classify(tool, text, own_dir):
    """The cause group of one refused call: `shell form` (a check command with
    a form outside the allowlist), `harness file` (a Read of a harness
    tool-results file) or `other`, with a short detail."""
    if tool == "Read":
        if TOOL_RESULTS.fullmatch(text):
            return "harness file", "Read of a tool-results file"
        if text.rstrip("/") == str(own_dir):
            return "other", "Read of its own directory"
        return "other", "Read of another path"
    if re.search(r"harness\.py check\b", text):
        return "shell form", "check with a form outside the allowlist"
    if re.search(r"harness\.py (run|try|score|extract|prompt|repair|report)\b", text):
        return "other", "another harness subcommand"
    if "<<" in text and "/tmp/" in text:
        return "other", "heredoc script in /tmp"
    paths = re.findall(r"/[\w./-]+", text)
    if paths and all(p.rstrip("/").startswith(str(own_dir)) for p in paths):
        return "other", "its own files read by another command"
    return "other", "another command"


def refused_calls(d):
    """Every refused call of an arm B sample, in log order: (time, tool, text)."""
    rx = check_command(HARNESS, RUN / "arm-b" / d.name, shell_forms=True)
    calls = json.loads((d / "bash-calls.json").read_text())["calls"]
    bash = [(c["at"], "Bash", c["command"]) for c in calls
            if not (rx.fullmatch(c["command"]) and int(rx.fullmatch(c["command"])[1]) <= 3)]
    flagged = json.loads((d / "transcript.json").read_text())["flagged"]
    reads = [(None, "Read", json.loads(f[len("Read: "):])["file_path"])
             for f in flagged if f.startswith("Read: ")]
    n_bash = sum(f.startswith("Bash: ") for f in flagged)
    if n_bash != len(bash):
        raise SystemExit(f"{d.name}: {len(bash)} refused Bash calls found, the audit flagged {n_bash}")
    return bash + reads


def scores(d):
    return [run13.passed(d / f"results-{r}.json") if (d / f"results-{r}.json").is_file() else None
            for r in (1, 2, 3)]


def main():
    for arm, path in run13.ARMS.items():
        print(f"arm {arm}")
        for d in run13.samples(path):
            kind = run13.void_kind(d)
            label = f"{kind} ({', '.join(run13.void_causes(d))})" if kind == "rule" else (kind or "valid")
            runs = sum(run13.check_calls(d / "transcript.json").values()) if arm == "B" else None
            shown = ", ".join("-" if x is None else str(x) for x in scores(d))
            print(f"  {d.name:15} {label:26} passed by answer: {shown}"
                  + (f"; checker runs {runs}" if runs is not None else ""))
        finals = [run13.final_passed(d) for d in run13.started(path)]
        print(f"  third answers, all {len(finals)} started samples: sum {sum(finals)}")
        n, void = run13.status_leaks(path)
        print(f"  secondary 5: shown another author's task_status {n}, of them void {void}")
    print("\nArm B audit voids: refused calls by cause")
    stand_cf1 = []
    audit_voids = [d for d in run13.samples(run13.ARMS["B"]) if run13.audit_void(d)]
    for d in audit_voids:
        own = RUN / "arm-b" / d.name
        groups = {}
        for _, tool, text in refused_calls(d):
            group, detail = classify(tool, text, own)
            groups.setdefault(group, []).append(detail)
        print(f"  {d.name}: " + "; ".join(f"{g} {len(v)} ({', '.join(sorted(set(v)))})"
                                         for g, v in sorted(groups.items())))
        if set(groups) - {"harness file"}:
            stand_cf1.append(d.name)
    print(f"\nCounterfactual, hand-set, not scored: harness tool-results Reads allowed: "
          f"{len(stand_cf1)} of {len(audit_voids)} audit voids stand ({', '.join(stand_cf1)})")
    rest = {d.name: [c for c in run13.void_causes(d) if c != "audit"] for d in audit_voids}
    still = [f"{n} ({', '.join(c)})" for n, c in rest.items() if c]
    print(f"Counterfactual, hand-set, not scored: refused calls blocked instead of voided: "
          f"0 of {len(audit_voids)} audit voids; still void for another cause: "
          f"{len(still)} ({'; '.join(still)})")


def self_test():
    own = Path("/w/run/arm-b/haiku-firth-1")
    plants = [
        (("Bash", f"python3 /w/harness.py check --lang firth {own}/answer-1.md | wc -l"), "shell form"),
        (("Read", "/root/.claude/projects/-home-user/s/tool-results/b1.txt"), "harness file"),
        (("Read", "/root/.claude/projects/-home-user/s/other.txt"), "other"),
        (("Bash", f"grep -n x {own}/answer-1.md"), "other"),
        (("Bash", f"cd /w && python3 /w/harness.py score --lang firth {own}/answer-2.md"), "other"),
        (("Bash", "cat > /tmp/f.py << 'EOF'\nprint(1)\nEOF\npython3 /tmp/f.py"), "other"),
    ]
    for (tool, text), want in plants:
        got = classify(tool, text, own)[0]
        assert got == want, (tool, text, got, want)
    assert classify("Bash", f"grep -n x {own}/answer-1.md", own)[1] == "its own files read by another command"
    assert classify("Bash", "grep -n x /w/run/arm-b/haiku-firth-2/answer-1.md", own)[1] == "another command"
    print("describe.py self-test: ok")


if __name__ == "__main__":
    self_test() if sys.argv[1:] == ["--self-test"] else main()
