import Firth.ProgramLogic
import exports.Inventory.Allocator

/-!
The inventory allocator's repeated-ID scan (`has-repeat` and the words it
calls in `examples/inventory/allocator.firth`), proved from its exported kernel
program. The scan is written with locals, which the elaborator compiles to the
kernel atoms `pick` and `roll`.

The host passes the request IDs as one flat `Seq Int`, four parts per ID, each
part eight base-65 digits, so every part is in `[0, 65^8)`. For such a
sequence of `n` IDs, `has-repeat` leaves `true` exactly when two of the IDs are
equal, within `172·n(n−1)/2 + 49n + 44` transitions and a kernel cost of
`163·n(n−1)/2 + 45n + 42`. The 163 per pair is the measured worst case of
`examples/inventory/measure_cost.py`: `same-id` costs 120 when the first parts
agree and every other part takes the negating branch of `distance`, and
`repeat-from` adds 43.

Every fact is proved under `int64Gamma`, where `+`, `-` and `*` fault outside
i64 as the VM's do, so the scan never overflows on such input; `Runs.of_int64`
gives the same facts under the reference registry. The remaining gaps are the
ones every such proof states: VM agreement with the reference interpreter rests
on differential testing, and the host's ID encoding is tested, not proved.
-/

namespace Firth.Proofs.Inventory.DupScan
open Firth.Interpreter
open Firth.Logic
open Firth.ReferenceRun
open Firth.Exports.Inventory.Allocator

abbrev R := Runs int64Gamma dictionary defaultCosts
abbrev RW := RunsWithin int64Gamma dictionary defaultCosts

/-- `65^8`: every ID part is below it. -/
def partLimit : Int := 318644812890625

theorem partLimit_eq : partLimit = 65 ^ 8 := by decide

/-- The distance `distance` computes between `x` and `y`. It is irreducible so
that a chain settling an `if` on it never tries to evaluate it. -/
@[irreducible] def absDiff (x y : Int) : Int := if x - y < 0 then y - x else x - y

/-- Steps and cost of `distance` on `x y`, which depend on the branch taken. -/
def distanceCost (x y : Int) : Nat := if x - y < 0 then 11 else 8

/-! ## Distances between ID parts -/

theorem distance_neg (x y : Int) (tail : Stack) (h : x - y < 0) (hr : InInt64 (x - y))
    (hr2 : InInt64 (0 - (x - y))) :
    R (.cons (.word "distance") .empty) (.literal (.int y) :: .literal (.int x) :: tail)
      (.literal (.int (0 - (x - y))) :: tail) 11 11 := by
  runs_unfold

theorem distance_nonneg (x y : Int) (tail : Stack) (h : ¬ x - y < 0) (hr : InInt64 (x - y)) :
    R (.cons (.word "distance") .empty) (.literal (.int y) :: .literal (.int x) :: tail)
      (.literal (.int (x - y)) :: tail) 8 8 := by
  runs_unfold

theorem distanceCost_le (x y : Int) : distanceCost x y ≤ 11 := by
  unfold distanceCost; split <;> omega

theorem absDiff_nonneg (x y : Int) : 0 ≤ absDiff x y := by
  unfold absDiff; split <;> omega

theorem absDiff_eq_zero (x y : Int) : absDiff x y = 0 ↔ x = y := by
  unfold absDiff; split <;> omega

/-- `distance` on two ID parts leaves their distance. -/
theorem distance {x y : Int} (hx : 0 ≤ x ∧ x < partLimit) (hy : 0 ≤ y ∧ y < partLimit)
    (tail : Stack) :
    R (.cons (.word "distance") .empty) (.literal (.int y) :: .literal (.int x) :: tail)
      (.literal (.int (absDiff x y)) :: tail) (distanceCost x y) (distanceCost x y) := by
  simp only [partLimit] at hx hy
  by_cases h : x - y < 0
  · have := distance_neg x y tail h (by simp only [InInt64]; omega) (by simp only [InInt64]; omega)
    exact (this.congr_stacks rfl (by simp [absDiff, h]; omega)).congr
      (by simp [distanceCost, h]) (by simp [distanceCost, h])
  · have := distance_nonneg x y tail h (by simp only [InInt64]; omega)
    exact (this.congr_stacks rfl (by simp [absDiff, h])).congr
      (by simp [distanceCost, h]) (by simp [distanceCost, h])

