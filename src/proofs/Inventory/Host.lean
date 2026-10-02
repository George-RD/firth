import proofs.Inventory.Allocate

/-!
The inventory allocator's host encoding, the part of
`specs/inventory-allocation.md` ("Host and Firth split") that turns request IDs
into the component's input and the component's answer back into allocations.
These are the functions the host runs: `lake exe inventoryHost`
(`HostMain.lean`) evaluates them for `examples/inventory/run_cases.py`, so the
facts below are about the code that runs, not a copy of it.

* `encodeId` writes an ID as four Ints, eight base-65 digits each, a character
  being its position in `alphabet` plus one and 0 padding a short ID. It is
  injective on the spec's ID syntax (`encodeId_inj`) and every part is below
  `65^8` (`encodeIds_idParts`), the precondition of `allocateBatchContract`.
* So on encoded IDs the repeated-block test `HasRepeat` is exactly "two
  requests have the same ID" (`hasRepeat_encodeIds`), and `allocate-batch`
  computes `hostSpec`, the spec's answer stated on the ID strings
  (`allocate_batch_host_contract`).
* `hostEncode` attaches each allocation and reason to its request's ID by
  position. On success the allocations carry the request IDs in request order,
  each with its own quantity and reason (`hostEncode_ok`).

What stays in Python is what the spec gives the host and Lean does not model:
JSON parsing, the shape and type checks that answer `invalid-input`, the i64
range check that answers `invalid-range`, and the JSON transport to and from
this executable. The ID syntax is checked twice: by the Python pattern, which
decides `invalid-input`, and by `validId` here (`validId_iff`), which refuses
to encode anything the proofs do not cover.
-/

namespace Firth.Proofs.Inventory.Host
open Firth.Interpreter
open Firth.Logic
open Firth.ReferenceRun
open Firth.Exports.Inventory.Allocator
open Firth.Proofs.Inventory.DupScan (HasRepeat IdParts blockMatch partLimit partLimit_eq)
open Firth.Proofs.Inventory.Allocate

/-! ## The ID encoding -/

/-- The spec's ID characters, in digit order. -/
def alphabet : List Char :=
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-".toList

theorem alphabet_length : alphabet.length = 64 := by decide

/-- The spec's ID syntax: 1 to 32 characters from `alphabet`. -/
def ValidId (s : String) : Prop := 0 < s.length ∧ s.length ≤ 32 ∧ ∀ c ∈ s.toList, c ∈ alphabet

/-- `ValidId`, decided. -/
def validId (s : String) : Bool :=
  0 < s.length && s.length ≤ 32 && s.toList.all (· ∈ alphabet)

theorem validId_iff (s : String) : validId s = true ↔ ValidId s := by
  simp [validId, ValidId, List.all_eq_true, and_assoc]

/-- A character's digit: its position in `alphabet` plus one, so 0 is free for
padding. -/
def digit (c : Char) : Nat := alphabet.idxOf c + 1

/-- The 32 digits of an ID: its characters' digits, then 0s. -/
def digits (s : String) : List Nat := s.toList.map digit ++ List.replicate (32 - s.length) 0

/-- Digits read as a base-65 number, most significant first. -/
def part (ds : List Nat) : Nat := ds.foldl (fun v d => v * 65 + d) 0

/-- Eight digits starting at `k`. -/
def chunk (ds : List Nat) (k : Nat) : List Nat := (ds.drop k).take 8

/-- An ID as four Ints, eight base-65 digits each. -/
def encodeId (s : String) : List Int :=
  [0, 8, 16, 24].map fun k => ((part (chunk (digits s) k) : Nat) : Int)

/-- The component's ID sequence: every request's four parts, in request order. -/
def encodeIds (ids : List String) : List Int := ids.flatMap encodeId

/-! ### Base 65 -/

theorem foldl_part (a : Nat) (ds : List Nat) :
    ds.foldl (fun v d => v * 65 + d) a = a * 65 ^ ds.length + part ds := by
  induction ds generalizing a with
  | nil => simp [part]
  | cons d ds ih =>
    simp only [part, List.foldl_cons, List.length_cons]
    rw [ih, ih (0 * 65 + d), Nat.pow_succ]
    simp only [Nat.zero_mul, Nat.zero_add, Nat.add_mul, Nat.mul_assoc, Nat.add_assoc]
    rw [Nat.mul_comm 65 (65 ^ ds.length)]

