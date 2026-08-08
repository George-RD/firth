#!/usr/bin/env python3
"""Adversarial tests for the machine-readable TCB boundary."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import unittest

import check_tcb_boundary


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "specs" / "tcb-boundary.toml"


class TcbBoundaryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.manifest = check_tcb_boundary.load_manifest(MANIFEST)

    def assert_fails_with(self, manifest: dict, fragment: str) -> None:
        errors = check_tcb_boundary.validate_manifest(manifest, ROOT)
        self.assertTrue(
            any(fragment in error for error in errors),
            f"expected {fragment!r} in errors, got {errors}",
        )

    def test_committed_inventory_passes(self) -> None:
        self.assertEqual(check_tcb_boundary.validate_manifest(self.manifest, ROOT), [])

    def test_unknown_revalidator_fails_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["components"][0]["outputs"][0]["accepted_by"] = ["untrusted-helper"]
        self.assert_fails_with(manifest, "unknown trusted revalidator")


    def test_empty_outputs_fails_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["components"][0]["outputs"] = []
        self.assert_fails_with(manifest, "outputs must be non-empty")

    def test_unclassified_trusted_component_fails_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["components"][0]["trusted"] = True
        manifest["components"][0]["trusted_component"] = "lean-kernel"
        self.assert_fails_with(manifest, "only firth.runtime.vm may be the VM trusted component")

    def test_missing_trusted_flag_fails_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        del manifest["components"][0]["trusted"]
        self.assert_fails_with(manifest, ".trusted must be boolean")
    def test_missing_component_fails_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["components"].pop()
        self.assert_fails_with(manifest, "missing required components")


    def test_component_and_manifest_id_removal_fails_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        removed = manifest["required_component_ids"].pop()
        manifest["components"] = [
            row for row in manifest["components"] if row["id"] != removed
        ]
        self.assert_fails_with(manifest, "pinned architecture inventory")

    def test_vm_must_remain_trusted(self) -> None:
        manifest = deepcopy(self.manifest)
        vm = next(row for row in manifest["components"] if row["id"] == "firth.runtime.vm")
        vm["trusted"] = False
        del vm["trusted_component"]
        self.assert_fails_with(manifest, "firth.runtime.vm must be explicitly trusted")

    def test_each_revalidator_needs_evidence(self) -> None:
        manifest = deepcopy(self.manifest)
        harness = next(
            row for row in manifest["components"] if row["id"] == "firth.toolchain.diffharness"
        )
        harness["outputs"][0]["evidence"] = ["lean-test-driver"]
        self.assert_fails_with(manifest, "lacks evidence for trusted checker: vm")

    def test_output_coverage_is_pinned(self) -> None:
        manifest = deepcopy(self.manifest)
        elaborator = next(
            row for row in manifest["components"] if row["id"] == "firth.toolchain.elaborator"
        )
        elaborator["outputs"].pop()
        self.assert_fails_with(manifest, "missing required outputs")

    def test_paths_must_remain_inside_repository(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["source_spec"] = "../outside-spec.md"
        self.assert_fails_with(manifest, "safe repository-relative path")

    def test_structured_smt_policy_is_required(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["smt_policy"]["accepted_result"] = "sat"
        self.assert_fails_with(manifest, "accepted_result must be unsat")

    def test_non_string_smt_terms_fail_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["smt_policy"]["required_terms"].append(1)
        self.assert_fails_with(manifest, "required_terms must be exactly")
    def test_unclassified_output_fails_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["components"][0]["outputs"][0]["accepted_by"] = []
        self.assert_fails_with(manifest, "has no trusted revalidator")

    def test_missing_evidence_path_fails_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["stages"][0]["evidence_paths"] = ["does-not-exist"]
        self.assert_fails_with(manifest, "stage evidence path missing")

    def test_smt_policy_cannot_become_unconditional(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["smt_policy"]["solver_pinned"] = False
        self.assert_fails_with(manifest, "smt_policy.solver_pinned must be true")

    def test_smt_required_terms_are_pinned(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["smt_policy"]["required_terms"] = [
            "unsat",
            "content-addressed",
            "Lean",
            "rechecked",
        ]
        self.assert_fails_with(manifest, "required_terms must be exactly")


    def test_nested_stage_checker_values_fail_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["stages"][0]["trusted_components"] = [["lean-kernel"]]
        self.assert_fails_with(manifest, "stage has no trusted components")

    def test_nested_output_checker_values_fail_closed(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["components"][0]["outputs"][0]["accepted_by"] = [["lean-kernel"]]
        self.assert_fails_with(manifest, "has no trusted revalidator")

    def test_schema_version_are_pinned(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["schema"] = "other.schema"
        manifest["version"] = 2
        self.assert_fails_with(manifest, "schema must")
        self.assert_fails_with(manifest, "version must be 1")

    def test_stage_commands_are_pinned(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["stages"][0]["command"] = "echo untrusted"
        self.assert_fails_with(manifest, "stage command is not pinned")

    def test_stage_coverage_is_pinned(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["stages"].pop()
        self.assert_fails_with(manifest, "missing required stages")

    def test_source_provenance_is_pinned(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["source_spec"] = "specs/tcb-boundary.toml"
        self.assert_fails_with(manifest, "source_spec must be pinned")
    def test_boolean_version_is_not_schema_version(self) -> None:
        manifest = deepcopy(self.manifest)
        manifest["version"] = True
        self.assert_fails_with(manifest, "version must be 1")


if __name__ == "__main__":
    unittest.main()
