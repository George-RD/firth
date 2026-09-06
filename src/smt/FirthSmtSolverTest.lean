import smt.Firth.SmtSolver

/-!
Behaviour tests for the bounded solver runner.

Every case runs against an injected runner rather than a fetched binary, so
the suite is reproducible on a host with no solver, which is the point of the
seam. What is tested is exactly what the module owns: the refusal rules that
run before any invocation, the total classification of a transcript, and the
model parser.
-/

namespace Firth.SmtSolverTest

open Firth.Smt
open Firth.Smt.Solver

private def fail (message : String) : IO α := throw <| IO.userError message

private def expectEq [BEq α] [Repr α] (actual expected : α) (message : String) : IO Unit :=
  if actual == expected then pure ()
  else fail s!"{message}\nactual: {repr actual}\nexpected: {repr expected}"

private def expectTrue (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else fail message

/-- A runner that answers from a queue of prepared transcripts. -/
private def stubRunner (transcripts : List Transcript)
    (digest : Option String := some defaultSolverProfile.executableDigest)
    (path : Option String := some "/pinned/z3") : IO SolverRunner := do
  let queue ← IO.mkRef transcripts
  pure
    { run := fun _ _ _ => do
        match ← queue.get with
        | [] => pure { exitCode := 0, stdout := "", stderr := "" }
        | head :: rest =>
            queue.set rest
            pure head
      executableDigest := pure digest
      executablePath := pure path }

private def answer (text : String) (exitCode : UInt32 := 0) : Transcript :=
  { exitCode, stdout := text, stderr := "" }

private def obligationFormula : Formula :=
  { premises := [.intLt (.literal 0) (.variable "x")]
    conclusions := [.intLt (.variable "x") (.literal 0)] }

private def pinnedRequest : IO SmtRequest :=
  match checkedSmtRequest defaultSolverProfile obligationFormula with
  | .ok request => pure request
  | .error error => fail s!"the checked adapter rejected a QF_LIA obligation: {repr error}"

private def classificationTests : IO Unit := do
  let profile := defaultSolverProfile
  expectEq (classifyTranscript profile { answer "unsat" with timedOut := true })
    (ExternalOutcome.timeout profile.wallTimeMilliseconds)
    "a bound reached before exit is a timeout, whatever was printed"
  expectEq (classifyTranscript profile { answer "unsat" with outputLimitExceeded := true })
    (ExternalOutcome.malformed "output limit exceeded")
    "output past the bound is malformed, not an answer"
  expectEq (classifyTranscript profile (answer "(error \"out of memory\")"))
    ExternalOutcome.resourceExhausted
    "a reported resource limit is exhaustion, not a crash"
  expectEq (classifyTranscript profile (answer "unsat"))
    (ExternalOutcome.uncheckedUnsat "unsat")
    "a bare unsat is unchecked until something rechecks it"
  expectEq (classifyTranscript profile (answer "unknown"))
    ExternalOutcome.unknown
    "unknown is deferred, never success"
  expectEq (classifyTranscript profile (answer "sat"))
    (ExternalOutcome.sat { integers := [], booleans := [] })
    "a sat answer is carried forward so its model can be fetched"
  expectEq (classifyTranscript profile (answer "unsat" 1))
    (ExternalOutcome.crashed "exit 1")
    "an answer with a non-zero exit is a crash, not that answer"
  expectEq (classifyTranscript profile (answer ""))
    (ExternalOutcome.malformed "empty answer")
    "silence is malformed output"
  expectEq (classifyTranscript profile (answer "maybe"))
    (ExternalOutcome.malformed "unrecognised answer: maybe")
    "an answer outside the vocabulary is malformed"

private def modelScriptTests : IO Unit := do
  let request ← pinnedRequest
  let script := modelScript request
  expectTrue ((script.splitOn "(get-model)").length == 2)
    "the model script asks for a model exactly once"
  expectTrue ((request.smtLib.splitOn "(get-model)").length == 1)
    "the decision script never asks for a model, so unsat is never an error"
  expectTrue ((script.splitOn "(check-sat)").length == 2)
    "the model script still decides before it asks"

private def parseModelTests : IO Unit := do
  let request ← pinnedRequest
  match parseModel request.bindings "((define-fun i0 () Int 5))" with
  | .ok model =>
      expectEq model.integers [("x", (5 : Int))]
        "a model is reported against source names, not solver symbols"
      expectTrue (validatesCounterexample obligationFormula model)
        "the parsed model is a counterexample the boundary accepts"
  | .error error => fail s!"a well-formed model was rejected: {error}"
  match parseModel request.bindings "((define-fun i0 () Int (- 7)))" with
  | .ok model => expectEq model.integers [("x", (-7 : Int))] "a negative value parses"
  | .error error => fail s!"a negative model value was rejected: {error}"
  for (text, reason) in [
      ("((define-fun i9 () Int 1))", "a symbol the request never declared"),
      ("((define-fun i0 () Real 1))", "an unsupported sort"),
      ("((define-fun i0 () Int true))", "a non-integer value"),
      ("((define-fun i0 () Int", "a truncated definition"),
      ("((define-fun i0 () Bool maybe))", "a non-boolean value")] do
    match parseModel request.bindings text with
    | .ok model => fail s!"{reason} was accepted as a model: {repr model}"
    | .error _ => pure ()

private def refusalTests : IO Unit := do
  let request ← pinnedRequest
  let runner ← stubRunner [answer "unsat"]
  let mutated := { defaultSolverProfile with version := "4.0.0" }
  match ← verifyPin runner mutated request with
  | .error .unpinnedProfile => pure ()
  | result => fail s!"an unpinned profile was accepted: {repr result}"
  match ← verifyPin runner defaultSolverProfile { request with smtLib := "(check-sat)" } with
  | .error .unpinnedRequest => pure ()
  | result => fail s!"a request that does not rebuild to itself was accepted: {repr result}"
  let absent ← stubRunner [answer "unsat"] (path := none)
  match ← verifyPin absent defaultSolverProfile request with
  | .error (.executableMissing _) => pure ()
  | result => fail s!"a missing executable was accepted: {repr result}"
  let undigested ← stubRunner [answer "unsat"] (digest := none)
  match ← verifyPin undigested defaultSolverProfile request with
  | .error .digestUnavailable => pure ()
  | result => fail s!"an unverifiable executable was accepted: {repr result}"
  let impostor ← stubRunner [answer "unsat"] (digest := some "sha256:00")
  match ← verifyPin impostor defaultSolverProfile request with
  | .error (.executableDigestMismatch _ _) => pure ()
  | result => fail s!"an executable that is not the pinned one was accepted: {repr result}"

private def solveTests : IO Unit := do
  let request ← pinnedRequest
  let expectOutcome (transcripts : List Transcript) (expected : ExternalOutcome)
      (message : String) : IO Unit := do
    let runner ← stubRunner transcripts
    match ← solve runner defaultSolverProfile request with
    | .error refusal => fail s!"{message}: refused with {repr refusal}"
    | .ok result =>
        expectEq result.outcome expected message
        expectEq result.profile defaultSolverProfile
          "every result carries the profile it was produced under"
        expectEq result.proofBindings request.proofBindings
          "every result carries the request's translation and proof bindings"
  expectOutcome [answer "unsat"] (.uncheckedUnsat "unsat")
    "an unsat answer stays unchecked"
  expectOutcome [answer "unknown"] .unknown "an unknown answer is deferred"
  expectOutcome [{ answer "" with timedOut := true }]
    (.timeout defaultSolverProfile.wallTimeMilliseconds)
    "a decision run that reached its bound is a timeout"
  expectOutcome [answer "sat", answer "sat\n((define-fun i0 () Int 5))"]
    (.sat { integers := [("x", 5)], booleans := [] })
    "a sat answer costs a second bounded run that fetches its model"
  expectOutcome [answer "sat", answer "sat\n((define-fun i9 () Int 5))"]
    (.malformed "model: i9 was never declared")
    "a model naming a symbol the request never declared is malformed"
  expectOutcome [answer "sat", { answer "" with timedOut := true }]
    (.timeout defaultSolverProfile.wallTimeMilliseconds)
    "a model run that reached its bound is a timeout, not a counterexample"
  -- A refusal is reported as a refusal, never as an outcome, so nothing an
  -- unpinned solver said can reach the record boundary.
  let impostor ← stubRunner [answer "unsat"] (digest := some "sha256:00")
  match ← solve impostor defaultSolverProfile request with
  | .error (.executableDigestMismatch _ _) => pure ()
  | result => fail s!"an unpinned executable produced a result: {repr result}"

private def testBinding : ObligationBinding :=
  { obligationId := "obligation-1"
    wordId := "w"
    bodyHash := "sha256:body"
    erasedWordTypeHash := "sha256:type"
    specHash := "sha256:spec"
    calleeContractHashes := []
    predicateDefinitionHashes := []
    vcGeneratorVersion := "vc-1"
    normaliserVersion := "norm-1"
    toolchainRevision := "rev-1"
    sourcePath := "w.firth"
    sourceStartOffset := 0
    sourceStartLine := 1
    sourceStartColumn := 1
    sourceStopOffset := 7
    sourceStopLine := 1
    sourceStopColumn := 8 }

private def checkedResult (request : SmtRequest) : IO SmtResult :=
  match checkUnsat request
      { profile := defaultSolverProfile
        proofBindings := request.proofBindings
        requestIdentity := canonicalRequestIdentity request
        outcome := .uncheckedUnsat "unsat" } with
  | .ok result => pure result
  | .error failure => fail s!"a pinned unsat was refused: {repr failure}"

private def recordTests : IO Unit := do
  let request ← pinnedRequest
  -- Promotion refuses each way it can be wrong, and only the checked adapter
  -- can produce a checked unsat at all.
  for (result, expected, reason) in [
      ({ profile := { defaultSolverProfile with version := "4.0.0" }
         requestIdentity := canonicalRequestIdentity request
         outcome := ExternalOutcome.uncheckedUnsat "unsat" },
       CheckFailure.unpinnedProfile, "an unpinned profile"),
      ({ profile := defaultSolverProfile, requestIdentity := "request(0:)"
         outcome := .uncheckedUnsat "unsat" },
       .requestIdentityMismatch, "a result bound to another request"),
      ({ profile := defaultSolverProfile
         proofBindings := { defaultSmtProofBindings with translationRuleHashes := ["sha256:x"] }
         requestIdentity := canonicalRequestIdentity request
         outcome := .uncheckedUnsat "unsat" },
       .proofBindingsMismatch, "stale proof bindings"),
      ({ profile := defaultSolverProfile
         requestIdentity := canonicalRequestIdentity request
         outcome := .unknown },
       .notUnsat, "an answer that is not unsat")] do
    match checkUnsat request result with
    | .error failure => expectEq failure expected s!"{reason} is refused"
    | .ok promoted => fail s!"{reason} was promoted: {repr promoted}"
  match checkUnsat { request with smtLib := "(check-sat)" }
      { profile := defaultSolverProfile
        requestIdentity := canonicalRequestIdentity request
        outcome := .uncheckedUnsat "unsat" } with
  | .error .unpinnedRequest => pure ()
  | result => fail s!"a request that does not rebuild to itself was promoted: {repr result}"

  let checked ← checkedResult request
  match makeDischargeRecord testBinding request checked with
  | .error failure => fail s!"a checked unsat produced no record: {repr failure}"
  | .ok record =>
      expectEq record.result "unsat" "a record states the result it was created from"
      expectEq record.solverExecutableDigest defaultSolverProfile.executableDigest
        "a record binds the pinned executable digest"
      expectEq record.invocationOptions defaultSolverProfile.invocationOptions
        "a record binds the pinned invocation options"
      expectEq record.requestIdentity (canonicalRequestIdentity request)
        "a record binds the request it answers"
      expectEq record.translationRuleHashes defaultSmtProofBindings.translationRuleHashes
        "a record binds the translation rules it was produced under"
      expectEq record.normalisedFormulaHash (canonicalNormalisedFormula request.formula)
        "a record binds the formula the encoder consumed"
      expectEq record.obligation.sourceStopOffset testBinding.sourceStopOffset
        "a record keeps the whole source span, not just where it starts"
      -- The record has an address of its own, and it separates records that
      -- differ in any single field.
      for (other, field) in [
          ({ record with evidenceHash := "0:" }, "evidence"),
          ({ record with result := "sat" }, "result"),
          ({ record with normalisedFormulaHash := "formula(0[]0[])" }, "formula"),
          ({ record with obligation := { record.obligation with sourceStopLine := 9 } },
            "source span"),
          ({ record with profile := { record.profile with licence := "GPL" } }, "licence")] do
        expectTrue (canonicalDischargeRecord other != canonicalDischargeRecord record)
          s!"a record that differs in its {field} has a different address"
      match recheckDischargeRecord testBinding obligationFormula record with
      | .ok rebuilt =>
          expectEq rebuilt request "recheck rebuilds the very request the record names"
      | .error failure => fail s!"a fresh record failed recheck: {repr failure}"
      match recheckDischargeRecord { testBinding with wordId := "other" } obligationFormula
          record with
      | .error .recordStale => pure ()
      | result => fail s!"a record for another obligation was accepted: {repr result}"
  -- An unchecked unsat never becomes a record, whatever else is in order.
  match makeDischargeRecord testBinding request
      { profile := defaultSolverProfile
        requestIdentity := canonicalRequestIdentity request
        outcome := .uncheckedUnsat "unsat" } with
  | .error .notUnsat => pure ()
  | result => fail s!"an unchecked unsat produced a record: {repr result}"
  -- Nor does a checked result that was not checked against this request.
  let checkedAgain ← checkedResult request
  for (mutated, expected, reason) in [
      ({ checkedAgain with profile := { defaultSolverProfile with version := "4.0.0" } },
       CheckFailure.unpinnedProfile, "a result carrying another profile"),
      ({ checkedAgain with requestIdentity := "request(0:)" },
       .requestIdentityMismatch, "a result bound to another request"),
      ({ checkedAgain with
         proofBindings := { defaultSmtProofBindings with translationRuleHashes := ["sha256:x"] } },
       .proofBindingsMismatch, "a result carrying stale proof bindings")] do
    match makeDischargeRecord testBinding request mutated with
    | .error failure => expectEq failure expected s!"{reason} is refused a record"
    | .ok record => fail s!"{reason} produced a record: {repr record}"
  match makeDischargeRecord testBinding { request with smtLib := "(check-sat)" } checkedAgain with
  | .error .unpinnedRequest => pure ()
  | result => fail s!"a request that does not rebuild to itself produced a record: {repr result}"

private def rerunTests : IO Unit := do
  let request ← pinnedRequest
  let checked ← checkedResult request
  let record ←
    match makeDischargeRecord testBinding request checked with
    | .ok record => pure record
    | .error failure => fail s!"could not build a record: {repr failure}"
  let runner ← stubRunner [answer "unsat"]
  match ← rerunDischargeRecord runner testBinding obligationFormula record with
  | .rechecked rebuilt => expectEq rebuilt record "a recheck rebuilds the same record"
  | verdict => fail s!"a sound record failed recheck: {repr verdict}"
  let changedRunner ← stubRunner [answer "unknown"]
  match ← rerunDischargeRecord changedRunner testBinding obligationFormula record with
  | .notRechecked .notUnsat .unknown => pure ()
  | verdict => fail s!"a record whose answer changed was accepted: {repr verdict}"
  -- A rerun that answers sat is not the same fact as one that answers unknown,
  -- and the verdict keeps them apart.
  let satRunner ← stubRunner [answer "sat", answer "sat\n((define-fun i0 () Int 5))"]
  match ← rerunDischargeRecord satRunner testBinding obligationFormula record with
  | .notRechecked .notUnsat (.sat model) =>
      expectEq model.integers [("x", (5 : Int))]
        "a rerun that answers sat carries the model it found"
  | verdict => fail s!"a rerun that disproved the obligation was collapsed: {repr verdict}"
  let impostor ← stubRunner [answer "unsat"] (digest := some "sha256:00")
  match ← rerunDischargeRecord impostor testBinding obligationFormula record with
  | .refused (.executableDigestMismatch _ _) => pure ()
  | verdict => fail s!"an unpinned solver rechecked a record: {repr verdict}"
  let drifted := { record with invocationOptions := ["-in"] }
  match ← rerunDischargeRecord runner testBinding obligationFormula drifted with
  | .driftedRecord .optionDrift => pure ()
  | verdict => fail s!"invocation-option drift was accepted: {repr verdict}"
  let tampered := { record with normalisedFormulaHash := "formula(0[]0[])" }
  match ← rerunDischargeRecord runner testBinding obligationFormula tampered with
  | .driftedRecord (.recordTampered "normalised-formula") => pure ()
  | verdict => fail s!"a tampered normalised formula was accepted: {repr verdict}"
  -- Evidence is an output, not an input. A second run that answers unsat with
  -- a different core confirms the record; the verdict carries what this run
  -- said rather than what the stored record did.
  let coredRunner ← stubRunner [answer "unsat\n(core a)"]
  match ← rerunDischargeRecord coredRunner testBinding obligationFormula record with
  | .rechecked rebuilt =>
      expectTrue (rebuilt.evidenceHash != record.evidenceHash)
        "the verdict carries the evidence this run produced"
      expectEq { rebuilt with evidenceHash := record.evidenceHash } record
        "every input still matches the recorded one"
  | verdict => fail s!"a differing unsat core was treated as drift: {repr verdict}"
  let staleSource := { record with
    obligation := { record.obligation with sourceStopColumn := 99 } }
  match ← rerunDischargeRecord runner testBinding obligationFormula staleSource with
  | .driftedRecord .recordStale => pure ()
  | verdict => fail s!"a record naming another source span was accepted: {repr verdict}"

def runTests : IO Unit := do
  classificationTests
  modelScriptTests
  parseModelTests
  refusalTests
  solveTests
  recordTests
  rerunTests
  IO.println "all SMT solver runner tests passed"

end Firth.SmtSolverTest

def main : IO Unit := Firth.SmtSolverTest.runTests
