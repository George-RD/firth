#!/usr/bin/env python3
"""Adversarial tests for the portable comparison and adapter JSON boundaries.

These fixtures test gate behaviour, not compiler correctness or independent
agent authorship. The language-examples gate separately invokes real hosts.
"""
from __future__ import annotations

import copy
import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest.mock import patch

import mvp_agent_gate as gate


def literal(kind: str, value: object) -> dict:
    return {"kind": "literal", "literal": {"type": kind, "value": value}}


def observations() -> tuple[dict, dict]:
    shared = {"status": "success", "trap": None, "stack": [], "trace": []}
    reference = {**copy.deepcopy(shared), "cost": {"total": 0, "steps": 0},
                 "world_observation": {"ids": []}}
    target = {**copy.deepcopy(shared), "cost": {"total": 0, "kernel": 0, "steps": 0},
              "world_observation": {"bytes": [0]}}
    return reference, target


class PortableObservationTests(unittest.TestCase):
    def assert_invalid_value(self, value: object, reason: str) -> None:
        # Both sides, separately and together: equal malformed values are not
        # agreement, nor may one invalid side be masked by the other's shape.
        for sides in ((0,), (1,), (0, 1)):
            pair = observations()
            for index in sides:
                pair[index]["stack"] = [copy.deepcopy(value)]
            with self.subTest(value=value, sides=sides):
                with self.assertRaisesRegex(gate.GateError, reason):
                    gate.compare(*pair, "invalid-value")

    def test_supported_results_include_both_integer_boundaries(self) -> None:
        for values in ([], [False, True, 0, 1, 2**63 - 1], [1, False, 1]):
            reference, target = observations()
            reference["stack"] = gate.initial_values(values)
            target["stack"] = copy.deepcopy(reference["stack"])
            gate.compare(reference, target, "supported", fuel=0)

    def test_python_boolean_integer_equality_cannot_mask_wrong_payloads(self) -> None:
        for kind, left, right in (("nat", True, 1), ("nat", False, 0),
                                  ("bool", True, 1), ("bool", False, 0),
                                  ("nat", 1.0, 1), ("nat", 0.0, 0)):
            for a, b in ((left, right), (right, left)):
                reference, target = observations()
                reference["stack"] = [literal(kind, a)]
                target["stack"] = [literal(kind, b)]
                with self.subTest(kind=kind, left=a, right=b):
                    with self.assertRaisesRegex(gate.GateError, "payload"):
                        gate.compare(reference, target, "coercion")

    def test_nat_payloads_are_exact_integers_in_the_portable_range(self) -> None:
        for value in (True, False, -1, 2**63, 2**100, 1.0, "1", None,
                      float("nan"), float("inf"), [], {}):
            self.assert_invalid_value(literal("nat", value), "integer payload")

    def test_boolean_payloads_are_exact_booleans(self) -> None:
        for value in (0, 1, 0.0, 1.0, "true", None, [], {}):
            self.assert_invalid_value(literal("bool", value), "Boolean payload")

    def test_value_envelopes_are_complete_and_have_no_extra_fields(self) -> None:
        for value in (None, 1, True, [], {}, {"literal": {"type": "nat", "value": 1}},
                      {"kind": "literal"}, {"kind": "literal", "literal": None},
                      {"kind": "literal", "literal": []},
                      {"kind": "literal", "literal": {"value": 1}},
                      {"kind": "literal", "literal": {"type": "nat"}},
                      {**literal("nat", 1), "extra": 0},
                      {"kind": "literal", "literal": {"type": "nat", "value": 1, "extra": 0}}):
            self.assert_invalid_value(value, "malformed.*value|malformed.*literal")

    def test_unsupported_value_kinds_never_count_as_agreement(self) -> None:
        for value in ({"kind": "world"}, {"kind": "bytes", "value": "00"},
                      {"kind": "primitive", "tag": 1, "value": "00"},
                      {"kind": "unknown"}, {"kind": []},
                      literal("int", -1), {"kind": "literal", "literal": {"type": "unit"}},
                      literal("unknown", 1), literal([], 1)):
            self.assert_invalid_value(value, "unsupported.*value|unsupported.*literal")

    def test_quotation_results_are_explicitly_unsupported(self) -> None:
        for value in ({"kind": "quotation", "usage": "many"},
                      {"kind": "quotation", "body": [], "usage": "many"},
                      {"kind": "quotation", "body": [{"kind": "word", "name": "one"}],
                       "captures": [literal("nat", 1)], "usage": "many"},
                      {"kind": "quotation", "body": [], "usage": "linear"}):
            self.assert_invalid_value(value, "unsupported quotation result")

    def test_distinct_quotation_bodies_or_captures_are_not_normalised_away(self) -> None:
        for field in ("body", "captures"):
            reference, target = observations()
            reference["stack"] = [{"kind": "quotation", "usage": "many", field: [1]}]
            target["stack"] = [{"kind": "quotation", "usage": "many", field: [2]}]
            with self.subTest(field=field):
                with self.assertRaisesRegex(gate.GateError, "unsupported quotation result"):
                    gate.compare(reference, target, "different-closures")

    def test_valid_but_different_stacks_are_still_mismatches(self) -> None:
        for left, right in (([True], [1]), ([0], [False]), ([1, 2], [2, 1]),
                            ([1], [2]), ([1], [])):
            reference, target = observations()
            reference["stack"] = gate.initial_values(left)
            target["stack"] = gate.initial_values(right)
            with self.subTest(left=left, right=right):
                with self.assertRaisesRegex(gate.GateError, "residual stack"):
                    gate.compare(reference, target, "mismatch")

    def test_pure_world_sentinel_rejects_boolean_and_float_bytes(self) -> None:
        for value in (False, 0.0):
            reference, target = observations()
            target["world_observation"] = {"bytes": [value]}
            with self.subTest(value=value):
                with self.assertRaisesRegex(gate.GateError, "world observation"):
                    gate.compare(reference, target, "world-coercion")

    def test_world_schemas_and_effects_are_checked_on_each_side(self) -> None:
        for index, values in (
            (0, (None, [], {}, {"ids": None}, {"ids": [0]}, {"ids": [], "extra": 0})),
            (1, (None, [], {}, {"bytes": None}, {"bytes": []}, {"bytes": [1]},
                 {"bytes": [0, 0]}, {"bytes": ["0"]}, {"bytes": [0], "extra": 0})),
        ):
            for value in values:
                pair = observations()
                pair[index]["world_observation"] = value
                with self.subTest(side=index, value=value):
                    with self.assertRaisesRegex(gate.GateError, "world observation|effectful"):
                        gate.compare(*pair, "world")

    def test_non_object_observations_raise_gate_errors(self) -> None:
        for index in (0, 1):
            for value in (None, [], 0, "success"):
                pair = list(observations())
                pair[index] = value
                with self.subTest(side=index, value=value):
                    with self.assertRaisesRegex(gate.GateError, "observation is not an object"):
                        gate.compare(*pair, "malformed-observation")

    def test_comparison_fuel_has_the_same_contract_as_execution_fuel(self) -> None:
        for fuel in (True, False, -1, 4097, 100001, 1.0, "10", None):
            with self.subTest(fuel=fuel):
                with self.assertRaisesRegex(gate.GateError, "fuel"):
                    gate.compare(*observations(), "invalid-fuel", fuel=fuel)
        gate.compare(*observations(), "bound", fuel=4096)
        self.assertEqual(gate.MAX_FUEL, 4096)

    def test_fuel_exhaustion_traps_and_overflow_never_pass(self) -> None:
        for trap in ("fuel-exhausted", "primitive-fault", "stack-fault"):
            for sides in ((0,), (1,), (0, 1)):
                pair = observations()
                for index in sides:
                    pair[index].update(status="trap", trap=trap)
                with self.subTest(trap=trap, sides=sides):
                    with self.assertRaises(gate.GateError):
                        gate.compare(*pair, "not-termination")

    def test_kernel_cost_and_trace_bounds_are_still_enforced(self) -> None:
        reference, target = observations()
        target["cost"].update(total=2, kernel=1)
        with self.assertRaisesRegex(gate.GateError, "kernel cost"):
            gate.compare(reference, target, "cost")
        reference, target = observations()
        reference["trace"] = [{"index": 0}]
        with self.assertRaisesRegex(gate.GateError, "fuel budget"):
            gate.compare(reference, target, "trace", fuel=0)


