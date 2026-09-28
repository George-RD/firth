import Firth.CostInvariance
import FirthReferenceRun
import Lean.Elab.Tactic

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

/-- `pick depth` copies the value `depth` places below the top. -/
theorem runs_pick {depth : Nat} {stack : Stack} {value : Value}
    (h : stack[depth]? = some value) :
    Runs gamma dictionary costs (.cons (.pick depth) .empty) stack (value :: stack) 1
      (costs.atom (.pick depth)) :=
  runs_simple fun _ => by simp [step, h]

/-- `roll depth` moves the value `depth` places below the top to the top. -/
theorem runs_roll {depth : Nat} {stack tail : Stack} {value : Value}
    (h : rollOut stack depth = some (value, tail)) :
    Runs gamma dictionary costs (.cons (.roll depth) .empty) stack (value :: tail) 1
      (costs.atom (.roll depth)) :=
  runs_simple fun _ => by simp [step, h]

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
## Registries

`adapterGamma` is the reference runner's registry. `int64Gamma` is the same
registry with `+`, `-`, `*` and `div` faulting outside i64, as the VM's do (see the
Overflow section). `ReferenceRegistry` holds for both: they agree on literals
and on every other primitive, so the literal and non-arithmetic primitive
lemmas below hold under either.
-/

section Registries
open Firth.ReferenceRun

/-- The VM's signed 64-bit range. -/
def InInt64 (value : Int) : Prop := -9223372036854775808 ≤ value ∧ value ≤ 9223372036854775807

instance (value : Int) : Decidable (InInt64 value) := by
  unfold InInt64; exact inferInstance

/-- A binary integer primitive that faults when its result leaves i64. -/
def checkedIntDelta (operation : Int → Int → Int) : Stack → Option Stack
  | .literal (.int right) :: .literal (.int left) :: rest =>
      if InInt64 (operation left right) then
        some (.literal (.int (operation left right)) :: rest)
      else none
  | _ => none

/-- Euclidean division that faults on a zero divisor, as the reference's does,
and also when the quotient leaves i64. The only such quotient is
`-2^63 div -1`. -/
def checkedDivDelta : Stack → Option Stack
  | .literal (.int right) :: .literal (.int left) :: rest =>
      if right = 0 then none
      else if InInt64 (left / right) then some (.literal (.int (left / right)) :: rest)
      else none
  | _ => none

/-- The delta `int64Gamma` gives a surface primitive whose reference delta is
`delta`. -/
def int64Delta (primitive : Prim) (delta : Stack → Option Stack) : Stack → Option Stack :=
  if primitive = "+" then checkedIntDelta (· + ·)
  else if primitive = "-" then checkedIntDelta (· - ·)
  else if primitive = "*" then checkedIntDelta (· * ·)
  else if primitive = "div" then checkedDivDelta
  else delta

/-- Whether `int64Gamma` checks a surface primitive for i64 overflow. `mod`
is not checked: its result lies between 0 and its divisor. -/
def Int64Checked (primitive : Prim) : Prop :=
  primitive = "+" ∨ primitive = "-" ∨ primitive = "*" ∨ primitive = "div"

instance (primitive : Prim) : Decidable (Int64Checked primitive) := by
  unfold Int64Checked; exact inferInstance

/-- The reference registry with `+`, `-`, `*` and `div` checked for i64 overflow.
The checked primitives are declared `faults := true`, since an overflow is a
primitive fault on a well-typed stack, as the VM's trap is. The kernel's
progress theorem is not yet proved for this registry. -/
def int64Gamma : Gamma :=
  { adapterGamma with
    primitive := fun primitive => (adapterGamma.primitive primitive).map fun specification =>
      { specification with
        delta := int64Delta primitive specification.delta
        faults := decide (Int64Checked primitive) || specification.faults } }

/-- The checked arithmetic of `int64Gamma` is declared as faulting. -/
theorem int64Gamma_checked_faults {primitive : Prim} {specification : PrimitiveSpec}
    (hChecked : Int64Checked primitive)
    (hSpec : int64Gamma.primitive primitive = some specification) :
    specification.faults = true := by
  simp only [int64Gamma, Option.map_eq_some_iff] at hSpec
  rcases hSpec with ⟨_, _, rfl⟩
  simp [hChecked]

/-- A registry that agrees with the reference runner's on literal types and on
every primitive other than `+`, `-`, `*` and `div`. -/
class ReferenceRegistry (gamma : Gamma) : Prop where
  literalType : gamma.literalType = defaultGamma.literalType
  primitive : ∀ primitive : Prim, ¬ Int64Checked primitive →
    gamma.primitive primitive = adapterGamma.primitive primitive

instance : ReferenceRegistry adapterGamma where
  literalType := rfl
  primitive _ _ := rfl

