import Firth.Interpreter
import Firth.KernelMetatheory
import Firth.Linearity

open Firth.Interpreter

def testPolicy : PrimitiveOwnershipPolicy where
  authorised := fun name consumed produced =>
    (name == "addNat" ∧ consumed = [] ∧ produced = []) ∨
    (name == "makeWorld" ∧ consumed = [] ∧ produced.length = 1) ∨
    (name == "consumeWorld" ∧ consumed.length = 1 ∧ produced = [])

abbrev examplePolicy := testPolicy
abbrev exampleGamma := defaultGamma

#print axioms eraseProgram_append
#print axioms usageMeet_decide
#print axioms eraseProgram_if
#print axioms taggedLinearTagsProgram_append
#print axioms ownershipAbsent_of_false
#print axioms ownershipAbsent_of_true
#print axioms taggedLinearTagsValueList_eq_flatMap
#print axioms taggedLinearTagsValueList_eq_foldr
#print axioms taggedLinearTagsValue_mem_foldr
#print axioms taggedLinearTagsValue_mem_foldr_iff
#print axioms mem_filter_bool_iff
#print axioms ownershipContains_eq_true_iff_mem
#print axioms mem_produced_iff
#print axioms nodup_filter_bool
#print axioms filter_complement_disjoint
#print axioms filter_partition_membership
#print axioms filter_absent_eq_nil_of_subset
#print axioms filter_not_contains_self
#print axioms mem_filter_not_contains_self
#print axioms frontier_succ
#print axioms instrumented_frontier_preserved
#print axioms instrumented_step_erases_lit
#print axioms instrumented_step_erases_push
#print axioms instrumented_step_erases_quotation
#print axioms instrumented_step_erases_dup
#print axioms instrumented_step_erases_drop
#print axioms instrumented_step_erases_swap
#print axioms instrumented_step_erases_call
#print axioms instrumented_step_erases_dip
#print axioms instrumented_step_erases_compose
#print axioms instrumented_step_erases_quote
#print axioms instrumented_step_erases_ifThenElse
#print axioms instrumented_step_erases_word
#print axioms instrumented_step_erases_prim
#print axioms instrumented_step_erases
#print axioms step_ownership_from_events
#print axioms perm_mem_constructive
#print axioms perm_nodup_constructive
#print axioms nodup_append_constructive
#print axioms nodup_reorder_three
#print axioms step_ownership_of_tag_permutation
#print axioms step_ownership_of_step
#print axioms instrumented_well_formed_preserved_of_step_ownership
#print axioms consumed_is_not_later
#print axioms instrumented_trace_erases
#print axioms consumed_mem_before
#print axioms mem_consumed_of_contains_false
#print axioms after_mem_before_or_produced
#print axioms consumed_lt_frontier
#print axioms tag_absent_through_trace
#print axioms tag_never_consumed_through_trace
#print axioms finite_trace_at_most_once
#print axioms initial_tag_survives_or_consumed_at
#print axioms exact_once_of_terminating_empty_residue
#print axioms exact_once_of_terminating_empty_residue_all_born
#print axioms trace_produced_ge_frontier
#print axioms born_tags_nodup
#print axioms born_tag_survives_or_consumed
#print axioms divergence_may_leave_linear_live
#print axioms annotation_value_erases
#print axioms annotation_value_advances
#print axioms annotation_program_erases
#print axioms annotation_program_advances
#print axioms annotation_config_erases
#print axioms annotation_config_advances
#print axioms primitive_tag_lift_is_contract
#print axioms many_annotated_value_has_no_linear_tags
#print axioms many_annotated_atom_has_no_linear_tags
#print axioms many_annotated_program_has_no_linear_tags
#print axioms backward_adequacy
#print axioms trace_backward_adequacy
#print axioms annotated_dictionary_self_recursive_witness

example (tag : Tag) (value : Literal) :
    taggedLinearTagsValue (.literal tag value) = [] := by
  rfl

example (tag : Tag) (payload : Nat) :
    taggedLinearTagsValue (.world tag payload) = [tag] := by
  rfl

example (tag : Tag) :
    taggedLinearTagsValue (.quotation tag .empty .many) = [] := by
  rfl

example (tag : Tag) :
    taggedLinearTagsValue (.quotation tag .empty .linear) = [tag] := by
  rfl

example (tag : Tag) :
    ∃ step : InstrumentedStep testPolicy defaultGamma emptyDictionary defaultCosts
        { stack := [.literal tag (.nat 7)], program := .cons .dup .empty, nextTag := tag + 1 }
        { stack := [.literal tag (.nat 7), .literal tag (.nat 7)], program := .empty,
          nextTag := tag + 1 }, True := by
  exact ⟨.dup rfl, trivial⟩

example (tag : Tag) :
    ¬ taggedLinearTagsValue (.world tag 0) = [] := by
  intro h
  cases h

example (tag : Tag) :
    ¬ taggedLinearTagsValue (.quotation tag .empty .linear) = [] := by
  intro h
  cases h

example : InstrumentedStep testPolicy defaultGamma emptyDictionary defaultCosts
    { stack := [.quotation 10 .empty .many, .quotation 11 .empty .many,
        .literal 12 (.bool true)],
      program := .cons .ifThenElse .empty, nextTag := 13 }
    { stack := [], program := .empty, nextTag := 13 } := by
  exact .ifThenElse rfl rfl

example : ∃ (dictionary : Dictionary) (annotated : String → Option AProgram),
    AnnotatedDictionary dictionary annotated :=
  annotated_dictionary_self_recursive_witness

example : PrimitiveStackContract "makeWorld" [] [.world 5 0] :=
  .makeWorld

example : PrimitiveStackContract "consumeWorld" [.world 5 0] [] :=
  .consumeWorld

example : testPolicy.authorised "makeWorld" [] [5] :=
  by simp [testPolicy]

example : testPolicy.authorised "consumeWorld" [5] [] :=
  by simp [testPolicy]