def reference_event(index: int, stack: list, cost: int, program: list | None = None) -> dict:
    return {"index": index, "stack": stack, "program": program or [], "cost": cost}


def target_event(index: int, stack: list, cost: int, kernel_cost: int, word: str = "main",
                 pc: int = 0) -> dict:
    return {"index": index, "word": word, "pc": pc, "stack": stack, "cost": cost,
            "kernel_cost": kernel_cost, "image_version": 1, "frames": []}


def traced(reference_events: list, target_events: list, stack: list | None = None,
           total: int | None = None) -> tuple[dict, dict]:
    reference, target = observations()
    reference["trace"], target["trace"] = reference_events, target_events
    if stack is not None:
        reference["stack"] = target["stack"] = copy.deepcopy(stack)
    if total is None:
        total = sum(event["cost"] for event in reference_events)
    reference["cost"] = {"total": total, "steps": len(reference_events)}
    target["cost"] = {"total": max(total, sum(e.get("cost", 0) for e in target_events)), "kernel": total,
                      "steps": len(target_events)}
    return reference, target


class TraceComparisonTests(unittest.TestCase):
    """The per-event comparison of `compare_traces`, through `compare`."""

    def test_a_reordered_program_with_the_same_result_is_refused(self) -> None:
        # `1 drop 2` and `2 1 drop` both leave [2] at kernel cost 3, and before
        # the per-event comparison this reorder passed as agreement.
        one, two = literal("nat", 1), literal("nat", 2)
        reference = [reference_event(0, [], 1), reference_event(1, [one], 1), reference_event(2, [], 1)]
        target = [target_event(0, [], 1, 1), target_event(1, [two], 1, 1, pc=1),
                  target_event(2, [two, one], 1, 1, pc=2)]
        with self.assertRaisesRegex(gate.TraceMismatch, "trace event 1 stack"):
            gate.compare(*traced(reference, target, stack=[two]), "reorder")

    def test_cumulative_target_charges_are_refused(self) -> None:
        # The old adapter reported the running total [1, 2, 3] per event.
        one, two = literal("nat", 1), literal("nat", 2)
        reference = [reference_event(0, [], 1), reference_event(1, [one], 1), reference_event(2, [one, two], 1)]
        cumulative = [target_event(0, [], 1, 1), target_event(1, [one], 2, 2, pc=1),
                      target_event(2, [one, two], 3, 3, pc=2)]
        with self.assertRaisesRegex(gate.TraceMismatch, "trace event 1 charges 1 against the VM kernel charge 2"):
            gate.compare(*traced(reference, cumulative), "cumulative")
        per_event = [target_event(0, [], 1, 1), target_event(1, [one], 1, 1, pc=1),
                     target_event(2, [one, two], 1, 1, pc=2)]
        self.assertEqual(gate.compare(*traced(reference, per_event), "per-event"), gate.TRACE_AGREED)

    def test_zero_cost_pushes_and_capture_restorations_project_away(self) -> None:
        # `42 quote call`: the reference's zero-cost S-PUSH and the VM's
        # zero-kernel PUSH_CAPTURE both drop out; the quoted value on the
        # intermediate stacks makes the result the explicit unsupported label.
        value = literal("nat", 42)
        quoted = {"kind": "quotation", "body": [{"kind": "push", "value": value}], "usage": "many"}
        vm_quoted = {"kind": "quotation", "usage": "many", "body_digest": "00" * 32,
                     "code": [{"op": "push-capture", "index": 0}],
                     "captures": [{"kind": "int", "value": 42}], "consumed": [False]}
        reference = [reference_event(0, [], 1), reference_event(1, [value], 1),
                     reference_event(2, [quoted], 1), reference_event(3, [], 0)]
        target = [target_event(0, [], 1, 1), target_event(1, [value], 1, 1, pc=1),
                  target_event(2, [vm_quoted], 1, 1, pc=2), target_event(3, [], 1, 0)]
        self.assertEqual(gate.compare(*traced(reference, target, stack=[value]), "quote-call"),
                         gate.TRACE_UNSUPPORTED)
        # The same projection with scalar stacks only is a full agreement.
        reference = [reference_event(0, [], 1), reference_event(1, [value], 0), reference_event(2, [value], 1)]
        target = [target_event(0, [], 1, 1), target_event(1, [value], 1, 0, pc=1),
                  target_event(2, [value], 1, 1, pc=2)]
        self.assertEqual(gate.compare(*traced(reference, target, stack=[value]), "scalar"),
                         gate.TRACE_AGREED)

    def test_quotation_values_in_intermediate_stacks_are_unsupported_not_agreement(self) -> None:
        value = literal("nat", 1)
        quoted = {"kind": "quotation", "body": [], "usage": "many"}
        reference = [reference_event(0, [quoted], 1)]
        target = [target_event(0, [quoted], 1, 1)]
        self.assertEqual(gate.compare(*traced(reference, target), "quoted"), gate.TRACE_UNSUPPORTED)
        # The label still requires the projected lengths and charges to match.
        with self.assertRaisesRegex(gate.TraceMismatch, "lengths differ"):
            gate.compare(*traced(reference, target + [target_event(1, [value], 1, 1, pc=1)], total=1), "length")
        with self.assertRaisesRegex(gate.TraceMismatch, "charges 1 against the VM kernel charge 2"):
            gate.compare(*traced(reference, [target_event(0, [quoted], 2, 2)]), "charge")

    def test_a_trace_event_missing_its_kernel_charge_or_frames_is_malformed(self) -> None:
        value = literal("nat", 1)
        good = target_event(0, [], 1, 1)
        for missing in ("kernel_cost", "frames", "image_version", "word", "pc", "stack", "cost", "index"):
            event = {key: item for key, item in good.items() if key != missing}
            with self.subTest(missing=missing):
                with self.assertRaisesRegex(gate.GateError, "malformed trace event"):
                    gate.compare(*traced([reference_event(0, [], 1)], [event]), "malformed")
        for extra in ({**good, "extra": 1}, {**good, "kernel_cost": 2}, {**good, "kernel_cost": True},
                      {**good, "index": 1}, {**good, "stack": None}):
            with self.subTest(extra=extra):
                with self.assertRaises(gate.GateError):
                    gate.compare(*traced([reference_event(0, [], 1)], [extra]), "malformed")
        for bad in ({"index": 0, "stack": [], "cost": 1}, {**reference_event(0, [], 1), "cost": -1},
                    {**reference_event(0, [], 1), "index": 1}):
            with self.subTest(bad=bad):
                with self.assertRaises(gate.GateError):
                    gate.compare(*traced([bad], [good]), "malformed")
        # Malformed stack values inside a projected event are refused too.
        with self.assertRaisesRegex(gate.GateError, "trace\\[0\\]"):
            gate.compare(*traced([reference_event(0, [{"kind": "literal", "literal": {"type": "nat", "value": True}}], 1)],
                                 [target_event(0, [value], 1, 1)]), "coercion")

    def test_traces_that_are_not_arrays_are_refused(self) -> None:
        for index in (0, 1):
            pair = list(traced([], []))
            pair[index]["trace"] = {}
            with self.subTest(side=index), self.assertRaisesRegex(gate.GateError, "trace is not an array"):
                gate.compare(*pair, "shape")


