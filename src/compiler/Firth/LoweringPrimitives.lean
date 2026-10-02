import compiler.Firth.LoweringCorrect

/-!
Every surface primitive the compiler lowers does on the target what it does in
the reference interpreter under `int64Gamma`.

`prim_agree` covers the 23 primitives of `Interpreter.surfacePrimitives`. On
related stacks, a primitive the interpreter runs to a result runs on the target
to a related result, and one the interpreter faults on faults on the target
(by a failed operand check or a primitive fault). The single exception is
`seq-int.len` or `seq-bool.len` of a sequence with 2^63 or more elements: the
interpreter returns its length, which is not an `i64`, and the target faults
(`LenOverflow`).

The `len` cases rewrite with `int64Result_in` and `int64Result_out` rather than
unfolding `int64Result`: unfolding it leaves the kernel to decide `isInt64` of
a symbolic length against the 2^63 bounds, which recurses too deeply.

Part of step 3 of `todo.compiler-vm-agreement-proof`.
-/

set_option linter.unusedSimpArgs false

namespace Firth.Compiler.LoweringCorrect
open Firth.Compiler Firth.Compiler.Lowering Firth.Compiler.TargetSemantics
theorem pow63 : (2 : Int) ^ 63 = 9223372036854775808 := by rfl
theorem isInt64_iff (n : Int) : Target.isInt64 n = true ↔ Firth.Logic.InInt64 n := by
  simp only [Target.isInt64, Firth.Logic.InInt64, Bool.and_eq_true, decide_eq_true_eq, pow63]
  omega
def sprim (name : String) (s : List SValue) : Option (List SValue) :=
  (Firth.Logic.int64Gamma.primitive name).bind fun spec => spec.delta s
def tprim (k : String) (s : List TValue) : Option (List TValue) :=
  match validate (.prim k) s [] [] with
  | some _ => none
  | none => primitiveDelta k s
def LenOverflow (name : String) (s : List SValue) : Prop :=
  (name = "seq-int.len" ∧ ∃ xs rest, s = .literal (.intSeq xs) :: rest ∧ ¬ Firth.Logic.InInt64 xs.length) ∨
  (name = "seq-bool.len" ∧ ∃ bs rest, s = .literal (.boolSeq bs) :: rest ∧ ¬ Firth.Logic.InInt64 bs.length)
