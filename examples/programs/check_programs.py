#!/usr/bin/env python3
"""Run every case in cases.json on the VM and the reference interpreter.

Each case is checked, compiled and executed through the same portable
toolchain as `tools/loop/firth_run.py run`; the gate there compares the two
hosts' results, costs and traces. This script only adds the expected final
stack, so a program that both hosts agree on but that computes the wrong
answer still fails. A case with `expect_error` must be refused with that
diagnostic code, so a program that must not compile can't start running.
A case with `expect_trap` must stop with that trap on both hosts, at the same
stack and cost.
"""
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / "tools" / "loop"))

import mvp_agent_gate as gate  # noqa: E402


def main() -> int:
    cases = json.loads((HERE / "cases.json").read_text(encoding="utf-8"))["cases"]
    gate.build_toolchain()
    failures = 0
    for index, case in enumerate(cases):
        label = f"{case['source']} {case['entry']} {json.dumps(case['stack'])}"
        with tempfile.TemporaryDirectory(prefix="firth-programs-") as directory:
            try:
                observation = gate.rebuild(
                    {"name": f"case-{index}", "entry": case["entry"],
                     "source": str(HERE / case["source"]), "source_path": case["source"]},
                    Path(directory), stack=case["stack"],
                    expected_trap=case.get("expect_trap"),
                )
            except gate.GateError as error:
                expected_error = case.get("expect_error")
                if expected_error and f"'code': '{expected_error}'" in str(error):
                    print(f"ok   {label} -> refused with {expected_error}")
                else:
                    print(f"FAIL {label}: {str(error)[:300]}")
                    failures += 1
                continue
        if "expect_error" in case:
            print(f"FAIL {label}: expected {case['expect_error']}, but it ran")
            failures += 1
            continue
        stack = [value["literal"]["value"] for value in observation["stack"]]
        if case.get("expect_trap") is not None:
            print(f"ok   {label} -> both hosts trapped with {observation['trap']}")
            continue
        if stack != case["expect"]:
            print(f"FAIL {label}: expected {case['expect']}, both hosts gave {stack}")
            failures += 1
        else:
            print(f"ok   {label} -> {stack} (kernel cost {observation['kernel_cost']})")
    print(f"{len(cases) - failures}/{len(cases)} programs agree with their expected results")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