/-- A chain step that also takes `seq-int.at` at an index the context locates,
and `distance` on parts the context bounds. -/
macro "leaf_atom" : tactic => `(tactic| first
  | apply runs_cons (runs_intSeq_at_int _ (by omega) (by assumption))
  | apply runs_cons (distance (by assumption) (by assumption) _)
  | runs_atom)

/-- `runs_unfold` with `leaf_atom`. -/
macro "leaf_chain" : tactic => `(tactic| (
  apply Runs.congr
  focus
    apply runs_word (by rfl)
    dsimp only
    runs_expand
  repeat' leaf_atom
  all_goals try runs_side))

/-- `part-distance` on `ids p q k` leaves the distance between part `k` of the
IDs at offsets `p` and `q`. -/
theorem part_distance {ids : List Int} {p q k : Int} {a b : Int}
    (hpk : 0 ≤ p + k) (hqk : 0 ≤ q + k)
    (ha : ids[(p + k).toNat]? = some a) (hb : ids[(q + k).toNat]? = some b)
    (hA : 0 ≤ a ∧ a < partLimit) (hB : 0 ≤ b ∧ b < partLimit)
    (hp : InInt64 (p + k)) (hq : InInt64 (q + k)) (tail : Stack) :
    R (.cons (.word "part-distance") .empty)
      (.literal (.int k) :: .literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
      (.literal (.int (absDiff a b)) :: tail) (11 + distanceCost a b) (11 + distanceCost a b) := by
  leaf_chain

set_option hygiene false in
/-- `runs_unfold`, but the step and cost arithmetic runs without the `if`
condition `hCond`, which `omega` would otherwise try to decide. -/
macro "word_chain" : tactic => `(tactic| (
  apply Runs.congr
  focus
    apply runs_word (by rfl)
    dsimp only
    runs_expand
  repeat' runs_atom
  all_goals try (simp only [InInt64]; omega)
  all_goals try (try clear hCond); (try clear hCond2); (try clear hCond3); runs_arith))

set_option hygiene false in
/-- `word_chain` that stops at the step and cost equations, simplified, so the
counts can be read off while a proof is written. -/
macro "word_chain_counts" : tactic => `(tactic| (
  apply Runs.congr
  focus
    apply runs_word (by rfl)
    dsimp only
    runs_expand
  repeat' runs_atom
  all_goals try (simp only [InInt64]; omega)
  all_goals try simp only [defaultCosts_atom, defaultCosts_primitive, defaultCosts_unfold,
    Nat.add_zero, Nat.zero_add]))

/-- The IDs at offsets `p` and `q` are equal: their four parts agree. -/
def blockMatch (ids : List Int) (p q : Nat) : Prop := ∀ k, k < 4 → ids[p + k]? = ids[q + k]?

/-! ## Comparing two IDs -/

/-- `same-id` when the first parts differ: it stops after one distance. -/
theorem same_id_first_differs {ids : List Int} {p q : Int} {a0 b0 : Int}
    (hp0 : 0 ≤ p + 0) (hq0 : 0 ≤ q + 0)
    (ha0 : ids[(p + 0).toNat]? = some a0) (hb0 : ids[(q + 0).toNat]? = some b0)
    (hA0 : 0 ≤ a0 ∧ a0 < partLimit) (hB0 : 0 ≤ b0 ∧ b0 < partLimit)
    (hpr : InInt64 (p + 0)) (hqr : InInt64 (q + 0))
    (hCond : decide (absDiff a0 b0 = 0) = false) (tail : Stack) :
    R (.cons (.word "same-id") .empty)
      (.literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool false) :: tail) (31 + distanceCost a0 b0) (31 + distanceCost a0 b0) := by
  have pd0 := part_distance hp0 hq0 ha0 hb0 hA0 hB0 hpr hqr
    (.literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
  runs_unfold

/-- A distance between two parts is below `65^8`, so three sum inside i64. -/
theorem absDiff_lt {x y : Int} (hx : 0 ≤ x ∧ x < partLimit) (hy : 0 ≤ y ∧ y < partLimit) :
    absDiff x y < 318644812890625 := by
  simp only [partLimit] at hx hy; unfold absDiff; split <;> omega

/-- Where the ID parts at offsets `p + k` and `q + k` are, and that they are
parts as the host encodes them. -/
structure PartsAt (ids : List Int) (p q k : Int) (a b : Int) : Prop where
  hp : 0 ≤ p + k
  hq : 0 ≤ q + k
  ha : ids[(p + k).toNat]? = some a
  hb : ids[(q + k).toNat]? = some b
  hA : 0 ≤ a ∧ a < partLimit
  hB : 0 ≤ b ∧ b < partLimit
  hpr : InInt64 (p + k)
  hqr : InInt64 (q + k)

theorem PartsAt.run {ids : List Int} {p q k a b : Int} (h : PartsAt ids p q k a b) (tail : Stack) :
    R (.cons (.word "part-distance") .empty)
      (.literal (.int k) :: .literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
      (.literal (.int (absDiff a b)) :: tail) (11 + distanceCost a b) (11 + distanceCost a b) :=
  part_distance h.hp h.hq h.ha h.hb h.hA h.hB h.hpr h.hqr tail

/-- `same-id` when the first parts agree: it sums the other three distances. -/
theorem same_id_first_equal {ids : List Int} {p q : Int} {a0 b0 a1 b1 a2 b2 a3 b3 : Int}
    (h0 : PartsAt ids p q 0 a0 b0) (h1 : PartsAt ids p q 1 a1 b1)
    (h2 : PartsAt ids p q 2 a2 b2) (h3 : PartsAt ids p q 3 a3 b3)
    (hCond : decide (absDiff a0 b0 = 0) = true) (tail : Stack) :
    R (.cons (.word "same-id") .empty)
      (.literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool (decide (absDiff a1 b1 + absDiff a2 b2 + absDiff a3 b3 = 0))) :: tail)
      (82 + distanceCost a0 b0 + distanceCost a1 b1 + distanceCost a2 b2 + distanceCost a3 b3)
      (79 + distanceCost a0 b0 + distanceCost a1 b1 + distanceCost a2 b2 + distanceCost a3 b3) := by
  have pd0 := h0.run (.literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
  have pd1 := h1.run (.literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
  have pd2 := h2.run (.literal (.int (absDiff a1 b1)) :: .literal (.int q) :: .literal (.int p) ::
    .literal (.intSeq ids) :: tail)
  have pd3 := h3.run (.literal (.int (absDiff a1 b1 + absDiff a2 b2)) :: tail)
  have l1 := absDiff_lt h1.hA h1.hB
  have l2 := absDiff_lt h2.hA h2.hB
  have l3 := absDiff_lt h3.hA h3.hB
  have n1 := absDiff_nonneg a1 b1
  have n2 := absDiff_nonneg a2 b2
  have n3 := absDiff_nonneg a3 b3
  word_chain

/-- Every part is an eight-digit base-65 number, as the host encodes IDs. -/
def IdParts (ids : List Int) : Prop := ∀ value ∈ ids, 0 ≤ value ∧ value < partLimit

theorem IdParts.get {ids : List Int} (h : IdParts ids) {i : Nat} {value : Int}
    (hGet : ids[i]? = some value) : 0 ≤ value ∧ value < partLimit :=
  h value (List.mem_of_getElem? hGet)

theorem getElem?_getD {ids : List Int} {i : Nat} (h : i < ids.length) :
    ids[i]? = some (ids.getD i 0) := by
  simp [List.getD, List.getElem?_eq_getElem h]

/-- A bound on sequence lengths and positions, far above the host's 256 parts
and far enough below `2^63` that the scan's index arithmetic stays in i64. -/
def indexLimit : Nat := 4611686018427387904

/-- The parts at `p + k` and `q + k` of an ID sequence the host encoded. -/
theorem partsAt {ids : List Int} (hIds : IdParts ids) (hLen : ids.length < indexLimit)
    (p q : Nat) (k : Int) (kn : Nat) (hk : k = kn) (hp : p + kn < ids.length)
    (hq : q + kn < ids.length) :
    PartsAt ids p q k (ids.getD (p + kn) 0) (ids.getD (q + kn) 0) := by
  subst hk
  simp only [indexLimit] at hLen
  have ha := getElem?_getD hp
  have hb := getElem?_getD hq
  refine ⟨by omega, by omega, ?_, ?_, hIds.get ha, hIds.get hb, ?_, ?_⟩
  · rwa [show ((p : Int) + kn).toNat = p + kn by omega]
  · rwa [show ((q : Int) + kn).toNat = q + kn by omega]
  · simp only [InInt64]; omega
  · simp only [InInt64]; omega

/-- `same-id` on `ids p q` leaves whether the IDs at `p` and `q` are equal:
within 123 transitions at a cost of 120 when their first parts agree, and 42
otherwise. -/
theorem same_id {ids : List Int} (hIds : IdParts ids) (hLen : ids.length < indexLimit)
    {p q : Nat} (hp : p + 3 < ids.length) (hq : q + 3 < ids.length) (tail : Stack) :
    ∃ found, RW (.cons (.word "same-id") .empty)
      (.literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool found) :: tail)
      (if ids.getD p 0 = ids.getD q 0 then 123 else 42)
      (if ids.getD p 0 = ids.getD q 0 then 120 else 42) ∧
      (found = true ↔ blockMatch ids p q) := by
  have P0 := partsAt hIds hLen p q 0 0 rfl (by omega) (by omega)
  have P1 := partsAt hIds hLen p q 1 1 rfl (by omega) (by omega)
  have P2 := partsAt hIds hLen p q 2 2 rfl (by omega) (by omega)
  have P3 := partsAt hIds hLen p q 3 3 rfl (by omega) (by omega)
  have match_iff : blockMatch ids p q ↔ ids.getD (p + 0) 0 = ids.getD (q + 0) 0 ∧
      ids.getD (p + 1) 0 = ids.getD (q + 1) 0 ∧ ids.getD (p + 2) 0 = ids.getD (q + 2) 0 ∧
      ids.getD (p + 3) 0 = ids.getD (q + 3) 0 := by
    have g : ∀ k, k < 4 → ids[p + k]? = some (ids.getD (p + k) 0) ∧
        ids[q + k]? = some (ids.getD (q + k) 0) :=
      fun k hk => ⟨getElem?_getD (by omega), getElem?_getD (by omega)⟩
    constructor
    · intro h
      refine ⟨?_, ?_, ?_, ?_⟩ <;>
      · first
        | (have := h 0 (by omega); rw [(g 0 (by omega)).1, (g 0 (by omega)).2] at this; simpa using this)
        | (have := h 1 (by omega); rw [(g 1 (by omega)).1, (g 1 (by omega)).2] at this; simpa using this)
        | (have := h 2 (by omega); rw [(g 2 (by omega)).1, (g 2 (by omega)).2] at this; simpa using this)
        | (have := h 3 (by omega); rw [(g 3 (by omega)).1, (g 3 (by omega)).2] at this; simpa using this)
    · rintro ⟨h0, h1, h2, h3⟩ k hk
      rw [(g k hk).1, (g k hk).2]
      match k, hk with
      | 0, _ => simpa using h0
      | 1, _ => simpa using h1
      | 2, _ => simpa using h2
      | 3, _ => simpa using h3
  have e0 := absDiff_eq_zero (ids.getD (p + 0) 0) (ids.getD (q + 0) 0)
  have e1 := absDiff_eq_zero (ids.getD (p + 1) 0) (ids.getD (q + 1) 0)
  have e2 := absDiff_eq_zero (ids.getD (p + 2) 0) (ids.getD (q + 2) 0)
  have e3 := absDiff_eq_zero (ids.getD (p + 3) 0) (ids.getD (q + 3) 0)
  have n1 := absDiff_nonneg (ids.getD (p + 1) 0) (ids.getD (q + 1) 0)
  have n2 := absDiff_nonneg (ids.getD (p + 2) 0) (ids.getD (q + 2) 0)
  have n3 := absDiff_nonneg (ids.getD (p + 3) 0) (ids.getD (q + 3) 0)
  have c1 := distanceCost_le (ids.getD (p + 1) 0) (ids.getD (q + 1) 0)
  have c2 := distanceCost_le (ids.getD (p + 2) 0) (ids.getD (q + 2) 0)
  have c3 := distanceCost_le (ids.getD (p + 3) 0) (ids.getD (q + 3) 0)
  by_cases h0 : ids.getD p 0 = ids.getD q 0
  · have hc : decide (absDiff (ids.getD (p + 0) 0) (ids.getD (q + 0) 0) = 0) = true :=
      decide_eq_true (e0.mpr h0)
    have c0 : distanceCost (ids.getD (p + 0) 0) (ids.getD (q + 0) 0) = 8 := by
      unfold distanceCost; rw [if_neg]; show ¬ ids.getD p 0 - ids.getD q 0 < 0; omega
    refine ⟨_, (same_id_first_equal P0 P1 P2 P3 hc tail).within.weaken ?_ ?_, ?_⟩
    · simp only [h0, if_true]; omega
    · simp only [h0, if_true]; omega
    · rw [match_iff, decide_eq_true_iff]
      constructor
      · intro h
        exact ⟨h0, e1.mp (by omega), e2.mp (by omega), e3.mp (by omega)⟩
      · rintro ⟨-, h1, h2, h3⟩
        have := e1.mpr h1; have := e2.mpr h2; have := e3.mpr h3
        omega
  · have hc : decide (absDiff (ids.getD (p + 0) 0) (ids.getD (q + 0) 0) = 0) = false :=
      decide_eq_false (fun h => h0 (e0.mp h))
    have c0 := distanceCost_le (ids.getD (p + 0) 0) (ids.getD (q + 0) 0)
    refine ⟨false, (same_id_first_differs P0.hp P0.hq P0.ha P0.hb P0.hA P0.hB P0.hpr P0.hqr hc
      tail).within.weaken ?_ ?_, ?_⟩
    · simp only [h0, if_false]; omega
    · simp only [h0, if_false]; omega
    · rw [match_iff]
      simp only [Bool.false_eq_true, false_iff]
      exact fun h => h0 h.1

/-! ## The scan over pairs of IDs -/

section Branches
variable {ids : List Int} {p q : Int} {found : Bool} {s₁ c₁ s₂ c₂ : Nat} {tail : Stack}

/-- The stack under `repeat-from`'s own copies of its arguments. -/
abbrev args (ids : List Int) (p q : Int) (tail : Stack) : Stack :=
  .literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail

/-! Each branch of `repeat-from`, with its calls given. -/

/-- `q` is inside the sequence and the IDs at `p` and `q` are equal. -/
theorem repeat_from_same (hCond : decide (q < ids.length) = true)
    (hSame : R (.cons (.word "same-id") .empty)
      (args ids p q (args ids p q tail)) (.literal (.bool true) :: args ids p q tail) s₁ c₁) :
    R (.cons (.word "repeat-from") .empty)
      (.literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool true) :: tail) (42 + s₁) (39 + c₁) := by
  word_chain

/-- `q` is inside the sequence and the IDs differ: go on with `q + 4`. -/
theorem repeat_from_next (hCond : decide (q < ids.length) = true)
    (hq0 : 0 ≤ q) (hqBig : q < 4611686018427387904)
    (hSame : R (.cons (.word "same-id") .empty)
      (args ids p q (args ids p q tail)) (.literal (.bool false) :: args ids p q tail) s₁ c₁)
    (hRec : R (.cons (.word "repeat-from") .empty)
      (.literal (.int (q + 4)) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool found) :: tail) s₂ c₂) :
    R (.cons (.word "repeat-from") .empty)
      (.literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool found) :: tail) (49 + s₁ + s₂) (43 + c₁ + c₂) := by
  word_chain

