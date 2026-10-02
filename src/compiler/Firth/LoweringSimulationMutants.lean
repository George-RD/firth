import compiler.Firth.LoweringSimulation

/-! Planted miscompiles for the simulation theorems in `LoweringSimulation.lean`.

The source word `inc` is `1 +`. Its real lowering, computed by `lowerProgram`,
satisfies `ImageRel` and runs `5` to `6` on the target. Each mutant image
publishes a wrong body under the same name: `1 -` (wrong primitive) and `2 +`
(wrong literal). Each runs `5` to a result other than `6`, and for each the
theorems prove `¬ ImageRel`: from `ImageRel`, `execute_halted` would give an
interpreter run of `1 +` from `5` ending in a stack related to the mutant's,
and the interpreter's run is unique. So the simulation statement tells a
miscompiled image from the real one, rather than holding of any image. -/

namespace Firth.Compiler.LoweringSimulationMutants
open Firth.Compiler Firth.Compiler.Lowering Firth.Compiler.TargetSemantics
open Firth.Compiler.LoweringCorrect

def incProgram : Firth.Interpreter.Program :=
  .cons (.lit (.int 1)) (.cons (.prim "+") .empty)

def dictionary : Firth.Interpreter.Dictionary := fun name =>
  if name == "inc" then
    some { type := { rowVariables := [], input := .row "ρ", output := .row "ρ" }, body := incProgram }
  else none

def names : List (String × String) := [("inc", "inc")]

def entryOf (code : List Target.Instruction) : Target.WordEntry :=
  { name := "inc", erasedWordType := "", code, kernelEvidenceDigest := .empty,
    refinementEvidenceDigest := .empty, generation := 0 }

def realCode : List Target.Instruction :=
  match lowerProgram { word := "inc", words := names } incProgram with
  | .ok code => code
  | .error _ => []

def wrongPrimitive : List Target.Instruction := [.pushLiteral (.int 1), .prim "subInt"]
def wrongLiteral : List Target.Instruction := [.pushLiteral (.int 2), .prim "addInt"]

-- The real lowering is the target-spec table's `PUSH_LITERAL 1; PRIM addInt`.
#guard realCode.length == 2
example : realCode = [.pushLiteral (.int 1), .prim "addInt"] := rfl

theorem real_image : ImageRel names dictionary [entryOf realCode] := by
  intro name entry h
  have hn : name = "inc" := by
    simp only [names, List.find?_cons, List.find?_nil] at h
    split at h
    · rename_i hb; exact (beq_iff_eq.mp hb).symm
    · cases h
  subst hn
  simp only [names, List.find?_cons, List.find?_nil] at h
  cases h
  refine ⟨_, entryOf realCode, rfl, rfl, ?_⟩
  exact lowerProgram_rel (context := { word := "inc", words := names }) rfl incProgram realCode rfl []

/-- The interpreter runs `inc` from `5` to `6`, in two steps. -/
theorem interpreter_run : ∃ k, Firth.Logic.Reaches Firth.Logic.int64Gamma dictionary
    Firth.Interpreter.defaultCosts ⟨[.literal (.int 5)], incProgram⟩ ⟨[.literal (.int 6)], .empty⟩ 2 k :=
  ⟨_, Firth.Logic.Reaches.head rfl (Firth.Logic.Reaches.head rfl (Firth.Logic.Reaches.refl _))⟩

theorem real_runs : ∃ m, execute [entryOf realCode] "inc" [.int 5] 10 = .halted [.int 6] m :=
  ⟨_, rfl⟩

theorem wrongPrimitive_runs : ∃ m, execute [entryOf wrongPrimitive] "inc" [.int 5] 10 = .halted [.int 4] m :=
  ⟨_, rfl⟩

theorem wrongLiteral_runs : ∃ m, execute [entryOf wrongLiteral] "inc" [.int 5] 10 = .halted [.int 7] m :=
  ⟨_, rfl⟩

/-- An image of `inc` that halts from `5` with a single integer other than `6`
does not stand for `dictionary`. -/
theorem rejected {code : List Target.Instruction} {r : Int} (hr : r ≠ 6) {m : Machine}
    (hrun : execute [entryOf code] "inc" [.int 5] 10 = .halted [.int r] m) :
    ¬ ImageRel names dictionary [entryOf code] := by
  intro hI
  obtain ⟨e, w, he, hw, hcode⟩ := hI "inc" ("inc", "inc") rfl
  simp [dictionary] at he
  subst he
  have hS : ListRel (ValRel names) [.literal (.int 5)] [.int 5] :=
    .cons (.int rfl) .nil
  obtain ⟨S', n, hreach, hrel⟩ := execute_halted hI hw hcode hS hrun
  obtain ⟨k, hint⟩ := interpreter_run
  obtain ⟨rfl, _, _⟩ := terminal_unique hreach hint
  cases hrel with
  | cons hv _ => cases hv; exact hr rfl

theorem wrongPrimitive_rejected : ¬ ImageRel names dictionary [entryOf wrongPrimitive] :=
  have ⟨_, h⟩ := wrongPrimitive_runs
  rejected (by decide) h

theorem wrongLiteral_rejected : ¬ ImageRel names dictionary [entryOf wrongLiteral] :=
  have ⟨_, h⟩ := wrongLiteral_runs
  rejected (by decide) h

end Firth.Compiler.LoweringSimulationMutants
