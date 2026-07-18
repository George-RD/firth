import elaborator.Firth.Refinement

set_option maxRecDepth 2048

open Firth.Elaborator
open Firth.Elaborator.StackEffect
open Firth.Elaborator.Refinement
open Firth.Smt

#print axioms Firth.Elaborator.Refinement.leanDecide_sound
#print axioms Firth.Elaborator.Refinement.evalInt_stable
#print axioms Firth.Elaborator.Refinement.evalPredicate_stable

private def fail (message : String) : IO α := throw <| IO.userError message

private def expectTrue (actual : Bool) (message : String) : IO Unit :=
  if actual then pure () else fail message

private def expectEq [BEq α] [Repr α] (actual expected : α) (message : String) : IO Unit :=
  if actual == expected then pure ()
  else fail s!"{message}\nactual: {repr actual}\nexpected: {repr expected}"

private def expectAt : List α → Nat → String → IO α
  | [], _, message => fail s!"{message}: list entry is absent"
  | value :: _, 0, _ => pure value
  | _ :: rest, index + 1, message => expectAt rest index message

private def expectOk [Repr ε] : Except ε α → String → IO α
  | .ok value, _ => pure value
  | .error error, message => fail s!"{message}: unexpected error {repr error}"

private def position (offset : Nat) : Position :=
  { offset, line := 1, column := offset + 1 }

private def span (start stop : Nat) : Span :=
  { start := position start, stop := position stop }

private def integerStack (refinements : List Predicate) : RefinedStack :=
  { erased := .snoc (.row (.rigid "ρ")) (.base "Int" .many)
    refinements := { conjuncts := refinements } }

private def scheme : Scheme :=
  { rowVariables := ["ρ"]
    input := .snoc (.row (.rigid "ρ")) (.base "Int" .many)
    output := .snoc (.row (.rigid "ρ")) (.base "Int" .many) }

private def context (leanToolchainHash proofModuleHash : String)
    (wordId : String := "math.inc") (bodyHash : String := "sha256:body-a")
    (specHash : String := "sha256:spec-a") (path : String := "inc.firth")
    (start : Nat := 10) : ObligationContext :=
  { wordId
    bodyHash
    erasedWordTypeHash := "sha256:word-type-a"
    specHash
    calleeContractHashes := ["sha256:callee-a"]
    predicateDefinitionHashes := ["sha256:predicate-a"]
    normaliserVersion := "normaliser-v1"
    vcGeneratorVersion := "vc-v1"
    leanToolchainHash
    proofModuleHash
    toolchainRevision := "firth-a"
    source := { path, span := span start (start + 4) }
    expectedStack := integerStack [.intLt (.literal 0) (.variable "y")]
    actualStack := integerStack [.intEq (.variable "y")
      (.add (.variable "x") (.literal 1))] }

private def bodyTyping (ctx : ObligationContext) (pre semantics post : List Predicate) :
    BodyTypingPremises :=
  { context := ctx
    precondition := { conjuncts := pre }
    bodySemantics := { conjuncts := semantics }
    declaredPostcondition := { conjuncts := post } }

private def oneBody (ctx : ObligationContext) (pre semantics post : List Predicate) : Obligation :=
  match bodyObligations (bodyTyping ctx pre semantics post) with
  | [obligation] => obligation
  | _ => makeObligation .body [] [] ctx

private def expectOneLeanQueue (result : PipelineResult) (message : String) : IO LeanProofObligation :=
  match result.leanQueue with
  | [obligation] => pure obligation
  | queue => fail s!"{message}: expected one Lean obligation, got {repr queue}"

private def expectOneDiagnostic (result : PipelineResult) (message : String) :
    IO RefinementDiagnostic :=
  match result.diagnostics with
  | [diagnostic] => pure diagnostic
  | diagnostics => fail s!"{message}: expected one diagnostic, got {repr diagnostics}"

