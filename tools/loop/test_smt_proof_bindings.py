#!/usr/bin/env python3
"""Check SMT hash drift, declared proof coverage and safe regeneration.

Hash and marker checks are not semantic proof checking. Write-mode tests use
isolated source trees; no test rewrites the tracked Lean sources.
"""

from __future__ import annotations

import contextlib
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import update_smt_proof_bindings as bindings

LOOP = Path(__file__).resolve().parent
RULES = ("encoder", "serialiser", "normaliser", "vc-generator")
PROOFS = ("encoder", "serialiser", "adapter", "normaliser", "vc-generator", "normaliser-validity")
TARGET = """def defaultSmtProofBindings : SmtProofBindings :=
  { translationRuleHashes := ["uninitialised"]
    translationSoundnessProofHashes := ["uninitialised"] }

def validSmtProofBindings (value : SmtProofBindings) : Bool :=
  value == defaultSmtProofBindings
"""


def region(kind: str, name: str, body: str = "def witness := 0\n") -> str:
    return f"-- firth:{kind}-begin {name}\n{body}-- firth:{kind}-end {name}\n"


def fixture(rules: tuple[str, ...] = RULES, proofs: tuple[str, ...] = PROOFS) -> str:
    return TARGET + "\n" + "".join(region("translation-rules", name) for name in rules) + "".join(
        region("translation-soundness", name) for name in proofs
    )


@contextlib.contextmanager
def source_tree(*, real_sources: bool = False):
    """Run the real CLI against a temporary root with its normal layout."""
    with tempfile.TemporaryDirectory(prefix="firth-smt-bindings-") as temporary:
        root = Path(temporary)
        script = root / "tools/loop/update_smt_proof_bindings.py"
        script.parent.mkdir(parents=True)
        shutil.copy2(LOOP / script.name, script)
        if real_sources:
            sources = list((bindings.ROOT / "src").rglob("*.lean"))
            sources += [bindings.ROOT / name for name in bindings.BUILD_INPUTS]
            for source in sources:
                target = root / source.relative_to(bindings.ROOT)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
        else:
            for source in bindings.SOURCES:
                target = root / source.relative_to(bindings.ROOT)
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(fixture() if source == bindings.BINDINGS_SOURCE else "", encoding="utf-8")
            (root / "lean-toolchain").write_text("leanprover/lean4:v4.30.0\n", encoding="utf-8")
            (root / "lake-manifest.json").write_text('{"packages": []}\n', encoding="utf-8")
            (root / "lakefile.toml").write_text(
                'name = "fixture"\n[[lean_lib]]\nname = "Fixture"\nsrcDir = "src"\n',
                encoding="utf-8",
            )
        yield root, script, root / bindings.BINDINGS_SOURCE.relative_to(bindings.ROOT)


def invoke(script: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(script), *arguments],
        text=True,
        capture_output=True,
        check=False,
        timeout=30,
    )


class RegionParsingTests(unittest.TestCase):
    def test_preserves_region_bodies_and_order(self) -> None:
        text = region("translation-rules", "one", "  def one := 1\n\n")
        text += region("translation-soundness", "one", "theorem one := rfl\n")
        text += region("translation-rules", "two", "def two := 2\n")
        rules, proofs = bindings.regions(Path("example.lean"), text)
        self.assertEqual(rules, [("one", "  def one := 1\n\n"), ("two", "def two := 2\n")])
        self.assertEqual(proofs, [("one", "theorem one := rfl\n")])

    def test_rejects_malformed_reserved_markers(self) -> None:
        markers = (
            "-- firth:translation-rules-begni extra",
            "-- firth:translation-rules-ennd extra",
            "-- firth:translatoin-rules-begin extra",
            "-- firth:translation-rules-begin extra ",
            "-- firth:translation-rules-begin extra\t",
            "  -- firth:translation-rules-begin extra",
            "--\tfirth:translation-rules-begin extra",
            "-- firth:translation-rules-begin",
            "-- firth:translation-rules-begin extra unexpected",
            "-- firth:translation-rule-begin extra",
            "-- firth:translation-SOUNDNESS-begin extra",
            "-- FIRTH:translation-rules-begin extra",
        )
        for marker in markers:
            with self.subTest(marker=marker):
                with self.assertRaisesRegex(SystemExit, "example.lean:1:.*malformed"):
                    bindings.regions(Path("example.lean"), marker + "\n")

    def test_rejects_malformed_marker_inside_region(self) -> None:
        text = region("translation-rules", "encoder", "-- firth:translation-rules-begni hidden\n")
        with self.assertRaisesRegex(SystemExit, "malformed"):
            bindings.regions(Path("example.lean"), text)

    def test_ordinary_comments_are_not_markers(self) -> None:
        text = "-- Describes firth:translation-rules-begin without declaring one.\n"
        self.assertEqual(bindings.regions(Path("example.lean"), text), ([], []))

    def test_rejects_nested_regions(self) -> None:
        text = region("translation-rules", "outer", region("translation-soundness", "inner"))
        with self.assertRaisesRegex(SystemExit, "already open"):
            bindings.regions(Path("example.lean"), text)

    def test_rejects_unmatched_end(self) -> None:
        with self.assertRaisesRegex(SystemExit, "no region is open"):
            bindings.regions(Path("example.lean"), "-- firth:translation-rules-end encoder\n")

    def test_rejects_mismatched_name_and_kind(self) -> None:
        for suffix in ("translation-rules-end other", "translation-soundness-end encoder"):
            with self.subTest(suffix=suffix), self.assertRaisesRegex(SystemExit, "do not match"):
                bindings.regions(Path("example.lean"), "-- firth:translation-rules-begin encoder\n-- firth:" + suffix)

    def test_rejects_unclosed_region(self) -> None:
        with self.assertRaisesRegex(SystemExit, "never closed"):
            bindings.regions(Path("example.lean"), "-- firth:translation-rules-begin encoder\n")

    def test_rejects_empty_and_whitespace_only_regions(self) -> None:
        for body in ("", "\n", " \t\n"):
            with self.subTest(body=body), self.assertRaisesRegex(SystemExit, "empty"):
                bindings.regions(Path("example.lean"), region("translation-rules", "encoder", body))