instance : ReferenceRegistry int64Gamma where
  literalType := rfl
  primitive primitive hChecked := by
    simp only [Int64Checked, not_or] at hChecked
    obtain ⟨hAdd, hSub, hMul, hDiv⟩ := hChecked
    cases h : adapterGamma.primitive primitive with
    | none => simp [int64Gamma, h]
    | some specification =>
        simp [int64Gamma, h, int64Delta, Int64Checked, hAdd, hSub, hMul, hDiv]

end Registries

/-!
## Primitives under the reference runner's registry

Kernel programs name primitives by their surface names, and the reference
runner resolves them through `Firth.ReferenceRun.adapterGamma`. One lemma per
primitive states its effect under that registry.
-/

section Primitives
open Firth.ReferenceRun
variable {gamma : Gamma} [ReferenceRegistry gamma] {dictionary : Dictionary} {costs : CostTable}

private theorem adapter_prim {surface kernel : String} {specification : PrimitiveSpec}
    (hSurface : kernelPrimitive surface = some kernel)
    (hKernel : defaultGamma.primitive kernel = some specification) :
    adapterGamma.primitive surface = some specification := by
  simp [adapterGamma, hSurface, hKernel]

/-- A non-arithmetic primitive resolves under any reference registry as under
the runner's own. -/
private theorem registry_prim {surface kernel : String} {specification : PrimitiveSpec}
    (hOther : ¬ Int64Checked surface)
    (hSurface : kernelPrimitive surface = some kernel)
    (hKernel : defaultGamma.primitive kernel = some specification) :
    gamma.primitive surface = some specification := by
  rw [ReferenceRegistry.primitive surface hOther]
  exact adapter_prim hSurface hKernel

theorem runs_literal_int (value : Int) (stack : Stack) :
    Runs gamma dictionary costs (.cons (.lit (.int value)) .empty) stack
      (.literal (.int value) :: stack) 1 (costs.atom (.lit (.int value))) :=
  runs_lit (type := .int) stack (by rw [ReferenceRegistry.literalType]; rfl)

theorem runs_literal_bool (value : Bool) (stack : Stack) :
    Runs gamma dictionary costs (.cons (.lit (.bool value)) .empty) stack
      (.literal (.bool value) :: stack) 1 (costs.atom (.lit (.bool value))) :=
  runs_lit (type := .bool) stack (by rw [ReferenceRegistry.literalType]; rfl)

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

/-- `div` is Euclidean division, Lean's `Int./` (`Int.ediv`). A zero divisor
faults, so it has no rule. -/
theorem runs_div {left right : Int} (tail : Stack) (hNonzero : right ≠ 0) :
    Runs adapterGamma dictionary costs (.cons (.prim "div") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.int (left / right)) :: tail) 1 (costs.primitive "div") :=
  runs_prim (adapter_prim (kernel := "divInt") rfl rfl) (by simp [divIntDelta, hNonzero])

/-- `mod` is the Euclidean remainder, Lean's `Int.%` (`Int.emod`): at least 0
and below `|right|`, so it needs no i64 check. -/
theorem runs_mod {left right : Int} (tail : Stack) (hNonzero : right ≠ 0) :
    Runs gamma dictionary costs (.cons (.prim "mod") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.int (left % right)) :: tail) 1 (costs.primitive "mod") :=
  runs_prim (registry_prim (kernel := "modInt") (by decide) rfl rfl)
    (by simp [modIntDelta, hNonzero])

theorem runs_lt (left right : Int) (tail : Stack) :
    Runs gamma dictionary costs (.cons (.prim "<") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.bool (decide (left < right))) :: tail) 1 (costs.primitive "<") :=
  runs_prim (registry_prim (kernel := "ltInt") (by decide) rfl rfl) rfl

theorem runs_eq (left right : Int) (tail : Stack) :
    Runs gamma dictionary costs (.cons (.prim "=") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.bool (decide (left = right))) :: tail) 1 (costs.primitive "=") :=
  runs_prim (registry_prim (kernel := "eqInt") (by decide) rfl rfl) rfl

theorem runs_intSeq_empty (tail : Stack) :
    Runs gamma dictionary costs (.cons (.prim "seq-int.empty") .empty) tail
      (.literal (.intSeq []) :: tail) 1 (costs.primitive "seq-int.empty") :=
  runs_prim (registry_prim (kernel := "intSeqEmpty") (by decide) rfl rfl) rfl

theorem runs_intSeq_len (values : List Int) (tail : Stack) :
    Runs gamma dictionary costs (.cons (.prim "seq-int.len") .empty)
      (.literal (.intSeq values) :: tail) (.literal (.int values.length) :: tail) 1
      (costs.primitive "seq-int.len") :=
  runs_prim (registry_prim (kernel := "intSeqLen") (by decide) rfl rfl) rfl

