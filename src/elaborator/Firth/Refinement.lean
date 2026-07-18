import elaborator.Firth.StackEffect
import smt.Firth.SmtBoundary
import Lean.CoreM
import Lean.Util.CollectAxioms
import Std.Sync.Mutex

namespace Firth.Elaborator.Refinement

open Firth.Smt
open Firth.Elaborator.StackEffect

structure RefinementSet where
  conjuncts : List Predicate := []
  deriving Repr, BEq, DecidableEq

structure RefinedStack where
  erased : AStack
  refinements : RefinementSet
  deriving Repr, BEq

structure Spec where
  pre : RefinementSet
  post : RefinementSet
  totality : Option RefinementSet := none
  deriving Repr, BEq, DecidableEq

structure Contract where
  wordType : Scheme
  specification : Spec
  deriving Repr, BEq

inductive ObligationKind where
  | body
  | bodyTotality
  | erasedWordTypeEquality
  | totalityPromisePresence
  | preSubsumption
  | postSubsumption
  | totalitySubsumption
  deriving Repr, BEq, DecidableEq

def ObligationKind.canonical : ObligationKind → String
  | .body => "body"
  | .bodyTotality => "body-totality"
  | .erasedWordTypeEquality => "erased-word-type-equality"
  | .totalityPromisePresence => "totality-promise-presence"
  | .preSubsumption => "pre-subsumption"
  | .postSubsumption => "post-subsumption"
  | .totalitySubsumption => "totality-subsumption"

structure SourceLocation where
  path : String
  span : Span
  deriving Repr, BEq

/-!
Hashes in this context are supplied by the governed elaboration/build layer.
This module never substitutes a local weak digest for authoritative content
identity.
-/
structure ObligationContext where
  wordId : String
  bodyHash : String
  erasedWordTypeHash : String
  specHash : String
  calleeContractHashes : List String := []
  predicateDefinitionHashes : List String := []
  normaliserVersion : String
  vcGeneratorVersion : String
  leanToolchainHash : String
  proofModuleHash : String
  toolchainRevision : String
  source : SourceLocation
  expectedStack : RefinedStack
  actualStack : RefinedStack
  deriving Repr, BEq

structure Obligation where
  obligationId : String
  kind : ObligationKind
  formula : Formula
  context : ObligationContext
  deriving Repr, BEq

private inductive RefinementNode where
  | predicate (value : Predicate)
  | predicates (values : List Predicate)
  | predicateGroups (values : List (List Predicate))
  | intExpr (value : IntExpr)
  | intExprs (values : List IntExpr)

private def intKernelCost (value : Int) : Nat :=
  value.natAbs.log2 + 1

/- Traverse caller-supplied predicate roots incrementally.  In particular, do not first fold or
copy the complete top-level lists, because the budget is the resource boundary for those lists. -/
private def predicateGroupsWithinKernelBounds (groups : List (List Predicate)) : Bool :=
  let rec visit : Nat → Nat → Nat → List RefinementNode → Bool
    | _, _, _, [] => true
    | _, 0, _, .predicates _ :: _ => false
    | remaining, links + 1, stringBytes, .predicates [] :: rest =>
        visit remaining links stringBytes rest
    | remaining, links + 1, stringBytes, .predicates (value :: values) :: rest =>
        visit remaining links stringBytes (.predicate value :: .predicates values :: rest)
    | _, 0, _, .predicateGroups _ :: _ => false
    | remaining, links + 1, stringBytes, .predicateGroups [] :: rest =>
        visit remaining links stringBytes rest
    | remaining, links + 1, stringBytes, .predicateGroups (values :: groups) :: rest =>
        visit remaining links stringBytes (.predicates values :: .predicateGroups groups :: rest)
    | _, 0, _, .intExprs _ :: _ => false
    | remaining, links + 1, stringBytes, .intExprs [] :: rest =>
        visit remaining links stringBytes rest
    | remaining, links + 1, stringBytes, .intExprs (value :: values) :: rest =>
        visit remaining links stringBytes (.intExpr value :: .intExprs values :: rest)
    | 0, _, _, _ => false
    | remaining + 1, links, stringBytes, node :: rest =>
        match node with
        | .predicate predicate =>
            match predicate with
            | .truth | .falsity => visit remaining links stringBytes rest
            | .boolVariable name | .nonlinear name | .worldSensitive name =>
                let nextBytes := stringBytes + name.utf8ByteSize
                nextBytes <= 1048576 && visit remaining links nextBytes rest
            | .not body => visit remaining links stringBytes (.predicate body :: rest)
            | .and left right | .or left right =>
                visit remaining links stringBytes (.predicate left :: .predicate right :: rest)
            | .intEq left right | .intNe left right | .intLe left right | .intLt left right =>
                visit remaining links stringBytes (.intExpr left :: .intExpr right :: rest)
            | .named name version arguments =>
                let nextBytes := stringBytes + name.utf8ByteSize + version.utf8ByteSize
                nextBytes <= 1048576 &&
                  visit remaining links nextBytes (.intExprs arguments :: rest)
        | .intExpr expression =>
            match expression with
            | .literal value =>
                let nextBytes := stringBytes + intKernelCost value
                nextBytes <= 1048576 && visit remaining links nextBytes rest
            | .variable name =>
                let nextBytes := stringBytes + name.utf8ByteSize
                nextBytes <= 1048576 && visit remaining links nextBytes rest
            | .add left right | .sub left right =>
                visit remaining links stringBytes (.intExpr left :: .intExpr right :: rest)
            | .scale coefficient body =>
                let nextBytes := stringBytes + intKernelCost coefficient
                nextBytes <= 1048576 &&
                  visit remaining links nextBytes (.intExpr body :: rest)
        | .predicates _ | .predicateGroups _ | .intExprs _ => false
  visit 10000 10010 0 [.predicateGroups groups]

private def formulaWithinKernelBounds (formula : Formula) : Bool :=
  predicateGroupsWithinKernelBounds [formula.premises, formula.conclusions]

private def frame (value : String) : String := s!"{value.toUTF8.size}:{value}"

private def encodeStrings (values : List String) : String :=
  s!"{values.length}[{String.intercalate "" (values.map frame)}]"

private def obligationIdentity (kind : ObligationKind) (formula : Formula)
    (context : ObligationContext) : String :=
  "obligation(" ++ frame context.wordId ++ frame context.bodyHash ++
    frame context.erasedWordTypeHash ++ frame context.specHash ++
    frame (encodeStrings context.calleeContractHashes) ++
    frame (encodeStrings context.predicateDefinitionHashes) ++
    frame context.normaliserVersion ++ frame context.vcGeneratorVersion ++
    frame context.toolchainRevision ++
    frame kind.canonical ++ frame (canonicalFormula formula) ++ ")"