example : ∃ step : InstrumentedStep testPolicy defaultGamma emptyDictionary defaultCosts
    { stack := [], program := .cons (.prim "makeWorld") .empty, nextTag := 0 }
    { stack := [.world 5 0], program := .empty, nextTag := 6 }, True := by
  let specification : PrimitiveSpec :=
    { input := .row "ρ", output := .snoc (.row "ρ") (.base .world .linear),
      delta := makeWorldDelta }
  let contract : PrimitiveTagContract testPolicy defaultGamma "makeWorld" [] [.world 5 0] .empty
      specification [] [.world 0] [] [] [] [5] 0 6 :=
    { name_resolves := by simp [specification, defaultGamma]
      input_erases := by simp [eraseValue]
      delta := rfl
      output_erases := rfl
      input_partition := by simp [taggedLinearTagsValueList]
      output_partition := by intro tag; simp [taggedLinearTagsValueList, taggedLinearTagsValue]
      retained_nodup := by simp
      consumed_nodup := by simp
      produced_nodup := by simp
      retained_exact := by simp [taggedLinearTagsValueList]
      consumed_exact := by simp [taggedLinearTagsValueList]
      produced_exact := by intro tag; simp [taggedLinearTagsValueList, taggedLinearTagsValue]
      retained_unchanged := by simp [taggedLinearTagsValueList]
      consumed_absent := by simp [taggedLinearTagsValueList, taggedLinearTagsProgram]
      produced_fresh := by intro tag htag; simp at htag; subst tag; exact ⟨by decide, by decide⟩
      output_residue_nodup := by simp [taggedLinearTagsValueList, taggedLinearTagsValue,
        taggedLinearTagsProgram]
      frontier_monotone := by decide
      row_tail_retained := by simp
      stack_contract := .makeWorld
      authorised := by simp [testPolicy] }
  exact ⟨.prim (specification := specification) (plainInput := [])
    (plainOutput := [.world 0]) (rowTail := []) (retained := [])
    (consumed := []) (produced := [5])
    ⟨specification, [], [.world 0], [], [], [], [5], contract⟩, trivial⟩

example : ∃ step : InstrumentedStep testPolicy defaultGamma emptyDictionary defaultCosts
    { stack := [.world 0 7], program := .cons (.prim "consumeWorld") .empty, nextTag := 1 }
    { stack := [], program := .empty, nextTag := 1 }, True := by
  let specification : PrimitiveSpec :=
    { input := .snoc (.row "ρ") (.base .world .linear), output := .row "ρ",
      delta := consumeWorldDelta }
  let contract : PrimitiveTagContract testPolicy defaultGamma "consumeWorld" [.world 0 7] [] .empty
      specification [.world 7] [] [] [] [0] [] 1 1 :=
    { name_resolves := by simp [specification, defaultGamma]
      input_erases := by simp [eraseValue]
      delta := rfl
      output_erases := rfl
      input_partition := by intro tag; simp [taggedLinearTagsValueList, taggedLinearTagsValue]
      output_partition := by simp [taggedLinearTagsValueList]
      retained_nodup := by simp
      consumed_nodup := by simp
      produced_nodup := by simp
      retained_exact := by simp [taggedLinearTagsValueList]
      consumed_exact := by intro tag; simp [taggedLinearTagsValueList, taggedLinearTagsValue]
      produced_exact := by simp [taggedLinearTagsValueList]
      retained_unchanged := by simp [taggedLinearTagsValueList, taggedLinearTagsValue,
        ownershipContains]
      consumed_absent := by intro tag htag; simp [taggedLinearTagsValueList,
        taggedLinearTagsValue, taggedLinearTagsProgram, ownershipContains] at htag ⊢
      produced_fresh := by simp
      output_residue_nodup := by simp [taggedLinearTagsValueList, taggedLinearTagsProgram]
      frontier_monotone := by decide
      row_tail_retained := by simp
      stack_contract := .consumeWorld
      authorised := by simp [testPolicy] }
  exact ⟨.prim (specification := specification) (plainInput := [.world 7])
    (plainOutput := []) (rowTail := []) (retained := []) (consumed := [0])
    (produced := []) ⟨specification, [.world 7], [], [], [], [0], [], contract⟩, trivial⟩

def consumedWorldBefore : AConfig :=
  { stack := [.world 0 7], program := .cons (.prim "consumeWorld") .empty,
    nextTag := 1 }

def consumedWorldAfter : AConfig :=
  { stack := [], program := .empty, nextTag := 1 }

example : consumed consumedWorldBefore consumedWorldAfter = [0] := by
  rfl

example : (traceConsumed [consumedWorldBefore, consumedWorldAfter]).Nodup := by
  decide

