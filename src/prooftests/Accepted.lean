import proofs.Programs.SumTo

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
    Runs adapterGamma dictionary defaultCosts (.cons (.word "sum-acc") .empty)
      (.literal (.int ((0 : Nat) : Int)) :: .literal (.int 0) :: tail)
      (.literal (.int (0 + triangle 0)) :: tail) (14 * 0 + 8) (13 * 0 + 8) :=
  sum_acc 0 0 tail

end Firth.ProofTests.Accepted
