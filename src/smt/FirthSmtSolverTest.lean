import smt.Firth.SmtSolver

/-!
Behaviour tests for the bounded solver runner.

Every case runs against an injected runner rather than a fetched binary, so
the suite is reproducible on a host with no solver, which is the point of the
seam. What is tested is exactly what the module owns: the refusal rules that
run before any invocation, the total classification of both the decision and
the model transcript, the model parser, and the provenance every result and
verdict leaves the module with. An injected runner yields `injectedRunner`
whatever digest it reports, and `solvePinned` and `rerunPinned` are exercised
here only as far as their refusals: the positive, record-producing branch
needs the pinned binary, which `src/smt/FirthSmtPinnedSolverTest.lean` runs on
the platform the pin names. Nothing here reads the environment, so the result
does not depend on whether the host names a solver.
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
  match parseModel request.bindings "(model (define-fun i0 () Int 5))" with
  | .ok model =>
      expectEq model.integers [("x", (5 : Int))]
        "a model keyword immediately after the opening paren is accepted"
  | .error error => fail s!"a model keyword was rejected: {error}"
  -- The grammar is exactly one outer list of entries and nothing else: no
  -- bare entry, no extra wrapping, no second model, no trailing tokens, no
  -- keyword anywhere but first, and no symbol defined twice.
  for (text, reason) in [
      ("((define-fun i9 () Int 1))", "a symbol the request never declared"),
      ("((define-fun i0 () Real 1))", "an unsupported sort"),
      ("((define-fun i0 () Int true))", "a non-integer value"),
      ("((define-fun i0 () Int", "a truncated definition"),
      ("((define-fun i0 () Bool maybe))", "a non-boolean value"),
      ("((define-fun i0 () Int (- -7)))", "a signed magnitude inside a negation"),
      ("(define-fun i0 () Int 5)", "an entry without the outer list"),
      ("(((define-fun i0 () Int 5)))", "a doubly wrapped model"),
      ("((define-fun i0 () Int 5)) ((define-fun i0 () Int 6))", "two models"),
      ("((define-fun i0 () Int 5)", "an unterminated model"),
      ("((define-fun i0 () Int 5) model)", "a model keyword after an entry"),
      ("((define-fun i0 () Int 5) (define-fun i0 () Int 6))", "a symbol defined twice"),
      ("", "an empty response"),
      ("sat", "an answer where a model was expected")] do
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
        expectEq result.value.outcome expected message
        expectEq result.value.profile defaultSolverProfile
          "every result carries the profile it was produced under"
        expectEq result.value.proofBindings request.proofBindings
          "every result carries the request's translation and proof bindings"
        -- The stub reports the pinned digest and still yields the seam's
        -- provenance: what a runner says about itself is not what happened.
        expectEq result.provenance .injectedRunner
          "a result from an injected runner is labelled as such, whatever it reports"
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
  -- The model run is classified like the decision run before anything is
  -- parsed: a crash, a resource limit or a changed answer is never turned into
  -- a counterexample, and a repeated answer line is not part of the model.
  expectOutcome [answer "sat", answer "sat\n((define-fun i0 () Int 5))" 1]
    (.crashed "model run: exit 1")
    "a model run that exits non-zero is a crash, not a counterexample"
  expectOutcome [answer "sat", answer "(error \"out of memory\")\n((define-fun i0 () Int 5))"]
    .resourceExhausted
    "a model run that reports a resource limit is exhaustion, not a counterexample"
  expectOutcome [answer "sat", answer "unsat"]
    (.malformed "model run did not answer sat")
    "a model run that no longer answers sat is malformed output"
  expectOutcome [answer "sat", { answer "sat" with outputLimitExceeded := true }]
    (.malformed "model run: output limit exceeded")
    "a model run past the output bound is malformed output"
  let repeatedSat ← stubRunner [answer "sat", answer "sat\nsat\n((define-fun i0 () Int 5))"]
  match ← solve repeatedSat defaultSolverProfile request with
  | .ok result =>
      match result.value.outcome with
      | .malformed _ => pure ()
      | outcome => fail s!"a model run answering sat twice was accepted: {repr outcome}"
  | .error refusal => fail s!"a model run answering sat twice was refused: {repr refusal}"
  -- A refusal is reported as a refusal, never as an outcome, so nothing an
  -- unpinned solver said can reach the record boundary.
  let impostor ← stubRunner [answer "unsat"] (digest := some "sha256:00")
  match ← solve impostor defaultSolverProfile request with
  | .error (.executableDigestMismatch _ _) => pure ()
  | result => fail s!"an unpinned executable produced a result: {repr result}"

