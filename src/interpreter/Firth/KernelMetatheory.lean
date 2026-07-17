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

end Firth.Interpreter