/-- `seq-int.at` at an index inside the sequence. Outside it the primitive
faults, and no `Runs` fact holds. -/
theorem runs_intSeq_at {values : List Int} {index : Nat} {value : Int} (tail : Stack)
    (h : values[index]? = some value) :
    Runs gamma dictionary costs (.cons (.prim "seq-int.at") .empty)
      (.literal (.int index) :: .literal (.intSeq values) :: tail)
      (.literal (.int value) :: tail) 1 (costs.primitive "seq-int.at") :=
  runs_prim (registry_prim (kernel := "intSeqAt") (by decide) rfl rfl)
    (by simp [intSeqAtDelta, elementAt?, h])

theorem runs_intSeq_push (values : List Int) (value : Int) (tail : Stack) :
    Runs gamma dictionary costs (.cons (.prim "seq-int.push") .empty)
      (.literal (.int value) :: .literal (.intSeq values) :: tail)
      (.literal (.intSeq (values ++ [value])) :: tail) 1 (costs.primitive "seq-int.push") :=
  runs_prim (registry_prim (kernel := "intSeqPush") (by decide) rfl rfl) rfl

theorem runs_boolSeq_empty (tail : Stack) :
    Runs gamma dictionary costs (.cons (.prim "seq-bool.empty") .empty) tail
      (.literal (.boolSeq []) :: tail) 1 (costs.primitive "seq-bool.empty") :=
  runs_prim (registry_prim (kernel := "boolSeqEmpty") (by decide) rfl rfl) rfl

theorem runs_boolSeq_len (values : List Bool) (tail : Stack) :
    Runs gamma dictionary costs (.cons (.prim "seq-bool.len") .empty)
      (.literal (.boolSeq values) :: tail) (.literal (.int values.length) :: tail) 1
      (costs.primitive "seq-bool.len") :=
  runs_prim (registry_prim (kernel := "boolSeqLen") (by decide) rfl rfl) rfl

/-- `seq-bool.at` at an index inside the sequence. -/
theorem runs_boolSeq_at {values : List Bool} {index : Nat} {value : Bool} (tail : Stack)
    (h : values[index]? = some value) :
    Runs gamma dictionary costs (.cons (.prim "seq-bool.at") .empty)
      (.literal (.int index) :: .literal (.boolSeq values) :: tail)
      (.literal (.bool value) :: tail) 1 (costs.primitive "seq-bool.at") :=
  runs_prim (registry_prim (kernel := "boolSeqAt") (by decide) rfl rfl)
    (by simp [boolSeqAtDelta, elementAt?, h])

theorem runs_boolSeq_push (values : List Bool) (value : Bool) (tail : Stack) :
    Runs gamma dictionary costs (.cons (.prim "seq-bool.push") .empty)
      (.literal (.bool value) :: .literal (.boolSeq values) :: tail)
      (.literal (.boolSeq (values ++ [value])) :: tail) 1 (costs.primitive "seq-bool.push") :=
  runs_prim (registry_prim (kernel := "boolSeqPush") (by decide) rfl rfl) rfl

/-- `seq-int.at` at an index given as an `Int`, as arithmetic on the stack
leaves it: the index must be non-negative and inside the sequence. -/
theorem runs_intSeq_at_int {values : List Int} {index : Int} {value : Int} (tail : Stack)
    (hIndex : 0 ≤ index) (h : values[index.toNat]? = some value) :
    Runs gamma dictionary costs (.cons (.prim "seq-int.at") .empty)
      (.literal (.int index) :: .literal (.intSeq values) :: tail)
      (.literal (.int value) :: tail) 1 (costs.primitive "seq-int.at") := by
  have := runs_intSeq_at (gamma := gamma) (dictionary := dictionary) (costs := costs) tail h
  rwa [Int.toNat_of_nonneg hIndex] at this

/-- `seq-bool.at` at an index given as an `Int`. -/
theorem runs_boolSeq_at_int {values : List Bool} {index : Int} {value : Bool} (tail : Stack)
    (hIndex : 0 ≤ index) (h : values[index.toNat]? = some value) :
    Runs gamma dictionary costs (.cons (.prim "seq-bool.at") .empty)
      (.literal (.int index) :: .literal (.boolSeq values) :: tail)
      (.literal (.bool value) :: tail) 1 (costs.primitive "seq-bool.at") := by
  have := runs_boolSeq_at (gamma := gamma) (dictionary := dictionary) (costs := costs) tail h
  rwa [Int.toNat_of_nonneg hIndex] at this

end Primitives

/-!
## Overflow

