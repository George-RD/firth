import Firth.KernelMetatheory

namespace Firth.Interpreter

abbrev OwnershipId := Nat
abbrev Ownerships := List OwnershipId

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
    | .literal _ _ => []
    | .world tag _ => [tag]
    | .quotation tag body usage =>
        (if usage == .linear then [tag] else []) ++ taggedLinearTagsProgram body

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

/-! Adjacent ownership events.  These are identities in the instrumented
configuration, never payloads in the erased interpreter.  The filters use the
decidable `Bool` membership operation, so an event is constructive data. -/

def beforeTags (before after : AConfig) : Ownerships := taggedLinearTags before
def afterTags (before after : AConfig) : Ownerships := taggedLinearTags after
def preserved (before after : AConfig) : Ownerships :=
  (beforeTags before after).filter (fun tag => (afterTags before after).contains tag)
def consumed (before after : AConfig) : Ownerships :=
  (beforeTags before after).filter (fun tag => !(afterTags before after).contains tag)
def produced (before after : AConfig) : Ownerships :=
  (afterTags before after).filter (fun tag => !(beforeTags before after).contains tag)

def traceConsumed (configs : List AConfig) : Ownerships :=
  match configs with
  | before :: after :: rest => consumed before after ++ traceConsumed (after :: rest)
  | _ => []

def InstrumentedTraceConsumed (trace : List AConfig) : Ownerships := traceConsumed trace

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

theorem mem_filter_bool_iff {p : OwnershipId → Bool} {tag : OwnershipId}
    {tags : Ownerships} :
    tag ∈ tags.filter p ↔ tag ∈ tags ∧ p tag = true := by
  induction tags with
  | nil => simp only [List.filter, List.not_mem_nil, false_and, iff_false]
  | cons head tail ih =>
      by_cases h : p head = true
      · simp only [List.filter, h, List.mem_cons]
        constructor
        · intro hm
          rcases hm with rfl | hm
          · exact ⟨Or.inl rfl, h⟩
          · exact ⟨Or.inr (ih.mp hm).1, (ih.mp hm).2⟩
        · rintro ⟨hm, hp⟩
          rcases hm with rfl | hm
          · exact Or.inl rfl
          · exact Or.inr (ih.mpr ⟨hm, hp⟩)
      · simp only [List.filter, h, Bool.false_eq_true]
        constructor
        · intro hm
          exact ⟨List.mem_cons_of_mem _ (ih.mp hm).1, (ih.mp hm).2⟩
        · rintro ⟨hm, hp⟩
          rcases List.mem_cons.mp hm with hhead | hm
          · exact (h (by simpa [hhead] using hp)).elim
          · exact ih.mpr ⟨hm, hp⟩

theorem mem_produced_iff {before after : AConfig} {tag : OwnershipId} :
    tag ∈ produced before after ↔
      tag ∈ afterTags before after ∧ tag ∉ beforeTags before after := by
  rw [produced, mem_filter_bool_iff]
  constructor
  · rintro ⟨hafter, hnotContains⟩
    refine ⟨hafter, ?_⟩
    intro hbefore
    have hcontains : (beforeTags before after).contains tag = true :=
      List.contains_iff.mpr hbefore
    rw [hcontains] at hnotContains
    cases hnotContains
  · rintro ⟨hafter, hbefore⟩
    refine ⟨hafter, ?_⟩
    cases hcontains : (beforeTags before after).contains tag with
    | false => rfl
    | true => exact (hbefore (List.contains_iff.mp hcontains)).elim

theorem nodup_filter_bool {p : OwnershipId → Bool} {tags : Ownerships}
    (h : tags.Nodup) : (tags.filter p).Nodup := by
  induction tags with
  | nil => exact List.nodup_nil
  | cons head tail ih =>
      by_cases hp : p head = true
      · simp only [List.filter, hp]
        have hparts := List.nodup_cons.mp h
        exact List.nodup_cons.mpr ⟨
          (fun hmem => hparts.1 (mem_filter_bool_iff.mp hmem).1),
          ih hparts.2⟩
      · simp only [List.filter, hp, Bool.false_eq_true]
        exact ih (List.nodup_cons.mp h).2

def TagsDisjoint (left right : Ownerships) : Prop :=
  ∀ tag, tag ∈ left → tag ∉ right

theorem filter_complement_disjoint {p : OwnershipId → Bool} {tags : Ownerships} :
    TagsDisjoint (tags.filter p) (tags.filter (fun tag => !p tag)) := by
  intro tag hleft hright
  have hpl := (mem_filter_bool_iff.mp hleft).2
  have hpr := (mem_filter_bool_iff.mp hright).2
  cases hp : p tag <;> simp [hp] at hpl hpr

theorem filter_partition_membership {p : OwnershipId → Bool} {tags : Ownerships} :
    ∀ tag, tag ∈ tags ↔
      tag ∈ tags.filter p ∨ tag ∈ tags.filter (fun value => !p value) := by
  intro tag
  constructor
  · intro htag
    by_cases hp : p tag = true
    · exact Or.inl ((mem_filter_bool_iff.mpr ⟨htag, hp⟩))
    · exact Or.inr (mem_filter_bool_iff.mpr ⟨htag, by simp [hp]⟩)
  · intro htag
    rcases htag with htag | htag
    · exact (mem_filter_bool_iff.mp htag).1
    · exact (mem_filter_bool_iff.mp htag).1

theorem filter_not_contains_self (tags : Ownerships) :
    tags.filter (fun tag => !(tags.contains tag)) = [] := by
  apply List.eq_nil_iff_forall_not_mem.mpr
  intro tag htag
  have hfiltered := mem_filter_bool_iff.mp htag
  have hcontains : tags.contains tag = true := List.contains_iff.mpr hfiltered.1
  have hnot : tags.contains tag ≠ true := by
    intro htrue
    rw [htrue] at hfiltered
    simp at hfiltered
  exact hnot hcontains

 theorem mem_filter_not_contains_self {tags : Ownerships} {tag : OwnershipId}
    (h : tag ∈ tags.filter (fun value => !(tags.contains value))) : False := by
  rw [filter_not_contains_self tags] at h
  cases h

abbrev PrimitiveAuthorisation :=
  Prim → Ownerships → Ownerships → Prop

def primitiveAuthorisation : PrimitiveAuthorisation :=
  fun name consumed produced =>
    match name with
    | "addNat" => consumed = [] ∧ produced = []
    | "makeWorld" => consumed = [] ∧ produced.length = 1
    | "consumeWorld" => consumed.length = 1 ∧ produced = []
    | _ => False

