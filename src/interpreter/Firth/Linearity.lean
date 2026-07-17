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
  before.filter (fun id => !(after.contains id))

def producedOwners (before after : Ownerships) : Ownerships :=
  after.filter (fun id => !(before.contains id))

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
theorem eraseProgram_append (left right : AProgram) :
      eraseProgram (AProgram.append left right) =
        (eraseProgram left).append (eraseProgram right) := by
    cases left with
    | empty => rfl
    | cons head tail =>
        simp [AProgram.append, eraseProgram, eraseProgram_append, Program.append]
end

theorem usageMeet_decide (left right : Usage) :
    (if left == .linear || right == .linear then .linear else .many) =
      usageMeet left right := by
  cases left <;> cases right <;> rfl

theorem eraseProgram_if (condition : Bool) (trueBranch falseBranch : AProgram) :
    eraseProgram (if condition then trueBranch else falseBranch) =
      if condition then eraseProgram trueBranch else eraseProgram falseBranch := by
  cases condition <;> rfl

mutual
  def taggedLinearTagsValue : AValue → Ownerships
    | .literal tag _ => [tag]
    | .world tag _ => [tag]
    | .quotation tag body _ => tag :: taggedLinearTagsProgram body

  def taggedLinearTagsAtom : AAtom → Ownerships
    | .push value => taggedLinearTagsValue value
    | .quotation body => taggedLinearTagsProgram body
    | _ => []

  def taggedLinearTagsProgram : AProgram → Ownerships
    | .empty => []
    | .cons head tail => taggedLinearTagsAtom head ++ taggedLinearTagsProgram tail
end

mutual
  theorem taggedLinearTagsProgram_append (left right : AProgram) :
      taggedLinearTagsProgram (AProgram.append left right) =
        taggedLinearTagsProgram left ++ taggedLinearTagsProgram right := by
    cases left with
    | empty => rfl
    | cons head tail =>
        simp [AProgram.append, taggedLinearTagsProgram,
          taggedLinearTagsProgram_append, List.append_assoc]
end

def taggedLinearTagsValueList : AStack → Ownerships
  | [] => []
  | value :: tail => taggedLinearTagsValue value ++ taggedLinearTagsValueList tail

def taggedLinearTags (config : AConfig) : Ownerships :=
  config.stack.foldr (fun value tags => taggedLinearTagsValue value ++ tags) [] ++
    taggedLinearTagsProgram config.program

def InstrumentedWellFormed (config : AConfig) : Prop :=
  (taggedLinearTags config).Nodup ∧
    ∀ tag, tag ∈ taggedLinearTags config → tag < config.nextTag

def freshTag (config : AConfig) : Tag := config.nextTag

def FreshTag (before after : AConfig) (tag : Tag) : Prop :=
  tag = before.nextTag ∧ after.nextTag = before.nextTag + 1

def TagPreserving (before after : AConfig) : Prop :=
  taggedLinearTags before = taggedLinearTags after ∧ after.nextTag = before.nextTag

theorem taggedLinearTagsValueList_eq_flatMap (stack : AStack) :
    taggedLinearTagsValueList stack = stack.flatMap taggedLinearTagsValue := by
  induction stack with
  | nil => rfl
  | cons value tail ih => simp [taggedLinearTagsValueList, ih]

theorem taggedLinearTagsValueList_eq_foldr (stack : AStack) :
    taggedLinearTagsValueList stack =
      stack.foldr (fun value tags => taggedLinearTagsValue value ++ tags) [] := by
  induction stack with
  | nil => rfl
  | cons value tail ih => simp [taggedLinearTagsValueList, ih]

theorem taggedLinearTagsValue_mem_foldr {stack : AStack} {tag : Tag}
    (h : ∃ value, value ∈ stack ∧ tag ∈ taggedLinearTagsValue value) :
    tag ∈ stack.foldr (fun value tags => taggedLinearTagsValue value ++ tags) [] := by
  induction stack with
  | nil => cases h with | intro value h => cases h.1
  | cons value tail ih =>
      simp only [List.foldr, List.mem_append]
      rcases h with ⟨value', hvalue', htag⟩
      rcases List.mem_cons.mp hvalue' with rfl | hvalue'
      · exact Or.inl htag
      · exact Or.inr (ih ⟨value', hvalue', htag⟩)