private def diagnosticVariant (diagnostic : RefinementDiagnostic) (payloadId code path : String)
    (range : Span) : RefinementDiagnostic :=
  { schemaVersion := diagnostic.schemaVersion
    payloadKind := diagnostic.payloadKind
    payloadId
    requestId := diagnostic.requestId
    body :=
      { code
        severity := diagnostic.body.severity
        messageKey := diagnostic.body.messageKey
        messageParams := diagnostic.body.messageParams
        location := { path, range }
        cause := diagnostic.body.cause
        expectedStack := diagnostic.body.expectedStack
        actualStack := diagnostic.body.actualStack
        obligations := diagnostic.body.obligations
        proposedFixes := diagnostic.body.proposedFixes
        related := diagnostic.body.related
        groupId := diagnostic.body.groupId } }

private def expectExternalDeferred (obligation : Obligation) (outcome : ExternalOutcome)
    (reason : LeanEscalationReason) (data : String) : IO Unit := do
  let pending := discharge "request-a" [obligation]
  let entry ← expectAt pending.smtQueue 0 data
  let result := recordExternalOutcome "request-a" entry outcome
  let queued ← expectOneLeanQueue result data
  expectEq queued.reason reason s!"{data}: Lean escalation reason"
  expectEq result.leanRecords.length 0 s!"{data}: no proof record"
  let diagnostic ← expectOneDiagnostic result data
  let entry ← expectAt diagnostic.body.obligations 0 data
  expectEq entry.status .deferred s!"{data}: deferred status"
  expectEq entry.data.value [("reason", data)] s!"{data}: diagnostic data"

