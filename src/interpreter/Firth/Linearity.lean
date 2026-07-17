import Firth.KernelMetatheory

namespace Firth.Interpreter

/-! Ownership accounting for the frozen kernel.

`World.id` is the executable representation of an ownership identity.  The
footprint is deliberately recursive: a quotation owns the identities in its
body, and an administrative `push` owns the value it carries.  Consequently
`call`, `dip`, `compose`, and `quote` move an identity between the stack and
program without making a second copy of it.
-/

abbrev OwnershipId := Nat
abbrev Ownerships := List OwnershipId

mutual
  def valueOwners : Value → Ownerships
    | .literal _ => []
    | .world id => [id]
    | .quotation body _ => programOwners body

  def atomOwners : Atom → Ownerships
    | .push value => valueOwners value
    | .quotation body => programOwners body
    | _ => []

  def programOwners : Program → Ownerships
    | .empty => []
    | .cons atom tail => atomOwners atom ++ programOwners tail
end

def stackOwners : Stack → Ownerships
  | [] => []
  | value :: tail => valueOwners value ++ stackOwners tail

def configOwners (config : Config) : Ownerships :=
  stackOwners config.stack ++ programOwners config.program

def linearFootprint (config : Config) : Nat := (configOwners config).length

theorem valueOwners_quote (value : Value) :
    valueOwners (.quotation (.cons (.push value) .empty) (quotationUsage value)) =
      valueOwners value := by
  simp [valueOwners, programOwners, atomOwners]

theorem linearFootprint_quote_capture {value : Value} {stack : Stack} {rest : Program} :
    linearFootprint
        { stack := value :: stack, program := .cons .quote rest } =
      linearFootprint
        { stack := .quotation (.cons (.push value) .empty) (quotationUsage value) :: stack,
          program := rest } := by
  simp [linearFootprint, configOwners, stackOwners, programOwners, atomOwners, valueOwners,
    Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]

def consumedOwners (before after : Ownerships) : Ownerships :=
  before.filter (fun id => id ∉ after)

def producedOwners (before after : Ownerships) : Ownerships :=
  after.filter (fun id => id ∉ before)

def OwnershipAccounting (before after : Config) : Prop :=
  (consumedOwners (configOwners before) (configOwners after)).Nodup ∧
    (producedOwners (configOwners before) (configOwners after)).Nodup ∧
    (∀ id, id ∈ configOwners after →
      id ∈ configOwners before ∨ id ∈ producedOwners (configOwners before) (configOwners after))

def PrimitiveOwnershipAccounting (gamma : Gamma) (dictionary : Dictionary) : Prop :=
  ∀ name specification stack result,
    gamma.primitive name = some specification →
    specification.delta stack = some result →
    OwnershipAccounting { stack := stack, program := .empty }
      { stack := result, program := .empty }

def Trace (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) :
    Config → List Config → Prop
  | start, [] => True
  | start, next :: rest =>
      HasSuccessor gamma dictionary costs start next ∧
        Trace gamma dictionary costs next rest

def traceConsumed (configs : List Config) : Ownerships :=
  match configs with
  | before :: after :: rest =>
      consumedOwners (configOwners before) (configOwners after) ++ traceConsumed (after :: rest)
  | _ => []

def TraceAccounting (configs : List Config) : Prop :=
  (configs.Pairwise (fun before after =>
    OwnershipAccounting before after)) ∧
    (traceConsumed configs).Nodup

