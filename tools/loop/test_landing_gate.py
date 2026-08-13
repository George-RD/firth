#!/usr/bin/env python3
"""Behaviour tests for exact-object landing admission."""

from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path
from typing import Any


SOURCE = Path(__file__).with_name("landing_gate.py")
spec = importlib.util.spec_from_file_location("landing_gate", SOURCE)
assert spec and spec.loader
landing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(landing)


class LandingGateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.incident_id = "019126d3-4f7a-7cc0-9b5f-123456789abc"
        self.branch = "loop/resolver.019126d34f7a7cc09b5f123456789abc"
        self.projection_fixture = Path(__file__).with_name("authority-policy.projection.json")
        self.projection = __import__("json").loads(
            self.projection_fixture.read_text(encoding="utf-8")
        )
        self.assertEqual(
            __import__("hashlib").sha256(self.projection_fixture.read_bytes()).hexdigest(),
            "e72af3a9a2b7fc3506d595fded5372eab2222c23042e8840e9ceeb04620e6fd1",
        )
        self.todo_path = "meta/todos/todo.alpha.md"
        self.before = b"---\nnode: firth.governance.loop\nstatus: in_progress\n---\n\nRequires:\n"
        self.after = b"---\nnode: firth.governance.loop\nstatus: done\n---\n\nRequires:\n"
        self.admission: dict[str, Any] = {
            "schema": 1,
            "namespace": "normal-iteration",
            "repository_id": "George-RD/firth",
            "policy_digest": self.projection["policy_digest"],
            "ruleset_digest": "b" * 64,
            "snapshot_digest": "c" * 64,
            "patch_hash": "d" * 64,
            "prepared_lease_epoch": 7,
            "prepared_generation": 4,
            "prepared_observation_signature": "5" * 64,
            "prepared_head": "1" * 40,
            "prepared_worktree_id": "worktree-1",
            "prepared_container_id": "container-1",
            "prepared_cgroup_id": "cgroup-1",
            "base_commit": "1" * 40,
            "base_tree": "2" * 40,
            "head_commit": "3" * 40,
            "head_tree": "4" * 40,
            "unit": "alpha",
            "branch": self.branch,
            "incident_id": self.incident_id,
            "merge_class": "normal-auto",
            "selected_todo": "alpha",
            "selected_todo_expected_status": "in_progress",
            "snapshot_provenance": {
                "source": "installed-state",
                "artifact_id": "artifact-1",
                "snapshot_digest": "c" * 64,
                "prepared_head": "1" * 40,
                "candidate_commit": "3" * 40,
                "candidate_tree": "4" * 40,
                "patch_hash": "d" * 64,
                "changed_paths": ["meta/todos/todo.alpha.md", "src/Firth/Kernel.lean"],
                "verified": True,
            },
        }
        manifest = {
            "base_commit": self.admission["base_commit"],
            "head_tree": self.admission["head_tree"],
            "patch_hash": self.admission["patch_hash"],
            "changed_paths": self.admission["snapshot_provenance"]["changed_paths"],
        }
        self.admission["snapshot_provenance"]["changed_paths_digest"] = __import__(
            "hashlib"
        ).sha256(landing._canonical_bytes(manifest)).hexdigest()
        self.finaliser = {
            "prepared_generation": 4,
            "prepared_observation_signature": "5" * 64,
            "schema": landing.FINALISATION_PROTOCOL,
            "kind": "firth-finaliser-receipt",
            "namespace": "normal-iteration",
            "repository_id": "George-RD/firth",
            "policy_digest": self.projection["policy_digest"],
            "incident_id": self.incident_id,
            "head": "3" * 40,
            "changed_paths_digest": self.admission["snapshot_provenance"]["changed_paths_digest"],
            "head_tree": "4" * 40,
            "unit": "alpha",
            "branch": self.branch,
            "worktree_id": "worktree-1",
            "snapshot_digest": "c" * 64,
            "snapshot_artifact_id": "artifact-1",
            "observation_signature": "e" * 64,
            "generation": 8,
            "state_receipt_id": "f" * 64,
            "lease_epoch": 8,
            "receipts": ["7" * 64, "a" * 64, "8" * 64, "b" * 64],
            "model_terminal": True,
            "state_attestation": {
                "schema": "firth.state-finaliser-receipt.v2",
                "source": "installed-state",
                "issuer": "firth-resolver-state",
                "namespace": "normal-iteration",
                "repository_id": "George-RD/firth",
                "policy_digest": self.projection["policy_digest"],
                "operation_id": "operation-finalise-lease",
                "template_id": "normal.finalise.lease-acquire",
                "incident_id": self.incident_id,
                "unit": "alpha",
                "branch": self.branch,
                "worktree_id": "worktree-1",
                "head_commit": "3" * 40,
                "head_tree": "4" * 40,
                "lease_epoch": 8,
                "observation_generation": 8,
                "observation_signature": "e" * 64,
                "stage": "lease-acquired",
                "receipt_id": "f" * 64,
            },
            "model_attestation": {
                "schema": "firth.model-stop-attestation.v1",
                "source": "installed-model",
                "repository_id": "George-RD/firth",
                "policy_digest": self.projection["policy_digest"],
                "incident_id": self.incident_id,
                "unit": "alpha",
                "branch": self.branch,
                "worktree_id": "worktree-1",
                "head": "1" * 40,
                "lease_epoch": 7,
                "container_id": "container-1",
                "cgroup_id": "cgroup-1",
                "writer_present": False,
                "cgroup_stopped": True,
                "descendant_count": 0,
                "observation_signature": "6" * 64,
                "observation_generation": 6,
                "receipt_id": "a" * 64,
            },
            "worktree_attestation": {
                "schema": "firth.worktree-lease-attestation.v1",
                "source": "installed-worktree",
                "repository_id": "George-RD/firth",
                "policy_digest": self.projection["policy_digest"],
                "incident_id": self.incident_id,
                "unit": "alpha",
                "branch": self.branch,
                "worktree_id": "worktree-1",
                "head": "3" * 40,
                "head_tree": "4" * 40,
                "lease_epoch": 8,
                "lease_holder": "broker",
                "writer_present": False,
                "model_write_access": False,
                "broker_write_access": True,
                "observation_generation": 8,
                "observation_signature": "e" * 64,
                "receipt_id": "b" * 64,
            },
            "snapshot_attestation": {
                "schema": "firth.stable-snapshot-attestation.v1",
                "source": "installed-state",
                "repository_id": "George-RD/firth",
                "policy_digest": self.projection["policy_digest"],
                "incident_id": self.incident_id,
                "unit": "alpha",
                "branch": self.branch,
                "base_commit": "1" * 40,
                "patch_hash": "d" * 64,
                "changed_paths": ["meta/todos/todo.alpha.md", "src/Firth/Kernel.lean"],
                "changed_paths_digest": self.admission["snapshot_provenance"]["changed_paths_digest"],
                "worktree_id": "worktree-1",
                "head": "3" * 40,
                "head_tree": "4" * 40,
                "lease_epoch": 8,
                "observation_generation": 8,
                "observation_signature": "e" * 64,
                "snapshot_digest": "c" * 64,
                "artifact_id": "artifact-1",
            },
            "iteration_complete": False,
            "loop_exhausted": False,
        }
        self.finaliser["transition_attestations"] = [
            {
                "schema": "firth.state-transition-attestation.v1",
                "source": "installed-state",
                "namespace": "normal-iteration",
                "repository_id": "George-RD/firth",
                "policy_digest": self.projection["policy_digest"],
                "incident_id": self.incident_id,
                "unit": "alpha",
                "branch": self.branch,
                "worktree_id": "worktree-1",
                "template_id": template_id,
                "stage": stage,
                "generation": generation,
                "observation_signature": signature,
                "receipt_id": receipt_id,
            }
            for template_id, stage, generation, signature, receipt_id in (
                ("normal.finalise.seal", "seal-requested", 5, "5" * 64, "7" * 64),
                ("normal.finalise.model-stop", "model-stopped", 6, "6" * 64, "a" * 64),
                ("normal.finalise.acl-transfer", "acl-transferred", 7, "7" * 64, "8" * 64),
                ("normal.finalise.lease-acquire", "lease-acquired", 8, "e" * 64, "b" * 64),
            )
        ]
        transition_chain_digest = __import__("hashlib").sha256(
            landing._canonical_bytes(self.finaliser["transition_attestations"])
        ).hexdigest()
        self.finaliser["state_attestation"][
            "transition_chain_digest"
        ] = transition_chain_digest
        state_body = {
            key: value
            for key, value in self.finaliser["state_attestation"].items()
            if key not in {"source", "receipt_id"}
        }
        state_receipt_id = __import__("hashlib").sha256(
            b"firth-resolver/v1/finaliser_receipt\0"
            + landing._canonical_bytes(state_body)
        ).hexdigest()
        self.finaliser["state_attestation"]["receipt_id"] = state_receipt_id
        self.finaliser["state_receipt_id"] = state_receipt_id
        self.authenticated_state_receipt = {
            key: value
            for key, value in self.finaliser["state_attestation"].items()
            if key != "source"
        }
        common = {
            "schema": 1,
            "kind": "firth-exact-object-review",
            "repository_id": "George-RD/firth",
            "policy_digest": self.projection["policy_digest"],
            "ruleset_digest": "b" * 64,
            "base_commit": "1" * 40,
            "base_tree": "2" * 40,
            "head_commit": "3" * 40,
            "head_tree": "4" * 40,
            "patch_hash": "d" * 64,
            "incident_id": self.incident_id,
            "verdict": "accept",
        }
        self.reviews = [
            {
                **common,
                "lens": "correctness",
                "model_id": "reviewer-a",
                "session_id": "session-a",
                "review_attestation": {
                    **common,
                    "schema": "firth.review-attestation.v1",
                    "source": "installed-model-gateway",
                    "lens": "correctness",
                    "model_id": "reviewer-a",
                    "session_id": "session-a",
                },
            },
            {
                **common,
                "lens": "simplicity",
                "model_id": "reviewer-b",
                "session_id": "session-b",
                "review_attestation": {
                    **common,
                    "schema": "firth.review-attestation.v1",
                    "source": "installed-model-gateway",
                    "lens": "simplicity",
                    "model_id": "reviewer-b",
                    "session_id": "session-b",
                },
            },
        ]

    def validate(
        self,
        candidate_paths: list[str] | None = None,
        *,
        finaliser: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return landing.validate_landing(self.admission,
        self.projection,
        finaliser or self.finaliser,
        self.reviews,
        {self.todo_path: self.before},
        {self.todo_path: self.after},
            candidate_paths or ["src/Firth/Kernel.lean", self.todo_path],
            self.authenticated_state_receipt,
        )

    def test_exact_identity_reviews_and_final_todo_are_admitted(self) -> None:
        result = self.validate()
        self.assertTrue(result["admitted"])
        self.assertEqual(result["result"], "merge-admissible")
        self.assertFalse(result["loop_exhausted"])

    def test_finaliser_candidate_may_differ_from_prepared_head(self) -> None:
        self.assertNotEqual(self.admission["prepared_head"], self.admission["head_commit"])
        self.assertEqual(self.finaliser["head"], self.admission["head_commit"])
        self.assertEqual(self.finaliser["head_tree"], self.admission["head_tree"])
        self.assertEqual(self.reviews[0]["head_commit"], self.admission["head_commit"])
        self.assertTrue(self.validate()["admitted"])

    def test_branch_is_derived_from_canonical_uuidv7_not_unit(self) -> None:
        for incident_id, branch in (
            ("not-an-incident", self.branch),
            (self.incident_id, "loop/alpha"),
            (self.incident_id, "loop/resolver.019126d34f7a7cc09b5f123456789abd"),
        ):
            with self.subTest(incident_id=incident_id, branch=branch):
                self.admission.update(incident_id=incident_id, branch=branch)
                with self.assertRaises(landing.LandingError):
                    self.validate()

    def test_candidate_paths_must_equal_installed_complete_tree_delta(self) -> None:
        with self.assertRaisesRegex(landing.LandingError, "complete authoritative"):
            self.validate([self.todo_path])
        with self.assertRaisesRegex(landing.LandingError, "complete authoritative"):
            self.validate(["src/Firth/Kernel.lean", self.todo_path, "src/Firth/Extra.lean"])

        admission = copy.deepcopy(self.admission)
        admission["snapshot_provenance"]["changed_paths"] = [self.todo_path]
        with self.assertRaisesRegex(
            landing.LandingError, "manifest digest|snapshot attestation changed_paths"
        ):
            landing.validate_landing(admission,
            self.projection,
            self.finaliser,
            self.reviews,
            {self.todo_path: self.before},
            {self.todo_path: self.after},
                [self.todo_path],
                self.authenticated_state_receipt,
            )

    def test_unit_and_selected_todo_require_canonical_slugs(self) -> None:
        for field in ("unit", "selected_todo"):
            with self.subTest(field=field):
                admission = copy.deepcopy(self.admission)
                admission[field] = "alpha/beta"
                if field == "unit":
                    admission["selected_todo"] = "alpha/beta"
                with self.assertRaisesRegex(landing.LandingError, "canonical slug"):
                    landing.validate_landing(admission,
                    self.projection,
                    self.finaliser,
                    self.reviews,
                    {self.todo_path: self.before},
                    {self.todo_path: self.after},
                        ["src/Firth/Kernel.lean", self.todo_path],
                        self.authenticated_state_receipt,
                    )

        admission = copy.deepcopy(self.admission)
        admission["snapshot_provenance"]["changed_paths"] = [self.todo_path]
        altered_manifest = {
            "base_commit": admission["base_commit"],
            "head_tree": admission["head_tree"],
            "patch_hash": admission["patch_hash"],
            "changed_paths": [self.todo_path],
        }
        admission["snapshot_provenance"]["changed_paths_digest"] = __import__(
            "hashlib"
        ).sha256(landing._canonical_bytes(altered_manifest)).hexdigest()
        with self.assertRaisesRegex(landing.LandingError, "finaliser changed path"):
            landing.validate_landing(admission,
            self.projection,
            self.finaliser,
            self.reviews,
            {self.todo_path: self.before},
            {self.todo_path: self.after},
                [self.todo_path],
                self.authenticated_state_receipt,
            )

    def test_finaliser_and_reviews_bind_the_same_exact_objects(self) -> None:
        mutations = (
            (self.finaliser, "incident_id", "019126d3-4f7a-7cc0-9b5f-123456789abd"),
            (self.finaliser, "head", "5" * 40),
            (self.reviews[0], "patch_hash", "f" * 64),
            (self.reviews[1], "head_tree", "6" * 40),
        )
        for target, field, value in mutations:
            with self.subTest(field=field):
                original = target[field]
                target[field] = value
                with self.assertRaises(landing.LandingError):
                    self.validate()
                target[field] = original
    def test_installed_attestations_reject_fabricated_or_cross_bound_receipts(self) -> None:
        for key in ("state_attestation", "model_attestation", "worktree_attestation", "snapshot_attestation"):
            fabricated = copy.deepcopy(self.finaliser)
            fabricated.pop(key)
            original = self.finaliser
            self.finaliser = fabricated
            with self.subTest(missing=key), self.assertRaises(landing.LandingError):
                self.validate()
            self.finaliser = original

        mutations = (
            (self.finaliser["state_attestation"], "incident_id", "019126d3-4f7a-7cc0-9b5f-123456789abd"),
            (self.finaliser["state_attestation"], "unit", "beta"),
            (self.finaliser["model_attestation"], "worktree_id", "worktree-other"),
            (self.finaliser["worktree_attestation"], "head", "5" * 40),
            (self.finaliser["snapshot_attestation"], "head_tree", "6" * 40),
        )
        for target, field, value in mutations:
            with self.subTest(field=field):
                original = target[field]
                target[field] = value
                with self.assertRaises(landing.LandingError):
                    self.validate()
                target[field] = original

    def test_policy_version_and_projection_drift_fail_closed(self) -> None:
        projection = copy.deepcopy(self.projection)
        projection["policy_version"] = 2
        unsigned = dict(projection)
        unsigned.pop("projection_digest")
        projection["projection_digest"] = __import__("hashlib").sha256(
            landing._canonical_bytes(unsigned)
        ).hexdigest()
        original = self.projection
        self.projection = projection
        with self.assertRaisesRegex(landing.LandingError, "policy version"):
            self.validate()
        self.projection = original

    def test_fabricated_review_without_installed_attestation_is_rejected(self) -> None:
        reviews = copy.deepcopy(self.reviews)
        reviews[0].pop("review_attestation")
        with self.assertRaisesRegex(landing.LandingError, "reviewer attestation"):
            landing.validate_landing(self.admission,
            self.projection,
            self.finaliser,
            reviews,
            {self.todo_path: self.before},
            {self.todo_path: self.after},
                [self.todo_path],
                self.authenticated_state_receipt,
            )

    def test_review_receipts_must_be_distinct_external_lenses(self) -> None:
        duplicate = copy.deepcopy(self.reviews)
        duplicate[1]["model_id"] = duplicate[0]["model_id"]
        duplicate[1]["session_id"] = duplicate[0]["session_id"]
        with self.assertRaisesRegex(landing.LandingError, "distinct"):
            landing.validate_landing(self.admission,
            self.projection,
            self.finaliser,
            duplicate,
            {self.todo_path: self.before},
            {self.todo_path: self.after},
                [self.todo_path],
                self.authenticated_state_receipt,
            )

    def test_only_selected_todo_status_may_change(self) -> None:
        changed = self.after.replace(b"Requires:\n", b"Requires: beta\n")
        with self.assertRaisesRegex(landing.LandingError, "sanctioned final status"):
            landing.validate_landing(self.admission,
            self.projection,
            self.finaliser,
            self.reviews,
            {self.todo_path: self.before},
            {self.todo_path: changed},
                [self.todo_path],
                self.authenticated_state_receipt,
            )

    def test_duplicate_todo_status_is_rejected(self) -> None:
        duplicate_before = self.before.replace(
            b"status: in_progress\n",
            b"status: blocked\nstatus: in_progress\n",
        )
        duplicate_after = self.after.replace(
            b"status: done\n",
            b"status: blocked\nstatus: done\n",
        )
        with self.assertRaisesRegex(landing.LandingError, "sanctioned final status"):
            landing.validate_landing(self.admission,
            self.projection,
            self.finaliser,
            self.reviews,
            {self.todo_path: duplicate_before},
            {self.todo_path: duplicate_after},
                [self.todo_path],
                self.authenticated_state_receipt,
            )

    def test_old_finaliser_protocol_is_rejected(self) -> None:
        finaliser = copy.deepcopy(self.finaliser)
        finaliser["schema"] = 1
        with self.assertRaisesRegex(landing.LandingError, "protocol mismatch"):
            self.validate(finaliser=finaliser)

    def test_finaliser_requires_exact_generation_and_lease_successors(self) -> None:
        for field, value in (
            ("generation", 9),
            ("prepared_generation", 3),
            ("prepared_observation_signature", "4" * 64),
            ("lease_epoch", 9),
        ):
            with self.subTest(field=field):
                finaliser = copy.deepcopy(self.finaliser)
                finaliser[field] = value
                with self.assertRaises(landing.LandingError):
                    self.validate([self.todo_path], finaliser=finaliser)

        for attestation in ("state_attestation", "worktree_attestation", "snapshot_attestation"):
            with self.subTest(attestation=attestation):
                finaliser = copy.deepcopy(self.finaliser)
                finaliser[attestation]["lease_epoch"] = 9
                with self.assertRaises(landing.LandingError):
                    self.validate([self.todo_path], finaliser=finaliser)

        finaliser = copy.deepcopy(self.finaliser)
        finaliser["model_attestation"]["observation_generation"] = 7
        with self.assertRaises(landing.LandingError):
            self.validate([self.todo_path], finaliser=finaliser)

        for field, value in (
            ("stage", "lease-acquired"),
            ("source", "caller"),
            ("generation", 8),
            ("receipt_id", "b" * 64),
        ):
            with self.subTest(transition_field=field):
                finaliser = copy.deepcopy(self.finaliser)
                finaliser["transition_attestations"][0][field] = value
                with self.assertRaises(landing.LandingError):
                    self.validate([self.todo_path], finaliser=finaliser)

        finaliser = copy.deepcopy(self.finaliser)
        finaliser["transition_attestations"].reverse()
        with self.assertRaises(landing.LandingError):
            self.validate([self.todo_path], finaliser=finaliser)

        finaliser = copy.deepcopy(self.finaliser)
        finaliser["receipts"][2] = finaliser["receipts"][0]
        finaliser["transition_attestations"][2]["receipt_id"] = finaliser["receipts"][0]
        with self.assertRaisesRegex(landing.LandingError, "duplicated"):
            self.validate([self.todo_path], finaliser=finaliser)

        for index, label in ((0, "seal"), (2, "ACL")):
            with self.subTest(transition_signature=label):
                finaliser = copy.deepcopy(self.finaliser)
                finaliser["transition_attestations"][index][
                    "observation_signature"
                ] = "0" * 64
                with self.assertRaisesRegex(
                    landing.LandingError, "transition chain digest"
                ):
                    self.validate([self.todo_path], finaliser=finaliser)

        finaliser = copy.deepcopy(self.finaliser)
        finaliser["state_attestation"]["transition_chain_digest"] = "0" * 64
        with self.assertRaisesRegex(landing.LandingError, "not authenticated"):
            self.validate([self.todo_path], finaliser=finaliser)

        finaliser = copy.deepcopy(self.finaliser)
        finaliser["transition_attestations"][0]["observation_signature"] = "0" * 64
        forged_chain_digest = __import__("hashlib").sha256(
            landing._canonical_bytes(finaliser["transition_attestations"])
        ).hexdigest()
        finaliser["state_attestation"][
            "transition_chain_digest"
        ] = forged_chain_digest
        forged_state_body = {
            key: value
            for key, value in finaliser["state_attestation"].items()
            if key not in {"source", "receipt_id"}
        }
        forged_state_receipt_id = __import__("hashlib").sha256(
            b"firth-resolver/v1/finaliser_receipt\0"
            + landing._canonical_bytes(forged_state_body)
        ).hexdigest()
        finaliser["state_attestation"]["receipt_id"] = forged_state_receipt_id
        finaliser["state_receipt_id"] = forged_state_receipt_id
        with self.assertRaisesRegex(landing.LandingError, "not authenticated"):
            self.validate([self.todo_path], finaliser=finaliser)

        finaliser = copy.deepcopy(self.finaliser)
        for attestation in finaliser["transition_attestations"]:
            attestation["worktree_id"] = "worktree-other"
        finaliser["worktree_id"] = "worktree-other"
        finaliser["state_attestation"]["worktree_id"] = "worktree-other"
        finaliser["model_attestation"]["worktree_id"] = "worktree-other"
        finaliser["worktree_attestation"]["worktree_id"] = "worktree-other"
        finaliser["snapshot_attestation"]["worktree_id"] = "worktree-other"
        with self.assertRaisesRegex(landing.LandingError, "prepared worktree"):
            self.validate([self.todo_path], finaliser=finaliser)

        for field in ("container_id", "cgroup_id"):
            with self.subTest(prepared_identity=field):
                finaliser = copy.deepcopy(self.finaliser)
                finaliser["model_attestation"][field] = f"{field}-other"
                with self.assertRaisesRegex(landing.LandingError, field):
                    self.validate([self.todo_path], finaliser=finaliser)

    def test_selected_todo_must_match_prepared_unit(self) -> None:
        self.admission["selected_todo"] = "beta"
        with self.assertRaisesRegex(landing.LandingError, "prepared unit mismatch"):
            self.validate()

    def test_normal_auto_rejects_protected_and_git_control_paths(self) -> None:
        for path in (
            "tools/loop/landing_gate.py",
            "meta/decisions/loop-autonomy.md",
            "src/.gitmodules",
            "src/Firth/.gitconfig",
            "../src/Firth/Kernel.lean",
        ):
            with self.subTest(path=path), self.assertRaisesRegex(
                landing.LandingError, "outside normal-auto|excluded|canonical"
            ):
                self.validate(["src/Firth/Kernel.lean", self.todo_path, path])


if __name__ == "__main__":
    unittest.main()
