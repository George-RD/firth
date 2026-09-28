#!/usr/bin/env python3
"""Harness regressions. Fake subprocesses test plumbing, not Firth correctness.

The separate CI source campaign runs the real Lean and Rust adapters.
"""
from __future__ import annotations

import copy
import dataclasses
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "src/diffharness"))
import harness as h


def observations():
    shared = {"status": "success", "trap": None, "stack": [], "trace": []}
    return ({**copy.deepcopy(shared), "cost": {"total": 0, "steps": 0},
             "world_observation": {"ids": []}},
            {**copy.deepcopy(shared), "cost": {"total": 0, "kernel": 0, "steps": 0},
             "world_observation": {"bytes": [0]}})


class GenerationTests(unittest.TestCase):
    def test_deterministic_indexed_generation(self):
        a = h.generate(71, 9)
        h.generate(71, 0)
        self.assertEqual(a, h.generate(71, 9))
        self.assertNotEqual(a.source, h.generate(72, 9).source)
        self.assertNotEqual(a.source, h.generate(71, 10).source)

    def test_recipe_round_trip(self):
        for seed in (0, 1, 20260909, 2**64 - 1):
            for index in range(24):
                original = h.generate(seed, index)
                restored = h.Case.from_payload(json.loads(json.dumps(original.payload())))
                self.assertEqual(restored.source, original.source)
                self.assertEqual(restored.stack, original.stack)

    def test_feature_coverage_floor(self):
        features = set()
        for index in range(len(h.OPS)):
            case = h.generate(0, index, size=1)
            features.update(case.features)
            self.assertEqual(len(case.steps), 1)
        self.assertTrue(set(h.OPS) <= features)
        self.assertTrue({"external-if-True", "external-if-False"} <= features)

    def test_helpers_are_after_explicit_entry_and_unused_is_last(self):
        for op in ("call", "qualified"):
            case = h.Case(0, 0, (h.Step(op, 3),), 4, False)
            self.assertTrue(case.source.startswith(": main"))
            self.assertGreater(case.source.index(": bump"), case.source.index(";"))
            self.assertTrue(case.source.endswith(": unused ( -- result:Int^many ) 999;\n"))

    def test_all_fragments_render_and_closed_bounds(self):
        for op in h.OPS:
            body, _ = h.Step(op, 3, 4, True).render(0)
            self.assertTrue(body)
        case = h.generate(0, 0, size=24)
        self.assertLessEqual(len(case.steps), 24)
        self.assertEqual(case.stack[-1], case.flag)

    def test_numeric_and_structural_generation_bounds(self):
        for kwargs in ({"seed": -1}, {"seed": True}, {"seed": 2**64},
                       {"size": 0}, {"size": 25}, {"fuel": -1}, {"fuel": True},
                       {"index": -1}, {"index": True}):
            with self.subTest(kwargs=kwargs), self.assertRaises(h.HarnessError):
                h.generate(**{"seed": 0, "index": 0, **kwargs})

    def test_invalid_recipes_are_refused(self):
        recipe = h.generate(0, 0).payload()
        mutations = ({"extra": "x"}, {"flag": 1}, {"value": False}, {"unused": 1},
                     {"prefix": [2**63]}, {"prefix": [None]}, {"prefix": [1] * 5},
                     {"steps": {}}, {"steps": [{"op": "eval", "a": 0, "b": 0, "flag": False}]},
                     {"steps": [{"op": [], "a": 0, "b": 0, "flag": False}]},
                     {"steps": [{"op": "add", "a": True, "b": 0, "flag": False}]},
                     {"value": 2**63}, {"value": -(2**63) - 1},
                     {"steps": [{"op": "div", "a": -(2**63) - 1, "b": 0, "flag": False}]},
                     {"steps": [{"op": "mod", "a": 0, "b": 2**63, "flag": False}]})
        for mutation in mutations:
            with self.subTest(mutation=mutation), self.assertRaises(h.HarnessError):
                h.Case.from_payload({**recipe, **mutation})


def reference_event(index, stack, cost=1):
    return {"index": index, "stack": stack, "program": [], "cost": cost}


def target_event(index, stack, kernel_cost=1):
    return {"index": index, "word": "main", "pc": index, "stack": stack, "cost": kernel_cost,
            "kernel_cost": kernel_cost, "image_version": 1, "frames": []}


def judged(case, reference_side, target_side):
    """Observations built by hand, then compared and judged as the executor does.

    A faulting VM run ends with the charged event of its faulting instruction,
    whose stack is the stack at the fault; where the reference runs on, its
    trace holds the same step with the same stack.
    """
    reference, target = observations()
    for observation, (status, values) in ((reference, reference_side), (target, target_side)):
        observation.update(status=status, trap=None if status == "success" else "primitive-fault",
                           stack=h.encode(values))
    if target_side[0] == "trap":
        target.update(trace=[target_event(0, h.encode(target_side[1]))],
                      cost={"total": 1, "kernel": 1, "steps": 1})
        if reference_side[0] == "success":
            reference.update(trace=[reference_event(0, h.encode(target_side[1]))],
                             cost={"total": 1, "steps": 1})
    result = h.compare(reference, target, 4096)
    return result.kind, h.judge(case, reference, target, result).kind