def PrimAgree (M : List (String × String)) (name k : String) (s : List SValue) (s' : List TValue) : Prop :=
  (∀ r, sprim name s = some r →
    (∃ r', tprim k s' = some r' ∧ ListRel (ValRel M) r r') ∨ (tprim k s' = none ∧ LenOverflow name s)) ∧
  (sprim name s = none → tprim k s' = none)

theorem listRel_cons_cons {α β} {R : α → β → Prop} {a as b bs} :
    ListRel R (a :: as) (b :: bs) ↔ R a b ∧ ListRel R as bs :=
  ⟨fun h => by cases h; exact ⟨by assumption, by assumption⟩, fun ⟨h1, h2⟩ => .cons h1 h2⟩
theorem valRel_int {M n t} : ValRel M (.literal (.int n)) t ↔ t = .int n ∧ Firth.Logic.InInt64 n := by
  constructor
  · intro h; cases h; exact ⟨rfl, (isInt64_iff n).mp (by assumption)⟩
  · rintro ⟨rfl, h⟩; exact .int ((isInt64_iff n).mpr h)
theorem valRel_bool {M b t} : ValRel M (.literal (.bool b)) t ↔ t = .bool b := by
  constructor
  · intro h; cases h; rfl
  · rintro rfl; exact .bool
theorem self_imp_or (p q : Prop) : (p → p ∨ q) ↔ True := ⟨fun _ => trivial, fun _ h => .inl h⟩
theorem len1 (n : Nat) : (n + 1 < 1) ↔ False := ⟨fun h => by omega, False.elim⟩
theorem len2 (n : Nat) : (n + 1 + 1 < 2) ↔ False := ⟨fun h => by omega, False.elim⟩
theorem len3 (n : Nat) : (n + 1 + 1 + 1 < 3) ↔ False := ⟨fun h => by omega, False.elim⟩

theorem emod_in {l r : Int} (hr : Firth.Logic.InInt64 r) (h0 : r ≠ 0) :
    Firth.Logic.InInt64 (l % r) := by
  unfold Firth.Logic.InInt64 at *
  have h1 := Int.emod_nonneg l h0
  have h2 := Int.emod_lt l h0
  omega
theorem valRel_intSeq {M xs t} : ValRel M (.literal (.intSeq xs)) t ↔
    t = .primitiveValue Target.seqIntTag (Target.seqIntBytes xs) ∧ xs.all Target.isInt64 = true := by
  constructor
  · intro h; cases h; exact ⟨rfl, by assumption⟩
  · rintro ⟨rfl, h⟩; exact .intSeq h
theorem valRel_boolSeq {M bs t} : ValRel M (.literal (.boolSeq bs)) t ↔
    t = .primitiveValue Target.seqBoolTag (Target.seqBoolBytes bs) := by
  constructor
  · intro h; cases h; rfl
  · rintro rfl; exact .boolSeq
theorem elementAt_eq {α} (xs : List α) (i : Int) : elementAt xs i = Firth.Interpreter.elementAt? xs i := by
  cases i <;> simp [elementAt, Firth.Interpreter.elementAt?] <;> omega
theorem replaceAt_eq {α} (xs : List α) (i : Int) (v : α) :
    replaceAt xs i v = Firth.Interpreter.replaceAt? xs i v := by
  cases i with
  | ofNat n =>
      simp only [replaceAt, Firth.Interpreter.replaceAt?]
      by_cases h : n < xs.length
      · rw [if_pos h, if_neg (by simp; omega)]; rfl
      · rw [if_neg h, if_pos (by simp; omega)]
  | negSucc n => simp [replaceAt, Firth.Interpreter.replaceAt?]

theorem all_of_elementAt {α} {p : α → Bool} {xs : List α} {i : Int} {a : α}
    (h : xs.all p = true) (ha : Firth.Interpreter.elementAt? xs i = some a) : p a = true := by
  cases i with
  | ofNat n => exact List.all_eq_true.mp h a (List.mem_of_getElem? ha)
  | negSucc _ => cases ha
theorem tag_int_bool : (Target.seqIntTag == Target.seqBoolTag) = false := rfl
theorem tag_bool_int : (Target.seqBoolTag == Target.seqIntTag) = false := rfl
theorem all_of_replaceAt {α} {p : α → Bool} {xs ys : List α} {i : Int} {a : α}
    (h : xs.all p = true) (ha : p a = true) (hr : Firth.Interpreter.replaceAt? xs i a = some ys) :
    ys.all p = true := by
  cases i with
  | ofNat n =>
      simp only [Firth.Interpreter.replaceAt?] at hr
      split at hr
      · cases hr
        rw [List.all_eq_true] at h ⊢
        intro x hx
        rcases List.mem_or_eq_of_mem_set hx with hx | rfl
        · exact h x hx
        · exact ha
      · cases hr
  | negSucc _ => cases hr

theorem seqOp_pv {f : ByteArray → List TValue → Option (List TValue)} {t b r} :
    seqOp f (.primitiveValue t b :: r) = f b r := by rw [seqOp.eq_1]
theorem int64Result_in {v : Int} {r} (h : Target.isInt64 v = true) : int64Result v r = some (.int v :: r) := by
  rw [int64Result, if_pos h]
theorem int64Result_out {v : Int} {r} (h : Target.isInt64 v = false) : int64Result v r = none := by
  rw [int64Result, if_neg (by rw [h]; decide)]

theorem sprim_add (s : List SValue) : sprim "+" s = Firth.Logic.checkedIntDelta (· + ·) s := by rfl
theorem in_add : primitiveInputs "addInt" = some [.int, .int] := rfl
theorem pd_add (s : List TValue) : primitiveDelta "addInt" s = intOp (fun l r rest => int64Result (l + r) rest) s := rfl
theorem agree_add {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "+" "addInt" s s' := by
  unfold PrimAgree; rw [sprim_add]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_add, pd_add, hasKind, Firth.Logic.checkedIntDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_sub (s : List SValue) : sprim "-" s = Firth.Logic.checkedIntDelta (· - ·) s := by rfl
theorem in_sub : primitiveInputs "subInt" = some [.int, .int] := rfl
theorem pd_sub (s : List TValue) : primitiveDelta "subInt" s = intOp (fun l r rest => int64Result (l - r) rest) s := rfl
theorem agree_sub {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "-" "subInt" s s' := by
  unfold PrimAgree; rw [sprim_sub]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_sub, pd_sub, hasKind, Firth.Logic.checkedIntDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_mul (s : List SValue) : sprim "*" s = Firth.Logic.checkedIntDelta (· * ·) s := by rfl
theorem in_mul : primitiveInputs "mulInt" = some [.int, .int] := rfl
theorem pd_mul (s : List TValue) : primitiveDelta "mulInt" s = intOp (fun l r rest => int64Result (l * r) rest) s := rfl
theorem agree_mul {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "*" "mulInt" s s' := by
  unfold PrimAgree; rw [sprim_mul]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_mul, pd_mul, hasKind, Firth.Logic.checkedIntDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_div (s : List SValue) : sprim "div" s = Firth.Logic.checkedDivDelta s := by rfl
theorem in_div : primitiveInputs "divInt" = some [.int, .int] := rfl
theorem pd_div (s : List TValue) : primitiveDelta "divInt" s = intOp (fun l r rest => if r = 0 then none else int64Result (l / r) rest) s := rfl
theorem agree_div {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "div" "divInt" s s' := by
  unfold PrimAgree; rw [sprim_div]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_div, pd_div, hasKind, Firth.Logic.checkedDivDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *] <;>
    (try split) <;> simp_all [isInt64_iff]

theorem sprim_mod (s : List SValue) : sprim "mod" s = Firth.Interpreter.modIntDelta s := by rfl
theorem in_mod : primitiveInputs "modInt" = some [.int, .int] := rfl
theorem pd_mod (s : List TValue) : primitiveDelta "modInt" s = intOp (fun l r rest => if r = 0 then none else int64Result (l % r) rest) s := rfl
theorem agree_mod {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "mod" "modInt" s s' := by
  unfold PrimAgree; rw [sprim_mod]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_mod, pd_mod, hasKind, Firth.Interpreter.modIntDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *] <;>
    (try split) <;> simp_all [isInt64_iff, emod_in]

theorem sprim_lt (s : List SValue) : sprim "<" s = Firth.Interpreter.ltIntDelta s := by rfl
theorem in_lt : primitiveInputs "ltInt" = some [.int, .int] := rfl
theorem pd_lt (s : List TValue) : primitiveDelta "ltInt" s = intOp (fun l r rest => some (.bool (decide (l < r)) :: rest)) s := rfl
theorem agree_lt {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "<" "ltInt" s s' := by
  unfold PrimAgree; rw [sprim_lt]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_lt, pd_lt, hasKind, Firth.Interpreter.ltIntDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_eq (s : List SValue) : sprim "=" s = Firth.Interpreter.eqIntDelta s := by rfl
theorem in_eq : primitiveInputs "eqInt" = some [.int, .int] := rfl
theorem pd_eq (s : List TValue) : primitiveDelta "eqInt" s = intOp (fun l r rest => some (.bool (decide (l = r)) :: rest)) s := rfl
theorem agree_eq {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "=" "eqInt" s s' := by
  unfold PrimAgree; rw [sprim_eq]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_eq, pd_eq, hasKind, Firth.Interpreter.eqIntDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_le (s : List SValue) : sprim "<=" s = Firth.Interpreter.leIntDelta s := by rfl
theorem in_le : primitiveInputs "leInt" = some [.int, .int] := rfl
theorem pd_le (s : List TValue) : primitiveDelta "leInt" s = intOp (fun l r rest => some (.bool (decide (l ≤ r)) :: rest)) s := rfl
theorem agree_le {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "<=" "leInt" s s' := by
  unfold PrimAgree; rw [sprim_le]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_le, pd_le, hasKind, Firth.Interpreter.leIntDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_gt (s : List SValue) : sprim ">" s = Firth.Interpreter.gtIntDelta s := by rfl
theorem in_gt : primitiveInputs "gtInt" = some [.int, .int] := rfl
theorem pd_gt (s : List TValue) : primitiveDelta "gtInt" s = intOp (fun l r rest => some (.bool (decide (r < l)) :: rest)) s := rfl
theorem agree_gt {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M ">" "gtInt" s s' := by
  unfold PrimAgree; rw [sprim_gt]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_gt, pd_gt, hasKind, Firth.Interpreter.gtIntDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_ge (s : List SValue) : sprim ">=" s = Firth.Interpreter.geIntDelta s := by rfl
theorem in_ge : primitiveInputs "geInt" = some [.int, .int] := rfl
theorem pd_ge (s : List TValue) : primitiveDelta "geInt" s = intOp (fun l r rest => some (.bool (decide (r ≤ l)) :: rest)) s := rfl
theorem agree_ge {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M ">=" "geInt" s s' := by
  unfold PrimAgree; rw [sprim_ge]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_ge, pd_ge, hasKind, Firth.Interpreter.geIntDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_and (s : List SValue) : sprim "and" s = Firth.Interpreter.andBoolDelta s := by rfl
theorem in_and : primitiveInputs "andBool" = some [.bool, .bool] := rfl
theorem pd_and (s : List TValue) : primitiveDelta "andBool" s = boolOp (fun l r rest => some (.bool (l && r) :: rest)) s := rfl
theorem agree_and {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "and" "andBool" s s' := by
  unfold PrimAgree; rw [sprim_and]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_and, pd_and, hasKind, Firth.Interpreter.andBoolDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_or (s : List SValue) : sprim "or" s = Firth.Interpreter.orBoolDelta s := by rfl
theorem in_or : primitiveInputs "orBool" = some [.bool, .bool] := rfl
theorem pd_or (s : List TValue) : primitiveDelta "orBool" s = boolOp (fun l r rest => some (.bool (l || r) :: rest)) s := rfl
theorem agree_or {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "or" "orBool" s s' := by
  unfold PrimAgree; rw [sprim_or]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_or, pd_or, hasKind, Firth.Interpreter.orBoolDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_not (s : List SValue) : sprim "not" s = Firth.Interpreter.notBoolDelta s := by rfl
theorem in_not : primitiveInputs "notBool" = some [.bool] := rfl
theorem pd_not (s : List TValue) : primitiveDelta "notBool" s = boolOp1 (fun v rest => some (.bool (!v) :: rest)) s := rfl
theorem agree_not {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "not" "notBool" s s' := by
  unfold PrimAgree; rw [sprim_not]
  rcases hs with _ | ⟨h1, hr⟩ <;>
    (try cases h1) <;>
    simp [tprim, validate, in_not, pd_not, hasKind, Firth.Interpreter.notBoolDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_iempty (s : List SValue) : sprim "seq-int.empty" s = Firth.Interpreter.intSeqEmptyDelta s := by rfl
theorem in_iempty : primitiveInputs "intSeqEmpty" = some [] := rfl
theorem pd_iempty (s : List TValue) : primitiveDelta "intSeqEmpty" s = (fun rest => some (intSeqValue [] :: rest)) s := rfl
theorem agree_iempty {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "seq-int.empty" "intSeqEmpty" s s' := by
  unfold PrimAgree; rw [sprim_iempty]
  simp [tprim, validate, in_iempty, pd_iempty, hasKind, Firth.Interpreter.intSeqEmptyDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_bempty (s : List SValue) : sprim "seq-bool.empty" s = Firth.Interpreter.boolSeqEmptyDelta s := by rfl
theorem in_bempty : primitiveInputs "boolSeqEmpty" = some [] := rfl
theorem pd_bempty (s : List TValue) : primitiveDelta "boolSeqEmpty" s = (fun rest => some (boolSeqValue [] :: rest)) s := rfl
theorem agree_bempty {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "seq-bool.empty" "boolSeqEmpty" s s' := by
  unfold PrimAgree; rw [sprim_bempty]
  simp [tprim, validate, in_bempty, pd_bempty, hasKind, Firth.Interpreter.boolSeqEmptyDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_iat (s : List SValue) : sprim "seq-int.at" s = Firth.Interpreter.intSeqAtDelta s := by rfl
theorem in_iat : primitiveInputs "intSeqAt" = some [.intSeq, .int] := rfl
theorem pd_iat (s : List TValue) : primitiveDelta "intSeqAt" s = seqIntOp (fun b i rest => (elementAt (decodeSeqInt b) i).map fun value => .int value :: rest) s := rfl
theorem agree_iat {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "seq-int.at" "intSeqAt" s s' := by
  unfold PrimAgree; rw [sprim_iat]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_iat, pd_iat, hasKind, Firth.Interpreter.intSeqAtDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]
  intro a ha
  exact .inl ⟨_, ⟨a, ha, rfl⟩, .cons (.int (all_of_elementAt ‹_› ha)) hr⟩

theorem sprim_bat (s : List SValue) : sprim "seq-bool.at" s = Firth.Interpreter.boolSeqAtDelta s := by rfl
theorem in_bat : primitiveInputs "boolSeqAt" = some [.boolSeq, .int] := rfl
theorem pd_bat (s : List TValue) : primitiveDelta "boolSeqAt" s = seqIntOp (fun b i rest => (elementAt (decodeSeqBool b) i).map fun value => .bool value :: rest) s := rfl
theorem agree_bat {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "seq-bool.at" "boolSeqAt" s s' := by
  unfold PrimAgree; rw [sprim_bat]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_bat, pd_bat, hasKind, Firth.Interpreter.boolSeqAtDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]
  intro r h
  rcases h with ⟨ha, rfl⟩ | ⟨ha, rfl⟩
  · exact .inl ⟨_, .inl ⟨ha, rfl⟩, .cons .bool hr⟩
  · exact .inl ⟨_, .inr ⟨ha, rfl⟩, .cons .bool hr⟩

theorem sprim_ipush (s : List SValue) : sprim "seq-int.push" s = Firth.Interpreter.intSeqPushDelta s := by rfl
theorem in_ipush : primitiveInputs "intSeqPush" = some [.intSeq, .int] := rfl
theorem pd_ipush (s : List TValue) : primitiveDelta "intSeqPush" s = seqIntOp (fun b v rest => some (intSeqValue (decodeSeqInt b ++ [v]) :: rest)) s := rfl
theorem agree_ipush {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "seq-int.push" "intSeqPush" s s' := by
  unfold PrimAgree; rw [sprim_ipush]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_ipush, pd_ipush, hasKind, Firth.Interpreter.intSeqPushDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_bpush (s : List SValue) : sprim "seq-bool.push" s = Firth.Interpreter.boolSeqPushDelta s := by rfl
theorem in_bpush : primitiveInputs "boolSeqPush" = some [.boolSeq, .bool] := rfl
theorem pd_bpush (s : List TValue) : primitiveDelta "boolSeqPush" s = seqBoolOp (fun b v rest => some (boolSeqValue (decodeSeqBool b ++ [v]) :: rest)) s := rfl
theorem agree_bpush {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "seq-bool.push" "boolSeqPush" s s' := by
  unfold PrimAgree; rw [sprim_bpush]
  rcases hs with _ | ⟨h1, _ | ⟨h2, hr⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;>
    simp [tprim, validate, in_bpush, pd_bpush, hasKind, Firth.Interpreter.boolSeqPushDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]

theorem sprim_iset (s : List SValue) : sprim "seq-int.set" s = Firth.Interpreter.intSeqSetDelta s := by rfl
theorem in_iset : primitiveInputs "intSeqSet" = some [.intSeq, .int, .int] := rfl
theorem pd_iset (s : List TValue) : primitiveDelta "intSeqSet" s = seqSetIntOp (fun b i v rest => (replaceAt (decodeSeqInt b) i v).map fun values => intSeqValue values :: rest) s := rfl
theorem agree_iset {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "seq-int.set" "intSeqSet" s s' := by
  unfold PrimAgree; rw [sprim_iset]
  rcases hs with _ | ⟨h1, _ | ⟨h2, _ | ⟨h3, hr⟩⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;> (try cases h3) <;>
    simp [tprim, validate, in_iset, pd_iset, hasKind, Firth.Interpreter.intSeqSetDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]
  intro a ha
  exact .inl ⟨_, ⟨a, ha, rfl⟩, .cons (.intSeq (all_of_replaceAt ‹_› ‹_› ha)) hr⟩

theorem sprim_bset (s : List SValue) : sprim "seq-bool.set" s = Firth.Interpreter.boolSeqSetDelta s := by rfl
theorem in_bset : primitiveInputs "boolSeqSet" = some [.boolSeq, .int, .bool] := rfl
theorem pd_bset (s : List TValue) : primitiveDelta "boolSeqSet" s = seqSetBoolOp (fun b i v rest => (replaceAt (decodeSeqBool b) i v).map fun values => boolSeqValue values :: rest) s := rfl
theorem agree_bset {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "seq-bool.set" "boolSeqSet" s s' := by
  unfold PrimAgree; rw [sprim_bset]
  rcases hs with _ | ⟨h1, _ | ⟨h2, _ | ⟨h3, hr⟩⟩⟩ <;>
    (try cases h1) <;> (try cases h2) <;> (try cases h3) <;>
    simp [tprim, validate, in_bset, pd_bset, hasKind, Firth.Interpreter.boolSeqSetDelta,
      listRel_cons_cons, isInt64_iff, valRel_int, valRel_bool, valRel_intSeq, valRel_boolSeq, self_imp_or, len1, len2, len3, and_assoc, exists_and_left, tag_int_bool, tag_bool_int, decodeSeqInt_encode, decodeSeqBool_encode, elementAt_eq, replaceAt_eq, List.all_append, intOp, boolOp, boolOp1, seqOp, seqIntOp, seqBoolOp, seqSetIntOp, seqSetBoolOp, int64Result, intSeqValue, boolSeqValue, *]
  intro a ha
  exact .inl ⟨_, ⟨a, ha, rfl⟩, .cons .boolSeq hr⟩

theorem sprim_ilen (s : List SValue) : sprim "seq-int.len" s = Firth.Interpreter.intSeqLenDelta s := by rfl
theorem in_ilen : primitiveInputs "intSeqLen" = some [.intSeq] := rfl
theorem pd_ilen (s : List TValue) : primitiveDelta "intSeqLen" s = seqOp (fun b rest => int64Result (decodeSeqInt b).length rest) s := rfl
theorem agree_ilen {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "seq-int.len" "intSeqLen" s s' := by
  unfold PrimAgree; rw [sprim_ilen]
  rcases hs with _ | ⟨h1, hr⟩
  · simp [tprim, validate, in_ilen, Firth.Interpreter.intSeqLenDelta]
  · cases h1 with
    | intSeq hall =>
        rename_i as bs xs
        refine ⟨?_, fun h => by simp [Firth.Interpreter.intSeqLenDelta] at h⟩
        simp only [Firth.Interpreter.intSeqLenDelta, Option.some.injEq, forall_eq']
        have hv : validate (.prim "intSeqLen")
            (.primitiveValue Target.seqIntTag (Target.seqIntBytes xs) :: bs) [] [] = none := by
          simp [validate, in_ilen, hasKind]
        cases hlen : Target.isInt64 (xs.length : Int)
        · refine .inr ⟨?_, .inl ⟨rfl, xs, _, rfl, fun h => by rw [(isInt64_iff _).mpr h] at hlen; cases hlen⟩⟩
          rw [tprim, hv]
          simp only
          rw [pd_ilen, seqOp_pv, decodeSeqInt_encode _ hall, int64Result_out hlen]
        · refine .inl ⟨_, ?_, .cons (.int hlen) hr⟩
          rw [tprim, hv]
          simp only
          rw [pd_ilen, seqOp_pv, decodeSeqInt_encode _ hall, int64Result_in hlen]
    | _ => simp [tprim, validate, in_ilen, hasKind, Firth.Interpreter.intSeqLenDelta, tag_bool_int]

theorem sprim_blen (s : List SValue) : sprim "seq-bool.len" s = Firth.Interpreter.boolSeqLenDelta s := by rfl
theorem in_blen : primitiveInputs "boolSeqLen" = some [.boolSeq] := rfl
theorem pd_blen (s : List TValue) : primitiveDelta "boolSeqLen" s = seqOp (fun b rest => int64Result (decodeSeqBool b).length rest) s := rfl
theorem agree_blen {M s s'} (hs : ListRel (ValRel M) s s') : PrimAgree M "seq-bool.len" "boolSeqLen" s s' := by
  unfold PrimAgree; rw [sprim_blen]
  rcases hs with _ | ⟨h1, hr⟩
  · simp [tprim, validate, in_blen, Firth.Interpreter.boolSeqLenDelta]
  · cases h1 with
    | boolSeq =>
        rename_i as bs xs
        refine ⟨?_, fun h => by simp [Firth.Interpreter.boolSeqLenDelta] at h⟩
        simp only [Firth.Interpreter.boolSeqLenDelta, Option.some.injEq, forall_eq']
        have hv : validate (.prim "boolSeqLen")
            (.primitiveValue Target.seqBoolTag (Target.seqBoolBytes xs) :: bs) [] [] = none := by
          simp [validate, in_blen, hasKind]
        cases hlen : Target.isInt64 (xs.length : Int)
        · refine .inr ⟨?_, .inr ⟨rfl, xs, _, rfl, fun h => by rw [(isInt64_iff _).mpr h] at hlen; cases hlen⟩⟩
          rw [tprim, hv]
          simp only
          rw [pd_blen, seqOp_pv, decodeSeqBool_encode xs, int64Result_out hlen]
        · refine .inl ⟨_, ?_, .cons (.int hlen) hr⟩
          rw [tprim, hv]
          simp only
          rw [pd_blen, seqOp_pv, decodeSeqBool_encode xs, int64Result_in hlen]
    | _ => simp [tprim, validate, in_blen, hasKind, Firth.Interpreter.boolSeqLenDelta, tag_int_bool]

theorem prim_agree {M name k s s'} (hk : Firth.Interpreter.kernelPrimitive name = some k)
    (hs : ListRel (ValRel M) s s') : PrimAgree M name k s s' := by
  have hm := kernelPrimitive_mem hk
  simp only [Firth.Interpreter.surfacePrimitives, List.mem_cons, Prod.mk.injEq, List.not_mem_nil,
    or_false] at hm
  rcases hm with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ |
    ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ |
    ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ |
    ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
  · exact agree_add hs
  · exact agree_sub hs
  · exact agree_mul hs
  · exact agree_lt hs
  · exact agree_eq hs
  · exact agree_le hs
  · exact agree_gt hs
  · exact agree_ge hs
  · exact agree_div hs
  · exact agree_mod hs
  · exact agree_and hs
  · exact agree_or hs
  · exact agree_not hs
  · exact agree_iempty hs
  · exact agree_ilen hs
  · exact agree_iat hs
  · exact agree_ipush hs
  · exact agree_iset hs
  · exact agree_bempty hs
  · exact agree_blen hs
  · exact agree_bat hs
  · exact agree_bpush hs
  · exact agree_bset hs

end Firth.Compiler.LoweringCorrect
