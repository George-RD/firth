#!/usr/bin/env python3
"""Run every case in cases.json on the VM and the reference interpreter.

Each case is checked, compiled and executed through the same portable
toolchain as `tools/loop/firth_run.py run`; the gate there compares the two
hosts' results, costs and traces. This script only adds the expected final
stack, so a program that both hosts agree on but that computes the wrong
answer still fails.
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
                )
            except gate.GateError as error:
                print(f"FAIL {label}: {str(error)[:300]}")
                failures += 1
                continue
        stack = [value["literal"]["value"] for value in observation["stack"]]
        if stack != case["expect"]:
            print(f"FAIL {label}: expected {case['expect']}, both hosts gave {stack}")
            failures += 1
        else:
            print(f"ok   {label} -> {stack} (kernel cost {observation['kernel_cost']})")
    print(f"{len(cases) - failures}/{len(cases)} programs agree with their expected results")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