def case_of(value, *steps, prefix=()):
    return h.Case(0, 0, tuple(steps), value, False, prefix)


class OracleTests(unittest.TestCase):
    # Expected values are written out by hand from the documented meaning:
    # Euclidean division, a zero divisor faults, the VM faults outside i64.
    def test_euclidean_division_by_hand(self):
        for left, right, quotient, remainder in ((7, 2, 3, 1), (-7, 2, -4, 1), (7, -2, -3, 1),
                                                 (-7, -2, 4, 1), (6, -3, -2, 0), (-1, 5, -1, 4),
                                                 (h.MIN_INT, -1, 2**63, 0), (h.MIN_INT, 2, -(2**62), 0)):
            with self.subTest(left=left, right=right):
                self.assertEqual(h.primitive("div", left, right, False), quotient)
                self.assertEqual(h.primitive("mod", left, right, False), remainder)
                self.assertEqual(h.primitive("mod", left, right, True), remainder)

    def test_faults_by_hand(self):
        for portable in (False, True):
            for name in ("div", "mod"):
                with self.assertRaises(h.Fault) as raised:
                    h.primitive(name, 5, 0, portable)
                self.assertEqual(raised.exception.operands, (5, 0))
        for name, left, right in (("div", h.MIN_INT, -1), ("+", h.MAX_INT, 1), ("-", h.MIN_INT, 1),
                                  ("*", 2**32, 2**31), ("*", h.MIN_INT, -1)):
            with self.subTest(name=name), self.assertRaises(h.Fault):
                h.primitive(name, left, right, True)
            self.assertIsInstance(h.primitive(name, left, right, False), int)
        self.assertEqual(h.primitive("mod", h.MIN_INT, -1, True), 0)
        self.assertEqual(h.primitive("*", -(2**32), 2**31, True), h.MIN_INT)

    def test_every_fragment_has_a_meaning(self):
        # Each value is the fragment's rendered source worked by hand for n = 10.
        cases = {"add": 13, "double": 20, "call": 13, "qualified": 13, "local": 13,
                 "quote-call": 13, "quoted-value": 13, "compose": 17, "dip": 23, "if": 13,
                 "nested": 13, "swap": 13, "sub": 7, "rsub": -7, "mul": 30, "div": 3,
                 "rdiv": 0, "mod": 1, "rmod": 3, "less": 40, "equal": 2, "and": 2}
        self.assertEqual(set(cases), set(h.OPS))
        for op, value in cases.items():
            with self.subTest(op=op):
                self.assertEqual(h.apply_step(h.Step(op, 3, 4, True), 10, True), value)
        self.assertEqual(h.apply_step(h.Step("if", 3, 4, False), 10, True), 14)
        self.assertEqual(h.apply_step(h.Step("less", 30, 4, False), 10, True), 14)
        self.assertEqual(h.apply_step(h.Step("equal", 10, 4, False), 10, True), 2)
        self.assertEqual(h.apply_step(h.Step("equal", 3, 4, False), 10, True), 6)
        self.assertEqual(h.apply_step(h.Step("and", 3, 4, False), 10, True), 10)
        self.assertEqual(h.apply_step(h.Step("and", 30, 4, True), 10, True), 10)

    def test_fault_leaves_the_operands_above_the_prefix(self):
        case = case_of(9, h.Step("add", 1), h.Step("div", 0), h.Step("add", 1), prefix=(True, 4))
        self.assertEqual(h.expected(case, True), ("trap", [True, 4, 10, 0]))
        case = case_of(h.MAX_INT, h.Step("add", 1), h.Step("sub", 2), prefix=(3,))
        self.assertEqual(h.expected(case, False), ("success", [3, h.MAX_INT - 1]))
        self.assertEqual(h.expected(case, True), ("trap", [3, h.MAX_INT, 1]))

    def test_expected_classes_pass_only_when_both_hosts_match(self):
        division = case_of(-7, h.Step("div", 2))
        self.assertEqual(judged(division, ("success", [-4]), ("success", [-4])), ("agreement", "agreement"))
        zero = case_of(7, h.Step("mod", 0))
        self.assertEqual(judged(zero, ("trap", [7, 0]), ("trap", [7, 0])), ("runtime-trap", "expected-trap"))
        overflow = case_of(h.MAX_INT, h.Step("add", 1), h.Step("sub", 2))
        self.assertEqual(judged(overflow, ("success", [h.MAX_INT - 1]), ("trap", [h.MAX_INT, 1])),
                         ("portable-integer-overflow", "expected-portable-overflow"))
        for kind in ("expected-trap", "expected-portable-overflow"):
            self.assertIn(kind, h.PASSING)

    def test_planted_shared_bugs_are_caught(self):
        # Both hosts agree with each other on each of these, or differ only
        # in a way the plain comparison cannot name. Each is a planted bug.
        division = case_of(-7, h.Step("div", 2))
        self.assertEqual(judged(division, ("success", [-3]), ("success", [-3])),  # truncating division
                         ("agreement", "oracle-mismatch"))
        remainder = case_of(-7, h.Step("mod", 2))
        self.assertEqual(judged(remainder, ("success", [-1]), ("success", [-1])),  # remainder takes the sign
                         ("agreement", "oracle-mismatch"))
        order = case_of(10, h.Step("rsub", 3))
        self.assertEqual(judged(order, ("success", [7]), ("success", [7])),  # operands swapped
                         ("agreement", "oracle-mismatch"))
        branch = case_of(10, h.Step("less", 30, 4))
        self.assertEqual(judged(branch, ("success", [40]), ("success", [40])),  # `<` reversed
                         ("agreement", "oracle-mismatch"))
        zero = case_of(7, h.Step("div", 0))
        self.assertEqual(judged(zero, ("trap", [7, 0]), ("success", [0])),  # VM returns 0
                         ("trap-mismatch", "oracle-mismatch"))
        self.assertEqual(judged(zero, ("trap", [7]), ("trap", [7])),  # fault leaves the wrong stack
                         ("runtime-trap", "oracle-mismatch"))
        edge = case_of(h.MIN_INT, h.Step("div", -1))
        self.assertEqual(judged(edge, ("trap", [h.MIN_INT, -1]), ("trap", [h.MIN_INT, -1])),  # reference bounded
                         ("runtime-trap", "oracle-mismatch"))
        self.assertEqual(judged(edge, ("success", [2**63]), ("trap", [h.MIN_INT, -1])),
                         ("portable-integer-overflow", "expected-portable-overflow"))
        boolean = case_of(1, h.Step("mul", 1), prefix=(True,))
        reference, target = observations()
        for observation in (reference, target):
            observation["stack"] = h.encode([1, 1])  # a Boolean prefix read back as 1
        result = h.compare(reference, target, 4096)
        self.assertEqual(h.judge(boolean, reference, target, result).kind, "oracle-mismatch")

    def test_generation_reaches_signed_edges_and_faults(self):
        operands, outcomes = set(), set()
        for index in range(200):
            case = h.generate(0, index)
            operands.update(v for s in case.steps for v in (s.a, s.b))
            outcomes.add((h.expected(case, False)[0], h.expected(case, True)[0]))
        self.assertTrue({h.MIN_INT, h.MAX_INT, -1, 0} <= operands)
        self.assertTrue(any(v < 0 for v in operands))
        self.assertEqual(outcomes, {("success", "success"), ("success", "trap"), ("trap", "trap")})

    def test_negative_literals_shrink_towards_zero(self):
        self.assertEqual([h.half(v) for v in (-7, -1, 0, 7, h.MIN_INT)], [-3, 0, 0, 3, -(2**62)])


