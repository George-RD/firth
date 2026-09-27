import Firth.CostInvariance
import FirthReferenceRun

/-!
A program logic for kernel programs, with cost.

`Runs gamma dictionary costs program before after steps cost` says that
`program`, started on the stack `before` and followed by any continuation,
executes to exactly that continuation on the stack `after`, in `steps`
transitions charging `cost`. Quantifying over the continuation is what makes
the relation compose: a word body, a quotation body or a program prefix is
proved once and reused wherever it runs.

The rules below cover every kernel atom, sequencing, `if`, `dip`, quotation
calls and word unfolding. Recursion is proved by induction on a measure
(`induction_on_measure`), which is ordinary well-founded induction. There is no
separate recursion rule to trust.

`run_of_runs` is the adequacy theorem: whatever a `Runs` fact says is what the
reference interpreter's `run` returns, given at least `steps` fuel. So a proof
stated with `Runs` about an exported word (`src/exports/`) is a statement about
what the reference runner, and by differential testing the VM, does with the
program whose body digest the export records.

The logic is total correctness: a `Runs` fact includes termination and the
absence of any stuck state, including a faulting sequence index.
-/

namespace Firth.Logic
open Firth.Interpreter

section Reaches
variable {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}

/-- `start` reaches `finish` in exactly `steps` transitions charging `cost`. -/
def Reaches (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (start finish : Config) (steps cost : Nat) : Prop :=
  ∃ trace : Trace gamma dictionary costs start finish,
    traceLength trace = steps ∧ traceCost trace = cost

theorem Reaches.refl (config : Config) : Reaches gamma dictionary costs config config 0 0 :=
  ⟨.nil config, rfl, rfl⟩

theorem Reaches.head {start middle finish : Config} {stepCost steps cost : Nat}
    (first : step gamma dictionary costs start = .stepped middle stepCost)
    (rest : Reaches gamma dictionary costs middle finish steps cost) :
    Reaches gamma dictionary costs start finish (steps + 1) (stepCost + cost) := by
  rcases rest with ⟨trace, hLength, hCost⟩
  exact ⟨.cons stepCost first trace, by simp [traceLength, hLength],
    by simp [traceCost, hCost]⟩

theorem traceLength_trans {start middle finish : Config}
    (first : Trace gamma dictionary costs start middle)
    (second : Trace gamma dictionary costs middle finish) :
    traceLength (Trace.trans first second) = traceLength first + traceLength second := by
  induction first with
  | nil config => simp [Trace.trans, traceLength]
  | cons stepCost stepProof tail ih =>
      simp only [Trace.trans, traceLength, ih second]
      omega

theorem Reaches.trans {start middle finish : Config} {steps₁ cost₁ steps₂ cost₂ : Nat}
    (left : Reaches gamma dictionary costs start middle steps₁ cost₁)
    (right : Reaches gamma dictionary costs middle finish steps₂ cost₂) :
    Reaches gamma dictionary costs start finish (steps₁ + steps₂) (cost₁ + cost₂) := by
  rcases left with ⟨first, hLength₁, hCost₁⟩
  rcases right with ⟨second, hLength₂, hCost₂⟩
  exact ⟨Trace.trans first second, by rw [traceLength_trans, hLength₁, hLength₂],
    by rw [traceCost_trans, hCost₁, hCost₂]⟩

end Reaches

theorem programAppend_empty : (program : Program) → program.append .empty = program
  | .empty => rfl
  | .cons head tail => by simp [Program.append, programAppend_empty tail]

/-- More fuel never changes a terminal result. -/
theorem run_terminal_more_fuel (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    {fuel : Nat} {start finish : Config} {steps cost : Nat}
    (h : run gamma dictionary costs fuel start = .terminal finish steps cost) (extra : Nat) :
    run gamma dictionary costs (fuel + extra) start = .terminal finish steps cost := by
  induction fuel generalizing start finish steps cost with
  | zero =>
      rw [run] at h
      rw [Nat.zero_add]
      cases hs : step gamma dictionary costs start with
      | terminal config =>
          simp only [hs, RunResult.terminal.injEq] at h
          obtain ⟨rfl, rfl, rfl⟩ := h
          cases extra <;> simp [run, hs]
      | stuck config => simp [hs] at h
      | stepped next stepCost => simp [hs] at h
  | succ fuel ih =>
      rw [Nat.add_right_comm, run]
      rw [run] at h
      cases hs : step gamma dictionary costs start with
      | terminal config => simpa [hs] using h
      | stuck config => simp [hs] at h
      | stepped next stepCost =>
          simp only [hs] at h ⊢
          cases recursive : run gamma dictionary costs fuel next with
          | terminal final tailSteps tailCost =>
              rw [ih recursive]
              simpa [recursive] using h
          | stuck config tailSteps tailCost => simp [recursive] at h
          | outOfFuel config tailSteps tailCost => simp [recursive] at h

section Runs
variable {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}

/-- `program` takes `before` to `after` in `steps` transitions charging `cost`,
whatever continuation follows it. -/
def Runs (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (program : Program) (before after : Stack) (steps cost : Nat) : Prop :=
  ∀ rest, Reaches gamma dictionary costs
    { stack := before, program := program.append rest } { stack := after, program := rest }
    steps cost

/-- Adequacy: the reference interpreter's `run` returns what `Runs` states. -/
theorem run_of_runs {program : Program} {before after : Stack} {steps cost : Nat}
    (h : Runs gamma dictionary costs program before after steps cost) (extra : Nat) :
    run gamma dictionary costs (steps + extra) { stack := before, program := program } =
      .terminal { stack := after, program := .empty } steps cost := by
  have h := h .empty
  rw [programAppend_empty] at h
  rcases h with ⟨trace, hLength, hCost⟩
  have exact := run_agrees_with_terminal_trace gamma dictionary costs trace rfl
  rw [hLength, hCost] at exact
  exact run_terminal_more_fuel gamma dictionary costs exact extra

/-- Restates the step and cost indices, typically after `omega`. -/
theorem Runs.congr {program : Program} {before after : Stack} {steps cost steps' cost' : Nat}
    (h : Runs gamma dictionary costs program before after steps cost)
    (hSteps : steps = steps') (hCost : cost = cost') :
    Runs gamma dictionary costs program before after steps' cost' := by
  subst hSteps hCost
  exact h

/-- Restates the stacks, typically after arithmetic on the values in them. -/
theorem Runs.congr_stacks {program : Program} {before after before' after' : Stack}
    {steps cost : Nat}
    (h : Runs gamma dictionary costs program before after steps cost)
    (hBefore : before = before') (hAfter : after = after') :
    Runs gamma dictionary costs program before' after' steps cost := by
  subst hBefore hAfter
  exact h

theorem runs_empty (stack : Stack) : Runs gamma dictionary costs .empty stack stack 0 0 :=
  fun rest => Reaches.refl { stack := stack, program := rest }

/-- Sequencing. -/
theorem runs_append {first second : Program} {before middle after : Stack}
    {steps₁ cost₁ steps₂ cost₂ : Nat}
    (left : Runs gamma dictionary costs first before middle steps₁ cost₁)
    (right : Runs gamma dictionary costs second middle after steps₂ cost₂) :
    Runs gamma dictionary costs (first.append second) before after
      (steps₁ + steps₂) (cost₁ + cost₂) := by
  intro rest
  rw [← programAppend_assoc]
  exact (left (second.append rest)).trans (right rest)

/-- Sequencing one atom in front of a program. -/
theorem runs_cons {atom : Atom} {tail : Program} {before middle after : Stack}
    {steps₁ cost₁ steps₂ cost₂ : Nat}
    (head : Runs gamma dictionary costs (.cons atom .empty) before middle steps₁ cost₁)
    (rest : Runs gamma dictionary costs tail middle after steps₂ cost₂) :
    Runs gamma dictionary costs (.cons atom tail) before after
      (steps₁ + steps₂) (cost₁ + cost₂) :=
  runs_append (first := .cons atom .empty) head rest

/-- Any atom whose single step leaves the continuation untouched. -/
theorem runs_simple {atom : Atom} {before after : Stack} {cost : Nat}
    (h : ∀ rest, step gamma dictionary costs { stack := before, program := .cons atom rest } =
      .stepped { stack := after, program := rest } cost) :
    Runs gamma dictionary costs (.cons atom .empty) before after 1 cost := by
  intro rest
  have := Reaches.head (h rest) (Reaches.refl (gamma := gamma) (dictionary := dictionary)
    (costs := costs) { stack := after, program := rest })
  simpa [Program.append] using this

theorem runs_lit {literal : Literal} {type : BaseType} (stack : Stack)
    (h : gamma.literalType literal = some type) :
    Runs gamma dictionary costs (.cons (.lit literal) .empty) stack (.literal literal :: stack) 1
      (costs.atom (.lit literal)) :=
  runs_simple fun _ => by simp [step, h]

theorem runs_push (value : Value) (stack : Stack) :
    Runs gamma dictionary costs (.cons (.push value) .empty) stack (value :: stack) 1 0 :=
  runs_simple fun _ => by simp [step]

theorem runs_quotation (body : Program) (stack : Stack) :
    Runs gamma dictionary costs (.cons (.quotation body) .empty) stack
      (.quotation body (programUsage body) :: stack) 1 (costs.atom (.quotation body)) :=
  runs_simple fun _ => by simp [step]

theorem runs_dup (value : Value) (tail : Stack) :
    Runs gamma dictionary costs (.cons .dup .empty) (value :: tail) (value :: value :: tail) 1
      (costs.atom .dup) :=
  runs_simple fun _ => by simp [step]

theorem runs_drop (value : Value) (tail : Stack) :
    Runs gamma dictionary costs (.cons .drop .empty) (value :: tail) tail 1 (costs.atom .drop) :=
  runs_simple fun _ => by simp [step]

theorem runs_swap (second first : Value) (tail : Stack) :
    Runs gamma dictionary costs (.cons .swap .empty) (second :: first :: tail)
      (first :: second :: tail) 1 (costs.atom .swap) :=
  runs_simple fun _ => by simp [step]

theorem runs_quote (value : Value) (tail : Stack) :
    Runs gamma dictionary costs (.cons .quote .empty) (value :: tail)
      (.quotation (.cons (.push value) .empty) (quotationUsage value) :: tail) 1
      (costs.atom .quote) :=
  runs_simple fun _ => by simp [step]

theorem runs_compose (first second : Program) (usage₁ usage₂ : Usage) (tail : Stack) :
    Runs gamma dictionary costs (.cons .compose .empty)
      (.quotation second usage₂ :: .quotation first usage₁ :: tail)
      (.quotation (first.append second)
        (if usage₁ == .linear || usage₂ == .linear then .linear else .many) :: tail) 1
      (costs.atom .compose) :=
  runs_simple fun _ => by simp [step]

/-- A primitive whose delta succeeds. A delta that returns `none` is stuck, and
a stuck program has no `Runs` fact. -/
theorem runs_prim {primitive : Prim} {specification : PrimitiveSpec} {before after : Stack}
    (hSpec : gamma.primitive primitive = some specification)
    (hDelta : specification.delta before = some after) :
    Runs gamma dictionary costs (.cons (.prim primitive) .empty) before after 1
      (costs.primitive primitive) :=
  runs_simple fun _ => by simp [step, hSpec, hDelta]

/-- Calling a quotation runs its body. -/
theorem runs_call {body : Program} {usage : Usage} {tail after : Stack} {steps cost : Nat}
    (h : Runs gamma dictionary costs body tail after steps cost) :
    Runs gamma dictionary costs (.cons .call .empty) (.quotation body usage :: tail) after
      (steps + 1) (costs.atom .call + cost) := by
  intro rest
  have first : step gamma dictionary costs
      { stack := .quotation body usage :: tail, program := .cons .call rest } =
      .stepped { stack := tail, program := body.append rest } (costs.atom .call) := by
    simp [step]
  simpa [Program.append] using Reaches.head first (h rest)

/-- `dip` runs the quotation under the value below it, then restores the value. -/
theorem runs_dip {body : Program} {usage : Usage} {value : Value} {tail after : Stack}
    {steps cost : Nat}
    (h : Runs gamma dictionary costs body tail after steps cost) :
    Runs gamma dictionary costs (.cons .dip .empty) (.quotation body usage :: value :: tail)
      (value :: after) (steps + 2) (costs.atom .dip + cost) := by
  intro rest
  have first : step gamma dictionary costs
      { stack := .quotation body usage :: value :: tail, program := .cons .dip rest } =
      .stepped { stack := tail, program := body.append (.cons (.push value) rest) }
        (costs.atom .dip) := by
    simp [step]
  have pushed : step gamma dictionary costs
      { stack := after, program := .cons (.push value) rest } =
      .stepped { stack := value :: after, program := rest } 0 := by
    simp [step]
  have body := (h (.cons (.push value) rest)).trans
    (Reaches.head pushed (Reaches.refl { stack := value :: after, program := rest }))
  simpa [Program.append, Nat.add_assoc] using Reaches.head first body

/-- `if` runs the branch its condition selects. -/
theorem runs_if {condition : Bool} {trueBranch falseBranch : Program} {usage₁ usage₂ : Usage}
    {tail after : Stack} {steps cost : Nat}
    (h : Runs gamma dictionary costs (if condition then trueBranch else falseBranch) tail after
      steps cost) :
    Runs gamma dictionary costs (.cons .ifThenElse .empty)
      (.quotation falseBranch usage₂ :: .quotation trueBranch usage₁ ::
        .literal (.bool condition) :: tail) after (steps + 1) (costs.atom .ifThenElse + cost) := by
  intro rest
  have first : step gamma dictionary costs
      { stack := .quotation falseBranch usage₂ :: .quotation trueBranch usage₁ ::
          .literal (.bool condition) :: tail, program := .cons .ifThenElse rest } =
      .stepped
        { stack := tail
          program := (if condition then trueBranch else falseBranch).append rest }
        (costs.atom .ifThenElse) := by
    simp [step]
  simpa [Program.append] using Reaches.head first (h rest)

theorem runs_if_true {trueBranch falseBranch : Program} {usage₁ usage₂ : Usage}
    {tail after : Stack} {steps cost : Nat}
    (h : Runs gamma dictionary costs trueBranch tail after steps cost) :
    Runs gamma dictionary costs (.cons .ifThenElse .empty)
      (.quotation falseBranch usage₂ :: .quotation trueBranch usage₁ ::
        .literal (.bool true) :: tail) after (steps + 1) (costs.atom .ifThenElse + cost) :=
  runs_if (condition := true) (by simpa using h)

theorem runs_if_false {trueBranch falseBranch : Program} {usage₁ usage₂ : Usage}
    {tail after : Stack} {steps cost : Nat}
    (h : Runs gamma dictionary costs falseBranch tail after steps cost) :
    Runs gamma dictionary costs (.cons .ifThenElse .empty)
      (.quotation falseBranch usage₂ :: .quotation trueBranch usage₁ ::
        .literal (.bool false) :: tail) after (steps + 1) (costs.atom .ifThenElse + cost) :=
  runs_if (condition := false) (by simpa using h)

/-- Calling a dictionary word runs its body, charging one unfold. -/
theorem runs_word {name : String} {entry : WordEntry} {before after : Stack} {steps cost : Nat}
    (hEntry : dictionary name = some entry)
    (h : Runs gamma dictionary costs entry.body before after steps cost) :
    Runs gamma dictionary costs (.cons (.word name) .empty) before after
      (steps + 1) (costs.unfold + cost) := by
  intro rest
  have first : step gamma dictionary costs
      { stack := before, program := .cons (.word name) rest } =
      .stepped { stack := before, program := entry.body.append rest } costs.unfold := by
    simp [step, hEntry]
  simpa [Program.append] using Reaches.head first (h rest)

end Runs

/-- Recursion by a measure: to prove `P x` for every `x`, prove it for `x`
assuming it for everything of smaller measure. A recursive word's `Runs` fact
is proved this way, with the word call inside its body discharged by the
induction hypothesis. -/
theorem induction_on_measure {α : Sort _} (size : α → Nat) {P : α → Prop}
    (step : ∀ x, (∀ y, size y < size x → P y) → P x) (x : α) : P x :=
  (_root_.measure size).wf.induction x step

/-!
## Primitives under the reference runner's registry

Kernel programs name primitives by their surface names, and the reference
runner resolves them through `Firth.ReferenceRun.adapterGamma`. One lemma per
primitive states its effect under that registry.
-/

section Primitives
open Firth.ReferenceRun
variable {dictionary : Dictionary} {costs : CostTable}

private theorem adapter_prim {surface kernel : String} {specification : PrimitiveSpec}
    (hSurface : kernelPrimitive surface = some kernel)
    (hKernel : defaultGamma.primitive kernel = some specification) :
    adapterGamma.primitive surface = some specification := by
  simp [adapterGamma, hSurface, hKernel]

theorem runs_literal_int (value : Int) (stack : Stack) :
    Runs adapterGamma dictionary costs (.cons (.lit (.int value)) .empty) stack
      (.literal (.int value) :: stack) 1 (costs.atom (.lit (.int value))) :=
  runs_lit (type := .int) stack rfl

theorem runs_literal_bool (value : Bool) (stack : Stack) :
    Runs adapterGamma dictionary costs (.cons (.lit (.bool value)) .empty) stack
      (.literal (.bool value) :: stack) 1 (costs.atom (.lit (.bool value))) :=
  runs_lit (type := .bool) stack rfl

theorem runs_add (left right : Int) (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "+") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.int (left + right)) :: tail) 1 (costs.primitive "+") :=
  runs_prim (adapter_prim (kernel := "addInt") rfl rfl) rfl

theorem runs_sub (left right : Int) (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "-") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.int (left - right)) :: tail) 1 (costs.primitive "-") :=
  runs_prim (adapter_prim (kernel := "subInt") rfl rfl) rfl