structure PrimitiveTagContract (authorised : PrimitiveAuthorisation)
    (gamma : Gamma) (name : Prim) (input output : AStack) (residue : AProgram)
    (specification : PrimitiveSpec) (plainInput plainOutput : Stack)
    (rowTail retained consumed produced : Ownerships)
    (nextTag nextTag' : Tag) : Prop where
  name_resolves : gamma.primitive name = some specification
  input_erases : input.map eraseValue = plainInput
  delta : specification.delta plainInput = some plainOutput
  output_erases : output.map eraseValue = plainOutput
  input_partition : ∀ tag, tag ∈ taggedLinearTagsValueList input ↔
    tag ∈ retained ∨ tag ∈ consumed
  output_partition : ∀ tag, tag ∈ taggedLinearTagsValueList output ↔
    tag ∈ retained ∨ tag ∈ produced
  retained_nodup : retained.Nodup
  consumed_nodup : consumed.Nodup
  produced_nodup : produced.Nodup
  retained_exact : ∀ tag, tag ∈ retained ↔
    tag ∈ taggedLinearTagsValueList input ∧ tag ∈ taggedLinearTagsValueList output
  consumed_exact : ∀ tag, tag ∈ consumed ↔
    tag ∈ taggedLinearTagsValueList input ∧ tag ∉ taggedLinearTagsValueList output
  produced_exact : ∀ tag, tag ∈ produced ↔
    tag ∈ taggedLinearTagsValueList output ∧ tag ∉ taggedLinearTagsValueList input
  retained_unchanged : retained =
    (taggedLinearTagsValueList input).filter
      (fun tag => (taggedLinearTagsValueList output).contains tag)
  consumed_absent : ∀ tag, tag ∈ consumed →
    tag ∉ taggedLinearTagsValueList output ∧ tag ∉ taggedLinearTagsProgram residue
  produced_fresh : ∀ tag, tag ∈ produced → nextTag ≤ tag ∧ tag < nextTag'
  output_residue_nodup :
    (taggedLinearTagsValueList output ++ taggedLinearTagsProgram residue).Nodup
  frontier_monotone : nextTag ≤ nextTag'
  row_tail_retained : ∀ tag, tag ∈ rowTail → tag ∈ retained
  authorised : authorised name consumed produced

/- A dictionary body is annotated at the frontier at which the word is
unfolded.  It is not a globally tagged cache: each word step receives a fresh
annotation of the plain body and an advanced frontier. -/
def DictionaryTagContract (dictionary : Dictionary) : Prop :=
  ∀ name entry body frontier frontier',
    dictionary name = some entry →
    eraseProgram body = entry.body →
    (∀ tag, tag ∈ taggedLinearTagsProgram body → tag < frontier') →
    frontier ≤ frontier'

def aQuotationSource (stack : AStack) (body rest : AProgram) (nextTag : Tag) : AConfig :=
  { stack := stack, program := .cons (.quotation body) rest, nextTag := nextTag }

def aQuotationTarget (stack : AStack) (body rest : AProgram) (nextTag : Tag) : AConfig :=
  { stack := .quotation nextTag body (programUsage (eraseProgram body)) :: stack, program := rest,
    nextTag := nextTag + 1 }

def WordAnnotation (plain : Program) (body : AProgram) (frontier frontier' : Tag) : Prop :=
  eraseProgram body = plain ∧ frontier ≤ frontier' ∧
    (∀ tag, tag ∈ taggedLinearTagsProgram body → frontier ≤ tag ∧ tag < frontier') ∧
    (taggedLinearTagsProgram body).Nodup

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
      {nextTag nextTag' : Tag}
      (h : ∃ entry, dictionary name = some entry ∧ WordAnnotation entry.body body nextTag nextTag') :
      InstrumentedStep gamma dictionary costs
        { stack := stack, program := .cons (.word name) rest, nextTag := nextTag }
        { stack := stack, program := AProgram.append body rest, nextTag := nextTag' }
  | prim {primitive : Prim} {input output : AStack} {rest : AProgram}
      {specification : PrimitiveSpec} {plainInput plainOutput : Stack}
      {rowTail retained consumed produced : Ownerships}
      {nextTag nextTag' : Tag}
      (h : ∃ specification plainInput plainOutput rowTail retained consumed produced,
        PrimitiveTagContract primitiveAuthorisation gamma primitive input output rest
          specification plainInput plainOutput rowTail retained consumed produced
          nextTag nextTag') :
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
      have hold := hbefore tag (by simpa [taggedLinearTags,
          taggedLinearTagsProgram, taggedLinearTagsAtom, taggedLinearTagsValue] using htag)
      exact Nat.lt_succ_of_lt hold
  | push =>
      intro tag htag
      exact hbefore tag (by simpa [taggedLinearTags, taggedLinearTagsProgram,
        taggedLinearTagsAtom, taggedLinearTagsValue, or_comm, or_left_comm,
        or_assoc] using htag)
  | quotation =>
      rename_i body stack rest nextTag
      intro tag htag
      by_cases hlinear : programUsage (eraseProgram body) == Usage.linear
      · simp [aQuotationTarget, taggedLinearTags, taggedLinearTagsValue, hlinear] at htag
        rcases htag with hfresh | hrest
        · have : tag = nextTag := by simpa using hfresh
          subst tag
          exact Nat.lt_succ_self _
        · exact Nat.lt_succ_of_lt (hbefore tag (by simpa [aQuotationSource,
            taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
            taggedLinearTagsValue, hlinear, or_comm, or_left_comm, or_assoc] using hrest))
      · simp [aQuotationTarget, taggedLinearTags, taggedLinearTagsValue, hlinear] at htag
        exact Nat.lt_succ_of_lt (hbefore tag (by simpa [aQuotationSource,
          taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
          taggedLinearTagsValue, hlinear, or_comm, or_left_comm, or_assoc] using htag))
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
          · by_cases hlinear : ((if (usage₁ == Usage.linear) = true ∨
              (usage₂ == Usage.linear) = true then Usage.linear else Usage.many) ==
              Usage.linear) = true
            · simp [hlinear] at hfresh
              rcases hfresh with ⟨_, rfl⟩
              exact Nat.lt_succ_self _
            · simp [hlinear] at hfresh
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
      by_cases hlinear : quotationUsage (eraseValue value) == .linear
      · simp [taggedLinearTags, taggedLinearTagsValue, hlinear] at htag
        rcases htag with hfresh | hold
        · have : tag = nextTag := by simpa using hfresh
          subst tag
          exact Nat.lt_succ_self _
        · exact Nat.lt_succ_of_lt (hbefore tag (by simpa [taggedLinearTags,
          taggedLinearTagsProgram, taggedLinearTagsAtom, taggedLinearTagsValue,
          hlinear] using hold))
      · simp [taggedLinearTags, taggedLinearTagsValue, hlinear] at htag
        exact Nat.lt_succ_of_lt (hbefore tag (by simpa [taggedLinearTags,
          taggedLinearTagsProgram, taggedLinearTagsAtom, taggedLinearTagsValue,
          hlinear] using htag))
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
      rcases h with ⟨entry, hname, hannotation⟩
      rcases hannotation with ⟨hbody, hadvance, htags, hnd⟩
      intro tag htag
      simp only [taggedLinearTags, List.mem_append] at htag
      rcases htag with hstack | hprog
      · exact Nat.lt_of_lt_of_le (hbefore tag (by
          simp only [taggedLinearTags, List.mem_append]
          exact Or.inl hstack)) hadvance
      · simp only [taggedLinearTagsProgram_append, List.mem_append] at hprog
        rcases hprog with hbody' | hrest
        · exact (htags tag hbody').2
        · exact Nat.lt_of_lt_of_le (hbefore tag (by
            simp [taggedLinearTags, taggedLinearTagsProgram, hrest])) hadvance
  | @prim primitive input output rest specification plainInput plainOutput rowTail retained consumed produced nextTag nextTag' h =>
      rcases h with ⟨specification, plainInput, plainOutput, rowTail, retained,
        consumed, produced, h⟩
      have hnext := h.frontier_monotone
      have hupper : ∀ tag, tag ∈ taggedLinearTagsValueList output → tag < nextTag' := by
        intro tag htag
        rcases (h.output_partition tag).mp htag with hretained | hproduced
        · apply Nat.lt_of_lt_of_le (hbefore tag ?_) hnext
          simp only [taggedLinearTags, List.mem_append]
          exact Or.inl (by
            simpa only [taggedLinearTagsValueList_eq_foldr] using
              (h.input_partition tag).mpr (Or.inl hretained))
        · exact (h.produced_fresh tag hproduced).2
      intro tag htag
      simp only [taggedLinearTags, List.mem_append] at htag
      rcases htag with houtput | hrest
      · exact hupper tag (by
          rw [taggedLinearTagsValueList_eq_foldr]
          exact houtput)
      · exact Nat.lt_of_lt_of_le
          (hbefore tag (by simp [taggedLinearTags, taggedLinearTagsProgram, hrest])) hnext

theorem instrumented_step_erases_lit
    {config : AConfig} {literal : Literal} {rest : AProgram}
    (h : (gamma.literalType literal).isSome) (nextTag : Tag) :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨config.stack, .cons (.lit literal) rest, nextTag⟩)
      (eraseAConfig ⟨.literal nextTag literal :: config.stack, rest,
        nextTag + 1⟩) := by
  refine ⟨costs.atom (.lit literal), ?_⟩
  simp only [step, h, eraseAConfig, eraseValue, eraseAtom, eraseProgram, List.map]
  rfl

theorem instrumented_step_erases_push
    {value : AValue} {stack : AStack} {rest : AProgram} {nextTag : Tag} :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨stack, .cons (.push value) rest, nextTag⟩)
      (eraseAConfig ⟨value :: stack, rest, nextTag⟩) := by
  refine ⟨0, ?_⟩
  rfl

theorem instrumented_step_erases_quotation
    {body : AProgram} {stack : AStack} {rest : AProgram} {nextTag : Tag} :
    HasSuccessor gamma dictionary costs
      (eraseAConfig (aQuotationSource stack body rest nextTag))
      (eraseAConfig (aQuotationTarget stack body rest nextTag)) := by
  refine ⟨costs.atom (.quotation (eraseProgram body)), ?_⟩
  rfl

theorem instrumented_step_erases_dup
    {value : AValue} {tail : AStack} {rest : AProgram} {nextTag : Tag}
    (h : taggedLinearTagsValue value = []) :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨value :: tail, .cons .dup rest, nextTag⟩)
      (eraseAConfig ⟨value :: value :: tail, rest, nextTag⟩) := by
  refine ⟨costs.atom .dup, ?_⟩
  rfl

theorem instrumented_step_erases_drop
    {value : AValue} {tail : AStack} {rest : AProgram} {nextTag : Tag}
    (h : taggedLinearTagsValue value = []) :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨value :: tail, .cons .drop rest, nextTag⟩)
      (eraseAConfig ⟨tail, rest, nextTag⟩) := by
  refine ⟨costs.atom .drop, ?_⟩
  rfl

theorem instrumented_step_erases_swap
    {first second : AValue} {tail : AStack} {rest : AProgram} {nextTag : Tag} :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨second :: first :: tail, .cons .swap rest, nextTag⟩)
      (eraseAConfig ⟨first :: second :: tail, rest, nextTag⟩) := by
  refine ⟨costs.atom .swap, ?_⟩
  rfl

theorem instrumented_step_erases_call
    {body : AProgram} {tail : AStack} {rest : AProgram}
    {usage : Usage} {tag nextTag : Tag} :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨.quotation tag body usage :: tail, .cons .call rest, nextTag⟩)
      (eraseAConfig ⟨tail, AProgram.append body rest, nextTag⟩) := by
  refine ⟨costs.atom .call, ?_⟩
  simp only [step, eraseAConfig, eraseValue, eraseAtom, eraseProgram,
    eraseProgram_append, List.map]

theorem instrumented_step_erases_dip
    {body : AProgram} {value : AValue} {tail : AStack} {rest : AProgram}
    {usage : Usage} {tag nextTag : Tag} :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨.quotation tag body usage :: value :: tail, .cons .dip rest, nextTag⟩)
      (eraseAConfig ⟨tail, AProgram.append body (.cons (.push value) rest), nextTag⟩) := by
  refine ⟨costs.atom .dip, ?_⟩
  simp only [step, eraseAConfig, eraseValue, eraseAtom, eraseProgram,
    eraseProgram_append, List.map]

theorem instrumented_step_erases_compose
    {first second : AProgram} {usage₁ usage₂ : Usage} {tail : AStack}
    {rest : AProgram} {tag₁ tag₂ nextTag : Tag} :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨.quotation tag₂ second usage₂ :: .quotation tag₁ first usage₁ :: tail,
        .cons .compose rest, nextTag⟩)
      (eraseAConfig ⟨.quotation nextTag (AProgram.append first second)
          (if usage₁ == .linear || usage₂ == .linear then .linear else .many) :: tail,
        rest, nextTag + 1⟩) := by
  refine ⟨costs.atom .compose, ?_⟩
  cases usage₁ <;> cases usage₂ <;>
    simp only [step, eraseAConfig, eraseValue, eraseAtom, eraseProgram,
      eraseProgram_append, List.map, Bool.false_eq_true, if_true, if_false]

theorem instrumented_step_erases_quote
    {value : AValue} {tail : AStack} {rest : AProgram} {nextTag : Tag} :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨value :: tail, .cons .quote rest, nextTag⟩)
      (eraseAConfig ⟨.quotation nextTag (.cons (.push value) .empty)
          (quotationUsage (eraseValue value)) :: tail, rest, nextTag + 1⟩) := by
  refine ⟨costs.atom .quote, ?_⟩
  rfl

theorem instrumented_step_erases_ifThenElse
    {condition : Bool} {trueBranch falseBranch : AProgram} {tail : AStack}
    {rest : AProgram} {falseTag trueTag conditionTag nextTag : Tag} :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨.quotation falseTag falseBranch .many ::
          .quotation trueTag trueBranch .many :: .literal conditionTag (.bool condition) :: tail,
        .cons .ifThenElse rest, nextTag⟩)
      (eraseAConfig ⟨tail, AProgram.append (if condition then trueBranch else falseBranch) rest,
        nextTag⟩) := by
  cases condition
  · refine ⟨costs.atom .ifThenElse, ?_⟩
    simp only [step, eraseAConfig, eraseValue, eraseAtom, eraseProgram, eraseProgram_append,
      eraseProgram_if, List.map, Bool.false_eq_true, if_false, if_true]
  · refine ⟨costs.atom .ifThenElse, ?_⟩
    simp only [step, eraseAConfig, eraseValue, eraseAtom, eraseProgram, eraseProgram_append,
      eraseProgram_if, List.map, Bool.false_eq_true, if_false, if_true]

