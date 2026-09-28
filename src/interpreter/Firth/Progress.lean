import Firth.KernelMetatheory

namespace Firth.Interpreter

/-! Progress for the frozen kernel transition system.

The executable `Gamma` type is intentionally permissive, so progress carries
the specification's literal-signature well-formedness condition explicitly.
Likewise, primitive totality is a premise because `PrimitiveSpec.delta` is
represented as an `Option` in the unchecked interpreter. A primitive declared
with `faults := true` (a sequence index read or replaced, or integer division
and remainder on a zero divisor) is exempt from totality, so progress
has exactly one exception: such a primitive faulting on its typed input.
-/

def LiteralTypingSound (gamma : Gamma) : Prop :=
  ∀ literal base, gamma.literalType literal = some base →
    match literal, base with
    | .int _, .int => True
    | .bool _, .bool => True
    | .unit, .unit => True
    | .intSeq _, .intSeq => True
    | .boolSeq _, .boolSeq => True
    | _, _ => False

def PrimitivesTotal (gamma : Gamma) (dictionary : Dictionary) : Prop :=
  ∀ name specification stack,
    gamma.primitive name = some specification →
    specification.faults = false →
    StackTyping gamma dictionary stack specification.input →
    ∃ result, specification.delta stack = some result

def PrimitivesWellFormed (gamma : Gamma) (dictionary : Dictionary) : Prop :=
  PrimitivesPreserve gamma dictionary ∧ PrimitivesTotal gamma dictionary

theorem defaultGamma_literalTypingSound : LiteralTypingSound defaultGamma := by
  intro literal base h
  cases literal <;> simp [defaultGamma] at h ⊢ <;> subst base <;> trivial