class ComparisonTests(unittest.TestCase):
    def test_only_successful_well_formed_observations_agree(self):
        reference, target = observations()
        self.assertEqual(h.compare(reference, target, 4096).kind, "agreement")
        reference["stack"] = h.gate.initial_values([0, h.MAX_INT, True])
        target["stack"] = copy.deepcopy(reference["stack"])
        self.assertEqual(h.compare(reference, target, 4096).kind, "agreement")

    def test_stack_and_kernel_cost_have_distinct_failure_classes(self):
        reference, target = observations()
        target["stack"] = h.gate.initial_values([1])
        self.assertEqual(h.compare(reference, target, 8).kind, "stack-mismatch")
        reference, target = observations()
        target["cost"] = {"total": 10, "kernel": 2, "steps": 1}
        self.assertEqual(h.compare(reference, target, 8).kind, "kernel-cost-mismatch")
        reference["cost"]["total"] = 2
        self.assertEqual(h.compare(reference, target, 8).kind, "agreement")

    def test_invalid_values_and_python_coercions_cannot_agree(self):
        for value in (True, False, 1.0, h.MIN_INT - 1, h.MAX_INT + 1, "1", None):
            reference, target = observations()
            reference["stack"] = [{"kind": "literal", "literal": {"type": "int", "value": value}}]
            target["stack"] = copy.deepcopy(reference["stack"])
            self.assertEqual(h.compare(reference, target, 8).kind, "invalid-observation")

    def test_malformed_observations_costs_traces_worlds_and_quotes(self):
        mutations = ({"cost": {"total": True, "steps": 0}}, {"trace": [1] * 10},
                     {"world_observation": {"ids": [1]}}, {"status": "success", "trap": "fault"},
                     {"stack": [{"kind": "quotation"}]}, {"status": []}, {"trap": False})
        for mutation in mutations:
            reference, target = observations()
            reference.update(mutation)
            self.assertEqual(h.compare(reference, target, 8).kind, "invalid-observation")
        for value in (None, [], {}, {"status": "success"}):
            self.assertEqual(h.compare(value, observations()[1], 8).kind, "invalid-observation")
        reference, target = observations()
        target["cost"] = {"total": 0, "kernel": 1, "steps": 0}
        self.assertEqual(h.compare(reference, target, 8).kind, "invalid-observation")
        target = observations()[1]
        target["world_observation"] = {"bytes": [False]}
        self.assertEqual(h.compare(reference, target, 8).kind, "invalid-observation")

    def test_exhaustion_is_inconclusive_not_agreement(self):
        reference, target = observations()
        reference.update(status="trap", trap="fuel-exhausted")
        target.update(status="trap", trap="fuel-exhausted")
        self.assertEqual(h.compare(reference, target, 8).kind, "bounded-fuel-inconclusive")
        target.update(status="success", trap=None)
        self.assertEqual(h.compare(reference, target, 8).kind, "fuel-asymmetry")

    def test_traps_are_not_passing_cases(self):
        reference, target = observations()
        reference.update(status="trap", trap="primitive-fault")
        target.update(status="trap", trap="primitive-fault", trace=[target_event(0, [])],
                      cost={"total": 1, "kernel": 1, "steps": 1})
        self.assertEqual(h.compare(reference, target, 8).kind, "runtime-trap")
        target["trap"] = "type-mismatch"
        self.assertEqual(h.compare(reference, target, 8).kind, "trap-mismatch")

    def test_target_integer_overflow_is_explicit(self):
        reference, target = observations()
        reference["stack"] = [{"kind": "literal", "literal": {"type": "int", "value": h.MAX_INT + 1}}]
        reference.update(trace=[reference_event(0, [])], cost={"total": 1, "steps": 1})
        target.update(status="trap", trap="primitive-fault", trace=[target_event(0, [])],
                      cost={"total": 1, "kernel": 1, "steps": 1})
        self.assertEqual(h.compare(reference, target, 8).kind, "portable-integer-overflow")

    def test_faults_are_compared_up_to_the_fault(self):
        # `7 0 mod`: the reference stops before `mod` after two charged pushes;
        # the VM also charges the faulting `mod`. Both leave 7 0 at the fault.
        seven, zero = h.encode([7]), h.encode([7, 0])
        case = case_of(7, h.Step("mod", 0))

        def faulted(target_trace):
            reference, target = observations()
            reference.update(status="trap", trap="primitive-fault", stack=zero,
                             trace=[reference_event(0, []), reference_event(1, seven)],
                             cost={"total": 2, "steps": 2})
            target.update(status="trap", trap="primitive-fault", stack=zero, trace=target_trace,
                          cost={"total": len(target_trace), "kernel": len(target_trace),
                                "steps": len(target_trace)})
            result = h.compare(reference, target, 8)
            return result.kind, h.judge(case, reference, target, result).kind

        right = [target_event(0, []), target_event(1, seven), target_event(2, zero)]
        self.assertEqual(faulted(right), ("runtime-trap", "expected-trap"))
        # Planted: the VM faults a step later with the same operands, and
        # before this check the stack at the fault alone passed it.
        late = right[:2] + [target_event(2, zero), target_event(3, zero)]
        self.assertEqual(faulted(late), ("kernel-cost-mismatch", "kernel-cost-mismatch"))
        # Planted: same charges, a different stack on the way.
        detour = [target_event(0, []), target_event(1, h.encode([8])), target_event(2, zero)]
        self.assertEqual(faulted(detour)[0], "trace-mismatch")
        self.assertEqual(faulted(detour)[1], "trace-mismatch")

    def test_an_overflow_must_follow_the_reference_up_to_the_fault(self):
        # `MAX 1 +` then `2 -`: the VM faults at `+` with MAX 1 on the stack;
        # the reference runs on and leaves MAX - 1.
        top, both = h.encode([h.MAX_INT]), h.encode([h.MAX_INT, 1])
        case = case_of(h.MAX_INT, h.Step("add", 1), h.Step("sub", 2))
        reference_trace = [reference_event(0, []), reference_event(1, top), reference_event(2, both),
                           reference_event(3, h.encode([h.MAX_INT + 1])),
                           reference_event(4, h.encode([h.MAX_INT + 1, 2]))]

        def overflowed(target_trace, stack=both, kernel=None):
            reference, target = observations()
            reference.update(stack=h.encode([h.MAX_INT - 1]), trace=copy.deepcopy(reference_trace),
                             cost={"total": 5, "steps": 5})
            kernel = len(target_trace) if kernel is None else kernel
            target.update(status="trap", trap="primitive-fault", stack=stack, trace=target_trace,
                          cost={"total": kernel, "kernel": kernel, "steps": len(target_trace)})
            result = h.compare(reference, target, 8)
            return result.kind, h.judge(case, reference, target, result).kind

        right = [target_event(0, []), target_event(1, top), target_event(2, both)]
        self.assertEqual(overflowed(right), ("portable-integer-overflow", "expected-portable-overflow"))
        # Planted: the VM took a different path to the same operands.
        detour = [target_event(0, []), target_event(1, h.encode([1])), target_event(2, both)]
        self.assertEqual(overflowed(detour), ("trace-mismatch", "trace-mismatch"))
        # Planted: a pure program that touched the World on either host.
        for side, world in ((0, {"ids": [1]}), (1, {"bytes": [1]})):
            reference, target = observations()
            reference.update(stack=h.encode([h.MAX_INT - 1]), trace=copy.deepcopy(reference_trace),
                             cost={"total": 5, "steps": 5})
            target.update(status="trap", trap="primitive-fault", stack=both, trace=copy.deepcopy(right),
                          cost={"total": 3, "kernel": 3, "steps": 3})
            (reference, target)[side]["world_observation"] = world
            self.assertEqual(h.compare(reference, target, 8).kind, "invalid-observation")
        # Planted: the VM's stack at the fault is not the reference's there.
        self.assertEqual(overflowed(right, h.encode([h.MAX_INT, 2]))[0], "stack-mismatch")
        # Planted: the VM faults a step early, at the push of 1. Its run is a
        # true prefix of the reference's, so only the oracle can name it.
        early = [target_event(0, []), target_event(1, top)]
        self.assertEqual(overflowed(early, top), ("portable-integer-overflow", "oracle-mismatch"))
        # Planted: one step charged differently, the reported total unchanged,
        # so only the per-event charge check can name it.
        charged = [target_event(0, []), target_event(1, top, kernel_cost=2), target_event(2, both)]
        self.assertEqual(overflowed(charged, kernel=3)[0], "trace-mismatch")
        # Planted: every event right, the reported kernel cost not the sum of
        # the reference's charges up to the fault.
        self.assertEqual(overflowed(right, kernel=4)[0], "kernel-cost-mismatch")
        # Planted: the VM follows the reference step for step and faults
        # after the reference's last step.
        longer = [target_event(i, event["stack"]) for i, event in enumerate(reference_trace)]
        longer.append(target_event(len(longer), h.encode([h.MAX_INT - 1])))
        self.assertEqual(overflowed(longer, h.encode([h.MAX_INT - 1]))[0], "trace-mismatch")

    def test_per_event_trace_differences_have_their_own_failure_class(self):
        one, two = h.gate.initial_values([1, 2])
        reference, target = observations()
        reference["trace"] = [{"index": 0, "stack": [], "program": [], "cost": 1},
                              {"index": 1, "stack": [one], "program": [], "cost": 1},
                              {"index": 2, "stack": [], "program": [], "cost": 1}]
        target["trace"] = [{"index": 0, "word": "main", "pc": 0, "stack": [], "cost": 1, "kernel_cost": 1,
                            "image_version": 1, "frames": []},
                           {"index": 1, "word": "main", "pc": 1, "stack": [two], "cost": 1, "kernel_cost": 1,
                            "image_version": 1, "frames": []},
                           {"index": 2, "word": "main", "pc": 2, "stack": [two, one], "cost": 1,
                            "kernel_cost": 1, "image_version": 1, "frames": []}]
        reference["stack"] = target["stack"] = [two]
        reference["cost"] = {"total": 3, "steps": 3}
        target["cost"] = {"total": 3, "kernel": 3, "steps": 3}
        result = h.compare(reference, target, 8)
        self.assertEqual(result.kind, "trace-mismatch")
        self.assertIn("trace event 1 stack", result.detail)
        target["trace"][1]["stack"] = [one]
        target["trace"][2]["stack"] = []
        result = h.compare(reference, target, 8)
        self.assertEqual((result.kind, result.trace_comparison), ("agreement", h.gate.TRACE_AGREED))
        quoted = {"kind": "quotation", "body": [], "usage": "many"}
        reference["trace"][1]["stack"] = target["trace"][1]["stack"] = [quoted]
        result = h.compare(reference, target, 8)
        self.assertEqual((result.kind, result.trace_comparison), ("agreement", h.gate.TRACE_UNSUPPORTED))
        del target["trace"][2]["frames"]
        self.assertEqual(h.compare(reference, target, 8).kind, "invalid-observation")

    def test_fuel_is_bounded_by_the_adapter_budget(self):
        for fuel in (h.gate.MAX_FUEL + 1, 10 * h.gate.MAX_FUEL):
            with self.subTest(fuel=fuel), self.assertRaises(h.HarnessError):
                h.generate(0, 0, fuel=fuel)
        self.assertEqual(h.generate(0, 0, fuel=4096).fuel, 4096)


