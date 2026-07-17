import Firth.KernelMetatheory

namespace Firth.Interpreter

/-! Progress for the frozen kernel transition system.

The executable `Gamma` type is intentionally permissive, so progress carries
the specification's literal-signature well-formedness condition explicitly.
Likewise, primitive totality is a premise because `PrimitiveSpec.delta` is
represented as an `Option` in the unchecked interpreter.
-/

def LiteralTypingSound (gamma : Gamma) : Prop :=
  ∀ literal base, gamma.literalType literal = some base →
    match literal, base with
    | .nat _, .nat => True
    | .bool _, .bool => True
    | .unit, .unit => True
    | _, _ => False

def PrimitivesTotal (gamma : Gamma) (dictionary : Dictionary) : Prop :=
  ∀ name specification stack,
    gamma.primitive name = some specification →
    StackTyping gamma dictionary stack specification.input →
    ∃ result, specification.delta stack = some result

def PrimitivesWellFormed (gamma : Gamma) (dictionary : Dictionary) : Prop :=
  PrimitivesPreserve gamma dictionary ∧ PrimitivesTotal gamma dictionary

theorem defaultGamma_literalTypingSound : LiteralTypingSound defaultGamma := by
  intro literal base h
  cases literal <;> simp [defaultGamma] at h ⊢ <;> subst base <;> trivial

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
      ∃ next, HasSuccessor gamma dictionary costs config next := by
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
                refine ⟨{ stack := .literal literal :: stack, program := rest }, ?_⟩
                exact ⟨costs.atom (.lit literal), by simp [step, h]⟩
        | push value =>
            cases headTyping with
            | push h =>
                refine ⟨{ stack := value :: stack, program := rest }, ?_⟩
                exact ⟨0, by simp [step]⟩
        | quotation body =>
            cases headTyping with
            | quotation h =>
                let next : Config :=
                  { stack := (Value.quotation body (programUsage body)) :: stack,
                    program := rest }
                refine ⟨next, ?_⟩
                exact ⟨costs.atom (.quotation body), by simp [next, step]⟩
        | dup =>
            cases headTyping with
            | dup h =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨value, tail, rfl, valueTyping, tailTyping⟩
                refine ⟨{ stack := value :: value :: tail, program := rest }, ?_⟩
                exact ⟨costs.atom .dup, by simp [step]⟩
        | drop =>
            cases headTyping with
            | drop h =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨value, tail, rfl, valueTyping, tailTyping⟩
                refine ⟨{ stack := tail, program := rest }, ?_⟩
                exact ⟨costs.atom .drop, by simp [step]⟩
        | swap =>
            cases headTyping with
            | swap =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨second, tail₁, rfl, secondTyping, tailTyping⟩
                rcases stackTyping_snoc_inv tailTyping with
                  ⟨first, tail, rfl, firstTyping, tailTyping⟩
                refine ⟨{ stack := first :: second :: tail, program := rest }, ?_⟩
                exact ⟨costs.atom .swap, by simp [step]⟩
        | call =>
            cases headTyping with
            | call =>
                rcases stackTyping_snoc_inv stackTyping with
                  ⟨quotation, tail, rfl, quotationTyping, tailTyping⟩
                rcases valueTyping_quotation_unpack quotationTyping with
                  ⟨body, rfl, usageEq, bodyTyping⟩
                refine ⟨{ stack := tail, program := body.append rest }, ?_⟩
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
                refine ⟨next, ?_⟩
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
                refine ⟨next, ?_⟩
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
                refine ⟨next, ?_⟩
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
                        refine ⟨{ stack := tail, program := chosen.append rest }, ?_⟩
                        exact ⟨costs.atom .ifThenElse, by simp [step, chosen]⟩
                  | nat value =>
                    cases conditionTyping with
                    | literal conditionType =>
                      exact False.elim (by
                        have h := literalTypingSound (.nat value) .bool conditionType
                        simp at h)
                  | unit =>
                    cases conditionTyping with
                    | literal conditionType =>
                      exact False.elim (by
                        have h := literalTypingSound .unit .bool conditionType
                        simp at h)
        | word name =>
            cases headTyping with
            | word h =>
                rcases h with ⟨entry, entryEq, entryInput, entryOutput⟩
                refine ⟨{ stack := stack, program := entry.body.append rest }, ?_⟩
                exact ⟨costs.unfold, by simp [step, entryEq]⟩
        | prim name =>
            cases headTyping with
            | prim h =>
                rcases primitivesWellFormed.2 name _ stack h stackTyping with ⟨result, deltaEq⟩
                refine ⟨{ stack := result, program := rest }, ?_⟩
                exact ⟨costs.primitive name, by simp [step, h, deltaEq]⟩

/- These guards execute representative well-typed transition shapes while
   compiling the module, keeping progress smoke coverage next to the proof. -/
def progressSmokeLiteral : Bool :=
  match step defaultGamma emptyDictionary defaultCosts
      { stack := [], program := .cons (.lit (.nat 7)) .empty } with
  | .stepped { stack := [.literal (.nat 7)], program := .empty } 1 => true
  | _ => false

#guard progressSmokeLiteral = true

def progressSmokeQuotationCall : Bool :=
  match run defaultGamma emptyDictionary defaultCosts 8
      { stack := [], program :=
          .cons (.quotation (.cons (.lit (.nat 9)) .empty))
            (.cons .call .empty) } with
  | .terminal { stack := [.literal (.nat 9)], program := .empty } _ _ => true
  | _ => false

#guard progressSmokeQuotationCall = true

end Firth.Interpreter
