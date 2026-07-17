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

def traceLength {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}
    {start finish : Config} :
    Trace gamma dictionary costs start finish → Nat
  | .nil _ => 0
  | .cons _ _ tail => Nat.succ (traceLength tail)

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

theorem programAppend_traceCost_decomposes
    {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}
    (p₁ p₂ : Program) (initialStack boundaryStack : Stack) (finish : Config)
    (first : Trace gamma dictionary costs
      { stack := initialStack, program := p₁.append p₂ }
      { stack := boundaryStack, program := p₂ })
    (second : Trace gamma dictionary costs
      { stack := boundaryStack, program := p₂ } finish) :
    traceCost (Trace.trans first second) =
      sequenceCost id (traceCosts first) + sequenceCost id (traceCosts second) := by
  rw [traceCost_trans, traceCost_eq_sequenceCost first,
    traceCost_eq_sequenceCost second]

theorem programAppend_traceCost_sequenceCost
    {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}
    (p₁ p₂ : Program) (initialStack boundaryStack : Stack) (finish : Config)
    (first : Trace gamma dictionary costs
      { stack := initialStack, program := p₁.append p₂ }
      { stack := boundaryStack, program := p₂ })
    (second : Trace gamma dictionary costs
      { stack := boundaryStack, program := p₂ } finish) :
    traceCost (Trace.trans first second) =
      sequenceCost id (traceCosts first ++ traceCosts second) := by
  rw [programAppend_traceCost_decomposes p₁ p₂ initialStack boundaryStack finish first second,
    sequenceCost_append]

theorem run_agrees_with_terminal_trace
    (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    {start finish : Config} (trace : Trace gamma dictionary costs start finish)
    (terminal : finish.program = .empty) :
    run gamma dictionary costs (traceLength trace) start =
      .terminal finish (traceLength trace) (traceCost trace) := by
  induction trace with
  | nil config =>
      cases config with
      | mk stack program =>
          cases program with
          | empty => rfl
          | cons head tail => cases terminal
  | @cons start middle finish cost stepProof tail ih =>
      cases start with
      | mk stack program =>
          cases program with
          | empty =>
              simp [step] at stepProof
          | cons atom rest =>
              simp only [traceLength, traceCost]
              rw [run]
              rw [stepProof]
              simp only
              rw [ih terminal]
              simp [traceLength, traceCost, Nat.add_comm, Nat.add_left_comm,
                Nat.add_assoc]

def executableCostChecks : List Bool :=
  [ chargedCost defaultCosts (.lit (.nat 1)) == 1,
    chargedCost { defaultCosts with atom := fun _ => 7 }
      (.quotation .empty) == 7,
    chargedCost { defaultCosts with primitive := fun _ => 5 } (.prim "p") == 5,
    chargedCost { defaultCosts with unfold := 4 } (.word "w") == 4,
    chargedCost { defaultCosts with atom := fun _ => 99 }
      (.push (.literal (.nat 1))) == 0 ]

example : executableCostChecks.all id = true := by native_decide

def executableTraceCostChecks : List Bool :=
  [ match run defaultGamma emptyDictionary defaultCosts 10
      { stack := [],
        program := .cons (.quotation (.cons (.lit (.nat 1)) .empty))
          (.cons .call .empty) } with
    | .terminal _ _ cost => cost == 3
    | _ => false,
    match run defaultGamma emptyDictionary
      { defaultCosts with atom := fun _ => 99 } 10
      { stack := [], program := .cons (.push (.literal (.nat 1))) .empty } with
    | .terminal _ _ cost => cost == 0
    | _ => false ]

example : executableTraceCostChecks.all id = true := by native_decide

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
