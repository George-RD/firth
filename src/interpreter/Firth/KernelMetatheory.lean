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

end Firth.Interpreter