/-- `solvePinned` and `rerunPinned` are the only producers of `pinnedProcess`,
and on this host they can only refuse: no explicit path here names the pinned
binary, and the environment is never consulted because every call passes an
explicit path. -/
private def pinnedTests : IO Unit := do
  let request ← pinnedRequest
  expectEq unattestedProvenanceCode "firth.smt.unattested-provenance"
    "the unattested-provenance code is the stable string the boundary reports"
  expectEq pinnedSolverVariable "FIRTH_SMT_SOLVER"
    "the pinned executable is named by FIRTH_SMT_SOLVER when no path is given"
  match ← solvePinned defaultSolverProfile request (some "/nonexistent/firth-z3") with
  | .error (.executableMissing _) => pure ()
  | result => fail s!"a missing pinned executable produced a result: {repr result}"
  match ← solvePinned defaultSolverProfile request (some "z3") with
  | .error (.executableMissing _) => pure ()
  | result => fail s!"a relative executable path was resolved: {repr result}"
  match ← solvePinned defaultSolverProfile request (some "") with
  | .error (.executableMissing _) => pure ()
  | result => fail s!"an empty executable path was resolved: {repr result}"
  expectEq (← pinnedExecutable (some "/nonexistent/firth-z3"))
    (some (System.FilePath.mk "/nonexistent/firth-z3"))
    "an explicit absolute path resolves to itself; only the digest pin says what is there"
  expectEq (← pinnedExecutable (some "bin/z3")) none
    "an explicit relative path is refused rather than searched"
  -- Profile and request checks still run first, so a caller learns about an
  -- unpinned profile before it learns that no solver is installed.
  match ← solvePinned { defaultSolverProfile with version := "4.0.0" } request
      (some "/nonexistent/firth-z3") with
  | .error .unpinnedProfile => pure ()
  | result => fail s!"an unpinned profile reached executable resolution: {repr result}"
  -- The injected seam cannot be talked into the pinned provenance.
  expectEq (injected (0 : Nat)).provenance .injectedRunner
    "an injected value is labelled as the test seam"

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

private def uncheckedResult (request : SmtRequest) : SmtResult :=
  { profile := defaultSolverProfile
    proofBindings := request.proofBindings
    requestIdentity := canonicalRequestIdentity request
    outcome := .uncheckedUnsat "unsat" }

private def recordTests : IO Unit := do
  let request ← pinnedRequest
  -- No solver is invoked: a caller can fabricate every field of this result.
  -- The formula is explicitly false, so the marker cannot be evidence of it.
  let falseRequest ←
    match checkedSmtRequest defaultSolverProfile { premises := [], conclusions := [.falsity] } with
    | .ok value => pure value
    | .error failure => fail s!"false-formula fixture failed: {repr failure}"
  match makeDischargeRecord testBinding falseRequest
      { uncheckedResult falseRequest with outcome := .checkedUnsat "fabricated" } with
  | .error .notUnsat => pure ()
  | result => fail s!"fabricated checked-unsat produced a record: {repr result}"
  -- Even a marker returned by the promotion helper is not a transferable token.
  match checkUnsat request (uncheckedResult request) with
  | .error failure => fail s!"a pinned raw result was not promoted: {repr failure}"
  | .ok promoted =>
      match makeDischargeRecord testBinding request promoted with
      | .error .notUnsat => pure ()
      | result => fail s!"a pre-promoted result produced a record: {repr result}"
  -- Promotion refuses each way the request/result metadata can be wrong.
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

  let raw := uncheckedResult request
  match makeDischargeRecord testBinding request raw with
  | .error failure => fail s!"a pinned raw unsat produced no record: {repr failure}"
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
  -- Neither pre-promoted markers nor non-unsat answers are admitted.
  for outcome in [ExternalOutcome.checkedUnsat "unsat", .unknown, .timeout 5000,
      .resourceExhausted, .malformed "bad", .crashed "exit 1", .sat {}] do
    match makeDischargeRecord testBinding request { raw with outcome } with
    | .error .notUnsat => pure ()
    | result => fail s!"a non-admissible outcome produced a record: {repr result}"
  -- Replaying a result across premises or conclusions must fail identity binding.
  for formula in [{ request.formula with premises := [] },
      { request.formula with conclusions := [.truth] }] do
    let otherRequest ←
      match checkedSmtRequest defaultSolverProfile formula with
      | .ok value => pure value
      | .error failure => fail s!"replay fixture failed: {repr failure}"
    match makeDischargeRecord testBinding otherRequest raw with
    | .error .requestIdentityMismatch => pure ()
    | result => fail s!"a result replayed across formulae produced a record: {repr result}"
  -- Raw metadata must still pass each distinct admission check.
  for (mutated, expected, reason) in [
      ({ raw with profile := { defaultSolverProfile with version := "4.0.0" } },
       CheckFailure.unpinnedProfile, "a result carrying another profile"),
      ({ raw with requestIdentity := "request(0:)" },
       .requestIdentityMismatch, "a result bound to another request"),
      ({ raw with
         proofBindings := { defaultSmtProofBindings with translationRuleHashes := ["sha256:x"] } },
       .proofBindingsMismatch, "a result carrying stale proof bindings")] do
    match makeDischargeRecord testBinding request mutated with
    | .error failure => expectEq failure expected s!"{reason} is refused a record"
    | .ok record => fail s!"{reason} produced a record: {repr record}"
  match makeDischargeRecord testBinding { request with smtLib := "(check-sat)" } raw with
  | .error .unpinnedRequest => pure ()
  | result => fail s!"a request that does not rebuild to itself produced a record: {repr result}"