example (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (before after : AConfig) (hbefore : FrontierInvariant before)
    (hstep : InstrumentedStep policy gamma dictionary costs before after) :
    FrontierInvariant after := by
  exact instrumented_frontier_preserved before after hbefore hstep

example (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (before after : AConfig)
    (hstep : InstrumentedStep policy gamma dictionary costs before after) :
    HasSuccessor gamma dictionary costs (eraseAConfig before) (eraseAConfig after) := by
  exact instrumented_step_erases hstep

example (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (config next₁ next₂ : Config) :
    HasSuccessor gamma dictionary costs config next₁ →
      HasSuccessor gamma dictionary costs config next₂ → next₁ = next₂ := by
  exact step_deterministic gamma dictionary costs config next₁ next₂

example (costs : CostTable) (left right : List Atom) :
    sequenceCost costs.atom (left ++ right) =
      sequenceCost costs.atom left + sequenceCost costs.atom right := by
  exact atomSequenceCost_append costs left right

def quoteBefore : AConfig :=
  { stack := [.world 0 7], program := .cons .quote .empty, nextTag := 1 }

def quoteAfter : AConfig :=
  { stack := [.quotation 1 (.cons (.push (.world 0 7)) .empty) .linear],
    program := .empty, nextTag := 2 }

example : InstrumentedTrace testPolicy defaultGamma emptyDictionary defaultCosts
    quoteBefore [quoteAfter] ∧ taggedLinearTags quoteBefore = [0] ∧
      taggedLinearTags quoteAfter = [1, 0] := by
  refine ⟨⟨.quote, trivial⟩, rfl, rfl⟩

example : InstrumentedTrace testPolicy defaultGamma emptyDictionary defaultCosts
    { stack := [.quotation 1 (.cons (.push (.world 0 7)) .empty) .linear],
      program := .cons .call .empty, nextTag := 2 }
    [{ stack := [], program := .cons (.push (.world 0 7)) .empty, nextTag := 2 },
      { stack := [.world 0 7], program := .empty, nextTag := 2 }] ∧
      consumed
        { stack := [.quotation 1 (.cons (.push (.world 0 7)) .empty) .linear],
          program := .cons .call .empty, nextTag := 2 }
        { stack := [], program := .cons (.push (.world 0 7)) .empty, nextTag := 2 } = [1] := by
  refine ⟨⟨.call, ⟨.push, trivial⟩⟩, rfl⟩

example : InstrumentedTrace testPolicy defaultGamma emptyDictionary defaultCosts
    { stack := [.quotation 2 .empty .many, .world 0 7],
      program := .cons .dip .empty, nextTag := 3 }
    [{ stack := [], program := .cons (.push (.world 0 7)) .empty, nextTag := 3 },
      { stack := [.world 0 7], program := .empty, nextTag := 3 }] ∧
      taggedLinearTags
        { stack := [.quotation 2 .empty .many, .world 0 7],
          program := .cons .dip .empty, nextTag := 3 } = [0] ∧
      taggedLinearTags
        { stack := [], program := .cons (.push (.world 0 7)) .empty, nextTag := 3 } = [0] := by
  refine ⟨⟨.dip, ⟨.push, trivial⟩⟩, rfl, rfl⟩

example : InstrumentedTrace testPolicy defaultGamma emptyDictionary defaultCosts
    { stack := [.quotation 11 .empty .linear, .quotation 10 .empty .linear],
      program := .cons .compose .empty, nextTag := 12 }
    [{ stack := [.quotation 12 .empty .linear], program := .empty, nextTag := 13 }] ∧
      taggedLinearTags
        { stack := [.quotation 11 .empty .linear, .quotation 10 .empty .linear],
          program := .cons .compose .empty, nextTag := 12 } = [11, 10] ∧
      taggedLinearTags
        { stack := [.quotation 12 .empty .linear], program := .empty, nextTag := 13 } = [12] := by
  refine ⟨⟨.compose, trivial⟩, rfl, rfl⟩

example : ∃ (dictionary : Dictionary) (run : Nat → AConfig),
    InfiniteInstrumentedTrace testPolicy defaultGamma dictionary defaultCosts run := by
  let entry : WordEntry :=
    { type := { rowVariables := ["ρ"], input := .row "ρ", output := .row "ρ" },
      body := .cons (.word "loop") .empty }
  let dictionary : Dictionary := fun _ => some entry
  let live : AConfig :=
    { stack := [.world 0 7], program := .cons (.word "loop") .empty, nextTag := 1 }
  let run : Nat → AConfig := fun _ => live
  refine ⟨dictionary, run, ?_⟩
  constructor
  · intro n
    exact .word (name := "loop") (body := .cons (.word "loop") .empty)
      (stack := [.world 0 7]) (rest := .empty) (nextTag := 1) (nextTag' := 1) (by
        refine ⟨entry, ?_, ?_⟩
        · simp [dictionary, entry]
        · exact ⟨rfl, Nat.le_refl _, by simp [taggedLinearTagsProgram, taggedLinearTagsAtom]⟩)
  · refine ⟨0, ?_⟩
    intro n
    simp [run, live, taggedLinearTags, taggedLinearTagsValue,
      taggedLinearTagsProgram, taggedLinearTagsAtom]

def makeWorldLiftContractWitness : ∃ output nextTag',
    PrimitiveTagContract testPolicy defaultGamma "makeWorld" [] output .empty
      { input := .row "ρ", output := .snoc (.row "ρ") (.base .world .linear), delta := makeWorldDelta }
      [] [.world 0] [] [] [] [5] 0 nextTag' := by
  let specification : PrimitiveSpec :=
    { input := .row "ρ", output := .snoc (.row "ρ") (.base .world .linear),
      delta := makeWorldDelta }
  let contract : PrimitiveTagContract testPolicy defaultGamma "makeWorld" [] [.world 5 0] .empty
      specification [] [.world 0] [] [] [] [5] 0 6 :=
    { name_resolves := by simp [specification, defaultGamma]
      input_erases := rfl
      delta := rfl
      output_erases := rfl
      input_partition := by simp [taggedLinearTagsValueList]
      output_partition := by intro tag; simp [taggedLinearTagsValueList, taggedLinearTagsValue]
      retained_nodup := by simp
      consumed_nodup := by simp
      produced_nodup := by simp
      retained_exact := by simp [taggedLinearTagsValueList]
      consumed_exact := by simp [taggedLinearTagsValueList]
      produced_exact := by intro tag; simp [taggedLinearTagsValueList, taggedLinearTagsValue]
      retained_unchanged := by simp [taggedLinearTagsValueList]
      consumed_absent := by simp [taggedLinearTagsValueList, taggedLinearTagsProgram]
      produced_fresh := by intro tag htag; simp at htag; subst tag; exact ⟨by decide, by decide⟩
      output_residue_nodup := by simp [taggedLinearTagsValueList, taggedLinearTagsValue, taggedLinearTagsProgram]
      frontier_monotone := by decide
      row_tail_retained := by simp
      stack_contract := .makeWorld
      authorised := by simp [testPolicy] }
  exact ⟨[.world 5 0], 6, contract⟩

theorem filterContainsEqSelf_explicit : ∀ (source candidates : Ownerships),
      (∀ tag, tag ∈ candidates → tag ∈ source) →
      candidates.filter (fun tag => ownershipContains source tag) = candidates := by
    intro source candidates hsubset
    induction candidates with
    | nil => rfl
    | cons head tail ih =>
      have hhead : ownershipContains source head = true :=
        ownershipContains_eq_true_iff_mem.mpr (hsubset head List.mem_cons_self)
      simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.filter, hhead]
      exact congrArg (List.cons head) (ih (by
        intro tag htag
        exact hsubset tag (List.mem_cons_of_mem head htag)))

theorem examplePrimitiveTagLift_addNat :
    PrimitiveTagLift examplePolicy exampleGamma "addNat" := by
  intro input residue nextTag specification plainInput plainOutput
    hname hinput hdelta hwellformed
  have hspecification : specification =
      { input := .snoc (.snoc (.row "ρ") (.base .nat .many)) (.base .nat .many),
        output := .snoc (.row "ρ") (.base .nat .many), delta := addNatDelta } :=
    (Option.some.inj hname).symm
  subst specification
  subst plainInput
  cases input with
  | nil => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta; cases hdelta
  | cons rightValue inputTail =>
    cases rightValue with
    | quotation rightTag body usage => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta; cases hdelta
    | world rightTag payload => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta; cases hdelta
    | literal rightTag rightLiteral =>
      cases rightLiteral with
      | bool right => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta; cases hdelta
      | unit => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta; cases hdelta
      | nat right =>
        cases inputTail with
        | nil => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta; cases hdelta
        | cons leftValue tail =>
          cases leftValue with
          | quotation leftTag body usage => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta; cases hdelta
          | world leftTag payload => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta; cases hdelta
          | literal leftTag leftLiteral =>
            cases leftLiteral with
            | bool left => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta; cases hdelta
            | unit => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta; cases hdelta
            | nat left =>
              simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, addNatDelta] at hdelta
              have hplainOutput := Option.some.inj hdelta
              subst plainOutput
              let tailTags := taggedLinearTagsValueList tail
              have htags :
                  taggedLinearTags
                    { stack := .literal rightTag (.nat right) ::
                        .literal leftTag (.nat left) :: tail,
                      program := .cons (.prim "addNat") residue,
                      nextTag := nextTag } =
                    tailTags ++ taggedLinearTagsProgram residue := by
                simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, taggedLinearTags, taggedLinearTagsValueList,
                  taggedLinearTagsValue, taggedLinearTagsProgram,
                  taggedLinearTagsAtom, tailTags,
                  taggedLinearTagsValueList_eq_foldr]
              unfold InstrumentedWellFormed at hwellformed
              rw [htags] at hwellformed
              let output : AStack := .literal rightTag (.nat (left + right)) :: tail
              refine ⟨output, nextTag, ?_, Nat.le_refl _, ?_, ?_⟩
              · simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, eraseValue]
              · refine ⟨
                  { input := .snoc (.snoc (.row "ρ") (.base .nat .many))
                      (.base .nat .many),
                    output := .snoc (.row "ρ") (.base .nat .many),
                    delta := addNatDelta },
                  .literal (.nat right) :: .literal (.nat left) :: tail.map eraseValue,
                  .literal (.nat (left + right)) :: tail.map eraseValue,
                  tailTags, tailTags, [], [], ?_⟩
                refine
                  { name_resolves := hname
                    input_erases := by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, eraseValue]
                    delta := by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, addNatDelta, eraseValue]
                    output_erases := by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, eraseValue]
                    input_partition := ?_
                    output_partition := ?_
                    retained_nodup := ?_
                    consumed_nodup := List.nodup_nil
                    produced_nodup := List.nodup_nil
                    retained_exact := ?_
                    consumed_exact := ?_
                    produced_exact := ?_
                    retained_unchanged := ?_
                    consumed_absent := by
                      intro tag htag
                      cases htag
                    produced_fresh := by
                      intro tag htag
                      cases htag
                    output_residue_nodup := ?_
                    frontier_monotone := Nat.le_refl _
                    row_tail_retained := by
                      intro tag htag
                      exact htag
                    stack_contract := .addNat
                    authorised := by
                      change ("addNat" == "addNat" ∧ [] = [] ∧ [] = []) ∨ _
                      exact Or.inl ⟨rfl, rfl, rfl⟩ }
                · intro tag
                  simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, taggedLinearTagsValueList, taggedLinearTagsValue, tailTags]
                · intro tag
                  simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList, taggedLinearTagsValue,
                    tailTags]
                · exact (nodup_append_constructive.mp hwellformed.1).1
                · intro tag
                  constructor
                  · intro htag
                    exact ⟨htag, htag⟩
                  · rintro ⟨htag, _⟩
                    exact htag
                · intro tag
                  constructor
                  · intro htag
                    cases htag
                  · rintro ⟨htag, hnot⟩
                    exact (hnot htag).elim
                · intro tag
                  constructor
                  · intro htag
                    cases htag
                  · rintro ⟨htag, hnot⟩
                    exact (hnot htag).elim
                · exact (filterContainsEqSelf_explicit _ tailTags (by
                    intro tag htag
                    simpa only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList,
                      taggedLinearTagsValue, tailTags] using htag)).symm
                · simpa only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList, taggedLinearTagsValue,
                    tailTags] using hwellformed.1
              · intro tag htag
                apply hwellformed.2 tag
                simpa only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList, taggedLinearTagsValue,
                  tailTags] using List.mem_append_left
                    (taggedLinearTagsProgram residue) htag


