import Firth.ProgramLogic

/-!
The allocation rule of `specs/inventory-allocation.md` ("Calculation"), stated
in Lean independently of any Firth program, with its required properties
proved.

`allocateAll` is the rule as the spec text gives it, in the component's
encoding: the policy as `wholeOnly` (true for all-or-nothing, as
`allocate-batch` takes it) and reasons as codes 0 fulfilled, 1 partial,
2 out-of-stock, 3 insufficient-stock. The theorems below prove the spec's
"Required properties" of that rule for every valid input: lengths and order,
no request over its quantity, non-negative stock, conservation, the policy
rule, the reason table, and priority (each request is decided on the stock
left after every earlier request).

`Allocate.lean` proves that `allocate-batch`'s kernel program computes
`allocateAll` on every valid input, which carries all of these to the program.
This file does not depend on the program.
-/

namespace Firth.Proofs.Inventory.Spec

/-- One request, decided on the stock `remaining` still has: the stock left
after it, the amount allocated and the reason code. -/
def allocateOne (wholeOnly : Bool) (remaining requested : Int) : Int × Int × Int :=
  let take := if wholeOnly then (if requested ≤ remaining then requested else 0)
    else min remaining requested
  let reason := if take = requested then 0 else if 0 < take then 1
    else if remaining = 0 then 2 else 3
  (remaining - take, take, reason)

/-- Every request in order, subtracting each allocation before the next: the
final stock, the allocations and the reasons. -/
def allocateAll (wholeOnly : Bool) : Int → List Int → Int × List Int × List Int
  | remaining, [] => (remaining, [], [])
  | remaining, requested :: rest =>
    let one := allocateOne wholeOnly remaining requested
    let later := allocateAll wholeOnly one.1 rest
    (later.1, one.2.1 :: later.2.1, one.2.2 :: later.2.2)

/-- The value and count bounds of the spec's "Boundary". -/
def InRange (available : Int) (quantities : List Int) : Prop :=
  0 ≤ available ∧ available ≤ 1000000 ∧ quantities.length ≤ 64 ∧
    ∀ q ∈ quantities, 1 ≤ q ∧ q ≤ 1000000

/-! ## One request -/

section One
variable {wholeOnly : Bool} {remaining requested : Int}

theorem one_left (h : 0 ≤ remaining) (hq : 1 ≤ requested) :
    let one := allocateOne wholeOnly remaining requested
    one.1 = remaining - one.2.1 ∧ 0 ≤ one.2.1 ∧ one.2.1 ≤ requested ∧ one.2.1 ≤ remaining := by
  simp only [allocateOne, Int.min_def]; cases wholeOnly <;> simp only [Bool.false_eq_true,
    ↓reduceIte] <;> repeat' split
  all_goals (try simp only [true_and]) <;> omega

theorem one_whole :
    (allocateOne true remaining requested).2.1 = if requested ≤ remaining then requested else 0 := by
  simp [allocateOne]

theorem one_partial :
    (allocateOne false remaining requested).2.1 = min remaining requested := by
  simp [allocateOne]

/-- The reason table: fulfilled when the whole quantity is allocated, partial when
a positive part is, out-of-stock when nothing remained, and otherwise
insufficient-stock. -/
theorem one_reason (h : 0 ≤ remaining) (hq : 1 ≤ requested) :
    let one := allocateOne wholeOnly remaining requested
    (one.2.2 = 0 ↔ one.2.1 = requested) ∧
    (one.2.2 = 1 ↔ 0 < one.2.1 ∧ one.2.1 < requested) ∧
    (one.2.2 = 2 ↔ one.2.1 = 0 ∧ remaining = 0) ∧
    (one.2.2 = 3 ↔ one.2.1 = 0 ∧ 0 < remaining) := by
  simp only [allocateOne, Int.min_def]; cases wholeOnly <;> simp only [Bool.false_eq_true,
    ↓reduceIte] <;> repeat' split
  all_goals (refine ⟨⟨fun _ => ?_, fun _ => ?_⟩, ⟨fun _ => ?_, fun _ => ?_⟩, ⟨fun _ => ?_, fun _ => ?_⟩,
    ⟨fun _ => ?_, fun _ => ?_⟩⟩ <;> omega)

theorem one_no_insufficient_under_partial (h : 0 ≤ remaining) (hq : 1 ≤ requested) :
    (allocateOne false remaining requested).2.2 ≠ 3 := by
  simp only [allocateOne, Int.min_def, Bool.false_eq_true, ↓reduceIte]; repeat' split
  all_goals (try simp only [true_and, and_true]) <;> omega

end One

/-! ## The whole batch -/

section Batch
variable {wholeOnly : Bool}

/-- Every quantity is at least 1, as the bounds require. -/
def Positive (quantities : List Int) : Prop := ∀ q ∈ quantities, 1 ≤ q

theorem allocateAll_length (remaining : Int) (quantities : List Int) :
    (allocateAll wholeOnly remaining quantities).2.1.length = quantities.length ∧
    (allocateAll wholeOnly remaining quantities).2.2.length = quantities.length := by
  induction quantities generalizing remaining with
  | nil => simp [allocateAll]
  | cons q rest ih => simp [allocateAll, ih]

/-- Stock is conserved and never negative: the final stock plus everything
allocated is the initial stock. -/
theorem allocateAll_conserves {remaining : Int} {quantities : List Int}
    (h : 0 ≤ remaining) (hq : Positive quantities) :
    let result := allocateAll wholeOnly remaining quantities
    0 ≤ result.1 ∧ result.1 + result.2.1.sum = remaining := by
  induction quantities generalizing remaining with
  | nil => simp [allocateAll, h]
  | cons q rest ih =>
    have hq1 : 1 ≤ q := hq q (by simp)
    have one := one_left (wholeOnly := wholeOnly) h hq1
    have later := ih (remaining := (allocateOne wholeOnly remaining q).1) (by omega)
      (fun x hx => hq x (by simp [hx]))
    simp only [allocateAll, List.sum_cons]
    omega