private def rerunTests : IO Unit := do
  let request ← pinnedRequest
  let raw := uncheckedResult request
  let record ←
    match makeDischargeRecord testBinding request raw with
    | .ok record => pure record
    | .error failure => fail s!"could not build a record: {repr failure}"
  let runner ← stubRunner [answer "unsat"]
  let confirmed ← rerunDischargeRecord runner testBinding obligationFormula record
  match confirmed.value with
  | .rechecked rebuilt => expectEq rebuilt record "a recheck rebuilds the same record"
  | verdict => fail s!"a sound record failed recheck: {repr verdict}"
  expectEq confirmed.provenance .injectedRunner
    "a rechecked verdict from an injected runner is labelled as the test seam"
  -- The pinned rerun resolves an executable exactly as solvePinned does, and
  -- on this host it can only refuse; the drift check still runs first.
  let pinnedAbsent ← rerunPinned testBinding obligationFormula record (some "/nonexistent/firth-z3")
  match pinnedAbsent.value with
  | .refused (.executableMissing _) => pure ()
  | verdict => fail s!"a missing pinned executable rechecked a record: {repr verdict}"
  match (← rerunPinned testBinding obligationFormula record (some "z3")).value with
  | .refused (.executableMissing _) => pure ()
  | verdict => fail s!"a relative pinned executable path was resolved: {repr verdict}"
  match (← rerunPinned testBinding obligationFormula { record with invocationOptions := ["-in"] }
      (some "/nonexistent/firth-z3")).value with
  | .driftedRecord .optionDrift => pure ()
  | verdict => fail s!"a drifted record was not rechecked before the solver was sought: {repr verdict}"
  let changedRunner ← stubRunner [answer "unknown"]
  match (← rerunDischargeRecord changedRunner testBinding obligationFormula record).value with
  | .notRechecked .notUnsat .unknown => pure ()
  | verdict => fail s!"a record whose answer changed was accepted: {repr verdict}"
  -- A rerun that answers sat is not the same fact as one that answers unknown,
  -- and the verdict keeps them apart.
  let satRunner ← stubRunner [answer "sat", answer "sat\n((define-fun i0 () Int 5))"]
  match (← rerunDischargeRecord satRunner testBinding obligationFormula record).value with
  | .notRechecked .notUnsat (.sat model) =>
      expectEq model.integers [("x", (5 : Int))]
        "a rerun that answers sat carries the model it found"
  | verdict => fail s!"a rerun that disproved the obligation was collapsed: {repr verdict}"
  let impostor ← stubRunner [answer "unsat"] (digest := some "sha256:00")
  match (← rerunDischargeRecord impostor testBinding obligationFormula record).value with
  | .refused (.executableDigestMismatch _ _) => pure ()
  | verdict => fail s!"an unpinned solver rechecked a record: {repr verdict}"
  let drifted := { record with invocationOptions := ["-in"] }
  match (← rerunDischargeRecord runner testBinding obligationFormula drifted).value with
  | .driftedRecord .optionDrift => pure ()
  | verdict => fail s!"invocation-option drift was accepted: {repr verdict}"
  let tampered := { record with normalisedFormulaHash := "formula(0[]0[])" }
  match (← rerunDischargeRecord runner testBinding obligationFormula tampered).value with
  | .driftedRecord (.recordTampered "normalised-formula") => pure ()
  | verdict => fail s!"a tampered normalised formula was accepted: {repr verdict}"
  -- Evidence is an output, not an input. A second run that answers unsat with
  -- a different core confirms the record; the verdict carries what this run
  -- said rather than what the stored record did.
  let coredRunner ← stubRunner [answer "unsat\n(core a)"]
  match (← rerunDischargeRecord coredRunner testBinding obligationFormula record).value with
  | .rechecked rebuilt =>
      expectTrue (rebuilt.evidenceHash != record.evidenceHash)
        "the verdict carries the evidence this run produced"
      expectEq { rebuilt with evidenceHash := record.evidenceHash } record
        "every input still matches the recorded one"
  | verdict => fail s!"a differing unsat core was treated as drift: {repr verdict}"
  let staleSource := { record with
    obligation := { record.obligation with sourceStopColumn := 99 } }
  match (← rerunDischargeRecord runner testBinding obligationFormula staleSource).value with
  | .driftedRecord .recordStale => pure ()
  | verdict => fail s!"a record naming another source span was accepted: {repr verdict}"

def runTests : IO Unit := do
  classificationTests
  modelScriptTests
  parseModelTests
  refusalTests
  solveTests
  pinnedTests
  recordTests
  rerunTests
  IO.println "all SMT solver runner tests passed"

end Firth.SmtSolverTest

def main : IO Unit := Firth.SmtSolverTest.runTests