private def budgetObligationIdentity (kind : ObligationKind) (context : ObligationContext) : String :=
  "kernel-budget-exceeded(" ++ frame context.wordId ++ frame context.bodyHash ++
    frame context.erasedWordTypeHash ++ frame context.specHash ++ frame kind.canonical ++ ")"

private def makeBudgetExceededObligation (kind : ObligationKind)
    (context : ObligationContext) : Obligation :=
  { obligationId := budgetObligationIdentity kind context
    kind
    formula := { premises := [], conclusions := [.nonlinear "kernel-budget-exceeded"] }
    context }

def makeObligation (kind : ObligationKind) (premises conclusions : List Predicate)
    (context : ObligationContext) : Obligation :=
  let formula := { premises, conclusions }
  if formulaWithinKernelBounds formula then
    { obligationId := obligationIdentity kind formula context, kind, formula, context }
  else
    makeBudgetExceededObligation kind context

structure TotalityTypingPremises where
  premises : RefinementSet
  conclusion : RefinementSet
  deriving Repr, BEq

structure BodyTypingPremises where
  context : ObligationContext
  precondition : RefinementSet
  bodySemantics : RefinementSet
  declaredPostcondition : RefinementSet
  totality : Option TotalityTypingPremises := none
  deriving Repr, BEq

private def bodyTypingBudgetExceeded (typing : BodyTypingPremises) : Option ObligationKind :=
  if !predicateGroupsWithinKernelBounds
      [ typing.precondition.conjuncts
      , typing.bodySemantics.conjuncts
      , typing.declaredPostcondition.conjuncts ] then
    some .body
  else
    match typing.totality with
    | some totality =>
        if predicateGroupsWithinKernelBounds
            [totality.premises.conjuncts, totality.conclusion.conjuncts] then
          none
        else
          some .bodyTotality
    | none => none

def bodyObligations (typing : BodyTypingPremises) : List Obligation :=
  match bodyTypingBudgetExceeded typing with
  | some kind => [makeBudgetExceededObligation kind typing.context]
  | none =>
      let safety := makeObligation .body
        (typing.precondition.conjuncts ++ typing.bodySemantics.conjuncts)
        typing.declaredPostcondition.conjuncts typing.context
      match typing.totality with
      | some totality =>
          [safety, makeObligation .bodyTotality totality.premises.conjuncts
            totality.conclusion.conjuncts typing.context]
      | none => [safety]

structure SubsumptionTypingPremises where
  context : ObligationContext
  oldContract : Contract
  newContract : Contract
  deriving Repr, BEq

private def subsumptionBudgetExceeded
    (typing : SubsumptionTypingPremises) : Option ObligationKind :=
  let oldSpec := typing.oldContract.specification
  let newSpec := typing.newContract.specification
  if !predicateGroupsWithinKernelBounds [oldSpec.pre.conjuncts, newSpec.pre.conjuncts] then
    some .preSubsumption
  else if !predicateGroupsWithinKernelBounds
      [oldSpec.pre.conjuncts, newSpec.post.conjuncts, oldSpec.post.conjuncts] then
    some .postSubsumption
  else
    match oldSpec.totality, newSpec.totality with
    | some oldTotality, some newTotality =>
        if predicateGroupsWithinKernelBounds
            [oldSpec.pre.conjuncts, oldTotality.conjuncts, newTotality.conjuncts] then
          none
        else
          some .totalitySubsumption
    | _, _ => none

private def refinementSubsumptionObligations (typing : SubsumptionTypingPremises)
    (totalityPair : Option (RefinementSet × RefinementSet)) : List Obligation :=
  let oldSpec := typing.oldContract.specification
  let newSpec := typing.newContract.specification
  let pre := makeObligation .preSubsumption
    oldSpec.pre.conjuncts newSpec.pre.conjuncts typing.context
  let post := makeObligation .postSubsumption
    (oldSpec.pre.conjuncts ++ newSpec.post.conjuncts)
    oldSpec.post.conjuncts typing.context
  match totalityPair with
  | some (oldTotality, newTotality) =>
      [pre, post, makeObligation .totalitySubsumption
        (oldSpec.pre.conjuncts ++ oldTotality.conjuncts)
        newTotality.conjuncts typing.context]
  | none => [pre, post]

inductive SubsumptionError where
  | erasedWordTypeMismatch
  | totalityPromiseRemoved
  deriving Repr, BEq

def subsumptionObligations (typing : SubsumptionTypingPremises) :
    Except SubsumptionError (List Obligation) :=
  if let some kind := subsumptionBudgetExceeded typing then
    .ok [makeBudgetExceededObligation kind typing.context]
  else if typing.oldContract.wordType != typing.newContract.wordType then
    .error .erasedWordTypeMismatch
  else
    match typing.oldContract.specification.totality, typing.newContract.specification.totality with
    | some _, none => .error .totalityPromiseRemoved
    | some oldTotality, some newTotality =>
        .ok (refinementSubsumptionObligations typing (some (oldTotality, newTotality)))
    | _, _ => .ok (refinementSubsumptionObligations typing none)

private def findClosedFalse : List Predicate → Option Predicate
  | [] => none
  | predicate :: rest =>
      match evalPredicate {} predicate with
      | some false => some predicate
      | _ => findClosedFalse rest

private def closedConclusionsTrue : List Predicate → Bool
  | [] => true
  | predicate :: rest =>
      match evalPredicate {} predicate with
      | some true => closedConclusionsTrue rest
      | _ => false

def leanDecide (formula : Formula) : Bool :=
  match findClosedFalse formula.premises with
  | some _ => true
  | none => closedConclusionsTrue formula.conclusions

def Valid (formula : Formula) : Prop :=
  ∀ valuation,
    (∀ predicate, predicate ∈ formula.premises → evalPredicate valuation predicate = some true) →
      ∀ predicate, predicate ∈ formula.conclusions →
        evalPredicate valuation predicate = some true

