import elaborator.Firth.StackEffect
import smt.Firth.SmtBoundary

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

def makeObligation (kind : ObligationKind) (premises conclusions : List Predicate)
    (context : ObligationContext) : Obligation :=
  let formula := { premises, conclusions }
  { obligationId := obligationIdentity kind formula context, kind, formula, context }

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

def bodyObligations (typing : BodyTypingPremises) : List Obligation :=
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
  if typing.oldContract.wordType != typing.newContract.wordType then
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
  | kernelUnavailable
  deriving Repr, BEq

inductive LeanEscalationReason where
  | directProcedureIncomplete
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

private def leanStringLiteral (value : String) : String :=
  toString (repr value)

private def leanList (render : α → String) (values : List α) : String :=
  "[" ++ String.intercalate ", " (values.map render) ++ "]"

mutual
  private def leanIntExpr : IntExpr → String
    | .literal value => s!"Firth.Smt.IntExpr.literal ({value})"
    | .variable name => s!"Firth.Smt.IntExpr.variable {leanStringLiteral name}"
    | .add left right =>
        s!"Firth.Smt.IntExpr.add ({leanIntExpr left}) ({leanIntExpr right})"
    | .sub left right =>
        s!"Firth.Smt.IntExpr.sub ({leanIntExpr left}) ({leanIntExpr right})"
    | .scale coefficient body =>
        s!"Firth.Smt.IntExpr.scale ({coefficient}) ({leanIntExpr body})"

  private def leanPredicate : Predicate → String
    | .truth => "Firth.Smt.Predicate.truth"
    | .falsity => "Firth.Smt.Predicate.falsity"
    | .boolVariable name =>
        s!"Firth.Smt.Predicate.boolVariable {leanStringLiteral name}"
    | .not body => s!"Firth.Smt.Predicate.not ({leanPredicate body})"
    | .and left right =>
        s!"Firth.Smt.Predicate.and ({leanPredicate left}) ({leanPredicate right})"
    | .or left right =>
        s!"Firth.Smt.Predicate.or ({leanPredicate left}) ({leanPredicate right})"
    | .intEq left right =>
        s!"Firth.Smt.Predicate.intEq ({leanIntExpr left}) ({leanIntExpr right})"
    | .intNe left right =>
        s!"Firth.Smt.Predicate.intNe ({leanIntExpr left}) ({leanIntExpr right})"
    | .intLe left right =>
        s!"Firth.Smt.Predicate.intLe ({leanIntExpr left}) ({leanIntExpr right})"
    | .intLt left right =>
        s!"Firth.Smt.Predicate.intLt ({leanIntExpr left}) ({leanIntExpr right})"
    | .named name version arguments =>
        s!"Firth.Smt.Predicate.named {leanStringLiteral name} {leanStringLiteral version} " ++
          leanList (fun argument => s!"({leanIntExpr argument})") arguments
    | .nonlinear description =>
        s!"Firth.Smt.Predicate.nonlinear {leanStringLiteral description}"
    | .worldSensitive description =>
        s!"Firth.Smt.Predicate.worldSensitive {leanStringLiteral description}"
end

private def leanFormula (formula : Formula) : String :=
  "{ premises := " ++ leanList (fun predicate => s!"({leanPredicate predicate})")
    formula.premises ++ ", conclusions := " ++
    leanList (fun predicate => s!"({leanPredicate predicate})") formula.conclusions ++ " }"

private def leanProofModule (obligation : Obligation) (proofTerm : LeanProofTerm) : String :=
  "import elaborator.Firth.Refinement\n\n" ++
    "namespace Firth.Elaborator.Refinement.RecordedProof\n\n" ++
    "private def targetFormula : Firth.Smt.Formula :=\n  " ++
      leanFormula obligation.formula ++ "\n\n" ++
    "private def instantiatedFormula : Firth.Smt.Formula :=\n  " ++
      leanFormula proofTerm.formula ++ "\n\n" ++
    "theorem checked : Firth.Elaborator.Refinement.Valid targetFormula := by\n" ++
    "  exact Firth.Elaborator.Refinement.leanDecide_sound instantiatedFormula (by rfl)\n\n" ++
    "#print axioms checked\n\n" ++
    "end Firth.Elaborator.Refinement.RecordedProof\n"

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

private def elanLeanExecutable : IO (Option System.FilePath) := do
  let root ← match ← IO.getEnv "ELAN_HOME" with
    | some path => pure (some (System.FilePath.mk path))
    | none =>
        match ← IO.getEnv "HOME" with
        | some home => pure (some (System.FilePath.mk home / ".elan"))
        | none => pure none
  let some root := root | pure none
  let name := if System.Platform.isWindows then "lean.exe" else "lean"
  let executable := root / "bin" / name
  if ← executable.pathExists then pure (some executable) else pure none

