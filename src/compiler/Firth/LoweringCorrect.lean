import Firth.ProgramLogic
import compiler.Firth.LoweringFacts
import compiler.Firth.TargetSemantics

/-!
The compiler's lowering is correct against the target semantics.

Part of step 3 of `todo.compiler-vm-agreement-proof`; the simulation theorems are in
`LoweringSimulation.lean`.

## Relations

`ValRel M v t` relates a reference value `v` to the target value `t` that
represents it, and `CodeRel M caps code p` relates target code `code`, running
with capture slots `caps`, to the reference program `p` it stands for. `M` is
the dictionary's name map. Both follow the lowering table of
`target-spec.md` §3 and are defined independently of `Lowering.lean`: that
`lowerProgram` emits related code is a theorem below, so a lowering rule that
departs from the table breaks the build.
-/

namespace Firth.Compiler.LoweringCorrect

open Firth.Compiler Firth.Compiler.Lowering
open Firth.Compiler.TargetSemantics (linearValue linearValues)

abbrev SValue := Firth.Interpreter.Value
abbrev SProgram := Firth.Interpreter.Program
abbrev TValue := Firth.Compiler.Target.Value
abbrev TCode := List Firth.Compiler.Target.Instruction

/-- Every capture slot of a quotation that has not run starts unconsumed. -/
def fresh (captures : List TValue) : List Bool := captures.map fun _ => false

mutual
inductive ValRel (M : List (String × String)) : SValue → TValue → Prop
  | int {n : Int} : Target.isInt64 n = true → ValRel M (.literal (.int n)) (.int n)
  | bool {b : Bool} : ValRel M (.literal (.bool b)) (.bool b)
  | intSeq {xs : List Int} : xs.all Target.isInt64 = true →
      ValRel M (.literal (.intSeq xs)) (.primitiveValue Target.seqIntTag (Target.seqIntBytes xs))
  | boolSeq {bs : List Bool} :
      ValRel M (.literal (.boolSeq bs)) (.primitiveValue Target.seqBoolTag (Target.seqBoolBytes bs))
  | quotation {body : SProgram} {code : TCode} {caps : List TValue} :
      CodeRel M caps code body → linearValues caps = false →
      ValRel M (.quotation body .many) (.quotation code caps (fresh caps))

inductive CodeRel (M : List (String × String)) : List TValue → TCode → SProgram → Prop
  | nil {caps} : CodeRel M caps [] .empty
  | lit {caps l v c p} : ValRel M (.literal l) v → CodeRel M caps c p →
      CodeRel M caps (.pushLiteral v :: c) (.cons (.lit l) p)
  | quotation {caps qc body c p} : CodeRel M [] qc body → CodeRel M caps c p →
      CodeRel M caps (.pushQuote qc [] [] :: c) (.cons (.quotation body) p)
  | capture {caps i t v c p} : caps[i]? = some t → ValRel M v t → CodeRel M caps c p →
      CodeRel M caps (.pushCapture i :: c) (.cons (.push v) p)
  | dup {caps c p} : CodeRel M caps c p → CodeRel M caps (.dup :: c) (.cons .dup p)
  | drop {caps c p} : CodeRel M caps c p → CodeRel M caps (.drop :: c) (.cons .drop p)
  | swap {caps c p} : CodeRel M caps c p → CodeRel M caps (.swap :: c) (.cons .swap p)
  | pick {caps n c p} : CodeRel M caps c p → CodeRel M caps (.pick n :: c) (.cons (.pick n) p)
  | roll {caps n c p} : CodeRel M caps c p → CodeRel M caps (.roll n :: c) (.cons (.roll n) p)
  | dip {caps c p} : CodeRel M caps c p → CodeRel M caps (.dip :: c) (.cons .dip p)
  | call {caps c p} : CodeRel M caps c p → CodeRel M caps (.call :: c) (.cons .call p)
  | compose {caps c p} : CodeRel M caps c p → CodeRel M caps (.compose :: c) (.cons .compose p)
  | quote {caps c p} : CodeRel M caps c p → CodeRel M caps (.quote :: c) (.cons .quote p)
  | ifThenElse {caps c p} : CodeRel M caps c p →
      CodeRel M caps (.ifThenElse :: c) (.cons .ifThenElse p)
  | word {caps name entry c p} : M.find? (fun e => e.1 == name) = some entry →
      CodeRel M caps c p → CodeRel M caps (.callWord entry.2 :: c) (.cons (.word name) p)
  | prim {caps name kernel c p} : Firth.Interpreter.kernelPrimitive name = some kernel →
      CodeRel M caps c p → CodeRel M caps (.prim kernel :: c) (.cons (.prim name) p)
end

/-! ## Structural facts -/