theorem part_cons (d : Nat) (ds : List Nat) : part (d :: ds) = d * 65 ^ ds.length + part ds := by
  simp only [part, List.foldl_cons]
  rw [foldl_part]; simp [part]

theorem part_lt (ds : List Nat) (h : ∀ d ∈ ds, d < 65) : part ds < 65 ^ ds.length := by
  induction ds with
  | nil => simp [part]
  | cons d ds ih =>
    rw [part_cons, List.length_cons, Nat.pow_succ]
    have hd : d < 65 := h d (by simp)
    have hs := ih (fun e he => h e (by simp [he]))
    have : d * 65 ^ ds.length + part ds < (d + 1) * 65 ^ ds.length := by
      rw [Nat.add_mul, Nat.one_mul]; omega
    calc d * 65 ^ ds.length + part ds < (d + 1) * 65 ^ ds.length := this
      _ ≤ 65 * 65 ^ ds.length := Nat.mul_le_mul_right _ hd
      _ = 65 ^ ds.length * 65 := Nat.mul_comm _ _

/-- Base 65 is injective on equal-length digit lists. -/
theorem part_inj : ∀ (ds es : List Nat), ds.length = es.length → (∀ d ∈ ds, d < 65) →
    (∀ e ∈ es, e < 65) → part ds = part es → ds = es
  | [], [], _, _, _, _ => rfl
  | [], _ :: _, h, _, _, _ => by simp at h
  | _ :: _, [], h, _, _, _ => by simp at h
  | d :: ds, e :: es, hLen, hd, he, hEq => by
    simp only [List.length_cons, Nat.add_right_cancel_iff] at hLen
    rw [part_cons, part_cons, ← hLen] at hEq
    have hds := part_lt ds (fun x hx => hd x (by simp [hx]))
    have hes := part_lt es (fun x hx => he x (by simp [hx]))
    rw [← hLen] at hes
    have hPos : 0 < 65 ^ ds.length := Nat.pow_pos (by decide)
    have hHead : d = e := by
      have h1 := congrArg (· / 65 ^ ds.length) hEq
      simp only at h1
      rwa [Nat.mul_comm d, Nat.mul_comm e, Nat.mul_add_div hPos, Nat.mul_add_div hPos,
        Nat.div_eq_of_lt hds, Nat.div_eq_of_lt hes, Nat.add_zero, Nat.add_zero] at h1
    subst hHead
    have hTail : part ds = part es := by omega
    rw [part_inj ds es hLen (fun x hx => hd x (by simp [hx])) (fun x hx => he x (by simp [hx])) hTail]

/-! ### Digits -/

theorem idxOf_getElem {l : List Char} {c : Char} (h : c ∈ l) :
    l[l.idxOf c]'(List.idxOf_lt_length_iff.mpr h) = c := by
  induction l with
  | nil => simp at h
  | cons a l ih =>
    by_cases hac : a = c
    · subst hac; simp [List.idxOf_cons_self]
    · have hl : c ∈ l := by simpa [Ne.symm hac] using h
      have hb : (a == c) = false := by simp [hac]
      have : (a :: l).idxOf c = l.idxOf c + 1 := by
        simp [List.idxOf_cons, hb]
      simp only [this, List.getElem_cons_succ]
      exact ih hl

theorem digit_inj {c d : Char} (hc : c ∈ alphabet) (hd : d ∈ alphabet) (h : digit c = digit d) :
    c = d := by
  have : alphabet.idxOf c = alphabet.idxOf d := by simp only [digit] at h; omega
  rw [← idxOf_getElem hc, ← idxOf_getElem hd]
  simp only [this]

theorem digit_pos (c : Char) : 0 < digit c := Nat.succ_pos _

theorem digit_lt {c : Char} (hc : c ∈ alphabet) : digit c < 65 := by
  have := List.idxOf_lt_length_iff.mpr hc
  rw [alphabet_length] at this
  simp only [digit]; omega

theorem digits_length {s : String} (h : s.length ≤ 32) : (digits s).length = 32 := by
  simp [digits, String.length_toList]; omega

theorem digits_lt {s : String} (h : ValidId s) : ∀ d ∈ digits s, d < 65 := by
  intro d hd
  simp only [digits, List.mem_append, List.mem_map, List.mem_replicate] at hd
  rcases hd with ⟨c, hc, rfl⟩ | ⟨_, rfl⟩
  · exact digit_lt (h.2.2 c hc)
  · decide

