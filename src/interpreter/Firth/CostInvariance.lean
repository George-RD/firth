import Firth.KernelMetatheory

namespace Firth.Interpreter

/-!
  Cost accounting for the executable kernel transition relation.

  The frozen kernel table charges kernel atoms, primitive dispatch, and word
  unfolding.  `push` is the administrative exception recorded by the
  registered gap decision and is therefore charged zero.
-/

def chargedCost (costs : CostTable) : Atom → Nat
  | .push _ => 0
  | .prim primitive => costs.primitive primitive
  | .word _ => costs.unfold
  | atom => costs.atom atom

theorem step_cost_matches_kappa (gamma : Gamma) (dictionary : Dictionary)
    (costs : CostTable) (stack : Stack) (atom : Atom) (rest : Program)
    (next : Config) (cost : Nat)
    (h : step gamma dictionary costs
      { stack := stack, program := .cons atom rest } = .stepped next cost) :
    cost = chargedCost costs atom := by
  cases atom <;> simp only [step, chargedCost] at h ⊢
  all_goals try split at h
  all_goals try split at h
  all_goals try split at h
  all_goals try split at h
  all_goals try split at h
  all_goals simp_all

theorem successor_cost_matches_kappa
    (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (stack : Stack) (atom : Atom) (rest : Program) (next : Config)
    (h : HasSuccessor gamma dictionary costs
      { stack := stack, program := .cons atom rest } next) :
    ∃ cost, step gamma dictionary costs
        { stack := stack, program := .cons atom rest } = .stepped next cost ∧
      cost = chargedCost costs atom := by
  rcases h with ⟨actualCost, h⟩
  exact ⟨actualCost, h,
    step_cost_matches_kappa gamma dictionary costs stack atom rest next actualCost h⟩

inductive Trace (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) :
    Config → Config → Type where
  | nil (config : Config) : Trace gamma dictionary costs config config
  | cons {start middle finish : Config} (cost : Nat)
      (stepProof : step gamma dictionary costs start = .stepped middle cost)
      (tail : Trace gamma dictionary costs middle finish) :
      Trace gamma dictionary costs start finish

def Trace.trans {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}
    {start middle finish : Config} :
    Trace gamma dictionary costs start middle →
      Trace gamma dictionary costs middle finish →
      Trace gamma dictionary costs start finish
  | .nil _, right => right
  | .cons cost stepProof tail, right =>
      .cons cost stepProof (Trace.trans tail right)

def traceCosts {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}
    {start finish : Config} :
    Trace gamma dictionary costs start finish → List Nat
  | .nil _ => []
  | .cons cost _ tail => cost :: traceCosts tail

def traceCost {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}
    {start finish : Config} :
    Trace gamma dictionary costs start finish → Nat
  | .nil _ => 0
  | .cons cost _ tail => cost + traceCost tail

theorem traceCost_eq_sequenceCost {gamma : Gamma} {dictionary : Dictionary}
    {costs : CostTable} {start finish : Config} (trace : Trace gamma dictionary costs start finish) :
    traceCost trace = sequenceCost id (traceCosts trace) := by
  induction trace with
  | nil config => rfl
  | cons cost stepProof tail ih =>
      simp [traceCost, traceCosts, sequenceCost, ih]

theorem traceCost_trans {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}
    {start middle finish : Config}
    (left : Trace gamma dictionary costs start middle)
    (right : Trace gamma dictionary costs middle finish) :
    traceCost (Trace.trans left right) = traceCost left + traceCost right := by
  induction left with
  | nil config => simp [Trace.trans, traceCost]
  | cons cost stepProof tail ih =>
      simp [Trace.trans, traceCost, ih, Nat.add_assoc]

theorem traceStep_cost_matches_kappa {gamma : Gamma} {dictionary : Dictionary}
    {costs : CostTable} {start middle : Config} (cost : Nat)
    (stepProof : step gamma dictionary costs start = .stepped middle cost)
    :
    ∃ atom rest stack,
      start = { stack := stack, program := .cons atom rest } ∧
        cost = chargedCost costs atom := by
  cases start with
  | mk stack program =>
      cases program with
      | empty => simp [step] at stepProof
      | cons atom rest =>
          refine ⟨atom, rest, stack, rfl, ?_⟩
          exact step_cost_matches_kappa gamma dictionary costs stack atom rest middle cost stepProof

end Firth.Interpreter
