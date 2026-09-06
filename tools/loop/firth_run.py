#!/usr/bin/env python3
"""Check or execute Firth source through the checked portable toolchain."""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
from pathlib import Path

import mvp_agent_gate as gate


def parser() -> argparse.ArgumentParser:
    cli = argparse.ArgumentParser(description=__doc__)
    commands = cli.add_subparsers(dest="command", required=True)
    check = commands.add_parser("check", help="parse and check all definitions without executing")
    check.add_argument("source", type=Path)
    run = commands.add_parser("run", help="check, compile and compare VM/reference execution")
    run.add_argument("source", type=Path)
    run.add_argument("--entry", required=True, help="source word name, for example main or app.main")
    run.add_argument("--stack", default="[]", help="JSON array of integers/booleans, bottom to top")
    run.add_argument("--fuel", type=int, default=4096, help="finite step budget, 0 to 100000")
    return cli


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        source = args.source.resolve(strict=True)
        if not source.is_file():
            gate.fail("source: expected a UTF-8 file")
        # Reject malformed external values before invoking a toolchain.
        stack = json.loads(args.stack) if args.command == "run" else []
        gate.initial_values(stack)
        if args.command == "run" and not 0 <= args.fuel <= 100000:
            gate.fail("fuel: expected an integer from 0 to 100000")
        gate.build_toolchain()
        with tempfile.TemporaryDirectory(prefix="firth-run-") as directory:
            workspace = Path(directory)
            if args.command == "check":
                scratch = workspace / source.name
                shutil.copyfile(source, scratch)
                response = gate.adapter(
                    [str(gate.LEAN_BIN / "firthElaborate")],
                    {"request_id": "check", "source_path": source.name,
                     "source_text": scratch.read_text(encoding="utf-8"),
                     "language_version": gate.LANGUAGE_VERSION, "gamma_version": gate.GAMMA_VERSION},
                    workspace, "check",
                )
                gate.expect_status(response, "success", "check")
                result = {"status": "success", "command": "check",
                          "words": list(gate.checked_dictionary(response)),
                          "warnings": response.get("warnings", [])}
            else:
                observation = gate.rebuild(
                    {"name": "application", "entry": args.entry,
                     "source": str(source), "source_path": source.name},
                    workspace, stack=stack, fuel=args.fuel,
                )
                values = []
                for value in observation["stack"]:
                    if value.get("kind") != "literal" or value.get("literal", {}).get("type") not in ("nat", "bool"):
                        gate.fail("result: this runner only exposes integer and Boolean results")
                    values.append(value["literal"]["value"])
                result = {"status": "success", "command": "run", "entry": observation["entry"],
                          "stack": values, "words": observation["words"], "fuel": observation["fuel"],
                          "kernel_cost": observation["kernel_cost"], "vm_cost": observation["cost"]}
        print(json.dumps(result, sort_keys=True))
        return 0
    except (gate.GateError, OSError, UnicodeError, json.JSONDecodeError) as error:
        print(json.dumps({"status": "error", "error": str(error)}, sort_keys=True), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
