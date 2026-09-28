import Firth.ProgramLogic
import exports.Programs.SumTo

/-!
`examples/programs/sum-to.firth`, proved from its exported kernel program.

For every natural `n` whose triangle number `1 + 2 + ... + n` is in i64
range, the body of `sum-to` leaves that number and charges exactly `13·n + 10`
under the default cost table, in `14·n + 10` transitions. The statements are
under `int64Gamma`, whose `+` and `-` trap outside i64 as the VM's do, so the
range hypothesis is exactly what rules out an overflow trap. The source's
domain is `n ≥ 0`: a negative argument never reaches the `0 =` exit and runs
until the step budget stops it, which nothing here claims otherwise.

The statements are about `Firth.Exports.Programs.SumTo.dictionary`, the
programs whose body digests the export records. `run_of_runs` and
`Runs.of_int64` turn them into statements about the reference runner. No
input is enumerated and nothing is measured. The remaining gap is stated in
`src/exports/README.md`: VM agreement rests on differential testing.
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

theorem triangle_nonneg (n : Nat) : 0 ≤ triangle n := by
  induction n with
  | zero => simp [triangle]
  | succ n ih => simp only [triangle]; omega

theorem le_triangle (n : Nat) : (n : Int) ≤ triangle n := by
  induction n with
  | zero => simp [triangle]
  | succ n ih => simp only [triangle]; push_cast; have := triangle_nonneg n; omega

/-- `sum-acc` adds `1 + ... + n` to a non-negative accumulator below `n`,
provided the final sum is in i64 range; every intermediate sum lies between
the accumulator and the final one. -/
theorem sum_acc (n : Nat) (acc : Int) (tail : Stack) (hAcc : 0 ≤ acc)
    (hRange : InInt64 (acc + triangle n)) :
    Runs int64Gamma dictionary defaultCosts (.cons (.word "sum-acc") .empty)
      (.literal (.int n) :: .literal (.int acc) :: tail)
      (.literal (.int (acc + triangle n)) :: tail) (14 * n + 8) (13 * n + 8) := by
  induction n generalizing acc with
  | zero =>
      have body : Runs int64Gamma dictionary defaultCosts «sum-acc».body
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
      have hTriangle := triangle_nonneg n
      have hLe := le_triangle n
      simp only [triangle, InInt64] at hRange
      have hNext : 0 ≤ acc + ((n : Int) + 1) := by omega
      have hNextRange : InInt64 (acc + ((n : Int) + 1) + triangle n) := by
        simp only [InInt64]; constructor <;> omega
      have recurse := ih (acc + ((n : Int) + 1)) hNext hNextRange
      have branch : Runs int64Gamma dictionary defaultCosts
          (.cons .dup <| .cons (.lit (.int 1)) <| .cons (.prim "-") <|
            .cons (.quotation (.cons (.prim "+") .empty)) <| .cons .dip <|
            .cons (.word "sum-acc") .empty)
          (.literal (.int ((n + 1 : Nat) : Int)) :: .literal (.int acc) :: tail)
          (.literal (.int (acc + (n + 1) + triangle n)) :: tail)
          (14 * n + 8 + 7) (13 * n + 8 + 6) :=
        (runs_cons (runs_dup _ _) <| runs_cons (runs_literal_int 1 _) <|
          runs_cons (runs_sub_int64 (left := ((n + 1 : Nat) : Int)) (right := 1) _
            (by simp only [InInt64]; constructor <;> omega)) <|
          runs_cons (runs_quotation _ _) <|
          runs_cons (runs_dip (runs_cons (runs_add_int64 (left := acc)
            (right := ((n + 1 : Nat) : Int)) _
            (by simp only [InInt64]; push_cast; constructor <;> omega)) (runs_empty _))) <|
          (recurse.congr_stacks (by push_cast; simp) rfl)).congr
          (by omega) (by simp [defaultCosts]; omega)
      have body : Runs int64Gamma dictionary defaultCosts «sum-acc».body
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

/-- The body of `sum-to` leaves `1 + ... + n`, charging `13·n + 10`, when that
sum is in i64 range. This is what the reference runner executes for the entry
word, and the figure `firth_run.py` reports as `kernel_cost`. -/
theorem sum_to_body (n : Nat) (tail : Stack) (hRange : InInt64 (triangle n)) :
    Runs int64Gamma dictionary defaultCosts «sum-to».body
      (.literal (.int n) :: tail) (.literal (.int (triangle n)) :: tail)
      (14 * n + 10) (13 * n + 10) := by
  have loop := sum_acc n 0 tail (Int.le_refl 0) (by simpa using hRange)
  refine Runs.congr_stacks (after := .literal (.int (0 + triangle n)) :: tail) ?_ rfl (by simp)
  runs_chain

/-- A call to `sum-to` costs one more, for the unfold. -/
theorem sum_to (n : Nat) (tail : Stack) (hRange : InInt64 (triangle n)) :
    Runs int64Gamma dictionary defaultCosts (.cons (.word "sum-to") .empty)
      (.literal (.int n) :: tail) (.literal (.int (triangle n)) :: tail)
      (14 * n + 11) (13 * n + 11) :=
  (runs_word «sum-to».entry (sum_to_body n tail hRange)).congr (by omega)
    (by simp [defaultCosts]; omega)

/-- The reference runner, given at least `14·n + 10` fuel, returns exactly
that for the entry body, with no overflow on the way. -/
theorem run_sum_to (n : Nat) (tail : Stack) (extra : Nat) (hRange : InInt64 (triangle n)) :
    run adapterGamma dictionary defaultCosts (14 * n + 10 + extra)
        { stack := .literal (.int n) :: tail, program := «sum-to».body } =
      .terminal { stack := .literal (.int (triangle n)) :: tail, program := .empty }
        (14 * n + 10) (13 * n + 10) :=
  run_of_runs (sum_to_body n tail hRange).of_int64 extra

/-- `sum-to`'s contract: for every natural `n` whose triangle number is in i64,
`n` becomes `1 + ... + n` within `14·n + 10` transitions at a cost of at most
`13·n + 10`. -/
def sumToContract : WordContract where
  Args := Nat
  pre n := InInt64 (triangle n)
  input n := [.literal (.int n)]
  output n := [.literal (.int (triangle n))]
  steps n := 14 * n + 10
  cost n := 13 * n + 10
  witness := ⟨0, by simp only [InInt64, triangle]; omega⟩

/-- The recorded contract of `sum-to`, under the i64 registry. -/
theorem sum_to_contract :
    sumToContract.Holds int64Gamma dictionary defaultCosts «sum-to».body :=
  fun n tail hRange => (sum_to_body n tail hRange).within

end Firth.Proofs.Programs.SumTo
