import proofs.Programs.SumTo
import proofs.Programs.Signed

/-!
Theorems the proof-record audit must accept, with exactly the coverage and
bindings `tools/loop/update_proof_records.py` expects. Their contracts are in
`src/prooftests/accepted.json`.
-/

namespace Firth.ProofTests.Accepted
open Firth.Interpreter Firth.Logic Firth.ReferenceRun

/-- `sum-to` calls `sum-acc`, so its record covers both. -/
theorem sumTo : Firth.Proofs.Programs.SumTo.sumToContract.Holds int64Gamma
    Firth.Exports.Programs.SumTo.dictionary defaultCosts
    Firth.Exports.Programs.SumTo.«sum-to».body :=
  Firth.Proofs.Programs.SumTo.sum_to_contract

/-- `abs` calls nothing, so its record covers `abs` alone and none of the
other words of its source. -/
theorem absOnly : Firth.Proofs.Programs.Signed.absContract.Holds int64Gamma
    Firth.Exports.Programs.Signed.dictionary defaultCosts
    Firth.Exports.Programs.Signed.«abs».body :=
  Firth.Proofs.Programs.Signed.abs_contract

/-- `diff`: the difference of two integers whose difference is in i64. -/
def diffContract : WordContract where
  Args := Int × Int
  pre args := InInt64 (args.1 - args.2)
  input args := [.literal (.int args.2), .literal (.int args.1)]
  output args := [.literal (.int (args.1 - args.2))]
  steps _ := 1
  cost _ := 1
  witness := ⟨(0, 0), by simp only [InInt64]; omega⟩

/-- Proved by `runs_chain` alone, which closes the `InInt64` side goal of `-`
from the precondition. -/
theorem int64Diff : diffContract.Holds int64Gamma Firth.Exports.Programs.Signed.dictionary
    defaultCosts Firth.Exports.Programs.Signed.«diff».body := by
  intro ⟨x, y⟩ tail (h : InInt64 (x - y))
  exact (show Runs int64Gamma _ defaultCosts _ _ _ 1 1 by runs_chain).within

/-- A cost table other than the default: every primitive costs 2. -/
def doubledPrimitives : CostTable := { defaultCosts with primitive := fun _ => 2 }

/-- `diffContract` with the cost doubled. -/
def diffDoubledContract : WordContract := { diffContract with cost := fun _ => 2 }

/-- The same body costed under `doubledPrimitives`. Its record binds that
table's digest, not the default one's. -/
theorem int64DiffDoubled : diffDoubledContract.Holds int64Gamma
    Firth.Exports.Programs.Signed.dictionary doubledPrimitives
    Firth.Exports.Programs.Signed.«diff».body := by
  intro args tail h
  exact (runs_cons (runs_sub_int64 (left := args.1) (right := args.2) tail h)
    (runs_empty _)).within

end Firth.ProofTests.Accepted