class ProcessTests(unittest.TestCase):
    def invoke(self, code, **kwargs):
        with tempfile.TemporaryDirectory() as directory:
            return h.invoke((sys.executable, "-S", "-c", code), {"request_id": "test"}, Path(directory), **kwargs)

    def test_real_process_captures_request_response_stderr_and_exit(self):
        record = self.invoke('import sys,json; r=json.load(sys.stdin); print(json.dumps(r)); print("detail",file=sys.stderr)')
        self.assertEqual(record["response"], {"request_id": "test"})
        self.assertEqual(record["exit_code"], 0)
        self.assertEqual(record["stderr"], "detail\n")

    def test_crash_and_missing_executable_are_explicit(self):
        with self.assertRaises(h.AdapterError) as raised:
            self.invoke('import sys; print("crash",file=sys.stderr); sys.exit(7)')
        self.assertEqual(raised.exception.kind, "adapter-crash")
        self.assertEqual(raised.exception.record["exit_code"], 7)
        with tempfile.TemporaryDirectory() as directory, self.assertRaises(h.AdapterError) as raised:
            h.invoke(("/firth/nonexistent",), {"request_id": "test"}, Path(directory))
        self.assertEqual(raised.exception.kind, "adapter-unavailable")

    def test_timeout_is_not_a_runtime_exhaustion(self):
        start = time.monotonic()
        with self.assertRaises(h.AdapterError) as raised:
            self.invoke("import time; time.sleep(20)", timeout=0.1)
        self.assertEqual(raised.exception.kind, "adapter-timeout")
        self.assertLess(time.monotonic() - start, 3)

    def test_descendant_holding_pipes_does_not_escape_deadline(self):
        start = time.monotonic()
        with self.assertRaises(h.AdapterError) as raised:
            self.invoke('import subprocess,sys; subprocess.Popen([sys.executable,"-S","-c","import time; time.sleep(20)"])', timeout=0.15)
        self.assertEqual(raised.exception.kind, "adapter-timeout")
        self.assertLess(time.monotonic() - start, 3)

    def test_large_request_is_written_concurrently_without_deadlock(self):
        with tempfile.TemporaryDirectory() as directory:
            request = {"request_id": "test", "large": "x" * 200000}
            record = h.invoke((sys.executable, "-S", "-c", 'import json,sys; r=json.load(sys.stdin); print(json.dumps({"request_id":r["request_id"]}))'),
                              request, Path(directory))
        self.assertEqual(record["response"]["request_id"], "test")

    def test_output_limit_covers_combined_stdout_and_stderr(self):
        with self.assertRaises(h.AdapterError) as raised:
            self.invoke('import os; os.write(1,b"a"*600); os.write(2,b"b"*600)', output_limit=1000)
        self.assertEqual(raised.exception.kind, "adapter-output-limit")
        record = raised.exception.record
        self.assertEqual(len(record["stdout"]) + len(record["stderr"]), 1000)

    def test_invalid_utf8_is_preserved_and_refused(self):
        with self.assertRaises(h.AdapterError) as raised:
            self.invoke('import os; os.write(1,b"\\xff")')
        self.assertEqual(raised.exception.kind, "adapter-invalid-utf8")
        self.assertEqual(raised.exception.record["stdout_base64"], "/w==")

    def test_ambiguous_or_wrong_json_is_refused(self):
        for output in ('{"request_id":"test","request_id":"test"}',
                       '{"request_id":"test","x":NaN}',
                       '{"request_id":"test","x":1e999}',
                       '{"request_id":"other"}', '[]', 'null', 'text'):
            with self.subTest(output=output), self.assertRaises(h.AdapterError) as raised:
                self.invoke(f"print({output!r})")
            self.assertEqual(raised.exception.kind, "adapter-protocol-error")


