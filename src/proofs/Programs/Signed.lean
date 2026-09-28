import Firth.ProgramLogic
import exports.Programs.Signed

/-!
`abs` from `examples/programs/signed.firth`, proved from its exported kernel
program under `int64Gamma`, the registry whose `-` traps outside i64 as the
VM's does.

`abs` is written with a local, so its body reaches the argument with the
kernel atoms `pick` and `roll`. Each branch is proved by `runs_chain` alone:
the chain settles the `if` from the hypothesis on `x`, and the i64 side
condition of `-` from the hypothesis on `0 - x`.
-/

namespace Firth.Proofs.Programs.Signed
open Firth.Interpreter
open Firth.Logic
open Firth.ReferenceRun
open Firth.Exports.Programs.Signed

/-- A negative argument is negated, in 16 transitions at a cost of 15. -/
theorem abs_of_neg (x : Int) (tail : Stack) (hx : x < 0) (hRange : InInt64 (0 - x)) :
    Runs int64Gamma dictionary defaultCosts «abs».body
      (.literal (.int x) :: tail) (.literal (.int (0 - x)) :: tail) 16 15 := by
  runs_chain

/-- Any other argument is returned unchanged, in 13 transitions at a cost of
12. -/
theorem abs_of_nonneg (x : Int) (tail : Stack) (hx : ¬ x < 0) :
    Runs int64Gamma dictionary defaultCosts «abs».body
      (.literal (.int x) :: tail) (.literal (.int x) :: tail) 13 12 := by
  runs_chain

/-- Both branches leave `|x|`, provided `-x` is in i64 range. That fails only
for the least i64 value, -2^63, whose negation overflows: there `0 x -` is a
primitive fault under `int64Gamma` and traps on the VM, so `abs` of the i64
minimum stops with an overflow trap and returns nothing. -/
theorem abs_natAbs (x : Int) (tail : Stack) (hRange : InInt64 (0 - x)) :
    RunsWithin int64Gamma dictionary defaultCosts «abs».body
      (.literal (.int x) :: tail) (.literal (.int x.natAbs) :: tail) 16 15 := by
  by_cases hx : x < 0
  · have hAbs : (x.natAbs : Int) = 0 - x := by omega
    rw [hAbs]
    exact ((abs_of_neg x tail hx hRange).within).weaken (by omega) (by omega)
  · have hAbs : (x.natAbs : Int) = x := by omega
    rw [hAbs]
    exact ((abs_of_nonneg x tail hx).within).weaken (by omega) (by omega)

/-- `abs`'s contract: every integer whose negation is in i64
(`-(2^63 - 1) ≤ x ≤ 2^63`) becomes its absolute value within 16 transitions
at a cost of at most 15. -/
def absContract : WordContract where
  Args := Int
  pre x := InInt64 (0 - x)
  input x := [.literal (.int x)]
  output x := [.literal (.int x.natAbs)]
  steps _ := 16
  cost _ := 15
  witness := ⟨0, by simp only [InInt64]; omega⟩

/-- The recorded contract of `abs`, under the i64 registry. -/
theorem abs_contract : absContract.Holds int64Gamma dictionary defaultCosts «abs».body :=
  fun x tail hRange => abs_natAbs x tail hRange

end Firth.Proofs.Programs.Signed