theorem evalInt_stable (expression : IntExpr) (valuation : Valuation) (result : Int) :
    evalInt {} expression = some result → evalInt valuation expression = some result := by
  induction expression generalizing result with
  | literal value =>
      intro evaluated
      exact evaluated
  | «variable» name =>
      intro evaluated
      change none = some result at evaluated
      cases evaluated
  | add left right leftIH rightIH =>
      intro evaluated
      cases leftResult : evalInt {} left with
      | none =>
          rw [evalInt, leftResult] at evaluated
          cases evaluated
      | some leftValue =>
          cases rightResult : evalInt {} right with
          | none =>
              rw [evalInt, leftResult, rightResult] at evaluated
              cases evaluated
          | some rightValue =>
              have stableLeft := leftIH leftValue leftResult
              have stableRight := rightIH rightValue rightResult
              rw [evalInt, leftResult, rightResult] at evaluated
              rw [evalInt, stableLeft, stableRight]
              exact evaluated
  | sub left right leftIH rightIH =>
      intro evaluated
      cases leftResult : evalInt {} left with
      | none =>
          rw [evalInt, leftResult] at evaluated
          cases evaluated
      | some leftValue =>
          cases rightResult : evalInt {} right with
          | none =>
              rw [evalInt, leftResult, rightResult] at evaluated
              cases evaluated
          | some rightValue =>
              have stableLeft := leftIH leftValue leftResult
              have stableRight := rightIH rightValue rightResult
              rw [evalInt, leftResult, rightResult] at evaluated
              rw [evalInt, stableLeft, stableRight]
              exact evaluated
  | scale coefficient body bodyIH =>
      intro evaluated
      cases bodyResult : evalInt {} body with
      | none =>
          rw [evalInt, bodyResult] at evaluated
          cases evaluated
      | some bodyValue =>
          have stableBody := bodyIH bodyValue bodyResult
          rw [evalInt, bodyResult] at evaluated
          rw [evalInt, stableBody]
          exact evaluated

theorem evalPredicate_stable (predicate : Predicate) (valuation : Valuation) (result : Bool) :
    evalPredicate {} predicate = some result → evalPredicate valuation predicate = some result := by
  induction predicate generalizing result with
  | truth | falsity =>
      intro evaluated
      exact evaluated
  | boolVariable name =>
      intro evaluated
      change none = some result at evaluated
      cases evaluated
  | not body bodyIH =>
      intro evaluated
      cases bodyResult : evalPredicate {} body with
      | none =>
          rw [evalPredicate, bodyResult] at evaluated
          cases evaluated
      | some bodyValue =>
          have stableBody := bodyIH bodyValue bodyResult
          rw [evalPredicate, bodyResult] at evaluated
          rw [evalPredicate, stableBody]
          exact evaluated
  | and left right leftIH rightIH | or left right leftIH rightIH =>
      intro evaluated
      cases leftResult : evalPredicate {} left with
      | none =>
          rw [evalPredicate, leftResult] at evaluated
          cases evaluated
      | some leftValue =>
          cases rightResult : evalPredicate {} right with
          | none =>
              rw [evalPredicate, leftResult, rightResult] at evaluated
              cases evaluated
          | some rightValue =>
              have stableLeft := leftIH leftValue leftResult
              have stableRight := rightIH rightValue rightResult
              rw [evalPredicate, leftResult, rightResult] at evaluated
              rw [evalPredicate, stableLeft, stableRight]
              exact evaluated
  | intEq left right | intNe left right | intLe left right | intLt left right =>
      intro evaluated
      cases leftResult : evalInt {} left with
      | none =>
          rw [evalPredicate, leftResult] at evaluated
          cases evaluated
      | some leftValue =>
          cases rightResult : evalInt {} right with
          | none =>
              rw [evalPredicate, leftResult, rightResult] at evaluated
              cases evaluated
          | some rightValue =>
              have stableLeft := evalInt_stable left valuation leftValue leftResult
              have stableRight := evalInt_stable right valuation rightValue rightResult
              rw [evalPredicate, leftResult, rightResult] at evaluated
              rw [evalPredicate, stableLeft, stableRight]
              exact evaluated
  | named name version arguments | nonlinear description | worldSensitive description =>
      intro evaluated
      change none = some result at evaluated
      cases evaluated

private theorem findClosedFalse_sound : ∀ predicates candidate,
    findClosedFalse predicates = some candidate →
      candidate ∈ predicates ∧ evalPredicate {} candidate = some false := by
  intro predicates
  induction predicates with
  | nil =>
      intro candidate found
      cases found
  | cons head tail ih =>
      intro candidate found
      unfold findClosedFalse at found
      split at found <;> rename_i evaluated
      · cases found
        exact ⟨.head _, evaluated⟩
      · obtain ⟨member, result⟩ := ih candidate found
        exact ⟨.tail head member, result⟩

private theorem closedConclusionsTrue_sound : ∀ predicates,
    closedConclusionsTrue predicates = true →
      ∀ predicate, predicate ∈ predicates → evalPredicate {} predicate = some true := by
  intro predicates
  induction predicates with
  | nil =>
      intro _ predicate member
      cases member
  | cons head tail ih =>
      intro result predicate member
      unfold closedConclusionsTrue at result
      split at result <;> rename_i evaluated
      · cases member with
        | head => exact evaluated
        | tail _ later => exact ih result predicate later
      · cases result

theorem leanDecide_sound (formula : Formula) :
    leanDecide formula = true → Valid formula := by
  intro decided valuation premisesTrue
  unfold leanDecide at decided
  split at decided <;> rename_i found
  · rename_i candidate
    obtain ⟨member, evaluatedFalse⟩ :=
      findClosedFalse_sound formula.premises candidate found
    have evaluatedFalseAtValuation :=
      evalPredicate_stable candidate valuation false evaluatedFalse
    have evaluatedTrue := premisesTrue candidate member
    have impossible : false = true :=
      Option.some.inj (evaluatedFalseAtValuation.symm.trans evaluatedTrue)
    exact Bool.noConfusion impossible
  · intro predicate member
    have evaluated := closedConclusionsTrue_sound formula.conclusions decided predicate member
    exact evalPredicate_stable predicate valuation true evaluated

structure LeanProofTerm where
  formula : Formula
  deriving Repr, BEq

structure LeanProofRecord where
  obligationId : String
  theoremStatement : String
  predicateDefinitionHashes : List String
  proofModuleHash : String
  leanToolchainHash : String
  bodyHash : String
  erasedWordTypeHash : String
  specHash : String
  toolchainRevision : String
  source : SourceLocation
  proofTerm : LeanProofTerm
  deriving Repr, BEq

inductive LeanRecordRecheck where
  | accepted
  | metadataMismatch
  | toolchainMismatch
  | proofModuleMismatch
  | kernelRejected
  | kernelTimedOut
  | kernelUnavailable
  deriving Repr, BEq