theorem runs_mul (left right : Int) (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "*") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.int (left * right)) :: tail) 1 (costs.primitive "*") :=
  runs_prim (adapter_prim (kernel := "mulInt") rfl rfl) rfl

theorem runs_lt (left right : Int) (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "<") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.bool (decide (left < right))) :: tail) 1 (costs.primitive "<") :=
  runs_prim (adapter_prim (kernel := "ltInt") rfl rfl) rfl

theorem runs_eq (left right : Int) (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "=") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.bool (decide (left = right))) :: tail) 1 (costs.primitive "=") :=
  runs_prim (adapter_prim (kernel := "eqInt") rfl rfl) rfl

theorem runs_intSeq_empty (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "seq-int.empty") .empty) tail
      (.literal (.intSeq []) :: tail) 1 (costs.primitive "seq-int.empty") :=
  runs_prim (adapter_prim (kernel := "intSeqEmpty") rfl rfl) rfl

theorem runs_intSeq_len (values : List Int) (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "seq-int.len") .empty)
      (.literal (.intSeq values) :: tail) (.literal (.int values.length) :: tail) 1
      (costs.primitive "seq-int.len") :=
  runs_prim (adapter_prim (kernel := "intSeqLen") rfl rfl) rfl

/-- `seq-int.at` at an index inside the sequence. Outside it the primitive
faults, and no `Runs` fact holds. -/
theorem runs_intSeq_at {values : List Int} {index : Nat} {value : Int} (tail : Stack)
    (h : values[index]? = some value) :
    Runs adapterGamma dictionary costs (.cons (.prim "seq-int.at") .empty)
      (.literal (.int index) :: .literal (.intSeq values) :: tail)
      (.literal (.int value) :: tail) 1 (costs.primitive "seq-int.at") :=
  runs_prim (adapter_prim (kernel := "intSeqAt") rfl rfl)
    (by simp [intSeqAtDelta, elementAt?, h])

