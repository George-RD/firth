#!/usr/bin/env python3
"""The VM-versus-Lean-semantics check must be able to fail.

`mvp_agent_gate.compare_target_semantics` requires the Rust VM and the Lean
target semantics (`lake exe firthTargetRun`) to agree exactly. This suite
holds two real response pairs, recorded from one run of each binary on the
same `firth.vm-run.v1` request (`allocate.firth` entry `allocate` on
`[10, 2, false]`, and `division.firth` entry `divmod` on `[7, 0]`, which
traps), trimmed to the compared members. It shows the pairs agree and that the
comparison refuses each planted difference. When both binaries are built, a
live case also runs the whole gate on a program and with a perturbed Lean
response; CI runs those with `FIRTH_REQUIRE_LIVE_TARGET_RUN=1`, so they cannot
skip there.
"""
from __future__ import annotations

from copy import deepcopy
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import mvp_agent_gate as gate


def literal(value: int) -> dict:
    return {"kind": "literal", "literal": {"type": "int", "value": value}}


# Recorded responses: `allocate [10, 2, false]` succeeds with 8 2 0.
VM_SUCCESS = {
    "request_id": "p", "status": "success",
    "stack": [literal(8), literal(2), literal(0)],
    "cost": {"steps": 64, "total": 73, "kernel": 64},
    "trap": None, "trap_subcode": None,
}
LEAN_SUCCESS = {
    "request_id": "p", "status": "success",
    "stack": [literal(8), literal(2), literal(0)],
    "cost": {"instructions": 64, "kernel": 64, "primitives": 3, "steps": 64,
             "total": 73, "word_entries": 9},
    "trap": None, "trap_subcode": None,
}
# Recorded responses: `divmod [7, 0]` traps with a primitive fault.
VM_TRAP = {
    "request_id": "p", "status": "trap",
    "stack": [literal(7), literal(0), literal(7), literal(0)],
    "cost": {"steps": 3, "total": 3, "kernel": 3},
    "trap": "primitive-fault", "trap_subcode": "",
}
LEAN_TRAP = {
    "request_id": "p", "status": "trap",
    "stack": [literal(7), literal(0), literal(7), literal(0)],
    "cost": {"instructions": 3, "kernel": 3, "primitives": 1, "steps": 3,
             "total": 3, "word_entries": 0},
    "trap": "primitive-fault", "trap_subcode": "",
}


def refusal(vm: dict, lean: dict) -> str:
    """The gate error the comparison raises, failing the test if it accepts."""
    with unittest.TestCase().assertRaises(gate.GateError) as caught:
        gate.compare_target_semantics(vm, lean, "p")
    return str(caught.exception)


class RecordedAgreement(unittest.TestCase):
    def test_recorded_pairs_agree(self) -> None:
        gate.compare_target_semantics(VM_SUCCESS, LEAN_SUCCESS, "p")
        gate.compare_target_semantics(VM_TRAP, LEAN_TRAP, "p")


class PlantedDifferences(unittest.TestCase):
    def check(self, vm: dict, lean: dict, *needles: str) -> None:
        message = refusal(vm, lean)
        for needle in needles:
            self.assertIn(needle, message)

    def test_total_cost_off_by_one(self) -> None:
        lean = deepcopy(LEAN_SUCCESS)
        lean["cost"]["total"] += 1
        self.check(VM_SUCCESS, lean, "cost.total differs", "VM 73", "Lean 74")

    def test_kernel_cost_off_by_one(self) -> None:
        lean = deepcopy(LEAN_SUCCESS)
        lean["cost"]["kernel"] -= 1
        self.check(VM_SUCCESS, lean, "cost.kernel differs", "VM 64", "Lean 63")

    def test_step_count_off_by_one(self) -> None:
        lean = deepcopy(LEAN_SUCCESS)
        lean["cost"]["steps"] += 1
        self.check(VM_SUCCESS, lean, "cost.steps differs")

    def test_word_entry_split_off_by_one(self) -> None:
        lean = deepcopy(LEAN_SUCCESS)
        lean["cost"]["word_entries"] += 1
        self.check(VM_SUCCESS, lean, "cost.word_entries differs")

    def test_two_stack_values_swapped(self) -> None:
        lean = deepcopy(LEAN_SUCCESS)
        lean["stack"][0], lean["stack"][1] = lean["stack"][1], lean["stack"][0]
        self.check(VM_SUCCESS, lean, "stack[0]", "differs")

    def test_stack_longer_than_the_vm_stack(self) -> None:
        lean = deepcopy(LEAN_SUCCESS)
        lean["stack"].append(literal(0))
        self.check(VM_SUCCESS, lean, "stack[3]", "<absent>")

    def test_boolean_is_not_an_integer(self) -> None:
        lean = deepcopy(LEAN_SUCCESS)
        lean["stack"][2] = {"kind": "literal", "literal": {"type": "bool", "value": False}}
        self.check(VM_SUCCESS, lean, "stack[2]", "differs")

    def test_different_trap_code(self) -> None:
        lean = deepcopy(LEAN_TRAP)
        lean["trap"] = "stack-fault"
        self.check(VM_TRAP, lean, "trap differs", "primitive-fault", "stack-fault")

    def test_different_trap_subcode(self) -> None:
        lean = deepcopy(LEAN_TRAP)
        lean["trap_subcode"] = "call-depth-exceeded"
        self.check(VM_TRAP, lean, "trap_subcode differs")

    def test_success_reported_as_a_trap(self) -> None:
        lean = deepcopy(LEAN_SUCCESS)
        lean.update(status="trap", trap="primitive-fault", trap_subcode="")
        self.check(VM_SUCCESS, lean, "status differs", "VM 'success'", "Lean 'trap'")

    def test_trap_reported_as_a_success(self) -> None:
        lean = deepcopy(LEAN_TRAP)
        lean.update(status="success", trap=None, trap_subcode=None)
        self.check(VM_TRAP, lean, "status differs")

    def test_unsupported_result_is_never_agreement(self) -> None:
        lean = deepcopy(LEAN_SUCCESS)
        lean.update(status="unsupported", trap="unsupported", trap_subcode="")
        self.check(VM_SUCCESS, lean, "unsupported by the Lean semantics")

    def test_unsupported_is_refused_even_when_the_vm_trapped_the_same_way(self) -> None:
        lean = deepcopy(LEAN_TRAP)
        lean.update(status="unsupported", trap="unsupported", trap_subcode="")
        vm = deepcopy(VM_TRAP)
        vm["trap"] = "unsupported"
        self.check(vm, lean, "unsupported by the Lean semantics")

    def test_malformed_cost_is_refused(self) -> None:
        lean = deepcopy(LEAN_SUCCESS)
        lean["cost"]["total"] = "73"
        self.check(VM_SUCCESS, lean, "cost.total is not an integer")

    def test_dual_fuel_exhaustion_is_inconclusive(self) -> None:
        vm, lean = deepcopy(VM_TRAP), deepcopy(LEAN_TRAP)
        vm["trap"] = lean["trap"] = "fuel-exhausted"
        self.check(vm, lean, "exhausted its fuel", "inconclusive")

    def test_malformed_primitive_count_is_refused(self) -> None:
        for bad in ("3", None, -1, 65, True):
            lean = deepcopy(LEAN_SUCCESS)
            lean["cost"]["primitives"] = bad
            self.check(VM_SUCCESS, lean, "cost.primitives")

    def test_a_missing_trap_member_is_refused(self) -> None:
        for key in ("trap", "trap_subcode"):
            lean = deepcopy(LEAN_SUCCESS)
            del lean[key]
            self.check(VM_SUCCESS, lean, f"{key} is missing")