/-- `q` is past the end and another row remains: go on with `(p + 4, p + 8)`. -/
theorem repeat_from_row (hCond : decide (q < ids.length) = false)
    (hCond2 : decide (p + 8 < ids.length) = true)
    (hp0 : 0 ≤ p) (hpBig : p < 4611686018427387904)
    (hRec : R (.cons (.word "repeat-from") .empty)
      (.literal (.int (p + 8)) :: .literal (.int (p + 4)) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool found) :: tail) s₂ c₂) :
    R (.cons (.word "repeat-from") .empty)
      (.literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool found) :: tail) (49 + s₂) (45 + c₂) := by
  word_chain

/-- No pair remains. -/
theorem repeat_from_done (hCond : decide (q < ids.length) = false)
    (hCond2 : decide (p + 8 < ids.length) = false) (hp0 : 0 ≤ p)
    (hpBig : p < 4611686018427387904) :
    R (.cons (.word "repeat-from") .empty)
      (.literal (.int q) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool false) :: tail) 41 39 := by
  word_chain

end Branches

/-- Triangular numbers: `tri m = m * (m - 1) / 2`, the pairs among `m` IDs. -/
def tri : Nat → Nat
  | 0 => 0
  | m + 1 => tri m + m

theorem tri_succ (m : Nat) : tri (m + 1) = tri m + m := rfl