class ExecutionTests(unittest.TestCase):
    def fixture(self, directory, *, target_mode="success", compiler_mode="success", elaborate_mode="success",
                stack=None):
        # Both fake hosts answer with the stack the case is expected to leave,
        # so these plumbing tests reach the comparison rather than the oracle.
        status, values = h.expected(h.generate(0, 0), portable=True)
        assert status == "success"
        (Path(directory) / "stack.json").write_text(json.dumps(h.encode(values) if stack is None else stack))
        path = Path(directory) / "adapter.py"
        path.write_text('''import json,sys
r=json.load(sys.stdin); stage=sys.argv[1]
common={"request_id":r["request_id"],"status":"success"}
if stage=="elaborate":
  base=lambda name:{"kind":"base","name":name,"usage":"many"}
  word={"name":"main","checking_state":"checked","proof_state":"available","program":[]}
  response={**common,"checked_words":[word],"erased_word_types":[{"word":"main","type":{"input":{"row":"r","items":[base("Int"),base("Bool")]}}}],"kernel_programs":[[]]}
  response["status"]=sys.argv[4]
elif stage=="compile":
  response={**common,"target_program":{},"status":sys.argv[3]}
else:
  stack=json.load(open(__file__.replace("adapter.py","stack.json")))
  response={**common,"trap":None,"stack":stack,"trace":[],"cost":{"total":0,"steps":0},"world_observation":{"ids":[]}}
  if stage=="target":
    response["cost"]["kernel"]=0; response["world_observation"]={"bytes":[0]}
    if sys.argv[2]=="mismatch": response["cost"].update(total=2,kernel=1)
    if sys.argv[2]=="trap":
      response.update(status="trap",trap="primitive-fault",cost={"total":1,"kernel":1,"steps":1})
      response["trace"]=[{"index":0,"word":"main","pc":0,"stack":stack,"cost":1,"kernel_cost":1,"image_version":1,"frames":[]}]
    if sys.argv[2]=="malformed": response.pop("stack")
  elif sys.argv[2]=="trap":
    # The reference runs on through the step at which the VM faults.
    response.update(cost={"total":1,"steps":1},trace=[{"index":0,"stack":stack,"program":[],"cost":1}])
print(json.dumps(response))
''', encoding="utf-8")
        return {stage: (sys.executable, "-S", str(path), stage, target_mode, compiler_mode, elaborate_mode)
                for stage in ("elaborate", "reference", "compile", "target")}

    def test_executor_runs_all_four_real_subprocesses_in_oracle_order(self):
        with tempfile.TemporaryDirectory() as directory:
            result = h.Executor(self.fixture(directory))(h.generate(0, 0))
        self.assertEqual(result.kind, "agreement")
        self.assertEqual([r["stage"] for r in result.records], ["elaborate", "reference", "compile", "target"])
        self.assertEqual(result.records[0]["request"]["source_text"], h.generate(0, 0).source)
        self.assertEqual(result.records[1]["request"]["initial_stack"], result.records[3]["request"]["initial_stack"])

    def test_real_subprocess_failure_paths(self):
        for kwargs, kind, stage, count in (
            ({"elaborate_mode": "error"}, "elaboration-rejected", "elaborate", 1),
            ({"compiler_mode": "error"}, "compiler-rejected", "compile", 3),
            ({"target_mode": "mismatch"}, "kernel-cost-mismatch", "compare", 4),
            # The oracle expects success, so a trapping VM is named against it.
            ({"target_mode": "trap"}, "oracle-mismatch", "oracle", 4),
            ({"target_mode": "malformed"}, "invalid-observation", "compare", 4)):
            with self.subTest(kwargs=kwargs), tempfile.TemporaryDirectory() as directory:
                result = h.Executor(self.fixture(directory, **kwargs))(h.generate(0, 0))
                self.assertEqual((result.kind, result.stage, len(result.records)), (kind, stage, count))

    def test_reductions_use_actual_execution_plumbing(self):
        with tempfile.TemporaryDirectory() as directory:
            executor = h.Executor(self.fixture(directory, target_mode="mismatch"))
            case = h.generate(0, 0)
            original = executor(case)
            reduced, result, report = h.shrink(case, original, executor, 8)
            self.assertLess(reduced.complexity, case.complexity)
            self.assertEqual(result.signature, original.signature)
            self.assertEqual(result.records[0]["stage"], "elaborate")
            self.assertLessEqual(report["attempts"], 8)