theorem ValRel.not_linear {M} {v : SValue} {t : TValue} (h : ValRel M v t) : linearValue t = false := by
  cases h <;> simp_all [linearValue, Target.seqIntTag, Target.seqBoolTag]

theorem linearValues_append {a b : List TValue} :
    linearValues (a ++ b) = (linearValues a || linearValues b) := by
  induction a with
  | nil => simp [linearValues]
  | cons x xs ih => simp [linearValues, ih, Bool.or_assoc]

theorem CodeRel.append {M caps} :
    ∀ {c₁ p₁ c₂ p₂}, CodeRel M caps c₁ p₁ → CodeRel M caps c₂ p₂ →
      CodeRel M caps (c₁ ++ c₂) (p₁.append p₂)
  | _, _, _, _, .nil, h₂ => h₂
  | _, _, _, _, .lit hv h, h₂ => .lit hv (h.append h₂)
  | _, _, _, _, .quotation hq h, h₂ => .quotation hq (h.append h₂)
  | _, _, _, _, .capture hi hv h, h₂ => .capture hi hv (h.append h₂)
  | _, _, _, _, .dup h, h₂ => .dup (h.append h₂)
  | _, _, _, _, .drop h, h₂ => .drop (h.append h₂)
  | _, _, _, _, .swap h, h₂ => .swap (h.append h₂)
  | _, _, _, _, .pick h, h₂ => .pick (h.append h₂)
  | _, _, _, _, .roll h, h₂ => .roll (h.append h₂)
  | _, _, _, _, .dip h, h₂ => .dip (h.append h₂)
  | _, _, _, _, .call h, h₂ => .call (h.append h₂)
  | _, _, _, _, .compose h, h₂ => .compose (h.append h₂)
  | _, _, _, _, .quote h, h₂ => .quote (h.append h₂)
  | _, _, _, _, .ifThenElse h, h₂ => .ifThenElse (h.append h₂)
  | _, _, _, _, .word hf h, h₂ => .word hf (h.append h₂)
  | _, _, _, _, .prim hk h, h₂ => .prim hk (h.append h₂)

/-- Code keeps its meaning when more capture slots follow its own. -/
theorem CodeRel.extend {M caps more} :
    ∀ {c p}, CodeRel M caps c p → CodeRel M (caps ++ more) c p
  | _, _, .nil => .nil
  | _, _, .lit hv h => .lit hv h.extend
  | _, _, .quotation hq h => .quotation hq h.extend
  | _, _, .capture hi hv h => .capture (by rw [List.getElem?_append_left (List.getElem?_eq_some_iff.mp hi).1]; exact hi) hv h.extend
  | _, _, .dup h => .dup h.extend
  | _, _, .drop h => .drop h.extend
  | _, _, .swap h => .swap h.extend
  | _, _, .pick h => .pick h.extend
  | _, _, .roll h => .roll h.extend
  | _, _, .dip h => .dip h.extend
  | _, _, .call h => .call h.extend
  | _, _, .compose h => .compose h.extend
  | _, _, .quote h => .quote h.extend
  | _, _, .ifThenElse h => .ifThenElse h.extend
  | _, _, .word hf h => .word hf h.extend
  | _, _, .prim hk h => .prim hk h.extend

/-- Code keeps its meaning when its capture slots move after `before`, if its
capture indices move with them, as `COMPOSE` moves its right half. -/
theorem CodeRel.rebase {M caps before} :
    ∀ {c p}, CodeRel M caps c p →
      CodeRel M (before ++ caps) (TargetSemantics.rebase before.length c) p
  | _, _, .nil => .nil
  | _, _, .lit hv h => .lit hv h.rebase
  | _, _, .quotation hq h => .quotation hq h.rebase
  | _, _, .capture hi hv h => by
      refine .capture ?_ hv h.rebase
      rw [List.getElem?_append_right (by omega)]
      simpa [Nat.add_sub_cancel] using hi
  | _, _, .dup h => .dup h.rebase
  | _, _, .drop h => .drop h.rebase
  | _, _, .swap h => .swap h.rebase
  | _, _, .pick h => .pick h.rebase
  | _, _, .roll h => .roll h.rebase
  | _, _, .dip h => .dip h.rebase
  | _, _, .call h => .call h.rebase
  | _, _, .compose h => .compose h.rebase
  | _, _, .quote h => .quote h.rebase
  | _, _, .ifThenElse h => .ifThenElse h.rebase
  | _, _, .word hf h => .word hf h.rebase
  | _, _, .prim hk h => .prim hk h.rebase

/-! ## The lowering emits related code -/