inductive LeanEscalationReason where
  | directProcedureIncomplete
  | kernelBudgetExceeded
  | outsideSmtFragment (fragment : Fragment)
  | totalityIsLeanOnly
  | checkedSmtAdapterUnavailable
  | externalUnknown
  | externalTimeout (milliseconds : Nat)
  | externalResourceExhausted
  | externalMalformed
  | externalCrash
  | uncheckedUnsatRejected
  | invalidCountermodel
  | externalRequestIneligible
  deriving Repr, BEq

structure LeanProofObligation where
  obligationId : String
  theoremStatement : String
  formula : Formula
  context : ObligationContext
  reason : LeanEscalationReason
  deriving Repr, BEq

inductive SmtQueueStatus where
  | awaitingCheckedAdapter
  deriving Repr, BEq

structure SmtQueueEntry where
  obligation : Obligation
  canonicalRequest : String
  requirements : CheckedAdapterRequirements
  status : SmtQueueStatus := .awaitingCheckedAdapter
  deriving Repr, BEq

inductive ObligationStatus where
  | deferred
  | failed
  deriving Repr, BEq

structure DiagnosticLocation where
  path : String
  range : Span
  deriving Repr, BEq

structure OpaqueData where
  encoding : String := "opaque"
  value : List (String × String)
  deriving Repr, BEq

structure DiagnosticCause where
  kind : String := "refinement"
  data : OpaqueData
  deriving Repr, BEq

structure OpaqueStack where
  encoding : String := "opaque"
  value : RefinedStack
  deriving Repr, BEq

structure DiagnosticObligation where
  obligationId : String
  kind : ObligationKind
  status : ObligationStatus
  data : OpaqueData
  deriving Repr, BEq

structure DiagnosticEdit where
  location : DiagnosticLocation
  replacement : String
  deriving Repr, BEq

structure ProposedFix where
  fixId : String
  kind : String
  titleKey : String
  applicability : String
  edits : List DiagnosticEdit
  deriving Repr, BEq

structure RelatedDiagnostic where
  relation : String
  location : DiagnosticLocation
  payloadId : Option String := none
  deriving Repr, BEq

structure RefinementDiagnosticBody where
  code : String
  severity : String := "error"
  messageKey : String
  messageParams : List (String × String) := []
  location : DiagnosticLocation
  cause : DiagnosticCause
  expectedStack : OpaqueStack
  actualStack : OpaqueStack
  obligations : List DiagnosticObligation
  proposedFixes : List ProposedFix := []
  related : List RelatedDiagnostic := []
  groupId : String
  deriving Repr, BEq

structure RefinementDiagnostic where
  schemaVersion : String := "1.0"
  payloadKind : String := "diagnostic"
  payloadId : String
  requestId : String
  body : RefinementDiagnosticBody
  deriving Repr, BEq

private def diagnosticCode : ObligationStatus → String
  | .deferred => "firth.refinement.not-decided"
  | .failed => "firth.refinement.counterexample"

private def diagnosticKey : ObligationStatus → String
  | .deferred => "diagnostic.refinement_not_decided"
  | .failed => "diagnostic.refinement_counterexample"

private def makeDiagnostic (requestId : String) (obligation : Obligation)
    (status : ObligationStatus) (data : OpaqueData)
    (messageParams : List (String × String) := []) : RefinementDiagnostic :=
  let diagnosticObligation : DiagnosticObligation :=
    { obligationId := obligation.obligationId
      kind := obligation.kind
      status := status
      data := data }
  { payloadId := "diagnostic(" ++ frame obligation.obligationId ++ ")"
    requestId
    body :=
      { code := diagnosticCode status
        messageKey := diagnosticKey status
        messageParams
        location := { path := obligation.context.source.path, range := obligation.context.source.span }
        cause := { data }
        expectedStack := { value := obligation.context.expectedStack }
        actualStack := { value := obligation.context.actualStack }
        obligations := [diagnosticObligation]
        groupId := "refinement(" ++ frame obligation.context.wordId ++ ")" } }

private def reasonData (reason : String) : OpaqueData :=
  { value := [("reason", reason)] }

private def positionLess (left right : Position) : Bool :=
  left.line < right.line ||
    (left.line == right.line && (left.column < right.column ||
      (left.column == right.column && left.offset < right.offset)))

private def positionEqual (left right : Position) : Bool :=
  left.line == right.line && left.column == right.column && left.offset == right.offset

private def diagnosticLess (left right : RefinementDiagnostic) : Bool :=
  if left.body.location.path != right.body.location.path then
    left.body.location.path < right.body.location.path
  else if !positionEqual left.body.location.range.start right.body.location.range.start then
    positionLess left.body.location.range.start right.body.location.range.start
  else if !positionEqual left.body.location.range.stop right.body.location.range.stop then
    positionLess left.body.location.range.stop right.body.location.range.stop
  else if left.body.code != right.body.code then
    left.body.code < right.body.code
  else
    left.payloadId < right.payloadId

private def insertDiagnostic (diagnostic : RefinementDiagnostic) :
    List RefinementDiagnostic → List RefinementDiagnostic
  | [] => [diagnostic]
  | head :: tail =>
      if diagnosticLess diagnostic head then diagnostic :: head :: tail
      else head :: insertDiagnostic diagnostic tail

def sortDiagnostics (diagnostics : List RefinementDiagnostic) : List RefinementDiagnostic :=
  diagnostics.foldl (fun sorted diagnostic => insertDiagnostic diagnostic sorted) []

structure PipelineResult where
  leanRecords : List LeanProofRecord := []
  leanQueue : List LeanProofObligation := []
  smtQueue : List SmtQueueEntry := []
  diagnostics : List RefinementDiagnostic := []
  deriving Repr, BEq

private def theoremStatement (obligation : Obligation) : String :=
  "closed-refinement(" ++ frame (canonicalFormula obligation.formula) ++ ")"

private def expressionList (elementType : Lean.Expr) (values : List Lean.Expr) : Lean.Expr :=
  values.foldr
    (fun value rest =>
      Lean.mkApp3 (Lean.mkConst ``List.cons [Lean.Level.zero]) elementType value rest)
    (Lean.mkApp (Lean.mkConst ``List.nil [Lean.Level.zero]) elementType)