def main : IO Unit := do
  let some leanToolchainHash ← currentLeanToolchainHash |
    fail "pinned Lean executable hash is unavailable"
  let some proofModuleHash ← currentProofModuleHash |
    fail "refinement proof-module hash is unavailable"
  let ctx := context leanToolchainHash proofModuleHash
  let xPositive := Predicate.intLt (.literal 0) (.variable "x")
  let successor := Predicate.intEq (.variable "y") (.add (.variable "x") (.literal 1))
  let yPositive := Predicate.intLt (.literal 0) (.variable "y")

  let generated := oneBody ctx [xPositive] [successor] [yPositive]
  expectEq generated.formula.premises [xPositive, successor]
    "body VC is Pre and Sem implies Post"
  expectEq generated.formula.conclusions [yPositive] "body VC conclusion"

  let oldSpec : Spec :=
    { pre := { conjuncts := [xPositive] }
      post := { conjuncts := [yPositive] }
      totality := some { conjuncts := [.boolVariable "old-total"] } }
  let newSpec : Spec :=
    { pre := { conjuncts := [.intLe (.literal 0) (.variable "x")] }
      post := { conjuncts := [successor] }
      totality := some { conjuncts := [.boolVariable "new-total"] } }
  let oldContract : Contract := { wordType := scheme, specification := oldSpec }
  let newContract : Contract := { wordType := scheme, specification := newSpec }
  let substitutions ← expectOk
    (subsumptionObligations { context := ctx, oldContract, newContract }) "subsumption obligations"
  expectEq substitutions.length 3 "subsumption generates pre, post, and totality VCs"
  let preSubsumption ← expectAt substitutions 0 "precondition VC"
  let postSubsumption ← expectAt substitutions 1 "postcondition VC"
  let totalitySubsumption ← expectAt substitutions 2 "totality VC"
  expectEq preSubsumption.formula
    { premises := oldSpec.pre.conjuncts, conclusions := newSpec.pre.conjuncts }
    "precondition implication direction"
  expectEq postSubsumption.formula
    { premises := oldSpec.pre.conjuncts ++ newSpec.post.conjuncts,
      conclusions := oldSpec.post.conjuncts }
    "postcondition implication direction"
  expectEq totalitySubsumption.formula
    { premises := oldSpec.pre.conjuncts ++ [.boolVariable "old-total"],
      conclusions := [.boolVariable "new-total"] }
    "totality implication direction"
  let differentScheme : Scheme :=
    { scheme with output := .snoc (.row (.rigid "ρ")) (.base "Bool" .many) }
  let mismatch := checkContractSubsumption "request-a"
    { context := ctx
      oldContract
      newContract := { newContract with wordType := differentScheme } }
  expectEq mismatch.leanRecords.length 0 "word-type mismatch has no proof record"
  expectEq mismatch.leanQueue.length 0 "word-type mismatch is rejected before refinements"
  let mismatchDiagnostic ← expectOneDiagnostic mismatch "word-type mismatch"
  expectEq mismatchDiagnostic.body.obligations.length 1 "word-type mismatch has an obligation entry"
  let mismatchObligation ← expectAt mismatchDiagnostic.body.obligations 0 "word-type mismatch"
  expectEq mismatchObligation.kind .erasedWordTypeEquality
    "replacement enforces exact erased WordType equality"
  let newWithoutTotality : Contract :=
    { newContract with specification := { newSpec with totality := none } }
  let removedTotality := checkContractSubsumption "request-a"
    { context := ctx, oldContract, newContract := newWithoutTotality }
  expectEq removedTotality.leanRecords.length 0 "removed totality promise has no proof record"
  let removedDiagnostic ← expectOneDiagnostic removedTotality "removed totality promise"
  expectEq removedDiagnostic.body.code "firth.refinement.totality-promise-removed"
    "removing an old totality promise is explicitly rejected"
  let removedObligation ← expectAt removedDiagnostic.body.obligations 0 "removed totality promise"
  expectEq removedObligation.kind .totalityPromisePresence
    "totality presence rejection is not encoded as an alternate VC"

  let closedSuccess := oneBody ctx [] [] [.intLt (.literal 0) (.literal 1)]
  let closedResult := discharge "request-a" [closedSuccess]
  expectEq closedResult.leanRecords.length 1 "closed true refinement discharges in Lean"
  expectEq closedResult.leanQueue.length 0 "Lean success leaves no escalation"
  expectEq closedResult.smtQueue.length 0 "Lean success leaves no SMT request"
  expectEq closedResult.diagnostics.length 0 "Lean success has no diagnostic"
  let closedRecord ← expectAt closedResult.leanRecords 0 "closed Lean record"
  expectEq closedRecord.bodyHash "sha256:body-a"
    "Lean proof record binds the body"
  expectEq closedRecord.predicateDefinitionHashes ["sha256:predicate-a"]
    "Lean proof record binds predicate definitions"
  expectEq closedRecord.proofModuleHash proofModuleHash
    "Lean proof record binds the proof module"
  expectEq closedRecord.proofTerm.formula closedSuccess.formula
    "Lean proof record stores the instantiated formula"
  expectEq (← recheckLeanRecord closedSuccess closedRecord) .accepted
    "Lean proof record is accepted after kernel rechecking"
  expectEq
    (← recheckLeanRecord closedSuccess { closedRecord with bodyHash := "sha256:body-b" })
    .metadataMismatch
    "mutated Lean proof metadata is rejected"
  let tamperedProof : LeanProofTerm :=
    { formula := { premises := [], conclusions := [.truth] } }
  expectEq
    (← recheckLeanRecord closedSuccess { closedRecord with proofTerm := tamperedProof })
    .kernelRejected
    "tampered Lean proof term must fail kernel rechecking"
  let staleIdentity :=
    { closedSuccess with context := { closedSuccess.context with normaliserVersion := "normaliser-v2" } }
  expectEq (← recheckLeanRecord staleIdentity closedRecord) .metadataMismatch
    "semantic context mutation with a stale obligation ID is rejected"
  let wrongToolchain := oneBody { ctx with leanToolchainHash := "forged-toolchain" }
    [] [] [.truth]
  let wrongToolchainRecord ← expectAt
    (discharge "request-a" [wrongToolchain]).leanRecords 0 "wrong-toolchain record"
  expectEq (← recheckLeanRecord wrongToolchain wrongToolchainRecord) .toolchainMismatch
    "recorded Lean toolchain identity must match the executing kernel"
  let wrongProofModule := oneBody { ctx with proofModuleHash := "sha256:forged-module" }
    [] [] [.truth]
  let wrongProofModuleRecord ← expectAt
    (discharge "request-a" [wrongProofModule]).leanRecords 0 "wrong-proof-module record"
  expectEq (← recheckLeanRecord wrongProofModule wrongProofModuleRecord) .proofModuleMismatch
    "recorded proof-module digest must match the imported module"

  let vacuous := oneBody ctx [.falsity] [] [yPositive]
  let vacuousResult := discharge "request-a" [vacuous]
  expectEq vacuousResult.leanRecords.length 1
    "a closed false premise is discharged by the proved procedure"
  let vacuousRecord ← expectAt vacuousResult.leanRecords 0 "vacuous Lean record"
  expectEq (← recheckLeanRecord vacuous vacuousRecord) .accepted
    "a vacuous proof record passes kernel rechecking"

  let hostileName := "x\")\naxiom forged : False\n("
  let constructorComplete := oneBody ctx [.falsity] []
    [ .truth
    , .falsity
    , .boolVariable hostileName
    , .not (.boolVariable hostileName)
    , .and .truth .falsity
    , .or .falsity .truth
    , .intEq (.literal (-3)) (.scale (-7) (.variable hostileName))
    , .intNe (.add (.literal (-4)) (.literal 1)) (.literal (-2))
    , .intLe (.sub (.literal (-4)) (.literal (-1))) (.literal 0)
    , .intLt (.literal (-1)) (.literal 0)
    , .named hostileName "1\n2" [.literal (-5), .variable hostileName]
    , .nonlinear hostileName
    , .worldSensitive hostileName ]
  let constructorResult := discharge "request-a" [constructorComplete]
  let constructorRecord ← expectAt constructorResult.leanRecords 0
    "constructor-complete Lean record"
  expectEq (← recheckLeanRecord constructorComplete constructorRecord) .accepted
    "every predicate and integer-expression constructor renders as safe Lean syntax"

  let pending := discharge "request-a" [generated]
  expectEq pending.leanRecords.length 0 "undischargeable refinement has no proof record"
  expectEq pending.leanQueue.length 1 "undischargeable refinement must enter the Lean queue"
  expectEq pending.smtQueue.length 1 "eligible open VC enters the typed SMT queue"
  let smtEntry ← expectAt pending.smtQueue 0 "typed SMT queue"
  expectEq smtEntry.canonicalRequest (canonicalSmtRequest generated)
    "SMT queue binds the exact obligation and semantic context"
  expectEq smtEntry.status .awaitingCheckedAdapter
    "SMT queue names the unavailable checked adapter"
  expectTrue smtEntry.requirements.pinnedSolverRequired
    "SMT boundary requires a pinned solver"
  expectTrue smtEntry.requirements.serialiserProofRequired
    "SMT boundary requires a checked serialiser"
  let pendingDiagnostic ← expectOneDiagnostic pending "undischargeable refinement"
  expectEq pendingDiagnostic.schemaVersion "1.0" "diagnostic schema version"
  expectEq pendingDiagnostic.payloadKind "diagnostic" "diagnostic payload kind"
  expectEq pendingDiagnostic.requestId "request-a" "diagnostic request linkage"
  expectEq pendingDiagnostic.body.cause.kind "refinement" "diagnostic cause"
  expectEq pendingDiagnostic.body.cause.data.encoding "opaque" "cause data is opaque"
  expectEq pendingDiagnostic.body.proposedFixes [] "diagnostics do not invent edits"
  expectEq pendingDiagnostic.body.related [] "diagnostic related list is present"

  let unsupported := oneBody ctx [] [] [.named "pred.recursive" "1" [.variable "x"]]
  let unsupportedResult := discharge "request-a" [unsupported]
  expectEq unsupportedResult.smtQueue.length 0 "untranslated predicates never enter SMT"
  let unsupportedQueue ← expectOneLeanQueue unsupportedResult "unsupported predicate"
  expectEq unsupportedQueue.reason (.outsideSmtFragment .untranslatedPredicate)
    "unsupported predicate escalates to Lean"

  let nonlinear := oneBody ctx [] [] [.nonlinear "x*x > 0"]
  let nonlinearResult := discharge "request-a" [nonlinear]
  expectEq nonlinearResult.smtQueue.length 0 "non-linear predicates never enter QF_LIA"
  let nonlinearQueue ← expectOneLeanQueue nonlinearResult "non-linear predicate"
  expectEq nonlinearQueue.reason (.outsideSmtFragment .nonlinearArithmetic)
    "non-linear reasoning escalates to Lean"

  let world := oneBody ctx [] [] [.worldSensitive "World transition"]
  let worldResult := discharge "request-a" [world]
  expectEq worldResult.smtQueue.length 0
    "World refinements never enter SMT"
  let worldQueue ← expectOneLeanQueue worldResult "World refinement"
  expectEq worldQueue.reason (.outsideSmtFragment .worldEffect)
    "World refinements explicitly escalate to Lean"

  let totalityTyping :=
    { bodyTyping ctx [] [] [.truth] with
      totality := some
        { premises := { conjuncts := [.boolVariable "old-total"] }
          conclusion := { conjuncts := [.boolVariable "new-total"] } } }
  let totalityResult := checkBodyRefinements "request-a" totalityTyping
  expectEq totalityResult.leanRecords.length 1 "body safety still discharges"
  expectEq totalityResult.leanQueue.length 1 "open totality enters Lean queue"
  expectEq totalityResult.smtQueue.length 0 "totality is always Lean-only"
  let totalityQueue ← expectOneLeanQueue totalityResult "totality"
  expectEq totalityQueue.reason .totalityIsLeanOnly
    "totality has an explicit Lean-only reason"
  let totalityObligations := bodyObligations totalityTyping
  let totalityObligation ← expectAt totalityObligations 1 "body totality obligation"
  let forgedTotalityEntry : SmtQueueEntry :=
    { obligation := totalityObligation
      canonicalRequest := canonicalSmtRequest totalityObligation
      requirements := checkedAdapterRequirements }
  let externalTotality := recordExternalOutcome "request-a" forgedTotalityEntry
    (.sat { booleans := [("old-total", true), ("new-total", false)] })
  let externalTotalityDiagnostic ← expectOneDiagnostic externalTotality "external totality"
  let externalTotalityStatus ← expectAt externalTotalityDiagnostic.body.obligations 0
    "external totality"
  expectEq externalTotalityStatus.status .deferred
    "external outcomes cannot bypass the Lean-only totality boundary"
  let externalTotalityQueue ← expectOneLeanQueue externalTotality "external totality"
  expectEq externalTotalityQueue.reason .externalRequestIneligible
    "ineligible external request has an explicit escalation reason"
  for kind in [ObligationKind.erasedWordTypeEquality, .totalityPromisePresence] do
    let structural := makeObligation kind [.truth] [.boolVariable "structural-result"] ctx
    expectEq (discharge "request-a" [structural]).smtQueue.length 0
      "structural obligations never enter SMT"
    let forgedStructural : SmtQueueEntry :=
      { obligation := structural
        canonicalRequest := canonicalSmtRequest structural
        requirements := checkedAdapterRequirements }
    let structuralOutcome := recordExternalOutcome "request-a" forgedStructural
      (.sat { booleans := [("structural-result", false)] })
    let structuralQueue ← expectOneLeanQueue structuralOutcome "structural external outcome"
    expectEq structuralQueue.reason .externalRequestIneligible
      "external outcomes cannot target structural obligations"

  expectExternalDeferred generated .unknown .externalUnknown "external-unknown"
  expectExternalDeferred generated (.timeout 250) (.externalTimeout 250) "external-timeout:250"
  expectExternalDeferred generated .resourceExhausted .externalResourceExhausted
    "external-resource-exhausted"
  expectExternalDeferred generated (.malformed "bad sexpr") .externalMalformed "external-malformed"
  expectExternalDeferred generated (.crashed "exit 9") .externalCrash "external-crash"
  expectExternalDeferred generated (.uncheckedUnsat "forged") .uncheckedUnsatRejected
    "unchecked-unsat-rejected"

  let falseConclusion := oneBody ctx [.intEq (.variable "x") (.literal 1)] []
    [.intLt (.variable "x") (.literal 0)]
  let falsePending := discharge "request-a" [falseConclusion]
  let falseEntry ← expectAt falsePending.smtQueue 0 "countermodel request"
  let countermodel := Valuation.mk [("x", 1)] []
  let failed := recordExternalOutcome "request-a" falseEntry (.sat countermodel)
  expectEq failed.leanRecords.length 0 "countermodel never creates proof evidence"
  let failedDiagnostic ← expectOneDiagnostic failed "valid countermodel"
  let failedObligation ← expectAt failedDiagnostic.body.obligations 0 "valid countermodel"
  expectEq failedObligation.status .failed
    "complete countermodel is a failed obligation"
  expectEq failedDiagnostic.body.messageParams
    [("counterexample", renderCountermodel countermodel)]
    "counterexample is retained in deterministic message parameters"
  expectEq failedObligation.data.value
    [("backend", "smt"), ("result", "sat"), ("model", renderCountermodel countermodel)]
    "counterexample is retained in opaque obligation data"
  let invalidModel := recordExternalOutcome "request-a" falseEntry (.sat {})
  let invalidDiagnostic ← expectOneDiagnostic invalidModel "invalid countermodel"
  let invalidObligation ← expectAt invalidDiagnostic.body.obligations 0 "invalid countermodel"
  expectEq invalidObligation.status .deferred
    "incomplete countermodel is non-success"
  let duplicateModel := recordExternalOutcome "request-a" falseEntry
    (.sat { integers := [("x", 1), ("x", 1)] })
  let duplicateDiagnostic ← expectOneDiagnostic duplicateModel "duplicate countermodel"
  let duplicateObligation ← expectAt duplicateDiagnostic.body.obligations 0 "duplicate countermodel"
  expectEq duplicateObligation.status .deferred
    "duplicate model bindings are rejected"
  let missingLater := oneBody ctx [.truth] [] [.falsity, .boolVariable "missing"]
  let missingLaterPending := discharge "request-a" [missingLater]
  let missingLaterEntry ← expectAt missingLaterPending.smtQueue 0 "missing later variable"
  let missingLaterResult := recordExternalOutcome "request-a" missingLaterEntry (.sat {})
  let missingLaterDiagnostic ← expectOneDiagnostic missingLaterResult "missing later variable"
  let missingLaterObligation ← expectAt missingLaterDiagnostic.body.obligations 0
    "missing later variable"
  expectEq missingLaterObligation.status .deferred
    "all formula variables are required even after an earlier false conclusion"
  let forgedObligation := { falseConclusion with obligationId := "forged-obligation-id" }
  let forgedEntry : SmtQueueEntry :=
    { obligation := forgedObligation
      canonicalRequest := canonicalSmtRequest forgedObligation
      requirements := checkedAdapterRequirements }
  let forgedResult := recordExternalOutcome "request-a" forgedEntry (.sat countermodel)
  let forgedQueue ← expectOneLeanQueue forgedResult "forged obligation identity"
  expectEq forgedQueue.reason .externalRequestIneligible
    "queue eligibility recomputes the obligation identity"

  let bodyMutation := oneBody { ctx with bodyHash := "sha256:body-b" } [xPositive] [successor]
    [yPositive]
  let specMutation := oneBody { ctx with specHash := "sha256:spec-b" } [xPositive] [successor]
    [yPositive]
  expectTrue (generated.obligationId != bodyMutation.obligationId)
    "body identity mutation invalidates the obligation"
  expectTrue (generated.obligationId != specMutation.obligationId)
    "specification identity mutation invalidates the obligation"
  let calleeMutation := oneBody { ctx with calleeContractHashes := ["sha256:callee-b"] }
    [xPositive] [successor] [yPositive]
  let predicateMutation := oneBody
    { ctx with predicateDefinitionHashes := ["sha256:predicate-b"] }
    [xPositive] [successor] [yPositive]
  let normaliserMutation := oneBody { ctx with normaliserVersion := "normaliser-v2" }
    [xPositive] [successor] [yPositive]
  let vcMutation := oneBody { ctx with vcGeneratorVersion := "vc-v2" }
    [xPositive] [successor] [yPositive]
  let toolchainMutation := oneBody { ctx with toolchainRevision := "firth-b" }
    [xPositive] [successor] [yPositive]
  for mutation in [calleeMutation, predicateMutation, normaliserMutation, vcMutation,
      toolchainMutation] do
    expectTrue (generated.obligationId != mutation.obligationId)
      "semantic dependency mutation invalidates the obligation identity"
    expectTrue (canonicalSmtRequest generated != canonicalSmtRequest mutation)
      "semantic dependency mutation invalidates the exact SMT request"
  expectTrue (canonicalFormula { premises := [.boolVariable "a|b"], conclusions := [] } !=
    canonicalFormula { premises := [.boolVariable "a", .boolVariable "b"], conclusions := [] })
    "length framing resists delimiter ambiguity"

  let late := discharge "request-sort" [oneBody { ctx with
      source := { path := "z.firth", span := span 20 24 } }
    [xPositive] [successor] [yPositive]]
  let early := discharge "request-sort" [oneBody { ctx with
      source := { path := "a.firth", span := span 30 34 } }
    [xPositive] [successor] [yPositive]]
  let sorted := sortDiagnostics (late.diagnostics ++ early.diagnostics)
  let firstDiagnostic ← expectAt sorted 0 "first sorted diagnostic"
  let secondDiagnostic ← expectAt sorted 1 "second sorted diagnostic"
  expectEq firstDiagnostic.body.location.path "a.firth"
    "diagnostics sort by path before discovery order"
  expectEq secondDiagnostic.body.location.path "z.firth"
    "diagnostic ordering retains later path"

  let base ← expectOneDiagnostic pending "diagnostic ordering base"
  let atPathB := diagnosticVariant base "path-b" base.body.code "b.firth" (span 1 5)
  let atStartLater := diagnosticVariant base "start-later" base.body.code "a.firth" (span 2 5)
  let atStopEarlier := diagnosticVariant base "stop-earlier" base.body.code "a.firth" (span 1 4)
  let atCodeEarlier := diagnosticVariant base "code-earlier" "firth.refinement.a"
    "a.firth" (span 1 5)
  let atPayloadEarlier := diagnosticVariant base "a-payload" base.body.code "a.firth" (span 1 5)
  let atPayloadLater := diagnosticVariant base "z-payload" base.body.code "a.firth" (span 1 5)
  let fullySorted := sortDiagnostics [atPathB, atPayloadLater, atStartLater,
    atCodeEarlier, atStopEarlier, atPayloadEarlier]
  expectEq (fullySorted.map (fun diagnostic => diagnostic.payloadId))
    ["stop-earlier", "code-earlier", "a-payload", "z-payload", "start-later", "path-b"]
    "diagnostics sort by path, start, stop, code, and payload ID"

  IO.println "all refinement discharge tests passed"