/-- The one way a well-typed configuration may stop before its program ends:
its next atom is a primitive declared `faults := true` whose delta refused the
stack, and the interpreter is stuck there (a primitive fault). -/
def PrimitiveFault (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (config : Config) : Prop :=
  ∃ name specification rest, config.program = .cons (.prim name) rest ∧
    gamma.primitive name = some specification ∧ specification.faults = true ∧
    step gamma dictionary costs config = .stuck config

theorem progress (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (literalTypingSound : LiteralTypingSound gamma)
    (_dictionaryWellTyped : DictionaryWellTyped gamma dictionary)
    (primitivesWellFormed : PrimitivesWellFormed gamma dictionary) {config : Config} :
    /- Dictionary well-typedness is retained as the specification-level
       premise.  The `AtomTyping.word` constructor supplies the concrete body
       lookup needed by this progress proof; preservation uses this premise
       when it needs the body's typing derivation. -/
    TypedConfig gamma dictionary config →
      config.program ≠ .empty →
      (∃ next, HasSuccessor gamma dictionary costs config next) ∨
        PrimitiveFault gamma dictionary costs config := by
  intro configTyping nonterminal
  rcases config with ⟨stack, program⟩
  rcases configTyping with ⟨stackType, outputType, stackTyping, programTyping⟩
  cases program with
  | empty => exact False.elim (nonterminal rfl)
  | cons head rest =>
      cases programTyping with
      | cons headTyping restTyping =>
        cases head with
        | lit literal =>
            cases headTyping with
            | lit h =>
                refine .inl ⟨{ stack := .literal literal :: stack, program := rest }, ?_⟩
                exact ⟨costs.atom (.lit literal), by simp [step, h]⟩
        | push value =>
            cases headTyping with
            | push h =>
                refine .inl ⟨{ stack := value :: stack, program := rest }, ?_⟩
                exact ⟨0, by simp [step]⟩
        | quotation body =>
            cases headTyping with
            | quotation h =>
                let next : Config :=
                  { stack := (Value.quotation body (programUsage body)) :: stack,
                    program := rest }
                refine .inl ⟨next, ?_⟩
                exact ⟨costs.atom (.quotation body), by simp [next, step]⟩
        | dup =>
            cases headTyping with
            | dup h =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨value, tail, rfl, valueTyping, tailTyping⟩
                refine .inl ⟨{ stack := value :: value :: tail, program := rest }, ?_⟩
                exact ⟨costs.atom .dup, by simp [step]⟩
        | drop =>
            cases headTyping with
            | drop h =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨value, tail, rfl, valueTyping, tailTyping⟩
                refine .inl ⟨{ stack := tail, program := rest }, ?_⟩
                exact ⟨costs.atom .drop, by simp [step]⟩
        | swap =>
            cases headTyping with
            | swap =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨second, tail₁, rfl, secondTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with
                  ⟨first, tail, rfl, firstTyping, tailTyping⟩
                refine .inl ⟨{ stack := first :: second :: tail, program := rest }, ?_⟩
                exact ⟨costs.atom .swap, by simp [step]⟩
        | pick depth =>
            cases headTyping with
            | pick h many =>
                rcases stackTyping_pickAt stackTyping h with ⟨value, found, valueTyping⟩
                refine .inl ⟨{ stack := value :: stack, program := rest }, ?_⟩
                exact ⟨costs.atom (.pick depth), by simp [step, found]⟩
        | roll depth =>
            cases headTyping with
            | roll h =>
                rcases stackTyping_rollAt stackTyping h with
                  ⟨value, tail, found, valueTyping, tailTyping⟩
                refine .inl ⟨{ stack := value :: tail, program := rest }, ?_⟩
                exact ⟨costs.atom (.roll depth), by simp [step, found]⟩
        | call =>
            cases headTyping with
            | call =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨quotation, tail, rfl, quotationTyping, tailTyping⟩
                rcases valueTyping_quotation_unpack quotationTyping with
                  ⟨body, rfl, usageEq, bodyTyping⟩
                refine .inl ⟨{ stack := tail, program := body.append rest }, ?_⟩
                exact ⟨costs.atom .call, by simp [step]⟩
        | dip =>
            cases headTyping with
            | dip =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨quotation, tail₁, rfl, quotationTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with
                  ⟨value, tail, rfl, valueTyping, tailTyping⟩
                rcases valueTyping_quotation_unpack quotationTyping with
                  ⟨body, rfl, usageEq, bodyTyping⟩
                let next : Config :=
                  { stack := tail, program := body.append (.cons (.push value) rest) }
                refine .inl ⟨next, ?_⟩
                exact ⟨costs.atom .dip, by simp [next, step]⟩
        | compose =>
            cases headTyping with
            | compose =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨secondQuotation, tail₁, rfl, secondTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with
                  ⟨firstQuotation, tail, rfl, firstTyping, baseTyping⟩
                rcases valueTyping_quotation_unpack secondTyping with
                  ⟨second, rfl, usage₂Eq, secondTyping⟩
                rcases valueTyping_quotation_unpack firstTyping with
                  ⟨first, rfl, usage₁Eq, firstTyping⟩
                let next : Config :=
                  { stack := (Value.quotation (first.append second)
                      (usageMeet (programUsage first) (programUsage second))) :: tail,
                    program := rest }
                refine .inl ⟨next, ?_⟩
                exact ⟨costs.atom .compose, by simp [next, step,
                  compose_usage_runtime_eq]⟩
        | quote =>
            cases headTyping with
            | quote =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨value, tail, rfl, valueTyping, tailTyping⟩
                let next : Config :=
                  { stack := (Value.quotation (.cons (.push value) .empty)
                      (quotationUsage value)) :: tail, program := rest }
                refine .inl ⟨next, ?_⟩
                exact ⟨costs.atom .quote, by simp [next, step]⟩
        | ifThenElse =>
            cases headTyping with
            | ifThenElse =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨falseQuotation, tail₁, rfl, falseTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with
                  ⟨trueQuotation, tail₂, rfl, trueTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with
                  ⟨conditionValue, tail, rfl, conditionTyping, baseTyping⟩
                cases conditionValue with
                | world id => cases conditionTyping
                | quotation body usage => cases conditionTyping
                | literal literal =>
                  cases literal with
                  | bool condition =>
                    cases conditionTyping with
                    | literal conditionType =>
                        rcases valueTyping_quotation_unpack falseTyping with
                          ⟨falseBody, rfl, falseUsageEq, falseBodyTyping⟩
                        rcases valueTyping_quotation_unpack trueTyping with
                          ⟨trueBody, rfl, trueUsageEq, trueBodyTyping⟩
                        let chosen := if condition then trueBody else falseBody
                        refine .inl ⟨{ stack := tail, program := chosen.append rest }, ?_⟩
                        exact ⟨costs.atom .ifThenElse, by simp [step, chosen]⟩
                  | int value =>
                    cases conditionTyping with
                    | literal conditionType =>
                      exact False.elim (by
                        have h := literalTypingSound (.int value) .bool conditionType
                        simp at h)
                  | unit =>
                    cases conditionTyping with
                    | literal conditionType =>
                      exact False.elim (by
                        have h := literalTypingSound .unit .bool conditionType
                        simp at h)
                  | intSeq values =>
                    cases conditionTyping with
                    | literal conditionType =>
                      exact False.elim (by
                        have h := literalTypingSound (.intSeq values) .bool conditionType
                        simp at h)
                  | boolSeq values =>
                    cases conditionTyping with
                    | literal conditionType =>
                      exact False.elim (by
                        have h := literalTypingSound (.boolSeq values) .bool conditionType
                        simp at h)
        | word name =>
            cases headTyping with
            | word h =>
                rcases h with ⟨entry, entryEq, entryInput, entryOutput⟩
                refine .inl ⟨{ stack := stack, program := entry.body.append rest }, ?_⟩
                exact ⟨costs.unfold, by simp [step, entryEq]⟩
        | prim name =>
            cases headTyping with
            | prim h =>
                rename_i specification
                cases faults : specification.faults with
                | false =>
                    rcases primitivesWellFormed.2 name _ stack h faults stackTyping with
                      ⟨result, deltaEq⟩
                    exact .inl ⟨{ stack := result, program := rest },
                      costs.primitive name, by simp [step, h, deltaEq]⟩
                | true =>
                    cases deltaEq : specification.delta stack with
                    | some result =>
                        exact .inl ⟨{ stack := result, program := rest },
                          costs.primitive name, by simp [step, h, deltaEq]⟩
                    | none =>
                        exact .inr ⟨name, specification, rest, rfl, h, faults,
                          by simp [step, h, deltaEq]⟩


theorem defaultGamma_int_literal {dictionary : Dictionary} {value : Value}
    (h : ValueTyping defaultGamma dictionary value (.base .int .many)) :
    ∃ n, value = .literal (.int n) := by
  cases h with
  | literal hlit =>
    rename_i literal
    cases literal with
    | int n => exact ⟨n, rfl⟩
    | bool _ => simp [defaultGamma] at hlit
    | unit => simp [defaultGamma] at hlit
    | intSeq _ => simp [defaultGamma] at hlit
    | boolSeq _ => simp [defaultGamma] at hlit

theorem defaultGamma_bool_literal {dictionary : Dictionary} {value : Value}
    (h : ValueTyping defaultGamma dictionary value (.base .bool .many)) :
    ∃ b, value = .literal (.bool b) := by
  cases h with
  | literal hlit =>
    rename_i literal
    cases literal with
    | bool b => exact ⟨b, rfl⟩
    | int _ => simp [defaultGamma] at hlit
    | unit => simp [defaultGamma] at hlit
    | intSeq _ => simp [defaultGamma] at hlit
    | boolSeq _ => simp [defaultGamma] at hlit

theorem defaultGamma_intSeq_literal {dictionary : Dictionary} {value : Value}
    (h : ValueTyping defaultGamma dictionary value (.base .intSeq .many)) :
    ∃ values, value = .literal (.intSeq values) := by
  cases h with
  | literal hlit =>
    rename_i literal
    cases literal with
    | intSeq values => exact ⟨values, rfl⟩
    | int _ => simp [defaultGamma] at hlit
    | bool _ => simp [defaultGamma] at hlit
    | unit => simp [defaultGamma] at hlit
    | boolSeq _ => simp [defaultGamma] at hlit

theorem defaultGamma_boolSeq_literal {dictionary : Dictionary} {value : Value}
    (h : ValueTyping defaultGamma dictionary value (.base .boolSeq .many)) :
    ∃ values, value = .literal (.boolSeq values) := by
  cases h with
  | literal hlit =>
    rename_i literal
    cases literal with
    | boolSeq values => exact ⟨values, rfl⟩
    | int _ => simp [defaultGamma] at hlit
    | bool _ => simp [defaultGamma] at hlit
    | unit => simp [defaultGamma] at hlit
    | intSeq _ => simp [defaultGamma] at hlit

theorem defaultGamma_int_pair {dictionary : Dictionary} {stack : Stack}
    (h : StackTyping defaultGamma dictionary stack
      (.snoc (.snoc (.row "ρ") (.base .int .many)) (.base .int .many))) :
    ∃ left right, stack = [.literal (.int right), .literal (.int left)] := by
  cases h with
  | cons rightType tailType =>
    cases tailType with
    | cons leftType emptyType =>
      cases emptyType
      obtain ⟨right, rfl⟩ := defaultGamma_int_literal rightType
      obtain ⟨left, rfl⟩ := defaultGamma_int_literal leftType
      exact ⟨left, right, rfl⟩

theorem defaultGamma_bool_pair {dictionary : Dictionary} {stack : Stack}
    (h : StackTyping defaultGamma dictionary stack
      (.snoc (.snoc (.row "ρ") (.base .bool .many)) (.base .bool .many))) :
    ∃ left right, stack = [.literal (.bool right), .literal (.bool left)] := by
  cases h with
  | cons rightType tailType =>
    cases tailType with
    | cons leftType emptyType =>
      cases emptyType
      obtain ⟨right, rfl⟩ := defaultGamma_bool_literal rightType
      obtain ⟨left, rfl⟩ := defaultGamma_bool_literal leftType
      exact ⟨left, right, rfl⟩

private theorem literal_stack {dictionary : Dictionary} (literal : Literal) (base : BaseType)
    (h : defaultGamma.literalType literal = some base) :
    StackTyping defaultGamma dictionary [.literal literal] (.snoc (.row "ρ") (.base base .many)) :=
  .cons (.literal h) .empty

/-- The shipped primitive table satisfies both premises of progress and
preservation: every primitive preserves its declared stack, and every
primitive not declared `faults := true` is total on it. -/
theorem defaultGamma_primitivesWellFormed (dictionary : Dictionary) :
    PrimitivesWellFormed defaultGamma dictionary := by
  constructor
  · intro name specification stack result hname htyped hdelta
    simp only [defaultGamma] at hname
    split at hname <;> cases hname
    · obtain ⟨l, r, rfl⟩ := defaultGamma_int_pair htyped
      simp only [addIntDelta, Option.some.injEq] at hdelta; subst hdelta
      exact literal_stack _ _ rfl
    · obtain ⟨l, r, rfl⟩ := defaultGamma_int_pair htyped
      simp only [subIntDelta, Option.some.injEq] at hdelta; subst hdelta
      exact literal_stack _ _ rfl
    · obtain ⟨l, r, rfl⟩ := defaultGamma_int_pair htyped
      simp only [mulIntDelta, Option.some.injEq] at hdelta; subst hdelta
      exact literal_stack _ _ rfl
    · obtain ⟨l, r, rfl⟩ := defaultGamma_int_pair htyped
      simp only [ltIntDelta, Option.some.injEq] at hdelta; subst hdelta
      exact literal_stack _ _ rfl
    · obtain ⟨l, r, rfl⟩ := defaultGamma_int_pair htyped
      simp only [eqIntDelta, Option.some.injEq] at hdelta; subst hdelta
      exact literal_stack _ _ rfl
    · -- divInt
      obtain ⟨l, r, rfl⟩ := defaultGamma_int_pair htyped
      simp only [divIntDelta] at hdelta
      split at hdelta
      · cases hdelta
      · simp only [Option.some.injEq] at hdelta; subst hdelta
        exact literal_stack _ _ rfl
    · -- modInt
      obtain ⟨l, r, rfl⟩ := defaultGamma_int_pair htyped
      simp only [modIntDelta] at hdelta
      split at hdelta
      · cases hdelta
      · simp only [Option.some.injEq] at hdelta; subst hdelta
        exact literal_stack _ _ rfl
    · obtain ⟨l, r, rfl⟩ := defaultGamma_bool_pair htyped
      simp only [andBoolDelta, Option.some.injEq] at hdelta; subst hdelta
      exact literal_stack _ _ rfl
    · obtain ⟨l, r, rfl⟩ := defaultGamma_bool_pair htyped
      simp only [orBoolDelta, Option.some.injEq] at hdelta; subst hdelta
      exact literal_stack _ _ rfl
    · -- notBool
      cases htyped with
      | cons valueType emptyType =>
        cases emptyType
        obtain ⟨value, rfl⟩ := defaultGamma_bool_literal valueType
        simp only [notBoolDelta, Option.some.injEq] at hdelta; subst hdelta
        exact literal_stack _ _ rfl
    · -- intSeqEmpty
      cases htyped
      simp only [intSeqEmptyDelta, Option.some.injEq] at hdelta; subst hdelta
      exact literal_stack _ _ rfl
    · -- intSeqLen
      cases htyped with
      | cons seqType emptyType =>
        cases emptyType
        obtain ⟨values, rfl⟩ := defaultGamma_intSeq_literal seqType
        simp only [intSeqLenDelta, Option.some.injEq] at hdelta; subst hdelta
        exact literal_stack _ _ rfl
    · -- intSeqAt
      cases htyped with
      | cons indexType tailType =>
        cases tailType with
        | cons seqType emptyType =>
          cases emptyType
          obtain ⟨index, rfl⟩ := defaultGamma_int_literal indexType
          obtain ⟨values, rfl⟩ := defaultGamma_intSeq_literal seqType
          simp only [intSeqAtDelta] at hdelta
          cases hat : elementAt? values index with
          | none => simp [hat] at hdelta
          | some value =>
            simp only [hat, Option.map_some, Option.some.injEq] at hdelta; subst hdelta
            exact literal_stack _ _ rfl
    · -- intSeqPush
      cases htyped with
      | cons valueType tailType =>
        cases tailType with
        | cons seqType emptyType =>
          cases emptyType
          obtain ⟨value, rfl⟩ := defaultGamma_int_literal valueType
          obtain ⟨values, rfl⟩ := defaultGamma_intSeq_literal seqType
          simp only [intSeqPushDelta, Option.some.injEq] at hdelta; subst hdelta
          exact literal_stack _ _ rfl
    · -- intSeqSet
      cases htyped with
      | cons valueType tailType =>
        cases tailType with
        | cons indexType tailType =>
          cases tailType with
          | cons seqType emptyType =>
            cases emptyType
            obtain ⟨value, rfl⟩ := defaultGamma_int_literal valueType
            obtain ⟨index, rfl⟩ := defaultGamma_int_literal indexType
            obtain ⟨values, rfl⟩ := defaultGamma_intSeq_literal seqType
            simp only [intSeqSetDelta] at hdelta
            cases hset : replaceAt? values index value with
            | none => simp [hset] at hdelta
            | some updated =>
              simp only [hset, Option.map_some, Option.some.injEq] at hdelta; subst hdelta
              exact literal_stack _ _ rfl
    · -- boolSeqEmpty
      cases htyped
      simp only [boolSeqEmptyDelta, Option.some.injEq] at hdelta; subst hdelta
      exact literal_stack _ _ rfl
    · -- boolSeqLen
      cases htyped with
      | cons seqType emptyType =>
        cases emptyType
        obtain ⟨values, rfl⟩ := defaultGamma_boolSeq_literal seqType
        simp only [boolSeqLenDelta, Option.some.injEq] at hdelta; subst hdelta
        exact literal_stack _ _ rfl
    · -- boolSeqAt
      cases htyped with
      | cons indexType tailType =>
        cases tailType with
        | cons seqType emptyType =>
          cases emptyType
          obtain ⟨index, rfl⟩ := defaultGamma_int_literal indexType
          obtain ⟨values, rfl⟩ := defaultGamma_boolSeq_literal seqType
          simp only [boolSeqAtDelta] at hdelta
          cases hat : elementAt? values index with
          | none => simp [hat] at hdelta
          | some value =>
            simp only [hat, Option.map_some, Option.some.injEq] at hdelta; subst hdelta
            exact literal_stack _ _ rfl
    · -- boolSeqPush
      cases htyped with
      | cons valueType tailType =>
        cases tailType with
        | cons seqType emptyType =>
          cases emptyType
          obtain ⟨value, rfl⟩ := defaultGamma_bool_literal valueType
          obtain ⟨values, rfl⟩ := defaultGamma_boolSeq_literal seqType
          simp only [boolSeqPushDelta, Option.some.injEq] at hdelta; subst hdelta
          exact literal_stack _ _ rfl
    · -- boolSeqSet
      cases htyped with
      | cons valueType tailType =>
        cases tailType with
        | cons indexType tailType =>
          cases tailType with
          | cons seqType emptyType =>
            cases emptyType
            obtain ⟨value, rfl⟩ := defaultGamma_bool_literal valueType
            obtain ⟨index, rfl⟩ := defaultGamma_int_literal indexType
            obtain ⟨values, rfl⟩ := defaultGamma_boolSeq_literal seqType
            simp only [boolSeqSetDelta] at hdelta
            cases hset : replaceAt? values index value with
            | none => simp [hset] at hdelta
            | some updated =>
              simp only [hset, Option.map_some, Option.some.injEq] at hdelta; subst hdelta
              exact literal_stack _ _ rfl
    · cases htyped
      simp only [makeWorldDelta, Option.some.injEq] at hdelta; subst hdelta
      exact .cons .world .empty
    · cases htyped with
      | cons worldType emptyType =>
        cases emptyType
        cases worldType
        simp only [consumeWorldDelta, Option.some.injEq] at hdelta; subst hdelta
        exact .empty
  · intro name specification stack hname hfaults htyped
    simp only [defaultGamma] at hname
    split at hname <;> cases hname
    all_goals first
      | (simp at hfaults; done)
      | (obtain ⟨l, r, rfl⟩ := defaultGamma_int_pair htyped; exact ⟨_, rfl⟩)
      | (obtain ⟨l, r, rfl⟩ := defaultGamma_bool_pair htyped; exact ⟨_, rfl⟩)
      | exact ⟨_, rfl⟩
      | (cases htyped with
         | cons seqType emptyType =>
           cases emptyType
           first
             | (obtain ⟨values, rfl⟩ := defaultGamma_intSeq_literal seqType; exact ⟨_, rfl⟩)
             | (obtain ⟨values, rfl⟩ := defaultGamma_boolSeq_literal seqType; exact ⟨_, rfl⟩)
             | (obtain ⟨value, rfl⟩ := defaultGamma_bool_literal seqType; exact ⟨_, rfl⟩))
      | (cases htyped with
         | cons valueType tailType =>
           cases tailType with
           | cons seqType emptyType =>
             cases emptyType
             first
               | (obtain ⟨value, rfl⟩ := defaultGamma_int_literal valueType
                  obtain ⟨values, rfl⟩ := defaultGamma_intSeq_literal seqType
                  exact ⟨_, rfl⟩)
               | (obtain ⟨value, rfl⟩ := defaultGamma_bool_literal valueType
                  obtain ⟨values, rfl⟩ := defaultGamma_boolSeq_literal seqType
                  exact ⟨_, rfl⟩))
      | (cases htyped with
         | cons worldType emptyType => cases emptyType; cases worldType; exact ⟨_, rfl⟩)

/-- Type safety for the shipped primitive table: a well-typed configuration
under a well-typed dictionary either has finished, steps to a configuration
that is again well typed, or stops at a primitive declared `faults := true`:
a sequence index out of range for `at` or `set`, or a zero divisor. No premise about primitives remains. -/
theorem defaultGamma_typeSafety (dictionary : Dictionary) (costs : CostTable)
    (dictionaryWellTyped : DictionaryWellTyped defaultGamma dictionary) {config : Config}
    (configTyping : TypedConfig defaultGamma dictionary config)
    (nonterminal : config.program ≠ .empty) :
    (∃ next, HasSuccessor defaultGamma dictionary costs config next ∧
      TypedConfig defaultGamma dictionary next) ∨
      PrimitiveFault defaultGamma dictionary costs config := by
  have wellFormed := defaultGamma_primitivesWellFormed dictionary
  rcases progress defaultGamma dictionary costs
    defaultGamma_literalTypingSound dictionaryWellTyped wellFormed configTyping nonterminal with
    ⟨next, successor⟩ | fault
  · exact .inl ⟨next, successor,
      preservation defaultGamma dictionary costs dictionaryWellTyped wellFormed.1 configTyping successor⟩
  · exact .inr fault

/-- The primitives that may fault are exactly the two sequence reads, the two
sequence replacements, and integer division and remainder. -/
theorem defaultGamma_faulting_primitives (name : Prim) (specification : PrimitiveSpec)
    (h : defaultGamma.primitive name = some specification) (faults : specification.faults = true) :
    name = "intSeqAt" ∨ name = "boolSeqAt" ∨ name = "intSeqSet" ∨ name = "boolSeqSet" ∨
      name = "divInt" ∨ name = "modInt" := by
  simp only [defaultGamma] at h
  split at h <;> cases h <;> simp_all

/- These guards execute representative well-typed transition shapes while
   compiling the module, keeping progress smoke coverage next to the proof. -/
def progressSmokeLiteral : Bool :=
  match step defaultGamma emptyDictionary defaultCosts
      { stack := [], program := .cons (.lit (.int 7)) .empty } with
  | .stepped { stack := [.literal (.int 7)], program := .empty } 1 => true
  | _ => false

#guard progressSmokeLiteral = true

def progressSmokeQuotationCall : Bool :=
  match run defaultGamma emptyDictionary defaultCosts 8
      { stack := [], program :=
          .cons (.quotation (.cons (.lit (.int 9)) .empty))
            (.cons .call .empty) } with
  | .terminal { stack := [.literal (.int 9)], program := .empty } _ _ => true
  | _ => false

#guard progressSmokeQuotationCall = true

/- `{ 4 5 } 1 at` reads the second element; `{ 4 5 } 2 at` is a primitive
   fault, never a default value, and so is a negative index. -/
def progressSmokeSeqAt (index : Int) : Option Int :=
  match run defaultGamma emptyDictionary defaultCosts 8
      { stack := [], program :=
          .cons (.lit (.intSeq [4, 5])) (.cons (.lit (.int index)) (.cons (.prim "intSeqAt") .empty)) } with
  | .terminal { stack := [.literal (.int value)], program := .empty } _ _ => some value
  | _ => none

#guard progressSmokeSeqAt 1 = some 5
#guard progressSmokeSeqAt 2 = none
#guard progressSmokeSeqAt (-1) = none

def progressSmokeSeqPush : Bool :=
  match run defaultGamma emptyDictionary defaultCosts 8
      { stack := [], program :=
          .cons (.prim "boolSeqEmpty") (.cons (.lit (.bool true)) (.cons (.prim "boolSeqPush")
            (.cons (.prim "boolSeqLen") .empty))) } with
  | .terminal { stack := [.literal (.int 1)], program := .empty } _ _ => true
  | _ => false

#guard progressSmokeSeqPush = true

/- `and`, `or` and `not` on each input. -/
def progressSmokeBool (program : Program) : Option Bool :=
  match run defaultGamma emptyDictionary defaultCosts 8 { stack := [], program } with
  | .terminal { stack := [.literal (.bool value)], program := .empty } _ _ => some value
  | _ => none

def boolBinary (name : Prim) (left right : Bool) : Program :=
  .cons (.lit (.bool left)) (.cons (.lit (.bool right)) (.cons (.prim name) .empty))

#guard [false, true].all fun left => [false, true].all fun right =>
  progressSmokeBool (boolBinary "andBool" left right) = some (left && right) &&
    progressSmokeBool (boolBinary "orBool" left right) = some (left || right)
#guard [false, true].all fun value =>
  progressSmokeBool (.cons (.lit (.bool value)) (.cons (.prim "notBool") .empty)) = some (!value)

/- `div` and `mod` against hand-computed Euclidean results (a = b*q + r,
   0 <= r < |b|), and a zero divisor is a primitive fault on either. -/
def progressSmokeInt (name : Prim) (left right : Int) : Option Int :=
  match run defaultGamma emptyDictionary defaultCosts 8
      { stack := [], program :=
          .cons (.lit (.int left)) (.cons (.lit (.int right)) (.cons (.prim name) .empty)) } with
  | .terminal { stack := [.literal (.int value)], program := .empty } _ _ => some value
  | _ => none

#guard progressSmokeInt "divInt" 7 2 = some 3
#guard progressSmokeInt "modInt" 7 2 = some 1
#guard progressSmokeInt "divInt" (-7) 2 = some (-4)
#guard progressSmokeInt "modInt" (-7) 2 = some 1
#guard progressSmokeInt "divInt" 7 (-2) = some (-3)
#guard progressSmokeInt "modInt" 7 (-2) = some 1
#guard progressSmokeInt "divInt" (-7) (-2) = some 4
#guard progressSmokeInt "modInt" (-7) (-2) = some 1
#guard progressSmokeInt "divInt" 6 3 = some 2
#guard progressSmokeInt "modInt" 6 3 = some 0
#guard progressSmokeInt "divInt" 7 0 = none
#guard progressSmokeInt "modInt" 7 0 = none
#guard progressSmokeInt "divInt" 0 0 = none

/- `set` against hand-written results: it replaces one element in place and
keeps the length; a negative index and one at or past the end fault. -/
def progressSmokeSet (values : List Int) (index value : Int) : Option (List Int) :=
  match run defaultGamma emptyDictionary defaultCosts 8
      { stack := [], program :=
          .cons (.lit (.intSeq values)) (.cons (.lit (.int index))
            (.cons (.lit (.int value)) (.cons (.prim "intSeqSet") .empty))) } with
  | .terminal { stack := [.literal (.intSeq result)], program := .empty } _ _ => some result
  | _ => none

#guard progressSmokeSet [4, 5, 6] 0 9 = some [9, 5, 6]
#guard progressSmokeSet [4, 5, 6] 2 (-1) = some [4, 5, -1]
#guard progressSmokeSet [4, 5, 6] 3 9 = none
#guard progressSmokeSet [4, 5, 6] (-1) 9 = none
#guard progressSmokeSet [] 0 9 = none
#guard match run defaultGamma emptyDictionary defaultCosts 8
    { stack := [], program :=
        .cons (.lit (.boolSeq [true, true])) (.cons (.lit (.int 1))
          (.cons (.lit (.bool false)) (.cons (.prim "boolSeqSet") .empty))) } with
  | .terminal { stack := [.literal (.boolSeq [true, false])], program := .empty } _ _ => true
  | _ => false

/- The fault is a stuck configuration at the primitive, not fuel running out. -/
#guard match run defaultGamma emptyDictionary defaultCosts 8
    { stack := [], program :=
        .cons (.lit (.int 7)) (.cons (.lit (.int 0)) (.cons (.prim "divInt") .empty)) } with
  | .stuck { stack := [.literal (.int 0), .literal (.int 7)], program := .cons (.prim "divInt") .empty } _ _ => true
  | _ => false

end Firth.Interpreter