class FirthRunInputTests(unittest.TestCase):
    def test_a_deeply_nested_stack_is_refused_as_a_gate_error(self) -> None:
        import firth_run
        with self.assertRaisesRegex(gate.GateError, "stack: not an accepted JSON array \\(RecursionError\\)"):
            firth_run.parse_stack("[" * 100000 + "]" * 100000)
        with self.assertRaisesRegex(gate.GateError, "JSONDecodeError"):
            firth_run.parse_stack("[1,")
        self.assertEqual(firth_run.parse_stack("[1, true]"), [1, True])

    def test_the_command_reports_the_refusal_without_a_toolchain(self) -> None:
        import firth_run
        with tempfile.NamedTemporaryFile(suffix=".firth") as source:
            stderr = io.StringIO()
            with patch.object(gate, "build_toolchain", side_effect=AssertionError("must not build")), \
                    redirect_stderr(stderr):
                code = firth_run.main(["run", source.name, "--entry", "main", "--stack", "[" * 100000 + "]" * 100000])
            self.assertEqual(code, 1)
            self.assertIn("RecursionError", json.loads(stderr.getvalue())["error"])
            stderr = io.StringIO()
            with patch.object(gate, "build_toolchain", side_effect=AssertionError("must not build")), \
                    redirect_stderr(stderr):
                code = firth_run.main(["run", source.name, "--entry", "main", "--fuel", "4097"])
            self.assertEqual(code, 1)
            self.assertIn("0 to 4096", json.loads(stderr.getvalue())["error"])


