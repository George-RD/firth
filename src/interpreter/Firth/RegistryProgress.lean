import Firth.Progress
import Firth.ProgramLogic

/-!
Progress and preservation for the reference runner's registries.

`defaultGamma_primitivesWellFormed` covers the kernel's own primitive table.
The reference runner resolves surface names through `adapterGamma`, and every
proof record states its contract under `int64Gamma`, which checks `+`, `-`,
`*` and `div` for i64 overflow. This file proves both premises of `progress`
for those two registries, so the kernel's progress and preservation theorems
apply to the registry the recorded contracts use.

The argument is a transfer. Every primitive's input and output stack types
hold only base types, and typing a stack of base types reads nothing of the
registry but its literal types, which all three registries share. So a
primitive's typed input under one registry is typed under the others, and its
output likewise. A checked delta either refuses or returns what the
unchecked one returns, and the checked primitives are declared
`faults := true`, so totality does not cover them.
-/

namespace Firth.Logic
open Firth.Interpreter Firth.ReferenceRun

/-- A stack type built from base types alone, with no quotation. -/
def StackType.baseOnly : StackType → Bool
  | .row _ => true
  | .snoc rest (.base _ _) => StackType.baseOnly rest
  | .snoc _ (.quotation _ _ _) => false

/-- Typing a stack of base types depends only on the registry's literal
types. -/
theorem stackTyping_transfer {gamma gamma' : Gamma} {dictionary : Dictionary}
    (hLiteral : gamma.literalType = gamma'.literalType) :
    ∀ {type : StackType} {stack : Stack}, StackType.baseOnly type = true →
      StackTyping gamma dictionary stack type → StackTyping gamma' dictionary stack type
  | .row _, _, _, h => by cases h; exact .empty
  | .snoc rest (.base base usage), _, hBase, h => by
      simp only [StackType.baseOnly] at hBase
      cases h with
      | cons valueType tailType =>
        refine .cons ?_ (stackTyping_transfer hLiteral hBase tailType)
        cases valueType with
        | literal hType => exact .literal (hLiteral ▸ hType)
        | world => exact .world
  | .snoc _ (.quotation _ _ _), _, hBase, _ => by simp [StackType.baseOnly] at hBase

/-- Every kernel primitive's input and output stack types are base types
alone. -/
theorem defaultGamma_baseOnly {name : Prim} {specification : PrimitiveSpec}
    (h : defaultGamma.primitive name = some specification) :
    StackType.baseOnly specification.input = true ∧
      StackType.baseOnly specification.output = true := by
  simp only [defaultGamma] at h
  split at h <;> cases h <;> decide

theorem adapterGamma_spec {name : Prim} {specification : PrimitiveSpec}
    (h : adapterGamma.primitive name = some specification) :
    ∃ kernel, defaultGamma.primitive kernel = some specification := by
  simp only [adapterGamma] at h
  split at h
  · exact ⟨_, h⟩
  · cases h

/-- The reference runner's registry satisfies both premises of progress and
preservation. -/
theorem adapterGamma_primitivesWellFormed (dictionary : Dictionary) :
    PrimitivesWellFormed adapterGamma dictionary := by
  obtain ⟨hPreserve, hTotal⟩ := defaultGamma_primitivesWellFormed dictionary
  constructor
  · intro name specification stack result hName hTyped hDelta
    obtain ⟨kernel, hKernel⟩ := adapterGamma_spec hName
    obtain ⟨hIn, hOut⟩ := defaultGamma_baseOnly hKernel
    exact stackTyping_transfer (gamma := defaultGamma) (gamma' := adapterGamma) rfl hOut
      (hPreserve kernel specification stack result hKernel
        (stackTyping_transfer (gamma := adapterGamma) (gamma' := defaultGamma) rfl hIn hTyped) hDelta)
  · intro name specification stack hName hFaults hTyped
    obtain ⟨kernel, hKernel⟩ := adapterGamma_spec hName
    obtain ⟨hIn, _⟩ := defaultGamma_baseOnly hKernel
    exact hTotal kernel specification stack hKernel hFaults
      (stackTyping_transfer (gamma := adapterGamma) (gamma' := defaultGamma) rfl hIn hTyped)

/-- A checked delta returns only what the unchecked one returns. -/
theorem int64Delta_some {primitive : Prim} {specification : PrimitiveSpec}
    (hSpec : adapterGamma.primitive primitive = some specification)
    {stack result : Stack} (h : int64Delta primitive specification.delta stack = some result) :
    specification.delta stack = some result := by
  unfold int64Delta at h
  by_cases hAdd : primitive = "+"
  · subst hAdd
    rw [show adapterGamma.primitive "+" = defaultGamma.primitive "addInt" from rfl] at hSpec
    simp only [defaultGamma, Option.some.injEq] at hSpec; subst hSpec
    rw [if_pos rfl] at h
    simp only [checkedIntDelta] at h
    split at h
    · split at h
      · exact h
      · cases h
    · cases h
  by_cases hSub : primitive = "-"
  · subst hSub
    rw [show adapterGamma.primitive "-" = defaultGamma.primitive "subInt" from rfl] at hSpec
    simp only [defaultGamma, Option.some.injEq] at hSpec; subst hSpec
    rw [if_neg (by decide), if_pos rfl] at h
    simp only [checkedIntDelta] at h
    split at h
    · split at h
      · exact h
      · cases h
    · cases h
  by_cases hMul : primitive = "*"
  · subst hMul
    rw [show adapterGamma.primitive "*" = defaultGamma.primitive "mulInt" from rfl] at hSpec
    simp only [defaultGamma, Option.some.injEq] at hSpec; subst hSpec
    rw [if_neg (by decide), if_neg (by decide), if_pos rfl] at h
    simp only [checkedIntDelta] at h
    split at h
    · split at h
      · exact h
      · cases h
    · cases h
  by_cases hDiv : primitive = "div"
  · subst hDiv
    rw [show adapterGamma.primitive "div" = defaultGamma.primitive "divInt" from rfl] at hSpec
    simp only [defaultGamma, Option.some.injEq] at hSpec; subst hSpec
    rw [if_neg (by decide), if_neg (by decide), if_neg (by decide), if_pos rfl] at h
    simp only [checkedDivDelta] at h
    split at h
    · rename_i right left rest
      simp only [divIntDelta]
      split at h
      · cases h
      · split at h
        · simp_all
        · cases h
    · cases h
  simpa [hAdd, hSub, hMul, hDiv] using h

/-- The registry every proof record's contract is stated under satisfies
both premises of progress and preservation. Its checked primitives are
declared `faults := true`, so an overflow is a primitive fault, the one way
`progress` lets a well-typed configuration stop. -/
theorem int64Gamma_primitivesWellFormed (dictionary : Dictionary) :
    PrimitivesWellFormed int64Gamma dictionary := by
  obtain ⟨hPreserve, hTotal⟩ := adapterGamma_primitivesWellFormed dictionary
  constructor
  · intro name specification stack result hName hTyped hDelta
    simp only [int64Gamma, Option.map_eq_some_iff] at hName
    obtain ⟨base, hBase, rfl⟩ := hName
    obtain ⟨kernel, hKernel⟩ := adapterGamma_spec hBase
    obtain ⟨hIn, hOut⟩ := defaultGamma_baseOnly hKernel
    exact stackTyping_transfer (gamma := adapterGamma) (gamma' := int64Gamma) rfl hOut
      (hPreserve name base stack result hBase
        (stackTyping_transfer (gamma := int64Gamma) (gamma' := adapterGamma) rfl hIn hTyped)
        (int64Delta_some hBase hDelta))
  · intro name specification stack hName hFaults hTyped
    simp only [int64Gamma, Option.map_eq_some_iff] at hName
    obtain ⟨base, hBase, rfl⟩ := hName
    simp only [Bool.or_eq_false_iff, decide_eq_false_iff_not] at hFaults
    obtain ⟨hUnchecked, hBaseFaults⟩ := hFaults
    obtain ⟨kernel, hKernel⟩ := adapterGamma_spec hBase
    obtain ⟨hIn, _⟩ := defaultGamma_baseOnly hKernel
    simp only [Int64Checked, not_or] at hUnchecked
    obtain ⟨hAdd, hSub, hMul, hDiv⟩ := hUnchecked
    simp only [int64Delta, hAdd, hSub, hMul, hDiv, if_false]
    exact hTotal name base stack hBase hBaseFaults
      (stackTyping_transfer (gamma := int64Gamma) (gamma' := adapterGamma) rfl hIn hTyped)

/-- A mutant of `int64Gamma` whose checked primitives keep the reference's
`faults` flag. It is not well formed: `+` is declared total but refuses
`9223372036854775807 1`. So the `faults := true` declaration is what
`int64Gamma_primitivesWellFormed` rests on, not a detail the proof ignores. -/
def int64GammaUnflagged : Gamma :=
  { int64Gamma with
    primitive := fun primitive => (adapterGamma.primitive primitive).map fun specification =>
      { specification with delta := int64Delta primitive specification.delta } }

theorem int64GammaUnflagged_not_total :
    ¬ PrimitivesTotal int64GammaUnflagged emptyDictionary := by
  intro hTotal
  obtain ⟨result, hResult⟩ := hTotal "+" _
    [.literal (.int 1), .literal (.int 9223372036854775807)] rfl rfl
    (.cons (.literal rfl) (.cons (.literal rfl) .empty))
  have hRefused : checkedIntDelta (· + ·)
      [.literal (.int 1), .literal (.int 9223372036854775807)] = none := by
    simp only [checkedIntDelta]; decide
  simp only [int64Delta, if_pos] at hResult
  rw [hRefused] at hResult
  cases hResult

theorem int64Gamma_literalTypingSound : LiteralTypingSound int64Gamma :=
  defaultGamma_literalTypingSound

/-- The faulting primitives of `int64Gamma` are those of the reference
runner's registry plus the checked `+`, `-`, `*` and `div`, and nothing
else. -/
theorem int64Gamma_faults_iff {name : Prim} {specification : PrimitiveSpec}
    (h : int64Gamma.primitive name = some specification) :
    specification.faults = true ↔
      Int64Checked name ∨ ∃ base, adapterGamma.primitive name = some base ∧ base.faults = true := by
  simp only [int64Gamma, Option.map_eq_some_iff] at h
  obtain ⟨base, hBase, rfl⟩ := h
  simp only [Bool.or_eq_true, decide_eq_true_eq]
  constructor
  · rintro (hChecked | hFaults)
    · exact .inl hChecked
    · exact .inr ⟨base, hBase, hFaults⟩
  · rintro (hChecked | ⟨other, hOther, hFaults⟩)
    · exact .inl hChecked
    · rw [hBase, Option.some.injEq] at hOther; subst hOther; exact .inr hFaults

/-- Progress for `int64Gamma`: a well-typed configuration with program left
either steps or stops at a primitive fault. By `int64Gamma_faults_iff`, the
faulting primitives are the reference's (a zero divisor, a sequence index out
of range) and the checked `+`, `-`, `*` and `div`, which fault on an i64
overflow. -/
theorem int64Gamma_progress (dictionary : Dictionary) (costs : CostTable)
    (dictionaryWellTyped : DictionaryWellTyped int64Gamma dictionary) {config : Config}
    (typed : TypedConfig int64Gamma dictionary config) (nonempty : config.program ≠ .empty) :
    (∃ next, HasSuccessor int64Gamma dictionary costs config next) ∨
      PrimitiveFault int64Gamma dictionary costs config :=
  progress int64Gamma dictionary costs int64Gamma_literalTypingSound dictionaryWellTyped
    (int64Gamma_primitivesWellFormed dictionary) typed nonempty

end Firth.Logic