The VM's integers are signed 64-bit and `+`, `-`, `*` and `div` trap on
overflow (for `div`, only `-2^63 div -1`), while the reference interpreter's
`Int` is unbounded. `int64Gamma` is the reference registry with those four
primitives faulting outside the i64 range, as the VM's do. A `Runs` fact under `int64Gamma` therefore also says that no
arithmetic step overflowed, and `Runs.of_int64` recovers the same fact under
`adapterGamma`. Literals need no check: the compiler refuses an out-of-range
literal, and `seq-int.len` of a sequence the VM can hold fits in i64.
-/

section Overflow
open Firth.ReferenceRun
variable {dictionary : Dictionary} {costs : CostTable}

private theorem int64Delta_sound {primitive : Prim} {specification : PrimitiveSpec}
    (hSpec : adapterGamma.primitive primitive = some specification)
    {before after : Stack} (h : int64Delta primitive specification.delta before = some after) :
    specification.delta before = some after := by
  unfold int64Delta at h
  split at h
  · subst primitive
    have : specification.delta = addIntDelta := by
      simp [adapterGamma, kernelPrimitive, surfacePrimitives, defaultGamma] at hSpec
      rw [← hSpec]
    rw [this]
    unfold checkedIntDelta at h
    split at h
    · split at h <;> simp_all [addIntDelta]
    · simp at h
  split at h
  · subst primitive
    have : specification.delta = subIntDelta := by
      simp [adapterGamma, kernelPrimitive, surfacePrimitives, defaultGamma] at hSpec
      rw [← hSpec]
    rw [this]
    unfold checkedIntDelta at h
    split at h
    · split at h <;> simp_all [subIntDelta]
    · simp at h
  split at h
  · subst primitive
    have : specification.delta = mulIntDelta := by
      simp [adapterGamma, kernelPrimitive, surfacePrimitives, defaultGamma] at hSpec
      rw [← hSpec]
    rw [this]
    unfold checkedIntDelta at h
    split at h
    · split at h <;> simp_all [mulIntDelta]
    · simp at h
  split at h
  · subst primitive
    have : specification.delta = divIntDelta := by
      simp [adapterGamma, kernelPrimitive, surfacePrimitives, defaultGamma] at hSpec
      rw [← hSpec]
    rw [this]
    unfold checkedDivDelta at h
    split at h
    · split at h
      · simp at h
      · split at h <;> simp_all [divIntDelta]
    · simp at h
  exact h

/-- Every step `int64Gamma` takes, `adapterGamma` takes identically. -/
theorem step_of_int64 {config next : Config} {cost : Nat}
    (h : step int64Gamma dictionary costs config = .stepped next cost) :
    step adapterGamma dictionary costs config = .stepped next cost := by
  rcases config with ⟨stack, program⟩
  cases program with
  | empty => simp [step] at h
  | cons atom rest =>
      cases atom with
      | prim primitive =>
          simp only [step] at h ⊢
          cases hSpec : adapterGamma.primitive primitive with
          | none => simp [int64Gamma, hSpec] at h
          | some specification =>
              simp only [int64Gamma, hSpec, Option.map_some] at h
              cases hDelta : int64Delta primitive specification.delta stack with
              | none => simp [hDelta] at h
              | some result =>
                  simp only [hDelta] at h
                  simp [int64Delta_sound hSpec hDelta, h]
      | _ => simpa [step, int64Gamma] using h

theorem Reaches.of_int64 {start finish : Config} {steps cost : Nat}
    (h : Reaches int64Gamma dictionary costs start finish steps cost) :
    Reaches adapterGamma dictionary costs start finish steps cost := by
  rcases h with ⟨trace, hLength, hCost⟩
  subst hLength hCost
  induction trace with
  | nil config => exact Reaches.refl config
  | cons stepCost stepProof tail ih =>
      simpa [traceLength, traceCost] using Reaches.head (step_of_int64 stepProof) ih

/-- A run with no overflow is a run of the reference interpreter. -/
theorem Runs.of_int64 {program : Program} {before after : Stack} {steps cost : Nat}
    (h : Runs int64Gamma dictionary costs program before after steps cost) :
    Runs adapterGamma dictionary costs program before after steps cost :=
  fun rest => (h rest).of_int64

private theorem int64_prim {primitive : Prim} {specification : PrimitiveSpec}
    (hSpec : adapterGamma.primitive primitive = some specification) :
    int64Gamma.primitive primitive =
      some { specification with
        delta := int64Delta primitive specification.delta
        faults := decide (Int64Checked primitive) || specification.faults } := by
  simp [int64Gamma, hSpec]

theorem runs_add_int64 {left right : Int} (tail : Stack) (hRange : InInt64 (left + right)) :
    Runs int64Gamma dictionary costs (.cons (.prim "+") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.int (left + right)) :: tail) 1 (costs.primitive "+") :=
  runs_prim (int64_prim rfl) (by simp [int64Delta, checkedIntDelta, hRange])

