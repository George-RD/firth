import proofs.Programs.Signed

/-!
A contract whose precondition goes through a helper definition, for the
planted helper edit in `tools/loop/update_proof_records.py`. That check
rewrites `Allowed`'s `∧ True` to `∧ x = 0`, rebuilds this module (the proof
still holds), and requires `firthProofRecords --status` to stop counting the
record written before the edit: the printed precondition, `Allowed x`, is the
same either way, so only the statement digest, which follows `Allowed`'s
definition, can tell. The module is imported by nothing else, so the rebuild
is quick.
-/

/-- The arguments `abs` is claimed for. It is deliberately outside the
`Firth` namespace: digests follow every definition of this repository, not
only those under `Firth`, so a helper anywhere is bound. -/
def ProofTestHelpers.Allowed (x : Int) : Prop := Firth.Logic.InInt64 (0 - x) ∧ True

/-- The contract's witness, also outside `Firth` and proved the same way
before and after the planted edit, so the contract's own definition does not
change: only following `Allowed` itself can see the edit. -/
theorem ProofTestHelpers.allowed_zero : ProofTestHelpers.Allowed 0 :=
  ⟨by unfold Firth.Logic.InInt64; omega, by simp⟩

namespace Firth.ProofTests.Helper
open Firth.Interpreter Firth.Logic Firth.ReferenceRun
open Firth.Exports.Programs.Signed
open ProofTestHelpers

/-- `abs`'s contract with its precondition behind `Allowed`. -/
def absAllowedContract : WordContract where
  Args := Int
  pre := Allowed
  input x := [.literal (.int x)]
  output x := [.literal (.int x.natAbs)]
  steps _ := 16
  cost _ := 15
  witness := ⟨0, allowed_zero⟩

theorem absAllowed : absAllowedContract.Holds int64Gamma dictionary defaultCosts «abs».body :=
  fun x tail h => Firth.Proofs.Programs.Signed.abs_natAbs x tail h.1

end Firth.ProofTests.Helper