theorem instrumented_step_erases_word
    {name : String} {body : AProgram} {stack : AStack} {rest : AProgram}
    {nextTag : Tag}
    {nextTag' : Tag}
    (h : ∃ entry, dictionary name = some entry ∧ WordAnnotation entry.body body nextTag nextTag') :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨stack, .cons (.word name) rest, nextTag⟩)
      (eraseAConfig ⟨stack, AProgram.append body rest, nextTag'⟩) := by
  rcases h with ⟨entry, hdict, ⟨herase, hadvance, hfront, hnd⟩⟩
  refine ⟨costs.unfold, ?_⟩
  simp only [step, eraseAConfig, eraseValue, eraseAtom, eraseProgram,
    hdict, herase, eraseProgram_append]

theorem instrumented_step_erases_prim
    {primitive : Prim} {input output : AStack} {rest : AProgram}
    {nextTag nextTag' : Tag}
    (h : ∃ specification plainInput plainOutput rowTail retained consumed produced,
      PrimitiveTagContract primitiveAuthorisation gamma primitive input output rest
        specification plainInput plainOutput rowTail retained consumed produced
        nextTag nextTag') :
    HasSuccessor gamma dictionary costs
      (eraseAConfig ⟨input, .cons (.prim primitive) rest, nextTag⟩)
      (eraseAConfig ⟨output, rest, nextTag'⟩) := by
  rcases h with ⟨specification, plainInput, plainOutput, rowTail, retained, consumed,
    produced, h⟩
  refine ⟨costs.primitive primitive, ?_⟩
  simp only [step, eraseAConfig, eraseValue, eraseAtom, eraseProgram,
    h.name_resolves, h.input_erases, h.delta, h.output_erases]

theorem instrumented_step_erases
    (hstep : InstrumentedStep gamma dictionary costs before after) :
    HasSuccessor gamma dictionary costs (eraseAConfig before) (eraseAConfig after) := by
  cases hstep with
  | lit h nextTag => exact instrumented_step_erases_lit h nextTag
  | push => exact instrumented_step_erases_push
  | quotation => exact instrumented_step_erases_quotation
  | dup h => exact instrumented_step_erases_dup h
  | drop h => exact instrumented_step_erases_drop h
  | swap => exact instrumented_step_erases_swap
  | call => exact instrumented_step_erases_call
  | dip => exact instrumented_step_erases_dip
  | compose => exact instrumented_step_erases_compose
  | quote => exact instrumented_step_erases_quote
  | ifThenElse => exact instrumented_step_erases_ifThenElse
  | word h => exact instrumented_step_erases_word h
  | prim h =>
      simpa using (instrumented_step_erases_prim (gamma := gamma)
        (dictionary := dictionary) (costs := costs) h)

def InstrumentedTrace (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) :
    AConfig → List AConfig → Prop
  | start, [] => True
  | start, next :: rest =>
        InstrumentedStep gamma dictionary costs start next ∧
        InstrumentedTrace gamma dictionary costs next rest

/-! The adjacent invariant is a property of a transition, not a field copied
from an accounting record.  In particular, all event lists below are computed
from the two configurations. -/
def StepOwnership (before after : AConfig)
    (hstep : InstrumentedStep gamma dictionary costs before after) : Prop :=
  (afterTags before after).Nodup ∧
    (∀ tag, tag ∈ consumed before after → tag ∉ afterTags before after) ∧
    (∀ tag, tag ∈ produced before after → tag ∉ beforeTags before after) ∧
    (∀ tag, tag ∈ produced before after →
      before.nextTag ≤ tag ∧ tag < after.nextTag) ∧
    before.nextTag ≤ after.nextTag

def InstrumentedWellFormedAt (config : AConfig) : Prop :=
  (taggedLinearTags config).Nodup ∧ FrontierInvariant config

theorem step_ownership_from_events
    {before after : AConfig}
    {hstep : InstrumentedStep gamma dictionary costs before after}
    (hafter : (afterTags before after).Nodup)
    (hproduced : ∀ tag, tag ∈ produced before after →
      before.nextTag ≤ tag ∧ tag < after.nextTag)
    (hfrontier : before.nextTag ≤ after.nextTag) :
    StepOwnership before after hstep := by
  refine ⟨hafter, ?_, ?_, hproduced, hfrontier⟩
  intro tag htag hafterTag
  have hfiltered := mem_filter_bool_iff.mp htag
  have hcontains : (afterTags before after).contains tag = true :=
    List.contains_iff.mpr hafterTag
  have hnot : (afterTags before after).contains tag ≠ true := by
    intro htrue
    rw [htrue] at hfiltered
    simp at hfiltered
  exact (hnot hcontains).elim
  intro tag htag hbeforeTag
  have hfiltered := mem_filter_bool_iff.mp htag
  have hcontains : (beforeTags before after).contains tag = true :=
    List.contains_iff.mpr hbeforeTag
  have hnot : (beforeTags before after).contains tag ≠ true := by
    intro htrue
    have hfalse : (beforeTags before after).contains tag = false := by
      simpa using hfiltered.2
    rw [htrue] at hfalse
    cases hfalse
  exact (hnot hcontains).elim

theorem nodup_reorder_three (left middle right : Ownerships)
    (h : (left ++ middle ++ right).Nodup) :
    (middle ++ left ++ right).Nodup := by
  exact List.Perm.nodup
    (List.Perm.append_right right
      (List.perm_append_comm (l₁ := left) (l₂ := middle))) h

theorem step_ownership_of_tag_permutation
    {before after : AConfig}
    {hstep : InstrumentedStep gamma dictionary costs before after}
    (hbefore : (taggedLinearTags before).Nodup)
    (htags : (afterTags before after).Perm (beforeTags before after))
    (hfrontier : before.nextTag ≤ after.nextTag) :
    StepOwnership before after hstep := by
  apply step_ownership_from_events
  · exact htags.symm.nodup hbefore
  · intro tag htag
    have hfiltered := mem_filter_bool_iff.mp htag
    have hmem : tag ∈ beforeTags before after := htags.mem_iff.mp hfiltered.1
    have hcontains := List.contains_iff.mpr hmem
    have hnot : (beforeTags before after).contains tag ≠ true := by
      intro htrue
      rw [htrue] at hfiltered
      simp at hfiltered
    exact False.elim (hnot hcontains)
  · exact hfrontier

set_option maxHeartbeats 2000000 in
theorem step_ownership_of_step
    (hbefore : InstrumentedWellFormedAt before)
    (hstep : InstrumentedStep gamma dictionary costs before after) :
    StepOwnership before after hstep := by
  cases hstep with
  | @lit config literal rest h nextTag =>
      have htags : afterTags
          { stack := config.stack, program := .cons (.lit literal) rest, nextTag := nextTag }
          { stack := .literal nextTag literal :: config.stack, program := rest,
            nextTag := nextTag + 1 } =
          beforeTags
          { stack := config.stack, program := .cons (.lit literal) rest, nextTag := nextTag }
          { stack := .literal nextTag literal :: config.stack, program := rest,
            nextTag := nextTag + 1 } := rfl
      apply step_ownership_from_events
      · rw [htags]
        exact hbefore.1
      · intro tag htag
        have hfiltered := mem_filter_bool_iff.mp htag
        rw [htags] at hfiltered
        rcases hfiltered with ⟨hmem, hnot⟩
        have hcontains := List.contains_iff.mpr hmem
        rw [hcontains] at hnot
        simp at hnot
      · exact Nat.le_add_right _ _
  | push =>
      rename_i value stack rest nextTag
      apply step_ownership_of_tag_permutation hbefore.1
      · simpa only [beforeTags, afterTags, taggedLinearTags, taggedLinearTagsAtom,
          taggedLinearTagsProgram, taggedLinearTagsValue, List.foldr, List.append_assoc]
          using (List.Perm.append_right (taggedLinearTagsProgram rest)
            (List.perm_append_comm
            (l₁ := List.foldr (fun value tags => taggedLinearTagsValue value ++ tags) [] stack)
            (l₂ := taggedLinearTagsValue value)).symm)
      · change nextTag ≤ nextTag
        exact Nat.le_refl _
  | quotation =>
      rename_i body stack rest nextTag
      by_cases hlinear : programUsage (eraseProgram body) == Usage.linear
      · rcases hbefore with ⟨hnodup, hfrontier⟩
        let stackTags :=
          List.foldr (fun value tags => taggedLinearTagsValue value ++ tags) [] stack
        let bodyTags := taggedLinearTagsProgram body
        let restTags := taggedLinearTagsProgram rest
        have hbeforeShape : taggedLinearTags (aQuotationSource stack body rest nextTag) =
            stackTags ++ (bodyTags ++ restTags) := by
          rfl
        have hafterShape : taggedLinearTags (aQuotationTarget stack body rest nextTag) =
            nextTag :: (bodyTags ++ (stackTags ++ restTags)) := by
          simp only [aQuotationTarget, taggedLinearTags, List.foldr,
            taggedLinearTagsValue, hlinear, if_true, List.singleton_append]
          simp only [stackTags, bodyTags, restTags, List.append_assoc]
          rw [List.cons_append]
        change ∀ tag, tag ∈ taggedLinearTags
          (aQuotationSource stack body rest nextTag) → tag < nextTag at hfrontier
        rw [hbeforeShape] at hnodup hfrontier
        have hbasePerm : (bodyTags ++ (stackTags ++ restTags)).Perm
            (stackTags ++ (bodyTags ++ restTags)) := by
          simpa only [List.append_assoc] using
            (List.Perm.append_right restTags
              (List.perm_append_comm (l₁ := bodyTags) (l₂ := stackTags)))
        have hbaseNodup : (bodyTags ++ (stackTags ++ restTags)).Nodup :=
          hbasePerm.symm.nodup hnodup
        have hfresh : nextTag ∉ bodyTags ++ (stackTags ++ restTags) := by
          intro htag
          exact Nat.lt_irrefl _ (hfrontier nextTag (hbasePerm.mem_iff.mp htag))
        apply step_ownership_from_events
        · rw [afterTags, hafterShape]
          exact List.nodup_cons.mpr ⟨hfresh, hbaseNodup⟩
        · intro tag htag
          have hevent := mem_produced_iff.mp htag
          rw [afterTags, hafterShape, beforeTags, hbeforeShape] at hevent
          rcases List.mem_cons.mp hevent.1 with hnew | hbase
          · subst tag
            exact ⟨Nat.le_refl _, Nat.lt_succ_self _⟩
          · exact (hevent.2 (hbasePerm.mem_iff.mp hbase)).elim
        · exact Nat.le_add_right _ _
      · rcases hbefore with ⟨hnodup, hfrontier⟩
        apply step_ownership_of_tag_permutation hnodup
        · simpa only [beforeTags, afterTags, aQuotationSource, aQuotationTarget,
            taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
            taggedLinearTagsValue, List.foldr, hlinear, List.append_assoc]
            using (List.Perm.append_right (taggedLinearTagsProgram rest)
              (List.perm_append_comm
                (l₁ := taggedLinearTagsProgram body)
                (l₂ := List.foldr
                  (fun value tags => taggedLinearTagsValue value ++ tags) [] stack)))
        · exact Nat.le_add_right _ _
  | dup h =>
      rename_i value tail rest nextTag
      apply step_ownership_of_tag_permutation hbefore.1
      · simpa only [beforeTags, afterTags, taggedLinearTags, taggedLinearTagsAtom,
          taggedLinearTagsProgram, taggedLinearTagsValue, List.foldr, List.append_assoc,
          h]
          using (List.Perm.refl _)
      · change nextTag ≤ nextTag
        exact Nat.le_refl _
  | drop h =>
      rename_i value tail rest nextTag
      apply step_ownership_of_tag_permutation hbefore.1
      · simpa only [beforeTags, afterTags, taggedLinearTags, taggedLinearTagsAtom,
          taggedLinearTagsProgram, taggedLinearTagsValue, List.foldr, List.append_assoc,
          h]
          using (List.Perm.refl _)
      · change nextTag ≤ nextTag
        exact Nat.le_refl _
  | swap =>
      rename_i first second tail rest nextTag
      apply step_ownership_of_tag_permutation hbefore.1
      · simpa only [beforeTags, afterTags, taggedLinearTags, taggedLinearTagsAtom,
          taggedLinearTagsProgram, taggedLinearTagsValue, List.foldr, List.append_assoc]
          using (List.Perm.append_right (taggedLinearTagsProgram rest)
            (List.Perm.append_right
              (List.foldr (fun value tags => taggedLinearTagsValue value ++ tags) [] tail)
              (List.perm_append_comm (l₁ := taggedLinearTagsValue second)
                (l₂ := taggedLinearTagsValue first))).symm)
      · change nextTag ≤ nextTag
        exact Nat.le_refl _
  | call =>
      rcases hbefore with ⟨hnodup, hfrontier⟩
      simp only [StepOwnership, beforeTags, afterTags, preserved, consumed, produced,
        taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
        taggedLinearTagsValue, taggedLinearTagsProgram_append, List.foldr,
        List.mem_append, List.append_assoc] at hnodup hfrontier ⊢
      simp [mem_filter_bool_iff] at *
      grind
  | dip =>
      rcases hbefore with ⟨hnodup, hfrontier⟩
      simp only [StepOwnership, beforeTags, afterTags, preserved, consumed, produced,
        taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
        taggedLinearTagsValue, taggedLinearTagsProgram_append, List.foldr,
        List.mem_append, List.append_assoc] at hnodup hfrontier ⊢
      simp [mem_filter_bool_iff] at *
      grind
  | compose =>
      rename_i first second usage₁ usage₂ tail rest tag₁ tag₂ nextTag
      rcases hbefore with ⟨hnodup, hfrontier⟩
      let firstTags := taggedLinearTagsProgram first
      let secondTags := taggedLinearTagsProgram second
      let tailTags :=
        List.foldr (fun value tags => taggedLinearTagsValue value ++ tags) [] tail
      let restTags := taggedLinearTagsProgram rest
      let firstWrapper := if usage₁ == .linear then [tag₁] else []
      let secondWrapper := if usage₂ == .linear then [tag₂] else []
      let outputUsage : Usage :=
        if usage₁ == .linear || usage₂ == .linear then Usage.linear else Usage.many
      have hbeforeShape : taggedLinearTags
          { stack := .quotation tag₂ second usage₂ :: .quotation tag₁ first usage₁ :: tail,
            program := .cons .compose rest, nextTag := nextTag } =
          secondWrapper ++ secondTags ++ firstWrapper ++ firstTags ++
            tailTags ++ restTags := by
        simp [taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
          taggedLinearTagsValue, secondWrapper, secondTags, firstWrapper, firstTags,
          tailTags, restTags, List.append_assoc]
      have hafterShape : taggedLinearTags
          { stack := .quotation nextTag (AProgram.append first second) outputUsage :: tail,
            program := rest, nextTag := nextTag + 1 } =
          (if outputUsage == .linear then [nextTag] else []) ++
            firstTags ++ secondTags ++ tailTags ++ restTags := by
        simp [taggedLinearTags, taggedLinearTagsProgram_append, taggedLinearTagsValue,
          outputUsage, firstTags, secondTags, tailTags, restTags, List.append_assoc]
      change ∀ tag, tag ∈ taggedLinearTags
        { stack := .quotation tag₂ second usage₂ :: .quotation tag₁ first usage₁ :: tail,
          program := .cons .compose rest, nextTag := nextTag } →
        tag < nextTag at hfrontier
      rw [hbeforeShape] at hnodup hfrontier
      have hsourceNodup : (secondWrapper ++ secondTags ++ firstWrapper ++ firstTags ++
          tailTags ++ restTags).Nodup := hnodup
      have hsourceFrontier : ∀ tag,
          tag ∈ secondWrapper ++ secondTags ++ firstWrapper ++ firstTags ++
            tailTags ++ restTags → tag < nextTag := hfrontier
      have hsub :
          (secondTags ++ firstTags ++ tailTags ++ restTags).Sublist
            (secondWrapper ++ secondTags ++ firstWrapper ++ firstTags ++
              tailTags ++ restTags) := by
        have hsecond : secondTags.Sublist (secondWrapper ++ secondTags) :=
          List.sublist_append_right secondWrapper secondTags
        have hfirst : firstTags.Sublist (firstWrapper ++ firstTags) :=
          List.sublist_append_right firstWrapper firstTags
        have hbodies := hsecond.append hfirst
        have htailRest := List.Sublist.refl (tailTags ++ restTags)
        simpa only [List.append_assoc] using hbodies.append htailRest
      have hbaseBeforeNodup :
          (secondTags ++ firstTags ++ tailTags ++ restTags).Nodup :=
        List.Nodup.sublist hsub hsourceNodup
      have hbaseAfterNodup :
          (firstTags ++ secondTags ++ tailTags ++ restTags).Nodup :=
        by
          simpa only [List.append_assoc] using
            (nodup_reorder_three secondTags firstTags (tailTags ++ restTags)
              (by simpa only [List.append_assoc] using hbaseBeforeNodup))
      have hbasePerm :
          (firstTags ++ secondTags ++ tailTags ++ restTags).Perm
            (secondTags ++ firstTags ++ tailTags ++ restTags) := by
        simpa only [List.append_assoc] using
          (List.Perm.append_right (tailTags ++ restTags)
            (List.perm_append_comm (l₁ := firstTags) (l₂ := secondTags)))
      have hbaseMemBefore : ∀ tag,
          tag ∈ firstTags ++ secondTags ++ tailTags ++ restTags →
            tag ∈ secondWrapper ++ secondTags ++ firstWrapper ++ firstTags ++
              tailTags ++ restTags := by
        intro tag htag
        exact List.Sublist.mem (hbasePerm.mem_iff.mp htag) hsub
      by_cases hout : outputUsage == .linear
      · have hfresh : nextTag ∉ firstTags ++ secondTags ++ tailTags ++ restTags := by
          intro htag
          exact Nat.lt_irrefl _ (hsourceFrontier nextTag (hbaseMemBefore nextTag htag))
        apply step_ownership_from_events
        · rw [afterTags, hafterShape]
          simp only [hout, if_true, List.singleton_append]
          exact List.nodup_cons.mpr ⟨hfresh, hbaseAfterNodup⟩
        · intro tag htag
          have hevent := mem_produced_iff.mp htag
          rw [afterTags, hafterShape, beforeTags, hbeforeShape] at hevent
          simp only [hout, if_true, List.mem_cons] at hevent
          have hafterMem : tag = nextTag ∨
              tag ∈ firstTags ++ secondTags ++ tailTags ++ restTags := by
            simpa [List.mem_cons, List.mem_append, or_assoc] using hevent.1
          rcases hafterMem with hnew | hbase
          · exact ⟨Nat.le_of_eq hnew.symm, hnew ▸ Nat.lt_succ_self nextTag⟩
          · exact (hevent.2 (hbaseMemBefore tag hbase)).elim
        · exact Nat.le_add_right _ _
      · apply step_ownership_from_events
        · rw [afterTags, hafterShape]
          simpa only [hout, if_false, List.nil_append] using hbaseAfterNodup
        · intro tag htag
          have hevent := mem_produced_iff.mp htag
          rw [afterTags, hafterShape, beforeTags, hbeforeShape] at hevent
          simp only [hout, if_false, List.nil_append] at hevent
          exact (hevent.2 (hbaseMemBefore tag hevent.1)).elim
        · exact Nat.le_add_right _ _
  | quote =>
      rename_i value tail rest nextTag
      rcases hbefore with ⟨hnodup, hfrontier⟩
      let valueTags := taggedLinearTagsValue value
      let tailTags :=
        List.foldr (fun item tags => taggedLinearTagsValue item ++ tags) [] tail
      let restTags := taggedLinearTagsProgram rest
      have hbeforeShape : taggedLinearTags
          { stack := value :: tail, program := .cons .quote rest, nextTag := nextTag } =
          valueTags ++ (tailTags ++ restTags) := by
        simp only [taggedLinearTags, List.foldr, taggedLinearTagsProgram,
          taggedLinearTagsAtom, List.nil_append, valueTags, tailTags, restTags,
          List.append_assoc]
      change ∀ tag, tag ∈ taggedLinearTags
        { stack := value :: tail, program := .cons .quote rest, nextTag := nextTag } →
        tag < nextTag at hfrontier
      rw [hbeforeShape] at hnodup hfrontier
      by_cases hlinear : quotationUsage (eraseValue value) == Usage.linear
      · have hafterShape : taggedLinearTags
            { stack := .quotation nextTag (.cons (.push value) .empty)
                (quotationUsage (eraseValue value)) :: tail,
              program := rest, nextTag := nextTag + 1 } =
            nextTag :: (valueTags ++ (tailTags ++ restTags)) := by
          simp only [taggedLinearTags, List.foldr, taggedLinearTagsValue, hlinear,
            if_true, taggedLinearTagsProgram, taggedLinearTagsAtom, List.append_nil,
            List.nil_append, List.singleton_append, valueTags, tailTags, restTags,
            List.append_assoc]
          rw [List.cons_append]
        have hfresh : nextTag ∉ valueTags ++ (tailTags ++ restTags) := by
          intro htag
          exact Nat.lt_irrefl _ (hfrontier nextTag htag)
        apply step_ownership_from_events
        · rw [afterTags, hafterShape]
          exact List.nodup_cons.mpr ⟨hfresh, hnodup⟩
        · intro tag htag
          have hevent := mem_produced_iff.mp htag
          rw [afterTags, hafterShape, beforeTags, hbeforeShape] at hevent
          rcases List.mem_cons.mp hevent.1 with hnew | hold
          · exact ⟨Nat.le_of_eq hnew.symm, hnew ▸ Nat.lt_succ_self nextTag⟩
          · exact (hevent.2 hold).elim
        · exact Nat.le_add_right _ _
      · apply step_ownership_of_tag_permutation
          (before :=
            { stack := value :: tail, program := .cons .quote rest, nextTag := nextTag })
          (after :=
            { stack := .quotation nextTag (.cons (.push value) .empty)
                (quotationUsage (eraseValue value)) :: tail,
              program := rest, nextTag := nextTag + 1 })
          (by rw [hbeforeShape]; exact hnodup)
        · simpa only [beforeTags, afterTags, taggedLinearTags, List.foldr,
            taggedLinearTagsValue, hlinear, if_false, taggedLinearTagsProgram,
            taggedLinearTagsAtom, List.append_nil, List.nil_append, valueTags,
            tailTags, restTags, List.append_assoc]
            using (List.Perm.refl (valueTags ++ (tailTags ++ restTags)))
        · exact Nat.le_add_right _ _
  | ifThenElse =>
      rename_i condition
      cases condition <;>
        (rcases hbefore with ⟨hnodup, hfrontier⟩
         simp only [StepOwnership, beforeTags, afterTags, preserved, consumed, produced,
           taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
           taggedLinearTagsValue, taggedLinearTagsProgram_append, List.foldr,
         List.mem_append, List.append_assoc] at hnodup hfrontier ⊢
         simp [mem_filter_bool_iff] at *
         grind)
  | word h =>
      rename_i name body stack rest nextTag nextTag'
      rcases h with ⟨entry, hname, hannotation⟩
      rcases hannotation with ⟨herase, hadvance, hfront, hnd⟩
      rcases hbefore with ⟨hnodup, hfrontier⟩
      let stackTags :=
        List.foldr (fun value tags => taggedLinearTagsValue value ++ tags) [] stack
      let bodyTags := taggedLinearTagsProgram body
      let restTags := taggedLinearTagsProgram rest
      have hbeforeShape : taggedLinearTags
          { stack := stack, program := .cons (.word name) rest, nextTag := nextTag } =
          stackTags ++ restTags := by
        simp only [taggedLinearTags, taggedLinearTagsProgram, List.foldr,
          taggedLinearTagsAtom, stackTags, restTags, List.append_assoc,
          List.nil_append]
      have hafterShape : taggedLinearTags
          { stack := stack, program := AProgram.append body rest, nextTag := nextTag' } =
          stackTags ++ (bodyTags ++ restTags) := by
        simp only [taggedLinearTags, taggedLinearTagsProgram_append, AProgram.append,
          taggedLinearTagsAtom, taggedLinearTagsProgram, List.foldr, stackTags,
          bodyTags, restTags, List.append_assoc]
      rw [hbeforeShape] at hnodup
      change ∀ tag, tag ∈ stackTags ++ restTags → tag < nextTag at hfrontier
      have hbaseNodup : (stackTags ++ restTags).Nodup := hnodup
      have hbodyBaseDisjoint : ∀ tag, tag ∈ bodyTags → tag ∉ stackTags ++ restTags := by
        intro tag hbody hbase
        rcases hfront tag hbody with ⟨hlo, _⟩
        exact Nat.not_lt_of_ge hlo (hfrontier tag hbase)
      have hafterNodup : (stackTags ++ (bodyTags ++ restTags)).Nodup := by
        have hbaseParts := (List.nodup_append.mp hbaseNodup)
        have hbodyRest : (bodyTags ++ restTags).Nodup := by
          apply (List.nodup_append).mpr
          refine ⟨hnd, hbaseParts.2.1, ?_⟩
          intro tag hbody other hrest heq
          exact hbodyBaseDisjoint tag (by simpa [heq] using hbody) (by
            simp only [List.mem_append]
            exact Or.inr hrest)
        apply (List.nodup_append).mpr
        refine ⟨hbaseParts.1, hbodyRest, ?_⟩
        intro tag hstack other hbodyRest heq
        rcases List.mem_append.mp hbodyRest with hbody | hrest
        · exact hbodyBaseDisjoint tag (by simpa [heq] using hbody) (by
            simp only [List.mem_append]
            exact Or.inl hstack)
        · exact hbaseParts.2.2 tag hstack other hrest heq
      apply step_ownership_from_events
      · rw [afterTags, hafterShape]
        exact hafterNodup
      · intro tag htag
        have hevent := mem_produced_iff.mp htag
        rw [afterTags, hafterShape, beforeTags, hbeforeShape] at hevent
        rcases List.mem_append.mp hevent.1 with hstack | hbodyrest
        · exact (hevent.2 (by simp only [List.mem_append]; exact Or.inl hstack)).elim
        · rcases List.mem_append.mp hbodyrest with hbody | hrest
          · exact hfront tag hbody
          · exact (hevent.2 (by simp only [List.mem_append]; exact Or.inr hrest)).elim
      · exact hadvance
  | prim h =>
      rcases h with ⟨specification, plainInput, plainOutput, rowTail, hname,
        hin, hdelta, hout, retained, consumed', produced', hinput, houtput,
        hretainedNd, hconsumedNd, hproducedNd, hretainedExact, hconsumedExact,
        hproducedExact, hretainedUnchanged, hconsumedAbsent, hproducedFresh,
        houtputResidueNd, hmonotone, hrowTail, hauthorised⟩
      rcases hbefore with ⟨hnodup, hfrontier⟩
      simp only [taggedLinearTagsValueList_eq_foldr] at hinput houtput hretainedExact hconsumedExact hproducedExact hretainedUnchanged hconsumedAbsent hproducedFresh houtputResidueNd hrowTail
      simp only [StepOwnership, beforeTags, afterTags, preserved, consumed, produced,
        taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
        taggedLinearTagsValue, taggedLinearTagsProgram_append, List.foldr,
        List.mem_append, List.append_assoc] at hnodup hfrontier ⊢
      grind

theorem instrumented_well_formed_preserved_of_step_ownership
    (hbefore : InstrumentedWellFormedAt before)
    (hstep : InstrumentedStep gamma dictionary costs before after) :
    InstrumentedWellFormedAt after := by
  have hownership := step_ownership_of_step hbefore hstep
  exact ⟨hownership.1, instrumented_frontier_preserved before after hbefore.2 hstep⟩

theorem consumed_is_not_later
    {before after : AConfig} {hstep : InstrumentedStep gamma dictionary costs before after}
    (hownership : StepOwnership before after hstep) :
    ∀ tag, tag ∈ consumed before after → tag ∉ afterTags before after := hownership.2.1

def Trace (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) :
    Config → List Config → Prop
  | _, [] => True
  | start, next :: rest =>
      HasSuccessor gamma dictionary costs start next ∧
      Trace gamma dictionary costs next rest

theorem instrumented_trace_erases
    {start : AConfig} {configs : List AConfig}
    (htrace : InstrumentedTrace gamma dictionary costs start configs) :
    Trace gamma dictionary costs (eraseAConfig start) (configs.map eraseAConfig) := by
  induction configs generalizing start with
  | nil => trivial
  | cons next rest ih =>
      constructor
      · exact instrumented_step_erases htrace.1
      · exact ih htrace.2

def TraceOwnership (configs : List AConfig) : Prop :=
  (configs.Pairwise (fun before after =>
    (taggedLinearTags before).Nodup ∧ (taggedLinearTags after).Nodup)) ∧
  (traceConsumed configs).Nodup ∧
  (∀ tag, tag ∈ traceConsumed configs →
    ∀ later, later ∈ configs → tag ∉ taggedLinearTags later)

theorem finite_trace_at_most_once_of_trace_ownership
    {configs : List AConfig} (htrace : InstrumentedTrace gamma dictionary costs start configs)
    (hownership : TraceOwnership (start :: configs)) :
    (traceConsumed (start :: configs)).Nodup := hownership.2.1

def InitialOwnershipCovered (start : AConfig) (configs : List AConfig) : Prop :=
  ∀ tag, tag ∈ taggedLinearTags start → tag ∈ traceConsumed (start :: configs)

theorem exact_once_of_terminating_empty_residue
    {start terminal : AConfig} {configs : List AConfig}
    (htrace : InstrumentedTrace gamma dictionary costs start configs)
    (hlast : configs.getLast? = some terminal)
    (hterm : terminal.program = .empty)
    (hempty : taggedLinearTags terminal = [])
    (hatmost : (traceConsumed (start :: configs)).Nodup)
    (hcovered : InitialOwnershipCovered start configs)
    (hnofabrication : ∀ tag, tag ∈ traceConsumed (start :: configs) →
      tag ∈ taggedLinearTags start) :
    configs.getLast? = some terminal ∧ terminal.program = .empty ∧
      taggedLinearTags terminal = [] ∧
      (traceConsumed (start :: configs)).Nodup ∧
      (∀ tag, tag ∈ taggedLinearTags start ↔
        tag ∈ traceConsumed (start :: configs)) := by
  refine ⟨hlast, hterm, hempty, hatmost, ?_⟩
  intro tag
  constructor
  · exact hcovered tag
  · intro h
    exact hnofabrication tag h

def InfiniteInstrumentedExecution (gamma : Gamma) (dictionary : Dictionary)
    (costs : CostTable) (run : Nat → AConfig) : Prop :=
  (∀ n, InstrumentedStep gamma dictionary costs (run n) (run (n + 1))) ∧
  (∃ tag, ∀ n, tag ∈ taggedLinearTags (run n))

theorem divergence_may_leave_linear_live :
  ∃ (dictionary : Dictionary) (run : Nat → AConfig),
      InfiniteInstrumentedExecution defaultGamma dictionary defaultCosts run := by
  let dictionary : Dictionary := fun _ => some
    { type := { rowVariables := ["ρ"], input := .row "ρ", output := .row "ρ" },
      body := .cons (.word "loop") .empty }
  let live : AConfig :=
    { stack := [.world 0 7], program := .cons (.word "loop") .empty, nextTag := 1 }
  let run : Nat → AConfig := fun _ => live
  refine ⟨dictionary, run, ?_⟩
  constructor
  · intro n
    change InstrumentedStep defaultGamma dictionary defaultCosts live live
    refine InstrumentedStep.word (name := "loop")
      (body := .cons (.word "loop") .empty) (stack := [.world 0 7])
      (rest := .empty) (nextTag := 1) (nextTag' := 1) ?_
    let entry : WordEntry :=
      { type := { rowVariables := ["ρ"], input := StackType.row "ρ", output := StackType.row "ρ" },
        body := Program.cons (.word "loop") Program.empty }
    refine ⟨entry, ?_, ?_⟩
    · simp [dictionary, entry]
    · refine ⟨rfl, Nat.le_refl _, ?_, ?_⟩
      · intro tag htag
        cases htag
      · simp [taggedLinearTagsProgram, taggedLinearTagsAtom]
  · refine ⟨0, ?_⟩
    intro n
    simp [run, live, taggedLinearTags, taggedLinearTagsValue,
      taggedLinearTagsProgram, taggedLinearTagsAtom]

/-! Frontier-indexed annotation relations.

The lower bound is the input frontier, not a requirement that pre-existing
tags be freshly minted.  An annotation may therefore retain ownership tags
below `n`, while every identity tag introduced by the annotation lies in the
half-open interval `[n, n')`.
-/

mutual
  def annotationIdentityTagsValue : AValue → Ownerships
    | .literal tag _ => [tag]
    | .world tag _ => [tag]
    | .quotation tag body _ => tag :: annotationIdentityTagsProgram body

  def annotationIdentityTagsAtom : AAtom → Ownerships
    | .push value => annotationIdentityTagsValue value
    | .quotation body => annotationIdentityTagsProgram body
    | _ => []

  def annotationIdentityTagsProgram : AProgram → Ownerships
    | .empty => []
    | .cons head tail => annotationIdentityTagsAtom head ++ annotationIdentityTagsProgram tail
end

def AnnotationValue (input : Tag) (plain : Value) (annotated : AValue) (output : Tag) : Prop :=
  eraseValue annotated = plain ∧
    input ≤ output ∧
    (∀ tag, tag ∈ annotationIdentityTagsValue annotated →
      tag < input ∨ (input ≤ tag ∧ tag < output)) ∧
    (∀ tag, tag ∈ taggedLinearTagsValue annotated → tag < output)

def AnnotationProgram (input : Tag) (plain : Program) (annotated : AProgram)
    (output : Tag) : Prop :=
    eraseProgram annotated = plain ∧
    input ≤ output ∧
    (∀ tag, tag ∈ annotationIdentityTagsProgram annotated →
      tag < input ∨ (input ≤ tag ∧ tag < output)) ∧
    (∀ tag, tag ∈ taggedLinearTagsProgram annotated → tag < output)

def annotationIdentityTagsValueList : AStack → Ownerships
  | [] => []
  | value :: tail => annotationIdentityTagsValue value ++ annotationIdentityTagsValueList tail

def AnnotationConfig (input : Tag) (plain : Config) (annotated : AConfig) (output : Tag) : Prop :=
    eraseAConfig annotated = plain ∧
    input ≤ output ∧
    (∀ tag, tag ∈ annotationIdentityTagsValueList annotated.stack →
      tag < input ∨ (input ≤ tag ∧ tag < output)) ∧
    (∀ tag, tag ∈ annotationIdentityTagsProgram annotated.program →
      tag < input ∨ (input ≤ tag ∧ tag < output)) ∧
    (∀ tag, tag ∈ taggedLinearTags annotated → tag < output)

theorem annotation_value_erases {input output : Tag} {plain : Value} {annotated : AValue}
    (h : AnnotationValue input plain annotated output) : eraseValue annotated = plain := h.1

theorem annotation_value_advances {input output : Tag} {plain : Value} {annotated : AValue}
    (h : AnnotationValue input plain annotated output) : input ≤ output := h.2.1

theorem annotation_program_erases {input output : Tag} {plain : Program} {annotated : AProgram}
    (h : AnnotationProgram input plain annotated output) : eraseProgram annotated = plain := h.1

theorem annotation_program_advances {input output : Tag} {plain : Program} {annotated : AProgram}
    (h : AnnotationProgram input plain annotated output) : input ≤ output := h.2.1

theorem annotation_config_erases {input output : Tag} {plain : Config} {annotated : AConfig}
    (h : AnnotationConfig input plain annotated output) : eraseAConfig annotated = plain := h.1

theorem annotation_config_advances {input output : Tag} {plain : Config} {annotated : AConfig}
    (h : AnnotationConfig input plain annotated output) : input ≤ output := h.2.1

def AnnotatedDictionary (dictionary : Dictionary) (annotated : String → Option AProgram)
    (frontier : Tag) : Prop :=
  ∀ name entry, dictionary name = some entry →
    ∃ body, annotated name = some body ∧ eraseProgram body = entry.body ∧
      (∀ tag, tag ∈ taggedLinearTagsProgram body → tag < frontier)

def PrimitiveTagLift (gamma : Gamma) (name : Prim) : Prop :=
  ∀ input residue nextTag specification plainInput plainOutput,
    gamma.primitive name = some specification →
    input.map eraseValue = plainInput →
    specification.delta plainInput = some plainOutput →
    ∃ output nextTag',
      output.map eraseValue = plainOutput ∧ nextTag ≤ nextTag' ∧
      (∃ specification plainInput plainOutput rowTail retained consumed produced,
        PrimitiveTagContract primitiveAuthorisation gamma name input output residue
          specification plainInput plainOutput rowTail retained consumed produced
          nextTag nextTag') ∧
      (∀ tag, tag ∈ taggedLinearTagsValueList output → tag < nextTag')

def PlainStepLiftContract (gamma : Gamma) (dictionary : Dictionary)
    (costs : CostTable) : Prop :=
  ∀ before after,
    TypedConfig gamma dictionary before →
    HasSuccessor gamma dictionary costs before after →
    ∃ annotatedBefore annotatedAfter,
      eraseAConfig annotatedBefore = before ∧ eraseAConfig annotatedAfter = after ∧
      InstrumentedWellFormedAt annotatedBefore ∧
      InstrumentedStep gamma dictionary costs annotatedBefore annotatedAfter

theorem backward_adequacy_of_lift_contract
    (hlift : PlainStepLiftContract gamma dictionary costs)
    {before after : Config}
    (htyped : TypedConfig gamma dictionary before)
    (hstep : HasSuccessor gamma dictionary costs before after) :
    ∃ annotatedBefore annotatedAfter,
      eraseAConfig annotatedBefore = before ∧ eraseAConfig annotatedAfter = after ∧
      InstrumentedWellFormedAt annotatedBefore ∧
      InstrumentedStep gamma dictionary costs annotatedBefore annotatedAfter := by
  exact hlift before after htyped hstep

theorem primitive_tag_lift_is_contract
    (h : PrimitiveTagLift gamma name) :
    ∀ input residue nextTag specification plainInput plainOutput,
      gamma.primitive name = some specification →
      input.map eraseValue = plainInput →
      specification.delta plainInput = some plainOutput →
      ∃ output nextTag', ∃ specification plainInput plainOutput rowTail retained consumed produced,
        PrimitiveTagContract primitiveAuthorisation gamma name input output residue
          specification plainInput plainOutput rowTail retained consumed produced
          nextTag nextTag' := by
  intro input residue nextTag specification plainInput plainOutput hname hin hdelta
  rcases h input residue nextTag specification plainInput plainOutput hname hin hdelta with
    ⟨output, nextTag', _, _, hcontract, _⟩
  exact ⟨output, nextTag', hcontract⟩

end Firth.Interpreter