theorem runs_sub_int64 {left right : Int} (tail : Stack) (hRange : InInt64 (left - right)) :
    Runs int64Gamma dictionary costs (.cons (.prim "-") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.int (left - right)) :: tail) 1 (costs.primitive "-") :=
  runs_prim (int64_prim rfl) (by simp [int64Delta, checkedIntDelta, hRange])

theorem runs_mul_int64 {left right : Int} (tail : Stack) (hRange : InInt64 (left * right)) :
    Runs int64Gamma dictionary costs (.cons (.prim "*") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.int (left * right)) :: tail) 1 (costs.primitive "*") :=
  runs_prim (int64_prim rfl) (by simp [int64Delta, checkedIntDelta, hRange])

theorem runs_div_int64 {left right : Int} (tail : Stack) (hNonzero : right ≠ 0)
    (hRange : InInt64 (left / right)) :
    Runs int64Gamma dictionary costs (.cons (.prim "div") .empty)
      (.literal (.int right) :: .literal (.int left) :: tail)
      (.literal (.int (left / right)) :: tail) 1 (costs.primitive "div") :=
  runs_prim (int64_prim rfl) (by simp [int64Delta, checkedDivDelta, hNonzero, hRange])

private theorem single_step {gamma : Gamma} {start finish : Config}
    (trace : Trace gamma dictionary costs start finish) (h : traceLength trace = 1) :
    ∃ stepCost, step gamma dictionary costs start = .stepped finish stepCost ∧
      traceCost trace = stepCost := by
  cases trace with
  | nil => simp [traceLength] at h
  | cons stepCost stepProof tail =>
      cases tail with
      | nil => exact ⟨stepCost, stepProof, by simp [traceCost]⟩
      | cons => simp [traceLength] at h

/-- Any other primitive step proved under `adapterGamma` holds under
`int64Gamma` unchanged. -/
theorem runs_prim_int64 {primitive : Prim} {before after : Stack} {cost : Nat}
    (hOther : ¬ Int64Checked primitive)
    (h : Runs adapterGamma dictionary costs (.cons (.prim primitive) .empty) before after 1 cost) :
    Runs int64Gamma dictionary costs (.cons (.prim primitive) .empty) before after 1 cost := by
  intro rest
  rcases h rest with ⟨trace, hLength, hCost⟩
  rcases single_step trace hLength with ⟨stepCost, stepProof, hTrace⟩
  rw [hTrace] at hCost
  subst hCost
  have hStep : step int64Gamma dictionary costs
      { stack := before, program := (Program.cons (.prim primitive) .empty).append rest } =
      .stepped { stack := after, program := rest } stepCost := by
    simp only [Program.append, step] at stepProof ⊢
    cases hSpec : adapterGamma.primitive primitive with
    | none => simp [hSpec] at stepProof
    | some specification =>
        simp only [hSpec] at stepProof
        simp only [Int64Checked, not_or] at hOther
        obtain ⟨hAdd, hSub, hMul, hDiv⟩ := hOther
        simpa [int64Gamma, hSpec, int64Delta, hAdd, hSub, hMul, hDiv] using stepProof
  simpa using Reaches.head hStep (Reaches.refl (gamma := int64Gamma) (dictionary := dictionary)
    (costs := costs) { stack := after, program := rest })

end Overflow

/-!
## Costs, conditions and upper bounds

`defaultCosts` charges 1 for every atom, primitive and unfold; the simp lemmas
below say so, and `runs_arith` closes the step and cost equations a chain of
rules leaves behind.
-/

@[simp] theorem defaultCosts_atom (atom : Atom) : defaultCosts.atom atom = 1 := rfl
@[simp] theorem defaultCosts_primitive (primitive : Prim) :
    defaultCosts.primitive primitive = 1 := rfl
@[simp] theorem defaultCosts_unfold : defaultCosts.unfold = 1 := rfl

open Lean Elab Tactic Meta in
/-- Clears every hypothesis that is an equation between Booleans, such as the
condition `decide (x < y) = true` of an `if`. `omega` cannot use one, and with
one in context it can run out of heartbeats normalising a long step or cost
sum; `Firth.LogicTest` has the case. -/
elab "runs_clear_bool" : tactic => withMainContext do
  let mut goal ← getMainGoal
  for decl in ← getLCtx do
    if decl.isImplementationDetail then continue
    let type ← instantiateMVars decl.type
    if type.isAppOfArity ``Eq 3 && (type.getArg! 0).isConstOf ``Bool then
      goal ← goal.tryClear decl.fvarId
  replaceMainGoal [goal]