theorem runs_intSeq_push (values : List Int) (value : Int) (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "seq-int.push") .empty)
      (.literal (.int value) :: .literal (.intSeq values) :: tail)
      (.literal (.intSeq (values ++ [value])) :: tail) 1 (costs.primitive "seq-int.push") :=
  runs_prim (adapter_prim (kernel := "intSeqPush") rfl rfl) rfl

theorem runs_boolSeq_empty (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "seq-bool.empty") .empty) tail
      (.literal (.boolSeq []) :: tail) 1 (costs.primitive "seq-bool.empty") :=
  runs_prim (adapter_prim (kernel := "boolSeqEmpty") rfl rfl) rfl

theorem runs_boolSeq_len (values : List Bool) (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "seq-bool.len") .empty)
      (.literal (.boolSeq values) :: tail) (.literal (.int values.length) :: tail) 1
      (costs.primitive "seq-bool.len") :=
  runs_prim (adapter_prim (kernel := "boolSeqLen") rfl rfl) rfl

/-- `seq-bool.at` at an index inside the sequence. -/
theorem runs_boolSeq_at {values : List Bool} {index : Nat} {value : Bool} (tail : Stack)
    (h : values[index]? = some value) :
    Runs adapterGamma dictionary costs (.cons (.prim "seq-bool.at") .empty)
      (.literal (.int index) :: .literal (.boolSeq values) :: tail)
      (.literal (.bool value) :: tail) 1 (costs.primitive "seq-bool.at") :=
  runs_prim (adapter_prim (kernel := "boolSeqAt") rfl rfl)
    (by simp [boolSeqAtDelta, elementAt?, h])

theorem runs_boolSeq_push (values : List Bool) (value : Bool) (tail : Stack) :
    Runs adapterGamma dictionary costs (.cons (.prim "seq-bool.push") .empty)
      (.literal (.bool value) :: .literal (.boolSeq values) :: tail)
      (.literal (.boolSeq (values ++ [value])) :: tail) 1 (costs.primitive "seq-bool.push") :=
  runs_prim (adapter_prim (kernel := "boolSeqPush") rfl rfl) rfl

end Primitives

end Firth.Logic
