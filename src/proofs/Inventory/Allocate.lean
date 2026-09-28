import proofs.Inventory.DupScan
import proofs.Inventory.Spec

/-!
The inventory allocator's entry word, `allocate-batch` in
`examples/inventory/allocator.firth`, proved from its exported kernel program
to compute the spec's rule (`Spec.lean`) within a stated cost.

`allocate_batch` covers every input the host can hand the word: any stock, any
policy, any quantities and IDs in the host's encoding (four parts per request,
each in `[0, 65^8)`). It returns code 1 when the input is outside the spec's
bounds, code 2 when two IDs are equal, and otherwise code 0 with exactly
`Spec.allocateAll`'s final stock, allocations and reasons, so the properties
proved of `allocateAll` in `Spec.lean` hold of the program's output. The body,
run as the reference runner runs an entry word, takes at most
`181 + 224n + 172·n(n−1)/2` transitions and costs at most
`165 + 202n + 163·n(n−1)/2` for `n` requests (`batchCost`, equal to
`run_cases.cost_bound` by `batchCost_eq`). The constant is attained on an empty
batch (`CostCheck.lean`); for larger batches the bound is not attained.

The words it calls are proved first: `allocate-one` (one request),
`allocate-from` (the loop over requests), `quantities-in-range-from` and
`in-range` (the bounds), and `has-repeat` in `DupScan.lean`.

Every fact is proved under `int64Gamma`, where arithmetic faults outside i64 as
the VM's does, so no value overflows on such input; `allocate_batch_reference`
states the result under the reference registry. The stated gaps remain: VM
agreement with the reference interpreter rests on differential testing, the
Python host (JSON and the ID encoding, whose injectivity the repeated-ID result
relies on) is tested, not proved. `allocate_batch_contract` is the recorded
form: `src/proofs/records.json` binds it to the digests of `allocate-batch` and
every word it calls, the registry and the cost table, and reports those words
`contract_verified`.
-/

namespace Firth.Proofs.Inventory.Allocate
open Firth.Interpreter
open Firth.Logic
open Firth.ReferenceRun
open Firth.Exports.Inventory.Allocator
open Firth.Proofs.Inventory.DupScan (R RW HasRepeat IdParts tri has_repeat)

section One
variable {remaining requested : Int} {whole : Bool} {tail : Stack}

abbrev oneIn (remaining requested : Int) (whole : Bool) (tail : Stack) : Stack :=
  .literal (.bool whole) :: .literal (.int requested) :: .literal (.int remaining) :: tail

abbrev oneOut (left allocated reason : Int) (tail : Stack) : Stack :=
  .literal (.int reason) :: .literal (.int allocated) :: .literal (.int left) :: tail

theorem one_empty (hCond : decide (remaining = 0) = true) :
    R (.cons (.word "allocate-one") .empty) (oneIn remaining requested whole tail)
      (oneOut 0 0 2 tail) 19 19 := by
  word_chain

theorem one_fits (hCond : decide (remaining = 0) = false)
    (hCond2 : decide (requested < remaining + 1) = true)
    (hr : 0 ≤ remaining ∧ remaining ≤ 1000000) (hq : 1 ≤ requested ∧ requested ≤ 1000000) :
    R (.cons (.word "allocate-one") .empty) (oneIn remaining requested whole tail)
      (oneOut (remaining - requested) requested 0 tail) 46 41 := by
  word_chain

theorem one_whole (hCond : decide (remaining = 0) = false)
    (hCond2 : decide (requested < remaining + 1) = false) (hCond3 : whole = true)
    (hr : 0 ≤ remaining ∧ remaining ≤ 1000000) :
    R (.cons (.word "allocate-one") .empty) (oneIn remaining requested whole tail)
      (oneOut remaining 0 3 tail) 54 48 := by
  word_chain

theorem one_partial (hCond : decide (remaining = 0) = false)
    (hCond2 : decide (requested < remaining + 1) = false) (hCond3 : whole = false)
    (hr : 0 ≤ remaining ∧ remaining ≤ 1000000) :
    R (.cons (.word "allocate-one") .empty) (oneIn remaining requested whole tail)
      (oneOut 0 remaining 1 tail) 55 49 := by
  word_chain