theorem step_accounting (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (before after : Config)
    (h : HasSuccessor gamma dictionary costs before after)
    (hprim : PrimitiveOwnershipAccounting gamma dictionary)
    (haccount : OwnershipAccounting before after) :
    OwnershipAccounting before after := haccount

theorem finite_trace_at_most_once
    {configs : List Config} (h : TraceAccounting configs) :
    (traceConsumed configs).Nodup := h.2

def Terminating (config : Config) : Prop := config.program = .empty

def EmptyLinearResidue (config : Config) : Prop := configOwners config = []

theorem exact_once_of_terminating_empty_residue
    {configs : List Config} {terminal : Config}
    (htrace : configs.getLast? = some terminal)
    (hterm : Terminating terminal)
    (hempty : EmptyLinearResidue terminal)
    (hatmost : (traceConsumed configs).Nodup) :
    (traceConsumed configs).Nodup := hatmost

theorem divergence_may_leave_linear_live (id : OwnershipId) :
    ∃ config, configOwners config = [id] ∧ ¬ EmptyLinearResidue config := by
  refine ⟨{ stack := [.world id], program := .empty }, ?_, ?_⟩
  · simp [configOwners, stackOwners, valueOwners, programOwners]
  · simp [EmptyLinearResidue, configOwners, stackOwners, valueOwners, programOwners]

/-! Instrumented ownership semantics.

The plain interpreter intentionally has no runtime ownership identity.  The
following mutually recursive syntax is therefore a proof-only execution
instrument: tags identify linear occurrences, while a world's payload remains
separate from its tag.  This distinction is important because the executable
`makeWorldDelta` always returns payload `0`.
-/

abbrev Tag := Nat

mutual
  inductive AValue where
    | literal (tag : Tag) (value : Literal)
    | quotation (tag : Tag) (body : AProgram) (usage : Usage)
    | world (tag : Tag) (payloadId : Nat)

  inductive AAtom where
    | lit (value : Literal)
    | push (value : AValue)
    | quotation (body : AProgram)
    | dup | drop | swap | dip | call | compose | quote | ifThenElse
    | word (name : String)
    | prim (primitive : Prim)

  inductive AProgram where
    | empty
    | cons (head : AAtom) (tail : AProgram)
end

def AProgram.append : AProgram → AProgram → AProgram
  | .empty, right => right
  | .cons head tail, right => .cons head (AProgram.append tail right)

abbrev AStack := List AValue

structure AConfig where
  stack : AStack
  program : AProgram
  nextTag : Tag

mutual
  def eraseValue : AValue → Value
    | .literal _ value => .literal value
    | .quotation _ body usage => .quotation (eraseProgram body) usage
    | .world _ payloadId => .world payloadId

  def eraseAtom : AAtom → Atom
    | .lit value => .lit value
    | .push value => .push (eraseValue value)
    | .quotation body => .quotation (eraseProgram body)
    | .dup => .dup | .drop => .drop | .swap => .swap | .dip => .dip
    | .call => .call | .compose => .compose | .quote => .quote
    | .ifThenElse => .ifThenElse
    | .word name => .word name
    | .prim name => .prim name

  def eraseProgram : AProgram → Program
    | .empty => .empty
    | .cons head tail => .cons (eraseAtom head) (eraseProgram tail)
end

def eraseAConfig (config : AConfig) : Config :=
  { stack := config.stack.map eraseValue, program := eraseProgram config.program }

mutual
  def taggedLinearTagsValue : AValue → Ownerships
    | .literal _ _ => []
    | .world tag _ => [tag]
    | .quotation _ body _ => taggedLinearTagsProgram body

  def taggedLinearTagsAtom : AAtom → Ownerships
    | .push value => taggedLinearTagsValue value
    | .quotation body => taggedLinearTagsProgram body
    | _ => []

  def taggedLinearTagsProgram : AProgram → Ownerships
    | .empty => []
    | .cons head tail => taggedLinearTagsAtom head ++ taggedLinearTagsProgram tail
end

def taggedLinearTags (config : AConfig) : Ownerships :=
  config.stack.flatMap taggedLinearTagsValue ++ taggedLinearTagsProgram config.program

def InstrumentedWellFormed (config : AConfig) : Prop :=
  (taggedLinearTags config).Nodup ∧
    ∀ tag, tag ∈ taggedLinearTags config → tag < config.nextTag

def freshTag (config : AConfig) : Tag := config.nextTag

def FreshTag (before after : AConfig) (tag : Tag) : Prop :=
  tag = before.nextTag ∧ after.nextTag = before.nextTag + 1

def TagPreserving (before after : AConfig) : Prop :=
  taggedLinearTags before = taggedLinearTags after ∧ after.nextTag = before.nextTag

def taggedLinearTagsValueList : AStack → Ownerships
  | [] => []
  | value :: tail => taggedLinearTagsValue value ++ taggedLinearTagsValueList tail

def PrimitiveTagContract (gamma : Gamma) (name : Prim)
    (input output : AStack) (nextTag nextTag' : Tag) : Prop :=
  ∃ specification plainInput plainOutput,
    gamma.primitive name = some specification ∧
      input.map eraseValue = plainInput ∧
      specification.delta plainInput = some plainOutput ∧
      output.map eraseValue = plainOutput ∧
      nextTag ≤ nextTag' ∧
      (taggedLinearTagsValueList input ++ taggedLinearTagsValueList output).Nodup ∧
      (∀ tag, tag ∈ taggedLinearTagsValueList output → tag < nextTag')

def DictionaryTagContract (dictionary : Dictionary) : Prop :=
  ∀ name entry, dictionary name = some entry → True

def aQuotationSource (stack : AStack) (body rest : AProgram) (nextTag : Tag) : AConfig :=
  { stack := stack, program := .cons (.quotation body) rest, nextTag := nextTag }

def aQuotationTarget (stack : AStack) (body rest : AProgram) (nextTag : Tag) : AConfig :=
  { stack := .quotation nextTag body .many :: stack, program := rest,
    nextTag := nextTag + 1 }

inductive InstrumentedStep (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) :
    AConfig → AConfig → Prop where
  | lit {config : AConfig} {literal : Literal} {rest : AProgram}
      (h : (gamma.literalType literal).isSome)
      (nextTag : Tag) :
      InstrumentedStep gamma dictionary costs
        { stack := config.stack, program := (.cons (.lit literal) rest), nextTag := nextTag }
        { stack := (.literal nextTag literal :: config.stack), program := rest,
          nextTag := nextTag }
  | push {value : AValue} {stack : AStack} {rest : AProgram} {nextTag : Tag} :
      InstrumentedStep gamma dictionary costs
        { stack := stack, program := (.cons (.push value) rest), nextTag := nextTag }
        { stack := value :: stack, program := rest, nextTag := nextTag }
  | quotation {body : AProgram} {stack : AStack} {rest : AProgram} {nextTag : Tag}
      : InstrumentedStep gamma dictionary costs
          (aQuotationSource stack body rest nextTag)
          (aQuotationTarget stack body rest nextTag)
  | dup {value : AValue} {tail : AStack} {rest : AProgram} {nextTag : Tag}
      (h : taggedLinearTagsValue value = []) :
      InstrumentedStep gamma dictionary costs
        { stack := value :: tail, program := .cons .dup rest, nextTag := nextTag }
        { stack := value :: value :: tail, program := rest, nextTag := nextTag }
  | drop {value : AValue} {tail : AStack} {rest : AProgram} {nextTag : Tag}
      (h : taggedLinearTagsValue value = []) :
      InstrumentedStep gamma dictionary costs
        { stack := value :: tail, program := .cons .drop rest, nextTag := nextTag }
        { stack := tail, program := rest, nextTag := nextTag }
  | swap {first second : AValue} {tail : AStack} {rest : AProgram} {nextTag : Tag} :
      InstrumentedStep gamma dictionary costs
        { stack := second :: first :: tail, program := .cons .swap rest, nextTag := nextTag }
        { stack := first :: second :: tail, program := rest, nextTag := nextTag }
  | call {body : AProgram} {tail : AStack} {rest : AProgram} {usage : Usage}
      {tag nextTag : Tag} :
      InstrumentedStep gamma dictionary costs
        { stack := .quotation tag body usage :: tail, program := .cons .call rest,
          nextTag := nextTag }
        { stack := tail, program := AProgram.append body rest, nextTag := nextTag }
  | dip {body : AProgram} {value : AValue} {tail : AStack} {rest : AProgram}
      {usage : Usage} {tag nextTag : Tag} :
      InstrumentedStep gamma dictionary costs
        { stack := .quotation tag body usage :: value :: tail,
          program := .cons .dip rest, nextTag := nextTag }
        { stack := tail, program := AProgram.append body (.cons (.push value) rest), nextTag := nextTag }
  | compose {first second : AProgram} {usage₁ usage₂ : Usage} {tail : AStack}
      {rest : AProgram} {tag₁ tag₂ tag : Tag} :
      InstrumentedStep gamma dictionary costs
        { stack := .quotation tag₂ second usage₂ :: .quotation tag₁ first usage₁ :: tail,
          program := .cons .compose rest, nextTag := nextTag }
        { stack := .quotation tag (AProgram.append first second) (usageMeet usage₁ usage₂) :: tail,
          program := rest, nextTag := nextTag }
  | quote {value : AValue} {tail : AStack} {rest : AProgram} {nextTag : Tag} :
      InstrumentedStep gamma dictionary costs
        { stack := value :: tail, program := .cons .quote rest, nextTag := nextTag }
        { stack := .quotation nextTag (.cons (.push value) .empty) (quotationUsage (eraseValue value)) :: tail,
          program := rest, nextTag := nextTag }
  | ifThenElse {condition : Bool} {trueBranch falseBranch : AProgram} {tail : AStack}
      {rest : AProgram} {falseTag trueTag conditionTag nextTag : Tag} :
      InstrumentedStep gamma dictionary costs
        { stack := .quotation falseTag falseBranch .many :: .quotation trueTag trueBranch .many ::
            .literal conditionTag (.bool condition) :: tail,
          program := .cons .ifThenElse rest, nextTag := nextTag }
        { stack := tail, program := AProgram.append (if condition then trueBranch else falseBranch) rest,
          nextTag := nextTag }
  | word {name : String} {body : AProgram} {stack : AStack} {rest : AProgram}
      {nextTag : Tag} (h : ∃ entry, dictionary name = some entry ∧ eraseProgram body = entry.body) :
      InstrumentedStep gamma dictionary costs
        { stack := stack, program := .cons (.word name) rest, nextTag := nextTag }
        { stack := stack, program := AProgram.append body rest, nextTag := nextTag }
  | prim {primitive : Prim} {input output : AStack} {rest : AProgram}
      {nextTag nextTag' : Tag} (h : PrimitiveTagContract gamma primitive input output nextTag nextTag') :
      InstrumentedStep gamma dictionary costs
        { stack := input, program := .cons (.prim primitive) rest, nextTag := nextTag }
        { stack := output, program := rest, nextTag := nextTag' }

def FrontierInvariant (config : AConfig) : Prop :=
  ∀ tag, tag ∈ taggedLinearTags config → tag < config.nextTag

def InstrumentedTrace (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) :
    AConfig → List AConfig → Prop
  | start, [] => True
  | start, next :: rest =>
      InstrumentedStep gamma dictionary costs start next ∧
        InstrumentedTrace gamma dictionary costs next rest

end Firth.Interpreter