theorem lowerLiteral_rel {M : List (String × String)} {context : Context}
    {l : Firth.Interpreter.Literal} {v : TValue}
    (h : lowerLiteral context l = .ok v) : ValRel M (.literal l) v := by
  cases l with
  | int n =>
      simp only [lowerLiteral] at h
      split at h
      · cases h; exact .int (by assumption)
      · cases h
  | bool b => cases h; exact .bool
  | unit => cases h
  | intSeq xs =>
      simp only [lowerLiteral] at h
      split at h
      · cases h
      · rename_i hnone
        cases h
        refine .intSeq ?_
        rw [List.all_eq_true]
        intro x hx
        have := List.find?_eq_none.mp hnone x hx
        simpa using this
  | boolSeq bs => cases h; exact .boolSeq

theorem resolveWord_rel {context : Context} {name target : String}
    (h : resolveWord context name = .ok target) :
    ∃ entry, context.words.find? (fun e => e.1 == name) = some entry ∧ entry.2 = target := by
  unfold resolveWord at h
  split at h
  · rename_i entry hentry
    cases h
    exact ⟨entry, hentry, rfl⟩
  · cases h

theorem targetPrimitive_rel {name target : String}
    (h : targetPrimitive name = some (some target)) :
    Firth.Interpreter.kernelPrimitive name = some target := by
  unfold targetPrimitive at h
  split at h
  · rename_i kernel hkernel
    cases h
    exact hkernel
  · split at h <;> cases h

mutual
theorem lowerProgram_rel {M : List (String × String)} {context : Context} (hM : context.words = M) :
    ∀ (p : SProgram) (c : TCode), lowerProgram context p = .ok c →
      ∀ caps, CodeRel M caps c p
  | .empty, c, h, _ => by
      simp only [lowerProgram, Except.ok.injEq] at h
      subst h
      exact .nil
  | .cons atom rest, c, h, caps => by
      simp only [lowerProgram, bind, Except.bind] at h
      split at h
      · cases h
      · rename_i first hfirst
        split at h
        · cases h
        · rename_i tail htail
          simp only [pure, Except.pure, Except.ok.injEq] at h
          subst h
          exact lowerAtom_rel hM atom first hfirst caps tail rest
            (lowerProgram_rel hM rest tail htail caps)

theorem lowerAtom_rel {M : List (String × String)} {context : Context} (hM : context.words = M) :
    ∀ (atom : Firth.Interpreter.Atom) (is : TCode), lowerAtom context atom = .ok is →
      ∀ caps c p, CodeRel M caps c p → CodeRel M caps (is ++ c) (.cons atom p)
  | .lit l, is, h, caps, c, p, hc => by
      simp only [lowerAtom, bind, Except.bind] at h
      split at h
      · cases h
      · rename_i v hv
        simp only [pure, Except.pure, Except.ok.injEq] at h
        subst h
        exact .lit (lowerLiteral_rel hv) hc
  | .push _, _, h, _, _, _, _ => by simp [lowerAtom] at h
  | .quotation body, is, h, caps, c, p, hc => by
      simp only [lowerAtom, bind, Except.bind] at h
      split at h
      · cases h
      · rename_i qc hqc
        simp only [pure, Except.pure, Except.ok.injEq] at h
        subst h
        exact .quotation (lowerProgram_rel hM body qc hqc []) hc
  | .dup, is, h, _, _, _, hc => by simp only [lowerAtom, Except.ok.injEq] at h; subst h; exact .dup hc
  | .drop, is, h, _, _, _, hc => by simp only [lowerAtom, Except.ok.injEq] at h; subst h; exact .drop hc
  | .swap, is, h, _, _, _, hc => by simp only [lowerAtom, Except.ok.injEq] at h; subst h; exact .swap hc
  | .pick _, is, h, _, _, _, hc => by simp only [lowerAtom, Except.ok.injEq] at h; subst h; exact .pick hc
  | .roll _, is, h, _, _, _, hc => by simp only [lowerAtom, Except.ok.injEq] at h; subst h; exact .roll hc
  | .dip, is, h, _, _, _, hc => by simp only [lowerAtom, Except.ok.injEq] at h; subst h; exact .dip hc
  | .call, is, h, _, _, _, hc => by simp only [lowerAtom, Except.ok.injEq] at h; subst h; exact .call hc
  | .compose, is, h, _, _, _, hc => by
      simp only [lowerAtom, Except.ok.injEq] at h; subst h; exact .compose hc
  | .quote, is, h, _, _, _, hc => by simp only [lowerAtom, Except.ok.injEq] at h; subst h; exact .quote hc
  | .ifThenElse, is, h, _, _, _, hc => by
      simp only [lowerAtom, Except.ok.injEq] at h; subst h; exact .ifThenElse hc
  | .word name, is, h, caps, c, p, hc => by
      simp only [lowerAtom, bind, Except.bind] at h
      split at h
      · cases h
      · rename_i target htarget
        simp only [pure, Except.pure, Except.ok.injEq] at h
        subst h
        obtain ⟨entry, hfind, rfl⟩ := resolveWord_rel htarget
        rw [hM] at hfind
        exact .word hfind hc
  | .prim name, is, h, caps, c, p, hc => by
      simp only [lowerAtom] at h
      split at h
      · cases h
      · cases h
      · rename_i target htarget
        cases h
        exact .prim (targetPrimitive_rel htarget) hc