/-- Some ID at or after the scan position `(p, q)` equals a later one. The scan
compares the ID at `p` with those from `q` onward, then each later pair. -/
def RepeatFrom (ids : List Int) (p q : Nat) : Prop :=
  ∃ i j, i % 4 = 0 ∧ j % 4 = 0 ∧ i < j ∧ j < ids.length ∧ (i = p ∧ q ≤ j ∨ p < i) ∧
    blockMatch ids i j

/-- Pairs still to compare from `(p, q)`, plus the rows still to start. -/
def scanSize (length p q : Nat) : Nat :=
  (length - q) / 4 + tri ((length - p) / 4 - 1) + (length - p) / 4

/-- The bound for `repeat-from` at `(p, q)`: `perPair` for each pair still to
compare, `perRow` for each row and `finish` to stop. -/
def scanBound (perPair perRow finish length p q : Nat) : Nat :=
  perPair * ((length - q) / 4 + tri ((length - p) / 4 - 1)) + perRow * ((length - p) / 4) + finish

/-- What `repeat-from` does at one scan position. -/
def RepeatSpec (ids : List Int) (pq : Nat × Nat) : Prop :=
  pq.1 % 4 = 0 → pq.2 % 4 = 0 → pq.1 < pq.2 → pq.2 ≤ ids.length + 4 → ∀ tail : Stack,
    ∃ found, RW (.cons (.word "repeat-from") .empty)
      (.literal (.int pq.2) :: .literal (.int pq.1) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool found) :: tail)
      (scanBound 172 49 41 ids.length pq.1 pq.2) (scanBound 163 45 39 ids.length pq.1 pq.2) ∧
      (found = true ↔ RepeatFrom ids pq.1 pq.2)

