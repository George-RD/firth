#!/usr/bin/env python3
"""Public saved-case runner regressions; no installed toolchains required."""
from __future__ import annotations

from contextlib import redirect_stderr, redirect_stdout
from copy import deepcopy
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import firth_run as runner
import mvp_agent_gate as gate


class SavedCaseTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.source = self.root / "double.firth"
        self.source.write_text(": main ( n:Int -- result:Int ) dup prim +;\n", encoding="utf-8")
        self.path = self.root / "double.tests.json"
        self.case = {"name": "ordinary input", "entry": "main", "stack": [21], "expected_stack": [42]}
        self.suite = {"schema": "firth.tests.v1", "source": self.source.name,
                      "cases": [deepcopy(self.case)]}
        self.write()

    def write(self, suite: object | None = None) -> None:
        self.path.write_text(json.dumps(self.suite if suite is None else suite), encoding="utf-8")

    def invoke(self, *extra: str) -> tuple[int, dict | None, dict | None]:
        stdout, stderr = io.StringIO(), io.StringIO()
        with redirect_stdout(stdout), redirect_stderr(stderr):
            code = runner.main(["test", str(self.path), *extra])
        return (code, json.loads(stdout.getvalue()) if stdout.getvalue() else None,
                json.loads(stderr.getvalue()) if stderr.getvalue() else None)

    def refuse_before_build(self, message: str = "") -> None:
        with patch.object(gate, "build_toolchain", side_effect=AssertionError("must not build")):
            code, result, error = self.invoke()
        self.assertEqual(code, 1)
        self.assertIsNone(result)
        self.assertEqual(error["status"], "error")
        self.assertIn(message, error["error"])

    @staticmethod
    def observation(stack: list) -> dict:
        return {"stack": gate.initial_values(stack), "kernel_cost": 2, "cost": 3,
                "trace_comparison": gate.TRACE_AGREED}

    def test_suite_source_is_relative_to_manifest_not_current_directory(self) -> None:
        source, cases = runner.load_suite(self.path)
        self.assertEqual(source, self.source)
        self.assertEqual(cases, self.suite["cases"])

    def test_relative_parent_source_is_supported(self) -> None:
        directory = self.root / "tests"
        directory.mkdir()
        self.path = directory / self.path.name
        self.suite["source"] = "../double.firth"
        self.write()
        self.assertEqual(runner.load_suite(self.path)[0], self.source)

    def test_suite_requires_exact_root_fields(self) -> None:
        for value in (None, [], True, 1, {}, {**self.suite, "extra": 1}):
            with self.subTest(value=value):
                self.path.write_text(json.dumps(value), encoding="utf-8")
                self.refuse_before_build("expected exactly")
        for key in self.suite:
            value = deepcopy(self.suite)
            del value[key]
            self.write(value)
            self.refuse_before_build("expected exactly")

    def test_schema_version_is_not_coerced(self) -> None:
        for version in (None, 1, True, "firth.tests.v2", {}, []):
            with self.subTest(version=version):
                self.write({**self.suite, "schema": version})
                self.refuse_before_build("unsupported schema")

    def test_source_path_is_an_explicit_relative_file(self) -> None:
        for source in (None, True, 1, [], "", " ", "bad\0name", str(self.source), ".", "absent.firth"):
            with self.subTest(source=source):
                self.write({**self.suite, "source": source})
                self.refuse_before_build()

    def test_empty_or_non_array_cases_cannot_pass(self) -> None:
        for cases in ([], None, {}, "cases", True):
            with self.subTest(cases=cases):
                self.write({**self.suite, "cases": cases})
                self.refuse_before_build("expected 1 to 128 cases")

    def test_case_limit_boundary(self) -> None:
        cases = [{**self.case, "name": f"case {n}"} for n in range(runner.MAX_TEST_CASES)]
        self.write({**self.suite, "cases": cases})
        self.assertEqual(len(runner.load_suite(self.path)[1]), runner.MAX_TEST_CASES)
        self.write({**self.suite, "cases": cases + [{**self.case, "name": "too many"}]})
        self.refuse_before_build("expected 1 to 128 cases")

    def test_case_fields_are_required_and_exact(self) -> None:
        cases = [None, [], True, {}, {**self.case, "skip": True},
                 {**self.case, "expected_error": "anything"}]
        for key in self.case:
            case = dict(self.case)
            del case[key]
            cases.append(case)
        for case in cases:
            with self.subTest(case=case):
                self.write({**self.suite, "cases": [case]})
                self.refuse_before_build("expected exactly")

    def test_case_name_and_entry_must_be_nonempty_strings(self) -> None:
        for field in ("name", "entry"):
            for value in (None, True, [], 0, "", " \t"):
                with self.subTest(field=field, value=value):
                    self.write({**self.suite, "cases": [{**self.case, field: value}]})
                    self.refuse_before_build(f".{field}: expected a non-empty string")

    def test_duplicate_case_names_are_rejected(self) -> None:
        self.write({**self.suite, "cases": [self.case, dict(self.case)]})
        self.refuse_before_build("duplicate case name")

    def test_duplicate_json_fields_are_rejected_at_each_depth(self) -> None:
        for raw in ('{"schema": 1, "schema": 2}',
                    '{"cases": [{"entry":"one","entry":"two"}]}',
                    '{"cases": [{"name":"one","n\\u0061me":"two"}]}'):
            with self.subTest(raw=raw):
                self.path.write_text(raw, encoding="utf-8")
                self.refuse_before_build("duplicate JSON member")

    def test_nonfinite_and_malformed_json_are_rejected(self) -> None:
        for raw in ("NaN", "Infinity", "-Infinity", "{", "", "[] trailing"):
            with self.subTest(raw=raw):
                self.path.write_text(raw, encoding="utf-8")
                self.refuse_before_build()

    def test_invalid_utf8_is_structured_failure(self) -> None:
        self.path.write_bytes(b"\xff")
        self.refuse_before_build()

    def test_nested_json_is_bounded_without_traceback(self) -> None:
        self.path.write_text("[" * 10000 + "]" * 10000, encoding="utf-8")
        # The decoder may raise RecursionError or accept the depth; either way
        # the suite is refused before any build.
        self.refuse_before_build()

    def test_suite_byte_limit_boundary(self) -> None:
        raw = self.path.read_bytes()
        self.path.write_bytes(raw + b" " * (runner.MAX_SUITE_BYTES - len(raw)))
        runner.load_suite(self.path)
        with self.path.open("ab") as stream:
            stream.write(b" ")
        self.refuse_before_build("exceeds")

    def test_only_exact_portable_scalars_are_allowed_in_both_stacks(self) -> None:
        for field in ("stack", "expected_stack"):
            for value in (-1, 2**63, 1.0, 0.0, "1", None, [], {}):
                with self.subTest(field=field, value=value):
                    self.write({**self.suite, "cases": [{**self.case, field: [value]}]})
                    self.refuse_before_build(field)

    def test_both_stacks_must_be_arrays(self) -> None:
        for field in ("stack", "expected_stack"):
            for value in (None, True, 1, {}, "[]"):
                with self.subTest(field=field, value=value):
                    self.write({**self.suite, "cases": [{**self.case, field: value}]})
                    self.refuse_before_build(field)

    def test_stack_length_boundary_and_scalar_boundaries(self) -> None:
        for field in ("stack", "expected_stack"):
            self.write({**self.suite, "cases": [{**self.case, field: [0] * runner.MAX_TEST_STACK}]})
            runner.load_suite(self.path)
            self.write({**self.suite, "cases": [{**self.case, field: [0] * (runner.MAX_TEST_STACK + 1)}]})
            self.refuse_before_build(field)
            self.write({**self.suite, "cases": [{**self.case, field: [0, 2**63 - 1, True, False]}]})
            runner.load_suite(self.path)

    def test_invalid_fuel_is_refused_before_build(self) -> None:
        for fuel in ("-1", str(gate.MAX_FUEL + 1)):
            with patch.object(gate, "build_toolchain", side_effect=AssertionError("must not build")):
                code, result, error = self.invoke("--fuel", fuel)
            self.assertEqual(code, 1)
            self.assertIsNone(result)
            self.assertIn(f"0 to {gate.MAX_FUEL}", error["error"])
        for fuel in (True, 1.0, None):
            with self.assertRaises(gate.GateError):
                runner.test_suite(self.path, fuel)

    def test_non_utf8_source_is_refused_before_build(self) -> None:
        self.source.write_bytes(b": main ( -- ) \xff ;\n")
        self.refuse_before_build("UTF-8")

    def test_every_case_runs_the_source_snapshot_taken_before_build(self) -> None:
        self.write({**self.suite, "cases": [self.case, {**self.case, "name": "second"}]})
        original = self.source.read_bytes()
        seen = []

        def run_case(entry, workspace, **_):
            seen.append(Path(entry["source"]).read_bytes())
            self.source.write_text(": main ( -- ) ;\n", encoding="utf-8")
            return self.observation([42])

        with patch.object(gate, "build_toolchain"), patch.object(gate, "rebuild", side_effect=run_case):
            code, result, error = self.invoke()
        self.assertEqual(code, 0)
        self.assertEqual(seen, [original, original])

    def test_whole_suite_is_validated_before_any_case_executes(self) -> None:
        self.write({**self.suite, "cases": [self.case, {**self.case, "name": "second", "expected_stack": [-1]}]})
        with patch.object(gate, "rebuild", side_effect=AssertionError("must not execute")):
            self.refuse_before_build("expected_stack")

    def test_success_builds_once_and_passes_stack_entry_and_fuel(self) -> None:
        with patch.object(gate, "build_toolchain") as build, \
                patch.object(gate, "rebuild", return_value=self.observation([42])) as rebuild:
            code, result, error = self.invoke("--fuel", "32")
        self.assertEqual(code, 0)
        self.assertIsNone(error)
        build.assert_called_once_with()
        entry, workspace = rebuild.call_args.args
        self.assertEqual(entry, {"name": "case-0", "entry": "main",
                                 "source": str(workspace / "source" / "double.firth"),
                                 "source_path": "double.firth"})
        self.assertEqual(rebuild.call_args.kwargs, {"stack": [21], "fuel": 32})
        self.assertFalse(workspace.exists())
        self.assertEqual(result["source"], str(self.source))
        self.assertEqual((result["passed"], result["failed"]), (1, 0))
        self.assertEqual(result["schema"], "firth.test-results.v1")
        self.assertEqual(result["cases"][0]["stack"], [42])
        self.assertEqual(result["cases"][0]["trace_comparison"], gate.TRACE_AGREED)

    def test_display_names_never_become_scratch_paths(self) -> None:
        self.write({**self.suite, "cases": [{**self.case, "name": "../human readable label"}]})
        with patch.object(gate, "build_toolchain"), \
                patch.object(gate, "rebuild", return_value=self.observation([42])) as rebuild:
            code, result, _ = self.invoke()
        self.assertEqual(code, 0)
        self.assertEqual(rebuild.call_args.args[0]["name"], "case-0")
        self.assertEqual(result["cases"][0]["name"], "../human readable label")

    def test_typed_boolean_integer_mismatches_never_pass(self) -> None:
        for expected, actual in (([True], [1]), ([False], [0]), ([1], [True]), ([0], [False]),
                                 ([42], [43]), ([42], []), ([1, 2], [2, 1])):
            with self.subTest(expected=expected, actual=actual):
                self.write({**self.suite, "cases": [{**self.case, "expected_stack": expected}]})
                with patch.object(gate, "build_toolchain"), \
                        patch.object(gate, "rebuild", return_value=self.observation(actual)):
                    code, result, error = self.invoke()
                self.assertEqual(code, 1)
                self.assertIsNone(error)
                self.assertEqual(result["status"], "failure")
                self.assertEqual((result["passed"], result["failed"]), (0, 1))
                self.assertIn("typed stack", result["cases"][0]["error"])

    def test_case_failures_do_not_skip_later_cases(self) -> None:
        self.write({**self.suite, "cases": [{**self.case, "name": f"case {n}"} for n in range(3)]})
        with patch.object(gate, "build_toolchain") as build, \
                patch.object(gate, "rebuild", side_effect=[gate.GateError("inconclusive, not agreement"),
                    self.observation([43]), self.observation([42])]) as rebuild:
            code, result, error = self.invoke()
        self.assertEqual(code, 1)
        self.assertIsNone(error)
        build.assert_called_once()
        self.assertEqual((result["passed"], result["failed"]), (1, 2))
        self.assertEqual([case["name"] for case in result["cases"]], ["case 0", "case 1", "case 2"])
        self.assertEqual([call.args[0]["name"] for call in rebuild.call_args_list],
                         ["case-0", "case-1", "case-2"])
        self.assertIn("inconclusive", result["cases"][0]["error"])

    def test_build_failures_are_not_reported_as_test_passes(self) -> None:
        with patch.object(gate, "build_toolchain", side_effect=gate.GateError("toolchain absent")), \
                patch.object(gate, "rebuild", side_effect=AssertionError("must not execute")):
            code, result, error = self.invoke()
        self.assertEqual(code, 1)
        self.assertIsNone(result)
        self.assertIn("toolchain absent", error["error"])

    def test_malformed_observation_is_a_case_failure(self) -> None:
        observation = self.observation([1])
        observation["stack"][0]["literal"]["value"] = True
        with patch.object(gate, "build_toolchain"), patch.object(gate, "rebuild", return_value=observation):
            code, result, _ = self.invoke()
        self.assertEqual(code, 1)
        self.assertIn("integer payload", result["cases"][0]["error"])

    def test_unsupported_quotation_trace_label_is_preserved(self) -> None:
        observation = self.observation([42])
        observation["trace_comparison"] = gate.TRACE_UNSUPPORTED
        with patch.object(gate, "build_toolchain"), patch.object(gate, "rebuild", return_value=observation):
            code, result, _ = self.invoke()
        self.assertEqual(code, 0)
        self.assertEqual(result["cases"][0]["trace_comparison"], gate.TRACE_UNSUPPORTED)

    def test_empty_output_stack_is_not_an_empty_suite(self) -> None:
        self.write({**self.suite, "cases": [{**self.case, "expected_stack": []}]})
        with patch.object(gate, "build_toolchain"), patch.object(gate, "rebuild", return_value=self.observation([])):
            code, result, _ = self.invoke()
        self.assertEqual(code, 0)
        self.assertEqual(result["passed"], 1)


if __name__ == "__main__":
    unittest.main()