theorem examplePrimitiveTagLift_makeWorld :
    PrimitiveTagLift examplePolicy exampleGamma "makeWorld" := by
  intro input residue nextTag specification plainInput plainOutput
    hname hinput hdelta hwellformed
  have hspecification : specification =
      { input := .row "ρ",
        output := .snoc (.row "ρ") (.base .world .linear),
        delta := makeWorldDelta } :=
    (Option.some.inj hname).symm
  subst specification
  subst plainInput
  simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, makeWorldDelta] at hdelta
  have hplainOutput := Option.some.inj hdelta
  subst plainOutput
  let inputTags := taggedLinearTagsValueList input
  have htags :
      taggedLinearTags
        { stack := input, program := .cons (.prim "makeWorld") residue,
          nextTag := nextTag } =
        inputTags ++ taggedLinearTagsProgram residue := by
    simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, taggedLinearTags, taggedLinearTagsProgram, taggedLinearTagsAtom,
      inputTags, taggedLinearTagsValueList_eq_foldr]
  unfold InstrumentedWellFormed at hwellformed
  rw [htags] at hwellformed
  have hnextAbsent :
      nextTag ∉ inputTags ++ taggedLinearTagsProgram residue := by
    intro hmem
    exact (Nat.lt_irrefl nextTag) (hwellformed.2 nextTag hmem)
  have hnextInputAbsent : nextTag ∉ inputTags := by
    intro hmem
    exact hnextAbsent (List.mem_append_left _ hmem)
  let output : AStack := .world nextTag 0 :: input
  refine ⟨output, nextTag + 1, ?_, Nat.le_succ _, ?_, ?_⟩
  · simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, eraseValue]
  · refine ⟨
      { input := .row "ρ",
        output := .snoc (.row "ρ") (.base .world .linear),
        delta := makeWorldDelta },
      input.map eraseValue, .world 0 :: input.map eraseValue,
      inputTags, inputTags, [], [nextTag], ?_⟩
    refine
      { name_resolves := hname
        input_erases := by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, eraseValue]
        delta := by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, makeWorldDelta]
        output_erases := by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, eraseValue]
        input_partition := ?_
        output_partition := ?_
        retained_nodup := ?_
        consumed_nodup := List.nodup_nil
        produced_nodup := List.nodup_cons.mpr
          ⟨fun hmem => List.not_mem_nil hmem, List.nodup_nil⟩
        retained_exact := ?_
        consumed_exact := ?_
        produced_exact := ?_
        retained_unchanged := ?_
        consumed_absent := by
          intro tag htag
          cases htag
        produced_fresh := ?_
        output_residue_nodup := ?_
        frontier_monotone := Nat.le_succ _
        row_tail_retained := by
          intro tag htag
          exact htag
        stack_contract := .makeWorld
        authorised := by
          change _ ∨ ("makeWorld" == "makeWorld" ∧ [] = [] ∧ [nextTag].length = 1) ∨ _
          exact Or.inr (Or.inl ⟨rfl, rfl, rfl⟩) }
    · intro tag
      simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, inputTags]
    · intro tag
      simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList, taggedLinearTagsValue,
        inputTags, or_comm]
    · exact (nodup_append_constructive.mp hwellformed.1).1
    · intro tag
      constructor
      · intro htag
        exact ⟨htag, by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList,
            taggedLinearTagsValue, inputTags, htag]⟩
      · intro htag
        exact htag.1
    · intro tag
      constructor
      · intro htag
        cases htag
      · rintro ⟨hin, hnot⟩
        exact (hnot (by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList,
          taggedLinearTagsValue, inputTags, hin])).elim
    · intro tag
      constructor
      · intro htag
        have htag' : tag = nextTag := List.mem_singleton.mp htag
        subst tag
        exact ⟨by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList,
          taggedLinearTagsValue, inputTags], hnextInputAbsent⟩
      · rintro ⟨hout, hnot⟩
        simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList, taggedLinearTagsValue,
          inputTags] at hout
        rcases hout with rfl | hin
        · exact List.mem_cons_self
        · exact (hnot hin).elim
    · exact (filterContainsEqSelf_explicit _ inputTags (by
        intro tag htag
        simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList, taggedLinearTagsValue,
          inputTags, htag])).symm
    · intro tag htag
      have htag' : tag = nextTag := List.mem_singleton.mp htag
      subst tag
      exact ⟨Nat.le_refl _, Nat.lt_succ_self _⟩
    · simpa only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList, taggedLinearTagsValue,
        inputTags] using List.nodup_cons.2 ⟨hnextAbsent, hwellformed.1⟩
  · intro tag htag
    simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList, taggedLinearTagsValue,
      inputTags] at htag
    rcases htag with rfl | htag
    · exact Nat.lt_succ_self _
    · exact Nat.lt_succ_of_lt
        (hwellformed.2 tag (List.mem_append_left _ htag))


