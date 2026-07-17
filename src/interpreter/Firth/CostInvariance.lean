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

theorem programAppend_assoc (left middle right : Program) :
    left.append (middle.append right) = (left.append middle).append right := by
  cases left with
  | empty => rfl
  | cons head tail =>
      simp [Program.append]
      exact programAppend_assoc tail middle right

theorem programAppend_push_assoc (body rest suffix : Program) (value : Value) :
    body.append (Program.cons (Atom.push value) (rest.append suffix)) =
      (body.append (Program.cons (Atom.push value) rest)).append suffix := by
  exact programAppend_assoc body (Program.cons (Atom.push value) rest) suffix

theorem step_append_congruence (gamma : Gamma) (dictionary : Dictionary)
    (costs : CostTable) (suffix : Program) (stack : Stack) (atom : Atom)
    (rest : Program) (next : Config) (cost : Nat)
    (h : step gamma dictionary costs
      { stack := stack, program := .cons atom rest } = .stepped next cost) :
    step gamma dictionary costs
        { stack := stack, program := (Program.cons atom rest).append suffix } =
      .stepped { stack := next.stack, program := next.program.append suffix } cost := by
  cases atom <;> simp only [Program.append, step] at h ⊢
  all_goals try split at h
  all_goals try split at h
  all_goals try split at h
  all_goals try split at h
  all_goals try simp_all
  all_goals rcases h with ⟨rfl, rfl⟩ <;> simp [programAppend_assoc]
  all_goals try apply programAppend_push_assoc

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

theorem run_terminal_to_trace (gamma : Gamma) (dictionary : Dictionary)
    (costs : CostTable) (fuel : Nat) (start finish : Config)
    (steps cost : Nat)
    (h : run gamma dictionary costs fuel start = .terminal finish steps cost) :
    ∃ trace : Trace gamma dictionary costs start finish,
      traceLength trace = steps ∧ traceCost trace = cost := by
  induction fuel generalizing start finish steps cost with
  | zero =>
      cases start with
      | mk stack program =>
          cases program with
          | empty =>
              simp [run] at h
              rcases h with ⟨rfl, rfl, rfl⟩
              exact ⟨.nil _, rfl, rfl⟩
          | cons atom rest =>
              simp only [run] at h
              generalize hs : step gamma dictionary costs
                { stack := stack, program := .cons atom rest } = result at h
              cases result with
              | terminal config =>
                  cases atom <;> simp only [step] at hs
                  all_goals try split at hs
                  all_goals try split at hs
                  all_goals try split at hs
                  all_goals try split at hs
                  all_goals cases hs
              | stuck config => cases h
              | stepped next stepCost => cases h
  | succ fuel ih =>
      rw [run] at h
      generalize hs : step gamma dictionary costs start = result at h
      cases result with
      | terminal config =>
          cases start with
          | mk stack program =>
              cases program with
              | empty =>
                  simp [step] at hs
                  cases hs
                  cases h
                  exact ⟨.nil { stack := stack, program := .empty }, rfl, rfl⟩
              | cons atom rest =>
                  cases atom <;> simp only [step] at hs
                  all_goals try split at hs
                  all_goals try split at hs
                  all_goals try split at hs
                  all_goals try split at hs
                  all_goals cases hs
      | stuck config =>
          simp_all
      | stepped next stepCost =>
          cases recursive : run gamma dictionary costs fuel next with
          | terminal final tailSteps tailCost =>
              simp [recursive] at h
              rcases h with ⟨rfl, rfl, rfl⟩
              rcases ih (start := next) (finish := final)
                (steps := tailSteps) (cost := tailCost) recursive with
                ⟨tail, lengthTail, costTail⟩
              refine ⟨.cons stepCost hs tail, ?_, ?_⟩
              · simp [traceLength, lengthTail, Nat.add_comm]
              · simp [traceCost, costTail, Nat.add_comm]
          | stuck config tailSteps tailCost =>
              simp [recursive] at h
          | outOfFuel config tailSteps tailCost =>
              simp [recursive] at h

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

example : executableCostChecks.all id = true := by decide

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

example : executableTraceCostChecks.all id = true := by decide

theorem step_program_append_congruence (gamma : Gamma) (dictionary : Dictionary)
    (costs : CostTable) (suffix : Program) (stack : Stack) (program : Program)
    (next : Config) (cost : Nat)
    (h : step gamma dictionary costs { stack := stack, program := program } =
      .stepped next cost) :
    step gamma dictionary costs { stack := stack, program := program.append suffix } =
      .stepped { stack := next.stack, program := next.program.append suffix } cost := by
  cases program with
  | empty => simp [step] at h
  | cons atom rest =>
      exact step_append_congruence gamma dictionary costs suffix stack atom rest next cost h