theorem chunk_getElem {ds : List Nat} {k r : Nat} (hr : r < 8) :
    (chunk ds k)[r]? = ds[k + r]? := by
  simp [chunk, hr, List.getElem?_drop]

/-- Equal parts mean equal digits. -/
theorem digits_eq_of_encodeId {s t : String} (hs : ValidId s) (ht : ValidId t)
    (h : encodeId s = encodeId t) : digits s = digits t := by
  have hls := digits_length hs.2.1
  have hlt := digits_length ht.2.1
  have hChunk : ∀ k ∈ [0, 8, 16, 24], chunk (digits s) k = chunk (digits t) k := by
    intro k hk
    have hp : part (chunk (digits s) k) = part (chunk (digits t) k) := by
      simp only [encodeId, List.map_cons, List.map_nil, List.cons.injEq] at h
      simp only [List.mem_cons, List.not_mem_nil, or_false] at hk
      rcases hk with rfl | rfl | rfl | rfl <;> omega
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hk
    apply part_inj _ _ _ _ _ hp
    · simp only [chunk, List.length_take, List.length_drop, hls, hlt]
    · intro d hd; exact digits_lt hs d (List.mem_of_mem_drop (List.mem_of_mem_take hd))
    · intro d hd; exact digits_lt ht d (List.mem_of_mem_drop (List.mem_of_mem_take hd))
  apply List.ext_getElem?
  intro i
  by_cases hi : i < 32
  · have hk : i / 8 * 8 ∈ [0, 8, 16, 24] := by
      have : i / 8 = 0 ∨ i / 8 = 1 ∨ i / 8 = 2 ∨ i / 8 = 3 := by omega
      rcases this with h | h | h | h <;> simp [h]
    have e := congrArg (·[i % 8]?) (hChunk _ hk)
    simp only at e
    rw [chunk_getElem (Nat.mod_lt _ (by decide)), chunk_getElem (Nat.mod_lt _ (by decide)),
      show i / 8 * 8 + i % 8 = i by omega] at e
    exact e
  · rw [List.getElem?_eq_none (by omega), List.getElem?_eq_none (by omega)]

/-- Equal digits mean equal IDs. -/
theorem eq_of_digits {s t : String} (hs : ValidId s) (ht : ValidId t)
    (h : digits s = digits t) : s = t := by
  have hl : s.length = t.length := by
    refine Classical.byContradiction fun hne => ?_
    have key : ∀ {a b : String}, ValidId a → ValidId b → a.length < b.length →
        digits a = digits b → False := by
      intro a b ha hb hab hd
      have e := congrArg (·[a.length]?) hd
      simp only [digits] at e
      rw [List.getElem?_append_right (by simp [String.length_toList]),
        List.getElem?_append_left (by simp [String.length_toList]; exact hab)] at e
      simp only [List.length_map, String.length_toList, Nat.sub_self,
        List.getElem?_replicate, List.getElem?_map] at e
      have hpos : 0 < 32 - a.length := by have := hb.2.1; omega
      simp only [hpos, ite_true] at e
      have hget : b.toList[a.length]? = some (b.toList[a.length]'(by
          simp [String.length_toList]; exact hab)) := List.getElem?_eq_getElem _
      rw [hget] at e
      simp only [Option.map_some, Option.some.injEq] at e
      exact absurd e.symm (Nat.ne_of_gt (digit_pos _))
    rcases Nat.lt_or_gt_of_ne hne with hlt | hgt
    · exact key hs ht hlt h
    · exact key ht hs hgt h.symm
  apply String.ext
  have hm : s.toList.map digit = t.toList.map digit := by
    have e := congrArg (·.take s.length) h
    simp only [digits] at e
    rwa [List.take_append_of_le_length (by simp [String.length_toList]),
      List.take_append_of_le_length (by simp [String.length_toList, hl]),
      List.take_of_length_le (by simp [String.length_toList]),
      List.take_of_length_le (by simp [String.length_toList, hl])] at e
  apply List.ext_getElem (by simp [String.length_toList, hl])
  intro i h1 h2
  have e := congrArg (·[i]?) hm
  simp only [List.getElem?_map, List.getElem?_eq_getElem h1, List.getElem?_eq_getElem h2,
    Option.map_some, Option.some.injEq] at e
  exact digit_inj (hs.2.2 _ (List.getElem_mem h1)) (ht.2.2 _ (List.getElem_mem h2)) e