theorem examplePrimitiveTagLift_consumeWorld :
    PrimitiveTagLift examplePolicy exampleGamma "consumeWorld" := by
  intro input residue nextTag specification plainInput plainOutput
    hname hinput hdelta hwellformed
  have hspecification : specification =
      { input := .snoc (.row "ρ") (.base .world .linear),
        output := .row "ρ", delta := consumeWorldDelta } :=
    (Option.some.inj hname).symm
  subst specification
  subst plainInput
  cases input with
  | nil => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, consumeWorldDelta] at hdelta; cases hdelta
  | cons first tail =>
    cases first with
    | literal tag literal => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, consumeWorldDelta] at hdelta; cases hdelta
    | quotation tag body usage => simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, consumeWorldDelta] at hdelta; cases hdelta
    | world worldTag payload =>
      simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, List.map, eraseValue, consumeWorldDelta] at hdelta
      have hplainOutput := Option.some.inj hdelta
      subst plainOutput
      let tailTags := taggedLinearTagsValueList tail
      let residueTags := taggedLinearTagsProgram residue
      have htags :
          taggedLinearTags
            { stack := .world worldTag payload :: tail,
              program := .cons (.prim "consumeWorld") residue,
              nextTag := nextTag } =
            worldTag :: (tailTags ++ residueTags) := by
        simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, taggedLinearTags, taggedLinearTagsValueList,
          taggedLinearTagsValue, taggedLinearTagsProgram,
          taggedLinearTagsAtom, tailTags, residueTags,
          taggedLinearTagsValueList_eq_foldr]
      unfold InstrumentedWellFormed at hwellformed
      rw [htags] at hwellformed
      have hworldAbsent : worldTag ∉ tailTags ++ residueTags :=
        (List.nodup_cons.mp hwellformed.1).1
      have hworldTailAbsent : worldTag ∉ tailTags := by
        intro hmem
        exact hworldAbsent (List.mem_append_left _ hmem)
      have hworldResidueAbsent : worldTag ∉ residueTags := by
        intro hmem
        exact hworldAbsent (List.mem_append_right _ hmem)
      have htailResidueNodup : (tailTags ++ residueTags).Nodup :=
        (List.nodup_cons.mp hwellformed.1).2
      let output : AStack := tail
      refine ⟨output, nextTag, ?_, Nat.le_refl _, ?_, ?_⟩
      · simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output]
      · refine ⟨
          { input := .snoc (.row "ρ") (.base .world .linear),
            output := .row "ρ", delta := consumeWorldDelta },
          .world payload :: tail.map eraseValue, tail.map eraseValue,
          tailTags, tailTags, [worldTag], [], ?_⟩
        refine
          { name_resolves := hname
            input_erases := by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, eraseValue]
            delta := by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, consumeWorldDelta, eraseValue]
            output_erases := by simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output]
            input_partition := ?_
            output_partition := ?_
            retained_nodup := ?_
            consumed_nodup := List.nodup_cons.mpr
              ⟨fun hmem => List.not_mem_nil hmem, List.nodup_nil⟩
            produced_nodup := List.nodup_nil
            retained_exact := ?_
            consumed_exact := ?_
            produced_exact := ?_
            retained_unchanged := ?_
            consumed_absent := ?_
            produced_fresh := by
              intro tag htag
              cases htag
            output_residue_nodup := by simpa only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, tailTags, residueTags]
              using htailResidueNodup
            frontier_monotone := Nat.le_refl _
            row_tail_retained := by
              intro tag htag
              exact htag
            stack_contract := .consumeWorld
            authorised := by
              change _ ∨ _ ∨
                ("consumeWorld" == "consumeWorld" ∧ [worldTag].length = 1 ∧ [] = [])
              exact Or.inr (Or.inr ⟨rfl, rfl, rfl⟩) }
        · intro tag
          simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, taggedLinearTagsValueList, taggedLinearTagsValue,
            tailTags, or_comm]
        · intro tag
          change tag ∈ tailTags ↔ tag ∈ tailTags ∨ tag ∈ ([] : Ownerships)
          constructor
          · intro htag
            exact Or.inl htag
          · intro htag
            cases htag with
            | inl htag => exact htag
            | inr htag => cases htag
        · exact (nodup_append_constructive.mp htailResidueNodup).1
        · intro tag
          constructor
          · intro htag
            refine ⟨?_, htag⟩
            simpa only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, taggedLinearTagsValueList, taggedLinearTagsValue,
              tailTags] using Or.inr htag
          · intro htag
            exact htag.2
        · intro tag
          constructor
          · intro htag
            have heq : tag = worldTag := List.mem_singleton.mp htag
            subst tag
            refine ⟨?_, hworldTailAbsent⟩
            simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, taggedLinearTagsValueList, taggedLinearTagsValue]
          · rintro ⟨hinputTag, houtputAbsent⟩
            have hinputCases : tag = worldTag ∨ tag ∈ tailTags := by
              simpa only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, taggedLinearTagsValueList, taggedLinearTagsValue,
                tailTags] using hinputTag
            rcases hinputCases with heq | htail
            · exact List.mem_singleton.mpr heq
            · exact (houtputAbsent htail).elim
        · intro tag
          constructor
          · intro htag
            cases htag
          · rintro ⟨houtputTag, hinputAbsent⟩
            exact (hinputAbsent (by
              simpa only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, taggedLinearTagsValueList,
                taggedLinearTagsValue, tailTags] using Or.inr houtputTag)).elim
        · have hfilter : List.filter
              (fun tag => ownershipContains tailTags tag) tailTags = tailTags :=
              filterContainsEqSelf_explicit tailTags tailTags (fun _ htag => htag)
          have hworldContainsFalse : ownershipContains tailTags worldTag = false := by
            cases hcontains : ownershipContains tailTags worldTag with
            | false => rfl
            | true =>
              exact (hworldTailAbsent
                (ownershipContains_eq_true_iff_mem.mp hcontains)).elim
          change tailTags = List.filter
            (fun tag => ownershipContains tailTags tag) (worldTag :: tailTags)
          rw [List.filter, hworldContainsFalse, hfilter]
        · intro tag htag
          have htag' : tag = worldTag := List.mem_singleton.mp htag
          subst tag
          exact ⟨hworldTailAbsent, hworldResidueAbsent⟩
      · intro tag htag
        exact hwellformed.2 tag (List.mem_cons_of_mem _
          (List.mem_append_left residueTags (by simpa only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, output, tailTags] using htag)))


