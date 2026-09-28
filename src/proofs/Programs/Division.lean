import Firth.ProgramLogic
import exports.Programs.Division

/-!
`divmod` and `gcd` from `examples/programs/division.firth`, proved from their
exported kernel programs under `int64Gamma`, where `div` faults on a zero
divisor and on the one quotient past i64 (`-2^63 div -1`), as the VM's does.

`gcd` is Euclid's algorithm, `gcd(a, b) = gcd(b, a mod b)` until `b` is 0, and
its proof is by strong induction on `|b|`: `mod` is Euclidean, so
`0 ≤ a mod b < |b|`. The step and cost bounds proved here are linear in `|b|`,
one iteration per unit of `|b|`. They are sound but loose: Euclid's algorithm
needs only logarithmically many iterations, which is not proved.

Neither argument of `gcd` may be the least i64 value, -2^63: `gcd` ends with
`abs`, and `abs` of -2^63 overflows. `gcd 0 -2^63` reaches it.
-/

namespace Firth.Proofs.Programs.Division
open Firth.Interpreter
open Firth.Logic
open Firth.ReferenceRun
open Firth.Exports.Programs.Division

/-- `divmod` leaves the Euclidean quotient and remainder, in 6 transitions at a
cost of 6. -/
theorem divmod (a b : Int) (tail : Stack) (hb : b ≠ 0) (hRange : InInt64 (a / b)) :
    Runs int64Gamma dictionary defaultCosts «divmod».body
      (.literal (.int b) :: .literal (.int a) :: tail)
      (.literal (.int (a % b)) :: .literal (.int (a / b)) :: tail) 6 6 := by
  runs_chain

theorem abs_of_neg (x : Int) (tail : Stack) (hx : x < 0) (hRange : InInt64 (0 - x)) :
    Runs int64Gamma dictionary defaultCosts (.cons (.word "abs") .empty)
      (.literal (.int x) :: tail) (.literal (.int (0 - x)) :: tail) 17 16 := by
  runs_unfold

theorem abs_of_nonneg (x : Int) (tail : Stack) (hx : ¬ x < 0) :
    Runs int64Gamma dictionary defaultCosts (.cons (.word "abs") .empty)
      (.literal (.int x) :: tail) (.literal (.int x) :: tail) 14 13 := by
  runs_unfold

/-- `abs` leaves `|x|` unless `x` is -2^63. -/
theorem abs_natAbs (x : Int) (tail : Stack) (hRange : InInt64 (0 - x)) :
    RunsWithin int64Gamma dictionary defaultCosts (.cons (.word "abs") .empty)
      (.literal (.int x) :: tail) (.literal (.int x.natAbs) :: tail) 17 16 := by
  by_cases hx : x < 0
  · have hAbs : (x.natAbs : Int) = 0 - x := by omega
    rw [hAbs]
    exact (abs_of_neg x tail hx hRange).within
  · have hAbs : (x.natAbs : Int) = x := by omega
    rw [hAbs]
    exact ((abs_of_nonneg x tail hx).within).weaken (by omega) (by omega)

/-- `gcd` with `b = 0` calls `abs` on `a`. -/
theorem gcd_zero {a result : Int} {tail : Stack} {steps cost : Nat}
    (hAbs : Runs int64Gamma dictionary defaultCosts (.cons (.word "abs") .empty)
      (.literal (.int a) :: tail) (.literal (.int result) :: tail) steps cost) :
    Runs int64Gamma dictionary defaultCosts (.cons (.word "gcd") .empty)
      (.literal (.int 0) :: .literal (.int a) :: tail) (.literal (.int result) :: tail)
      (17 + steps) (16 + cost) := by
  runs_unfold

/-- `gcd` with `b ≠ 0` continues with `b` and `a mod b`. -/
theorem gcd_step {a b : Int} {tail after : Stack} {steps cost : Nat} (hb : b ≠ 0)
    (hRec : Runs int64Gamma dictionary defaultCosts (.cons (.word "gcd") .empty)
      (.literal (.int (a % b)) :: .literal (.int b) :: tail) after steps cost) :
    Runs int64Gamma dictionary defaultCosts (.cons (.word "gcd") .empty)
      (.literal (.int b) :: .literal (.int a) :: tail) after (22 + steps) (20 + cost) := by
  runs_unfold

/-- Euclid's step: `gcd(a, b) = gcd(b, a mod b)`. -/
theorem gcd_emod (a b : Int) : Int.gcd b (a % b) = Int.gcd a b := by
  rw [Int.emod_def, Int.sub_eq_add_neg, ← Int.mul_neg, Int.gcd_add_mul_left_right,
    Int.gcd_comm]