mutual
  private def intExprExpression : IntExpr → Lean.Expr
    | .literal value =>
        Lean.mkApp (Lean.mkConst ``Firth.Smt.IntExpr.literal) (Lean.mkIntLit value)
    | .variable name =>
        Lean.mkApp (Lean.mkConst ``Firth.Smt.IntExpr.variable) (Lean.mkStrLit name)
    | .add left right =>
        Lean.mkApp2 (Lean.mkConst ``Firth.Smt.IntExpr.add)
          (intExprExpression left) (intExprExpression right)
    | .sub left right =>
        Lean.mkApp2 (Lean.mkConst ``Firth.Smt.IntExpr.sub)
          (intExprExpression left) (intExprExpression right)
    | .scale coefficient body =>
        Lean.mkApp2 (Lean.mkConst ``Firth.Smt.IntExpr.scale)
          (Lean.mkIntLit coefficient) (intExprExpression body)

  private def predicateExpression : Predicate → Lean.Expr
    | .truth => Lean.mkConst ``Firth.Smt.Predicate.truth
    | .falsity => Lean.mkConst ``Firth.Smt.Predicate.falsity
    | .boolVariable name =>
        Lean.mkApp (Lean.mkConst ``Firth.Smt.Predicate.boolVariable) (Lean.mkStrLit name)
    | .not body =>
        Lean.mkApp (Lean.mkConst ``Firth.Smt.Predicate.not) (predicateExpression body)
    | .and left right =>
        Lean.mkApp2 (Lean.mkConst ``Firth.Smt.Predicate.and)
          (predicateExpression left) (predicateExpression right)
    | .or left right =>
        Lean.mkApp2 (Lean.mkConst ``Firth.Smt.Predicate.or)
          (predicateExpression left) (predicateExpression right)
    | .intEq left right =>
        Lean.mkApp2 (Lean.mkConst ``Firth.Smt.Predicate.intEq)
          (intExprExpression left) (intExprExpression right)
    | .intNe left right =>
        Lean.mkApp2 (Lean.mkConst ``Firth.Smt.Predicate.intNe)
          (intExprExpression left) (intExprExpression right)
    | .intLe left right =>
        Lean.mkApp2 (Lean.mkConst ``Firth.Smt.Predicate.intLe)
          (intExprExpression left) (intExprExpression right)
    | .intLt left right =>
        Lean.mkApp2 (Lean.mkConst ``Firth.Smt.Predicate.intLt)
          (intExprExpression left) (intExprExpression right)
    | .named name version arguments =>
        Lean.mkApp3 (Lean.mkConst ``Firth.Smt.Predicate.named)
          (Lean.mkStrLit name) (Lean.mkStrLit version)
          (expressionList (Lean.mkConst ``Firth.Smt.IntExpr)
            (arguments.map intExprExpression))
    | .nonlinear description =>
        Lean.mkApp (Lean.mkConst ``Firth.Smt.Predicate.nonlinear) (Lean.mkStrLit description)
    | .worldSensitive description =>
        Lean.mkApp (Lean.mkConst ``Firth.Smt.Predicate.worldSensitive) (Lean.mkStrLit description)
end

private def formulaExpression (formula : Formula) : Lean.Expr :=
  Lean.mkApp2 (Lean.mkConst ``Firth.Smt.Formula.mk)
    (expressionList (Lean.mkConst ``Firth.Smt.Predicate)
      (formula.premises.map predicateExpression))
    (expressionList (Lean.mkConst ``Firth.Smt.Predicate)
      (formula.conclusions.map predicateExpression))

private def leanRecord (obligation : Obligation) : LeanProofRecord :=
  { obligationId := obligation.obligationId
    theoremStatement := theoremStatement obligation
    predicateDefinitionHashes := obligation.context.predicateDefinitionHashes
    proofModuleHash := obligation.context.proofModuleHash
    leanToolchainHash := obligation.context.leanToolchainHash
    bodyHash := obligation.context.bodyHash
    erasedWordTypeHash := obligation.context.erasedWordTypeHash
    specHash := obligation.context.specHash
    toolchainRevision := obligation.context.toolchainRevision
    source := obligation.context.source
    proofTerm := { formula := obligation.formula } }

private def canonicalObligationIdentity (obligation : Obligation) : Bool :=
  obligation.obligationId == obligationIdentity obligation.kind obligation.formula obligation.context

private def isBudgetExceededObligation (obligation : Obligation) : Bool :=
  obligation.obligationId == budgetObligationIdentity obligation.kind obligation.context

private inductive BoundedProcessOutput where
  | completed (output : IO.Process.Output)
  | timedOut
  | outputLimitExceeded

private inductive BoundedText where
  | value (text : String)
  | limitExceeded
  | invalidUtf8

private partial def readBoundedText (handle : IO.FS.Handle) (limit : Nat) : IO BoundedText := do
  let rec read (bytes : ByteArray) : IO BoundedText := do
    let chunk ← handle.read 4096
    if chunk.isEmpty then
      match String.fromUTF8? bytes with
      | some text => pure (.value text)
      | none => pure .invalidUtf8
    else if bytes.size + chunk.size > limit then
      pure .limitExceeded
    else
      read (bytes ++ chunk)
  read ByteArray.empty

private def boundedProcessOutput (timeoutMilliseconds : Nat) (arguments : IO.Process.SpawnArgs)
    (outputLimit : Nat := 4096) : IO BoundedProcessOutput := do
  let child ← IO.Process.spawn
    { arguments with stdout := .piped, stderr := .piped, stdin := .null, setsid := true }
  let stdout ← IO.asTask (readBoundedText child.stdout outputLimit) Task.Priority.dedicated
  let stderr ← IO.asTask (readBoundedText child.stderr outputLimit) Task.Priority.dedicated
  let rec wait : Nat → IO (Option UInt32)
    | 0 => do
        try child.kill catch _ => pure ()
        try discard child.wait catch _ => pure ()
        pure none
    | remaining + 1 => do
        match ← child.tryWait with
        | some exitCode => pure (some exitCode)
        | none =>
            IO.sleep 25
            wait remaining
  match ← wait (timeoutMilliseconds / 25 + 1) with
  | none => pure .timedOut
  | some exitCode =>
      let stdout ← IO.ofExcept stdout.get
      let stderr ← IO.ofExcept stderr.get
      match stdout, stderr with
      | .value stdout, .value stderr =>
          pure (.completed { exitCode, stdout, stderr })
      | _, _ => pure .outputLimitExceeded

private def sha256Digest (output : IO.Process.Output) : Option String :=
  if output.exitCode != 0 then none
  else
    let digest := output.stdout.takeWhile (fun character => !character.isWhitespace) |>.copy
    if digest.isEmpty then none else some digest

private def pinnedLeanToolchain : String := "leanprover/lean4:v4.30.0"