@[simp] theorem taggedLinearTagsValue_mem_foldr_iff {stack : AStack} {tag : Tag} :
    tag ∈ stack.foldr (fun value tags => taggedLinearTagsValue value ++ tags) [] ↔
      ∃ value, value ∈ stack ∧ tag ∈ taggedLinearTagsValue value := by
  induction stack with
  | nil =>
      constructor
      · intro h
        cases h
      · rintro ⟨value, hvalue, htag⟩
        cases hvalue
  | cons value tail ih =>
      constructor
      · intro h
        simp only [List.foldr, List.mem_append] at h
        rcases h with hvalue | htail
        · exact ⟨value, List.mem_cons_self, hvalue⟩
        · rcases ih.mp htail with ⟨value', hvalue', htag⟩
          exact ⟨value', List.mem_cons_of_mem _ hvalue', htag⟩
      · rintro ⟨value', hvalue', htag⟩
        simp only [List.foldr, List.mem_append]
        rcases List.mem_cons.mp hvalue' with rfl | hvalue'
        · exact Or.inl htag
        · exact Or.inr (ih.mpr ⟨value', hvalue', htag⟩)

attribute [-simp] List.mem_flatMap
attribute [-simp] List.mem_map
attribute [-simp] List.mem_flatten

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
  { stack := .quotation nextTag body (programUsage (eraseProgram body)) :: stack, program := rest,
    nextTag := nextTag + 1 }

inductive InstrumentedStep (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) :
    AConfig → AConfig → Prop where
  | lit {config : AConfig} {literal : Literal} {rest : AProgram}
      (h : (gamma.literalType literal).isSome)
      (nextTag : Tag) :
      InstrumentedStep gamma dictionary costs
        { stack := config.stack, program := (.cons (.lit literal) rest), nextTag := nextTag }
        { stack := (.literal nextTag literal :: config.stack), program := rest,
          nextTag := nextTag + 1 }
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
      {rest : AProgram} {tag₁ tag₂ nextTag : Tag} :
      InstrumentedStep gamma dictionary costs
        { stack := .quotation tag₂ second usage₂ :: .quotation tag₁ first usage₁ :: tail,
          program := .cons .compose rest, nextTag := nextTag }
        { stack := .quotation nextTag (AProgram.append first second)
            (if usage₁ == .linear || usage₂ == .linear then .linear else .many) :: tail,
          program := rest, nextTag := nextTag + 1 }
  | quote {value : AValue} {tail : AStack} {rest : AProgram} {nextTag : Tag} :
      InstrumentedStep gamma dictionary costs
        { stack := value :: tail, program := .cons .quote rest, nextTag := nextTag }
        { stack := .quotation nextTag (.cons (.push value) .empty) (quotationUsage (eraseValue value)) :: tail,
          program := rest, nextTag := nextTag + 1 }
  | ifThenElse {condition : Bool} {trueBranch falseBranch : AProgram} {tail : AStack}
      {rest : AProgram} {falseTag trueTag conditionTag nextTag : Tag} :
      InstrumentedStep gamma dictionary costs
        { stack := .quotation falseTag falseBranch .many :: .quotation trueTag trueBranch .many ::
            .literal conditionTag (.bool condition) :: tail,
          program := .cons .ifThenElse rest, nextTag := nextTag }
        { stack := tail, program := AProgram.append (if condition then trueBranch else falseBranch) rest,
          nextTag := nextTag }
  | word {name : String} {body : AProgram} {stack : AStack} {rest : AProgram}
      {nextTag : Tag}
      (h : ∃ entry, dictionary name = some entry ∧ eraseProgram body = entry.body ∧
        ∀ tag, tag ∈ taggedLinearTagsProgram body → tag < nextTag) :
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

theorem frontier_succ {tag frontier : Tag}
    (h : tag = frontier ∨ tag < frontier) : tag < frontier + 1 := by
  rcases h with rfl | h
  · exact Nat.lt_succ_self _
  · exact Nat.lt_succ_of_lt h