end

/-! ## Sequence bytes

The semantics reads a sequence's elements back from its canonical bytes.
These lemmas say it reads back exactly what `seqIntBytes` and `seqBoolBytes`
wrote. -/

section Bytes
open Firth.Compiler.TargetSemantics

theorem byteFold (n : Nat) : ∀ w : Nat,
    ((List.range n).map (fun i => UInt8.ofNat ((w / 256 ^ i) % 256))).foldr
      (fun byte acc => byte.toNat + 256 * acc) 0 = w % 256 ^ n := by
  induction n with
  | zero => intro w; simp [Nat.mod_one]
  | succ n ih =>
      intro w
      rw [List.range_succ_eq_map]
      simp only [List.map_cons, List.map_map, List.foldr_cons]
      have hshift : (fun i => UInt8.ofNat ((w / 256 ^ i) % 256)) ∘ Nat.succ =
          (fun i => UInt8.ofNat ((w / 256 / 256 ^ i) % 256)) := by
        funext i
        simp [Nat.pow_succ, Nat.div_div_eq_div_mul, Nat.mul_comm]
      rw [hshift, ih (w / 256)]
      simp only [Nat.pow_zero, Nat.div_one]
      rw [Nat.pow_succ', Nat.mod_mul]
      congr 1
      simp [UInt8.toNat, UInt8.ofNat, BitVec.toNat_ofNat]

theorem int64OfBytes_encode (v : Int) (hv : Target.isInt64 v = true) :
    int64OfBytes ((List.range 8).map fun index =>
      UInt8.ofNat (((v % (2 ^ 64 : Int)).toNat / 256 ^ index) % 256)) = v := by
  unfold int64OfBytes
  simp only
  rw [byteFold]
  simp only [Target.isInt64, Bool.and_eq_true, decide_eq_true_eq] at hv
  have h0 : 0 ≤ v % (2 ^ 64 : Int) := Int.emod_nonneg _ (by decide)
  have hlt : v % (2 ^ 64 : Int) < 2 ^ 64 := Int.emod_lt_of_pos _ (by decide)
  have htoNat : (((v % (2 ^ 64 : Int)).toNat : Nat) : Int) = v % 2 ^ 64 := Int.toNat_of_nonneg h0
  have hw : (v % (2 ^ 64 : Int)).toNat < 256 ^ 8 := by omega
  rw [Nat.mod_eq_of_lt hw]
  split <;> omega

theorem seqIntElements_append :
    ∀ (word rest : List UInt8), word.length = 8 →
      seqIntElements (word ++ rest) = int64OfBytes word :: seqIntElements rest
  | [b0, b1, b2, b3, b4, b5, b6, b7], rest, _ => by simp [seqIntElements]

theorem decodeSeqInt_encode : ∀ (xs : List Int), xs.all Target.isInt64 = true →
    decodeSeqInt (Target.seqIntBytes xs) = xs
  | [], _ => by rfl
  | x :: xs, h => by
      simp only [List.all_cons, Bool.and_eq_true] at h
      have ih := decodeSeqInt_encode xs h.2
      unfold decodeSeqInt Target.seqIntBytes at *
      simp only [List.flatMap_cons] at *
      rw [seqIntElements_append _ _ (by simp), int64OfBytes_encode x h.1]
      simpa using ih

theorem decodeSeqBool_encode (bs : List Bool) : decodeSeqBool (Target.seqBoolBytes bs) = bs := by
  unfold decodeSeqBool Target.seqBoolBytes
  simp only [List.toList_toArray, List.map_map]
  conv => rhs; rw [← List.map_id bs]
  apply List.map_congr_left
  intro b _
  cases b <;> rfl

end Bytes

theorem kernelPrimitive_mem {name kernel : String}
    (h : Firth.Interpreter.kernelPrimitive name = some kernel) :
    (name, kernel) ∈ Firth.Interpreter.surfacePrimitives := by
  unfold Firth.Interpreter.kernelPrimitive at h
  obtain ⟨e, he, rfl⟩ := Option.map_eq_some_iff.mp h
  have hname := List.find?_some he
  have hm := List.mem_of_find?_eq_some he
  simp only [beq_iff_eq] at hname
  subst hname
  exact hm

end Firth.Compiler.LoweringCorrect
