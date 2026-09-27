#!/usr/bin/env python3
"""Check, run or test Firth source through the checked portable toolchain."""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
from pathlib import Path

import mvp_agent_gate as gate


MAX_SUITE_BYTES = 1024 * 1024
MAX_TEST_CASES = 128
MAX_TEST_STACK = 256


def parser() -> argparse.ArgumentParser:
    cli = argparse.ArgumentParser(description=__doc__)
    commands = cli.add_subparsers(dest="command", required=True)
    check = commands.add_parser("check", help="parse and check all definitions without executing")
    check.add_argument("source", type=Path)
    run = commands.add_parser("run", help="check, compile and compare VM/reference execution")
    run.add_argument("source", type=Path)
    run.add_argument("--entry", required=True, help="source word name, for example main or app.main")
    run.add_argument("--stack", default="[]", help="JSON array of integers/booleans, bottom to top")
    run.add_argument("--fuel", type=int, default=gate.FUEL,
                     help=f"finite step budget, 0 to {gate.MAX_FUEL}")
    test = commands.add_parser("test", help="compare saved input/output cases on both hosts")
    test.add_argument("suite", type=Path)
    test.add_argument("--fuel", type=int, default=gate.FUEL,
                      help=f"finite per-case step budget, 0 to {gate.MAX_FUEL}")
    return cli


def parse_stack(text: str) -> list:
    """Decode the external `--stack` value, refusing anything Python's decoder
    cannot represent as a bounded portable input, including nesting deep
    enough to exhaust the decoder's recursion."""
    try:
        return json.loads(text)
    except (ValueError, RecursionError) as error:
        gate.fail(f"stack: not an accepted JSON array ({type(error).__name__})")
    raise AssertionError("unreachable")


def suite_object(pairs: list[tuple[str, object]]) -> dict:
    """Reject ambiguous JSON rather than accepting its last duplicate member."""
    result = {}
    for key, value in pairs:
        if key in result:
            gate.fail(f"suite: duplicate JSON member {key!r}")
        result[key] = value
    return result


def suite_constant(value: str) -> None:
    gate.fail(f"suite: non-finite JSON value {value}")


def exact_fields(value: object, fields: set[str], label: str) -> None:
    if not isinstance(value, dict) or set(value) != fields:
        gate.fail(f"{label}: expected exactly {', '.join(sorted(fields))}")


def load_suite(path: Path) -> tuple[Path, list[dict]]:
    """Validate the whole suite before invoking a toolchain or running a case."""
    with path.open("rb") as stream:
        raw = stream.read(MAX_SUITE_BYTES + 1)
    if len(raw) > MAX_SUITE_BYTES:
        gate.fail(f"suite: exceeds {MAX_SUITE_BYTES} bytes")
    try:
        suite = json.loads(raw.decode("utf-8"), object_pairs_hook=suite_object,
                           parse_constant=suite_constant)
    except (ValueError, RecursionError) as error:
        gate.fail(f"suite: invalid JSON ({type(error).__name__})")
    exact_fields(suite, {"schema", "source", "cases"}, "suite")
    if suite["schema"] != "firth.tests.v1":
        gate.fail("suite: unsupported schema; expected firth.tests.v1")
    source_name = suite["source"]
    if not isinstance(source_name, str) or not source_name.strip() or "\0" in source_name:
        gate.fail("suite.source: expected a non-empty relative file path")
    if Path(source_name).is_absolute():
        gate.fail("suite.source: expected a relative file path")
    source = (path.resolve().parent / source_name).resolve(strict=True)
    if not source.is_file():
        gate.fail("suite.source: expected a UTF-8 file")
    cases = suite["cases"]
    if not isinstance(cases, list) or not 1 <= len(cases) <= MAX_TEST_CASES:
        gate.fail(f"suite.cases: expected 1 to {MAX_TEST_CASES} cases")
    names = set()
    for index, case in enumerate(cases):
        label = f"suite.cases[{index}]"
        exact_fields(case, {"name", "entry", "stack", "expected_stack"}, label)
        for field in ("name", "entry"):
            if not isinstance(case[field], str) or not case[field].strip():
                gate.fail(f"{label}.{field}: expected a non-empty string")
        if case["name"] in names:
            gate.fail(f"{label}.name: duplicate case name {case['name']!r}")
        names.add(case["name"])
        for field in ("stack", "expected_stack"):
            values = case[field]
            if not isinstance(values, list) or len(values) > MAX_TEST_STACK:
                gate.fail(f"{label}.{field}: expected an array of at most {MAX_TEST_STACK} values")
            try:
                gate.initial_values(values)
            except gate.GateError as error:
                gate.fail(f"{label}.{field}: {error}")
    return source, cases