BINARIES = (gate.LEAN_BIN / "firthTargetRun", gate.LEAN_BIN / "firthElaborate",
            gate.LEAN_BIN / "firthCompile", gate.LEAN_BIN / "firthReferenceRun",
            gate.VM_BINARY)


BUILT = all(path.is_file() for path in BINARIES)
# CI sets this after the gate has built every binary, so the live cases run
# there instead of skipping; a missing binary is then a failure.
REQUIRE_LIVE = os.environ.get("FIRTH_REQUIRE_LIVE_TARGET_RUN") == "1"
if REQUIRE_LIVE and not BUILT:
    raise SystemExit("FIRTH_REQUIRE_LIVE_TARGET_RUN=1 but these are not built: "
                     + ", ".join(str(path) for path in BINARIES if not path.is_file()))


@unittest.skipUnless(BUILT, "the Lean adapters and the VM are not built")
class LiveAgreement(unittest.TestCase):
    """The same comparison on responses from the real binaries."""

    ENTRY = {"name": "p", "entry": "allocate", "source_path": "allocate.firth",
             "source": str(gate.ROOT / "examples" / "programs" / "allocate.firth")}

    def rebuild(self) -> dict:
        with tempfile.TemporaryDirectory(prefix="firth-agreement-") as directory:
            return gate.rebuild(dict(self.ENTRY), Path(directory), stack=[10, 2, False])

    def test_real_responses_agree(self) -> None:
        self.assertEqual(self.rebuild()["cost"], 73)

    def test_a_perturbed_lean_response_fails_the_gate(self) -> None:
        real = gate.adapter

        def perturbed(command, request, workspace, label):
            response = real(command, request, workspace, label)
            if Path(command[0]).name == "firthTargetRun":
                response["cost"]["total"] += 1
            return response

        with patch.object(gate, "adapter", perturbed):
            with self.assertRaises(gate.GateError) as caught:
                self.rebuild()
        self.assertIn("p target semantics: cost.total differs", str(caught.exception))

    def test_the_runner_refuses_a_digest_it_cannot_reproduce(self) -> None:
        import subprocess
        request = {"request_id": "p", "gamma_version": "0.8", "fuel": 10, "initial_stack": [],
                   "image": {"image_version": 1, "gamma_version": 8},
                   "target_program": {"format_version": 1, "entry": "w", "words": [{
                       "name": "w", "erased_word_type": "(--)", "code": [],
                       "body_digest": "00" * 32, "kernel_evidence_digest": "00" * 32,
                       "refinement_evidence_digest": "00" * 32, "generation": 0}]}}
        done = subprocess.run([str(BINARIES[0])], input=json.dumps(request), text=True,
                              capture_output=True, check=False,
                              timeout=gate.ADAPTER_TIMEOUT_SECONDS)
        self.assertEqual(done.returncode, 1)
        self.assertEqual(done.stdout, "")
        self.assertIn("body_digest", done.stderr)


if __name__ == "__main__":
    unittest.main()
