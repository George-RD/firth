import Firth.Interpreter

namespace Firth.Interpreter

/-!
  The executable interpreter is the single definition of the v0.1 transition
  system.  This file records the metatheory that is already meaningful for
  that definition.  The typing and ownership judgements are deliberately not
  reconstructed here: the current interpreter does not contain them.
-/

def HasSuccessor (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (config : Config) (next : Config) : Prop :=
  ∃ cost, step gamma dictionary costs config = .stepped next cost

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
