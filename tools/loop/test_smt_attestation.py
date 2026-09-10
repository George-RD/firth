#!/usr/bin/env python3
"""Tests for the sealed SMT provenance lint.

Every mutation runs against a temporary fixture tree with the real layout; the
tracked sources are read only by the one test that checks the committed tree.
The lint is textual, so these tests are about what it refuses, not about Lean
semantics.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import check_smt_attestation as lint

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = Path(lint.__file__)

SOLVER_FIXTURE = """import smt.Firth.SmtBoundary

namespace Firth.Smt.Solver

inductive Provenance where
  | pinnedProcess
  | injectedRunner
  deriving Repr, BEq, DecidableEq

/-- Sealed. -/
structure Attested (α : Type) where
  private mk ::
  provenance : Provenance
  value : α
  deriving Repr, BEq

abbrev AttestedResult := Attested SmtResult
abbrev AttestedVerdict := Attested RecheckVerdict

def injected (value : α) : Attested α := ⟨.injectedRunner, value⟩

end Firth.Smt.Solver
"""

BOUNDARY_FIXTURE = """import elaborator.Firth.StackEffect
import smt.Firth.SmtBoundary
import smt.Firth.SmtSolver

structure PipelineResult where
  dischargeRecords : List DischargeRecord := []

def recordExternalOutcome (requestId : String) (entry : SmtQueueEntry)
    (attested : Firth.Smt.Solver.AttestedResult) : PipelineResult :=
  if attested.provenance != .pinnedProcess then
    { leanQueue := [leanObligation obligation .unattestedProvenance] }
  else { dischargeRecords := [record] }

def recordRerunVerdict (requestId : String) (obligation : Obligation)
    (attested : Firth.Smt.Solver.AttestedVerdict) : PipelineResult :=
  match attested.value with
  | .rechecked record =>
      if attested.provenance != .pinnedProcess then
        { leanQueue := [leanObligation obligation .unattestedProvenance] }
      else { dischargeRecords := [record] }
  | _ => { dischargeRecords := [] }
"""

OTHER_FIXTURE = """import smt.Firth.SmtSolver