/-- The encoding is injective on the spec's ID syntax. -/
theorem encodeId_inj {s t : String} (hs : ValidId s) (ht : ValidId t)
    (h : encodeId s = encodeId t) : s = t :=
  eq_of_digits hs ht (digits_eq_of_encodeId hs ht h)

theorem encodeId_length (s : String) : (encodeId s).length = 4 := by simp [encodeId]

/-- Every part of a valid ID is in `[0, 65^8)`. -/
theorem encodeId_parts {s : String} (hs : ValidId s) : IdParts (encodeId s) := by
  intro v hv
  simp only [encodeId, List.mem_map, List.mem_cons, List.not_mem_nil, or_false] at hv
  obtain ⟨k, -, rfl⟩ := hv
  have hlen : (chunk (digits s) k).length ≤ 8 := by simp only [chunk, List.length_take]; exact Nat.min_le_left _ _
  have hlt := part_lt (chunk (digits s) k)
    (fun d hd => digits_lt hs d (List.mem_of_mem_drop (List.mem_of_mem_take hd)))
  have hle : 65 ^ (chunk (digits s) k).length ≤ 65 ^ 8 := Nat.pow_le_pow_right (by decide) hlen
  rw [partLimit_eq]
  constructor
  · exact Int.natCast_nonneg _
  · have : part (chunk (digits s) k) < 65 ^ 8 := Nat.lt_of_lt_of_le hlt hle
    exact_mod_cast this

/-! ## Repeated IDs -/

theorem encodeIds_getElem : ∀ (ids : List String) (i k : Nat), i < ids.length → k < 4 →
    (encodeIds ids)[4 * i + k]? = (encodeId (ids[i]?.getD ""))[k]?
  | [], _, _, h, _ => by simp at h
  | s :: rest, 0, k, _, hk => by
    simp only [encodeIds, List.flatMap_cons, Nat.mul_zero, Nat.zero_add,
      List.getElem?_cons_zero, Option.getD_some]
    rw [List.getElem?_append_left (by rw [encodeId_length]; exact hk)]
  | s :: rest, i + 1, k, hi, hk => by
    simp only [encodeIds, List.flatMap_cons, List.getElem?_cons_succ]
    rw [List.getElem?_append_right (by rw [encodeId_length]; omega), encodeId_length,
      show 4 * (i + 1) + k - 4 = 4 * i + k by omega]
    exact encodeIds_getElem rest i k (by simp at hi; omega) hk

theorem encodeIds_length (ids : List String) : (encodeIds ids).length = 4 * ids.length := by
  induction ids with
  | nil => rfl
  | cons s rest ih =>
    simp only [encodeIds, List.flatMap_cons, List.length_append, encodeId_length] at ih ⊢
    rw [ih, List.length_cons]; omega

theorem encodeIds_idParts {ids : List String} (h : ∀ s ∈ ids, ValidId s) :
    IdParts (encodeIds ids) := by
  intro v hv
  simp only [encodeIds, List.mem_flatMap] at hv
  obtain ⟨s, hs, hv⟩ := hv
  exact encodeId_parts (h s hs) v hv

/-- Two requests have the same ID. -/
def HasDuplicate (ids : List String) : Prop :=
  ∃ i j, i < j ∧ j < ids.length ∧ ids[i]? = ids[j]?

instance (ids : List String) : Decidable (HasDuplicate ids) :=
  decidable_of_iff (∃ j, j < ids.length ∧ ∃ i, i < j ∧ ids[i]? = ids[j]?) (by
    unfold HasDuplicate
    constructor
    · rintro ⟨j, hj, i, hi, h⟩; exact ⟨i, j, hi, hj, h⟩
    · rintro ⟨i, j, hi, hj, h⟩; exact ⟨j, hj, i, hi, h⟩)

