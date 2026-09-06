#!/usr/bin/env python3
"""Execute the documented language workflow; no mocks or skipped toolchains.

These are implementation regression fixtures, not evidence of independent
agent authorship. The original authored corpus remains separately pinned.
"""
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

import mvp_agent_gate as gate


CASES = (
    ("choose-increment.firth", "main", [41, True], [42]),
    ("choose-increment.firth", "main", [41, False], [41]),
    ("choose-increment.firth", "increment", [9], [10]),
    ("choose-increment.firth", "unused", [], [999]),
    ("double.firth", "main", [21], [42]),
    ("double.firth", "main", [True, 21], [True, 42]),
    ("double.firth", "main", [0], [0]),
    ("qualified-call.firth", "main", [41], [42]),
    ("locals-add.firth", "main", [20, 22], [42]),
)


def main() -> int:
    try:
        gate.build_toolchain()
        results = []
        with tempfile.TemporaryDirectory(prefix="firth-language-examples-") as directory:
            workspace = Path(directory)
            for index, (filename, entry, stack, expected) in enumerate(CASES):
                source = gate.ROOT / "examples/mvp" / filename
                result = gate.rebuild(
                    {"name": f"case-{index}", "entry": entry, "source": str(source), "source_path": filename},
                    workspace, stack=stack,
                )
                if result["stack"] != gate.initial_values(expected):
                    gate.fail(f"{filename}/{entry}: expected {expected}, observed {result['stack']}")
                if index in (0, 1, 7) and result["cost"] <= result["kernel_cost"]:
                    gate.fail(f"{filename}: dictionary-call overhead was not exercised")
                results.append({"source": filename, "entry": entry, "stack": expected})

            source = gate.ROOT / "examples/mvp/choose-increment.firth"
            refused = [
                ("missing", [41, True], "unknown checked word"),
                ("main", [41], "input count"),
                ("main", [True, True], "type mismatch"),
                ("main", [-1, True], "initial stack"),
            ]
            for index, (entry, stack, reason) in enumerate(refused):
                try:
                    gate.rebuild({"name": f"invalid-input-{index}", "entry": entry,
                                  "source": str(source), "source_path": source.name}, workspace, stack=stack)
                except gate.GateError as error:
                    if reason not in str(error):
                        raise
                else:
                    gate.fail(f"invalid entry/input was accepted: {entry} {stack}")

            for index, (text, reason) in enumerate((
                (": main ( -- n:Int ) true;", "elaborate"),
                (": main ( -- ) main;", "fuel-exhausted"),
                (": main ( -- n:Int ) 9223372036854775807 1 prim +;", "primitive-fault"),
            )):
                source = workspace / f"rejected-{index}.firth"
                source.write_text(text, encoding="utf-8")
                try:
                    gate.rebuild({"name": f"invalid-program-{index}", "entry": "main",
                                  "source": str(source), "source_path": source.name}, workspace, fuel=16)
                except gate.GateError as error:
                    if reason not in str(error):
                        raise
                else:
                    gate.fail(f"invalid or bounded-out program was accepted: {index}")

        # Run the documented commands too, rather than only calling their library.
        source = "examples/mvp/choose-increment.firth"
        for command in (
            [sys.executable, "tools/loop/firth_run.py", "check", source],
            [sys.executable, "tools/loop/firth_run.py", "run", source,
             "--entry", "main", "--stack", "[41, true]"],
        ):
            output = gate.run(command, cwd=gate.ROOT, stdin=None, timeout=120)
            result = json.loads(output)
            if result.get("status") != "success":
                gate.fail("documented command did not succeed")
            if result["command"] == "run" and result["stack"] != [42]:
                gate.fail("documented run command did not return 42")
        print(json.dumps({"status": "ok", "successful_cases": results,
                          "refused_cases": 7, "documented_cli_commands": 2}, sort_keys=True))
        return 0
    except (gate.GateError, OSError, UnicodeError, json.JSONDecodeError) as error:
        print(json.dumps({"status": "error", "error": str(error)}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
