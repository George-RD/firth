import compiler.Firth.LoweringPrimitives

/-!
The target machine simulates the reference interpreter on lowered code.

Step 3 of `todo.compiler-vm-agreement-proof`.

## What is proved

`compileWords_correct`: for each source word that `compileWords` compiles,
run on the target from a stack that stands for the interpreter stack `S`,

* when the target halts, the interpreter runs the word's body from `S` to a
  terminal configuration whose stack stands for the target's, and the target's
  kernel cost is exactly the cost the interpreter charges;
* when the interpreter runs the body from `S` to a terminal configuration in
  `N` steps charging `k`, the target given at least `N` fuel halts with a
  related stack and kernel cost `k`, except in two stated cases: the target
  exceeds its 256-frame call-depth bound, or the body takes the length of a
  sequence with 2^63 or more elements, which the interpreter returns and the
  target faults on (`LenOverflowAt`).

`execute_of_stuck` and `execute_trapped` relate faults: when the interpreter
gets stuck after `n` steps, the target given more than `n` fuel traps, and not
for want of fuel; and a target trap other than the depth bound and fuel
exhaustion means the interpreter gets stuck or meets the same length overflow.
The kernel cost spent before a fault is not related.

The hypotheses are that the interpreter's dictionary gives each source word
its checked body, and that no body holds the runtime-only `push` atom, which
the elaborator never writes. Typing is not assumed.

What this does not cover: the cost of a run that faults; the target's total cost adds a word-entry charge
the interpreter has no counterpart for, so only the kernel cost is related;
the target semantics is a Lean model of `target-spec.md` that the Rust VM is
tested against (step 2), not proved against; and the image the VM loads is
the one `Compile.lean` serialises, which this proof does not cover.
`LoweringSimulationMutants.lean` plants miscompiled images that the theorems
reject.

## The machine relation

A target machine stands for an interpreter configuration when its stack is
related value by value and its frames, read innermost first, spell out the
interpreter's program: each frame's remaining code, followed by the value a
`DIP` frame restores when it ends, followed by its callers. The interpreter
keeps that restore as an administrative `push` atom, which is why a `DIP`
frame's exit is part of the program.
-/

namespace Firth.Compiler.LoweringCorrect

open Firth.Compiler Firth.Compiler.Lowering Firth.Compiler.TargetSemantics
open Firth.Interpreter (Config)

/-- A frame as the lowering's code leaves it: its code stands for `p`, its
capture slots hold no linear value and none is consumed, and a transfer from
its last instruction may replace it. -/
structure FrameOk (M : List (String × String)) (f : Frame) (p : SProgram) : Prop where
  code : CodeRel M f.captures f.code p
  consumed : f.consumed = fresh f.captures
  many : linearValues f.captures = false
  tail : f.allowTail = true

/-- What a frame's exit adds to the program after its code: nothing, or the
value a `DIP` restores. -/
inductive ExitRel (M : List (String × String)) : Exit → SProgram → SProgram → Prop
  | halt {q} : ExitRel M .halt q q
  | plain {q} : ExitRel M .plain q q
  | checked {q} : ExitRel M .checked q q
  | dip {q v saved} : ValRel M v saved → ExitRel M (.dip saved) q (.cons (.push v) q)

