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
        self.todo_path = "meta/todos/todo.alpha.md"
        self.before = b"---\nnode: firth.governance.loop\nstatus: in_progress\n---\n\nRequires:\n"
        self.after = b"---\nnode: firth.governance.loop\nstatus: done\n---\n\nRequires:\n"
        self.admission: dict[str, Any] = {
            "schema": 1,
            "namespace": "normal-iteration",
            "repository_id": "George-RD/firth",
            "policy_digest": "a" * 64,
            "ruleset_digest": "b" * 64,
            "snapshot_digest": "c" * 64,
            "patch_hash": "d" * 64,
            "prepared_head": "1" * 40,
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
                "artifact_id": "artifact-1",
                "snapshot_digest": "c" * 64,
                "prepared_head": "1" * 40,
                "candidate_commit": "3" * 40,
                "candidate_tree": "4" * 40,
                "patch_hash": "d" * 64,
                "verified": True,
            },
        }
        templates = {
            template_id: {
                "namespace": "normal-iteration",
                "max_invocations": 1,
                "retry": "never" if template_id in {"normal.binding.verify", "normal.finalise.seal"} else "reconcile-only",
                "input_fields": sorted(fields),
            }
            for template_id, fields in landing.EXPECTED_NORMAL_TEMPLATE_FIELDS.items()
        }
        self.projection = {
            "schema": 1,
            "kind": "firth-authority-policy-projection",
            "policy_version": 1,
            "repository_id": "George-RD/firth",
            "operator_repository_id": "George-RD/georges-devops",
            "policy_digest": "a" * 64,
            "issuer_namespaces": ["normal-iteration", "halted-recovery", "local-operator"],
            "merge_classes": ["normal-auto", "resolver-auto", "auto-operator", "protected-human", "manual-root"],
            "path_classes": {
                "normal-auto": {
                    "repositories": ["firth"],
                    "include": ["src/**", "meta/todos/todo.<selected-slug>.md"],
                    "exclude": ["src/**/.gitmodules", "src/**/.gitattributes", "src/**/.gitconfig"],
                    "approval": "exact-group-check",
                },
                "resolver-auto": {
                    "repositories": ["firth"],
                    "include": ["src/**"],
                    "exclude": ["src/**/.gitmodules", "src/**/.gitattributes", "src/**/.gitconfig"],
                    "approval": "exact-group-check",
                },
            },
            "completion_tcb": {
                "exclusive_command": "python3 tools/loop/coverage.py --run-gates",
                "required_paths": [".claude/commands/firth-loop.md", "tools/loop/coverage.py", "tools/loop/obligations.toml"],
                "terminal_token": "LOOP EXHAUSTED",
            },
            "normal_templates": templates,
        }
        self.projection["projection_digest"] = __import__("hashlib").sha256(
            landing._canonical_bytes(self.projection)
        ).hexdigest()
        self.finaliser = {
            "schema": 1,
            "kind": "firth-finaliser-receipt",
            "namespace": "normal-iteration",
            "repository_id": "George-RD/firth",
            "policy_digest": "a" * 64,
            "incident_id": self.incident_id,
            "head": "3" * 40,
            "head_tree": "4" * 40,
            "unit": "alpha",
            "branch": self.branch,
            "snapshot_digest": "c" * 64,
            "snapshot_artifact_id": "artifact-1",
            "observation_signature": "e" * 64,
            "state_receipt_id": "f" * 64,
            "lease_epoch": 8,
            "receipts": ["seal", "stop", "acl", "lease"],
            "model_terminal": True,
            "iteration_complete": False,
            "loop_exhausted": False,
        }
        common = {
            "schema": 1,
            "kind": "firth-exact-object-review",
            "repository_id": "George-RD/firth",
            "policy_digest": "a" * 64,
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
            {**common, "lens": "correctness", "model_id": "reviewer-a", "session_id": "session-a"},
            {**common, "lens": "simplicity", "model_id": "reviewer-b", "session_id": "session-b"},
        ]

    def validate(self, candidate_paths: list[str] | None = None) -> dict[str, Any]:
        return landing.validate_landing(
            self.admission,
            self.projection,
            self.finaliser,
            self.reviews,
            {self.todo_path: self.before},
            {self.todo_path: self.after},
            candidate_paths or ["src/Firth/Kernel.lean", self.todo_path],
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

    def test_review_receipts_must_be_distinct_external_lenses(self) -> None:
        duplicate = copy.deepcopy(self.reviews)
        duplicate[1]["model_id"] = duplicate[0]["model_id"]
        duplicate[1]["session_id"] = duplicate[0]["session_id"]
        with self.assertRaisesRegex(landing.LandingError, "distinct"):
            landing.validate_landing(
                self.admission,
                self.projection,
                self.finaliser,
                duplicate,
                {self.todo_path: self.before},
                {self.todo_path: self.after},
                [self.todo_path],
            )

    def test_only_selected_todo_status_may_change(self) -> None:
        changed = self.after.replace(b"Requires:\n", b"Requires: beta\n")
        with self.assertRaisesRegex(landing.LandingError, "sanctioned final status"):
            landing.validate_landing(
                self.admission,
                self.projection,
                self.finaliser,
                self.reviews,
                {self.todo_path: self.before},
                {self.todo_path: changed},
                [self.todo_path],
            )

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