/-- Priority: request `i` is decided exactly as `allocateOne` decides it on the
stock left after requests `0 .. i-1`, whatever comes later. -/
theorem allocateAll_decides (remaining : Int) (quantities : List Int) (i : Nat)
    (hi : i < quantities.length) :
    let result := allocateAll wholeOnly remaining quantities
    let before := remaining - (result.2.1.take i).sum
    let one := allocateOne wholeOnly before quantities[i]
    result.2.1[i]? = some one.2.1 ∧ result.2.2[i]? = some one.2.2 := by
  induction quantities generalizing remaining i with
  | nil => simp at hi
  | cons q rest ih =>
    cases i with
    | zero => simp [allocateAll]
    | succ i =>
      have := ih (allocateOne wholeOnly remaining q).1 i (by simpa using hi)
      have hLeft : (allocateOne wholeOnly remaining q).1 =
          remaining - (allocateOne wholeOnly remaining q).2.1 := by
        simp only [allocateOne]
      simp only [allocateAll, List.take_succ_cons, List.sum_cons, List.getElem?_cons_succ,
        List.getElem_cons_succ] at this ⊢
      rw [hLeft] at this
      rwa [show remaining - ((allocateOne wholeOnly remaining q).2.1 +
          ((allocateAll wholeOnly (allocateOne wholeOnly remaining q).1 rest).2.1.take i).sum) =
          remaining - (allocateOne wholeOnly remaining q).2.1 -
          ((allocateAll wholeOnly (allocateOne wholeOnly remaining q).1 rest).2.1.take i).sum
          by omega, ← hLeft]

/-- The stock left before request `i` is never negative. -/
theorem allocateAll_before_nonneg {remaining : Int} {quantities : List Int}
    (h : 0 ≤ remaining) (hq : Positive quantities) (i : Nat) :
    0 ≤ remaining - ((allocateAll wholeOnly remaining quantities).2.1.take i).sum := by
  induction quantities generalizing remaining i with
  | nil => simp [allocateAll, h]
  | cons q rest ih =>
    have hq1 : 1 ≤ q := hq q (by simp)
    have one := one_left (wholeOnly := wholeOnly) h hq1
    cases i with
    | zero => simpa using h
    | succ i =>
      have later := ih (remaining := (allocateOne wholeOnly remaining q).1) (by omega)
        (fun x hx => hq x (by simp [hx])) i
      simp only [allocateAll, List.take_succ_cons, List.sum_cons]
      omega

/-- The spec's required properties of each allocation, for every valid batch:
no request gets more than it asked for or a negative amount, the policy rule
holds, and the reason follows the table. -/
theorem allocateAll_each {remaining : Int} {quantities : List Int}
    (h : 0 ≤ remaining) (hq : Positive quantities) (i : Nat) (hi : i < quantities.length) :
    let result := allocateAll wholeOnly remaining quantities
    let before := remaining - (result.2.1.take i).sum
    ∃ take reason, result.2.1[i]? = some take ∧ result.2.2[i]? = some reason ∧
      0 ≤ take ∧ take ≤ quantities[i] ∧ take ≤ before ∧
      (wholeOnly = true → take = if quantities[i] ≤ before then quantities[i] else 0) ∧
      (wholeOnly = false → take = min before quantities[i] ∧ reason ≠ 3) ∧
      (reason = 0 ↔ take = quantities[i]) ∧
      (reason = 1 ↔ 0 < take ∧ take < quantities[i]) ∧
      (reason = 2 ↔ take = 0 ∧ before = 0) ∧
      (reason = 3 ↔ take = 0 ∧ 0 < before) := by
  intro result before
  have hBefore : 0 ≤ before := allocateAll_before_nonneg h hq i
  have hQ : 1 ≤ quantities[i] := hq _ (List.getElem_mem hi)
  obtain ⟨hTake, hReason⟩ := allocateAll_decides (wholeOnly := wholeOnly) remaining quantities i hi
  have bounds := one_left (wholeOnly := wholeOnly) hBefore hQ
  have table := one_reason (wholeOnly := wholeOnly) hBefore hQ
  refine ⟨_, _, hTake, hReason, bounds.2.1, bounds.2.2.1, bounds.2.2.2, ?_, ?_, table⟩
  · intro hw; subst hw; exact one_whole
  · intro hw; subst hw
    exact ⟨one_partial, one_no_insufficient_under_partial hBefore hQ⟩

/-- Rejecting an oversized all-or-nothing request does not stop a later
smaller one: any request that fits the stock left before it is filled. -/
theorem allocateAll_later_fits {remaining : Int} {quantities : List Int}
    (h : 0 ≤ remaining) (hq : Positive quantities) (i : Nat) (hi : i < quantities.length)
    (hFits : quantities[i] ≤ remaining - ((allocateAll wholeOnly remaining quantities).2.1.take i).sum) :
    (allocateAll wholeOnly remaining quantities).2.1[i]? = some quantities[i] := by
  obtain ⟨take, reason, hTake, -, -, -, -, hWhole, hPartial, -⟩ :=
    allocateAll_each (wholeOnly := wholeOnly) h hq i hi
  rw [hTake]
  cases wholeOnly with
  | true => simp [hWhole rfl, hFits]
  | false => have := (hPartial rfl).1; congr 1; omega

end Batch

end Firth.Proofs.Inventory.Spec
