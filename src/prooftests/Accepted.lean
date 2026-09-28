import proofs.Programs.SumTo
import exports.Programs.Signed

/-!
Theorems the proof-record audit must accept, with exactly the coverage
`tools/loop/update_proof_records.py` expects.
-/

namespace Firth.ProofTests.Accepted
open Firth.Interpreter Firth.Logic Firth.ReferenceRun
open Firth.Exports.Programs.SumTo
open Firth.Proofs.Programs.SumTo

/-- Uses the whole `sum-to` dictionary but states a fact about `sum-acc`
only, so it covers `sum-acc` and not `sum-to`. -/
theorem narrow (tail : Stack) :
    Runs int64Gamma dictionary defaultCosts (.cons (.word "sum-acc") .empty)
      (.literal (.int ((0 : Nat) : Int)) :: .literal (.int 0) :: tail)
      (.literal (.int (0 + triangle 0)) :: tail) (14 * 0 + 8) (13 * 0 + 8) :=
  sum_acc 0 0 tail (Int.le_refl 0) (by simp only [triangle, InInt64]; omega)

/-- A body stated under `int64Gamma` and proved by `runs_chain` alone, which
closes the `InInt64` side goal of `-` from the assumption. It covers `diff`. -/
theorem int64Diff (x y : Int) (tail : Stack) (h : InInt64 (x - y)) :
    Runs int64Gamma Firth.Exports.Programs.Signed.dictionary defaultCosts
      Firth.Exports.Programs.Signed.«diff».body
      (.literal (.int y) :: .literal (.int x) :: tail) (.literal (.int (x - y)) :: tail) 1 1 := by
  runs_chain

/-- A cost table other than the default: every primitive costs 2. -/
def doubledPrimitives : CostTable := { defaultCosts with primitive := fun _ => 2 }

/-- The same body as `int64Diff` costed under `doubledPrimitives`. Its record
binds that table's digest, not the default one's. -/
theorem int64DiffDoubled (x y : Int) (tail : Stack) (h : InInt64 (x - y)) :
    Runs int64Gamma Firth.Exports.Programs.Signed.dictionary doubledPrimitives
      Firth.Exports.Programs.Signed.«diff».body
      (.literal (.int y) :: .literal (.int x) :: tail) (.literal (.int (x - y)) :: tail) 1 2 :=
  runs_cons (runs_sub_int64 (left := x) (right := y) tail h) (runs_empty _)

end Firth.ProofTests.Accepted