private def pinnedLeanGithash : String := "d024af099ca4bf2c86f649261ebf59565dc8c622"

private def proofModuleManifestPath : IO (Option System.FilePath) := do
  let binDirectory ← IO.appDir
  let some buildDirectory := binDirectory.parent | pure none
  let some lakeDirectory := buildDirectory.parent | pure none
  let some projectRoot := lakeDirectory.parent | pure none
  pure (some (projectRoot / "src" / "elaborator" / "refinement-proof-module.sha256"))

private def governedProofModules : List (Lean.Name × String) :=
  [ (`elaborator.Firth.Refinement, "elaborator/Firth/Refinement.olean")
  , (`elaborator.Firth.StackEffect, "elaborator/Firth/StackEffect.olean")
  , (`elaborator.Firth.Erasure, "elaborator/Firth/Erasure.olean")
  , (`elaborator.Firth.Parser, "elaborator/Firth/Parser.olean")
  , (`smt.Firth.SmtBoundary, "smt/Firth/SmtBoundary.olean")
  , (`Firth.Interpreter, "Firth/Interpreter.olean") ]

private def governedProofModuleHashes : IO (Option (List String)) := do
  let some manifest ← proofModuleManifestPath | pure none
  if !(← manifest.pathExists) then pure none
  else
    let hashes := (← IO.FS.readFile manifest).splitOn "\n" |>.filter (fun line => !line.isEmpty)
    if hashes.length == governedProofModules.length &&
        hashes.all (fun digest => digest.startsWith "sha256:" && digest.length == 71) then
      pure (some hashes)
    else pure none

private def governedProofModuleHash : IO (Option String) := do
  let some hashes ← governedProofModuleHashes | pure none
  pure hashes.head?

