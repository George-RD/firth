#!/usr/bin/env python3
"""Run the public VM execution and transport bound regressions under deadlines.

Each case of `src/runtime/vm/tests/bounds.rs` runs in its own subprocess: the
recursion case aborts the whole test process on the unchanged runtime, and the
flat-word and maximal-object cases exceed their deadlines there. The baseline
mode is only a reproducer. Its success means the old defects were observed; it
must never be used as a product acceptance gate.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
CRATE = ROOT / "src/runtime/vm"
RECURSION_CASE = "self_recursion_at_gate_fuel_traps_with_call_depth_exceeded"
# Deadlines in seconds for an unoptimised build on a shared host. The unchanged
# runtime took over a minute for each of these two cases.
DEADLINE_CASES = {
    "a_flat_word_at_gate_fuel_executes_within_the_deadline": 30,
    "a_maximal_member_object_parses_within_the_deadline": 30,
}
RECURSION_DEADLINE = 60


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def classify(returncode: int) -> str:
    if returncode == 0:
        return "passed"
    # A native stack overflow ends the process with SIGABRT: a negative status
    # from the subprocess module, or 134 through an intermediate shell.
    if returncode < 0 or returncode == 134:
        return "aborted"
    return "failed"


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--expect-vulnerable", action="store_true")
    cli.add_argument("--no-default-features", action="store_true")
    cli.add_argument("--artifacts", type=Path)
    args = cli.parse_args()
    directory = args.artifacts or Path(tempfile.mkdtemp(prefix="firth-bounds-"))
    directory.mkdir(parents=True, exist_ok=True)
    mode = "baseline-reproduction" if args.expect_vulnerable else "candidate-acceptance"
    report: dict = {"mode": mode, "no_default_features": args.no_default_features, "cases": []}
    try:
        command = ["cargo", "test", "--locked", "--test", "bounds", "--no-run", "--message-format=json"]
        if args.no_default_features:
            command.append("--no-default-features")
        build = subprocess.run(command, cwd=CRATE, capture_output=True, text=True, timeout=600)
        (directory / "build.stdout").write_text(build.stdout)
        (directory / "build.stderr").write_text(build.stderr)
        if build.returncode:
            raise RuntimeError("bounds test binary did not build")
        executables = []
        for line in build.stdout.splitlines():
            value = json.loads(line)
            if value.get("reason") == "compiler-artifact" and value.get("target", {}).get("name") == "bounds" \
                    and value.get("executable") and value.get("profile", {}).get("test"):
                executables.append(value["executable"])
        if len(executables) != 1:
            raise RuntimeError("expected exactly one bounds integration-test binary")
        executable = Path(executables[0])
        listing = subprocess.run([str(executable), "--list", "--format", "terse"],
                                 capture_output=True, text=True, check=True, timeout=10)
        cases = [line.removesuffix(": test") for line in listing.stdout.splitlines() if line.endswith(": test")]
        required = {RECURSION_CASE, *DEADLINE_CASES}
        if not required <= set(cases):
            raise RuntimeError("required bounds reproducers are missing")
        if set(cases) != required:
            raise RuntimeError("the bounds suite holds a case this gate does not classify")
        report["binary_sha256"] = digest(executable)
        report["regressions_sha256"] = digest(CRATE / "tests/bounds.rs")
        report["rust_toolchain_sha256"] = digest(ROOT / "rust-toolchain.toml")
        revision = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT,
                                  capture_output=True, text=True, check=True, timeout=10)
        report["git_revision"] = revision.stdout.strip()
        for case in sorted(cases):
            # Run the compiled binary rather than cargo so the deadline covers
            # the runtime, not compilation or shared build locks, and so an
            # abort takes down only this one case.
            timeout = DEADLINE_CASES.get(case, RECURSION_DEADLINE)
            with (directory / (case + ".stdout")).open("wb") as stdout, \
                    (directory / (case + ".stderr")).open("wb") as stderr:
                try:
                    run = subprocess.run([str(executable), case, "--exact", "--nocapture", "--test-threads", "1"],
                                         cwd=CRATE, stdout=stdout, stderr=stderr, timeout=timeout)
                    outcome, exit_code = classify(run.returncode), run.returncode
                except subprocess.TimeoutExpired:
                    outcome, exit_code = "deadline-exceeded", None
            expected = "passed"
            if args.expect_vulnerable:
                expected = "aborted" if case == RECURSION_CASE else "deadline-exceeded"
            report["cases"].append({"case": case, "outcome": outcome, "expected": expected,
                                    "exit_code": exit_code, "deadline_seconds": timeout})
        report["status"] = "ok" if all(row["outcome"] == row["expected"] for row in report["cases"]) else "failed"
        # Repeat executions remain reviewable rather than overwriting evidence.
        with tempfile.NamedTemporaryFile(mode="w", prefix="summary-", suffix=".json",
                                         dir=directory, delete=False) as stream:
            json.dump(report, stream, sort_keys=True, indent=2)
            stream.write("\n")
        print(json.dumps(report, sort_keys=True))
        return 0 if report["status"] == "ok" else 1
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(json.dumps({"status": "error", "mode": mode, "error": str(error)}), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