def snapshot_source(source: Path) -> bytes:
    """Read the suite source once so every case runs the same validated text."""
    raw = source.read_bytes()
    try:
        raw.decode("utf-8")
    except UnicodeDecodeError:
        gate.fail("suite.source: expected a UTF-8 file")
    return raw


def test_suite(path: Path, fuel: int) -> dict:
    if type(fuel) is not int or not 0 <= fuel <= gate.MAX_FUEL:
        gate.fail(f"fuel: expected an integer from 0 to {gate.MAX_FUEL}")
    source, cases = load_suite(path)
    snapshot = snapshot_source(source)
    gate.build_toolchain()
    results = []
    with tempfile.TemporaryDirectory(prefix="firth-test-") as directory:
        workspace = Path(directory)
        frozen = workspace / "source" / source.name
        frozen.parent.mkdir()
        frozen.write_bytes(snapshot)
        for index, case in enumerate(cases):
            result = {"name": case["name"], "entry": case["entry"],
                      "expected_stack": case["expected_stack"]}
            try:
                observation = gate.rebuild(
                    {"name": f"case-{index}", "entry": case["entry"],
                     "source": str(frozen), "source_path": source.name},
                    workspace, stack=case["stack"], fuel=fuel,
                )
                gate.validate_portable_stack(observation["stack"], f"case {index} result")
                result.update(stack=[value["literal"]["value"] for value in observation["stack"]],
                              kernel_cost=observation["kernel_cost"],
                              vm_cost=observation["cost"],
                              trace_comparison=observation["trace_comparison"])
                # Compare typed literals, not Python scalars (True == 1).
                if observation["stack"] != gate.initial_values(case["expected_stack"]):
                    gate.fail("expected stack does not match the observed typed stack")
                result["status"] = "passed"
            except (gate.GateError, OSError, UnicodeError) as error:
                result.update(status="failed", error=str(error))
            results.append(result)
    failed = sum(result["status"] == "failed" for result in results)
    return {"schema": "firth.test-results.v1", "status": "failure" if failed else "success",
            "command": "test", "source": str(source), "fuel": fuel,
            "passed": len(results) - failed, "failed": failed, "cases": results}


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "test":
            result = test_suite(args.suite, args.fuel)
            print(json.dumps(result, sort_keys=True))
            return 1 if result["failed"] else 0
        source = args.source.resolve(strict=True)
        if not source.is_file():
            gate.fail("source: expected a UTF-8 file")
        # Reject malformed external values before invoking a toolchain.
        stack = parse_stack(args.stack) if args.command == "run" else []
        gate.initial_values(stack)
        if args.command == "run" and not 0 <= args.fuel <= gate.MAX_FUEL:
            gate.fail(f"fuel: expected an integer from 0 to {gate.MAX_FUEL}")
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
                          "kernel_cost": observation["kernel_cost"], "vm_cost": observation["cost"],
                          "trace_comparison": observation["trace_comparison"]}
        print(json.dumps(result, sort_keys=True))
        return 0
    except (gate.GateError, OSError, UnicodeError, json.JSONDecodeError) as error:
        print(json.dumps({"status": "error", "error": str(error)}, sort_keys=True), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