theorem blockMatch_encodeIds {ids : List String} (h : ∀ s ∈ ids, ValidId s) {i j : Nat}
    (hi : i < ids.length) (hj : j < ids.length) :
    blockMatch (encodeIds ids) (4 * i) (4 * j) ↔ ids[i]? = ids[j]? := by
  rw [List.getElem?_eq_getElem hi, List.getElem?_eq_getElem hj, Option.some.injEq]
  have hsi := h _ (List.getElem_mem hi)
  have hsj := h _ (List.getElem_mem hj)
  constructor
  · intro hm
    apply encodeId_inj hsi hsj
    apply List.ext_getElem?
    intro k
    by_cases hk : k < 4
    · have := hm k hk
      rwa [encodeIds_getElem _ _ _ hi hk, encodeIds_getElem _ _ _ hj hk,
        List.getElem?_eq_getElem hi, List.getElem?_eq_getElem hj,
        Option.getD_some, Option.getD_some] at this
    · rw [List.getElem?_eq_none (by rw [encodeId_length]; omega),
        List.getElem?_eq_none (by rw [encodeId_length]; omega)]
  · intro he k hk
    rw [encodeIds_getElem _ _ _ hi hk, encodeIds_getElem _ _ _ hj hk,
      List.getElem?_eq_getElem hi, List.getElem?_eq_getElem hj, Option.getD_some,
      Option.getD_some, he]

/-- On encoded IDs, a repeated four-part block is exactly a repeated ID. -/
theorem hasRepeat_encodeIds {ids : List String} (h : ∀ s ∈ ids, ValidId s) :
    HasRepeat (encodeIds ids) ids.length ↔ HasDuplicate ids := by
  unfold HasRepeat HasDuplicate
  constructor
  · rintro ⟨i, j, hij, hj, hm⟩
    exact ⟨i, j, hij, hj, (blockMatch_encodeIds h (by omega) hj).mp hm⟩
  · rintro ⟨i, j, hij, hj, he⟩
    exact ⟨i, j, hij, hj, (blockMatch_encodeIds h (by omega) hj).mpr he⟩

/-! ## The contract on ID strings -/

/-- The spec's answer stated on the ID strings: code 1 out of bounds, code 2
when two requests share an ID, otherwise code 0 with `allocateAll`. -/
def hostSpec (available : Int) (whole : Bool) (ids : List String) (qs : List Int) :
    Int × Int × List Int × List Int :=
  if Spec.InRange available qs then
    if HasDuplicate ids then (2, 0, [], [])
    else ((0 : Int), (Spec.allocateAll whole available qs).1,
      (Spec.allocateAll whole available qs).2.1, (Spec.allocateAll whole available qs).2.2)
  else (1, 0, [], [])

theorem batchSpec_encodeIds {available : Int} {whole : Bool} {ids : List String} {qs : List Int}
    (hLen : ids.length = qs.length) (h : ∀ s ∈ ids, ValidId s) :
    batchSpec available whole (encodeIds ids) qs = hostSpec available whole ids qs := by
  have hr := hasRepeat_encodeIds h
  rw [hLen] at hr
  unfold batchSpec hostSpec
  by_cases hIn : Spec.InRange available qs
  · by_cases hd : HasDuplicate ids
    · rw [if_pos hIn, if_pos hIn, if_pos (hr.mpr hd), if_pos hd]
    · rw [if_pos hIn, if_pos hIn, if_neg (fun x => hd (hr.mp x)), if_neg hd]
  · rw [if_neg hIn, if_neg hIn]

/-- What the host hands `allocate-batch`, before encoding: the stock, the
policy (`true` for all-or-nothing), the ID strings and the quantities. -/
structure HostArgs where
  available : Int
  whole : Bool
  ids : List String
  qs : List Int

/-- `allocate-batch`'s contract on what the host decodes. The precondition is
the spec's ID syntax and one ID per quantity; the IDs reach the program through
`encodeIds`, and the answer is `hostSpec`, so code 2 means two requests share an
ID string. -/
def allocateBatchHostContract : WordContract where
  Args := HostArgs
  pre a := a.ids.length = a.qs.length ∧ ∀ s ∈ a.ids, ValidId s
  input a := batchIn a.available a.whole (encodeIds a.ids) a.qs []
  output a := batchOut (hostSpec a.available a.whole a.ids a.qs).1
    (hostSpec a.available a.whole a.ids a.qs).2.1 (hostSpec a.available a.whole a.ids a.qs).2.2.1
    (hostSpec a.available a.whole a.ids a.qs).2.2.2 []
  steps a := batchSteps a.qs.length
  cost a := batchCost a.qs.length
  witness := ⟨⟨0, false, [], []⟩, rfl, fun _ h => nomatch h⟩

/-- The recorded contract of `allocate-batch` on ID strings, under the i64
registry. -/
theorem allocate_batch_host_contract :
    allocateBatchHostContract.Holds int64Gamma dictionary defaultCosts «allocate-batch».body := by
  intro a tail hPre
  have e := batchSpec_encodeIds (available := a.available) (whole := a.whole) hPre.1 hPre.2
  have hRun := allocate_batch a.available a.whole (encodeIds a.ids) a.qs tail
    (by rw [encodeIds_length, hPre.1]) (encodeIds_idParts hPre.2)
  rw [e] at hRun
  exact hRun