/-- `gcd` leaves the greatest common divisor of `a` and `b`, within
`22·|b| + 34` transitions at a cost of at most `20·|b| + 32`, for any `a` and
`b` in i64 other than -2^63. -/
theorem gcd (a b : Int) (tail : Stack)
    (ha : InInt64 a) (ha' : InInt64 (0 - a)) (hb : InInt64 b) (hb' : InInt64 (0 - b)) :
    RunsWithin int64Gamma dictionary defaultCosts (.cons (.word "gcd") .empty)
      (.literal (.int b) :: .literal (.int a) :: tail)
      (.literal (.int (Int.gcd a b)) :: tail) (22 * b.natAbs + 34) (20 * b.natAbs + 32) := by
  induction h : b.natAbs using Nat.strongRecOn generalizing a b with
  | ind n ih =>
    by_cases hZero : b = 0
    · subst hZero
      rcases abs_natAbs a tail ha' with ⟨steps, cost, hAbs, hs, hc⟩
      rw [Int.gcd_zero_right]
      exact ⟨_, _, gcd_zero hAbs, by omega, by omega⟩
    · have hNonneg := Int.emod_nonneg a hZero
      have hLt := Int.emod_lt a hZero
      simp only [InInt64] at ha ha' hb hb'
      have hRec := ih (a % b).natAbs (by omega) b (a % b)
        (by simp only [InInt64]; omega) (by simp only [InInt64]; omega)
        (by simp only [InInt64]; omega) (by simp only [InInt64]; omega) rfl
      rw [gcd_emod] at hRec
      rcases hRec with ⟨steps, cost, hRuns, hs, hc⟩
      exact ⟨_, _, gcd_step hZero hRuns, by omega, by omega⟩

/-- `gcd`'s body with `b = 0` calls `abs` on `a`. -/
theorem gcd_body_zero {a result : Int} {tail : Stack} {steps cost : Nat}
    (hAbs : Runs int64Gamma dictionary defaultCosts (.cons (.word "abs") .empty)
      (.literal (.int a) :: tail) (.literal (.int result) :: tail) steps cost) :
    Runs int64Gamma dictionary defaultCosts «gcd».body
      (.literal (.int 0) :: .literal (.int a) :: tail) (.literal (.int result) :: tail)
      (16 + steps) (15 + cost) := by
  runs_chain

/-- `gcd`'s body with `b ≠ 0` calls `gcd` on `b` and `a mod b`. -/
theorem gcd_body_step {a b : Int} {tail after : Stack} {steps cost : Nat} (hb : b ≠ 0)
    (hRec : Runs int64Gamma dictionary defaultCosts (.cons (.word "gcd") .empty)
      (.literal (.int (a % b)) :: .literal (.int b) :: tail) after steps cost) :
    Runs int64Gamma dictionary defaultCosts «gcd».body
      (.literal (.int b) :: .literal (.int a) :: tail) after (21 + steps) (19 + cost) := by
  runs_chain

/-- `gcd`'s contract: for `a` and `b` in i64 other than -2^63, `gcd`'s body
leaves `gcd(a, b)` within `22·|b| + 33` transitions at a cost of at most
`20·|b| + 31`. -/
def gcdContract : WordContract where
  Args := Int × Int
  pre args := InInt64 args.1 ∧ InInt64 (0 - args.1) ∧ InInt64 args.2 ∧ InInt64 (0 - args.2)
  input args := [.literal (.int args.2), .literal (.int args.1)]
  output args := [.literal (.int (Int.gcd args.1 args.2))]
  steps args := 22 * args.2.natAbs + 33
  cost args := 20 * args.2.natAbs + 31
  witness := ⟨(0, 0), by simp only [InInt64]; omega⟩

/-- The recorded contract of `gcd`, under the i64 registry. -/
theorem gcd_contract : gcdContract.Holds int64Gamma dictionary defaultCosts «gcd».body := by
  intro ⟨a, b⟩ tail ⟨ha, ha', hb, hb'⟩
  show RunsWithin _ _ _ _ (.literal (.int b) :: .literal (.int a) :: tail)
    (.literal (.int (Int.gcd a b)) :: tail) (22 * b.natAbs + 33) (20 * b.natAbs + 31)
  by_cases hZero : b = 0
  · subst hZero
    rcases abs_natAbs a tail ha' with ⟨steps, cost, hAbs, hs, hc⟩
    rw [Int.gcd_zero_right]
    exact ⟨_, _, gcd_body_zero hAbs, by omega, by omega⟩
  · have hNonneg := Int.emod_nonneg a hZero
    have hLt := Int.emod_lt a hZero
    simp only [InInt64] at ha ha' hb hb'
    have hRec := gcd b (a % b) tail
      (by simp only [InInt64]; omega) (by simp only [InInt64]; omega)
      (by simp only [InInt64]; omega) (by simp only [InInt64]; omega)
    rw [gcd_emod] at hRec
    rcases hRec with ⟨steps, cost, hRuns, hs, hc⟩
    exact ⟨_, _, gcd_body_step hZero hRuns, by omega, by omega⟩

/-- `divmod`'s contract: for integers `a` and `b ≠ 0` whose quotient is in
i64, `divmod`'s body leaves the Euclidean quotient and remainder in 6
transitions at a cost of 6. -/
def divmodContract : WordContract where
  Args := Int × Int
  pre args := args.2 ≠ 0 ∧ InInt64 (args.1 / args.2)
  input args := [.literal (.int args.2), .literal (.int args.1)]
  output args := [.literal (.int (args.1 % args.2)), .literal (.int (args.1 / args.2))]
  steps _ := 6
  cost _ := 6
  witness := ⟨(0, 1), by simp only [InInt64]; omega⟩

/-- The recorded contract of `divmod`, under the i64 registry. -/
theorem divmod_contract :
    divmodContract.Holds int64Gamma dictionary defaultCosts «divmod».body := by
  intro ⟨a, b⟩ tail ⟨hb, hRange⟩
  exact (divmod a b tail hb hRange).within

end Firth.Proofs.Programs.Division
