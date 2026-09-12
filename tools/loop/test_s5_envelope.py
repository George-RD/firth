#!/usr/bin/env python3
"""Fail-closed tests for the S5 witness gate's trace-based checks.

Synthetic elaboration, target and trace fixtures exercise the branch witness,
the entry binding and the unread-field tracking without a toolchain. The gate
itself runs the real hosts and its own one-branch negative control.
"""
from __future__ import annotations

import copy
import unittest

import check_s5_envelope as s5

NAMES = ["handle-ping", "handle-pong", "dispatch", "session"]
MANGLED = {"handle-ping": "handle_hping", "handle-pong": "handle_hpong",
           "dispatch": "dispatch", "session": "session"}


def literal(kind: str, value: object) -> dict:
    return {"kind": "literal", "literal": {"type": kind, "value": value}}


def quotation(name: str) -> dict:
    return {"kind": "quotation", "body": [{"kind": "word", "name": name}], "usage": "many"}


def specification(**structure: object) -> dict:
    data = {
        "structure": {"words": list(NAMES), "entry": "session", "higher_order_dispatch": True,
                      "both_branches_taken": True, "dictionary_call_sites": 5,
                      "dictionary_calls_made": 6, **structure},
        "types": {name: "(--)" for name in NAMES},
        "behaviour": {"initial_stack": [], "result": 4, "fuel": 256},
        "cost": {"kernel_cost": 25, "target_cost": 31, "target_cost_envelope": 40},
    }
    return {table: s5.Tracked(values) for table, values in data.items()}


def elaboration() -> dict:
    programs = {
        "handle-ping": [{"kind": "lit", "value": {"type": "nat", "value": 1}}, {"kind": "prim", "name": "+"}],
        "handle-pong": [{"kind": "lit", "value": {"type": "nat", "value": 2}}, {"kind": "prim", "name": "+"}],
        "dispatch": [{"kind": "quotation", "body": [{"kind": "word", "name": "handle-ping"}]},
                     {"kind": "quotation", "body": [{"kind": "word", "name": "handle-pong"}]},
                     {"kind": "if"}],
        "session": [{"kind": "lit", "value": {"type": "nat", "value": 0}}],
    }
    return {"checked_words": [{"name": name} for name in NAMES],
            "kernel_programs": [{"word": name, "program": programs[name]} for name in NAMES]}


def target(entry: str = "session") -> dict:
    return {"target_program": {"entry": entry, "words": [
        {"name": MANGLED["handle-ping"], "code": [{"op": "push-literal"}, {"op": "prim"}]},
        {"name": MANGLED["handle-pong"], "code": [{"op": "push-literal"}, {"op": "prim"}]},
        {"name": "dispatch", "code": [{"op": "push-quote"}, {"op": "push-quote"}, {"op": "if"}]},
        {"name": "session", "code": [{"op": "push-literal"}]},
    ]}}


def traces(conditions: list[bool]) -> tuple[dict, dict]:
    """A VM and a reference trace of a session that dispatches on `conditions`."""
    vm_events, reference_events = [], []
    for condition in conditions:
        handler = "handle-ping" if condition else "handle-pong"
        stack = [literal("nat", 0), literal("bool", condition), quotation("handle-ping"), quotation("handle-pong")]
        vm_events.append({"word": "dispatch", "pc": 2, "stack": stack})
        vm_events.append({"word": MANGLED[handler], "pc": 0, "stack": [literal("nat", 0)]})
        reference_events.append({"program": [{"kind": "if"}], "stack": stack})
        reference_events.append({"program": [{"kind": "word", "name": handler}], "stack": [literal("nat", 0)]})
    return {"trace": vm_events}, {"trace": reference_events}