theorem repeat_from {ids : List Int} (hIds : IdParts ids) (hLen : ids.length < indexLimit)
    (hL : ids.length % 4 = 0) (pq : Nat × Nat) : RepeatSpec ids pq := by
  induction pq using induction_on_measure (fun pq : Nat × Nat => scanSize ids.length pq.1 pq.2) with
  | step pq ih =>
  obtain ⟨p, q⟩ := pq
  intro hp hq hpq hqEnd tail
  simp only at hp hq hpq hqEnd ih ⊢
  have hLenI := hLen
  simp only [indexLimit] at hLen
  by_cases hqL : q < ids.length
  · have hCond : decide ((q : Int) < ids.length) = true := decide_eq_true (by omega)
    obtain ⟨same, ⟨s₁, c₁, hSame, hs₁, hc₁⟩, hSameIff⟩ :=
      same_id hIds hLenI (p := p) (q := q) (by omega) (by omega) (args ids p q tail)
    have hs₁' : s₁ ≤ 123 := by split at hs₁ <;> omega
    have hc₁' : c₁ ≤ 120 := by split at hc₁ <;> omega
    cases same with
    | true =>
      refine ⟨true, ⟨_, _, repeat_from_same hCond hSame, ?_, ?_⟩, ?_⟩
      · simp only [scanBound]; omega
      · simp only [scanBound]; omega
      · simp only [true_iff]
        exact ⟨p, q, hp, hq, hpq, hqL, .inl ⟨rfl, Nat.le_refl _⟩, hSameIff.mp rfl⟩
    | false =>
      obtain ⟨found, ⟨s₂, c₂, hRest, hs₂, hc₂⟩, hRestIff⟩ :=
        ih (p, q + 4) (by simp only [scanSize]; omega) hp (by omega) (by omega) (by omega) tail
      have hRest' : R (.cons (.word "repeat-from") .empty)
          (.literal (.int ((q : Int) + 4)) :: .literal (.int p) :: .literal (.intSeq ids) :: tail)
          (.literal (.bool found) :: tail) s₂ c₂ := hRest.congr_stacks (by simp) rfl
      refine ⟨found, ⟨_, _, repeat_from_next hCond (by omega) (by omega) hSame hRest', ?_, ?_⟩, ?_⟩
      · simp only [scanBound] at hs₂ ⊢; omega
      · simp only [scanBound] at hc₂ ⊢; omega
      · rw [hRestIff]
        constructor
        · rintro ⟨i, j, hi, hj, hij, hjL, hpos, hm⟩
          exact ⟨i, j, hi, hj, hij, hjL, by omega, hm⟩
        · rintro ⟨i, j, hi, hj, hij, hjL, hpos, hm⟩
          refine ⟨i, j, hi, hj, hij, hjL, ?_, hm⟩
          by_cases hij' : i = p ∧ j = q
          · obtain ⟨rfl, rfl⟩ := hij'
            exact absurd (hSameIff.mpr hm) (by simp)
          · omega
  · have hCond : decide ((q : Int) < ids.length) = false := decide_eq_false (by omega)
    by_cases hpL : p + 8 < ids.length
    · have hCond2 : decide ((p : Int) + 8 < ids.length) = true := decide_eq_true (by omega)
      have tri_row : tri ((ids.length - p) / 4 - 1) =
          tri ((ids.length - (p + 4)) / 4 - 1) + ((ids.length - (p + 4)) / 4 - 1) := by
        rw [show (ids.length - p) / 4 - 1 = ((ids.length - (p + 4)) / 4 - 1) + 1 by omega]; rfl
      obtain ⟨found, ⟨s₂, c₂, hRest, hs₂, hc₂⟩, hRestIff⟩ :=
        ih (p + 4, p + 8) (by simp only [scanSize]; omega) (by omega) (by omega) (by omega)
          (by omega) tail
      have hRest' : R (.cons (.word "repeat-from") .empty)
          (.literal (.int ((p : Int) + 8)) :: .literal (.int ((p : Int) + 4)) ::
            .literal (.intSeq ids) :: tail)
          (.literal (.bool found) :: tail) s₂ c₂ := hRest.congr_stacks (by simp) rfl
      refine ⟨found, ⟨_, _, repeat_from_row hCond hCond2 (by omega) (by omega) hRest', ?_, ?_⟩, ?_⟩
      · simp only [scanBound] at hs₂ ⊢; omega
      · simp only [scanBound] at hc₂ ⊢; omega
      · rw [hRestIff]
        constructor
        · rintro ⟨i, j, hi, hj, hij, hjL, hpos, hm⟩
          exact ⟨i, j, hi, hj, hij, hjL, by omega, hm⟩
        · rintro ⟨i, j, hi, hj, hij, hjL, hpos, hm⟩
          exact ⟨i, j, hi, hj, hij, hjL, by omega, hm⟩
    · have hCond2 : decide ((p : Int) + 8 < ids.length) = false := decide_eq_false (by omega)
      refine ⟨false, ⟨_, _, repeat_from_done hCond hCond2 (by omega) (by omega), ?_, ?_⟩, ?_⟩
      · simp only [scanBound]; omega
      · simp only [scanBound]; omega
      · simp only [Bool.false_eq_true, false_iff]
        rintro ⟨i, j, hi, hj, hij, hjL, hpos, hm⟩
        omega

