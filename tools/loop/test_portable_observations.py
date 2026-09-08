#!/usr/bin/env python3
"""Adversarial tests for the portable comparison and adapter JSON boundaries.

These fixtures test gate behaviour, not compiler correctness or independent
agent authorship. The language-examples gate separately invokes real hosts.
"""
from __future__ import annotations

import copy
import json
import sys
import tempfile
import unittest
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
        for fuel in (True, False, -1, 100001, 1.0, "10", None):
            with self.subTest(fuel=fuel):
                with self.assertRaisesRegex(gate.GateError, "fuel"):
                    gate.compare(*observations(), "invalid-fuel", fuel=fuel)

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