theorem examplePrimitiveTagLift_unknown (name : Prim)
    (haddNat : name ≠ "addNat")
    (hmakeWorld : name ≠ "makeWorld")
    (hconsumeWorld : name ≠ "consumeWorld") :
    PrimitiveTagLift examplePolicy exampleGamma name := by
  intro input residue nextTag specification plainInput plainOutput hname
    hinput hdelta hwellformed
  have hnone : exampleGamma.primitive name = none := by
    simp only [List.foldr, List.singleton_append, List.cons_append, List.append_assoc, or_false, false_or, and_true, true_and, or_true, true_or, false_and, not_false_eq_true, eq_self, List.map, List.append_nil, List.nil_append, List.mem_append, List.mem_cons, List.not_mem_nil, Bool.false_eq_true, if_true, if_false, exampleGamma, defaultGamma, haddNat, hmakeWorld, hconsumeWorld]
  rw [hnone] at hname
  cases hname

theorem examplePrimitiveTagLift :
    ∀ name, PrimitiveTagLift examplePolicy exampleGamma name := by
  intro name
  by_cases haddNat : name = "addNat"
  · subst name
    exact examplePrimitiveTagLift_addNat
  · by_cases hmakeWorld : name = "makeWorld"
    · subst name
      exact examplePrimitiveTagLift_makeWorld
    · by_cases hconsumeWorld : name = "consumeWorld"
      · subst name
        exact examplePrimitiveTagLift_consumeWorld
      · exact examplePrimitiveTagLift_unknown name haddNat hmakeWorld hconsumeWorld

#print axioms filterContainsEqSelf_explicit
#print axioms examplePrimitiveTagLift_addNat
#print axioms examplePrimitiveTagLift_makeWorld
#print axioms examplePrimitiveTagLift_consumeWorld
#print axioms examplePrimitiveTagLift_unknown
#print axioms examplePrimitiveTagLift

