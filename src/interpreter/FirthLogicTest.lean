import Firth.ProgramLogic

/-!
Regression tests for the program-logic tactics. Each `example` runs under a
heartbeat limit well below the default, and each timed out before the fix it
names. The goal `(1 + (1 + (1 + (1 + …` is the shape `runs_chain` leaves for the step
count of a 33-atom body with a word call inside it.
-/

-- The conditions are unused on purpose: their presence is what is tested.
set_option linter.unusedVariables false

namespace Firth.LogicTest
open Firth.Logic

/- `runs_arith` with an `if` condition in context. Before `runs_clear_bool`,
`omega` ran out of heartbeats at `whnf` whenever a Boolean equation was in
context, even an unrelated `b = true`. -/
set_option maxHeartbeats 20000 in
example (c : Nat) (b : Bool) (hCondition : b = true) :
    (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + c))))))))))))))))))))))))))))))))) = 33 + c := by
  runs_arith

set_option maxHeartbeats 20000 in
example (x y : Int) (c : Nat) (hCondition : decide (x < y) = false) :
    (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + c))))))))))))))))))))))))))))))))) = 33 + c := by
  runs_arith

/- `runs_side` on the same goal. Before it matched assumptions up to
reducible unfolding only, `assumption` ran out of heartbeats comparing the
condition with the sum, before `runs_arith` was tried. -/
set_option maxHeartbeats 20000 in
example (c : Nat) (b : Bool) (hCondition : b = true) :
    (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + (1 + c))))))))))))))))))))))))))))))))) = 33 + c := by
  runs_side

/- `runs_side` still closes an i64 range condition from an identical
assumption, and from bounds by linear arithmetic with a condition in
context. -/
example (x : Int) (h : InInt64 (x + 1)) : InInt64 (x + 1) := by
  runs_side

example (p : Int) (b : Bool) (hCondition : b = true) (h0 : 0 ≤ p)
    (h1 : p < 4611686018427387904) : InInt64 (p + 8) := by
  runs_side

/- Clearing is limited to Boolean equations: an integer fact stays and
`omega` uses it. -/
example (x : Int) (b : Bool) (hCondition : b = true) (h : x < 3) : x + 1 ≤ 3 := by
  runs_arith

/- `int64Gamma` refuses `div` where the VM traps: a zero divisor, and the one
quotient past i64, `-2^63 div -1`. The reference registry refuses only the
zero divisor; its `-2^63 div -1` is the unbounded 2^63. -/
section Division
open Firth.Interpreter Firth.ReferenceRun

private def divAt (left right : Int) : Config :=
  { stack := [.literal (.int right), .literal (.int left)], program := .cons (.prim "div") .empty }

example : step int64Gamma (fun _ => none) defaultCosts (divAt (-9223372036854775808) (-1)) =
    .stuck (divAt (-9223372036854775808) (-1)) := by rfl

example : step adapterGamma (fun _ => none) defaultCosts (divAt (-9223372036854775808) (-1)) =
    .stepped { stack := [.literal (.int 9223372036854775808)], program := .empty } 1 := by rfl

example : step int64Gamma (fun _ => none) defaultCosts (divAt 7 0) = .stuck (divAt 7 0) := by
  rfl

example : step int64Gamma (fun _ => none) defaultCosts (divAt (-7) 2) =
    .stepped { stack := [.literal (.int (-4))], program := .empty } 1 := by rfl

end Division

end Firth.LogicTest