class ShrinkingTests(unittest.TestCase):
    def test_deterministic_same_failure_reductions(self):
        case = h.generate(9, 5)
        result = h.Result("stack-mismatch")
        execute = lambda candidate: h.Result("stack-mismatch")
        a = h.shrink(case, result, execute, 256)
        b = h.shrink(case, result, execute, 256)
        self.assertEqual(a[0], b[0])
        self.assertEqual(a[2], b[2])
        self.assertEqual(a[0].complexity, (0, 0, 0, 0))
        self.assertEqual(a[2]["stop"], "fixed-point")

    def test_changed_class_stage_or_trap_is_not_accepted(self):
        case = h.generate(9, 5)
        result = h.Result("runtime-trap", traps=("primitive-fault", "primitive-fault"))
        for other in (h.Result("agreement"), h.Result("elaboration-rejected", "elaborate"),
                      h.Result("runtime-trap", "compile", traps=result.traps),
                      h.Result("runtime-trap", traps=("stack-fault", "stack-fault"))):
            reduced, _, report = h.shrink(case, result, lambda candidate: other, 32)
            self.assertEqual(reduced, case)
            self.assertEqual(report["accepted"], 0)

    def test_budget_exhaustion_is_explicit(self):
        case = h.generate(0, 0)
        result = h.Result("stack-mismatch")
        calls = []
        def execute(candidate):
            calls.append(candidate)
            return h.Result("stack-mismatch")
        _, _, report = h.shrink(case, result, execute, 2)
        self.assertEqual(len(calls), 2)
        self.assertEqual(report["stop"], "budget-exhausted")
        _, _, report = h.shrink(case, result, execute, 0)
        self.assertEqual(report["attempts"], 0)

    def test_elaborator_rejection_and_success_do_not_shrink(self):
        case = h.generate(0, 0)
        for result in (h.Result("agreement"), h.Result("elaboration-rejected", "elaborate"),
                       h.Result("adapter-schema-error", "elaborate")):
            with patch.object(h, "reductions", side_effect=AssertionError("must not shrink")):
                self.assertEqual(h.shrink(case, result, lambda _: result, 10)[2]["stop"], "ineligible")

    def test_all_reductions_are_valid_and_strictly_smaller(self):
        for index in range(24):
            case = h.generate(42, index)
            for candidate in h.reductions(case):
                candidate.validate()
                self.assertLess(candidate.complexity, case.complexity)