theorem example_backward_adequacy_primitive_step :
    ∃ annotatedAfter,
      InstrumentedStep examplePolicy exampleGamma emptyDictionary defaultCosts
        { stack := [.literal 0 (.nat 3), .literal 1 (.nat 4)],
          program := .cons (.prim "addNat") .empty, nextTag := 2 }
        annotatedAfter ∧
      eraseAConfig annotatedAfter =
        { stack := [.literal (.nat (4 + 3))], program := .empty } ∧
      InstrumentedWellFormed annotatedAfter := by
  let annotatedBefore : AConfig :=
    { stack := [.literal 0 (.nat 3), .literal 1 (.nat 4)],
      program := .cons (.prim "addNat") .empty, nextTag := 2 }
  let before : Config :=
    { stack := [.literal (.nat 3), .literal (.nat 4)],
      program := .cons (.prim "addNat") .empty }
  let after : Config :=
    { stack := [.literal (.nat (4 + 3))], program := .empty }
  have hdictionary : AnnotatedDictionary emptyDictionary (fun _ => none) := by
    intro name entry frontier hentry
    simp [emptyDictionary] at hentry
  have hwellformed : InstrumentedWellFormed annotatedBefore := by
    change [].Nodup ∧ ∀ tag, tag ∈ [] → tag < 2
    exact ⟨List.nodup_nil, fun _ htag => (List.not_mem_nil htag).elim⟩
  have herases : eraseAConfig annotatedBefore = before := by
    rfl
  have htyped : TypedConfig exampleGamma emptyDictionary before := by
    refine ⟨
      .snoc (.snoc (.row "ρ") (.base .nat .many)) (.base .nat .many),
      .snoc (.row "ρ") (.base .nat .many), ?_, ?_⟩
    · exact .cons (.literal rfl) (.cons (.literal rfl) .empty)
    · exact ProgramTyping.cons
        (AtomTyping.prim (name := "addNat")
          (specification :=
            { input := .snoc (.snoc (.row "ρ") (.base .nat .many))
                (.base .nat .many),
              output := .snoc (.row "ρ") (.base .nat .many),
              delta := addNatDelta }) rfl)
        ProgramTyping.empty
  have hstep : HasSuccessor exampleGamma emptyDictionary defaultCosts before after := by
    refine ⟨defaultCosts.primitive "addNat", ?_⟩
    simp only [before, after, exampleGamma, defaultGamma, defaultCosts, step,
      addNatDelta]
  change ∃ annotatedAfter,
    InstrumentedStep examplePolicy exampleGamma emptyDictionary defaultCosts
      annotatedBefore annotatedAfter ∧
    eraseAConfig annotatedAfter = after ∧
    InstrumentedWellFormed annotatedAfter
  exact backward_adequacy (dictionary := emptyDictionary)
      (policy := examplePolicy) (gamma := exampleGamma)
      (costs := defaultCosts) (fun _ => none) hdictionary
      examplePrimitiveTagLift hwellformed herases htyped hstep

#print axioms example_backward_adequacy_primitive_step

def expectTerminalStack (expected : Stack) : RunResult → Bool
  | .terminal config _ _ => config.stack == expected
  | _ => false

def expectTerminalCost (expected : Nat) : RunResult → Bool
  | .terminal _ _ cost => cost == expected
  | _ => false

def expectOutOfFuel (result : RunResult) : Bool :=
  match result with
  | .outOfFuel _ _ _ => true
  | _ => false

def runTest (name : String) (condition : Bool) : IO Unit :=
  if condition then pure () else throw <| IO.userError s!"test failed: {name}"