class BranchWitnessTests(unittest.TestCase):
    def test_a_session_taking_both_branches_is_proved_from_both_traces(self) -> None:
        vm, reference = traces([True, False, True])
        witness = s5.check_branches(specification(), elaboration(), target(), vm, reference, MANGLED)
        self.assertEqual(witness["handlers"], ["handle-ping", "handle-pong"])

    def test_a_one_branch_session_fails_the_witness(self) -> None:
        for conditions in ([True, True, True], [False], []):
            vm, reference = traces(conditions)
            with self.subTest(conditions=conditions):
                with self.assertRaisesRegex(s5.GateError, "both_branches_taken"):
                    s5.check_branches(specification(), elaboration(), target(), vm, reference, MANGLED)

    def test_each_host_is_checked_on_its_own(self) -> None:
        both_vm, _ = traces([True, False])
        _, one_reference = traces([True])
        with self.assertRaisesRegex(s5.GateError, "reference selected only"):
            s5.check_branches(specification(), elaboration(), target(), both_vm, one_reference, MANGLED)
        _, both_reference = traces([True, False])
        one_vm, _ = traces([False])
        with self.assertRaisesRegex(s5.GateError, "VM selected only"):
            s5.check_branches(specification(), elaboration(), target(), one_vm, both_reference, MANGLED)

    def test_a_handler_that_never_runs_is_reported_under_its_mangled_name(self) -> None:
        vm, reference = traces([True, False])
        vm["trace"] = [event for event in vm["trace"] if event["word"] != MANGLED["handle-pong"]]
        with self.assertRaisesRegex(s5.GateError, "never entered handle-pong \\(target handle_hpong\\)"):
            s5.check_branches(specification(), elaboration(), target(), vm, reference, MANGLED)
        vm, reference = traces([True, False])
        reference["trace"] = [event for event in reference["trace"]
                              if event["program"][0] != {"kind": "word", "name": "handle-ping"}]
        with self.assertRaisesRegex(s5.GateError, "never unfolded handle-ping"):
            s5.check_branches(specification(), elaboration(), target(), vm, reference, MANGLED)

    def test_the_declared_claim_and_the_dispatcher_shape_are_required(self) -> None:
        vm, reference = traces([True, False])
        with self.assertRaisesRegex(s5.GateError, "must declare both branches"):
            s5.check_branches(specification(both_branches_taken=False), elaboration(), target(), vm, reference, MANGLED)
        straight = elaboration()
        straight["kernel_programs"][2]["program"] = [{"kind": "word", "name": "handle-ping"}]
        with self.assertRaisesRegex(s5.GateError, "fewer than two handlers"):
            s5.check_branches(specification(), straight, target(), vm, reference, MANGLED)
        no_if = target()
        no_if["target_program"]["words"][2]["code"] = [{"op": "push-quote"}]
        with self.assertRaisesRegex(s5.GateError, "has no IF"):
            s5.check_branches(specification(), elaboration(), no_if, vm, reference, MANGLED)

    def test_a_non_boolean_selection_is_malformed(self) -> None:
        vm, reference = traces([True, False])
        vm["trace"][0]["stack"][1] = literal("nat", 1)
        with self.assertRaisesRegex(s5.GateError, "does not select on a Boolean"):
            s5.check_branches(specification(), elaboration(), target(), vm, reference, MANGLED)


class EntryAndSpecificationTests(unittest.TestCase):
    def test_the_compiled_entry_must_be_the_specified_entry(self) -> None:
        s5.check_entry(specification(), target("session"), MANGLED)
        with self.assertRaisesRegex(s5.GateError, "structure.entry: the compiler emitted entry 'dispatch'"):
            s5.check_entry(specification(), target("dispatch"), MANGLED)

    def test_target_names_are_mapped_positionally(self) -> None:
        self.assertEqual(s5.target_names(target(), NAMES), MANGLED)
        with self.assertRaisesRegex(s5.GateError, "emitted 4 words for 3"):
            s5.target_names(target(), NAMES[:3])

    def test_an_unread_specification_field_is_reported(self) -> None:
        spec = specification(unchecked_claim=True)
        vm, reference = traces([True, False])
        s5.check_branches(spec, elaboration(), target(), vm, reference, MANGLED)
        self.assertIn("structure.unchecked_claim", s5.unread_fields(spec))
        self.assertIn("behaviour.result", s5.unread_fields(spec))

    def test_the_one_branch_control_differs_only_in_the_session(self) -> None:
        source = ": session ( -- r:Int^many )\n  " + s5.SESSION_BODY + "\n"
        control = s5.one_branch_session(source)
        self.assertNotEqual(control, source)
        self.assertIn(s5.ONE_BRANCH_BODY, control)
        self.assertNotIn("false", control)
        with self.assertRaisesRegex(s5.GateError, "negative control"):
            s5.one_branch_session(": other ( -- ) ;")

    def test_tracked_tables_record_reads_only(self) -> None:
        table = s5.Tracked({"a": 1, "b": 2})
        self.assertEqual(table.unread(), ["a", "b"])
        self.assertEqual(table["a"], 1)
        self.assertIsNone(table.get("c"))
        self.assertIn("b", table)
        self.assertEqual(table.unread(), ["b"])
        copied = copy.deepcopy(table)
        self.assertEqual(copied.unread(), ["b"])


if __name__ == "__main__":
    unittest.main()
