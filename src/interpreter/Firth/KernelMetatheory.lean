import Firth.Interpreter

namespace Firth.Interpreter

/-! The executable interpreter is the single definition of the v0.1 transition
system.  The preservation work uses the shared judgements in
`Firth.Interpreter`; its dictionary and primitive hypotheses are exactly the
well-formedness obligations stated by the frozen kernel specification. -/

def HasSuccessor (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (config : Config) (next : Config) : Prop :=
  ∃ cost, step gamma dictionary costs config = .stepped next cost

theorem quotationUsage_of_typing {value : Value} {type : ValueType}
    (h : ValueTyping gamma dictionary value type) :
    quotationUsage value = type.usage := by
  cases h <;> rfl

theorem push_program_typing {value : Value} {type : ValueType} {stack : StackType}
    (hv : ValueTyping gamma dictionary value type) :
    ProgramTyping gamma dictionary
      (.cons (.push value) .empty) stack (.snoc stack type) := by
  exact ProgramTyping.cons (AtomTyping.push hv) ProgramTyping.empty

theorem quote_program_typing {value : Value} {type : ValueType} {row : String}
    (hv : ValueTyping gamma dictionary value type) :
    ProgramTyping gamma dictionary
      (.cons (.push value) .empty) (.row row) (.snoc (.row row) type) := by
  exact push_program_typing hv

theorem quotation_capture_footprint {value : Value} {type : ValueType}
    (hv : ValueTyping gamma dictionary value type) :
    quotationUsage value = type.usage := by
  exact quotationUsage_of_typing hv

theorem usageMeet_assoc (a b c : Usage) :
    usageMeet (usageMeet a b) c = usageMeet a (usageMeet b c) := by
  cases a <;> cases b <;> cases c <;> rfl

theorem usageMeet_many_right (usage : Usage) :
    usageMeet .many usage = usage := by
  cases usage <;> rfl

theorem usageMeet_many_left (usage : Usage) :
    usageMeet usage .many = usage := by
  cases usage <;> rfl

theorem programTyping_append (left right : Program) {input middle output : StackType}
    (leftTyping : ProgramTyping gamma dictionary left input middle)
    (rightTyping : ProgramTyping gamma dictionary right middle output) :
    ProgramTyping gamma dictionary (left.append right) input output := by
  cases left with
  | empty =>
      cases leftTyping
      simpa [Program.append] using rightTyping
  | cons head tail =>
      cases leftTyping with
      | cons headTyping tailTyping =>
          exact ProgramTyping.cons headTyping
            (programTyping_append tail right tailTyping rightTyping)

theorem programUsage_append (left right : Program) :
    programUsage (left.append right) = usageMeet (programUsage left) (programUsage right) := by
  cases left with
  | empty => simp [Program.append, programUsage, usageMeet_many_right]
  | cons head tail =>
      simp [Program.append, programUsage,
        programUsage_append tail right, usageMeet_assoc]

theorem stackTyping_snoc_inv {rest : StackType} {type : ValueType} {stack : Stack}
    (hs : StackTyping gamma dictionary stack (.snoc rest type)) :
    ∃ value tail, stack = value :: tail ∧
      ValueTyping gamma dictionary value type ∧
      StackTyping gamma dictionary tail rest := by
  cases hs with
  | cons valueType tailType => exact ⟨_, _, rfl, valueType, tailType⟩

theorem step_deterministic (gamma : Gamma) (dictionary : Dictionary)
    (costs : CostTable) (config : Config) :
    ∀ next₁ next₂,
      HasSuccessor gamma dictionary costs config next₁ →
      HasSuccessor gamma dictionary costs config next₂ →
      next₁ = next₂ := by
  intro next₁ next₂ h₁ h₂
  rcases h₁ with ⟨cost₁, h₁⟩
  rcases h₂ with ⟨cost₂, h₂⟩
  rw [h₁] at h₂
  cases h₂
  rfl

def sequenceCost {α : Type} (cost : α → Nat) : List α → Nat
  | [] => 0
  | head :: tail => cost head + sequenceCost cost tail

theorem sequenceCost_append {α : Type} (cost : α → Nat)
    (left right : List α) :
    sequenceCost cost (left ++ right) =
      sequenceCost cost left + sequenceCost cost right := by
  induction left with
  | nil => simp [sequenceCost]
  | cons head tail ih =>
      simp [sequenceCost, ih, Nat.add_assoc]

theorem atomSequenceCost_append (costs : CostTable)
    (left right : List Atom) :
    sequenceCost costs.atom (left ++ right) =
      sequenceCost costs.atom left + sequenceCost costs.atom right :=
  sequenceCost_append costs.atom left right

theorem preservation_lit {literal : Literal} {stack : Stack}
    {stackType output : StackType} {base : BaseType}
    (literalTyping : gamma.literalType literal = some base)
    (stackTyping : StackTyping gamma dictionary stack stackType)
    (restTyping : ProgramTyping gamma dictionary rest
      (.snoc stackType (.base base .many)) output) :
    TypedConfig gamma dictionary
      { stack := .literal literal :: stack, program := rest } := by
  exact ⟨_, _, StackTyping.cons (.literal literalTyping) stackTyping, restTyping⟩

theorem preservation_quote {value : Value} {type : ValueType} {stack : Stack}
    {stackType output : StackType}
    (valueTyping : ValueTyping gamma dictionary value type)
    (stackTyping : StackTyping gamma dictionary stack stackType)
    (restTyping : ProgramTyping gamma dictionary rest
      (.snoc stackType (.quotation (.row "ρ") (.snoc (.row "ρ") type)
        (usageMeet .many type.usage))) output) :
    TypedConfig gamma dictionary
      { stack := .quotation (.cons (.push value) .empty) (quotationUsage value) :: stack,
        program := rest } := by
  have usageBridge : quotationUsage value = usageMeet .many type.usage := by
    cases valueTyping with
    | literal h => rfl
    | world => rfl
    | quotation h => cases programUsage _ <;> rfl
  have bodyTyping : ProgramTyping gamma dictionary
      (.cons (.push value) .empty) (.row "ρ")
      (.snoc (.row "ρ") type) := push_program_typing valueTyping
  have quotationTyping : ValueTyping gamma dictionary
      (.quotation (.cons (.push value) .empty) (quotationUsage value))
      (.quotation (.row "ρ") (.snoc (.row "ρ") type)
        (usageMeet .many type.usage)) := by
    simpa [programUsage, atomUsage, usageBridge, usageMeet_many_left,
      usageMeet_many_right, usageMeet_assoc] using
      (ValueTyping.quotation bodyTyping)
  exact ⟨_, _, StackTyping.cons quotationTyping stackTyping, restTyping⟩

theorem valueTyping_quotation_inv {body : Program} {storedUsage typeUsage : Usage}
    {input output : StackType}
    (h : ValueTyping gamma dictionary (.quotation body storedUsage)
      (.quotation input output typeUsage)) :
    storedUsage = programUsage body ∧ typeUsage = programUsage body ∧
      ProgramTyping gamma dictionary body input output := by
  cases h
  exact ⟨rfl, rfl, ‹ProgramTyping gamma dictionary body input output›⟩

theorem valueTyping_quotation_unpack {value : Value} {usage : Usage}
    {input output : StackType}
    (h : ValueTyping gamma dictionary value
      (.quotation input output usage)) :
    ∃ body, value = .quotation body (programUsage body) ∧
      usage = programUsage body ∧
      ProgramTyping gamma dictionary body input output := by
  cases h
  exact ⟨_, rfl, rfl, by assumption⟩

theorem preservation_quote_row {value : Value} {type : ValueType} {stack : Stack}
    {row : String} {stackType output : StackType}
    (valueTyping : ValueTyping gamma dictionary value type)
    (stackTyping : StackTyping gamma dictionary stack stackType)
    (restTyping : ProgramTyping gamma dictionary rest
      (.snoc stackType (.quotation (.row row) (.snoc (.row row) type)
        (usageMeet .many type.usage))) output) :
    TypedConfig gamma dictionary
      { stack := .quotation (.cons (.push value) .empty) (quotationUsage value) :: stack,
        program := rest } := by
  have bodyTyping : ProgramTyping gamma dictionary
      (.cons (.push value) .empty) (.row row)
      (.snoc (.row row) type) := push_program_typing valueTyping
  have quotationTyping : ValueTyping gamma dictionary
      (.quotation (.cons (.push value) .empty) (quotationUsage value))
      (.quotation (.row row) (.snoc (.row row) type)
        (usageMeet .many type.usage)) := by
    have usageBridge : quotationUsage value = usageMeet .many type.usage := by
      cases valueTyping with
      | literal h => rfl
      | world => rfl
      | quotation h => cases programUsage _ <;> rfl
    simpa [programUsage, atomUsage, usageBridge, usageMeet_many_left,
      usageMeet_many_right, usageMeet_assoc] using (ValueTyping.quotation bodyTyping)
  exact ⟨_, _, StackTyping.cons quotationTyping stackTyping, restTyping⟩

theorem preservation_dup {value : Value} {tail : Stack} {type : ValueType}
    {stackType output : StackType}
    (valueTyping : ValueTyping gamma dictionary value type)
    (tailTyping : StackTyping gamma dictionary tail stackType)
    (restTyping : ProgramTyping gamma dictionary rest
      (.snoc (.snoc stackType type) type) output) :
    TypedConfig gamma dictionary
      { stack := value :: value :: tail, program := rest } := by
  exact ⟨_, _, StackTyping.cons valueTyping (StackTyping.cons valueTyping tailTyping), restTyping⟩

theorem preservation_drop {tail : Stack}
    {stackType output : StackType}
    (tailTyping : StackTyping gamma dictionary tail stackType)
    (restTyping : ProgramTyping gamma dictionary rest stackType output) :
    TypedConfig gamma dictionary { stack := tail, program := rest } :=
  ⟨_, _, tailTyping, restTyping⟩

theorem preservation_swap {first second : Value} {tail : Stack}
    {firstType secondType : ValueType} {stackType output : StackType}
    (firstTyping : ValueTyping gamma dictionary first firstType)
    (secondTyping : ValueTyping gamma dictionary second secondType)
    (tailTyping : StackTyping gamma dictionary tail stackType)
    (restTyping : ProgramTyping gamma dictionary rest
      (.snoc (.snoc stackType secondType) firstType) output) :
    TypedConfig gamma dictionary
      { stack := first :: second :: tail, program := rest } :=
  ⟨_, _, StackTyping.cons firstTyping (StackTyping.cons secondTyping tailTyping), restTyping⟩

theorem preservation_call {body : Program} {tail : Stack}
    {input output resultType : StackType}
    (bodyTyping : ProgramTyping gamma dictionary body input output)
    (tailTyping : StackTyping gamma dictionary tail input)
    (restTyping : ProgramTyping gamma dictionary rest output resultType) :
    TypedConfig gamma dictionary
      { stack := tail, program := body.append rest } := by
  exact ⟨_, _, tailTyping, programTyping_append body rest bodyTyping restTyping⟩

theorem preservation_dip {body : Program} {value : Value}
    {tail : Stack} {input output resultType : StackType} {valueType : ValueType}
    (bodyTyping : ProgramTyping gamma dictionary body input output)
    (valueTyping : ValueTyping gamma dictionary value valueType)
    (tailTyping : StackTyping gamma dictionary tail input)
    (restTyping : ProgramTyping gamma dictionary rest
      (.snoc output valueType) resultType) :
    TypedConfig gamma dictionary
      { stack := tail, program := body.append (.cons (.push value) rest) } := by
  have pushed : ProgramTyping gamma dictionary
      (.cons (.push value) rest) output resultType := by
    exact programTyping_append (.cons (.push value) .empty) rest
      (push_program_typing valueTyping) restTyping
  exact ⟨_, _, tailTyping, programTyping_append body (.cons (.push value) rest)
    bodyTyping pushed⟩

theorem preservation_compose {first second : Program} {usage₁ usage₂ : Usage}
    {tail : Stack} {input middle output stackType resultType : StackType}
    (firstTyping : ProgramTyping gamma dictionary first input middle)
    (secondTyping : ProgramTyping gamma dictionary second middle output)
    (usage₁Eq : usage₁ = programUsage first)
    (usage₂Eq : usage₂ = programUsage second)
    (tailTyping : StackTyping gamma dictionary tail stackType)
    (restTyping : ProgramTyping gamma dictionary rest
      (.snoc stackType (.quotation input output (usageMeet usage₁ usage₂))) resultType) :
    TypedConfig gamma dictionary
      { stack := .quotation (first.append second) (usageMeet usage₁ usage₂) :: tail,
        program := rest } := by
  have composedTyping : ProgramTyping gamma dictionary (first.append second) input output :=
    programTyping_append first second firstTyping secondTyping
  have usageEq : programUsage (first.append second) = usageMeet usage₁ usage₂ := by
    rw [programUsage_append, usage₁Eq, usage₂Eq]
  have composedValueTyping : ValueTyping gamma dictionary
      (.quotation (first.append second) (usageMeet usage₁ usage₂))
      (.quotation input output (usageMeet usage₁ usage₂)) := by
    simpa [usageEq] using (ValueTyping.quotation composedTyping)
  exact ⟨_, _, StackTyping.cons composedValueTyping tailTyping, restTyping⟩

theorem preservation_if {branch : Program}
    {tail : Stack} {input output resultType : StackType}
    (branchTyping : ProgramTyping gamma dictionary branch input output)
    (tailTyping : StackTyping gamma dictionary tail input)
    (restTyping : ProgramTyping gamma dictionary rest output resultType) :
    TypedConfig gamma dictionary
      { stack := tail, program := branch.append rest } :=
  ⟨_, _, tailTyping, programTyping_append branch rest branchTyping restTyping⟩

theorem preservation_word {name : String} {entry : WordEntry} {tail : Stack}
    {middle stackType resultType : StackType}
    (entryEq : dictionary name = some entry)
    (entryInput : entry.type.input = stackType)
    (entryOutput : entry.type.output = middle)
    (dictionaryWellTyped : DictionaryWellTyped gamma dictionary)
    (tailTyping : StackTyping gamma dictionary tail stackType)
    (restTyping : ProgramTyping gamma dictionary rest middle resultType) :
    TypedConfig gamma dictionary
      { stack := tail, program := entry.body.append rest } := by
  have entryTyping := dictionaryWellTyped name entry entryEq
  subst entryInput
  subst entryOutput
  exact ⟨_, _, tailTyping, programTyping_append entry.body rest entryTyping restTyping⟩

theorem preservation_prim {name : Prim} {specification : PrimitiveSpec}
    {stack result : Stack} {resultType : StackType}
    (specificationEq : gamma.primitive name = some specification)
    (primitivesPreserve : PrimitivesPreserve gamma dictionary)
    (stackTyping : StackTyping gamma dictionary stack specification.input)
    (deltaEq : specification.delta stack = some result)
    (restTyping : ProgramTyping gamma dictionary rest specification.output resultType) :
    TypedConfig gamma dictionary { stack := result, program := rest } := by
  exact ⟨_, _, primitivesPreserve name specification stack result specificationEq
    stackTyping deltaEq, restTyping⟩

theorem compose_usage_runtime_eq (left right : Usage) :
    (if (left == .linear) = true ∨ (right == .linear) = true then
      .linear else .many) = usageMeet left right := by
  cases left <;> cases right <;> decide

theorem preservation (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (dictionaryWellTyped : DictionaryWellTyped gamma dictionary)
    (primitivesPreserve : PrimitivesPreserve gamma dictionary) {config next : Config}
    (configTyping : TypedConfig gamma dictionary config)
    (successor : HasSuccessor gamma dictionary costs config next) :
    TypedConfig gamma dictionary next := by
  rcases config with ⟨stack, program⟩
  rcases configTyping with ⟨stackType, outputType, stackTyping, programTyping⟩
  rcases successor with ⟨cost, successor⟩
  cases program with
  | empty =>
      cases successor
  | cons head rest =>
      cases programTyping with
      | cons headTyping restTyping =>
        cases head with
        | lit literal =>
            cases headTyping with
            | lit h =>
                simp [step, h] at successor
                rcases successor with ⟨rfl, rfl⟩
                exact preservation_lit h stackTyping restTyping
        | push value =>
            cases headTyping with
            | push h =>
                simp [step] at successor
                rcases successor with ⟨rfl, rfl⟩
                exact ⟨_, _, StackTyping.cons h stackTyping, restTyping⟩
        | quotation body =>
            cases headTyping with
            | quotation h =>
                simp [step] at successor
                rcases successor with ⟨rfl, rfl⟩
                exact ⟨_, _, StackTyping.cons (ValueTyping.quotation h) stackTyping, restTyping⟩
        | dup =>
            cases headTyping with
            | dup h =>
                rcases stackTyping_snoc_inv stackTyping with ⟨value, tail, rfl, valueTyping, tailTyping⟩
                simp [step] at successor
                rcases successor with ⟨rfl, rfl⟩
                exact preservation_dup valueTyping tailTyping restTyping
        | drop =>
            cases headTyping with
            | drop h =>
                rcases stackTyping_snoc_inv stackTyping with ⟨value, tail, rfl, valueTyping, tailTyping⟩
                simp [step] at successor
                rcases successor with ⟨rfl, rfl⟩
                exact preservation_drop tailTyping restTyping
        | swap =>
            cases headTyping with
            | swap =>
                rcases stackTyping_snoc_inv stackTyping with ⟨second, tail₁, rfl, secondTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with ⟨first, tail, rfl, firstTyping, tailTyping⟩
                simp [step] at successor
                rcases successor with ⟨rfl, rfl⟩
                exact preservation_swap firstTyping secondTyping tailTyping restTyping
        | call =>
            cases headTyping with
            | call =>
                rcases stackTyping_snoc_inv stackTyping with ⟨quotation, tail, rfl, quotationTyping, tailTyping⟩
                simp [step] at successor
                cases quotationTyping with
                | quotation bodyTyping =>
                    rcases successor with ⟨rfl, rfl⟩
                    exact preservation_call bodyTyping tailTyping restTyping
        | dip =>
            cases headTyping with
            | dip =>
                rcases stackTyping_snoc_inv stackTyping with ⟨quotation, tail₁, rfl, quotationTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with ⟨value, tail, rfl, valueTyping, tailTyping⟩
                simp [step] at successor
                cases quotationTyping with
                | quotation bodyTyping =>
                    rcases successor with ⟨rfl, rfl⟩
                    exact preservation_dip bodyTyping valueTyping tailTyping restTyping
        | compose =>
            cases headTyping with
            | compose =>
                rcases stackTyping_snoc_inv stackTyping with ⟨secondQuotation, tail₁, rfl, secondTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with ⟨firstQuotation, tail, rfl, firstTyping, baseTyping⟩
                rcases valueTyping_quotation_unpack secondTyping with
                  ⟨secondBody, rfl, usage₂Eq, secondBodyTyping⟩
                rcases valueTyping_quotation_unpack firstTyping with
                  ⟨firstBody, rfl, usage₁Eq, firstBodyTyping⟩
                simp [step] at successor
                rw [← successor.1]
                rw [compose_usage_runtime_eq]
                rw [← usage₁Eq, ← usage₂Eq]
                exact preservation_compose firstBodyTyping secondBodyTyping usage₁Eq usage₂Eq
                  baseTyping restTyping
        | quote =>
            cases headTyping with
            | quote =>
                rcases stackTyping_snoc_inv stackTyping with ⟨value, tail, rfl, valueTyping, tailTyping⟩
                simp [step] at successor
                rcases successor with ⟨rfl, rfl⟩
                exact preservation_quote_row valueTyping tailTyping restTyping
        | ifThenElse =>
            cases headTyping with
            | ifThenElse =>
                rcases stackTyping_snoc_inv stackTyping with ⟨falseQuotation, tail₁, rfl, falseTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with ⟨trueQuotation, tail₂, rfl, trueTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with ⟨conditionValue, tail, rfl, conditionTyping, baseTyping⟩
                cases conditionValue with
                | world id => simp [step] at successor
                | quotation body usage => simp [step] at successor
                | literal literal =>
                  cases literal with
                  | nat value => simp [step] at successor
                  | unit => simp [step] at successor
                  | bool condition =>
                    rcases valueTyping_quotation_unpack falseTyping with
                      ⟨falseBody, rfl, falseUsageEq, falseBodyTyping⟩
                    rcases valueTyping_quotation_unpack trueTyping with
                      ⟨trueBody, rfl, trueUsageEq, trueBodyTyping⟩
                    simp [step] at successor
                    rcases successor with ⟨rfl, rfl⟩
                    by_cases chosen : condition = true
                    · simp [chosen]
                      exact preservation_if trueBodyTyping baseTyping restTyping
                    · simp [chosen]
                      exact preservation_if falseBodyTyping baseTyping restTyping
        | word name =>
            cases headTyping with
            | word h =>
                rcases h with ⟨entry, entryEq, entryInput, entryOutput⟩
                simp [step, entryEq] at successor
                rcases successor with ⟨rfl, rfl⟩
                exact preservation_word (middle := _) (resultType := outputType) entryEq entryInput entryOutput
                  dictionaryWellTyped stackTyping restTyping
        | prim name =>
            cases headTyping with
            | prim h =>
                simp [step, h] at successor
                split at successor
                case h_1 hdelta =>
                    cases successor
                    exact preservation_prim h primitivesPreserve stackTyping hdelta restTyping
                case h_2 hdelta => cases successor


inductive KernelEffectDependency where
  | word (name : String) (type : WordType)
  | primitive (name : Prim) (input output : StackType)
  deriving BEq, Repr

mutual
  def resolveKernelValueDependencies (gamma : Gamma) (dictionary : Dictionary) :
      Value → Option (List KernelEffectDependency)
    | .literal _ => some []
    | .world _ => some []
    | .quotation body _ => resolveKernelProgramDependencies gamma dictionary body

  def resolveKernelAtomDependencies (gamma : Gamma) (dictionary : Dictionary) :
      Atom → Option (List KernelEffectDependency)
    | .lit _ => some []
    | .push value => resolveKernelValueDependencies gamma dictionary value
    | .quotation body => resolveKernelProgramDependencies gamma dictionary body
    | .dup | .drop | .swap | .dip | .call | .compose | .quote | .ifThenElse => some []
    | .word name =>
        match dictionary name with
        | some entry => some [.word name entry.type]
        | none => none
    | .prim name =>
        match gamma.primitive name with
        | some specification => some [.primitive name specification.input specification.output]
        | none => none

  def resolveKernelProgramDependencies (gamma : Gamma) (dictionary : Dictionary) :
      Program → Option (List KernelEffectDependency)
    | .empty => some []
    | .cons head tail =>
        match resolveKernelAtomDependencies gamma dictionary head,
          resolveKernelProgramDependencies gamma dictionary tail with
        | some headDependencies, some tailDependencies =>
            some (headDependencies ++ tailDependencies)
        | _, _ => none
end

structure KernelEffectBoundary (gamma : Gamma) (dictionary : Dictionary)
    (body : Program) (input output : StackType) where
  dependencies : List KernelEffectDependency
  resolved : resolveKernelProgramDependencies gamma dictionary body = some dependencies
  typing : ProgramTyping gamma dictionary body input output

mutual
  theorem valueTyping_resolves_kernel_effect_dependencies
      (typing : ValueTyping gamma dictionary value type) :
      ∃ dependencies,
        resolveKernelValueDependencies gamma dictionary value = some dependencies := by
    cases typing with
    | literal => exact ⟨[], rfl⟩
    | world => exact ⟨[], rfl⟩
    | quotation bodyTyping =>
        exact programTyping_resolves_kernel_effect_dependencies bodyTyping

  theorem atomTyping_resolves_kernel_effect_dependencies
      (typing : AtomTyping gamma dictionary atom input output) :
      ∃ dependencies,
        resolveKernelAtomDependencies gamma dictionary atom = some dependencies := by
    cases typing with
    | lit => exact ⟨[], rfl⟩
    | push valueTyping =>
        exact valueTyping_resolves_kernel_effect_dependencies valueTyping
    | quotation bodyTyping =>
        exact programTyping_resolves_kernel_effect_dependencies bodyTyping
    | dup => exact ⟨[], rfl⟩
    | drop => exact ⟨[], rfl⟩
    | swap => exact ⟨[], rfl⟩
    | call => exact ⟨[], rfl⟩
    | dip => exact ⟨[], rfl⟩
    | compose => exact ⟨[], rfl⟩
    | quote => exact ⟨[], rfl⟩
    | ifThenElse => exact ⟨[], rfl⟩
    | @word name input output h =>
        rcases h with ⟨entry, entryEq, _, _⟩
        refine ⟨[.word name entry.type], ?_⟩
        simp [resolveKernelAtomDependencies, entryEq]
    | @prim name specification h =>
        refine ⟨[.primitive name specification.input specification.output], ?_⟩
        simp [resolveKernelAtomDependencies, h]

  theorem programTyping_resolves_kernel_effect_dependencies
      (typing : ProgramTyping gamma dictionary body input output) :
      ∃ dependencies,
        resolveKernelProgramDependencies gamma dictionary body = some dependencies := by
    cases typing with
    | empty => exact ⟨[], rfl⟩
    | cons headTyping tailTyping =>
        rcases atomTyping_resolves_kernel_effect_dependencies headTyping with
          ⟨headDependencies, headResolved⟩
        rcases programTyping_resolves_kernel_effect_dependencies tailTyping with
          ⟨tailDependencies, tailResolved⟩
        refine ⟨headDependencies ++ tailDependencies, ?_⟩
        simp [resolveKernelProgramDependencies, headResolved, tailResolved]
end

theorem programTyping_has_kernel_effect_boundary
    (typing : ProgramTyping gamma dictionary body input output) :
    Nonempty (KernelEffectBoundary gamma dictionary body input output) := by
  rcases programTyping_resolves_kernel_effect_dependencies typing with
    ⟨dependencies, resolved⟩
  exact ⟨{ dependencies, resolved, typing }⟩
inductive KernelObligationResult where
  | unchecked
  | accepted
  | rejected (reason : String)
  deriving BEq, Repr

structure KernelWordReference where
  name : String
  type : WordType
  deriving BEq, Repr

structure KernelWordObligation where
  private mk ::
  private word : String
  private body : Program
  referencedSignatures : List KernelWordReference
  private requiredPremises : List KernelEffectDependency
  private checker : String
  private status : KernelObligationResult
  private verified : Bool
  private verifiedWord : String
  private verifiedBody : Program
  private verifiedPremises : List KernelEffectDependency
  deriving BEq, Repr
def KernelWordObligation.result
    (obligation : KernelWordObligation) : KernelObligationResult :=
  obligation.status

def KernelEffectDependency.toReference :
    KernelEffectDependency → Option KernelWordReference
  | .word name type => some { name, type }
  | .primitive _ _ _ => none

def kernelWordReferences : List KernelEffectDependency → List KernelWordReference
  | [] => []
  | dependency :: rest =>
      match dependency.toReference with
      | some reference => reference :: kernelWordReferences rest
      | none => kernelWordReferences rest

def checkedKernelWordObligation (name : String) (dictionary : Dictionary)
    (entry : WordEntry) (hlookup : dictionary name = some entry)
    (boundary : KernelEffectBoundary gamma dictionary entry.body
      entry.type.input entry.type.output) : KernelWordObligation :=
  { word := name
    body := entry.body
    referencedSignatures := kernelWordReferences boundary.dependencies
    requiredPremises := boundary.dependencies
    checker := "ProgramTyping"
    status := .accepted
    verified := true
    verifiedWord := name
    verifiedBody := entry.body
    verifiedPremises := boundary.dependencies }
def uncheckedKernelWordObligation (word : String) : KernelWordObligation :=
  { word, body := .empty, referencedSignatures := [], requiredPremises := [],
    checker := "unchecked", status := .unchecked, verified := false,
    verifiedWord := word, verifiedBody := .empty, verifiedPremises := [] }
def rejectedKernelWordObligation (word : String) (reason : String) :
    KernelWordObligation :=
  { word, body := .empty, referencedSignatures := [], requiredPremises := [],
    checker := "rejected", status := .rejected reason, verified := false,
    verifiedWord := word, verifiedBody := .empty, verifiedPremises := [] }


def composeKernelObligationResults :
    List KernelWordObligation → KernelObligationResult
  | [] => .accepted
  | obligation :: rest =>
      match obligation.status with
      | .rejected reason => .rejected reason
      | .unchecked =>
          match composeKernelObligationResults rest with
          | .rejected reason => .rejected reason
          | _ => .unchecked
      | .accepted =>
          if obligation.verified then
            composeKernelObligationResults rest
          else
            .unchecked

structure KernelVocabularyObligation where
  private mk ::
  private entries : List KernelWordObligation
  deriving BEq, Repr

def KernelVocabularyObligation.words
    (vocabulary : KernelVocabularyObligation) : List KernelWordObligation :=
  vocabulary.entries

def KernelVocabularyObligation.result
    (vocabulary : KernelVocabularyObligation) : KernelObligationResult :=
  composeKernelObligationResults vocabulary.entries

def composeKernelObligations
    (words : List KernelWordObligation) : KernelVocabularyObligation :=
  { entries := words }

def kernelNameMember (name : String) : List String → Bool
  | [] => false
  | head :: tail => name == head || kernelNameMember name tail

def kernelReferenceDependsOnAny (names : List String) :
    List KernelWordReference → Bool
  | [] => false
  | reference :: rest =>
      kernelNameMember reference.name names || kernelReferenceDependsOnAny names rest

def kernelObligationDependsOnAny (names : List String)
    (obligation : KernelWordObligation) : Bool :=
  kernelNameMember obligation.word names ||
    kernelReferenceDependsOnAny names
      (kernelWordReferences obligation.requiredPremises)

def kernelAppendName (names : List String) (name : String) : List String :=
  if kernelNameMember name names then names else names ++ [name]

def expandKernelAffectedNames (obligations : List KernelWordObligation)
    (names : List String) : List String :=
  obligations.foldl (fun expanded obligation =>
    if kernelObligationDependsOnAny expanded obligation then
      kernelAppendName expanded obligation.word
    else
      expanded) names

def kernelAffectedNamesFuel (obligations : List KernelWordObligation) :
    Nat → List String → List String
  | 0, names => names
  | fuel + 1, names =>
      let expanded := expandKernelAffectedNames obligations names
      if expanded.length == names.length then
        expanded
      else
        kernelAffectedNamesFuel obligations fuel expanded

def affectedKernelWordNames (changed : String)
    (obligations : List KernelWordObligation) : List String :=
  kernelAffectedNamesFuel obligations obligations.length [changed]

def invalidateKernelWordObligations (changed : String)
    (obligations : List KernelWordObligation) : List KernelWordObligation :=
  let affected := affectedKernelWordNames changed obligations
  obligations.map (fun obligation =>
    if kernelNameMember obligation.word affected then
      { obligation with status := .unchecked, verified := false }
    else
      obligation)

end Firth.Interpreter