theorem instrumented_frontier_preserved
    (before after : AConfig) (hbefore : FrontierInvariant before)
    (hstep : InstrumentedStep gamma dictionary costs before after) :
    FrontierInvariant after := by
  cases hstep with
  | lit h nextTag =>
      intro tag htag
      simp [aQuotationTarget, taggedLinearTags, taggedLinearTagsValue] at htag
      rcases htag with hfresh | hold
      · have : tag = nextTag := by simpa [taggedLinearTagsValue] using hfresh
        subst tag
        exact Nat.lt_succ_self _
      · have hold' := hbefore tag (by simpa [taggedLinearTags,
          taggedLinearTagsProgram, taggedLinearTagsAtom, taggedLinearTagsValue,
          or_comm, or_left_comm, or_assoc] using hold)
        exact Nat.lt_succ_of_lt hold'
  | push =>
      intro tag htag
      exact hbefore tag (by simpa [taggedLinearTags, taggedLinearTagsProgram,
        taggedLinearTagsAtom, taggedLinearTagsValue, or_comm, or_left_comm,
        or_assoc] using htag)
  | quotation =>
      rename_i body stack rest nextTag
      intro tag htag
      simp [aQuotationTarget, taggedLinearTags, taggedLinearTagsValue] at htag
      rcases htag with hfresh | hrest
      · have : tag = nextTag := by simpa [taggedLinearTagsValue] using hfresh
        subst tag
        exact Nat.lt_succ_self _
      · exact Nat.lt_succ_of_lt (hbefore tag (by simpa [aQuotationSource,
          taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
          taggedLinearTagsValue, or_comm, or_left_comm, or_assoc] using hrest))
  | dup h =>
      intro tag htag
      exact hbefore tag (by simpa [taggedLinearTags, taggedLinearTagsProgram,
        taggedLinearTagsAtom, taggedLinearTagsValue, h, or_comm, or_left_comm,
        or_assoc] using htag)
  | drop h =>
      intro tag htag
      exact hbefore tag (by simpa [taggedLinearTags, taggedLinearTagsProgram,
        taggedLinearTagsAtom, taggedLinearTagsValue, h, or_comm, or_left_comm,
        or_assoc] using htag)
  | swap =>
      intro tag htag
      exact hbefore tag (by simpa [taggedLinearTags, taggedLinearTagsProgram,
        taggedLinearTagsAtom, taggedLinearTagsValue, or_comm, or_left_comm,
        or_assoc] using htag)
  | call =>
      rename_i body tail rest usage tag nextTag
      intro tag htag
      simp [taggedLinearTags] at htag
      apply hbefore tag
      rcases htag with htail | hprog
      · simp [taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
          taggedLinearTagsValue, htail, or_comm, or_left_comm, or_assoc]
      · rw [taggedLinearTagsProgram_append] at hprog
        rcases List.mem_append.mp hprog with hbody | hrest
        · simp [taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
            taggedLinearTagsValue, hbody, or_comm, or_left_comm, or_assoc]
        · simp [taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
            taggedLinearTagsValue, hrest, or_comm, or_left_comm, or_assoc]
  | dip =>
      rename_i body value tail rest usage tag nextTag
      intro tag htag
      simp [taggedLinearTags] at htag
      apply hbefore tag
      rcases htag with htail | hprog
      · simp [taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
          taggedLinearTagsValue, htail, or_comm, or_left_comm, or_assoc]
      · rw [taggedLinearTagsProgram_append] at hprog
        rcases List.mem_append.mp hprog with hbody | hrest
        · simp [taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
            taggedLinearTagsValue, hbody, or_comm, or_left_comm, or_assoc]
        · change tag ∈ taggedLinearTagsValue value ++ taggedLinearTagsProgram rest at hrest
          rcases List.mem_append.mp hrest with hvalue | hrest
          · simp [taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
              taggedLinearTagsValue, hvalue, or_comm, or_left_comm, or_assoc]
          · simp [taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
              taggedLinearTagsValue, hrest, or_comm, or_left_comm, or_assoc]
  | compose =>
      rename_i first second usage₁ usage₂ tail rest tag₁ tag₂ nextTag
      intro tag htag
      simp only [taggedLinearTags, List.mem_append] at htag
      rcases htag with hstack | hprog
      · simp only [List.foldr, taggedLinearTagsValue, taggedLinearTagsProgram,
          taggedLinearTagsAtom, taggedLinearTagsProgram_append, List.mem_append,
          List.mem_cons] at hstack
        rcases hstack with h123 | htail
        · rcases h123 with hfresh | hbody | hbody
          · subst tag
            exact Nat.lt_add_one _
          · apply Nat.lt_succ_of_lt
            apply hbefore tag
            simp only [taggedLinearTags, List.mem_append, List.foldr,
              taggedLinearTagsValue, taggedLinearTagsProgram, taggedLinearTagsAtom,
              List.mem_cons]
            exact Or.inl (Or.inr (Or.inl (Or.inr hbody)))
          · apply Nat.lt_succ_of_lt
            apply hbefore tag
            simp only [taggedLinearTags, List.mem_append, List.foldr,
              taggedLinearTagsValue, taggedLinearTagsProgram, taggedLinearTagsAtom,
              List.mem_cons]
            exact Or.inl (Or.inl (Or.inr hbody))
        · apply Nat.lt_succ_of_lt
          apply hbefore tag
          simp only [taggedLinearTags, List.mem_append, List.foldr,
            taggedLinearTagsValue, taggedLinearTagsProgram, taggedLinearTagsAtom,
            List.mem_cons]
          exact Or.inl (Or.inr (Or.inr htail))
      · apply Nat.lt_succ_of_lt
        apply hbefore tag
        simp only [taggedLinearTags, List.mem_append, taggedLinearTagsProgram,
          taggedLinearTagsProgram_append, List.mem_cons, List.foldr]
        exact Or.inr (Or.inr hprog)
  | quote =>
      rename_i value tail rest nextTag
      intro tag htag
      simp [taggedLinearTags, taggedLinearTagsValue] at htag
      rcases htag with hfresh | hold
      · have : tag = nextTag := by simpa [taggedLinearTagsValue] using hfresh
        subst tag
        exact Nat.lt_succ_self _
      · exact Nat.lt_succ_of_lt (hbefore tag (by simpa [taggedLinearTags,
        taggedLinearTagsProgram,
        taggedLinearTagsAtom, taggedLinearTagsValue, or_comm, or_left_comm,
        or_assoc] using hold))
  | ifThenElse =>
      rename_i condition trueBranch falseBranch tail rest falseTag trueTag conditionTag nextTag
      intro tag htag
      cases condition <;> apply hbefore tag <;>
        simp only [taggedLinearTags, taggedLinearTagsProgram_append, AProgram.append,
          List.mem_append, List.foldr, taggedLinearTagsProgram, taggedLinearTagsAtom,
          taggedLinearTagsValue, List.mem_cons, Bool.false_eq_true] at htag ⊢
      · rcases htag with htail | hbranch | hrest
        · exact Or.inl (Or.inr (Or.inr (Or.inr htail)))
        · exact Or.inl (Or.inl (Or.inr hbranch))
        · exact Or.inr (Or.inr hrest)
      · rcases htag with htail | hbranch | hrest
        · exact Or.inl (Or.inr (Or.inr (Or.inr htail)))
        · exact Or.inl (Or.inr (Or.inl (Or.inr hbranch)))
        · exact Or.inr (Or.inr hrest)
  | word h =>
      rcases h with ⟨entry, hname, hbody, htags⟩
      intro tag htag
      simp only [taggedLinearTags, List.mem_append] at htag
      rcases htag with hstack | hprog
      · exact hbefore tag (by
          simp only [taggedLinearTags, List.mem_append]
          exact Or.inl hstack)
      · simp only [taggedLinearTagsProgram_append, List.mem_append] at hprog
        rcases hprog with hbody' | hrest
        · exact htags tag hbody'
        · exact hbefore tag (by simp [taggedLinearTags, taggedLinearTagsProgram, hrest])
  | prim h =>
      rcases h with ⟨specification, plainInput, plainOutput, hname, hin, hdelta,
        hout, hnext, hnd, htags⟩
      intro tag htag
      simp only [taggedLinearTags, List.mem_append] at htag
      rcases htag with houtput | hrest
      · exact htags tag (by
          rw [taggedLinearTagsValueList_eq_foldr]
          exact houtput)
      · exact Nat.lt_of_lt_of_le
          (hbefore tag (by simp [taggedLinearTags, taggedLinearTagsProgram, hrest])) hnext

