#!/usr/bin/env python3
"""Run public VM ingress regressions with a process deadline for validation.

The baseline mode is only a reproducer. Its success means the old defects
were observed; it must never be used as a product acceptance gate.
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
DEEP_CASE = "deepest_valid_code_validates_without_exponential_walk"
BASELINE_FAILURES = {
    "oversized_word_code_is_refused_before_fuel",
    "oversized_dictionary_is_refused_before_lookup",
    "oversized_literal_is_refused_before_hashing",
    "individually_valid_literals_share_one_image_budget",
    "unused_helpers_share_the_image_budget",
    "nested_code_vectors_cannot_bypass_the_limit",
    "quotation_capture_vectors_cannot_bypass_the_limit",
    "initial_stack_count_is_bounded_even_without_instructions",
    "initial_stack_bytes_are_bounded_even_without_instructions",
    "individually_valid_inputs_share_one_stack_budget",
    "nested_input_captures_share_the_stack_budget",
    "unused_initial_capture_indices_are_checked",
    "large_metadata_is_rejected_before_identity_hashing",
    "deepest_valid_capture_matches_the_binary_decoder",
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--expect-vulnerable", action="store_true")
    cli.add_argument("--no-default-features", action="store_true")
    cli.add_argument("--artifacts", type=Path)
    args = cli.parse_args()
    directory = args.artifacts or Path(tempfile.mkdtemp(prefix="firth-ingress-"))
    directory.mkdir(parents=True, exist_ok=True)
    mode = "baseline-reproduction" if args.expect_vulnerable else "candidate-acceptance"
    report: dict = {"mode": mode, "no_default_features": args.no_default_features, "cases": []}
    try:
        command = ["cargo", "test", "--locked", "--test", "ingress", "--no-run", "--message-format=json"]
        if args.no_default_features:
            command.append("--no-default-features")
        build = subprocess.run(command, cwd=CRATE, capture_output=True, text=True, timeout=180)
        (directory / "build.stdout").write_text(build.stdout)
        (directory / "build.stderr").write_text(build.stderr)
        if build.returncode:
            raise RuntimeError("ingress test binary did not build")
        executables = []
        for line in build.stdout.splitlines():
            value = json.loads(line)
            if value.get("reason") == "compiler-artifact" and value.get("target", {}).get("name") == "ingress" \
                    and value.get("executable") and value.get("profile", {}).get("test"):
                executables.append(value["executable"])
        if len(executables) != 1:
            raise RuntimeError("expected exactly one ingress integration-test binary")
        executable = Path(executables[0])
        listing = subprocess.run([str(executable), "--list", "--format", "terse"],
                                 capture_output=True, text=True, check=True, timeout=10)
        cases = [line.removesuffix(": test") for line in listing.stdout.splitlines() if line.endswith(": test")]
        if not BASELINE_FAILURES | {DEEP_CASE} <= set(cases):
            raise RuntimeError("required ingress reproducers are missing")
        report["binary_sha256"] = digest(executable)
        report["regressions_sha256"] = digest(CRATE / "tests/ingress.rs")
        report["rust_toolchain_sha256"] = digest(ROOT / "rust-toolchain.toml")
        revision = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT,
                                  capture_output=True, text=True, check=True, timeout=10)
        report["git_revision"] = revision.stdout.strip()
        if args.expect_vulnerable:
            cases = sorted(BASELINE_FAILURES | {DEEP_CASE})
        for case in cases:
            # Run a compiled binary rather than cargo so the deadline covers
            # the validator, not compilation or shared build locks.
            timeout = 3 if case == DEEP_CASE else 15
            with (directory / (case + ".stdout")).open("wb") as stdout, \
                    (directory / (case + ".stderr")).open("wb") as stderr:
                try:
                    run = subprocess.run([str(executable), case, "--exact", "--nocapture"],
                                         cwd=CRATE, stdout=stdout, stderr=stderr, timeout=timeout)
                    outcome = "passed" if run.returncode == 0 else "failed"
                    exit_code = run.returncode
                except subprocess.TimeoutExpired:
                    outcome, exit_code = "deadline-exceeded", None
            expected = "passed"
            if args.expect_vulnerable:
                expected = "deadline-exceeded" if case == DEEP_CASE else "failed"
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