class DecisionRecordTests(unittest.TestCase):
    """The decision record describing the binding mechanism states the region
    counts the generator actually requires, so it cannot silently describe a
    superseded region set."""

    WORDS = {2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight"}

    def test_decision_record_states_current_region_counts(self) -> None:
        record = LOOP.parents[1] / "meta" / "decisions" / "smt-adapter-soundness-bridge.md"
        text = " ".join(record.read_text(encoding="utf-8").split())
        rules = len(bindings.REQUIRED_RULE_REGIONS)
        proofs = rules + len(bindings.REQUIRED_PROOF_ONLY_REGIONS)
        self.assertEqual((rules, proofs), (len(RULES), len(PROOFS)))
        self.assertIn(f"{self.WORDS[rules]} translation-rule regions", text)
        self.assertIn(f"{self.WORDS[proofs]} soundness regions", text)
        for name in RULES + PROOFS:
            self.assertIn(name, text)


class RegionCoverageTests(unittest.TestCase):
    def collect(self, *texts: str):
        with tempfile.TemporaryDirectory(prefix="firth-smt-regions-") as temporary:
            sources = []
            for index, text in enumerate(texts):
                source = Path(temporary) / f"source-{index}.lean"
                source.write_text(text, encoding="utf-8")
                sources.append(source)
            with patch.object(bindings, "SOURCES", sources):
                return bindings.allRegions()

    def test_current_four_rules_and_six_proofs_are_valid(self) -> None:
        rules, proofs = self.collect(fixture())
        self.assertEqual(tuple(name for name, _ in rules), RULES)
        self.assertEqual(tuple(name for name, _ in proofs), PROOFS)

    def test_new_paired_stage_is_valid(self) -> None:
        rules, proofs = self.collect(fixture(RULES + ("new-stage",), PROOFS + ("new-stage",)))
        self.assertEqual(rules[-1][0], "new-stage")
        self.assertEqual(proofs[-1][0], "new-stage")

    def test_rejects_rule_without_soundness(self) -> None:
        with self.assertRaisesRegex(SystemExit, "without.*soundness"):
            self.collect(fixture(RULES + ("unproven",)))

    def test_rejects_unexpected_proof_only_region(self) -> None:
        with self.assertRaisesRegex(SystemExit, "without.*rule"):
            self.collect(fixture(proofs=PROOFS + ("unrelated",)))

    def test_rejects_removal_of_an_established_pair(self) -> None:
        for removed in RULES:
            with self.subTest(removed=removed), self.assertRaisesRegex(SystemExit, "required.*rule"):
                self.collect(fixture(tuple(name for name in RULES if name != removed), tuple(name for name in PROOFS if name != removed)))

    def test_rejects_missing_required_proof_only_regions(self) -> None:
        for removed in ("adapter", "normaliser-validity"):
            with self.subTest(removed=removed), self.assertRaisesRegex(SystemExit, "required.*soundness"):
                self.collect(fixture(proofs=tuple(name for name in PROOFS if name != removed)))

    def test_proof_only_names_cannot_become_rules(self) -> None:
        for name in ("adapter", "normaliser-validity"):
            with self.subTest(name=name), self.assertRaisesRegex(SystemExit, "proof-only"):
                self.collect(fixture(RULES + (name,)))

    def test_rejects_duplicate_rule_names_in_one_file(self) -> None:
        with self.assertRaisesRegex(SystemExit, "rule region.*declared twice"):
            self.collect(fixture() + region("translation-rules", "encoder"))

    def test_rejects_duplicate_rule_names_across_files(self) -> None:
        with self.assertRaisesRegex(SystemExit, "rule region.*declared twice"):
            self.collect(fixture(), region("translation-rules", "encoder"))

    def test_rejects_duplicate_proof_names_across_files(self) -> None:
        with self.assertRaisesRegex(SystemExit, "soundness region.*declared twice"):
            self.collect(fixture(), region("translation-soundness", "encoder"))

    def test_rejects_empty_sources(self) -> None:
        with self.assertRaises(SystemExit):
            self.collect("")


class SmtProofBindingsTests(unittest.TestCase):
    def test_the_bindings_match_the_marked_regions(self) -> None:
        result = invoke(LOOP / "update_smt_proof_bindings.py", "--check")
        self.assertEqual(result.returncode, 0, result.stderr or result.stdout)

    def test_the_generator_is_idempotent_without_writing_tracked_sources(self) -> None:
        tracked = {source: source.read_bytes() for source in bindings.SOURCES}
        with source_tree(real_sources=True) as (_, script, source):
            before = source.read_bytes()
            for arguments in ((), (), ("--check",)):
                result = invoke(script, *arguments)
                self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
                self.assertEqual(source.read_bytes(), before)
        for source, before in tracked.items():
            self.assertEqual(source.read_bytes(), before, f"tracked source changed: {source}")

    def test_check_mode_does_not_write(self) -> None:
        with source_tree() as (_, script, source):
            self.assertEqual(invoke(script).returncode, 0)
            before = source.read_bytes(), source.stat().st_mtime_ns
            self.assertEqual(invoke(script, "--check").returncode, 0)
            self.assertEqual((source.read_bytes(), source.stat().st_mtime_ns), before)

    def test_unknown_arguments_never_regenerate(self) -> None:
        with source_tree() as (_, script, source):
            before = source.read_bytes()
            for argument in ("--chek", "--check=unexpected", "unexpected"):
                with self.subTest(argument=argument):
                    result = invoke(script, argument)
                    self.assertEqual(result.returncode, 2, result.stderr)
                    self.assertEqual(source.read_bytes(), before)

    def test_help_never_regenerates(self) -> None:
        with source_tree() as (_, script, source):
            before = source.read_bytes()
            result = invoke(script, "--help")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("usage:", result.stdout)
            self.assertEqual(source.read_bytes(), before)

    def test_check_rejects_misspelled_new_region(self) -> None:
        with source_tree() as (_, script, source):
            self.assertEqual(invoke(script).returncode, 0)
            source.write_text(source.read_text(encoding="utf-8") +
                              "-- firth:translation-rules-begni hidden\ndef hidden := 1\n"
                              "-- firth:translation-rules-ennd hidden\n", encoding="utf-8")
            before = source.read_bytes()
            result = invoke(script, "--check")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("malformed", result.stderr)
            self.assertEqual(source.read_bytes(), before)

    def test_write_mode_rejects_unpaired_stage_without_repinning(self) -> None:
        with source_tree() as (_, script, source):
            self.assertEqual(invoke(script).returncode, 0)
            source.write_text(source.read_text(encoding="utf-8") + region("translation-rules", "unproven"), encoding="utf-8")
            before = source.read_bytes()
            result = invoke(script)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("without", result.stderr)
            self.assertEqual(source.read_bytes(), before)

    def test_rule_and_proof_body_mutations_are_detected(self) -> None:
        for kind in ("translation-rules", "translation-soundness"):
            with self.subTest(kind=kind), source_tree() as (_, script, source):
                self.assertEqual(invoke(script).returncode, 0)
                old = region(kind, "encoder")
                source.write_text(source.read_text(encoding="utf-8").replace(old, region(kind, "encoder", "def witness := 1\n"), 1), encoding="utf-8")
                before = source.read_bytes()
                result = invoke(script, "--check")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("drift", result.stderr)
                self.assertEqual(source.read_bytes(), before)

    def test_rejects_multiple_bindings_declarations(self) -> None:
        with source_tree() as (_, script, source):
            source.write_text(fixture() + TARGET, encoding="utf-8")
            before = source.read_bytes()
            result = invoke(script)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("exactly one", result.stderr)
            self.assertEqual(source.read_bytes(), before)

    def test_rejects_missing_bindings_declaration(self) -> None:
        with source_tree() as (_, script, source):
            source.write_text(fixture().replace(TARGET, ""), encoding="utf-8")
            before = source.read_bytes()
            result = invoke(script)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(source.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