def readOnly (value : Firth.Smt.Solver.AttestedResult) := value.provenance
def kernel := Lean.mkConst ``Nat
"""


class Tree:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.solver = root / lint.SOLVER
        self.boundary = root / lint.BOUNDARY
        self.other = root / "src" / "elaborator" / "Other.lean"
        for path, text in ((self.solver, SOLVER_FIXTURE), (self.boundary, BOUNDARY_FIXTURE), (self.other, OTHER_FIXTURE)):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")


class SmtAttestationLintTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="firth-smt-attestation-")
        self.tree = Tree(Path(self.temporary.name))

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def assert_refused(self, fragment: str) -> None:
        errors = lint.check(self.tree.root)
        self.assertTrue(
            any(fragment in error for error in errors),
            f"expected {fragment!r} in errors, got {errors}",
        )

    def test_fixture_passes(self) -> None:
        self.assertEqual(lint.check(self.tree.root), [])

    def test_committed_tree_passes(self) -> None:
        self.assertEqual(lint.check(ROOT), [])

    def test_cli_reports_failure(self) -> None:
        self.tree.solver.write_text(SOLVER_FIXTURE.replace("  private mk ::\n", ""), encoding="utf-8")
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--root", str(self.tree.root)],
            text=True, capture_output=True, check=False, timeout=30,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("smt attestation lint failed", result.stderr)
        passing = subprocess.run(
            [sys.executable, str(SCRIPT), "--root", str(ROOT)],
            text=True, capture_output=True, check=False, timeout=30,
        )
        self.assertEqual(passing.returncode, 0, passing.stderr)

    def test_public_constructor_is_refused(self) -> None:
        self.tree.solver.write_text(SOLVER_FIXTURE.replace("  private mk ::\n", ""), encoding="utf-8")
        self.assert_refused("exactly one `private mk ::` inside structure Attested")

    def test_second_private_constructor_is_refused(self) -> None:
        self.tree.solver.write_text(
            SOLVER_FIXTURE + "\nstructure Other where\n  private mk ::\n  value : Nat\n",
            encoding="utf-8",
        )
        self.assert_refused("private constructor outside structure Attested")

    def test_second_attested_structure_is_refused(self) -> None:
        self.tree.solver.write_text(
            SOLVER_FIXTURE + "\nstructure Attested' where\n  value : Nat\n"
            + "\nstructure Attested where\n  value : Nat\n",
            encoding="utf-8",
        )
        self.assert_refused("expected exactly one `structure Attested`")

    def test_metaprogramming_in_solver_is_refused(self) -> None:
        self.tree.solver.write_text(
            SOLVER_FIXTURE + "\ndef forged := Lean.mkConst (Lean.Name.mkNum `x 0)\n", encoding="utf-8"
        )
        self.assert_refused("names 'Name.mkNum'")

    def test_named_constructor_elsewhere_is_refused(self) -> None:
        self.tree.other.write_text(
            OTHER_FIXTURE + "\ndef forged := Firth.Smt.Solver.Attested.mk .pinnedProcess 0\n",
            encoding="utf-8",
        )
        self.assert_refused("names 'Attested.mk'")

    def test_mangled_name_elsewhere_is_refused(self) -> None:
        self.tree.other.write_text(
            OTHER_FIXTURE + "\ndef forged := `_private.smt.Firth.SmtSolver.0\n", encoding="utf-8"
        )
        self.assert_refused("names '_private'")

    def test_constant_rebuild_next_to_attested_is_refused(self) -> None:
        self.tree.other.write_text(
            OTHER_FIXTURE + "\ndef forged : Attested Nat := cast (mkConst `x) ()\n", encoding="utf-8"
        )
        self.assert_refused("names 'mkConst' next to Attested")

    def test_shadow_structure_elsewhere_is_refused(self) -> None:
        self.tree.other.write_text(
            OTHER_FIXTURE + "\nstructure Attested (α : Type) where\n  provenance : Nat\n",
            encoding="utf-8",
        )
        self.assert_refused("declares another structure Attested")

    def test_third_record_site_is_refused(self) -> None:
        self.tree.boundary.write_text(
            BOUNDARY_FIXTURE + "\ndef shortcut (record : DischargeRecord) : PipelineResult :=\n"
            "  { dischargeRecords := [record] }\n",
            encoding="utf-8",
        )
        self.assert_refused("expected 2 record-publishing sites, found 3")

    def test_ungated_record_site_is_refused(self) -> None:
        self.tree.boundary.write_text(
            BOUNDARY_FIXTURE.replace(
                "  if attested.provenance != .pinnedProcess then\n"
                "    { leanQueue := [leanObligation obligation .unattestedProvenance] }\n"
                "  else { dischargeRecords := [record] }",
                "  { dischargeRecords := [record] }",
            ),
            encoding="utf-8",
        )
        self.assert_refused("built without a provenance gate")

    def test_missing_import_is_refused(self) -> None:
        self.tree.boundary.write_text(
            BOUNDARY_FIXTURE.replace("import smt.Firth.SmtSolver\n", ""), encoding="utf-8"
        )
        self.assert_refused("does not import smt.Firth.SmtSolver")

    def test_unsealed_boundary_signature_is_refused(self) -> None:
        self.tree.boundary.write_text(
            BOUNDARY_FIXTURE.replace(
                "(attested : Firth.Smt.Solver.AttestedResult)", "(result : SmtResult)"
            ),
            encoding="utf-8",
        )
        self.assert_refused("boundary signature '(attested : Firth.Smt.Solver.AttestedResult)' is absent")

    def test_empty_record_list_is_not_a_site(self) -> None:
        self.tree.boundary.write_text(
            BOUNDARY_FIXTURE + "\ndef empty : PipelineResult := { dischargeRecords := [] }\n",
            encoding="utf-8",
        )
        self.assertEqual(lint.check(self.tree.root), [])

    def test_missing_files_are_refused(self) -> None:
        self.tree.solver.unlink()
        self.assert_refused("SmtSolver.lean: missing")
        self.tree.boundary.unlink()
        self.assert_refused("Refinement.lean: missing")


if __name__ == "__main__":
    unittest.main()
