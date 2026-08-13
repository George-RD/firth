#!/usr/bin/env python3
"""Behaviour tests for ticket-coordinated iteration preparation and sealing."""

from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import tempfile
import unittest
from collections.abc import Mapping
from pathlib import Path
from typing import Any


SOURCE = Path(__file__).with_name("prepare_iteration.py")
PROJECTION_FIXTURE = Path(__file__).with_name("authority-policy.projection.json")
spec = importlib.util.spec_from_file_location("prepare_iteration", SOURCE)
assert spec and spec.loader
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)


class FakeState:
    def __init__(self, generation: int = 10) -> None:
        self.generation = generation
        self.calls: list[tuple[str, dict[str, Any]]] = []
        self.mutate: dict[str, Any] = {}
        self.fail_at: str | None = None

    def request(self, template_id: str, context: Mapping[str, Any]) -> Mapping[str, Any]:
        if template_id == self.fail_at:
            raise RuntimeError("injected state failure")
        request = copy.deepcopy(dict(context))
        self.calls.append((template_id, request))
        self.generation += 1
        objects: dict[str, Any]
        if template_id == "normal.mirror.fetch":
            objects = {
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "main_commit": context["main_commit"],
                "main_tree": context["main_tree"],
                "mirror_id": "mirror-1",
            }
        elif template_id == "normal.branch.create":
            objects = {
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "branch": context["branch"],
                "head": context["main_commit"],
                "base_commit": context["main_commit"],
                "mirror_id": context["mirror_id"],
            }
        elif template_id == "normal.worktree.create":
            objects = {
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "branch": context["branch"],
                "head": context["head"],
                "worktree_id": "worktree-1",
                "metadata_read_only": True,
            }
        elif template_id == "normal.lease.grant":
            objects = {
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "branch": context["branch"],
                "head": context["head"],
                "worktree_id": context["worktree_id"],
                "lease_epoch": 7,
                "metadata_read_only": True,
                "writer": "model",
                "container_id": "container-1",
                "cgroup_id": "cgroup-1",
            }
        elif template_id == "normal.binding.verify":
            objects = {
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "unit": context["unit"],
                "branch": context["branch"],
                "head": context["head"],
                "worktree_id": "worktree-existing",
                "lease_epoch": 12,
                "metadata_read_only": True,
                "writer": "model",
                "container_id": "container-existing",
                "cgroup_id": "cgroup-existing",
            }
        elif template_id in prepare.FINALISE_TEMPLATES:
            objects = {
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "unit": context["unit"],
                "branch": context["branch"],
                "head": context["head"],
                "worktree_id": context["worktree_id"],
                "lease_epoch": context["lease_epoch"],
            }
            if template_id == "normal.finalise.model-stop":
                objects.update(
                    container_id=context["container_id"],
                    cgroup_id=context["cgroup_id"],
                    writer_present=False,
                    cgroup_stopped=True,
                    descendant_count=0,
                )
            elif template_id == "normal.finalise.acl-transfer":
                objects.update(
                    writer="broker",
                    model_write_access=False,
                    broker_write_access=True,
                )
            elif template_id == "normal.finalise.lease-acquire":
                objects.update(
                    head=context["head"],
                    head_tree="4" * 40,
                    lease_epoch=context["lease_epoch"] + 1,
                    lease_holder="broker",
                    writer_present=False,
                    model_write_access=False,
                    broker_write_access=True,
                )
        else:
            raise AssertionError(f"unexpected template {template_id}")
        objects = {**dict(context), **objects}
        objects.update(self.mutate.get(template_id, {}))
        if template_id == "normal.finalise.model-stop":
            response_receipt_id = "a" * 64
        elif template_id == "normal.finalise.lease-acquire":
            response_receipt_id = "b" * 64
        else:
            response_receipt_id = f"receipt-{self.generation}"
        response: dict[str, Any] = {
            "schema": 1,
            "namespace": "normal-iteration",
            "template_id": template_id,
            "status": "observed",
            "generation": self.generation,
            "observation_signature": f"{self.generation:064x}",
            "receipt_id": response_receipt_id,
            "objects": objects,
        }
        if template_id == "normal.finalise.lease-acquire":
            response["finaliser_receipt"] = {
                "receipt_id": "f" * 64,
                "schema": "firth.state-finaliser-receipt.v1",
                "namespace": "normal-iteration",
                "repository_id": context["repository_id"],
                "incident_id": context["incident_id"],
                "unit": context["unit"],
                "branch": context["branch"],
                "worktree_id": context["worktree_id"],
                "head_commit": objects["head"],
                "head_tree": objects["head_tree"],
                "lease_epoch": objects["lease_epoch"],
                "observation_generation": self.generation,
                "observation_signature": response["observation_signature"],
                "stage": "lease-acquired",
                "policy_digest": context["policy_digest"],
            }
        response.update(self.mutate.get(f"response:{template_id}", {}))
        return response