theorem instrumented_step_erases
    (hstep : InstrumentedStep gamma dictionary costs before after) :
    HasSuccessor gamma dictionary costs (eraseAConfig before) (eraseAConfig after) := by
  cases hstep with
  | lit h nextTag => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom,
      eraseProgram, h]
  | push => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom, eraseProgram]
  | quotation => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom,
      eraseProgram, aQuotationSource, aQuotationTarget]
  | dup h => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom,
      eraseProgram, h]
  | drop h => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom,
      eraseProgram, h]
  | swap => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom, eraseProgram]
  | call => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom,
      eraseProgram, eraseProgram_append]
  | dip => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom,
      eraseProgram, eraseProgram_append]
  | compose => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom,
      eraseProgram, eraseProgram_append]
  | quote => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom,
      eraseProgram, quotationUsage]
  | ifThenElse => simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom,
      eraseProgram, eraseProgram_append, eraseProgram_if]
  | word h =>
      rcases h with ⟨entry, hdict, herase, hfront⟩
      simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom, eraseProgram,
        hdict, herase, eraseProgram_append]
  | prim h =>
      rcases h with ⟨specification, plainInput, plainOutput, hname, hin, hdelta,
        hout, hnext, hnd, htags⟩
      simp [HasSuccessor, step, eraseAConfig, eraseValue, eraseAtom, eraseProgram,
        hname, hin, hdelta, hout]

def InstrumentedTrace (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) :
    AConfig → List AConfig → Prop
  | start, [] => True
  | start, next :: rest =>
      InstrumentedStep gamma dictionary costs start next ∧
        InstrumentedTrace gamma dictionary costs next rest

end Firth.Interpreter