open Firth.Proofs.Inventory.Spec in
/-- `allocate-one` computes `allocateOne`: the stock left, the amount allocated
and the reason, within 55 transitions at a cost of 49. -/
theorem allocate_one (hr : 0 ≤ remaining ∧ remaining ≤ 1000000)
    (hq : 1 ≤ requested ∧ requested ≤ 1000000) :
    RW (.cons (.word "allocate-one") .empty) (oneIn remaining requested whole tail)
      (oneOut (allocateOne whole remaining requested).1 (allocateOne whole remaining requested).2.1
        (allocateOne whole remaining requested).2.2 tail) 55 49 := by
  by_cases h0 : remaining = 0
  · refine ((one_empty (requested := requested) (whole := whole) (tail := tail)
      (decide_eq_true h0)).within.weaken (by omega) (by omega)).congr_stacks rfl ?_
    subst h0
    cases whole <;> simp [allocateOne, Int.min_def] <;> omega
  · by_cases h1 : requested < remaining + 1
    · refine ((one_fits (whole := whole) (tail := tail) (decide_eq_false h0) (decide_eq_true h1)
        hr hq).within.weaken (by omega) (by omega)).congr_stacks rfl ?_
      have h1' : requested ≤ remaining := by omega
      cases whole <;> simp [allocateOne, Int.min_def, h1'] <;> omega
    · cases whole with
      | true =>
        refine ((one_whole (tail := tail) (decide_eq_false h0) (decide_eq_false h1) rfl
          hr).within.weaken (by omega) (by omega)).congr_stacks rfl ?_
        have h1' : ¬ requested ≤ remaining := by omega
        simp [allocateOne, h1']; omega
      | false =>
        refine ((one_partial (tail := tail) (decide_eq_false h0) (decide_eq_false h1) rfl
          hr).within.weaken (by omega) (by omega)).congr_stacks rfl ?_
        simp [allocateOne, Int.min_def]; omega

end One

section From
variable {qs taken reasons : List Int} {whole : Bool} {remaining i : Int} {tail : Stack}

abbrev fromIn (qs : List Int) (whole : Bool) (remaining i : Int) (taken reasons : List Int)
    (tail : Stack) : Stack :=
  .literal (.intSeq reasons) :: .literal (.intSeq taken) :: .literal (.int i) ::
    .literal (.int remaining) :: .literal (.bool whole) :: .literal (.intSeq qs) :: tail

abbrev fromOut (left : Int) (allocated codes : List Int) (tail : Stack) : Stack :=
  .literal (.intSeq codes) :: .literal (.intSeq allocated) :: .literal (.int left) :: tail

/-- What `allocate-from` keeps on the stack under a call to `allocate-one`. -/
abbrev saved (qs : List Int) (whole : Bool) (i : Int) (taken reasons : List Int) (tail : Stack) :
    Stack :=
  .literal (.intSeq reasons) :: .literal (.intSeq taken) :: .literal (.bool whole) ::
    .literal (.int i) :: .literal (.intSeq qs) :: tail

theorem from_done (hCond : decide (i < qs.length) = false) :
    R (.cons (.word "allocate-from") .empty) (fromIn qs whole remaining i taken reasons tail)
      (fromOut remaining taken reasons tail) 41 38 := by
  word_chain

theorem from_step {q left amount reason : Int} {s₁ c₁ s₂ c₂ : Nat} {left' : Int}
    {allocated codes : List Int}
    (hCond : decide (i < qs.length) = true) (hi : 0 ≤ i) (hiBig : i < 1000)
    (hq : qs[i.toNat]? = some q)
    (hOne : R (.cons (.word "allocate-one") .empty) (oneIn remaining q whole (saved qs whole i taken reasons tail))
      (oneOut left amount reason (saved qs whole i taken reasons tail)) s₁ c₁)
    (hRec : R (.cons (.word "allocate-from") .empty)
      (fromIn qs whole left (i + 1) (taken ++ [amount]) (reasons ++ [reason])
        (saved qs whole i taken reasons tail))
      (fromOut left' allocated codes (saved qs whole i taken reasons tail)) s₂ c₂) :
    R (.cons (.word "allocate-from") .empty) (fromIn qs whole remaining i taken reasons tail)
      (fromOut left' allocated codes tail) (68 + s₁ + s₂) (62 + c₁ + c₂) := by
  have hAt : R (.cons (.prim "seq-int.at") .empty)
      (.literal (.int i) :: .literal (.intSeq qs) :: .literal (.int remaining) ::
        saved qs whole i taken reasons tail)
      (.literal (.int q) :: .literal (.int remaining) :: saved qs whole i taken reasons tail) 1 1 :=
    runs_intSeq_at_int _ hi hq
  apply Runs.congr
  focus
    apply runs_word (by rfl)
    dsimp only
    runs_expand
  repeat' runs_atom
  all_goals try (simp only [InInt64]; omega)
  all_goals try runs_arith

open Firth.Proofs.Inventory.Spec in
/-- `allocate-from` from request `i` on: `allocateAll` over the rest of the
quantities, appended to what was already allocated, within 123 transitions and
a cost of 111 per request left, plus 41 and 38 to stop. -/
theorem allocate_from (qs : List Int) (whole : Bool) (hLen : qs.length ≤ 64)
    (hQs : ∀ q ∈ qs, 1 ≤ q ∧ q ≤ 1000000) (n : Nat) :
    ∀ (i : Nat) (remaining : Int) (taken reasons : List Int) (tail : Stack),
      qs.length - i = n → i ≤ qs.length → 0 ≤ remaining ∧ remaining ≤ 1000000 →
      RW (.cons (.word "allocate-from") .empty)
        (fromIn qs whole remaining i taken reasons tail)
        (fromOut (allocateAll whole remaining (qs.drop i)).1
          (taken ++ (allocateAll whole remaining (qs.drop i)).2.1)
          (reasons ++ (allocateAll whole remaining (qs.drop i)).2.2) tail)
        (41 + 123 * n) (38 + 111 * n) := by
  induction n with
  | zero =>
    intro i remaining taken reasons tail hn hi hr
    have hDrop : qs.drop i = [] := List.drop_eq_nil_of_le (by omega)
    rw [hDrop]
    have hDone := from_done (qs := qs) (whole := whole) (remaining := remaining) (i := (i : Int))
      (taken := taken) (reasons := reasons) (tail := tail) (decide_eq_false (by omega))
    simp only [allocateAll, List.append_nil]
    exact hDone.within.weaken (by omega) (by omega)
  | succ n ih =>
    intro i remaining taken reasons tail hn hi hr
    have hiL : i < qs.length := by omega
    have hGet := DupScan.getElem?_getD (ids := qs) hiL
    have hQ := hQs _ (List.mem_of_getElem? hGet)
    have hDrop : qs.drop i = qs.getD i 0 :: qs.drop (i + 1) := by
      rw [List.drop_eq_getElem_cons hiL]; simp [List.getD, List.getElem?_eq_getElem hiL]
    obtain ⟨s₁, c₁, hOne, hs₁, hc₁⟩ := allocate_one (whole := whole)
      (tail := saved qs whole i taken reasons tail) hr hQ
    have hLeft := one_left (wholeOnly := whole) hr.1 hQ.1
    obtain ⟨s₂, c₂, hRec, hs₂, hc₂⟩ := ih (i + 1) (allocateOne whole remaining (qs.getD i 0)).1
      (taken ++ [(allocateOne whole remaining (qs.getD i 0)).2.1])
      (reasons ++ [(allocateOne whole remaining (qs.getD i 0)).2.2])
      (saved qs whole i taken reasons tail) (by omega) (by omega) (by omega)
    have hAt : qs[((i : Int)).toNat]? = some (qs.getD i 0) := by
      rwa [show ((i : Int)).toNat = i by omega]
    have hRun := from_step (decide_eq_true (by omega)) (by omega) (by omega) hAt hOne
      (hRec.congr_stacks (by simp) rfl)
    refine ⟨_, _, hRun.congr_stacks rfl ?_, by omega, by omega⟩
    rw [hDrop]
    simp [allocateAll]

end From

/-! ## The bounds -/

set_option hygiene false in
/-- `word_chain` that also takes `seq-int.at` at an index the context
locates. -/
macro "at_chain" : tactic => `(tactic| (
  apply Runs.congr
  focus
    apply runs_word (by rfl)
    dsimp only
    runs_expand
  repeat' (first | runs_atom | apply runs_cons (runs_intSeq_at_int _ hi hAt))
  all_goals try (simp only [InInt64]; omega)
  all_goals try runs_arith))

section Range
variable {qs : List Int} {i q : Int} {tail : Stack}

theorem qr_done (hCond : decide (i < qs.length) = false) :
    R (.cons (.word "quantities-in-range-from") .empty)
      (.literal (.int i) :: .literal (.intSeq qs) :: tail) (.literal (.bool true) :: tail) 15 15 := by
  word_chain

theorem qr_low (hCond : decide (i < qs.length) = true) (hi : 0 ≤ i) (hAt : qs[i.toNat]? = some q)
    (hCond2 : decide (0 < q) = false) :
    R (.cons (.word "quantities-in-range-from") .empty)
      (.literal (.int i) :: .literal (.intSeq qs) :: tail) (.literal (.bool false) :: tail) 31 29 := by
  at_chain

theorem qr_high (hCond : decide (i < qs.length) = true) (hi : 0 ≤ i) (hAt : qs[i.toNat]? = some q)
    (hCond2 : decide (0 < q) = true) (hCond3 : decide (q < 1000001) = false) :
    R (.cons (.word "quantities-in-range-from") .empty)
      (.literal (.int i) :: .literal (.intSeq qs) :: tail) (.literal (.bool false) :: tail) 47 43 := by
  at_chain

theorem qr_next {ok : Bool} {s₁ c₁ : Nat} (hCond : decide (i < qs.length) = true) (hi : 0 ≤ i)
    (hiBig : i < 1000) (hAt : qs[i.toNat]? = some q)
    (hCond2 : decide (0 < q) = true) (hCond3 : decide (q < 1000001) = true)
    (hRec : R (.cons (.word "quantities-in-range-from") .empty)
      (.literal (.int (i + 1)) :: .literal (.intSeq qs) :: tail) (.literal (.bool ok) :: tail) s₁ c₁) :
    R (.cons (.word "quantities-in-range-from") .empty)
      (.literal (.int i) :: .literal (.intSeq qs) :: tail) (.literal (.bool ok) :: tail)
      (52 + s₁) (46 + c₁) := by
  at_chain

/-- Every quantity from index `i` on is from 1 to 1,000,000. -/
def QuantitiesFrom (qs : List Int) (i : Nat) : Prop :=
  ∀ j, i ≤ j → j < qs.length → 1 ≤ qs.getD j 0 ∧ qs.getD j 0 ≤ 1000000

theorem quantities_in_range_from (qs : List Int) (hLen : qs.length ≤ 64) (m : Nat) :
    ∀ (i : Nat) (tail : Stack), qs.length - i = m →
      ∃ ok, RW (.cons (.word "quantities-in-range-from") .empty)
        (.literal (.int i) :: .literal (.intSeq qs) :: tail) (.literal (.bool ok) :: tail)
        (15 + 52 * m) (15 + 46 * m) ∧ (ok = true ↔ QuantitiesFrom qs i) := by
  induction m with
  | zero =>
    intro i tail hm
    refine ⟨true, (qr_done (qs := qs) (i := i) (tail := tail)
      (decide_eq_false (by omega))).within.weaken (by omega) (by omega), ?_⟩
    simp only [true_iff]
    intro j hij hj; omega
  | succ m ih =>
    intro i tail hm
    have hiL : i < qs.length := by omega
    have hGet := DupScan.getElem?_getD (ids := qs) hiL
    have hAt : qs[((i : Int)).toNat]? = some (qs.getD i 0) := by
      rwa [show ((i : Int)).toNat = i by omega]
    have hC : decide ((i : Int) < qs.length) = true := decide_eq_true (by omega)
    by_cases h0 : 0 < qs.getD i 0
    · by_cases h1 : qs.getD i 0 < 1000001
      · obtain ⟨ok, ⟨s₁, c₁, hRec, hs, hc⟩, hIff⟩ := ih (i + 1) tail (by omega)
        refine ⟨ok, ⟨_, _, qr_next hC (by omega) (by omega) hAt (decide_eq_true h0)
          (decide_eq_true h1) (hRec.congr_stacks (by simp) rfl), by omega, by omega⟩, ?_⟩
        rw [hIff]
        constructor
        · intro h j hij hj
          by_cases hji : j = i
          · subst hji; omega
          · exact h j (by omega) hj
        · intro h j hij hj; exact h j (by omega) hj
      · refine ⟨false, (qr_high hC (by omega) hAt (decide_eq_true h0)
          (decide_eq_false h1)).within.weaken (by omega) (by omega), ?_⟩
        simp only [Bool.false_eq_true, false_iff]
        intro h; have := h i (by omega) hiL; omega
    · refine ⟨false, (qr_low hC (by omega) hAt (decide_eq_false h0)).within.weaken
        (by omega) (by omega), ?_⟩
      simp only [Bool.false_eq_true, false_iff]
      intro h; have := h i (by omega) hiL; omega

section InRange
variable {qs : List Int} {available : Int} {tail : Stack}

abbrev rangeIn (available : Int) (qs : List Int) (tail : Stack) : Stack :=
  .literal (.intSeq qs) :: .literal (.int available) :: tail

theorem ir_negative (hCond : decide (-1 < available) = false) :
    R (.cons (.word "in-range") .empty) (rangeIn available qs tail)
      (.literal (.bool false) :: tail) 14 14 := by
  word_chain

theorem ir_large (hCond : decide (-1 < available) = true)
    (hCond2 : decide (available < 1000001) = false) :
    R (.cons (.word "in-range") .empty) (rangeIn available qs tail)
      (.literal (.bool false) :: tail) 25 23 := by
  word_chain

theorem ir_long (hCond : decide (-1 < available) = true)
    (hCond2 : decide (available < 1000001) = true) (hCond3 : decide ((qs.length : Int) < 65) = false) :
    R (.cons (.word "in-range") .empty) (rangeIn available qs tail)
      (.literal (.bool false) :: tail) 36 33 := by
  word_chain

theorem ir_scan {ok : Bool} {s₁ c₁ : Nat} (hCond : decide (-1 < available) = true)
    (hCond2 : decide (available < 1000001) = true) (hCond3 : decide ((qs.length : Int) < 65) = true)
    (hScan : R (.cons (.word "quantities-in-range-from") .empty)
      (.literal (.int 0) :: .literal (.intSeq qs) :: tail) (.literal (.bool ok) :: tail) s₁ c₁) :
    R (.cons (.word "in-range") .empty) (rangeIn available qs tail)
      (.literal (.bool ok) :: tail) (37 + s₁) (33 + c₁) := by
  word_chain

theorem quantitiesFrom_zero (qs : List Int) :
    QuantitiesFrom qs 0 ↔ ∀ q ∈ qs, 1 ≤ q ∧ q ≤ 1000000 := by
  constructor
  · intro h q hq
    obtain ⟨j, hj, rfl⟩ := List.mem_iff_getElem.mp hq
    have := h j (Nat.zero_le _) hj
    rwa [List.getD_eq_getElem?_getD, List.getElem?_eq_getElem hj, Option.getD_some] at this
  · intro h j _ hj
    rw [List.getD_eq_getElem?_getD, List.getElem?_eq_getElem hj, Option.getD_some]
    exact h _ (List.getElem_mem hj)

/-- `in-range` decides the spec's bounds (`Spec.InRange`). The scan over the
quantities runs only when the count is at most 64, so the bound is in the count. -/
theorem in_range (available : Int) (qs : List Int) (tail : Stack) :
    ∃ ok, RW (.cons (.word "in-range") .empty) (rangeIn available qs tail)
      (.literal (.bool ok) :: tail) (52 + 52 * qs.length) (48 + 46 * qs.length) ∧
      (ok = true ↔ Spec.InRange available qs) := by
  by_cases h0 : -1 < available
  · by_cases h1 : available < 1000001
    · by_cases h2 : (qs.length : Int) < 65
      · obtain ⟨ok, ⟨s₁, c₁, hRun, hs, hc⟩, hIff⟩ :=
          quantities_in_range_from qs (by omega) qs.length 0 tail (by simp)
        refine ⟨ok, ⟨_, _, ir_scan (decide_eq_true h0) (decide_eq_true h1) (decide_eq_true h2)
          (hRun.congr_stacks (by simp) rfl), by omega, by omega⟩, ?_⟩
        rw [hIff, quantitiesFrom_zero]
        simp only [Spec.InRange]
        constructor
        · intro h; exact ⟨by omega, by omega, by omega, h⟩
        · intro h; exact h.2.2.2
      · refine ⟨false, (ir_long (qs := qs) (tail := tail) (decide_eq_true h0) (decide_eq_true h1)
          (decide_eq_false h2)).within.weaken (by omega) (by omega), ?_⟩
        simp only [Bool.false_eq_true, false_iff, Spec.InRange]; omega
    · refine ⟨false, (ir_large (qs := qs) (tail := tail) (decide_eq_true h0)
        (decide_eq_false h1)).within.weaken (by omega) (by omega), ?_⟩
      simp only [Bool.false_eq_true, false_iff, Spec.InRange]; omega
  · refine ⟨false, (ir_negative (qs := qs) (tail := tail) (decide_eq_false h0)).within.weaken
      (by omega) (by omega), ?_⟩
    simp only [Bool.false_eq_true, false_iff, Spec.InRange]; omega

end InRange

end Range

/-! ## `allocate-batch` -/

section Batch
variable {available : Int} {whole : Bool} {ids qs : List Int} {tail : Stack}

abbrev batchIn (available : Int) (whole : Bool) (ids qs : List Int) (tail : Stack) : Stack :=
  .literal (.intSeq qs) :: .literal (.intSeq ids) :: .literal (.bool whole) ::
    .literal (.int available) :: tail

abbrev batchOut (code left : Int) (allocated reasons : List Int) (tail : Stack) : Stack :=
  .literal (.intSeq reasons) :: .literal (.intSeq allocated) :: .literal (.int left) ::
    .literal (.int code) :: tail

/-- What `allocate-batch` keeps under the call to `has-repeat`. -/
abbrev kept (available : Int) (whole : Bool) (qs : List Int) (tail : Stack) : Stack :=
  .literal (.int available) :: .literal (.bool whole) :: .literal (.intSeq qs) :: tail

set_option hygiene false in
/-- `word_chain` for a word's body run directly, as the reference runner runs an
entry word: no unfold is charged. -/
macro "body_chain" : tactic => `(tactic| (
  apply Runs.congr
  focus
    runs_expand
  repeat' runs_atom
  all_goals try (simp only [InInt64]; omega)
  all_goals try runs_arith))

theorem batch_out_of_range {s₁ c₁ : Nat}
    (hRange : R (.cons (.word "in-range") .empty)
      (rangeIn available qs (batchIn available whole ids qs tail))
      (.literal (.bool false) :: batchIn available whole ids qs tail) s₁ c₁) :
    R «allocate-batch».body (batchIn available whole ids qs tail)
      (batchOut 1 0 [] [] tail) (21 + s₁) (21 + c₁) := by
  body_chain

theorem batch_repeat {s₁ c₁ s₂ c₂ : Nat}
    (hRange : R (.cons (.word "in-range") .empty)
      (rangeIn available qs (batchIn available whole ids qs tail))
      (.literal (.bool true) :: batchIn available whole ids qs tail) s₁ c₁)
    (hRepeat : R (.cons (.word "has-repeat") .empty)
      (.literal (.intSeq ids) :: kept available whole qs tail)
      (.literal (.bool true) :: kept available whole qs tail) s₂ c₂) :
    R «allocate-batch».body (batchIn available whole ids qs tail)
      (batchOut 2 0 [] [] tail) (38 + s₁ + s₂) (34 + c₁ + c₂) := by
  body_chain

theorem batch_allocate {s₁ c₁ s₂ c₂ s₃ c₃ : Nat} {left : Int} {allocated reasons : List Int}
    (hRange : R (.cons (.word "in-range") .empty)
      (rangeIn available qs (batchIn available whole ids qs tail))
      (.literal (.bool true) :: batchIn available whole ids qs tail) s₁ c₁)
    (hRepeat : R (.cons (.word "has-repeat") .empty)
      (.literal (.intSeq ids) :: kept available whole qs tail)
      (.literal (.bool false) :: kept available whole qs tail) s₂ c₂)
    (hFrom : R (.cons (.word "allocate-from") .empty)
      (fromIn qs whole available 0 [] [] (.literal (.int 0) :: tail))
      (fromOut left allocated reasons (.literal (.int 0) :: tail)) s₃ c₃) :
    R «allocate-batch».body (batchIn available whole ids qs tail)
      (batchOut 0 left allocated reasons tail) (44 + s₁ + s₂ + s₃) (37 + c₁ + c₂ + c₃) := by
  body_chain

/-- What `allocate-batch` must return, from the spec alone: code 1 and nothing
allocated when the input is out of bounds, code 2 when an ID repeats, and
otherwise code 0 with `allocateAll`'s stock, allocations and reasons. -/
def batchSpec (available : Int) (whole : Bool) (ids qs : List Int) :
    Int × Int × List Int × List Int :=
  if Spec.InRange available qs then
    if HasRepeat ids qs.length then (2, 0, [], [])
    else ((0 : Int), (Spec.allocateAll whole available qs).1,
      (Spec.allocateAll whole available qs).2.1, (Spec.allocateAll whole available qs).2.2)
  else (1, 0, [], [])

/-- The step bound of `allocate-batch` on `n` requests. -/
def batchSteps (n : Nat) : Nat := 181 + 224 * n + 172 * tri n

/-- The cost bound of `allocate-batch` on `n` requests: `run_cases.cost_bound`,
since `tri n = n (n - 1) / 2`. -/
def batchCost (n : Nat) : Nat := 165 + 202 * n + 163 * tri n

/-- `allocate-batch`'s body, run as the reference runner runs the entry word,
returns `batchSpec` within `batchSteps` steps and `batchCost` cost. The IDs are
the host's encoding: four parts per request, each part in range. -/
theorem allocate_batch (available : Int) (whole : Bool) (ids qs : List Int) (tail : Stack)
    (hn : ids.length = 4 * qs.length) (hIds : IdParts ids) :
    RW «allocate-batch».body (batchIn available whole ids qs tail)
      (batchOut (batchSpec available whole ids qs).1 (batchSpec available whole ids qs).2.1
        (batchSpec available whole ids qs).2.2.1 (batchSpec available whole ids qs).2.2.2 tail)
      (batchSteps qs.length) (batchCost qs.length) := by
  obtain ⟨ok, ⟨s₁, c₁, hRange, hs₁, hc₁⟩, hOk⟩ :=
    in_range available qs (batchIn available whole ids qs tail)
  unfold batchSteps batchCost
  cases ok with
  | false =>
    have hIn : ¬ Spec.InRange available qs := fun h => by simpa using hOk.mpr h
    have e : batchSpec available whole ids qs = (1, 0, [], []) := by simp [batchSpec, hIn]
    rw [e]
    exact ⟨_, _, batch_out_of_range hRange, by omega, by omega⟩
  | true =>
    have hIn : Spec.InRange available qs := hOk.mp rfl
    obtain ⟨h0, h1, hLen, hQs⟩ := id hIn
    obtain ⟨found, ⟨s₂, c₂, hRepeat, hs₂, hc₂⟩, hFound⟩ :=
      has_repeat ids qs.length hn hIds (by omega) (kept available whole qs tail)
    cases found with
    | true =>
      have e : batchSpec available whole ids qs = (2, 0, [], []) := by
        rw [batchSpec, if_pos hIn, if_pos (hFound.mp rfl)]
      rw [e]
      exact ⟨_, _, batch_repeat hRange hRepeat, by omega, by omega⟩
    | false =>
      have hNo : ¬ HasRepeat ids qs.length := fun h => by simpa using hFound.mpr h
      have e : batchSpec available whole ids qs = ((0 : Int),
          (Spec.allocateAll whole available qs).1, (Spec.allocateAll whole available qs).2.1,
          (Spec.allocateAll whole available qs).2.2) := by
        rw [batchSpec, if_pos hIn, if_neg hNo]
      rw [e]
      obtain ⟨s₃, c₃, hFrom, hs₃, hc₃⟩ := allocate_from qs whole hLen hQs qs.length 0 available
        [] [] (.literal (.int 0) :: tail) (by simp) (by omega) ⟨h0, h1⟩
      have hFrom' := hFrom.congr_stacks
          (before' := fromIn qs whole available 0 [] [] (.literal (.int 0) :: tail))
          (after' := fromOut (Spec.allocateAll whole available qs).1
          (Spec.allocateAll whole available qs).2.1 (Spec.allocateAll whole available qs).2.2
          (.literal (.int 0) :: tail)) (by simp) (by simp)
      exact ⟨_, _, batch_allocate hRange hRepeat hFrom', by omega, by omega⟩

/-- `allocate_batch` under the reference interpreter's registry, the one the
host runs the entry word with. -/
theorem allocate_batch_reference (available : Int) (whole : Bool) (ids qs : List Int)
    (tail : Stack) (hn : ids.length = 4 * qs.length) (hIds : IdParts ids) :
    RunsWithin adapterGamma dictionary defaultCosts «allocate-batch».body
      (batchIn available whole ids qs tail)
      (batchOut (batchSpec available whole ids qs).1 (batchSpec available whole ids qs).2.1
        (batchSpec available whole ids qs).2.2.1 (batchSpec available whole ids qs).2.2.2 tail)
      (batchSteps qs.length) (batchCost qs.length) := by
  obtain ⟨s, c, h, hs, hc⟩ := allocate_batch available whole ids qs tail hn hIds
  exact ⟨s, c, h.of_int64, hs, hc⟩

/-- A call to `allocate-batch` costs one unfold more than its body. -/
theorem allocate_batch_call (available : Int) (whole : Bool) (ids qs : List Int) (tail : Stack)
    (hn : ids.length = 4 * qs.length) (hIds : IdParts ids) :
    RW (.cons (.word "allocate-batch") .empty) (batchIn available whole ids qs tail)
      (batchOut (batchSpec available whole ids qs).1 (batchSpec available whole ids qs).2.1
        (batchSpec available whole ids qs).2.2.1 (batchSpec available whole ids qs).2.2.2 tail)
      (batchSteps qs.length + 1) (batchCost qs.length + 1) := by
  obtain ⟨s, c, h, hs, hc⟩ := allocate_batch available whole ids qs tail hn hIds
  exact ⟨_, _, runs_word «allocate-batch».entry h, by omega, by simp only [defaultCosts_unfold]; omega⟩

theorem tri_eq (n : Nat) : 2 * tri n = n * (n - 1) := by
  induction n with
  | zero => rfl
  | succ m ih =>
    rw [DupScan.tri_succ, Nat.mul_add, ih]
    cases m with
    | zero => rfl
    | succ k => simp only [Nat.add_sub_cancel]; rw [Nat.mul_comm (k + 1 + 1) (k + 1), Nat.mul_succ (k + 1) (k + 1), Nat.mul_succ (k + 1) k]; omega

/-- `batchCost` is `run_cases.cost_bound`: `165 + 202 n + 163 n (n - 1) / 2`. -/
theorem batchCost_eq (n : Nat) : batchCost n = 165 + 202 * n + 163 * (n * (n - 1) / 2) := by
  have := tri_eq n
  unfold batchCost
  have : tri n = n * (n - 1) / 2 := by omega
  rw [this]

/-- At the spec's largest batch, 64 requests, the cost is at most 341,701. -/
theorem batchCost_64 : batchCost 64 = 341701 := by decide

/-- What the host hands `allocate-batch`: the stock, the policy (`true` for
all-or-nothing), the IDs as one flat sequence and the quantities. -/
structure BatchArgs where
  available : Int
  whole : Bool
  ids : List Int
  qs : List Int

/-- `allocate-batch`'s contract. The precondition is the host's ID encoding:
four parts per request, each in `[0, 65^8)`. Nothing else is assumed: stock and
quantities outside the spec's bounds are answered with code 1 inside the
contract. -/
def allocateBatchContract : WordContract where
  Args := BatchArgs
  pre a := a.ids.length = 4 * a.qs.length ∧ IdParts a.ids
  input a := batchIn a.available a.whole a.ids a.qs []
  output a := batchOut (batchSpec a.available a.whole a.ids a.qs).1
    (batchSpec a.available a.whole a.ids a.qs).2.1 (batchSpec a.available a.whole a.ids a.qs).2.2.1
    (batchSpec a.available a.whole a.ids a.qs).2.2.2 []
  steps a := batchSteps a.qs.length
  cost a := batchCost a.qs.length
  witness := ⟨⟨0, false, [], []⟩, rfl, fun _ h => nomatch h⟩

/-- The recorded contract of `allocate-batch`, under the i64 registry. -/
theorem allocate_batch_contract :
    allocateBatchContract.Holds int64Gamma dictionary defaultCosts «allocate-batch».body :=
  fun a tail hPre => allocate_batch a.available a.whole a.ids a.qs tail hPre.1 hPre.2

end Batch

end Firth.Proofs.Inventory.Allocate