class ArtefactTests(unittest.TestCase):
    def record(self):
        return h.failure_record(h.generate(4, 2), h.Result("stack-mismatch"), {"sha256": {"compiler": "a"}})

    def test_source_and_recipe_round_trip_and_original_preservation(self):
        with tempfile.TemporaryDirectory() as directory:
            record = self.record()
            path = h.save_failure(Path(directory), "original", record)
            saved, case = h.load_failure(path)
            self.assertEqual(saved, record)
            self.assertEqual(case.source, path.with_suffix(".firth").read_text())
            with self.assertRaises(FileExistsError):
                h.save_failure(Path(directory), "original", record)

    def test_tampered_source_input_recipe_version_or_hash_is_refused(self):
        for field, value in (("source", "shell script"), ("source_sha256", "0" * 64),
                             ("initial_stack", []), ("entry", "other"), ("generator", "unknown"),
                             ("schema", "unknown"), ("toolchain", {})):
            record = self.record()
            record[field] = value
            with self.subTest(field=field), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "x.json"
                path.write_text(json.dumps(record))
                with self.assertRaises(h.HarnessError):
                    h.load_failure(path)

    def test_boolean_numeric_input_substitution_is_refused(self):
        record = self.record()
        record["initial_stack"][-1] = int(record["initial_stack"][-1])
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "x.json"
            path.write_text(json.dumps(record))
            with self.assertRaises(h.HarnessError):
                h.load_failure(path)

    def test_malformed_or_oversized_json_is_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "x.json"
            path.write_text('{"schema":1,"schema":2}')
            with self.assertRaises(ValueError):
                h.load_failure(path)
            path.write_text("x" * 100)
            with patch.object(h, "MAX_ARTIFACT", 10), self.assertRaises(h.HarnessError):
                h.load_failure(path)

    def test_replay_refuses_toolchain_drift_before_execution(self):
        with tempfile.TemporaryDirectory() as directory:
            path = h.save_failure(Path(directory), "original", self.record())
            with patch.object(h.gate, "build_toolchain"), patch.object(h, "identities", return_value={"sha256": {"compiler": "b"}}), \
                    patch.object(h, "Executor", side_effect=AssertionError("must not execute")), \
                    patch("sys.stderr"):
                self.assertEqual(h.main(["replay", str(path)]), 2)

    def test_replay_uses_local_executor_not_artefact_commands(self):
        with tempfile.TemporaryDirectory() as directory:
            record = self.record()
            record["result"]["records"] = [{"command": ["/do/not/execute"], "request": {"source_path": "/etc/passwd"}}]
            path = h.save_failure(Path(directory), "original", record)
            seen = []
            def execute(case):
                seen.append(case.source)
                return h.Result("stack-mismatch")
            with patch.object(h.gate, "build_toolchain"), patch.object(h, "identities", return_value=record["toolchain"]), \
                    patch.object(h, "Executor", return_value=execute), patch("sys.stdout"):
                self.assertEqual(h.main(["replay", str(path), "--artifacts", directory]), 1)
            self.assertEqual(seen, [record["source"]])

    def test_bad_run_configuration_is_rejected_before_build(self):
        for args in (["run", "--cases", "0"], ["run", "--seed", "-1"],
                     ["run", "--size", "25"], ["run", "--shrink-steps", "257"]):
            with patch.object(h.gate, "build_toolchain", side_effect=AssertionError("must not build")), patch("sys.stderr"):
                self.assertEqual(h.main(args), 2)


if __name__ == "__main__":
    unittest.main()