class AdapterJsonTests(unittest.TestCase):
    def decode(self, text: str) -> dict:
        with patch.object(gate, "run", return_value=text):
            return gate.adapter(["fixture"], {"request_id": "fixture"}, Path.cwd(), "fixture")

    def test_valid_json_and_request_identity_remain_supported(self) -> None:
        text = '{"request_id":"fixture","status":"success","nested":{"value":1}}'
        self.assertEqual(self.decode(text), json.loads(text))
        with self.assertRaisesRegex(gate.GateError, "request id"):
            self.decode(text.replace('"fixture"', '"other"'))

    def test_duplicate_fields_are_rejected_at_every_depth(self) -> None:
        for suffix in ('"status":"error","status":"success"',
                       '"nested":{"value":0,"value":1}',
                       '"stack":[{"kind":"world","kind":"literal"}]',
                       '"cost":{"total":0,"total":0}',
                       '"nested":{"value":0,"\\u0076alue":1}'):
            with self.subTest(suffix=suffix):
                with self.assertRaisesRegex(gate.GateError, "duplicate.*field"):
                    self.decode('{"request_id":"fixture",' + suffix + '}')

    def test_non_finite_json_numbers_are_rejected(self) -> None:
        for value in ("NaN", "Infinity", "-Infinity", "1e999", "-1e999"):
            with self.subTest(value=value):
                with self.assertRaisesRegex(gate.GateError, "non-finite"):
                    self.decode('{"request_id":"fixture","value":' + value + '}')

    def test_invalid_json_fails_as_a_gate_error(self) -> None:
        for text in ("not json", '{"request_id":'):
            with self.subTest(length=len(text)):
                with self.assertRaisesRegex(gate.GateError, "not JSON"):
                    self.decode(text)

    def test_decoder_recursion_errors_are_reported_as_gate_errors(self) -> None:
        # Decoder nesting limits differ across supported Python versions.
        with patch.object(gate.json, "loads", side_effect=RecursionError("too deep")):
            with self.assertRaisesRegex(gate.GateError, "not JSON"):
                self.decode("{}")

    def test_ambiguous_responses_from_real_processes_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            for suffix in ('"status":"error","status":"success"', '"value":NaN'):
                text = '{"request_id":"fixture",' + suffix + '}'
                with self.subTest(suffix=suffix):
                    with self.assertRaises(gate.GateError):
                        gate.adapter([sys.executable, "-c", "import sys; sys.stdout.write(sys.argv[1])", text],
                                     {"request_id": "fixture"}, Path(directory), "process-fixture")


if __name__ == "__main__":
    unittest.main()
