#!/usr/bin/env python3
"""Mutation regressions for the complete Lean source binding, without Lean.

All writes occur in temporary trees. Passing these tests establishes source
integrity checks, not solver provenance or the semantic validity of a proof.
"""
from __future__ import annotations

import json
import unittest
from pathlib import Path

import update_smt_proof_bindings as bindings
from test_smt_proof_bindings import invoke, source_tree


class SourceEnvelopeTests(unittest.TestCase):
    def generate(self, script: Path) -> None:
        result = invoke(script)
        self.assertEqual(result.returncode, 0, result.stderr or result.stdout)

    def rejected_without_write(self, script: Path, source: Path, *, write: bool = False) -> str:
        before = source.read_bytes(), source.stat().st_mtime_ns
        result = invoke(script, *(() if write else ("--check",)))
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual((source.read_bytes(), source.stat().st_mtime_ns), before)
        return result.stderr

    def test_unmarked_request_helper_changes_invalidate_pins(self) -> None:
        with source_tree(real_sources=True) as (_, script, source):
            self.generate(script)
            text = source.read_text(encoding="utf-8")
            mutated = text.replace("let bindings := formulaBindings formula",
                                   "let bindings := (formulaBindings formula).reverse", 1)
            self.assertNotEqual(mutated, text)
            source.write_text(mutated, encoding="utf-8")
            self.assertIn("drift", self.rejected_without_write(script, source))

    def test_unmarked_elaborator_helper_changes_invalidate_pins(self) -> None:
        with source_tree(real_sources=True) as (root, script, source):
            self.generate(script)
            helper = root / "src/elaborator/Firth/Refinement.lean"
            text = helper.read_text(encoding="utf-8")
            mutated = text.replace("pure (predicateValue && restValue)",
                                   "pure (predicateValue || restValue)", 1)
            self.assertNotEqual(mutated, text)
            helper.write_text(mutated, encoding="utf-8")
            self.assertIn("drift", self.rejected_without_write(script, source))

    def test_transitive_module_changes_invalidate_pins(self) -> None:
        with source_tree(real_sources=True) as (root, script, source):
            self.generate(script)
            helper = root / "src/elaborator/Firth/StackEffect.lean"
            helper.write_text(helper.read_text(encoding="utf-8") + "\n-- changed dependency\n", encoding="utf-8")
            self.assertIn("drift", self.rejected_without_write(script, source))

    def test_added_lean_source_is_bound_without_import_parsing(self) -> None:
        with source_tree() as (root, script, source):
            self.generate(script)
            (root / "src/Helper.lean").write_text("def helper := 1\n", encoding="utf-8")
            self.assertIn("drift", self.rejected_without_write(script, source))

    def test_deleted_lean_source_invalidates_pins(self) -> None:
        with source_tree() as (root, script, source):
            helper = root / "src/Helper.lean"
            helper.write_text("def helper := 1\n", encoding="utf-8")
            self.generate(script)
            helper.unlink()
            self.assertIn("drift", self.rejected_without_write(script, source))

    def test_renamed_source_is_bound_by_path_not_only_content(self) -> None:
        with source_tree() as (root, script, source):
            helper = root / "src/Helper.lean"
            helper.write_text("def helper := 1\n", encoding="utf-8")
            self.generate(script)
            helper.rename(root / "src/Other.lean")
            self.assertIn("drift", self.rejected_without_write(script, source))

    def test_build_and_toolchain_inputs_are_bound(self) -> None:
        for name in bindings.BUILD_INPUTS:
            with self.subTest(name=name), source_tree() as (root, script, source):
                self.generate(script)
                path = root / name
                path.write_bytes(path.read_bytes() + b"\n")
                self.assertIn("drift", self.rejected_without_write(script, source))

    def test_missing_build_inputs_never_regenerate(self) -> None:
        for name in bindings.BUILD_INPUTS:
            with self.subTest(name=name), source_tree() as (root, script, source):
                (root / name).unlink()
                self.assertIn("input", self.rejected_without_write(script, source, write=True))

    def test_missing_required_source_never_regenerates(self) -> None:
        with source_tree() as (root, script, source):
            (root / "src/elaborator/Firth/Refinement.lean").unlink()
            self.assertIn("missing", self.rejected_without_write(script, source, write=True))

    def test_undeclared_and_unsupported_source_roots_are_refused(self) -> None:
        for directory in (None, ".", "../src", "/tmp/source", "other", "src/../other", "src/missing"):
            with self.subTest(directory=directory), source_tree() as (root, script, source):
                declaration = "" if directory is None else f"srcDir = {json.dumps(directory)}\n"
                (root / "lakefile.toml").write_text(
                    'name = "fixture"\n[[lean_lib]]\nname = "Fixture"\n' + declaration,
                    encoding="utf-8",
                )
                self.assertIn("source", self.rejected_without_write(script, source, write=True))

    def test_new_external_dependencies_are_refused_in_config_and_lock(self) -> None:
        for location in ("config", "lock"):
            with self.subTest(location=location), source_tree() as (root, script, source):
                if location == "lock":
                    (root / "lake-manifest.json").write_text('{"packages": [{"name": "external"}]}', encoding="utf-8")
                else:
                    config = root / "lakefile.toml"
                    config.write_text(config.read_text(encoding="utf-8") + '\n[[require]]\nname = "external"\n', encoding="utf-8")
                self.assertIn("dependencies", self.rejected_without_write(script, source, write=True))

    def test_competing_lakefile_is_refused(self) -> None:
        with source_tree() as (root, script, source):
            (root / "lakefile.lean").write_text("import Lake\n", encoding="utf-8")
            self.assertIn("competing", self.rejected_without_write(script, source, write=True))

    def test_duplicate_lock_members_are_refused(self) -> None:
        with source_tree() as (root, script, source):
            (root / "lake-manifest.json").write_text('{"packages": [{}], "packages": []}', encoding="utf-8")
            self.assertIn("duplicate", self.rejected_without_write(script, source, write=True))

    def test_malformed_build_inputs_never_regenerate(self) -> None:
        for name in ("lakefile.toml", "lake-manifest.json"):
            with self.subTest(name=name), source_tree() as (root, script, source):
                (root / name).write_text("{malformed", encoding="utf-8")
                self.rejected_without_write(script, source, write=True)

    def test_symlinked_lean_file_is_refused(self) -> None:
        with source_tree() as (root, script, source):
            target = root / "outside.lean"
            target.write_text("def hidden := 1\n", encoding="utf-8")
            (root / "src/Helper.lean").symlink_to(target)
            self.assertIn("symlink", self.rejected_without_write(script, source, write=True))

    def test_symlinked_source_directory_is_refused(self) -> None:
        with source_tree() as (root, script, source):
            target = root / "outside"
            target.mkdir()
            (root / "src/shared").symlink_to(target, target_is_directory=True)
            self.assertIn("symlink", self.rejected_without_write(script, source, write=True))

    def test_symlinked_source_root_is_refused(self) -> None:
        with source_tree() as (root, script, source):
            (root / "src").rename(root / "actual")
            (root / "src").symlink_to(root / "actual", target_is_directory=True)
            self.assertIn("symlink", self.rejected_without_write(script, source, write=True))

    def test_symlinked_build_input_is_refused(self) -> None:
        with source_tree() as (root, script, source):
            path = root / "lean-toolchain"
            path.rename(root / "pin")
            path.symlink_to(root / "pin")
            self.assertIn("symlink", self.rejected_without_write(script, source, write=True))

    def test_helper_between_pin_and_validation_declarations_is_preserved_and_bound(self) -> None:
        with source_tree() as (_, script, source):
            text = source.read_text(encoding="utf-8")
            text = text.replace("\ndef validSmtProofBindings", "\ndef hidden := 1\n\ndef validSmtProofBindings")
            source.write_text(text, encoding="utf-8")
            self.generate(script)
            self.assertIn("def hidden := 1", source.read_text(encoding="utf-8"))
            source.write_text(source.read_text(encoding="utf-8").replace("def hidden := 1", "def hidden := 2"), encoding="utf-8")
            self.assertIn("drift", self.rejected_without_write(script, source))

    def test_executable_pin_initializer_cannot_be_masked(self) -> None:
        with source_tree() as (_, script, source):
            text = source.read_text(encoding="utf-8").replace(
                'translationRuleHashes := ["uninitialised"]',
                'translationRuleHashes := (let hidden := ["uninitialised"]; hidden)',
            )
            source.write_text(text, encoding="utf-8")
            self.assertIn("literal", self.rejected_without_write(script, source, write=True))

    def test_pin_tampering_still_fails_check(self) -> None:
        with source_tree() as (_, script, source):
            self.generate(script)
            text = source.read_text(encoding="utf-8").replace("sha256:", "sha256:tampered", 1)
            source.write_text(text, encoding="utf-8")
            self.assertIn("drift", self.rejected_without_write(script, source))

    def test_envelope_order_does_not_depend_on_directory_enumeration(self) -> None:
        snapshot = bindings.source_snapshot()
        self.assertEqual(bindings.source_envelope(snapshot),
                         bindings.source_envelope(dict(reversed(list(snapshot.items())))))

    def test_regions_are_domain_separated_and_length_framed(self) -> None:
        self.assertNotEqual(bindings.frame(b"ab") + bindings.frame(b"c"),
                            bindings.frame(b"a") + bindings.frame(b"bc"))
        digest = bindings.region_hash("a" * 64, "rule", "stage", "body")
        for values in (("b" * 64, "rule", "stage", "body"),
                       ("a" * 64, "soundness", "stage", "body"),
                       ("a" * 64, "rule", "stage2", "body"),
                       ("a" * 64, "rule", "stage", "body2")):
            self.assertNotEqual(digest, bindings.region_hash(*values))

    def test_non_lean_files_are_not_accidentally_included(self) -> None:
        with source_tree() as (root, script, source):
            self.generate(script)
            before = source.read_bytes()
            (root / "src/unrelated.txt").write_text("not a Lean dependency\n", encoding="utf-8")
            result = invoke(script, "--check")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(source.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