private def refinementProofModulePath : IO (Option System.FilePath) := do
  let some leanPath ← IO.getEnv "LEAN_PATH" | pure none
  let rec find : System.SearchPath → IO (Option System.FilePath)
    | [] => pure none
    | root :: rest => do
        let candidate := root / "elaborator" / "Firth" / "Refinement.olean"
        if ← candidate.pathExists then pure (some candidate) else find rest
  find (System.SearchPath.parse leanPath)

private def sha256With (commands : List (System.FilePath × Array String))
    (path : System.FilePath) : IO (Option String) := do
  match commands with
  | [] => pure none
  | (executable, arguments) :: rest =>
      if !(← executable.pathExists) then sha256With rest path
      else
        let output ← try
          pure (some (← IO.Process.output
            { cmd := executable.toString, args := arguments.push path.toString }))
        catch _ => pure none
        match output with
        | none => sha256With rest path
        | some output =>
            if output.exitCode != 0 then sha256With rest path
            else
              let digest :=
                output.stdout.takeWhile (fun character => !character.isWhitespace) |>.copy
              if digest.isEmpty then sha256With rest path else pure (some digest)

private def sha256 (path : System.FilePath) : IO (Option String) :=
  sha256With
    [ (System.FilePath.mk "/usr/bin/shasum", #["-a", "256"])
    , (System.FilePath.mk "/usr/bin/sha256sum", #[])
    , (System.FilePath.mk "/bin/sha256sum", #[]) ] path

def recheckLeanRecord (obligation : Obligation) (record : LeanProofRecord) :
    IO LeanRecordRecheck := do
  let expected := leanRecord obligation
  let boundMetadata := { record with proofTerm := expected.proofTerm }
  if !canonicalObligationIdentity obligation || boundMetadata != expected then
    pure .metadataMismatch
  else
    let some leanExecutable ← elanLeanExecutable | pure .kernelUnavailable
    let some toolchain ← (try
      pure (some (← IO.Process.output
        { cmd := leanExecutable.toString, args := #["--githash"] }))
    catch _ => pure none) | pure .kernelUnavailable
    if toolchain.exitCode != 0 || toolchain.stdout.trimAscii.copy != Lean.githash ||
        record.leanToolchainHash != Lean.githash then
      pure .toolchainMismatch
    else
      let some modulePath ← refinementProofModulePath | pure .kernelUnavailable
      let some moduleDigest ← sha256 modulePath | pure .kernelUnavailable
      if record.proofModuleHash != "sha256:" ++ moduleDigest then
        pure .proofModuleMismatch
      else
        let source := leanProofModule obligation record.proofTerm
        let checked ← try
          let output ← IO.Process.output
            { cmd := leanExecutable.toString
              args := #["--stdin", "-t", "0", "-T", "1000000", "-M", "1024"] }
            (some source)
          let axiomReport :=
            "'Firth.Elaborator.Refinement.RecordedProof.checked' depends on axioms: [propext]"
          pure (some (output.exitCode == 0 &&
            (output.stdout ++ output.stderr).contains axiomReport))
        catch _ => pure none
        match checked with
        | none => pure .kernelUnavailable
        | some false => pure .kernelRejected
        | some true =>
            if record.proofTerm == expected.proofTerm then pure .accepted
            else pure .metadataMismatch

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

private def queueForSmt (obligation : Obligation) : Option SmtQueueEntry :=
  if !isSmtEligibleKind obligation.kind then none
  else if classify obligation.formula == .qfLia then
    some {
      obligation
      canonicalRequest := canonicalSmtRequest obligation
      requirements := checkedAdapterRequirements }
  else none

def dischargeObligation (requestId : String) (obligation : Obligation) : PipelineResult :=
  if leanDecide obligation.formula then
    { leanRecords := [leanRecord obligation] }
  else
    let reason := escalationReason obligation
    { leanQueue := [leanObligation obligation reason]
      smtQueue := (queueForSmt obligation).toList
      diagnostics := [makeDiagnostic requestId obligation .deferred
        (reasonData (toString (repr reason)))] }

def discharge (requestId : String) (obligations : List Obligation) : PipelineResult :=
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
  isSmtEligibleKind entry.obligation.kind &&
    classify entry.obligation.formula == .qfLia &&
    entry.obligation.obligationId == obligationIdentity entry.obligation.kind
      entry.obligation.formula entry.obligation.context &&
    entry.canonicalRequest == canonicalSmtRequest entry.obligation &&
    entry.requirements == checkedAdapterRequirements

def recordExternalOutcome (requestId : String) (entry : SmtQueueEntry)
    (outcome : ExternalOutcome) : PipelineResult :=
  let obligation := entry.obligation
  if !validSmtQueueEntry entry then
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
