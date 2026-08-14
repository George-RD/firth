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
        self.protocol_calls = 0
        self.finalisation_protocol = prepare.FINALISATION_PROTOCOL
        self.stage_attestations: list[dict[str, Any]] = []
        self.prepared_session_attestation: dict[str, Any] | None = None
        self.duplicate_model_receipt = False
    def protocol(self) -> Mapping[str, Any]:
        self.protocol_calls += 1
        return {
            "schema": prepare.SCHEMA,
            "namespace": prepare.NAMESPACE,
            "finalisation_protocol": self.finalisation_protocol,
            "state_finaliser_receipt_schema": "firth.state-finaliser-receipt.v2",
        }

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
        elif template_id == "normal.prepared-launch":
            objects = {
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "branch": context["branch"],
                "head": context["head"],
                "worktree_id": context["worktree_id"],
                "container_id": "container-1",
                "cgroup_id": "cgroup-1",
            }
        elif template_id == "normal.lease.grant":
            objects = {
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "branch": context["branch"],
                "head": context["head"],
                "worktree_id": context["worktree_id"],
                "container_id": context["container_id"],
                "cgroup_id": context["cgroup_id"],
                "lease_epoch": 7,
                "metadata_read_only": True,
                "writer": "model",
            }
        elif template_id == "normal.binding.verify":
            objects = {
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "unit": context["unit"],
                "branch": context["branch"],
                "head": context["head"],
                "worktree_id": "worktree-existing",
                "mirror_id": "mirror-existing",
                "lease_epoch": 12,
                "metadata_read_only": True,
                "writer": "model",
                "container_id": "container-existing",
                "cgroup_id": "cgroup-existing",
            }
        elif template_id == "normal.session.initialise":
            objects = {
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "main_commit": context["main_commit"],
                "main_tree": context["main_tree"],
                "incident_id": context["incident_id"],
                "unit": context["unit"],
                "observation_generation": context["observation_generation"],
                "observation_signature": context["observation_signature"],
                "mirror_id": context["mirror_id"],
                "branch": context["branch"],
                "head": context["head"],
                "worktree_id": context["worktree_id"],
                "container_id": context["container_id"],
                "cgroup_id": context["cgroup_id"],
                "lease_epoch": context["lease_epoch"],
                "envelope_digest": context["envelope_digest"],
                "profile_volume_id": context["profile_volume_id"],
                "merge_class": context["merge_class"],
                "ruleset_digest": context["ruleset_digest"],
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
            if template_id == "normal.session.close":
                objects.update(
                    session_id=context["session_id"],
                    authorization_digest=context["authorization_digest"],
                    envelope_digest=context["envelope_digest"],
                    profile_volume_id=context["profile_volume_id"],
                    runtime_container_id=context["container_id"],
                    total_calls=0,
                    settled_calls=0,
                    in_flight_calls=0,
                    actual_tokens=0,
                    actual_cost_micros=0,
                    closed=True,
                    closed_ns="1",
                    outcome="closed",
                    close_outcome="completed",
                    model_outcome="completed",
                )
            if template_id == "normal.finalise.seal":
                objects["seal_requested"] = True
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
        if (
            template_id == "normal.finalise.model-stop"
            and self.duplicate_model_receipt
        ):
            response_receipt_id = f"{self.generation - 1:064x}"
        elif template_id == "normal.finalise.model-stop":
            response_receipt_id = "a" * 64
        elif template_id == "normal.finalise.lease-acquire":
            response_receipt_id = "b" * 64
        elif template_id == "normal.session.initialise":
            response_receipt_id = "c" * 64
        elif template_id in prepare.FINALISE_TEMPLATES:
            response_receipt_id = f"{self.generation:064x}"
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
        if template_id == "normal.session.initialise":
            attestation = {
                "schema": "firth.prepared-session-attestation.v1",
                "issuer": "firth-resolver-state",
                "namespace": "normal-iteration",
                "template_id": "normal.session.initialise",
                "stage": "session-ready",
                "policy_digest": context["policy_digest"],
                "repository_id": context["repository_id"],
                "incident_id": context["incident_id"],
                "operation_id": "operation-session-init",
                "worktree_id": context["worktree_id"],
                "container_id": context["container_id"],
                "cgroup_id": context["cgroup_id"],
                "envelope_digest": context["envelope_digest"],
                "profile_volume_id": context["profile_volume_id"],
                "session_id": "session-1",
                "authorization_digest": "a" * 64,
                "profile_digest": "e" * 64,
                "generation": self.generation,
                "observation_signature": response["observation_signature"],
                "receipt_id": response_receipt_id,
                "receipt_digest": "d" * 64,
            }
            response["session_attestation"] = attestation
            self.prepared_session_attestation = attestation
        if template_id in prepare.FINALISE_TEMPLATES:
            stage_attestation = {
                "schema": "firth.state-transition-attestation.v1",
                "source": "installed-state",
                "namespace": "normal-iteration",
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "incident_id": context["incident_id"],
                "unit": context["unit"],
                "branch": context["branch"],
                "worktree_id": context["worktree_id"],
                "template_id": template_id,
                "stage": prepare.FINALISE_STAGES[template_id],
                "generation": self.generation,
                "observation_signature": response["observation_signature"],
                "receipt_id": response_receipt_id,
                "postcondition_objects": {
                    field: objects[field]
                    for field in prepare.FINALISE_OBJECT_FIELDS[template_id]
                },
                "objects_digest": hashlib.sha256(
                    prepare._canonical_projection_bytes(
                        {
                            field: objects[field]
                            for field in prepare.FINALISE_OBJECT_FIELDS[template_id]
                        }
                    )
                ).hexdigest(),
            }
            response["stage_attestation"] = stage_attestation
            self.stage_attestations.append(stage_attestation)
        if template_id == "normal.finalise.lease-acquire":
            transition_chain_digest = hashlib.sha256(
                prepare._canonical_projection_bytes(self.stage_attestations)
            ).hexdigest()
            receipt_body = {
                "schema": "firth.state-finaliser-receipt.v2",
                "issuer": "firth-resolver-state",
                "namespace": "normal-iteration",
                "repository_id": context["repository_id"],
                "policy_digest": context["policy_digest"],
                "incident_id": context["incident_id"],
                "operation_id": "operation-finalise-lease",
                "template_id": "normal.finalise.lease-acquire",
                "unit": context["unit"],
                "branch": context["branch"],
                "worktree_id": context["worktree_id"],
                "head_commit": objects["head"],
                "head_tree": objects["head_tree"],
                "lease_epoch": objects["lease_epoch"],
                "observation_generation": self.generation,
                "observation_signature": response["observation_signature"],
                "stage": "lease-acquired",
                "transition_chain_digest": transition_chain_digest,
            }
            response["finaliser_receipt"] = {
                "receipt_id": prepare._domain_digest(
                    "finaliser_receipt", receipt_body
                ),
                **receipt_body,
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
            "b600d4de630919e9d2dded36d3e718262968baf7757630ecfa41caaab51231f9",
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
            "merge_class": "normal-auto",
            "ruleset_digest": "f" * 64,
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
            "mirror_id": "mirror-existing",
        }
        base.update(fields)
        return base

    def prepare(self, state: FakeState | None = None) -> tuple[dict[str, Any], FakeState]:
        state = state or FakeState()
        prepared = prepare.prepare_iteration(
            self.request(), self.preflight(), self.selector(), state
        )
        return prepared, state

    def test_fresh_preparation_orders_five_separately_observed_transitions(self) -> None:
        prepared, state = self.prepare()
        envelope = prepared["envelope"]
        self.assertEqual([template for template, _ in state.calls], list(prepare.PREPARE_TEMPLATES))
        self.assertEqual([call[1]["observation_generation"] for call in state.calls], [10, 11, 12, 13, 14, 15])
        self.assertEqual(
            [call[1]["observation_signature"] for call in state.calls],
            ["e" * 64, f"{11:064x}", f"{12:064x}", f"{13:064x}", f"{14:064x}", f"{15:064x}"],
        )
        launch_context = state.calls[3][1]
        lease_context = state.calls[4][1]
        session_context = state.calls[5][1]
        self.assertNotIn("container_id", launch_context)
        self.assertNotIn("cgroup_id", launch_context)
        self.assertEqual(lease_context["container_id"], "container-1")
        self.assertEqual(lease_context["cgroup_id"], "cgroup-1")
        self.assertEqual(session_context["envelope_digest"], hashlib.sha256(
            prepare._canonical_projection_bytes(envelope)
        ).hexdigest())
        self.assertEqual(session_context["profile_volume_id"], "firth-loop_prepared-worktree-1")
        self.assertEqual(envelope["branch"], "loop/resolver.019126d34f7a7cc09b5f123456789abc")
        self.assertEqual(envelope["head"], "a" * 40)
        self.assertEqual(envelope["worktree_id"], "worktree-1")
        self.assertEqual(envelope["lease_epoch"], 7)
        self.assertEqual(envelope["container_id"], "container-1")
        self.assertEqual(envelope["cgroup_id"], "cgroup-1")
        self.assertEqual(envelope["metadata_read_only"], True)
        self.assertEqual(envelope["writer"], "model")
        self.assertEqual(envelope["generation"], 15)
        self.assertEqual(envelope["merge_class"], "normal-auto")
        self.assertEqual(envelope["ruleset_digest"], "f" * 64)
        self.assertEqual(len(envelope["receipts"]), 5)
        self.assertEqual(prepared["session_attestation"]["generation"], 16)
        self.assertEqual(prepared["session_attestation"]["session_id"], "session-1")
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
                prepared = prepare.prepare_iteration(
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
                envelope = prepared["envelope"]
                self.assertEqual(
                    [template for template, _ in state.calls],
                    ["normal.binding.verify", "normal.session.initialise"],
                )
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
        prepared, _preparation_state = self.prepare()
        envelope = prepared["envelope"]
        final_generation = prepared["session_attestation"]["generation"]
        state = FakeState(generation=final_generation)
        snapshot = FakeSnapshot()
        receipt = prepare.finalise_iteration(prepared, state, snapshot)
        self.assertEqual([template for template, _ in state.calls], list(prepare.FINALISE_TEMPLATES))
        self.assertEqual(
            [call[1]["observation_generation"] for call in state.calls],
            [16, 17, 18, 19, 20],
        )
        self.assertEqual(
            [call[1]["observation_signature"] for call in state.calls],
            [f"{16:064x}", f"{17:064x}", f"{18:064x}", f"{19:064x}", f"{20:064x}"],
        )
        self.assertLess(
            [template for template, _ in state.calls].index("normal.finalise.model-stop"),
            [template for template, _ in state.calls].index("normal.finalise.acl-transfer"),
        )
        self.assertEqual(snapshot.calls[0]["observation_generation"], 21)
        self.assertEqual(snapshot.calls[0]["observation_signature"], f"{21:064x}")
        self.assertEqual(receipt["snapshot_digest"], "d" * 64)
        self.assertEqual(receipt["snapshot_artifact_id"], "artifact-snapshot-1")
        self.assertEqual(receipt["head"], "a" * 40)
        self.assertEqual(receipt["head_tree"], "4" * 40)
        self.assertEqual(receipt["lease_epoch"], envelope["lease_epoch"] + 1)
        self.assertRegex(receipt["state_receipt_id"], r"^[0-9a-f]{64}$")
        self.assertEqual(receipt["model_terminal"], True)
        self.assertEqual(receipt["iteration_complete"], False)
        self.assertEqual(receipt["loop_exhausted"], False)
        self.assertEqual(len(receipt["receipts"]), 5)
        self.assertEqual(
            [
                (
                    attestation["template_id"],
                    attestation["stage"],
                    attestation["generation"],
                    attestation["receipt_id"],
                    attestation["observation_signature"],
                )
                for attestation in receipt["transition_attestations"]
            ],
            [
                (
                    template_id,
                    prepare.FINALISE_STAGES[template_id],
                    17 + index,
                    receipt["receipts"][index],
                    f"{17 + index:064x}",
                )
                for index, template_id in enumerate(prepare.FINALISE_TEMPLATES)
            ],
        )
        edited_state = FakeState(generation=prepared["session_attestation"]["generation"])
        edited_state.mutate["normal.finalise.lease-acquire"] = {
            "head": "c" * 40,
            "head_tree": "d" * 40,
        }
        edited_receipt = prepare.finalise_iteration(
            prepared,
            edited_state,
            FakeSnapshot(),
        )
        self.assertEqual(edited_receipt["head"], "c" * 40)
        self.assertEqual(edited_receipt["head_tree"], "d" * 40)
        self.assertEqual(
            edited_receipt["state_attestation"]["operation_id"],
            "operation-finalise-lease",
        )

        unsealed_state = FakeState(generation=prepared["session_attestation"]["generation"])
        unsealed_state.mutate["normal.finalise.seal"] = {
            "seal_requested": False,
        }
        with self.assertRaisesRegex(
            prepare.PreparationError,
            "seal was not independently observed",
        ):
            prepare.finalise_iteration(prepared, unsealed_state, FakeSnapshot())
        self.assertEqual(
            [template for template, _ in unsealed_state.calls],
            ["normal.session.close", "normal.finalise.seal"],
        )

        state = FakeState(generation=prepared["session_attestation"]["generation"])
        state.mutate["response:normal.finalise.seal"] = {
            "stage_attestation": None
        }
        with self.assertRaisesRegex(
            prepare.PreparationError, "stage attestation is missing"
        ):
            prepare.finalise_iteration(prepared, state, FakeSnapshot())
    def test_finalisation_refuses_old_protocol_before_state(self) -> None:
        prepared, _preparation_state = self.prepare()
        prepared["envelope"]["finalisation_protocol"] = 1
        state = FakeState(generation=prepared["session_attestation"]["generation"])
        with self.assertRaisesRegex(
            prepare.PreparationError, "finalisation protocol mismatch"
        ):
            prepare.finalise_iteration(prepared, state, FakeSnapshot())
        self.assertEqual(state.calls, [])

    def test_finalisation_rejects_invalid_session_close_postcondition(self) -> None:
        cases = (
            {"closed": False},
            {"closed_ns": 1},
            {"closed_ns": "01"},
            {"outcome": "stopped"},
            {"close_outcome": "failed"},
            {"model_outcome": "failed"},
            {"runtime_container_id": "container-other"},
            {"total_calls": 1},
            {"in_flight_calls": 1},
            {"actual_tokens": -1},
        )
        for mutation in cases:
            with self.subTest(mutation=mutation):
                prepared, _preparation_state = self.prepare()
                state = FakeState(generation=prepared["session_attestation"]["generation"])
                state.mutate["normal.session.close"] = mutation
                snapshot = FakeSnapshot()
                with self.assertRaisesRegex(
                    prepare.PreparationError,
                    "session close postcondition",
                ):
                    prepare.finalise_iteration(prepared, state, snapshot)
                self.assertEqual(
                    [template for template, _ in state.calls],
                    ["normal.session.close"],
                )
                self.assertEqual(snapshot.calls, [])

    def test_finalisation_refuses_missing_session_attestation(self) -> None:
        prepared, _preparation_state = self.prepare()
        prepared.pop("session_attestation")
        state = FakeState(generation=16)
        with self.assertRaisesRegex(
            prepare.PreparationError, "requires envelope and session attestation"
        ):
            prepare.finalise_iteration(prepared, state, FakeSnapshot())

    def test_preparation_refuses_old_state_protocol_before_effect(self) -> None:
        state = FakeState()
        state.finalisation_protocol = 1
        with self.assertRaisesRegex(
            prepare.PreparationError, "state finalisation protocol mismatch"
        ):
            prepare.prepare_iteration(
                self.request(), self.preflight(), self.selector(), state
            )
        self.assertEqual(state.calls, [])
        self.assertEqual(state.protocol_calls, 1)

    def test_finalisation_refuses_duplicate_transition_receipt_before_acl(self) -> None:
        prepared, _preparation_state = self.prepare()
        state = FakeState(generation=prepared["session_attestation"]["generation"])
        state.duplicate_model_receipt = True
        with self.assertRaisesRegex(
            prepare.PreparationError,
            "duplicate transition receipt_id",
        ):
            prepare.finalise_iteration(prepared, state, FakeSnapshot())
        self.assertEqual(
            [template for template, _ in state.calls],
            list(prepare.FINALISE_TEMPLATES[:3]),
        )

    def test_finalisation_refuses_live_writer_or_descendant(self) -> None:
        prepared, _preparation_state = self.prepare()
        for mutation in (
            {"writer_present": True},
            {"cgroup_stopped": False},
            {"descendant_count": 1},
        ):
            with self.subTest(mutation=mutation):
                state = FakeState(generation=prepared["session_attestation"]["generation"])
                state.mutate["normal.finalise.model-stop"] = mutation
                with self.assertRaisesRegex(prepare.PreparationError, "descendant termination"):
                    prepare.finalise_iteration(prepared, state, FakeSnapshot())
                self.assertEqual(
                    [template for template, _ in state.calls],
                    list(prepare.FINALISE_TEMPLATES[:3]),
                )

    def test_finalisation_refuses_acl_lease_or_unstable_snapshot(self) -> None:
        for template, mutation in (
            ("normal.finalise.acl-transfer", {"writer": "model"}),
            ("normal.finalise.lease-acquire", {"lease_holder": "model"}),
            ("normal.finalise.lease-acquire", {"writer_present": True}),
            ("normal.finalise.lease-acquire", {"head": "z" * 40}),
        ):
            with self.subTest(template=template, mutation=mutation):
                prepared, _preparation_state = self.prepare()
                state = FakeState(generation=prepared["session_attestation"]["generation"])
                state.mutate[template] = mutation
                snapshot = FakeSnapshot()
                with self.assertRaises(prepare.PreparationError):
                    prepare.finalise_iteration(prepared, state, snapshot)
                self.assertEqual(snapshot.calls, [])
    def test_finalisation_rejects_fabricated_nonempty_attestation_receipt(self) -> None:
        prepared, _preparation_state = self.prepare()
        state = FakeState(generation=prepared["session_attestation"]["generation"])
        state.mutate["response:normal.finalise.model-stop"] = {"receipt_id": "fabricated"}
        snapshot = FakeSnapshot()
        with self.assertRaisesRegex(prepare.PreparationError, "attestation receipt"):
            prepare.finalise_iteration(prepared, state, snapshot)
        self.assertEqual(snapshot.calls, [])

        for mutation in ({"stable": False}, {"snapshot_count": 2}, {"observation_generation": 23}):
            with self.subTest(snapshot=mutation):
                prepared, _preparation_state = self.prepare()
                state = FakeState(generation=prepared["session_attestation"]["generation"])
                snapshot = FakeSnapshot()
                snapshot.mutate = mutation
                with self.assertRaises(prepare.PreparationError):
                    prepare.finalise_iteration(prepared, state, snapshot)
                self.assertEqual(len(snapshot.calls), 1)
    def test_finalisation_rejects_caller_supplied_argument_contract(self) -> None:
        prepared, _preparation_state = self.prepare()
        prepared["envelope"]["finalise_arguments"] = ["other-unit"]
        state = FakeState(generation=prepared["session_attestation"]["generation"])
        with self.assertRaisesRegex(prepare.PreparationError, "no-argument finaliser"):
            prepare.finalise_iteration(prepared, state, FakeSnapshot())
        self.assertEqual(state.calls, [])

    def test_finalisation_requires_installed_matching_policy_projection(self) -> None:
        prepared, _preparation_state = self.prepare()
        state = FakeState(generation=prepared["session_attestation"]["generation"])
        prepare.INSTALLED_POLICY_PROJECTION.unlink()
        with self.assertRaisesRegex(prepare.PreparationError, "unavailable"):
            prepare.finalise_iteration(prepared, state, FakeSnapshot())
        self.assertEqual(state.calls, [])

        self.write_projection(policy_digest="0" * 64)
        with self.assertRaisesRegex(prepare.PreparationError, "digest mismatch"):
            prepare.finalise_iteration(prepared, state, FakeSnapshot())
        self.assertEqual(state.calls, [])

    def test_installed_projection_rejects_tampering_and_noncanonical_json(self) -> None:
        prepared, _preparation_state = self.prepare()
        state = FakeState(generation=prepared["session_attestation"]["generation"])
        projection = json.loads(prepare.INSTALLED_POLICY_PROJECTION.read_text(encoding="utf-8"))
        projection["normal_templates"]["normal.branch.create"]["input_fields"].append("head")
        prepare.INSTALLED_POLICY_PROJECTION.write_text(json.dumps(projection), encoding="utf-8")
        with self.assertRaisesRegex(prepare.PreparationError, "digest mismatch"):
            prepare.finalise_iteration(prepared, state, FakeSnapshot())
        self.assertEqual(state.calls, [])

        prepare.INSTALLED_POLICY_PROJECTION.write_text(
            '{"schema":1,"schema":1}', encoding="utf-8"
        )
        with self.assertRaisesRegex(prepare.PreparationError, "duplicate key"):
            prepare.finalise_iteration(prepared, state, FakeSnapshot())
        self.assertEqual(state.calls, [])


if __name__ == "__main__":
    unittest.main()