/-- Closes a step or cost equation or inequality under `defaultCosts`. Boolean
equations in context are cleared first (see `runs_clear_bool`), so a fact
`omega` needs must be stated over `Int` or `Nat`, not as a `decide`. -/
macro "runs_arith" : tactic =>
  `(tactic| ((try simp only [defaultCosts_atom, defaultCosts_primitive, defaultCosts_unfold]) <;>
    (runs_clear_bool; omega)))

section Bounds
variable {gamma : Gamma} {dictionary : Dictionary} {costs : CostTable}

/-- `if` on a condition known to be true. -/
theorem runs_if_of_true {condition : Bool} (hCondition : condition = true)
    {trueBranch falseBranch : Program} {usage₁ usage₂ : Usage}
    {tail after : Stack} {steps cost : Nat}
    (h : Runs gamma dictionary costs trueBranch tail after steps cost) :
    Runs gamma dictionary costs (.cons .ifThenElse .empty)
      (.quotation falseBranch usage₂ :: .quotation trueBranch usage₁ ::
        .literal (.bool condition) :: tail) after (steps + 1) (costs.atom .ifThenElse + cost) := by
  subst hCondition
  exact runs_if_true h

/-- `if` on a condition known to be false. -/
theorem runs_if_of_false {condition : Bool} (hCondition : condition = false)
    {trueBranch falseBranch : Program} {usage₁ usage₂ : Usage}
    {tail after : Stack} {steps cost : Nat}
    (h : Runs gamma dictionary costs falseBranch tail after steps cost) :
    Runs gamma dictionary costs (.cons .ifThenElse .empty)
      (.quotation falseBranch usage₂ :: .quotation trueBranch usage₁ ::
        .literal (.bool condition) :: tail) after (steps + 1) (costs.atom .ifThenElse + cost) := by
  subst hCondition
  exact runs_if_false h

/-- `program` takes `before` to `after` in at most `maxSteps` transitions
charging at most `maxCost`. This is the form for words whose exact cost depends
on the data; `Runs.within` and `RunsWithin.weaken` move between the two. -/
def RunsWithin (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (program : Program) (before after : Stack) (maxSteps maxCost : Nat) : Prop :=
  ∃ steps cost, Runs gamma dictionary costs program before after steps cost ∧
    steps ≤ maxSteps ∧ cost ≤ maxCost

theorem Runs.within {program : Program} {before after : Stack} {steps cost : Nat}
    (h : Runs gamma dictionary costs program before after steps cost) :
    RunsWithin gamma dictionary costs program before after steps cost :=
  ⟨steps, cost, h, Nat.le_refl _, Nat.le_refl _⟩

theorem RunsWithin.weaken {program : Program} {before after : Stack}
    {maxSteps maxCost maxSteps' maxCost' : Nat}
    (h : RunsWithin gamma dictionary costs program before after maxSteps maxCost)
    (hSteps : maxSteps ≤ maxSteps') (hCost : maxCost ≤ maxCost') :
    RunsWithin gamma dictionary costs program before after maxSteps' maxCost' := by
  rcases h with ⟨steps, cost, h, hs, hc⟩
  exact ⟨steps, cost, h, Nat.le_trans hs hSteps, Nat.le_trans hc hCost⟩

theorem RunsWithin.congr_stacks {program : Program} {before after before' after' : Stack}
    {maxSteps maxCost : Nat}
    (h : RunsWithin gamma dictionary costs program before after maxSteps maxCost)
    (hBefore : before = before') (hAfter : after = after') :
    RunsWithin gamma dictionary costs program before' after' maxSteps maxCost := by
  subst hBefore hAfter
  exact h

theorem runsWithin_append {first second : Program} {before middle after : Stack}
    {steps₁ cost₁ steps₂ cost₂ : Nat}
    (left : RunsWithin gamma dictionary costs first before middle steps₁ cost₁)
    (right : RunsWithin gamma dictionary costs second middle after steps₂ cost₂) :
    RunsWithin gamma dictionary costs (first.append second) before after
      (steps₁ + steps₂) (cost₁ + cost₂) := by
  rcases left with ⟨s₁, c₁, h₁, hs₁, hc₁⟩
  rcases right with ⟨s₂, c₂, h₂, hs₂, hc₂⟩
  exact ⟨s₁ + s₂, c₁ + c₂, runs_append h₁ h₂, Nat.add_le_add hs₁ hs₂, Nat.add_le_add hc₁ hc₂⟩

theorem runsWithin_cons {atom : Atom} {tail : Program} {before middle after : Stack}
    {steps₁ cost₁ steps₂ cost₂ : Nat}
    (head : RunsWithin gamma dictionary costs (.cons atom .empty) before middle steps₁ cost₁)
    (rest : RunsWithin gamma dictionary costs tail middle after steps₂ cost₂) :
    RunsWithin gamma dictionary costs (.cons atom tail) before after
      (steps₁ + steps₂) (cost₁ + cost₂) :=
  runsWithin_append (first := .cons atom .empty) head rest

theorem runsWithin_word {name : String} {entry : WordEntry} {before after : Stack}
    {maxSteps maxCost : Nat} (hEntry : dictionary name = some entry)
    (h : RunsWithin gamma dictionary costs entry.body before after maxSteps maxCost) :
    RunsWithin gamma dictionary costs (.cons (.word name) .empty) before after
      (maxSteps + 1) (costs.unfold + maxCost) := by
  rcases h with ⟨steps, cost, h, hs, hc⟩
  exact ⟨steps + 1, costs.unfold + cost, runs_word hEntry h, by omega, by omega⟩

theorem runsWithin_call {body : Program} {usage : Usage} {tail after : Stack}
    {maxSteps maxCost : Nat}
    (h : RunsWithin gamma dictionary costs body tail after maxSteps maxCost) :
    RunsWithin gamma dictionary costs (.cons .call .empty) (.quotation body usage :: tail) after
      (maxSteps + 1) (costs.atom .call + maxCost) := by
  rcases h with ⟨steps, cost, h, hs, hc⟩
  exact ⟨steps + 1, costs.atom .call + cost, runs_call h, by omega, by omega⟩

theorem runsWithin_dip {body : Program} {usage : Usage} {value : Value} {tail after : Stack}
    {maxSteps maxCost : Nat}
    (h : RunsWithin gamma dictionary costs body tail after maxSteps maxCost) :
    RunsWithin gamma dictionary costs (.cons .dip .empty) (.quotation body usage :: value :: tail)
      (value :: after) (maxSteps + 2) (costs.atom .dip + maxCost) := by
  rcases h with ⟨steps, cost, h, hs, hc⟩
  exact ⟨steps + 2, costs.atom .dip + cost, runs_dip h, by omega, by omega⟩

theorem runsWithin_if {condition : Bool} {trueBranch falseBranch : Program}
    {usage₁ usage₂ : Usage} {tail after : Stack} {maxSteps maxCost : Nat}
    (h : RunsWithin gamma dictionary costs (if condition then trueBranch else falseBranch)
      tail after maxSteps maxCost) :
    RunsWithin gamma dictionary costs (.cons .ifThenElse .empty)
      (.quotation falseBranch usage₂ :: .quotation trueBranch usage₁ ::
        .literal (.bool condition) :: tail) after
      (maxSteps + 1) (costs.atom .ifThenElse + maxCost) := by
  rcases h with ⟨steps, cost, h, hs, hc⟩
  exact ⟨steps + 1, costs.atom .ifThenElse + cost, runs_if h, by omega, by omega⟩

/-- Adequacy for bounds: with at least `maxSteps` fuel, `run` terminates on
`after` within both bounds. -/
theorem run_of_runsWithin {program : Program} {before after : Stack} {maxSteps maxCost : Nat}
    (h : RunsWithin gamma dictionary costs program before after maxSteps maxCost)
    {fuel : Nat} (hFuel : maxSteps ≤ fuel) :
    ∃ steps cost, steps ≤ maxSteps ∧ cost ≤ maxCost ∧
      run gamma dictionary costs fuel { stack := before, program := program } =
        .terminal { stack := after, program := .empty } steps cost := by
  rcases h with ⟨steps, cost, h, hs, hc⟩
  refine ⟨steps, cost, hs, hc, ?_⟩
  have := run_of_runs h (fuel - steps)
  rwa [Nat.add_sub_cancel' (Nat.le_trans hs hFuel)] at this

end Bounds

/-!
## Word contracts

A proof record admits exactly one shape of statement: a `WordContract` holds
of an exported word's body. The contract names its arguments, a precondition
on them, the stack the word starts from and the stack it leaves (top first,
above any `tail`), and bounds on steps and cost. `witness` is a proof that
some arguments meet the precondition, so a contract cannot be vacuous: a
precondition no input satisfies cannot be declared.
-/

/-- What a word does, for every argument that meets `pre`. -/
structure WordContract where
  Args : Type
  pre : Args → Prop
  input : Args → Stack
  output : Args → Stack
  steps : Args → Nat
  cost : Args → Nat
  witness : ∃ args, pre args

/-- `contract` holds of `program`: from `input args` above any `tail`, for
every `args` meeting `pre`, it leaves `output args` above the same `tail`
within the contract's bounds. -/
def WordContract.Holds (contract : WordContract) (gamma : Gamma) (dictionary : Dictionary)
    (costs : CostTable) (program : Program) : Prop :=
  ∀ (args : contract.Args) (tail : Stack), contract.pre args →
    RunsWithin gamma dictionary costs program (contract.input args ++ tail)
      (contract.output args ++ tail) (contract.steps args) (contract.cost args)

/-!
## Straight-line chains

`runs_chain` proves a `Runs` goal for a straight-line program by applying one
rule per atom: the structural atoms (with `pick` and `roll` on a stack deep
enough), literals, the arithmetic, comparison and
sequence-length primitives (under `int64Gamma`, `+`, `-` and `*` leave an
`InInt64` side goal, closed from the assumptions when linear arithmetic
suffices), `dip` and `call` of a literal quotation, `if` on a
condition `rfl`, `decide` or an assumption settles, and any word call or atom
for which a matching `Runs` hypothesis is in context. It then closes the step
and cost equations with `runs_arith`. Whatever it cannot settle, such as a
stack that is only equal up to arithmetic, is left as a goal.
-/

/-- Closes a side goal a chain leaves: step and cost arithmetic, or an i64
range condition that is an assumption or follows from the assumptions by
linear arithmetic. The assumption must match up to reducible unfolding only:
at default transparency, matching a hypothesis against a long cost sum can run
out of heartbeats. -/
macro "runs_side" : tactic => `(tactic| first
  | with_reducible assumption
  | runs_arith
  | (runs_clear_bool; simp only [InInt64] at *; omega))