class FakeSnapshot:
    def __init__(self) -> None:
        self.calls: list[dict[str, Any]] = []
        self.mutate: dict[str, Any] = {}
        self.fail = False

    def snapshot(self, context: Mapping[str, Any]) -> Mapping[str, Any]:
        if self.fail:
            raise RuntimeError("injected snapshot failure")
        call = copy.deepcopy(dict(context))
        self.calls.append(call)
        result = {
            "schema": 1,
            "kind": "firth-stable-source-snapshot",
            "repository_id": context["repository_id"],
            "policy_digest": context["policy_digest"],
            "incident_id": context["incident_id"],
            "unit": context["unit"],
            "branch": context["branch"],
            "head": context["head"],
            "worktree_id": context["worktree_id"],
            "head_tree": context["head_tree"],
            "base_commit": context["base_commit"],
            "base_tree": context["base_tree"],
            "lease_epoch": context["lease_epoch"],
            "observation_generation": context["observation_generation"],
            "observation_signature": context["observation_signature"],
            "stable": True,
            "snapshot_count": 1,
            "snapshot_digest": "d" * 64,
            "artifact_id": "artifact-snapshot-1",
            "patch_hash": "9" * 64,
            "changed_paths": ["meta/todos/todo.alpha.md", "src/Firth/Kernel.lean"],
        }
        manifest = {
            "base_commit": context["base_commit"],
            "head_tree": context["head_tree"],
            "patch_hash": result["patch_hash"],
            "changed_paths": result["changed_paths"],
        }
        result["changed_paths_digest"] = hashlib.sha256(
            prepare._canonical_projection_bytes(manifest)
        ).hexdigest()
        result.update(self.mutate)
        return result


class PrepareIterationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.original_projection_path = prepare.INSTALLED_POLICY_PROJECTION
        self.committed_projection = json.loads(PROJECTION_FIXTURE.read_text(encoding="utf-8"))
        self.assertEqual(
            hashlib.sha256(PROJECTION_FIXTURE.read_bytes()).hexdigest(),
            "e72af3a9a2b7fc3506d595fded5372eab2222c23042e8840e9ceeb04620e6fd1",
        )
        prepare.INSTALLED_POLICY_PROJECTION = Path(self.tmp.name) / "authority-policy.projection.json"
        self.write_projection()

    def tearDown(self) -> None:
        prepare.INSTALLED_POLICY_PROJECTION = self.original_projection_path
        self.tmp.cleanup()

    def write_projection(self, **changes: Any) -> None:
        projection = copy.deepcopy(self.committed_projection)
        for key, value in changes.items():
            projection[key] = value
        unsigned = dict(projection)
        unsigned.pop("projection_digest", None)
        projection["projection_digest"] = hashlib.sha256(
            prepare._canonical_projection_bytes(unsigned)
        ).hexdigest()
        prepare.INSTALLED_POLICY_PROJECTION.write_text(
            json.dumps(projection, separators=(",", ":")), encoding="utf-8"
        )

    def request(self) -> dict[str, Any]:
        return {
            "repository_id": "George-RD/firth",
            "policy_digest": self.committed_projection["policy_digest"],
            "main_commit": "a" * 40,
            "main_tree": "b" * 40,
            "incident_id": "019126d3-4f7a-7cc0-9b5f-123456789abc",
            "observation_generation": 10,
            "observation_signature": "e" * 64,
        }

    def selector(self, unit: str | None = "alpha") -> dict[str, Any]:
        return {"schema": 1, "next": unit}

    def preflight(self, verdict: str = "fresh", **fields: Any) -> dict[str, Any]:
        base = {
            "schema": 1,
            "verdict": verdict,
            "head": "a" * 40,
            "observation_generation": 10,
            "observation_signature": "e" * 64,
        }
        base.update(fields)
        return base

    def prepare(self, state: FakeState | None = None) -> tuple[dict[str, Any], FakeState]:
        state = state or FakeState()
        envelope = prepare.prepare_iteration(
            self.request(), self.preflight(), self.selector(), state
        )
        return envelope, state

    def test_fresh_preparation_orders_four_separately_observed_transitions(self) -> None:
        envelope, state = self.prepare()
        self.assertEqual([template for template, _ in state.calls], list(prepare.PREPARE_TEMPLATES))
        self.assertEqual([call[1]["observation_generation"] for call in state.calls], [10, 11, 12, 13])
        self.assertEqual(
            [call[1]["observation_signature"] for call in state.calls],
            ["e" * 64, f"{11:064x}", f"{12:064x}", f"{13:064x}"],
        )
        self.assertEqual(
            envelope["branch"],
            "loop/resolver.019126d34f7a7cc09b5f123456789abc",
        )
        self.assertEqual(envelope["head"], "a" * 40)
        self.assertEqual(envelope["worktree_id"], "worktree-1")
        self.assertEqual(envelope["lease_epoch"], 7)
        self.assertEqual(envelope["container_id"], "container-1")
        self.assertEqual(envelope["cgroup_id"], "cgroup-1")
        self.assertEqual(envelope["metadata_read_only"], True)
        self.assertEqual(envelope["writer"], "model")
        self.assertEqual(envelope["generation"], 14)
        self.assertEqual(len(envelope["receipts"]), 4)
        self.assertEqual(envelope["finalise_tool"], "firth_finalize")
        self.assertEqual(envelope["finalise_arguments"], [])

    def test_coordinator_never_supplies_ticket_or_effect_fields(self) -> None:
        _envelope, state = self.prepare()
        forbidden = {"ticket", "ticket_id", "operation_id", "path", "credential", "remote_url"}
        for template, context in state.calls:
            with self.subTest(template=template):
                self.assertFalse(forbidden.intersection(context))

    def test_each_response_is_observed_before_next_request(self) -> None:
        state = FakeState()
        state.mutate["response:normal.branch.create"] = {"status": "in_doubt"}
        with self.assertRaisesRegex(prepare.PreparationError, "not independently observed"):
            prepare.prepare_iteration(self.request(), self.preflight(), self.selector(), state)
        self.assertEqual([template for template, _ in state.calls], list(prepare.PREPARE_TEMPLATES[:2]))

    def test_stale_or_tampered_bindings_fail_before_launch(self) -> None:
        cases = {
            "normal.mirror.fetch": {"main_commit": "c" * 40},
            "normal.branch.create": {"branch": "loop/other"},
            "normal.worktree.create": {"metadata_read_only": False},
            "normal.lease.grant": {"writer": "broker"},
        }
        for template, mutation in cases.items():
            with self.subTest(template=template):
                state = FakeState()
                state.mutate[template] = mutation
                with self.assertRaises(prepare.PreparationError):
                    prepare.prepare_iteration(self.request(), self.preflight(), self.selector(), state)

    def test_wrong_namespace_generation_or_template_fails_closed(self) -> None:
        for mutation in (
            {"namespace": "halted-recovery"},
            {"generation": 99},
            {"template_id": "normal.branch.create"},
        ):
            with self.subTest(mutation=mutation):
                state = FakeState()
                state.mutate["response:normal.mirror.fetch"] = mutation
                with self.assertRaises(prepare.PreparationError):
                    prepare.prepare_iteration(self.request(), self.preflight(), self.selector(), state)

    def test_state_failure_is_closed_and_stops_chain(self) -> None:
        state = FakeState()
        state.fail_at = "normal.worktree.create"
        with self.assertRaisesRegex(prepare.PreparationError, "state request failed"):
            prepare.prepare_iteration(self.request(), self.preflight(), self.selector(), state)
        self.assertEqual([template for template, _ in state.calls], list(prepare.PREPARE_TEMPLATES[:2]))

    def test_refused_preflight_verdicts_never_contact_state(self) -> None:
        for verdict in sorted(prepare.REFUSED_VERDICTS):
            with self.subTest(verdict=verdict):
                state = FakeState()
                with self.assertRaisesRegex(prepare.PreparationError, "refuses normal launch"):
                    prepare.prepare_iteration(self.request(), self.preflight(verdict), self.selector(), state)
                self.assertEqual(state.calls, [])

    def test_safe_recovery_only_verifies_existing_binding(self) -> None:
        branch = "loop/resolver.019126d34f7a7cc09b5f123456789abc"
        for verdict in sorted(prepare.SAFE_RECOVERY_VERDICTS):
            with self.subTest(verdict=verdict):
                state = FakeState()
                envelope = prepare.prepare_iteration(
                    self.request(),
                    self.preflight(
                        verdict,
                        branch=branch,
                        head="c" * 40,
                        unit="alpha",
                        incident_id="019126d3-4f7a-7cc0-9b5f-123456789abc",
                    ),
                    self.selector(),
                    state,
                )
                self.assertEqual([template for template, _ in state.calls], ["normal.binding.verify"])
                self.assertEqual(envelope["head"], "c" * 40)
                self.assertEqual(envelope["worktree_id"], "worktree-existing")
                self.assertEqual(envelope["lease_epoch"], 12)

    def test_each_preparation_transition_rejects_cross_bound_identity(self) -> None:
        cases = {
            "normal.mirror.fetch": {"unit": "beta"},
            "normal.branch.create": {"incident_id": "019126d3-4f7a-7cc0-9b5f-123456789abd"},
            "normal.worktree.create": {"head": "c" * 40},
            "normal.lease.grant": {"worktree_id": "worktree-other"},
        }
        for template_id, mutation in cases.items():
            with self.subTest(template_id=template_id):
                state = FakeState()
                state.mutate[template_id] = mutation
                with self.assertRaises(prepare.PreparationError):
                    prepare.prepare_iteration(self.request(), self.preflight(), self.selector(), state)

    def test_safe_recovery_must_match_selected_unit(self) -> None:
        state = FakeState()
        with self.assertRaisesRegex(prepare.PreparationError, "does not match selected unit"):
            prepare.prepare_iteration(
                self.request(),
                self.preflight(
                    "dirty-known-unit",
                    branch="loop/resolver.019126d34f7a7cc09b5f123456789abc",
                    head="c" * 40,
                    unit="beta",
                ),
                self.selector("alpha"),
                state,
            )
        self.assertEqual(state.calls, [])


    def test_missing_selection_or_malformed_inputs_fail_without_state(self) -> None:
        for request, preflight, selector in (
            (self.request(), self.preflight(), self.selector(None)),
            ([], self.preflight(), self.selector()),
            (self.request(), [], self.selector()),
            (self.request(), self.preflight(), []),
        ):
            state = FakeState()
            with self.assertRaises(prepare.PreparationError):
                prepare.prepare_iteration(request, preflight, selector, state)
            self.assertEqual(state.calls, [])

    def test_finalisation_stops_model_before_acl_lease_and_one_snapshot(self) -> None:
        envelope, _preparation_state = self.prepare()
        state = FakeState(generation=envelope["generation"])
        snapshot = FakeSnapshot()
        receipt = prepare.finalise_iteration(envelope, state, snapshot)
        self.assertEqual([template for template, _ in state.calls], list(prepare.FINALISE_TEMPLATES))
        self.assertEqual(
            [call[1]["observation_generation"] for call in state.calls],
            [14, 15, 16, 17],
        )
        self.assertEqual(
            [call[1]["observation_signature"] for call in state.calls],
            [f"{14:064x}", f"{15:064x}", f"{16:064x}", f"{17:064x}"],
        )
        self.assertLess(
            [template for template, _ in state.calls].index("normal.finalise.model-stop"),
            [template for template, _ in state.calls].index("normal.finalise.acl-transfer"),
        )
        self.assertEqual(len(snapshot.calls), 1)
        self.assertEqual(snapshot.calls[0]["observation_generation"], 18)
        self.assertEqual(snapshot.calls[0]["observation_signature"], f"{18:064x}")
        self.assertEqual(receipt["snapshot_digest"], "d" * 64)
        self.assertEqual(receipt["snapshot_artifact_id"], "artifact-snapshot-1")
        self.assertEqual(receipt["head"], "a" * 40)
        self.assertEqual(receipt["head_tree"], "4" * 40)
        self.assertEqual(receipt["lease_epoch"], envelope["lease_epoch"] + 1)
        self.assertEqual(receipt["state_receipt_id"], "f" * 64)
        self.assertEqual(receipt["model_terminal"], True)
        self.assertEqual(receipt["iteration_complete"], False)
        self.assertEqual(receipt["loop_exhausted"], False)
        self.assertEqual(len(receipt["receipts"]), 4)

    def test_finalisation_refuses_live_writer_or_descendant(self) -> None:
        envelope, _preparation_state = self.prepare()
        for mutation in (
            {"writer_present": True},
            {"cgroup_stopped": False},
            {"descendant_count": 1},
        ):
            with self.subTest(mutation=mutation):
                state = FakeState(generation=envelope["generation"])
                state.mutate["normal.finalise.model-stop"] = mutation
                with self.assertRaisesRegex(prepare.PreparationError, "descendant termination"):
                    prepare.finalise_iteration(envelope, state, FakeSnapshot())
                self.assertEqual(
                    [template for template, _ in state.calls],
                    list(prepare.FINALISE_TEMPLATES[:2]),
                )

    def test_finalisation_refuses_acl_lease_or_unstable_snapshot(self) -> None:
        for template, mutation in (
            ("normal.finalise.acl-transfer", {"writer": "model"}),
            ("normal.finalise.lease-acquire", {"lease_holder": "model"}),
            ("normal.finalise.lease-acquire", {"writer_present": True}),
            ("normal.finalise.lease-acquire", {"head": "9" * 40}),
        ):
            with self.subTest(template=template, mutation=mutation):
                envelope, _preparation_state = self.prepare()
                state = FakeState(generation=envelope["generation"])
                state.mutate[template] = mutation
                snapshot = FakeSnapshot()
                with self.assertRaises(prepare.PreparationError):
                    prepare.finalise_iteration(envelope, state, snapshot)
                self.assertEqual(snapshot.calls, [])
    def test_finalisation_rejects_fabricated_nonempty_attestation_receipt(self) -> None:
        envelope, _preparation_state = self.prepare()
        state = FakeState(generation=envelope["generation"])
        state.mutate["response:normal.finalise.model-stop"] = {"receipt_id": "fabricated"}
        snapshot = FakeSnapshot()
        with self.assertRaisesRegex(prepare.PreparationError, "attestation receipt"):
            prepare.finalise_iteration(envelope, state, snapshot)
        self.assertEqual(snapshot.calls, [])

        for mutation in ({"stable": False}, {"snapshot_count": 2}, {"observation_generation": 17}):
            with self.subTest(snapshot=mutation):
                envelope, _preparation_state = self.prepare()
                state = FakeState(generation=envelope["generation"])
                snapshot = FakeSnapshot()
                snapshot.mutate = mutation
                with self.assertRaises(prepare.PreparationError):
                    prepare.finalise_iteration(envelope, state, snapshot)
                self.assertEqual(len(snapshot.calls), 1)

    def test_finalisation_rejects_caller_supplied_argument_contract(self) -> None:
        envelope, _preparation_state = self.prepare()
        envelope["finalise_arguments"] = ["other-unit"]
        state = FakeState(generation=envelope["generation"])
        with self.assertRaisesRegex(prepare.PreparationError, "no-argument finaliser"):
            prepare.finalise_iteration(envelope, state, FakeSnapshot())
        self.assertEqual(state.calls, [])

    def test_finalisation_requires_installed_matching_policy_projection(self) -> None:
        envelope, _preparation_state = self.prepare()
        state = FakeState(generation=envelope["generation"])
        prepare.INSTALLED_POLICY_PROJECTION.unlink()
        with self.assertRaisesRegex(prepare.PreparationError, "unavailable"):
            prepare.finalise_iteration(envelope, state, FakeSnapshot())
        self.assertEqual(state.calls, [])

        self.write_projection(policy_digest="0" * 64)
        with self.assertRaisesRegex(prepare.PreparationError, "digest mismatch"):
            prepare.finalise_iteration(envelope, state, FakeSnapshot())
        self.assertEqual(state.calls, [])

    def test_installed_projection_rejects_tampering_and_noncanonical_json(self) -> None:
        envelope, _preparation_state = self.prepare()
        state = FakeState(generation=envelope["generation"])
        projection = json.loads(prepare.INSTALLED_POLICY_PROJECTION.read_text(encoding="utf-8"))
        projection["normal_templates"]["normal.branch.create"]["input_fields"].append("head")
        prepare.INSTALLED_POLICY_PROJECTION.write_text(json.dumps(projection), encoding="utf-8")
        with self.assertRaisesRegex(prepare.PreparationError, "digest mismatch"):
            prepare.finalise_iteration(envelope, state, FakeSnapshot())
        self.assertEqual(state.calls, [])

        prepare.INSTALLED_POLICY_PROJECTION.write_text(
            '{"schema":1,"schema":1}', encoding="utf-8"
        )
        with self.assertRaisesRegex(prepare.PreparationError, "duplicate key"):
            prepare.finalise_iteration(envelope, state, FakeSnapshot())
        self.assertEqual(state.calls, [])


if __name__ == "__main__":
    unittest.main()