/-! ## `has-repeat` -/

/-- Two of the `n` IDs in `ids` (four parts each) are equal. -/
def HasRepeat (ids : List Int) (n : Nat) : Prop :=
  ∃ i j, i < j ∧ j < n ∧ blockMatch ids (4 * i) (4 * j)

theorem scanBound_start (perPair perRow finish n : Nat) :
    scanBound perPair perRow finish (4 * n) 0 4 = perPair * tri n + perRow * n + finish := by
  cases n with
  | zero => simp [scanBound, tri]
  | succ m =>
    simp only [scanBound, show (4 * (m + 1) - 4) / 4 = m by omega,
      show (4 * (m + 1) - 0) / 4 = m + 1 by omega, Nat.add_sub_cancel, tri_succ]
    rw [Nat.add_comm m (tri m)]

/-- For `ids` holding `n` IDs of four parts each, as the host encodes them,
`has-repeat` leaves `true` exactly when two of the IDs are equal, within
`172·n(n−1)/2 + 49n + 44` transitions at a kernel cost of at most
`163·n(n−1)/2 + 45n + 42`, and no arithmetic leaves i64. -/
theorem has_repeat (ids : List Int) (n : Nat) (hn : ids.length = 4 * n) (hIds : IdParts ids)
    (hSize : n < 2 ^ 32) (tail : Stack) :
    ∃ found, RW (.cons (.word "has-repeat") .empty)
      (.literal (.intSeq ids) :: tail) (.literal (.bool found) :: tail)
      (172 * tri n + 49 * n + 44) (163 * tri n + 45 * n + 42) ∧
      (found = true ↔ HasRepeat ids n) := by
  obtain ⟨found, ⟨steps, cost, hRun, hs, hc⟩, hIff⟩ :=
    repeat_from hIds (by simp only [indexLimit]; omega) (by omega) (0, 4) rfl rfl (by decide)
      (by omega) tail
  have hRun' : R (.cons (.word "repeat-from") .empty)
      (.literal (.int 4) :: .literal (.int 0) :: .literal (.intSeq ids) :: tail)
      (.literal (.bool found) :: tail) steps cost := hRun.congr_stacks (by simp) rfl
  simp only [hn, scanBound_start] at hs hc
  refine ⟨found, ⟨_, _, runs_word «has-repeat».entry <|
    runs_cons (runs_literal_int 0 _) <| runs_cons (runs_literal_int 4 _) <|
    runs_cons hRun' (runs_empty _), by simp; omega, by simp; omega⟩, ?_⟩
  rw [hIff]
  constructor
  · rintro ⟨i, j, hi, hj, hij, hjL, -, hm⟩
    refine ⟨i / 4, j / 4, by omega, by omega, ?_⟩
    rwa [show 4 * (i / 4) = i by omega, show 4 * (j / 4) = j by omega]
  · rintro ⟨i, j, hij, hjn, hm⟩
    exact ⟨4 * i, 4 * j, by omega, by omega, by omega, by omega, by omega, hm⟩

/-- The same under the reference interpreter's registry. -/
theorem has_repeat_reference (ids : List Int) (n : Nat) (hn : ids.length = 4 * n)
    (hIds : IdParts ids) (hSize : n < 2 ^ 32) (tail : Stack) :
    ∃ found, RunsWithin adapterGamma dictionary defaultCosts (.cons (.word "has-repeat") .empty)
      (.literal (.intSeq ids) :: tail) (.literal (.bool found) :: tail)
      (172 * tri n + 49 * n + 44) (163 * tri n + 45 * n + 42) ∧
      (found = true ↔ HasRepeat ids n) := by
  obtain ⟨found, ⟨steps, cost, hRun, hs, hc⟩, hIff⟩ := has_repeat ids n hn hIds hSize tail
  exact ⟨found, ⟨steps, cost, hRun.of_int64, hs, hc⟩, hIff⟩

end Firth.Proofs.Inventory.DupScan
