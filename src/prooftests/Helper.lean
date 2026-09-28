import proofs.Programs.Signed

/-!
Contracts whose precondition goes through a helper, for the planted helper
edits in `tools/loop/update_proof_records.py`. Each edit narrows one helper so
that the contract covers only `x = 0`, rebuilds this module (the proofs still
hold), and requires `firthProofRecords --status` to stop counting the record
written before the edit. The printed precondition, `Allowed` or `Ok`, is the
same either way, and so is each contract's own definition, so only a statement
digest that follows the helper's declaration can tell:

- `Allowed` is a definition; the edit rewrites its `∧ True` to `∧ x = 0`;
- `Ok` is an inductive type; the edit rewrites its constructor's premise
  `0 = x * 0`, which always holds, to `0 = x`. An inductive type has no
  value, and the witness's proof term (`rfl`) is the same either way, so a
  digest that followed only values would miss this one.

The helpers and their witnesses are deliberately outside the `Firth`
namespace: digests follow every declaration of this repository, not only
those under `Firth`. The module is imported by nothing else, so the rebuilds
are quick.
-/

/-- The arguments the first contract claims `abs` for. -/
def ProofTestHelpers.Allowed (x : Int) : Prop := Firth.Logic.InInt64 (0 - x) ∧ True

/-- The arguments the second contract claims `abs` for. -/
inductive ProofTestHelpers.Ok : Int → Prop
  | intro (x : Int) : Firth.Logic.InInt64 (0 - x) → 0 = x * 0 → ProofTestHelpers.Ok x

/-- The witnesses, proved the same way before and after each edit, so the
contracts' own definitions do not change. -/
theorem ProofTestHelpers.allowed_zero : ProofTestHelpers.Allowed 0 :=
  ⟨by unfold Firth.Logic.InInt64; omega, by simp⟩

theorem ProofTestHelpers.ok_zero : ProofTestHelpers.Ok 0 :=
  .intro 0 (by unfold Firth.Logic.InInt64; omega) rfl

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

/-- `abs`'s contract with its precondition behind `Ok`. -/
def absOkContract : WordContract where
  Args := Int
  pre := Ok
  input x := [.literal (.int x)]
  output x := [.literal (.int x.natAbs)]
  steps _ := 16
  cost _ := 15
  witness := ⟨0, ok_zero⟩

theorem absOk : absOkContract.Holds int64Gamma dictionary defaultCosts «abs».body :=
  fun x tail h => match h with
    | .intro _ hRange _ => Firth.Proofs.Programs.Signed.abs_natAbs x tail hRange

end Firth.ProofTests.Helper