inductive FramesRel (M : List (String × String)) : List Frame → SProgram → Prop
  | nil : FramesRel M [] .empty
  | cons {f callers p q q'} : FrameOk M f p → ExitRel M f.exit q q' → FramesRel M callers q →
      FramesRel M (f :: callers) (p.append q')

/-! ## Small facts -/

theorem CodeRel.nil_inv {M caps p} (h : CodeRel M caps [] p) : p = .empty := by
  cases h; rfl

theorem fresh_length (caps : List TValue) : (fresh caps).length = caps.length := by
  simp [fresh]

theorem fresh_append (a b : List TValue) : fresh (a ++ b) = fresh a ++ fresh b := by
  simp [fresh]

theorem owesCapture_fresh : ∀ caps : List TValue, linearValues caps = false →
    owesCapture caps (fresh caps) = false
  | [], _ => rfl
  | v :: caps, h => by
      simp only [linearValues, Bool.or_eq_false_iff] at h
      have := owesCapture_fresh caps h.2
      simp only [fresh, List.map_cons, owesCapture, h.1, Bool.false_and, Bool.false_or] at this ⊢
      exact this

theorem program_empty_append (q : SProgram) : Firth.Interpreter.Program.append .empty q = q := rfl

theorem program_cons_append (a : Firth.Interpreter.Atom) (p q : SProgram) :
    Firth.Interpreter.Program.append (.cons a p) q = .cons a (p.append q) := rfl

section Simulation
variable {D : Firth.Interpreter.Dictionary}

local notation "Reach" => Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts
local notation "istep" => Firth.Interpreter.step Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts

theorem istep_push (v : SValue) (S : List SValue) (q : SProgram) :
    istep ⟨S, .cons (.push v) q⟩ = .stepped ⟨v :: S, q⟩ 0 := rfl

/-- Ending finished frames is a run of zero-cost interpreter steps: none for a
plain return, one administrative `push` for each `DIP` restore. It never
faults on related frames, which owe no capture. -/
theorem unwind_sim {M} {frames : List Frame} {P : SProgram} (hF : FramesRel M frames P) :
    ∀ {s : List TValue} {S : List SValue}, ListRel (ValRel M) S s →
      ∃ s' frames' S' P' n, unwind s frames = .ok (s', frames') ∧
        Reach ⟨S, P⟩ ⟨S', P'⟩ n 0 ∧ ListRel (ValRel M) S' s' ∧ FramesRel M frames' P' ∧
        ∀ f rest, frames' = f :: rest → f.code ≠ [] := by
  induction hF with
  | nil =>
      intro s S hS
      exact ⟨s, [], S, .empty, 0, by simp [unwind], Firth.Logic.Reaches.refl _, hS, .nil,
        by simp⟩
  | @cons f callers p q q' hf he hc ih =>
      intro s S hS
      rcases f with ⟨word, code, caps, consumed, exit, allowTail⟩
      obtain ⟨hcodeRel, hconsumed, hmany, htail⟩ := hf
      simp only at hcodeRel hconsumed hmany htail he
      subst hconsumed
      cases code with
      | nil =>
          have hp : p = .empty := hcodeRel.nil_inv
          subst hp
          rw [program_empty_append]
          cases he with
          | halt => simpa [unwind] using ih hS
          | plain => simpa [unwind] using ih hS
          | checked => simpa [unwind, owesCapture_fresh _ hmany] using ih hS
          | @dip _ v saved hv =>
              obtain ⟨s', frames', S', P', n, hu, hr, hs', hf', hne⟩ := ih (.cons hv hS)
              exact ⟨s', frames', S', P', n + 1, by simpa [unwind, owesCapture_fresh _ hmany] using hu,
                by simpa using Firth.Logic.Reaches.head (istep_push v S q) hr, hs', hf', hne⟩
      | cons i rest =>
          refine ⟨s, ⟨word, i :: rest, caps, fresh caps, exit, allowTail⟩ :: callers, S, p.append q', 0,
            by rw [unwind]; rfl, Firth.Logic.Reaches.refl _, hS,
            .cons (f := ⟨word, i :: rest, caps, fresh caps, exit, allowTail⟩)
              ⟨hcodeRel, rfl, hmany, htail⟩ he hc, ?_⟩
          intro g r h; cases h; simp

/-- The interpreter cannot step. -/
def Stuck (D : Firth.Interpreter.Dictionary) (cfg : Config) : Prop :=
  ∃ c, Firth.Interpreter.step Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts cfg = .stuck c

/-- The interpreter is about to take the length of a sequence too long for an
`i64` length, which the target refuses. -/
def LenOverflowAt (cfg : Config) : Prop :=
  ∃ name rest, cfg.program = .cons (.prim name) rest ∧ LenOverflow name cfg.stack

/-- The image publishes, under each name the map gives a source word, code that
stands for that word's body. -/
def ImageRel (M : List (String × String)) (D : Firth.Interpreter.Dictionary)
    (image : List Target.WordEntry) : Prop :=
  ∀ name entry, M.find? (fun e => e.1 == name) = some entry →
    ∃ e w, D name = some e ∧ image.find? (·.name == entry.2) = some w ∧ CodeRel M [] w.code e.body

/-- What one validated, charged instruction does, against the interpreter
configuration `cfg` its frame stands for. -/
def InstrOk (M : List (String × String)) (D : Firth.Interpreter.Dictionary) (cfg : Config)
    (cost : Cost) : Effect → Prop
  | .ok stack frames cost' => ∃ S' P' n k,
      Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts cfg ⟨S', P'⟩ (n + 1) k ∧
      cost'.kernel = cost.kernel + k ∧ ListRel (ValRel M) S' stack ∧ FramesRel M frames P'
  | .fault trap _ _ _ => trap = .callDepthExceeded ∨ Stuck D cfg ∨ LenOverflowAt cfg

theorem listRel_length {α β} {R : α → β → Prop} : ∀ {a b}, ListRel R a b → a.length = b.length
  | _, _, .nil => rfl
  | _, _, .cons _ h => by simp [listRel_length h]

theorem listRel_getElem? {α β} {R : α → β → Prop} : ∀ {a b}, ListRel R a b → ∀ n : Nat,
    (a[n]? = none ∧ b[n]? = none) ∨ ∃ x y, a[n]? = some x ∧ b[n]? = some y ∧ R x y
  | _, _, .nil, _ => .inl ⟨rfl, rfl⟩
  | _, _, .cons h _, 0 => .inr ⟨_, _, rfl, rfl, h⟩
  | _, _, .cons _ t, n + 1 => by simpa using listRel_getElem? t n

theorem ValRel.usage {M v t} (h : ValRel M v t) : Firth.Interpreter.quotationUsage v = .many := by
  cases h <;> rfl

theorem CodeRel.usage {M caps} : ∀ {c p}, CodeRel M caps c p → Firth.Interpreter.programUsage p = .many
  | _, _, .nil => rfl
  | _, _, .lit _ h => by simp [Firth.Interpreter.programUsage, Firth.Interpreter.atomUsage, h.usage,
      Firth.Interpreter.usageMeet]
  | _, _, .quotation hq h => by
      simp [Firth.Interpreter.programUsage, Firth.Interpreter.atomUsage, hq.usage, h.usage,
        Firth.Interpreter.usageMeet]
  | _, _, .capture _ hv h => by
      simp [Firth.Interpreter.programUsage, Firth.Interpreter.atomUsage, hv.usage, h.usage,
        Firth.Interpreter.usageMeet]
  | _, _, .dup h | _, _, .drop h | _, _, .swap h | _, _, .pick h | _, _, .roll h | _, _, .dip h
  | _, _, .call h | _, _, .compose h | _, _, .quote h | _, _, .ifThenElse h | _, _, .word _ h
  | _, _, .prim _ h => by
      simp [Firth.Interpreter.programUsage, Firth.Interpreter.atomUsage, h.usage,
        Firth.Interpreter.usageMeet]

theorem seqIntBytes_size : ∀ xs : List Int, (Target.seqIntBytes xs).size = 8 * xs.length
  | [] => rfl
  | x :: xs => by
      have ih := seqIntBytes_size xs
      simp only [Target.seqIntBytes, ByteArray.size, List.flatMap_cons, List.size_toArray,
        List.length_append, List.length_map, List.length_range] at ih ⊢
      simp only [List.length_cons]
      omega

theorem reach1 {a b : Config} {k : Nat} (h : istep a = .stepped b k) : Reach a b 1 k := by
  simpa using Firth.Logic.Reaches.head h (Firth.Logic.Reaches.refl b)

theorem isLiteral_of {M l v} (h : ValRel M (.literal l) v) : isLiteral v = true := by
  cases h with
  | int h => exact h
  | bool => rfl
  | intSeq _ => simp [isLiteral, canonicalSeq, seqIntBytes_size]
  | boolSeq =>
      simp [isLiteral, canonicalSeq, Target.seqBoolBytes, Target.seqIntTag, Target.seqBoolTag, List.all_map]

theorem stuck_self {cfg : Config} (h : istep cfg = .stuck cfg) : Stuck D cfg := ⟨cfg, h⟩

theorem listRel_rollOut {M} : ∀ {S : List SValue} {s : List TValue}, ListRel (ValRel M) S s → ∀ n : Nat,
    (Firth.Interpreter.rollOut S n = none ∧ TargetSemantics.rollOut s n = none) ∨
    ∃ x y S' s', Firth.Interpreter.rollOut S n = some (x, S') ∧ TargetSemantics.rollOut s n = some (y, s') ∧
      ValRel M x y ∧ ListRel (ValRel M) S' s'
  | _, _, .nil, _ => .inl ⟨rfl, rfl⟩
  | _, _, .cons h t, 0 => .inr ⟨_, _, _, _, rfl, rfl, h, t⟩
  | _, _, .cons h t, n + 1 => by
      rcases listRel_rollOut t n with ⟨h1, h2⟩ | ⟨x, y, S', s', h1, h2, hx, hr⟩
      · exact .inl ⟨by simp [Firth.Interpreter.rollOut, h1], by simp [TargetSemantics.rollOut, h2]⟩
      · exact .inr ⟨x, y, _, _, by simp [Firth.Interpreter.rollOut, h1], by simp [TargetSemantics.rollOut, h2],
          hx, .cons h hr⟩

theorem rollOut_none_iff : ∀ (s : List TValue) (n : Nat), TargetSemantics.rollOut s n = none ↔ s.length ≤ n
  | [], n => by simp [TargetSemantics.rollOut]
  | _ :: s, 0 => by simp [TargetSemantics.rollOut]
  | _ :: s, n + 1 => by simp [TargetSemantics.rollOut, rollOut_none_iff s n]

theorem istep_prim (name : String) (S : List SValue) (P : SProgram) :
    istep ⟨S, .cons (.prim name) P⟩ =
      match sprim name S with
      | some r => .stepped ⟨r, P⟩ 1
      | none => .stuck ⟨S, .cons (.prim name) P⟩ := by
  simp only [Firth.Interpreter.step, sprim]
  cases Firth.Logic.int64Gamma.primitive name with
  | none => rfl
  | some spec =>
      simp only [Option.bind_some]
      cases spec.delta S <;> rfl

theorem validate_prim (k : String) (s : List TValue) (caps : List TValue) (cons : List Bool) :
    validate (.prim k) s caps cons = validate (.prim k) s [] [] := rfl

theorem tprim_of_validate {k : String} {s : List TValue} (h : validate (.prim k) s [] [] = none) :
    tprim k s = primitiveDelta k s := by simp [tprim, h]

theorem instr_sim {M image} (hI : ImageRel M D image) {f : Frame} {callers : List Frame}
    {i : Target.Instruction} {rest : TCode} {P0 q q' : SProgram} {S : List SValue} {s : List TValue}
    {c : Cost}
    (hcode : CodeRel M f.captures (i :: rest) P0) (hcons : f.consumed = fresh f.captures)
    (hmany : linearValues f.captures = false) (htail : f.allowTail = true)
    (he : ExitRel M f.exit q q') (hc : FramesRel M callers q) (hS : ListRel (ValRel M) S s) :
    (∀ t, validate i s f.captures f.consumed = some t →
      Stuck D ⟨S, P0.append q'⟩ ∨ LenOverflowAt ⟨S, P0.append q'⟩) ∧
    (validate i s f.captures f.consumed = none →
      InstrOk M D ⟨S, P0.append q'⟩ c (exec image f callers i rest s (charge c i))) := by
  have here : ∀ {pr}, CodeRel M f.captures rest pr →
      FramesRel M ({ f with code := rest } :: callers) (pr.append q') :=
    fun h => .cons (f := { f with code := rest }) ⟨h, hcons, hmany, htail⟩ he hc
  cases hcode with
  | lit hv hr =>
      refine ⟨fun t ht => by simp [validate, isLiteral_of hv] at ht, fun _ => ?_⟩
      refine ⟨_, _, 0, 1, ?_, by simp [charge], .cons hv hS, here hr⟩
      apply reach1
      cases hv <;> rfl
  | quotation hq hr =>
      refine ⟨fun t ht => by simp [validate, linearValues] at ht, fun _ => ?_⟩
      refine ⟨_, _, 0, 1, ?_, by simp [charge], .cons (.quotation hq rfl) hS, here hr⟩
      apply reach1
      rw [program_cons_append]; simp [Firth.Interpreter.step, hq.usage]
  | dup hr =>
      cases hS with
      | nil =>
          refine ⟨fun _ _ => .inl ⟨_, rfl⟩, fun h => by simp [validate] at h⟩
      | cons hv hS' =>
          refine ⟨fun t ht => by simp [validate, hv.not_linear] at ht, fun _ => ?_⟩
          refine ⟨_, _, 0, 1, reach1 rfl, by simp [charge], .cons hv (.cons hv hS'), here hr⟩
  | drop hr =>
      cases hS with
      | nil =>
          refine ⟨fun _ _ => .inl ⟨_, rfl⟩, fun h => by simp [validate] at h⟩
      | cons hv hS' =>
          refine ⟨fun t ht => by simp [validate, hv.not_linear] at ht, fun _ => ?_⟩
          refine ⟨_, _, 0, 1, reach1 rfl, by simp [charge], hS', here hr⟩
  | swap hr =>
      rcases hS with _ | ⟨hv, _ | ⟨hw, hS'⟩⟩
      · exact ⟨fun _ _ => .inl ⟨_, rfl⟩, fun h => by simp [validate] at h⟩
      · exact ⟨fun _ _ => .inl ⟨_, rfl⟩, fun h => by simp [validate] at h⟩
      · refine ⟨fun t ht => by simp [validate] at ht; omega, fun _ => ?_⟩
        exact ⟨_, _, 0, 1, reach1 rfl, by simp [charge], .cons hw (.cons hv hS'), here hr⟩
  | capture hi hv hr =>
      have hlt : _ < f.captures.length := (List.getElem?_eq_some_iff.mp hi).1
      refine ⟨fun t ht => ?_, fun _ => ?_⟩
      · rw [hcons] at ht
        simp [validate, fresh, hlt] at ht; omega
      · simp only [exec, hi, Option.getD_some, hv.not_linear, Bool.false_eq_true, ↓reduceIte]
        exact ⟨_, _, 0, 0, reach1 rfl, by simp [charge], .cons hv hS, here hr⟩
  | pick hr =>
      rename_i n _
      rcases listRel_getElem? hS n with ⟨h1, h2⟩ | ⟨x, y, h1, h2, hxy⟩
      · exact ⟨fun _ _ => .inl (stuck_self (by simp [Firth.Interpreter.step, program_cons_append, h1])),
          fun h => by simp [validate, h2] at h⟩
      · refine ⟨fun t ht => by simp [validate, h2, hxy.not_linear] at ht, fun _ => ?_⟩
        simp only [exec, h2]
        refine ⟨_, _, 0, 1, reach1 ?_, by simp [charge], .cons hxy hS, here hr⟩
        simp [Firth.Interpreter.step, program_cons_append, h1]
  | roll hr =>
      rename_i n _
      rcases listRel_rollOut hS n with ⟨h1, h2⟩ | ⟨x, y, S', s', h1, h2, hxy, hr'⟩
      · refine ⟨fun _ _ => .inl (stuck_self (by simp [Firth.Interpreter.step, program_cons_append, h1])), fun h => ?_⟩
        · simp only [validate] at h
          rw [if_pos ((rollOut_none_iff s n).mp h2)] at h
          cases h
      · refine ⟨fun t ht => ?_, fun _ => ?_⟩
        · simp only [validate] at ht
          rw [if_neg (fun hle => by rw [(rollOut_none_iff s n).mpr hle] at h2; cases h2)] at ht
          cases ht
        · simp only [exec, h2]
          refine ⟨_, _, 0, 1, reach1 ?_, by simp [charge], .cons hxy hr', here hr⟩
          simp [Firth.Interpreter.step, program_cons_append, h1]
  | quote hr =>
      cases hS with
      | nil => exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
      | cons hv hS' =>
          refine ⟨fun t ht => by simp [validate] at ht, fun _ => ?_⟩
          refine ⟨_, _, 0, 1, reach1 ?_, by simp [charge],
            .cons (.quotation (caps := [_]) (.capture rfl hv .nil) (by simp [linearValues, hv.not_linear])) hS',
            here hr⟩
          simp [Firth.Interpreter.step, program_cons_append, hv.usage]
  | prim hk hr =>
      rename_i name k _
      have hag := prim_agree hk hS
      rw [validate_prim]
      refine ⟨fun t ht => ?_, fun hv => ?_⟩
      · cases hsp : sprim name S with
        | none => exact .inl (stuck_self (by rw [program_cons_append, istep_prim, hsp]))
        | some r =>
            rcases hag.1 r hsp with ⟨r', ht', _⟩ | ⟨_, hlen⟩
            · simp [tprim, ht] at ht'
            · exact .inr ⟨name, _, by rw [program_cons_append], hlen⟩
      · have htp := tprim_of_validate hv
        simp only [exec]
        cases hpd : primitiveDelta k s with
        | some r' =>
            cases hsp : sprim name S with
            | none => have := hag.2 hsp; rw [htp, hpd] at this; cases this
            | some r =>
                rcases hag.1 r hsp with ⟨r'', h1, h2⟩ | ⟨h1, _⟩
                · rw [htp, hpd] at h1
                  cases h1
                  refine ⟨_, _, 0, 1, reach1 ?_, by simp [charge, primitiveCost], h2, here hr⟩
                  rw [program_cons_append, istep_prim, hsp]
                · rw [htp, hpd] at h1; cases h1
        | none =>
            show _ ∨ _ ∨ _
            cases hsp : sprim name S with
            | none => exact .inr (.inl (stuck_self (by rw [program_cons_append, istep_prim, hsp])))
            | some r =>
                rcases hag.1 r hsp with ⟨r'', h1, _⟩ | ⟨_, hlen⟩
                · rw [htp, hpd] at h1; cases h1
                · exact .inr (.inr ⟨name, _, by rw [program_cons_append], hlen⟩)
  | call hr =>
      rcases hS with _ | ⟨hv, hS'⟩
      · exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
      · cases hv with
        | int _ => exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
        | bool => exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
        | intSeq _ => exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
        | boolSeq => exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
        | quotation hq hlin =>
            rename_i body code caps
            refine ⟨fun t ht => by simp [validate] at ht, fun _ => ?_⟩
            cases rest with
            | nil =>
                have := hr.nil_inv; subst this
                simp only [exec, htail, hlin, List.isEmpty_nil, Bool.and_self, Bool.not_false, ↓reduceIte]
                refine ⟨_, _, 0, 1, reach1 rfl, by simp [charge], hS', ?_⟩
                exact .cons (f := { enter f.word code caps (fresh caps) .plain with exit := f.exit, allowTail := true })
                  ⟨hq, rfl, hlin, rfl⟩ he hc
            | cons j rest' =>
                simp only [exec, hlin, List.isEmpty_cons, Bool.and_false, Bool.false_and,
                  Bool.false_eq_true, ↓reduceIte]
                split
                · exact .inl rfl
                · refine ⟨_, _, 0, 1, reach1 rfl, by simp [charge], hS', ?_⟩
                  exact .cons (f := enter f.word code caps (fresh caps) .checked)
                    ⟨hq, rfl, hlin, by simp [enter, hlin]⟩ .checked (here hr)
  | dip hr =>
      rcases hS with _ | ⟨hv, _ | ⟨hw, hS'⟩⟩
      · exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
      · exact ⟨fun _ _ => .inl (stuck_self (by cases hv <;> rfl)), fun h => by simp [validate] at h⟩
      · cases hv with
        | int _ => exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
        | bool => exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
        | intSeq _ => exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
        | boolSeq => exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
        | quotation hq hlin =>
            rename_i body code caps
            refine ⟨fun t ht => by simp [validate] at ht, fun _ => ?_⟩
            simp only [exec]
            split
            · exact .inl rfl
            · refine ⟨_, _, 0, 1, reach1 rfl, by simp [charge], hS', ?_⟩
              exact .cons (f := enter f.word code caps (fresh caps) (.dip _))
                ⟨hq, rfl, hlin, by simp [enter, hlin]⟩ (.dip hw) (here hr)
  | compose hr =>
      rcases hS with _ | ⟨hv, _ | ⟨hw, hS'⟩⟩
      · exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
      · exact ⟨fun _ _ => .inl (stuck_self (by cases hv <;> rfl)), fun h => by simp [validate] at h⟩
      · cases hv <;> cases hw <;>
          first
          | exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate, isQuotation] at h⟩
          | skip
        rename_i rbody rcode rcaps hrq hrl lbody lcode lcaps hlq hll
        refine ⟨fun t ht => by simp [validate, isQuotation] at ht, fun _ => ?_⟩
        simp only [exec]
        have hrel : ValRel M (.quotation (lbody.append rbody) .many)
            (.quotation (lcode ++ TargetSemantics.rebase lcaps.length rcode) (lcaps ++ rcaps)
              (fresh lcaps ++ fresh rcaps)) := by
          rw [← fresh_append]
          exact .quotation (CodeRel.append hlq.extend hrq.rebase) (by simp [linearValues_append, hll, hrl])
        refine ⟨_, _, 0, 1, reach1 rfl, by simp [charge], .cons hrel hS', here hr⟩
  | ifThenElse hr =>
      rcases hS with _ | ⟨hv, _ | ⟨hw, _ | ⟨hx, hS'⟩⟩⟩
      · exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate] at h⟩
      · exact ⟨fun _ _ => .inl (stuck_self (by cases hv <;> rfl)), fun h => by simp [validate] at h⟩
      · exact ⟨fun _ _ => .inl (stuck_self (by cases hv <;> cases hw <;> rfl)),
          fun h => by simp [validate] at h⟩
      · cases hv <;> cases hw <;> cases hx <;>
          first
          | exact ⟨fun _ _ => .inl (stuck_self rfl), fun h => by simp [validate, isQuotation] at h⟩
          | skip
        rename_i fbody fcode fcaps hfq hfl tbody tcode tcaps htq htl b
        refine ⟨fun t ht => by simp [validate, isQuotation] at ht, fun _ => ?_⟩
        cases rest with
        | nil =>
            have := hr.nil_inv; subst this
            cases b
            · simp only [exec, htail, hfl, htl, List.isEmpty_nil, Bool.and_self, Bool.or_self,
                Bool.false_eq_true, ↓reduceIte]
              refine ⟨_, _, 0, 1, reach1 rfl, by simp [charge], hS', .cons ⟨?_, rfl, hfl, rfl⟩ he hc⟩
              simpa using hfq
            · simp only [exec, htail, hfl, htl, List.isEmpty_nil, Bool.and_self, Bool.or_self,
                Bool.false_eq_true, ↓reduceIte]
              refine ⟨_, _, 0, 1, reach1 rfl, by simp [charge], hS', .cons ⟨?_, rfl, htl, rfl⟩ he hc⟩
              simpa using htq
        | cons j rest' =>
            cases b
            · simp only [exec, hfl, htl, List.isEmpty_cons, Bool.and_false, Bool.or_self,
                Bool.false_eq_true, ↓reduceIte]
              split
              · exact .inl rfl
              · refine ⟨_, _, 0, 1, reach1 rfl, by simp [charge], hS', ?_⟩
                refine .cons ⟨?_, rfl, hfl, by simp [enter, hfl]⟩ .plain (here hr)
                simpa using hfq
            · simp only [exec, hfl, htl, List.isEmpty_cons, Bool.and_false, Bool.or_self,
                Bool.false_eq_true, ↓reduceIte]
              split
              · exact .inl rfl
              · refine ⟨_, _, 0, 1, reach1 rfl, by simp [charge], hS', ?_⟩
                refine .cons ⟨?_, rfl, htl, by simp [enter, htl]⟩ .plain (here hr)
                simpa using htq
  | word hfind hr =>
      rename_i name entry _
      obtain ⟨e, w, hD, hW, hcw⟩ := hI name entry hfind
      refine ⟨fun t ht => by simp [validate] at ht, fun _ => ?_⟩
      cases rest with
      | nil =>
          have := hr.nil_inv; subst this
          simp only [exec, hW, htail, List.isEmpty_nil, Bool.and_self, ↓reduceIte]
          refine ⟨_, _, 0, 1, reach1 ?_, by simp [charge, chargeEntry], hS, .cons ⟨hcw, rfl, rfl, rfl⟩ he hc⟩
          simp [Firth.Interpreter.step, program_cons_append, hD, program_empty_append]
      | cons j rest' =>
          simp only [exec, hW, List.isEmpty_cons, Bool.and_false, Bool.false_eq_true, ↓reduceIte]
          split
          · exact .inl rfl
          · refine ⟨_, _, 0, 1, reach1 ?_, by simp [charge, chargeEntry], hS,
              .cons ⟨hcw, rfl, rfl, rfl⟩ .plain (here hr)⟩
            simp [Firth.Interpreter.step, program_cons_append, hD]

end Simulation

section Runs
variable {D : Firth.Interpreter.Dictionary}
local notation "Reach" => Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts

/-- Only the fuel check traps for want of fuel. -/
theorem validate_ne_fuel {i : Target.Instruction} {s c : List Target.Value} {k : List Bool} :
    validate i s c k ≠ some .fuelExhausted := by
  unfold validate
  split <;> (repeat' split) <;> simp <;> (repeat' split) <;> simp
theorem exec_ne_fuel {image f callers i rest s cost} {s' fr c'} :
    exec image f callers i rest s cost ≠ .fault .fuelExhausted s' fr c' := by
  unfold exec
  split <;> (repeat' split) <;> simp <;> (repeat' split) <;> simp
/-- What one target step says about the interpreter, from the configuration
`cfg` the machine `m` stands for. -/
def StepOk (M : List (String × String)) (D : Firth.Interpreter.Dictionary) (cfg : Config)
    (m : Machine) : Step → Prop
  | .next m' => ∃ S' P' n k,
      Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts cfg ⟨S', P'⟩ (n + 1) k ∧
      m'.cost.kernel = m.cost.kernel + k ∧ m'.fuel + 1 = m.fuel ∧
      ListRel (ValRel M) S' m'.stack ∧ FramesRel M m'.frames P'
  | .halted s m' => ∃ S' n,
      Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts cfg ⟨S', .empty⟩ n 0 ∧
      ListRel (ValRel M) S' s ∧ m'.cost = m.cost
  | .trapped t _ => t = .callDepthExceeded ∨
      (t = .fuelExhausted ∧ m.fuel = 0 ∧ ∃ cfg' n,
        Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts cfg cfg' n 0 ∧
        cfg'.program ≠ .empty) ∨
      t ≠ .fuelExhausted ∧ ∃ cfg' n k,
        Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts cfg cfg' n k ∧
        (Stuck D cfg' ∨ LenOverflowAt cfg')

theorem terminalStack_rel {M} : ∀ {S : List SValue} {s : List TValue}, ListRel (ValRel M) S s →
    terminalStack s = some s
  | _, _, .nil => rfl
  | _, _, .cons hv hr => by
      cases hv <;> simp_all [terminalStack, terminalStack_rel hr, linearValue, Target.seqIntTag,
        Target.seqBoolTag]

theorem step_sim {M image} (hI : ImageRel M D image) {m : Machine} {P : SProgram} {S : List SValue}
    (hF : FramesRel M m.frames P) (hS : ListRel (ValRel M) S m.stack) :
    StepOk M D ⟨S, P⟩ m (step image m) := by
  obtain ⟨s', frames', S', P', n, hu, hr, hs', hf', hne⟩ := unwind_sim (D := D) hF hS
  unfold step
  rw [hu]
  cases hf' with
  | nil =>
      simp only [terminalStack_rel hs']
      exact ⟨S', n, hr, hs', rfl⟩
  | @cons f callers p q q' hfo he hc =>
      obtain ⟨hcode, hcons, hmany, htail⟩ := hfo
      cases hcf : f.code with
      | nil => exact absurd hcf (hne f callers rfl)
      | cons i rest =>
          rw [hcf] at hcode
          simp only [hcf]
          by_cases hfuel : m.fuel = 0
          · simp only [hfuel, ↓reduceIte]
            refine .inr (.inl ⟨rfl, hfuel, _, n, hr, ?_⟩)
            cases hcode <;> simp [program_cons_append]
          · simp only [hfuel, ↓reduceIte]
            have hI2 := instr_sim (D := D) hI (f := f) (callers := callers) (c := m.cost) hcode hcons hmany
              htail he hc hs'
            cases hv : validate i s' f.captures f.consumed with
            | some t => exact .inr (.inr ⟨by rintro rfl; exact validate_ne_fuel hv, _, n, 0, hr, hI2.1 t hv⟩)
            | none =>
                have hx := hI2.2 hv
                simp only
                cases hex : exec image f callers i rest s' (charge m.cost i) with
                | ok s2 fr2 c2 =>
                    rw [hex] at hx
                    obtain ⟨S2, P2, n2, k, hr2, hk, hs2, hf2⟩ := hx
                    refine ⟨S2, P2, n + n2, k, ?_, hk, by simp; omega, hs2, hf2⟩
                    have := Firth.Logic.Reaches.trans hr hr2
                    simpa [Nat.add_assoc] using this
                | fault t s2 fr2 c2 =>
                    rw [hex] at hx
                    rcases hx with h | h | h
                    · exact .inl h
                    · exact .inr (.inr ⟨by rintro rfl; exact exec_ne_fuel hex, _, n, 0, hr, .inl h⟩)
                    · exact .inr (.inr ⟨by rintro rfl; exact exec_ne_fuel hex, _, n, 0, hr, .inr h⟩)
/-! ## The interpreter is deterministic -/

theorem reaches_split {a b c : Config} {n k n' k' : Nat} (h1 : Reach a b n k) (h2 : Reach a c n' k')
    (hle : n ≤ n') : ∃ k'', Reach b c (n' - n) k'' ∧ k' = k + k'' := by
  rcases h1 with ⟨tr, hl, hc⟩
  subst hl hc
  induction tr generalizing n' k' with
  | nil => exact ⟨k', by simpa [Firth.Interpreter.traceLength] using h2, by simp [Firth.Interpreter.traceCost]⟩
  | @cons start mid fin cost hstep tail ih =>
      rcases h2 with ⟨tr2, hl2, hc2⟩
      subst hl2 hc2
      cases tr2 with
      | nil => simp [Firth.Interpreter.traceLength] at hle
      | @cons _ mid2 _ cost2 hstep2 tail2 =>
          rw [hstep] at hstep2
          cases hstep2
          simp only [Firth.Interpreter.traceLength, Nat.succ_le_succ_iff] at hle
          obtain ⟨k'', h, hk⟩ := ih ⟨tail2, rfl, rfl⟩ hle
          refine ⟨k'', by simpa [Firth.Interpreter.traceLength] using h, ?_⟩
          simp [Firth.Interpreter.traceCost, hk, Nat.add_assoc]

theorem reaches_from_terminal {X : List SValue} {c : Config} {m k : Nat}
    (h : Reach ⟨X, .empty⟩ c m k) : m = 0 ∧ c = ⟨X, .empty⟩ := by
  rcases h with ⟨tr, hl, _⟩
  cases tr with
  | nil => exact ⟨hl.symm, rfl⟩
  | cons _ hstep _ => cases hstep

theorem reaches_from_stuck {c d : Config} {m k : Nat} (hs : Stuck D c) (h : Reach c d m k) :
    m = 0 ∧ d = c := by
  rcases h with ⟨tr, hl, _⟩
  cases tr with
  | nil => exact ⟨hl.symm, rfl⟩
  | cons _ hstep _ => obtain ⟨_, h⟩ := hs; rw [h] at hstep; cases hstep

/-- A run that reaches a terminal configuration never meets a stuck one. -/
theorem not_stuck_of_terminal {a c : Config} {X : List SValue} {N K n k : Nat}
    (ht : Reach a ⟨X, .empty⟩ N K) (hc : Reach a c n k) (hs : Stuck D c) : False := by
  rcases Nat.le_total N n with hle | hle
  · obtain ⟨_, h, _⟩ := reaches_split ht hc hle
    obtain ⟨_, rfl⟩ := reaches_from_terminal h
    obtain ⟨_, h⟩ := hs
    cases h
  · obtain ⟨_, h, _⟩ := reaches_split hc ht hle
    obtain ⟨hm, _⟩ := reaches_from_stuck hs h
    obtain ⟨tr, _, _⟩ := h
    have : c = ⟨X, .empty⟩ := by
      cases tr with
      | nil => rfl
      | cons _ hstep _ => obtain ⟨_, h⟩ := hs; rw [h] at hstep; cases hstep
    subst this
    obtain ⟨_, h⟩ := hs
    cases h

/-- Two runs to terminal configurations end in the same one, after the same
steps and cost. -/
theorem terminal_unique {a : Config} {X Y : List SValue} {n k n' k' : Nat}
    (h1 : Reach a ⟨X, .empty⟩ n k) (h2 : Reach a ⟨Y, .empty⟩ n' k') : X = Y ∧ n = n' ∧ k = k' := by
  rcases Nat.le_total n n' with hle | hle
  · obtain ⟨k'', h, hk⟩ := reaches_split h1 h2 hle
    obtain ⟨hm, he⟩ := reaches_from_terminal h
    cases he
    obtain ⟨tr, hl, hc⟩ := h
    cases tr with
    | nil =>
        have hl' : n' - n = 0 := by simpa [Firth.Interpreter.traceLength] using hl.symm
        have hc' : k'' = 0 := by simpa [Firth.Interpreter.traceCost] using hc.symm
        refine ⟨rfl, by omega, by omega⟩
    | cons _ hstep _ => cases hstep
  · obtain ⟨k'', h, hk⟩ := reaches_split h2 h1 hle
    obtain ⟨hm, he⟩ := reaches_from_terminal h
    cases he
    obtain ⟨tr, hl, hc⟩ := h
    cases tr with
    | nil =>
        have hl' : n - n' = 0 := by simpa [Firth.Interpreter.traceLength] using hl.symm
        have hc' : k'' = 0 := by simpa [Firth.Interpreter.traceCost] using hc.symm
        refine ⟨rfl, by omega, by omega⟩
    | cons _ hstep _ => cases hstep

/-! ## Whole runs -/

/-- What a bounded target run says about the interpreter, from the
configuration `cfg` the starting machine `m` stands for. -/
def RunOk (M : List (String × String)) (D : Firth.Interpreter.Dictionary) (cfg : Config)
    (m : Machine) : Outcome → Prop
  | .halted s m' => ∃ S' n k,
      Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts cfg ⟨S', .empty⟩ n k ∧
      m'.cost.kernel = m.cost.kernel + k ∧ ListRel (ValRel M) S' s
  | .trapped t _ => t = .callDepthExceeded ∨
      (t = .fuelExhausted ∧ ∃ cfg' n k,
        Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts cfg cfg' n k ∧
        m.fuel ≤ n ∧ cfg'.program ≠ .empty) ∨
      t ≠ .fuelExhausted ∧ ∃ cfg' n k,
        Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts cfg cfg' n k ∧
        (Stuck D cfg' ∨ LenOverflowAt cfg')
  | .outOfBound _ => True

theorem RunOk.prepend {M} {cfg cfg' : Config} {m m' : Machine} {n k : Nat} {o : Outcome}
    (hr : Reach cfg cfg' (n + 1) k) (hk : m'.cost.kernel = m.cost.kernel + k) (hf : m'.fuel + 1 = m.fuel)
    (h : RunOk M D cfg' m' o) : RunOk M D cfg m o := by
  cases o with
  | halted s m'' =>
      obtain ⟨S', n', k', h1, h2, h3⟩ := h
      exact ⟨S', _, _, Firth.Logic.Reaches.trans hr h1, by rw [h2, hk, Nat.add_assoc], h3⟩
  | trapped t m'' =>
      rcases h with h | ⟨ht, c, n', k', h1, h2, h3⟩ | ⟨hne, c, n', k', h1, h2⟩
      · exact .inl h
      · exact .inr (.inl ⟨ht, c, _, _, Firth.Logic.Reaches.trans hr h1, by omega, h3⟩)
      · exact .inr (.inr ⟨hne, c, _, _, Firth.Logic.Reaches.trans hr h1, h2⟩)
  | outOfBound _ => trivial

theorem run_sim {M image} (hI : ImageRel M D image) :
    ∀ (bound : Nat) (m : Machine) {P : SProgram} {S : List SValue},
      FramesRel M m.frames P → ListRel (ValRel M) S m.stack → RunOk M D ⟨S, P⟩ m (run image bound m)
  | bound, m, P, S, hF, hS => by
      have hs := step_sim (D := D) hI hF hS
      unfold run
      cases hst : step image m with
      | halted s m' =>
          rw [hst] at hs
          obtain ⟨S', n, h1, h2, h3⟩ := hs
          exact ⟨S', n, 0, h1, by rw [h3]; rfl, h2⟩
      | trapped t m' =>
          rw [hst] at hs
          rcases hs with h | ⟨ht, hz, c, n, h1, h2⟩ | h
          · exact .inl h
          · exact .inr (.inl ⟨ht, c, n, 0, h1, by omega, h2⟩)
          · exact .inr (.inr h)
      | next m' =>
          rw [hst] at hs
          obtain ⟨S', P', n, k, h1, h2, h3, h4, h5⟩ := hs
          cases bound with
          | zero => trivial
          | succ bound => exact RunOk.prepend h1 h2 h3 (run_sim hI bound m' h5 h4)

/-! ## Running an entry word -/

theorem start_rel {M} {w : Target.WordEntry} {body : SProgram} (hbody : CodeRel M [] w.code body)
    (stack : List TValue) (fuel : Nat) : FramesRel M (start w stack fuel).frames body := by
  have := FramesRel.cons (M := M) (f := enter w.name w.code [] [] .halt) (q := .empty)
    ⟨hbody, rfl, rfl, rfl⟩ .halt .nil
  simpa [start, Firth.Logic.programAppend_empty] using this

theorem execute_sim {M image} (hI : ImageRel M D image) {entry : String} {w : Target.WordEntry}
    {body : SProgram} (hentry : image.find? (·.name == entry) = some w) (hbody : CodeRel M [] w.code body)
    {S : List SValue} {stack : List TValue} (hS : ListRel (ValRel M) S stack) (fuel : Nat) :
    RunOk M D ⟨S, body⟩ (start w stack fuel) (execute image entry stack fuel) := by
  unfold execute
  rw [hentry]
  exact run_sim hI fuel _ (start_rel hbody stack fuel) hS

/-- Soundness: when the target halts, the interpreter runs the same body from
the related stack to a terminal configuration, its stack related to the
target's, charging exactly the target's kernel cost. -/
theorem execute_halted {M image} (hI : ImageRel M D image) {entry : String} {w : Target.WordEntry}
    {body : SProgram} (hentry : image.find? (·.name == entry) = some w) (hbody : CodeRel M [] w.code body)
    {S : List SValue} {stack : List TValue} (hS : ListRel (ValRel M) S stack) {fuel : Nat}
    {s : List TValue} {m' : Machine} (h : execute image entry stack fuel = .halted s m') :
    ∃ S' n, Reach ⟨S, body⟩ ⟨S', .empty⟩ n m'.cost.kernel ∧ ListRel (ValRel M) S' s := by
  have := execute_sim hI hentry hbody hS fuel
  rw [h] at this
  obtain ⟨S', n, k, h1, h2, h3⟩ := this
  refine ⟨S', n, ?_, h3⟩
  rw [h2]
  simpa [start] using h1

/-- Completeness: when the interpreter runs the body to a terminal
configuration in `N` steps charging `k`, the target given at least `N` fuel
halts with a related stack and kernel cost `k`, unless it runs out of frames
(`call-depth-exceeded`) or the run takes the length of a sequence of 2^63 or
more elements. -/
theorem execute_of_reaches {M image} (hI : ImageRel M D image) {entry : String} {w : Target.WordEntry}
    {body : SProgram} (hentry : image.find? (·.name == entry) = some w) (hbody : CodeRel M [] w.code body)
    {S S' : List SValue} {stack : List TValue} (hS : ListRel (ValRel M) S stack) {N k fuel : Nat}
    (hrun : Reach ⟨S, body⟩ ⟨S', .empty⟩ N k) (hfuel : N ≤ fuel) :
    (∃ s m', execute image entry stack fuel = .halted s m' ∧ ListRel (ValRel M) S' s ∧
        m'.cost.kernel = k) ∨
      (∃ m', execute image entry stack fuel = .trapped .callDepthExceeded m') ∨
      (∃ cfg n k', Reach ⟨S, body⟩ cfg n k' ∧ LenOverflowAt cfg) := by
  have hsim := execute_sim hI hentry hbody hS fuel
  cases ho : execute image entry stack fuel with
  | halted s m' =>
      obtain ⟨S'', n, h1, h2⟩ := execute_halted hI hentry hbody hS ho
      obtain ⟨rfl, _, hk⟩ := terminal_unique h1 hrun
      exact .inl ⟨s, m', rfl, h2, hk⟩
  | trapped t m' =>
      rw [ho] at hsim
      rcases hsim with rfl | ⟨_, c, n, k', h1, h2, h3⟩ | ⟨_, c, n, k', h1, h2 | h2⟩
      · exact .inr (.inl ⟨m', rfl⟩)
      · exfalso
        obtain ⟨_, h, _⟩ := reaches_split hrun h1 (by simp [start] at h2; omega)
        obtain ⟨_, rfl⟩ := reaches_from_terminal h
        exact h3 rfl
      · exact (not_stuck_of_terminal hrun h1 h2).elim
      · exact .inr (.inr ⟨c, n, k', h1, h2⟩)
  | outOfBound last => exact absurd ho (execute_within_bound last)

/-- Faults: when the interpreter gets stuck (a type or stack fault, or a
primitive fault) on the body after `n` steps, the target given more than `n`
fuel traps, and not for want of fuel. With `execute_trapped`, the trap is the
depth bound, the interpreter's own fault, or an earlier length overflow. The
kernel cost spent before a fault is not related. -/
theorem execute_of_stuck {M image} (hI : ImageRel M D image) {entry : String} {w : Target.WordEntry}
    {body : SProgram} (hentry : image.find? (·.name == entry) = some w) (hbody : CodeRel M [] w.code body)
    {S : List SValue} {stack : List TValue} (hS : ListRel (ValRel M) S stack) {c : Config} {n k : Nat}
    (hc : Reach ⟨S, body⟩ c n k) (hstuck : Stuck D c) {fuel : Nat} (hfuel : n < fuel) :
    ∃ t m', execute image entry stack fuel = .trapped t m' ∧ t ≠ .fuelExhausted := by
  have hsim := execute_sim hI hentry hbody hS fuel
  cases ho : execute image entry stack fuel with
  | halted s m' =>
      obtain ⟨S'', n', h1, _⟩ := execute_halted hI hentry hbody hS ho
      exact (not_stuck_of_terminal h1 hc hstuck).elim
  | trapped t m' =>
      refine ⟨t, m', rfl, ?_⟩
      rintro rfl
      rw [ho] at hsim
      rcases hsim with h | ⟨_, c', n', k', h1, h2, _⟩ | ⟨hne, _⟩
      · cases h
      · simp only [start] at h2
        obtain ⟨_, h, _⟩ := reaches_split hc h1 (by omega)
        obtain ⟨h0, _⟩ := reaches_from_stuck hstuck h
        omega
      · exact hne rfl
  | outOfBound last => exact absurd ho (execute_within_bound last)

/-- And the converse: a target trap other than the depth bound and running
out of fuel means the interpreter, from the related start, reaches a
configuration where it is stuck, or where it takes the length of a sequence
too long for an `i64`. -/
theorem execute_trapped {M image} (hI : ImageRel M D image) {entry : String} {w : Target.WordEntry}
    {body : SProgram} (hentry : image.find? (·.name == entry) = some w) (hbody : CodeRel M [] w.code body)
    {S : List SValue} {stack : List TValue} (hS : ListRel (ValRel M) S stack) {fuel : Nat}
    {t : Trap} {m' : Machine} (h : execute image entry stack fuel = .trapped t m')
    (hdepth : t ≠ .callDepthExceeded) (hfuel : t ≠ .fuelExhausted) :
    ∃ cfg n k, Reach ⟨S, body⟩ cfg n k ∧ (Stuck D cfg ∨ LenOverflowAt cfg) := by
  have := execute_sim hI hentry hbody hS fuel
  rw [h] at this
  rcases this with h1 | ⟨h1, _⟩ | h1
  · exact absurd h1 hdepth
  · exact absurd h1 hfuel
  · exact h1.2

end Runs

section Compiled
variable {D : Firth.Interpreter.Dictionary}
local notation "Reach" => Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts

theorem listRel_mem_left {α β} {R : α → β → Prop} :
    ∀ {as : List α} {bs : List β}, ListRel R as bs → ∀ {a}, a ∈ as → ∃ b ∈ bs, R a b
  | _, _, .nil, _, h => by cases h
  | _, _, .cons hab hr, _, h => by
      rcases List.mem_cons.mp h with rfl | h
      · exact ⟨_, List.mem_cons_self, hab⟩
      · obtain ⟨b, hb, h⟩ := listRel_mem_left hr h
        exact ⟨b, List.mem_cons_of_mem _ hb, h⟩

theorem listRel_mem_right {α β} {R : α → β → Prop} :
    ∀ {as : List α} {bs : List β}, ListRel R as bs → ∀ {b}, b ∈ bs → ∃ a ∈ as, R a b
  | _, _, .nil, _, h => by cases h
  | _, _, .cons hab hr, _, h => by
      rcases List.mem_cons.mp h with rfl | h
      · exact ⟨_, List.mem_cons_self, hab⟩
      · obtain ⟨a, ha, h⟩ := listRel_mem_right hr h
        exact ⟨a, List.mem_cons_of_mem _ ha, h⟩

/-- In a map whose target names are distinct, two members with the same
target name are the same member. -/
theorem eq_of_snd_eq {mapping : List (String × String)} (hnodup : (mapping.map Prod.snd).Nodup)
    {p q : String × String} (hp : p ∈ mapping) (hq : q ∈ mapping) (h : p.2 = q.2) : p = q := by
  induction mapping with
  | nil => cases hp
  | cons r rest ih =>
      rw [List.map_cons, List.nodup_cons] at hnodup
      rcases List.mem_cons.mp hp with hp1 | hp1 <;> rcases List.mem_cons.mp hq with hq1 | hq1
      · rw [hp1, hq1]
      · subst hp1
        exact absurd (h ▸ List.mem_map_of_mem (f := Prod.snd) hq1) hnodup.1
      · subst hq1
        exact absurd (h ▸ List.mem_map_of_mem (f := Prod.snd) hp1) hnodup.1
      · exact ih hnodup.2 hp1 hq1

/-- The image `compileWords` emits stands for the dictionary `D`, when `D`
gives each source word its checked body and no body holds a runtime-only
`push` atom (the elaborator never writes one). -/
theorem compileWords_image {words : List CheckedWord} {image : List Target.WordEntry}
    (hc : compileWords words = .ok image)
    (hD : ∀ word ∈ words, ∃ e, D word.name = some e ∧ e.body = word.program)
    (hnp : ∀ word ∈ words, noPushProgram word.program = true) :
    ∃ M, nameMap words = .ok M ∧ ImageRel M D image := by
  obtain ⟨M, hM, hrel⟩ := compileWords_ok hc
  obtain ⟨hnames, hnd, _⟩ := nameMapOf_ok hM
  refine ⟨M, hM, fun name entry hfind => ?_⟩
  have hmem := List.mem_of_find?_eq_some hfind
  have hname : entry.1 = name := by simpa using List.find?_some hfind
  have : name ∈ words.map (·.name) := hnames ▸ hname ▸ List.mem_map_of_mem hmem
  obtain ⟨word, hword, rfl⟩ := List.mem_map.mp this
  obtain ⟨we, hwe, hwfind, _⟩ := listRel_mem_left hrel hword
  rw [hwfind] at hfind
  cases hfind
  obtain ⟨w, hw⟩ : ∃ w, image.find? (·.name == we.name) = some w := by
    cases h : image.find? (·.name == we.name) with
    | some w => exact ⟨w, rfl⟩
    | none => exact absurd (List.find?_eq_none.mp h we hwe) (by simp)
  have hwmem := List.mem_of_find?_eq_some hw
  have hwname : w.name = we.name := by simpa using List.find?_some hw
  obtain ⟨word', hword', hfind', hlower'⟩ := listRel_mem_right hrel hwmem
  have hsame := eq_of_snd_eq hnd (List.mem_of_find?_eq_some hfind')
    (List.mem_of_find?_eq_some hwfind) (by simp [hwname])
  simp only [Prod.mk.injEq] at hsame
  obtain ⟨e, he, hbody⟩ := hD word' hword'
  refine ⟨e, w, hsame.1 ▸ he, hw, ?_⟩
  rw [hbody]
  exact lowerProgram_rel rfl word'.program w.code hlower' (hnp word' hword') []

/-- Each source word is published under its mangled name, as code that stands
for its body in that image. -/
theorem compileWords_entry {words : List CheckedWord} {image : List Target.WordEntry}
    (hc : compileWords words = .ok image)
    (hD : ∀ word ∈ words, ∃ e, D word.name = some e ∧ e.body = word.program)
    (hnp : ∀ word ∈ words, noPushProgram word.program = true)
    {word : CheckedWord} (hword : word ∈ words) :
    ∃ M target w, nameMap words = .ok M ∧ ImageRel M D image ∧
      M.find? (fun e => e.1 == word.name) = some (word.name, target) ∧
      image.find? (·.name == target) = some w ∧ CodeRel M [] w.code word.program := by
  obtain ⟨M, hM, hI⟩ := compileWords_image hc hD hnp
  obtain ⟨M', hM', hrel⟩ := compileWords_ok hc
  rw [hM] at hM'
  cases hM'
  obtain ⟨we, _, hfind, _⟩ := listRel_mem_left hrel hword
  obtain ⟨e, w, he, hw, hcode⟩ := hI _ _ hfind
  obtain ⟨e', he', hbody⟩ := hD word hword
  rw [he] at he'
  cases he'
  exact ⟨M, we.name, w, hM, hI, hfind, hw, hbody ▸ hcode⟩

/-- The compiler is correct for each source word it compiles. Running the
word's published entry on the target from a stack that stands for `S`:

* when it halts, the interpreter runs the word's body from `S` to a terminal
  configuration whose stack stands for the target's, charging exactly the
  target's kernel cost;
* when the interpreter runs the body from `S` to a terminal configuration in
  `N` steps charging `k`, the target given at least `N` fuel halts with a
  related stack and kernel cost `k`, unless it exceeds its call-depth bound
  or the body takes the length of a sequence too long for `Int` on the way. -/
theorem compileWords_correct {words : List CheckedWord} {image : List Target.WordEntry}
    (hc : compileWords words = .ok image)
    (hD : ∀ word ∈ words, ∃ e, D word.name = some e ∧ e.body = word.program)
    (hnp : ∀ word ∈ words, noPushProgram word.program = true)
    {word : CheckedWord} (hword : word ∈ words) :
    ∃ M target, nameMap words = .ok M ∧
      M.find? (fun e => e.1 == word.name) = some (word.name, target) ∧
      (∀ {S stack fuel s m'}, ListRel (ValRel M) S stack →
        execute image target stack fuel = .halted s m' →
        ∃ S' n, Reach ⟨S, word.program⟩ ⟨S', .empty⟩ n m'.cost.kernel ∧ ListRel (ValRel M) S' s) ∧
      (∀ {S S' stack N k fuel}, ListRel (ValRel M) S stack →
        Reach ⟨S, word.program⟩ ⟨S', .empty⟩ N k → N ≤ fuel →
        (∃ s m', execute image target stack fuel = .halted s m' ∧ ListRel (ValRel M) S' s ∧
            m'.cost.kernel = k) ∨
          (∃ m', execute image target stack fuel = .trapped .callDepthExceeded m') ∨
          (∃ cfg n k', Reach ⟨S, word.program⟩ cfg n k' ∧ LenOverflowAt cfg)) := by
  obtain ⟨M, target, w, hM, hI, hfind, hw, hcode⟩ := compileWords_entry hc hD hnp hword
  exact ⟨M, target, hM, hfind, fun hS h => execute_halted hI hw hcode hS h,
    fun hS hrun hfuel => execute_of_reaches hI hw hcode hS hrun hfuel⟩

end Compiled

end Firth.Compiler.LoweringCorrect
