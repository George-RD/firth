import Firth.ProgramLogic
import exports.Stdlib.Core

/-!
`core.min-int` and `core.max-int` from `stdlib/core.firth`, proved from their
exported kernel programs under `int64Gamma`. Both compare with `<` alone, so
no arithmetic can overflow and every pair of i64 values is covered.

Each word is written with locals, so its body reaches the two arguments with
`pick` and `roll` and passes the chosen one to `if` inside a quotation. Each
branch is proved by `runs_chain`, which settles the `if` from the hypothesis
on the comparison.
-/

namespace Firth.Proofs.Stdlib.Core
open Firth.Interpreter
open Firth.Logic
open Firth.ReferenceRun
open Firth.Exports.Stdlib.Core

theorem min_int_of_lt (a b : Int) (tail : Stack) (h : a < b) :
    Runs int64Gamma dictionary defaultCosts «core.min-int».body
      (.literal (.int b) :: .literal (.int a) :: tail) (.literal (.int a) :: tail) 13 12 := by
  runs_chain

theorem min_int_of_not_lt (a b : Int) (tail : Stack) (h : ¬ a < b) :
    Runs int64Gamma dictionary defaultCosts «core.min-int».body
      (.literal (.int b) :: .literal (.int a) :: tail) (.literal (.int b) :: tail) 13 12 := by
  runs_chain

theorem max_int_of_lt (a b : Int) (tail : Stack) (h : a < b) :
    Runs int64Gamma dictionary defaultCosts «core.max-int».body
      (.literal (.int b) :: .literal (.int a) :: tail) (.literal (.int b) :: tail) 13 12 := by
  runs_chain

theorem max_int_of_not_lt (a b : Int) (tail : Stack) (h : ¬ a < b) :
    Runs int64Gamma dictionary defaultCosts «core.max-int».body
      (.literal (.int b) :: .literal (.int a) :: tail) (.literal (.int a) :: tail) 13 12 := by
  runs_chain

/-- `core.min-int` leaves the smaller of its two arguments, `min a b`, in 13
transitions at a cost of 12. -/
theorem min_int (a b : Int) (tail : Stack) :
    Runs int64Gamma dictionary defaultCosts «core.min-int».body
      (.literal (.int b) :: .literal (.int a) :: tail) (.literal (.int (min a b)) :: tail) 13 12 := by
  by_cases h : a < b
  · rw [Int.min_eq_left (Int.le_of_lt h)]; exact min_int_of_lt a b tail h
  · rw [Int.min_eq_right (by omega)]; exact min_int_of_not_lt a b tail h

/-- `core.max-int` leaves the larger of its two arguments, `max a b`, in 13
transitions at a cost of 12. -/
theorem max_int (a b : Int) (tail : Stack) :
    Runs int64Gamma dictionary defaultCosts «core.max-int».body
      (.literal (.int b) :: .literal (.int a) :: tail) (.literal (.int (max a b)) :: tail) 13 12 := by
  by_cases h : a < b
  · rw [Int.max_eq_right (Int.le_of_lt h)]; exact max_int_of_lt a b tail h
  · rw [Int.max_eq_left (by omega)]; exact max_int_of_not_lt a b tail h

/-- `core.min-int`'s contract: for every pair of integers `a b`, `min a b`
within 13 transitions at a cost of at most 12. -/
def minIntContract : WordContract where
  Args := Int × Int
  pre _ := True
  input args := [.literal (.int args.2), .literal (.int args.1)]
  output args := [.literal (.int (min args.1 args.2))]
  steps _ := 13
  cost _ := 12
  witness := ⟨(0, 0), trivial⟩

/-- The recorded contract of `core.min-int`, under the i64 registry. -/
theorem min_int_contract :
    minIntContract.Holds int64Gamma dictionary defaultCosts «core.min-int».body :=
  fun args tail _ => (min_int args.1 args.2 tail).within

/-- `core.max-int`'s contract: for every pair of integers `a b`, `max a b`
within 13 transitions at a cost of at most 12. -/
def maxIntContract : WordContract where
  Args := Int × Int
  pre _ := True
  input args := [.literal (.int args.2), .literal (.int args.1)]
  output args := [.literal (.int (max args.1 args.2))]
  steps _ := 13
  cost _ := 12
  witness := ⟨(0, 0), trivial⟩

/-- The recorded contract of `core.max-int`, under the i64 registry. -/
theorem max_int_contract :
    maxIntContract.Holds int64Gamma dictionary defaultCosts «core.max-int».body :=
  fun args tail _ => (max_int args.1 args.2 tail).within

end Firth.Proofs.Stdlib.Core