/-- Settles the condition of an `if` in a chain, or fails. -/
macro "runs_condition" : tactic => `(tactic| first
  | rfl
  | decide
  | assumption
  | (simp_all; done))

/-- One rule of a chain; fails when no rule applies. -/
macro "runs_atom" : tactic => `(tactic| first
  | exact runs_empty _
  | apply runs_cons (by assumption)
  | apply runs_cons (runs_dup _ _)
  | apply runs_cons (runs_drop _ _)
  | apply runs_cons (runs_swap _ _ _)
  | apply runs_cons (runs_pick (by rfl))
  | apply runs_cons (runs_roll (by rfl))
  | apply runs_cons (runs_quote _ _)
  | apply runs_cons (runs_compose _ _ _ _ _)
  | apply runs_cons (runs_push _ _)
  | apply runs_cons (runs_quotation _ _)
  | apply runs_cons (runs_literal_int _ _)
  | apply runs_cons (runs_literal_bool _ _)
  | apply runs_cons (runs_add _ _ _)
  | apply runs_cons (runs_sub _ _ _)
  | apply runs_cons (runs_mul _ _ _)
  | apply runs_cons (runs_add_int64 _ ?_)
  | apply runs_cons (runs_sub_int64 _ ?_)
  | apply runs_cons (runs_mul_int64 _ ?_)
  | apply runs_cons (runs_div _ ?_)
  | apply runs_cons (runs_div_int64 _ ?_ ?_)
  | apply runs_cons (runs_mod _ ?_)
  | apply runs_cons (runs_lt _ _ _)
  | apply runs_cons (runs_eq _ _ _)
  | apply runs_cons (runs_intSeq_empty _)
  | apply runs_cons (runs_intSeq_len _ _)
  | apply runs_cons (runs_intSeq_push _ _ _)
  | apply runs_cons (runs_boolSeq_empty _)
  | apply runs_cons (runs_boolSeq_len _ _)
  | apply runs_cons (runs_boolSeq_push _ _ _)
  | apply runs_cons (runs_dip ?_)
  | apply runs_cons (runs_call ?_)
  | (apply runs_cons (runs_if_of_true ?condition ?_); case condition => runs_condition)
  | (apply runs_cons (runs_if_of_false ?condition ?_); case condition => runs_condition))

open Lean Elab Tactic Meta in
/-- Unfolds the named program in a `Runs` goal, such as an exported
`«w».body`, into its atoms. Does nothing when the program is already atoms. -/
elab "runs_expand" : tactic => withMainContext do
  let goal ← getMainGoal
  let target ← instantiateMVars (← goal.getType)
  let args := target.getAppArgs
  if h : 3 < args.size then
    if let .const name _ := args[3].getAppFn then
      replaceMainGoal [← goal.deltaTarget (· == name)]

/-- Proves `Runs (.cons (.word name) .empty) …` by unfolding that one call
through its dictionary entry and chaining its body. Calls inside the body are
not unfolded; they need `Runs` hypotheses, so recursion stays explicit. -/
macro "runs_unfold" : tactic => `(tactic| (
  apply Runs.congr
  focus
    apply runs_word (by rfl)
    dsimp only
    runs_expand
  repeat' runs_atom
  all_goals try runs_side))

/-- Proves a straight-line `Runs` goal; see the section comment. -/
macro "runs_chain" : tactic => `(tactic| (
  apply Runs.congr
  runs_expand
  repeat' runs_atom
  all_goals try runs_side))

end Firth.Logic
