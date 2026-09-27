import Firth.ProgramLogic
import exports.Programs.SumTo

/-!
`examples/programs/sum-to.firth`, proved from its exported kernel program.

For every natural `n`, the body of `sum-to` leaves `1 + 2 + ... + n` and
charges exactly `13·n + 10` under the default cost table, in `14·n + 10`
transitions. The statement is about `Firth.Exports.Programs.SumTo.dictionary`,
the programs whose body digests the export records, and `run_of_runs` turns it
into a statement about the reference runner. No input is enumerated and nothing is measured.

The two gaps every such proof inherits are stated in `src/exports/README.md`:
VM agreement rests on differential testing, and Lean's `Int` does not model
the VM's i64 overflow trap.
-/

namespace Firth.Proofs.Programs.SumTo
open Firth.Interpreter
open Firth.Logic
open Firth.ReferenceRun
open Firth.Exports.Programs.SumTo

/-- `1 + 2 + ... + n`. -/
def triangle : Nat → Int
  | 0 => 0
  | n + 1 => triangle n + (n + 1)

theorem two_mul_triangle (n : Nat) : 2 * triangle n = n * (n + 1) := by
  induction n with
  | zero => simp [triangle]
  | succ n ih =>
      simp only [triangle, Int.mul_add, ih]
      push_cast
      grind

/-- `sum-acc` adds `1 + ... + n` to the accumulator below `n`. -/
theorem sum_acc (n : Nat) (acc : Int) (tail : Stack) :
    Runs adapterGamma dictionary defaultCosts (.cons (.word "sum-acc") .empty)
      (.literal (.int n) :: .literal (.int acc) :: tail)
      (.literal (.int (acc + triangle n)) :: tail) (14 * n + 8) (13 * n + 8) := by
  induction n generalizing acc with
  | zero =>
      have body : Runs adapterGamma dictionary defaultCosts «sum-acc».body
          (.literal (.int 0) :: .literal (.int acc) :: tail) (.literal (.int acc) :: tail) 7 7 :=
        (runs_cons (runs_dup _ _) <| runs_cons (runs_literal_int 0 _) <|
          runs_cons (runs_eq 0 0 _) <| runs_cons (runs_quotation _ _) <|
          runs_cons (runs_quotation _ _) <|
          runs_cons (runs_if (condition := decide ((0 : Int) = 0))
            (by simpa using runs_cons (runs_drop _ _) (runs_empty _))) (runs_empty _)).congr
          (by simp) (by simp [defaultCosts])
      exact ((runs_word «sum-acc».entry body).congr (by simp) (by simp [defaultCosts])).congr_stacks
        (by simp) (by simp [triangle])
  | succ n ih =>
      have recurse := ih (acc + (n + 1))
      have branch : Runs adapterGamma dictionary defaultCosts
          (.cons .dup <| .cons (.lit (.int 1)) <| .cons (.prim "-") <|
            .cons (.quotation (.cons (.prim "+") .empty)) <| .cons .dip <|
            .cons (.word "sum-acc") .empty)
          (.literal (.int ((n + 1 : Nat) : Int)) :: .literal (.int acc) :: tail)
          (.literal (.int (acc + (n + 1) + triangle n)) :: tail)
          (14 * n + 8 + 7) (13 * n + 8 + 6) :=
        (runs_cons (runs_dup _ _) <| runs_cons (runs_literal_int 1 _) <|
          runs_cons (runs_sub _ 1 _) <| runs_cons (runs_quotation _ _) <|
          runs_cons (runs_dip (runs_cons (runs_add _ _ _) (runs_empty _))) <|
          (recurse.congr_stacks (by push_cast; simp) rfl)).congr
          (by omega) (by simp [defaultCosts]; omega)
      have body : Runs adapterGamma dictionary defaultCosts «sum-acc».body
          (.literal (.int ((n + 1 : Nat) : Int)) :: .literal (.int acc) :: tail)
          (.literal (.int (acc + (n + 1) + triangle n)) :: tail)
          (14 * n + 8 + 13) (13 * n + 8 + 12) :=
        (runs_cons (runs_dup _ _) <| runs_cons (runs_literal_int 0 _) <|
          runs_cons (runs_eq _ 0 _) <| runs_cons (runs_quotation _ _) <|
          runs_cons (runs_quotation _ _) <|
          runs_cons (runs_if (by simpa using branch)) (runs_empty _)).congr
          (by omega) (by simp [defaultCosts]; omega)
      exact ((runs_word «sum-acc».entry body).congr (by omega) (by simp [defaultCosts]; omega)).congr_stacks
        rfl (by simp [triangle]; grind)

/-- The body of `sum-to` leaves `1 + ... + n`, charging `13·n + 10`. This is
what the reference runner executes for the entry word, and the figure
`firth_run.py` reports as `kernel_cost`. -/
theorem sum_to_body (n : Nat) (tail : Stack) :
    Runs adapterGamma dictionary defaultCosts «sum-to».body
      (.literal (.int n) :: tail) (.literal (.int (triangle n)) :: tail)
      (14 * n + 10) (13 * n + 10) := by
  have loop := sum_acc n 0 tail
  refine Runs.congr_stacks (after := .literal (.int (0 + triangle n)) :: tail) ?_ rfl (by simp)
  runs_chain

/-- A call to `sum-to` costs one more, for the unfold. -/
theorem sum_to (n : Nat) (tail : Stack) :
    Runs adapterGamma dictionary defaultCosts (.cons (.word "sum-to") .empty)
      (.literal (.int n) :: tail) (.literal (.int (triangle n)) :: tail)
      (14 * n + 11) (13 * n + 11) :=
  (runs_word «sum-to».entry (sum_to_body n tail)).congr (by omega) (by simp [defaultCosts]; omega)

/-- The reference runner, given at least `14·n + 10` fuel, returns exactly
that for the entry body. -/
theorem run_sum_to (n : Nat) (tail : Stack) (extra : Nat) :
    run adapterGamma dictionary defaultCosts (14 * n + 10 + extra)
        { stack := .literal (.int n) :: tail, program := «sum-to».body } =
      .terminal { stack := .literal (.int (triangle n)) :: tail, program := .empty }
        (14 * n + 10) (13 * n + 10) :=
  run_of_runs (sum_to_body n tail) extra

end Firth.Proofs.Programs.SumTo