theorem run_append_lift (gamma : Gamma) (dictionary : Dictionary)
    (costs : CostTable) (fuel₁ fuel₂ : Nat) (p₁ p₂ : Program)
    (initialStack boundaryStack finalStack : Stack) (steps₁ cost₁ steps₂ cost₂ : Nat)
    (h : run gamma dictionary costs fuel₁
      { stack := initialStack, program := p₁ } =
      .terminal { stack := boundaryStack, program := .empty } steps₁ cost₁)
    (h₂ : run gamma dictionary costs fuel₂
      { stack := boundaryStack, program := p₂ } =
      .terminal { stack := finalStack, program := .empty } steps₂ cost₂) :
    run gamma dictionary costs (fuel₂ + steps₁)
      { stack := initialStack, program := p₁.append p₂ } =
      .terminal { stack := finalStack, program := .empty }
        (steps₁ + steps₂) (cost₁ + cost₂) := by
  induction fuel₁ generalizing initialStack boundaryStack p₁ steps₁ cost₁ with
  | zero =>
      cases p₁ with
      | empty =>
          simp [run] at h
          rcases h with ⟨rfl, rfl, rfl⟩
          simpa [Program.append, Nat.add_zero] using h₂
      | cons atom rest =>
          simp only [run] at h
          generalize hs : step gamma dictionary costs
            { stack := initialStack, program := .cons atom rest } = result at h
          cases result with
          | terminal config =>
              cases atom <;> simp only [step] at hs
              all_goals try split at hs
              all_goals try split at hs
              all_goals try split at hs
              all_goals try split at hs
              all_goals cases hs
          | stuck config => simp_all
          | stepped next stepCost => simp_all
  | succ fuel₁ ih =>
      rw [run] at h
      generalize hs : step gamma dictionary costs
        { stack := initialStack, program := p₁ } = result at h
      cases result with
      | terminal config =>
          cases p₁ with
          | empty =>
              simp [step] at hs
              cases hs
              cases h
              simpa [Program.append, Nat.add_zero] using h₂
          | cons atom rest =>
              cases atom <;> simp only [step] at hs
              all_goals try split at hs
              all_goals try split at hs
              all_goals try split at hs
              all_goals try split at hs
              all_goals cases hs
      | stuck config => simp_all
      | stepped next stepCost =>
          cases recursive : run gamma dictionary costs fuel₁ next with
          | terminal final tailSteps tailCost =>
              simp [recursive] at h
              rcases h with ⟨rfl, rfl, rfl⟩
              have liftedStep := step_program_append_congruence gamma dictionary costs p₂
                initialStack p₁ next stepCost hs
              rw [← Nat.add_assoc fuel₂ tailSteps 1, run, liftedStep]
              simp only
              rw [ih next.program next.stack boundaryStack tailSteps tailCost recursive h₂]
              simp [Nat.add_comm, Nat.add_left_comm, Nat.add_assoc]
          | stuck config tailSteps tailCost => simp [recursive] at h
          | outOfFuel config tailSteps tailCost => simp [recursive] at h

theorem seq_execution_decomposes
    {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}
    (fuel₁ fuel₂ : Nat) (p₁ p₂ : Program)
    (initialStack boundaryStack finalStack : Stack)
    (steps₁ cost₁ steps₂ cost₂ : Nat)
    (first : run gamma dictionary costs fuel₁
      { stack := initialStack, program := p₁ } =
      .terminal { stack := boundaryStack, program := .empty } steps₁ cost₁)
    (second : run gamma dictionary costs fuel₂
      { stack := boundaryStack, program := p₂ } =
      .terminal { stack := finalStack, program := .empty } steps₂ cost₂) :
    run gamma dictionary costs (fuel₂ + steps₁)
      { stack := initialStack, program := p₁.append p₂ } =
      .terminal { stack := finalStack, program := .empty }
        (steps₁ + steps₂) (cost₁ + cost₂) := by
  exact run_append_lift gamma dictionary costs fuel₁ fuel₂ p₁ p₂
    initialStack boundaryStack finalStack steps₁ cost₁ steps₂ cost₂ first second

theorem seq_cost_composes
    {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}
    (fuel₁ fuel₂ : Nat) (p₁ p₂ : Program)
    (initialStack boundaryStack finalStack : Stack)
    (steps₁ cost₁ steps₂ cost₂ totalSteps totalCost : Nat)
    (first : run gamma dictionary costs fuel₁
      { stack := initialStack, program := p₁ } =
      .terminal { stack := boundaryStack, program := .empty } steps₁ cost₁)
    (second : run gamma dictionary costs fuel₂
      { stack := boundaryStack, program := p₂ } =
      .terminal { stack := finalStack, program := .empty } steps₂ cost₂)
    (combined : run gamma dictionary costs (fuel₂ + steps₁)
      { stack := initialStack, program := p₁.append p₂ } =
      .terminal { stack := finalStack, program := .empty } totalSteps totalCost) :
    totalSteps = steps₁ + steps₂ ∧ totalCost = cost₁ + cost₂ := by
  have expected := seq_execution_decomposes fuel₁ fuel₂ p₁ p₂ initialStack
    boundaryStack finalStack steps₁ cost₁ steps₂ cost₂ first second
  rw [expected] at combined
  cases combined
  exact ⟨rfl, rfl⟩

theorem seq_execution_splits_runs
    {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}
    (fuel₁ fuel₂ : Nat) (p₁ p₂ : Program)
    (initialStack boundaryStack finalStack : Stack)
    (steps₁ cost₁ steps₂ cost₂ totalSteps totalCost : Nat)
    (first : run gamma dictionary costs fuel₁
      { stack := initialStack, program := p₁ } =
      .terminal { stack := boundaryStack, program := .empty } steps₁ cost₁)
    (second : run gamma dictionary costs fuel₂
      { stack := boundaryStack, program := p₂ } =
      .terminal { stack := finalStack, program := .empty } steps₂ cost₂)
    (combined : run gamma dictionary costs (fuel₂ + steps₁)
      { stack := initialStack, program := p₁.append p₂ } =
      .terminal { stack := finalStack, program := .empty } totalSteps totalCost) :
    ∃ isolatedSteps isolatedCost,
      totalSteps = steps₁ + isolatedSteps ∧
      totalCost = cost₁ + isolatedCost ∧
      isolatedSteps = steps₂ ∧ isolatedCost = cost₂ := by
  rcases seq_cost_composes fuel₁ fuel₂ p₁ p₂ initialStack boundaryStack finalStack
    steps₁ cost₁ steps₂ cost₂ totalSteps totalCost first second combined with
    ⟨hs, hc⟩
  exact ⟨steps₂, cost₂, hs, hc, rfl, rfl⟩

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