def main : IO Unit := do
  let gamma := defaultGamma
  let d := emptyDictionary
  let c := defaultCosts
  let lit value := Value.literal (.nat value)
  -- S-LIT, S-DUP, S-DROP, S-SWAP.
  let structural :=
    { stack := ([] : Stack),
      program := .cons (.lit (.nat 7)) (.cons (.lit (.nat 8)) (.cons .drop .empty)) }
  runTest "structural atoms"
    (expectTerminalStack [lit 7] (run gamma d c 20 structural))
  runTest "dup preserves both values"
    (expectTerminalStack [lit 7, lit 7]
      (run gamma d c 20 { stack := [], program := .cons (.lit (.nat 7)) (.cons .dup .empty) }))
  runTest "swap preserves order"
    (expectTerminalStack [lit 7, lit 8]
      (run gamma d c 20 { stack := [], program := (.cons (.lit (.nat 7))
        (.cons (.lit (.nat 8)) (.cons .swap .empty))) }))
  runTest "parameterised cost"
    (expectTerminalCost 3 (run gamma d { c with atom := fun _ => 3 } 10
      { stack := [], program := .cons (.lit (.nat 0)) .empty }))
  -- S-QUOT, S-CALL, and S-PUSH.
  let callResult := run gamma d c 20
    { stack := [], program := .cons (.quotation (.cons (.lit (.nat 9)) .empty))
        (.cons .call .empty) }
  runTest "quotation call" (expectTerminalStack [lit 9] callResult)
  let closedQuotationResult := run gamma d c 20
    { stack := [], program := .cons (.quotation .empty) .empty }
  runTest "S-QUOT closed usage is many" (match closedQuotationResult with
    | .terminal { stack := [.quotation .empty .many], .. } _ _ => true
    | _ => false)
  let nestedCaptureQuotationResult := run gamma d c 20
    { stack := [], program := .cons (.quotation
        (.cons (.push (.world 0)) .empty)) .empty }
  runTest "S-QUOT recursive capture footprint is linear" (match nestedCaptureQuotationResult with
    | .terminal { stack := [.quotation body .linear], .. } _ _ =>
        body == .cons (.push (.world 0)) .empty
    | _ => false)
  -- S-DIP preserves the value by administrative push.
  let dipResult := run gamma d c 20
    { stack := [], program := .cons (.lit (.nat 4))
        (.cons (.quotation (.cons (.lit (.nat 5)) .empty)) (.cons .dip .empty)) }
  runTest "dip" (expectTerminalStack [lit 4, lit 5] dipResult)
  -- S-COMP, then S-CALL.
  let composed := .cons (.quotation (.cons (.lit (.nat 1)) .empty))
    (.cons (.quotation (.cons (.lit (.nat 2)) .empty)) (.cons .compose (.cons .call .empty)))
  runTest "compose" (expectTerminalStack [lit 2, lit 1]
    (run gamma d c 30 { stack := [], program := composed }))
  -- S-QUOTE captures a linear World value and records linear ownership.
  let capture := .cons (.prim "makeWorld") (.cons .quote .empty)
  let captureResult := run gamma d c 20 { stack := [], program := capture }
  let capturedLinear := match captureResult with
    | .terminal { stack := .quotation body .linear :: _, .. } _ _ =>
        body == .cons (.push (.world 0)) .empty
    | _ => false
  runTest "linear quote capture" capturedLinear
  runTest "compose usage meet" (match step gamma d c
    { stack := [.quotation .empty .linear, .quotation .empty .many], program := .cons .compose .empty } with
    | .stepped { stack := [.quotation .empty .linear], program := .empty } 1 => true
    | _ => false)
  runTest "compose many then linear remains linear" (match step gamma d c
    { stack := [.quotation .empty .many, .quotation .empty .linear], program := .cons .compose .empty } with
    | .stepped { stack := [.quotation .empty .linear], program := .empty } 1 => true
    | _ => false)
  runTest "compose many and many remains many" (match step gamma d c
    { stack := [.quotation .empty .many, .quotation .empty .many], program := .cons .compose .empty } with
    | .stepped { stack := [.quotation .empty .many], program := .empty } 1 => true
    | _ => false)
  -- S-IF-T and S-IF-F, with exact selected values.
  let ifProgram condition :=
    .cons (.lit (.bool condition))
      (.cons (.quotation (.cons (.lit (.nat 1)) .empty))
        (.cons (.quotation (.cons (.lit (.nat 2)) .empty)) (.cons .ifThenElse .empty)))
  runTest "if true" (expectTerminalStack [lit 1]
    (run gamma d c 20 { stack := [], program := ifProgram true }))
  runTest "if false" (expectTerminalStack [lit 2]
    (run gamma d c 20 { stack := [], program := ifProgram false }))
  -- S-WORD and S-PRIM.
  let words : Dictionary := fun name =>
    if name == "one" then some { type := { rowVariables := ["ρ"], input := .row "ρ", output := .snoc (.row "ρ") (.base .nat .many) },
                                    body := .cons (.lit (.nat 1)) .empty }
    else none
  runTest "dictionary word" (expectTerminalStack [lit 1]
    (run gamma words c 20 { stack := [], program := .cons (.word "one") .empty }))
  runTest "word cost" (expectTerminalCost 5
    (run gamma words { c with unfold := 4 } 20
      { stack := [], program := .cons (.word "one") .empty }))
  runTest "primitive add" (expectTerminalStack [lit 7]
    (run gamma d c 20 { stack := [], program := (.cons (.lit (.nat 3))
      (.cons (.lit (.nat 4)) (.cons (.prim "addNat") .empty))) }))
  runTest "primitive world" (expectTerminalStack []
    (run gamma d c 20 { stack := [], program := (.cons (.prim "makeWorld")
      (.cons (.prim "consumeWorld") .empty)) }))
  runTest "primitive cost" (expectTerminalCost 10
    (run gamma d { c with primitive := fun _ => 5 } 20
      { stack := [], program := (.cons (.prim "makeWorld")
        (.cons (.prim "consumeWorld") .empty)) }))
  let consumedBefore : AConfig :=
    { stack := [.world 0 7], program := .cons (.prim "consumeWorld") .empty,
      nextTag := 1 }
  let consumedAfter : AConfig :=
    { stack := [], program := .empty, nextTag := 1 }
  runTest "finite consumption event" (consumed consumedBefore consumedAfter == [0])
  runTest "finite at-most-once" (decide (traceConsumed [consumedBefore, consumedAfter]).Nodup)
  runTest "finite exact-once event count" (traceConsumed [consumedBefore, consumedAfter] == [0])
  -- A recursive word demonstrates that execution may diverge. Fuel is a driver
  -- artefact that keeps this executable total; it is not kernel semantics, and
  -- genuine kernel divergence remains divergence.
  let loopWords : Dictionary := fun name =>
    if name == "loop" then some { type := { rowVariables := ["ρ"], input := .row "ρ", output := .row "ρ" },
                                    body := .cons (.word "loop") .empty }
    else none
  runTest "fuel-bounded divergence"
    (expectOutOfFuel (run gamma loopWords c 12 { stack := [], program := .cons (.word "loop") .empty }))
  let loopLive : AConfig :=
    { stack := [.world 0 7], program := .cons (.word "loop") .empty, nextTag := 1 }
  runTest "loop witness retains live tag"
    (taggedLinearTags loopLive == [0] && taggedLinearTags loopLive == [0])
  let customGamma := { gamma with
    literalType := fun _ => none
    primitive := fun name => if name == "custom" then
      some { input := .row "ρ", output := .snoc (.row "ρ") (.base .nat .many),
             delta := fun stack => some (.literal (.nat 42) :: stack) }
      else none }
  runTest "Gamma controls literals" (match run customGamma d c 2
    { stack := [], program := .cons (.lit (.nat 1)) .empty } with
    | .stuck _ 0 0 => true
    | _ => false)
  runTest "Gamma controls primitive delta" (expectTerminalStack [lit 42]
    (run customGamma d c 2 { stack := [], program := .cons (.prim "custom") .empty }))
  -- The elaborator is the rejection point for malformed or ill-typed input;
  -- a stuck result here records that the unchecked driver received such input.
  runTest "malformed input is stuck" (match run gamma d c 2
    { stack := [], program := .cons .drop .empty } with
    | .stuck _ 0 0 => true
    | _ => false)
  runTest "S-PUSH has zero kappa cost" (match step gamma d { c with atom := fun _ => 99 }
    { stack := [], program := .cons (.push (.literal (.nat 9))) .empty } with
    | .stepped { stack := [Value.literal (.nat 9)], program := .empty } 0 => true
    | _ => false)
  runTest "one transition with one fuel" (expectTerminalStack [lit 1]
    (run gamma d c 1 { stack := [], program := .cons (.lit (.nat 1)) .empty }))
  runTest "terminal needs no fuel"
    (match run gamma d c 0 { stack := [], program := .empty } with
     | .terminal _ 0 0 => true
     | _ => false)
  IO.println "all interpreter tests passed"