/-! ## Attaching IDs to the answer -/

/-- The spec's reason names, by code. -/
def reasonName : Int → Option String
  | 0 => some "fulfilled"
  | 1 => some "partial"
  | 2 => some "out-of-stock"
  | 3 => some "insufficient-stock"
  | _ => none

/-- The spec's error names, by code. -/
def errorName : Int → Option String
  | 1 => some "invalid-range"
  | 2 => some "duplicate-id"
  | _ => none

/-- One request's line of the answer. -/
structure Allocation where
  id : String
  quantity : Int
  reason : String
  deriving DecidableEq, Repr

/-- The host's answer: an error name, or the stock left and one line per
request. -/
inductive Answer where
  | error (code : String)
  | ok (remaining : Int) (allocations : List Allocation)
  deriving DecidableEq, Repr

/-- Each request's line, by position: the `i`th ID with the `i`th quantity and
reason. `none` when the lengths differ or a reason code is unknown. -/
def attach : List String → List Int → List Int → Option (List Allocation)
  | [], [], [] => some []
  | id :: ids, q :: qs, r :: rs => do
    let name ← reasonName r
    let rest ← attach ids qs rs
    pure (⟨id, q, name⟩ :: rest)
  | _, _, _ => none

/-- The component's answer, turned into the host's. `none` when the component
returned something the spec does not allow. -/
def hostEncode (ids : List String) (code remaining : Int) (allocated reasons : List Int) :
    Option Answer :=
  if code = 0 then (attach ids allocated reasons).map (Answer.ok remaining)
  else (errorName code).map Answer.error

theorem attach_ok : ∀ {ids : List String} {qs rs : List Int} {lines : List Allocation},
    attach ids qs rs = some lines →
    lines.map (·.id) = ids ∧ lines.map (·.quantity) = qs ∧
    lines.map (some ·.reason) = rs.map reasonName
  | [], [], [], lines, h => by simp [attach] at h; subst h; simp
  | id :: ids, q :: qs, r :: rs, lines, h => by
    simp only [attach] at h
    cases hn : reasonName r with
    | none => simp [hn] at h
    | some name =>
      cases hr : attach ids qs rs with
      | none => simp [hn, hr] at h
      | some rest =>
        simp [hn, hr] at h
        subst h
        obtain ⟨h1, h2, h3⟩ := attach_ok hr
        simp [h1, h2, h3, hn]
  | [], [], _ :: _, _, h | [], _ :: _, _, _, h | _ :: _, [], _, _, h
  | _ :: _, _ :: _, [], _, h => by simp [attach] at h

/-- When the component succeeds, the answer lists the request IDs in request
order, each with its own allocated quantity and the name of its own reason. -/
theorem hostEncode_ok {ids : List String} {remaining : Int} {allocated reasons : List Int}
    {left : Int} {lines : List Allocation}
    (h : hostEncode ids 0 remaining allocated reasons = some (.ok left lines)) :
    left = remaining ∧ lines.map (·.id) = ids ∧ lines.map (·.quantity) = allocated ∧
    lines.map (some ·.reason) = reasons.map reasonName := by
  simp only [hostEncode, if_true] at h
  cases ha : attach ids allocated reasons with
  | none => simp [ha] at h
  | some ls =>
    simp only [ha, Option.map_some, Option.some.injEq, Answer.ok.injEq] at h
    obtain ⟨rfl, rfl⟩ := h
    exact ⟨rfl, attach_ok ha⟩

/-- An answer is never invented: a failing component code is reported by its
name, and only the spec's two codes are. -/
theorem hostEncode_error {ids : List String} {code remaining : Int} {allocated reasons : List Int}
    {name : String} (h : hostEncode ids code remaining allocated reasons = some (.error name)) :
    code ≠ 0 ∧ errorName code = some name := by
  unfold hostEncode at h
  by_cases hc : code = 0
  · rw [if_pos hc] at h
    cases (attach ids allocated reasons) <;> simp at h
  · rw [if_neg hc] at h
    refine ⟨hc, ?_⟩
    cases hn : errorName code <;> simp [hn] at h
    subst h; rfl

end Firth.Proofs.Inventory.Host