private def sha256 (path : System.FilePath) : IO (Option String) := do
  let rec select : List (System.FilePath × Array String) →
      IO (Option (System.FilePath × Array String))
    | [] => pure none
    | candidate@(executable, _) :: rest => do
        if ← executable.pathExists then pure (some candidate) else select rest
  let some (executable, arguments) ← select
    [ (System.FilePath.mk "/usr/bin/shasum", #["-a", "256"])
    , (System.FilePath.mk "/usr/bin/sha256sum", #[])
    , (System.FilePath.mk "/bin/sha256sum", #[]) ] | pure none
  let some output ← (try
    pure (some (← boundedProcessOutput 5000
      { cmd := executable.toString, args := arguments.push path.toString }))
    catch _ => pure none) | pure none
  match output with
  | .completed processOutput => pure (sha256Digest processOutput)
  | .timedOut => pure none
  | .outputLimitExceeded => pure none

private def withAuthenticatedProofArtifacts
    (action : Lean.NameMap Lean.ImportArtifacts → IO α) : IO (Option α) := do
  let some expectedHashes ← governedProofModuleHashes | pure none
  let some leanPath ← IO.getEnv "LEAN_PATH" | pure none
  let searchPath := System.SearchPath.parse leanPath
  -- The authenticated project root must be first.  Accepting a later matching
  -- root would let an earlier root shadow any transitive project dependency.
  match searchPath with
  | [] => pure none
  | root :: _ =>
      try
        IO.FS.withTempDir fun authenticatedRoot => do
          let rec copyAndAuthenticate : List (Lean.Name × String) → List String → IO Bool
            | [], [] => pure true
            | (_, path) :: modules, expectedHash :: hashes => do
                let candidate := root / path
                if !(← candidate.pathExists) then pure false
                else
                  let destination := authenticatedRoot / path
                  let some destinationRoot := destination.parent | pure false
                  IO.FS.createDirAll destinationRoot
                  IO.FS.writeBinFile destination (← IO.FS.readBinFile candidate)
                  let some digest ← sha256 destination | pure false
                  if "sha256:" ++ digest == expectedHash then
                    copyAndAuthenticate modules hashes
                  else pure false
            | _, _ => pure false
          if ← copyAndAuthenticate governedProofModules expectedHashes then
            let artifacts := governedProofModules.foldl (fun artifacts module =>
              artifacts.insert module.1 (.ofArray #[authenticatedRoot / module.2])) {}
            some <$> action artifacts
          else pure none
      catch _ => pure none

def currentLeanToolchainHash : IO (Option String) := do
  -- The running kernel is the checker. Its compiled identity must match the accepted repository pin.
  if Lean.githash != pinnedLeanGithash then pure none
  else pure (some (pinnedLeanToolchain ++ "@" ++ Lean.githash))

def currentProofModuleHash : IO (Option String) := do
  let some _ ← withAuthenticatedProofArtifacts (fun _ => pure ()) | pure none
  governedProofModuleHash

private initialize kernelCheckMutex : Std.Mutex Unit ← Std.Mutex.new ()

private def kernelCheckProofTerm (targetFormula instantiatedFormula : Formula)
    (cancelToken : IO.CancelToken) : IO Bool := do
  kernelCheckMutex.atomically do
    let some accepted ← withAuthenticatedProofArtifacts fun artifacts => do
      let previousSearchPath ← Lean.searchPathRef.get
      let builtinSearchPath ← Lean.getBuiltinSearchPath (← Lean.findSysroot)
      try
        -- Project modules are supplied through authenticated artifacts.  The ambient search path
        -- is reduced to the pinned toolchain library for their Lean/Std dependencies.
        Lean.searchPathRef.set builtinSearchPath
        let options := Lean.maxHeartbeats.set {} 1000000
        let environment ← Lean.importModules
          #[{ module := `elaborator.Firth.Refinement }] options 0 (arts := artifacts)
        let coreContext : Lean.Core.Context :=
          { fileName := "<refinement-recheck>"
            fileMap := Lean.FileMap.ofString ""
            options }
        let coreState : Lean.Core.State := { env := environment }
        let collect : Lean.CoreM (Array Lean.Name) :=
          Lean.collectAxioms ``Firth.Elaborator.Refinement.leanDecide_sound
        let axioms ← collect.toIO' coreContext coreState
        if axioms != #[``propext] then pure false
        else
          -- Construct the recorded proof as a kernel expression, then require its inferred type to
          -- be the independently reconstructed target theorem when the declaration enters the
          -- environment.
          let targetType := Lean.mkApp (Lean.mkConst ``Firth.Elaborator.Refinement.Valid)
            (formulaExpression targetFormula)
          let proof := Lean.mkApp2
            (Lean.mkConst ``Firth.Elaborator.Refinement.leanDecide_sound)
            (formulaExpression instantiatedFormula) Lean.reflBoolTrue
          let declaration : Lean.Declaration := .thmDecl
            { name := `Firth.Elaborator.Refinement.RecordedProof.checked
              levelParams := []
              type := targetType
              value := proof }
          match environment.addDeclCore (Lean.Core.getMaxHeartbeats options).toUSize declaration
              (some cancelToken) with
          | .ok _ => pure true
          | .error _ => pure false
      finally
        Lean.searchPathRef.set previousSearchPath
      | throw (IO.userError "authenticated Lean proof module is unavailable")
    pure accepted

private inductive BoundedKernelCheck where
  | completed (accepted : Bool)
  | timedOut
  | unavailable

private def boundedKernelCheck (targetFormula instantiatedFormula : Formula) :
    IO BoundedKernelCheck := do
  let cancelToken ← IO.CancelToken.new
  let check ← IO.asTask
    (try pure (some (← kernelCheckProofTerm targetFormula instantiatedFormula cancelToken))
      catch _ => pure none)
    Task.Priority.dedicated
  let rec wait : Nat → IO (Option (Option Bool))
    | 0 => pure none
    | remaining + 1 => do
        if ← IO.hasFinished check then pure (some (← IO.ofExcept check.get))
        else
          IO.sleep 25
          wait remaining
  match ← wait 401 with
  | none => do
      cancelToken.set
      IO.cancel check
      -- Cancellation is cooperative.  Do not report the timeout while the task could still be
      -- importing modules or holding the import mutex; wait until all scoped cleanup has run.
      discard <| IO.ofExcept check.get
      pure .timedOut
  | some none => pure .unavailable
  | some (some accepted) => pure (.completed accepted)

private def recheckLeanRecord (obligation : Obligation) (record : LeanProofRecord) :
    IO LeanRecordRecheck := do
  if isBudgetExceededObligation obligation ||
      !formulaWithinKernelBounds obligation.formula ||
      !formulaWithinKernelBounds record.proofTerm.formula then
    pure .kernelRejected
  else
    let expected := leanRecord obligation
    let boundMetadata := { record with proofTerm := expected.proofTerm }
    if !canonicalObligationIdentity obligation || boundMetadata != expected then
      pure .metadataMismatch
    else
      let some leanToolchainHash ← currentLeanToolchainHash | pure .kernelUnavailable
      if record.leanToolchainHash != leanToolchainHash then
        pure .toolchainMismatch
      else
        let some proofModuleHash ← currentProofModuleHash | pure .kernelUnavailable
        if record.proofModuleHash != proofModuleHash then pure .proofModuleMismatch
        else
          let encodedTarget := canonicalFormula obligation.formula
          let encodedProof := canonicalFormula record.proofTerm.formula
          if encodedTarget.toUTF8.size + encodedProof.toUTF8.size > 1048576 then
            pure .kernelRejected
          else
            match ← boundedKernelCheck obligation.formula record.proofTerm.formula with
            | .unavailable => pure .kernelUnavailable
            | .timedOut => pure .kernelTimedOut
            | .completed false => pure .kernelRejected
            | .completed true =>
                if record.proofTerm == expected.proofTerm then pure .accepted
                else pure .metadataMismatch

private def obligationWithId (obligationId : String) :
    List Obligation → Option Obligation
  | [] => none
  | obligation :: rest =>
      if obligation.obligationId == obligationId then some obligation
      else obligationWithId obligationId rest

private def recheckGeneratedLeanRecord (obligations : List Obligation)
    (record : LeanProofRecord) : IO LeanRecordRecheck :=
  match obligationWithId record.obligationId obligations with
  | none => pure .metadataMismatch
  | some obligation => recheckLeanRecord obligation record

def recheckBodyLeanRecord (typing : BodyTypingPremises)
    (record : LeanProofRecord) : IO LeanRecordRecheck :=
  match bodyTypingBudgetExceeded typing with
  | some _ => pure .kernelRejected
  | none => recheckGeneratedLeanRecord (bodyObligations typing) record

def recheckContractLeanRecord (typing : SubsumptionTypingPremises)
    (record : LeanProofRecord) : IO LeanRecordRecheck :=
  match subsumptionBudgetExceeded typing with
  | some _ => pure .kernelRejected
  | none =>
      match subsumptionObligations typing with
      | .error _ => pure .metadataMismatch
      | .ok obligations => recheckGeneratedLeanRecord obligations record

private def isTotality : ObligationKind → Bool
  | .bodyTotality | .totalitySubsumption | .totalityPromisePresence => true
  | _ => false

private def isSmtEligibleKind : ObligationKind → Bool
  | .body | .preSubsumption | .postSubsumption => true
  | _ => false

def canonicalSmtRequest (obligation : Obligation) : String :=
  let context := obligation.context
  "smt-queue-v1(" ++ frame obligation.obligationId ++ frame obligation.kind.canonical ++
    frame (canonicalFormula obligation.formula) ++ frame context.wordId ++
    frame context.bodyHash ++ frame context.erasedWordTypeHash ++ frame context.specHash ++
    frame (encodeStrings context.calleeContractHashes) ++
    frame (encodeStrings context.predicateDefinitionHashes) ++
    frame context.normaliserVersion ++ frame context.vcGeneratorVersion ++
    frame context.leanToolchainHash ++ frame context.proofModuleHash ++
    frame context.toolchainRevision ++ ")"

private def escalationReason (obligation : Obligation) : LeanEscalationReason :=
  if isTotality obligation.kind then .totalityIsLeanOnly
  else if !isSmtEligibleKind obligation.kind then .directProcedureIncomplete
  else
    match classify obligation.formula with
    | .qfLia => .checkedSmtAdapterUnavailable
    | fragment => .outsideSmtFragment fragment

private def leanObligation (obligation : Obligation)
    (reason : LeanEscalationReason) : LeanProofObligation :=
  { obligationId := obligation.obligationId
    theoremStatement := theoremStatement obligation
    formula := obligation.formula
    context := obligation.context
    reason }

private def kernelBudgetResult (requestId : String) (obligation : Obligation) : PipelineResult :=
  { leanQueue := [{
      obligationId := obligation.obligationId
      theoremStatement := "kernel-budget-exceeded"
      formula := obligation.formula
      context := obligation.context
      reason := .kernelBudgetExceeded }]
    diagnostics := [makeDiagnostic requestId obligation .deferred
      (reasonData "kernel-budget-exceeded")] }

private def queueForSmt (obligation : Obligation) : Option SmtQueueEntry :=
  if !isSmtEligibleKind obligation.kind then none
  else if classify obligation.formula == .qfLia then
    some {
      obligation
      canonicalRequest := canonicalSmtRequest obligation
      requirements := checkedAdapterRequirements }
  else none

private def dischargeObligation (requestId : String) (obligation : Obligation) : PipelineResult :=
  if isBudgetExceededObligation obligation || !formulaWithinKernelBounds obligation.formula then
    kernelBudgetResult requestId
      (makeBudgetExceededObligation obligation.kind obligation.context)
  else if leanDecide obligation.formula then
    { leanRecords := [leanRecord obligation] }
  else
    let reason := escalationReason obligation
    { leanQueue := [leanObligation obligation reason]
      smtQueue := (queueForSmt obligation).toList
      diagnostics := [makeDiagnostic requestId obligation .deferred
        (reasonData (toString (repr reason)))] }

private def discharge (requestId : String) (obligations : List Obligation) : PipelineResult :=
  let accumulated := obligations.foldl (fun (result : PipelineResult) obligation =>
    let next := dischargeObligation requestId obligation
    { leanRecords := result.leanRecords ++ next.leanRecords
      leanQueue := result.leanQueue ++ next.leanQueue
      smtQueue := result.smtQueue ++ next.smtQueue
      diagnostics := result.diagnostics ++ next.diagnostics })
    { leanRecords := [], leanQueue := [], smtQueue := [], diagnostics := [] }
  { accumulated with diagnostics := sortDiagnostics accumulated.diagnostics }

def checkBodyRefinements (requestId : String) (typing : BodyTypingPremises) : PipelineResult :=
  discharge requestId (bodyObligations typing)

def checkContractSubsumption (requestId : String)
    (typing : SubsumptionTypingPremises) : PipelineResult :=
  match subsumptionObligations typing with
  | .ok obligations => discharge requestId obligations
  | .error error =>
      let mismatchKind := match error with
        | .erasedWordTypeMismatch => ObligationKind.erasedWordTypeEquality
        | .totalityPromiseRemoved => ObligationKind.totalityPromisePresence
      let mismatch := makeObligation mismatchKind [] [.falsity] typing.context
      let reason := match error with
        | .erasedWordTypeMismatch => "erased-word-type-mismatch"
        | .totalityPromiseRemoved => "totality-promise-removed"
      let code := match error with
        | .erasedWordTypeMismatch => "firth.refinement.erased-word-type-mismatch"
        | .totalityPromiseRemoved => "firth.refinement.totality-promise-removed"
      let messageKey := match error with
        | .erasedWordTypeMismatch => "diagnostic.refinement_erased_word_type_mismatch"
        | .totalityPromiseRemoved => "diagnostic.refinement_totality_promise_removed"
      let diagnostic := makeDiagnostic requestId mismatch .failed
        (reasonData reason)
      { diagnostics := [{ diagnostic with body :=
          { diagnostic.body with
            code
            messageKey } }] }

private def externalReason : ExternalOutcome → LeanEscalationReason
  | .unknown => .externalUnknown
  | .timeout milliseconds => .externalTimeout milliseconds
  | .resourceExhausted => .externalResourceExhausted
  | .malformed _ => .externalMalformed
  | .crashed _ => .externalCrash
  | .uncheckedUnsat _ => .uncheckedUnsatRejected
  | .sat _ => .invalidCountermodel

private def externalData : ExternalOutcome → OpaqueData
  | .unknown => reasonData "external-unknown"
  | .timeout milliseconds => reasonData s!"external-timeout:{milliseconds}"
  | .resourceExhausted => reasonData "external-resource-exhausted"
  | .malformed _ => reasonData "external-malformed"
  | .crashed _ => reasonData "external-crash"
  | .uncheckedUnsat _ => reasonData "unchecked-unsat-rejected"
  | .sat _ => reasonData "invalid-countermodel"

private def pairLess (left right : String × String) : Bool :=
  left.1 < right.1 || (left.1 == right.1 && left.2 < right.2)

private def insertPair (entry : String × String) : List (String × String) → List (String × String)
  | [] => [entry]
  | head :: tail => if pairLess entry head then entry :: head :: tail
    else head :: insertPair entry tail

private def sortPairs (entries : List (String × String)) : List (String × String) :=
  entries.foldl (fun sorted entry => insertPair entry sorted) []

def renderCountermodel (model : Valuation) : String :=
  let integers := model.integers.map fun entry => ("int:" ++ entry.1, toString entry.2)
  let booleans := model.booleans.map fun entry => ("bool:" ++ entry.1, toString entry.2)
  let rendered := sortPairs (integers ++ booleans) |>.map fun entry =>
    frame entry.1 ++ frame entry.2
  encodeStrings rendered

def validSmtQueueEntry (entry : SmtQueueEntry) : Bool :=
  formulaWithinKernelBounds entry.obligation.formula &&
    isSmtEligibleKind entry.obligation.kind &&
    classify entry.obligation.formula == .qfLia &&
    entry.obligation.obligationId == obligationIdentity entry.obligation.kind
      entry.obligation.formula entry.obligation.context &&
    entry.canonicalRequest == canonicalSmtRequest entry.obligation &&
    entry.requirements == checkedAdapterRequirements

def recordExternalOutcome (requestId : String) (entry : SmtQueueEntry)
    (outcome : ExternalOutcome) : PipelineResult :=
  let obligation := entry.obligation
  if !formulaWithinKernelBounds obligation.formula then
    kernelBudgetResult requestId
      (makeBudgetExceededObligation obligation.kind obligation.context)
  else if !validSmtQueueEntry entry then
    { leanQueue := [leanObligation obligation .externalRequestIneligible]
      diagnostics := [makeDiagnostic requestId obligation .deferred
        (reasonData "external-request-ineligible")] }
  else
    match outcome with
    | .sat model =>
        if validatesCounterexample obligation.formula model then
          let rendered := renderCountermodel model
          { diagnostics := [makeDiagnostic requestId obligation .failed
              { value := [("backend", "smt"), ("result", "sat"), ("model", rendered)] }
              [("counterexample", rendered)]] }
        else
          { leanQueue := [leanObligation obligation .invalidCountermodel]
            diagnostics := [makeDiagnostic requestId obligation .deferred
              (reasonData "invalid-countermodel")] }
    | outcome =>
        let reason := externalReason outcome
        { leanQueue := [leanObligation obligation reason]
          diagnostics := [makeDiagnostic requestId obligation .deferred (externalData outcome)] }

end Firth.Elaborator.Refinement
