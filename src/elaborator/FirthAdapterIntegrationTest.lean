import elaborator.Firth.Refinement
import smt.Firth.SmtSolver

/-!
The external SMT slice end to end: obligation, request, invocation, answer,
and what crosses the refinement-discharge result boundary.

Every other suite tests one link. `smtBoundaryTest` proves the translation is
sound, `smtSolverTest` proves a transcript classifies deterministically,
`firthRefinementTest` proves the boundary refuses a result that is not bound to
its request, and `firthRecordIntegrityTest` proves a stored record cannot go
stale unnoticed. None of them runs an obligation from generation through a
solver invocation to a diagnostic, which is where the properties the
architecture actually promises live:

* a validated `unsat` becomes a content-addressed record that rechecks, and
  nothing else does;
* a complete validated `sat` is a failed refinement with a deterministic
  counterexample, and never proof evidence;
* every other answer, and every answer that cannot be trusted, is a deferred
  non-success with its own stable code;
* the resource bounds in the pinned profile are what the invocation is given.

`spec/smt/refinement-discharge-architecture.md` §3 and §4 are what those come
from. The runner is injected, so the whole suite runs on a host with no solver:
the pinned profile names one platform and one executable digest, so most hosts
cannot run the pinned solver even in principle.
-/

namespace Firth.AdapterIntegrationTest

open Firth.Elaborator
open Firth.Elaborator.Refinement
open Firth.Smt
open Firth.Smt.Solver

private def fail (message : String) : IO α := throw <| IO.userError message

private def expectEq [BEq α] [Repr α] (actual expected : α) (message : String) : IO Unit :=
  if actual == expected then pure ()
  else fail s!"{message}\nactual: {repr actual}\nexpected: {repr expected}"

private def expectTrue (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else fail message

private def expectAt [Repr α] (values : List α) (index : Nat) (message : String) : IO α :=
  match values[index]? with
  | some value => pure value
  | none => fail s!"{message}: expected an entry at {index}, got {repr values}"

/-- One recorded invocation: the options, the script and the bound the runner
was actually given. -/
private structure Invocation where
  options : List String
  script : String
  bound : Nat
  deriving Repr, BEq

private def answer (text : String) (exitCode : UInt32 := 0) : Transcript :=
  { exitCode, stdout := text, stderr := "" }

/-- A runner that answers from a queue and records what it was asked. -/
private def recordingRunner (transcripts : List Transcript)
    (digest : Option String := some defaultSolverProfile.executableDigest)
    (path : Option String := some "/pinned/z3") :
    IO (SolverRunner × IO.Ref (List Invocation)) := do
  let queue ← IO.mkRef transcripts
  let seen ← IO.mkRef ([] : List Invocation)
  let runner : SolverRunner :=
    { run := fun options script bound => do
        seen.modify (fun previous => previous ++ [{ options, script, bound }])
        match ← queue.get with
        | [] => pure { exitCode := 0, stdout := "", stderr := "" }
        | head :: rest =>
            queue.set rest
            pure head
      executableDigest := pure digest
      executablePath := pure path }
  pure (runner, seen)

private def position (offset : Nat) : Position :=
  { offset, line := 1, column := offset + 1 }

private def integerStack (refinements : List Predicate) : RefinedStack :=
  { erased := .snoc (.row (.rigid "ρ")) (.base "Int" .many)
    refinements := { conjuncts := refinements } }

private def testContext : ObligationContext :=
  { wordId := "math.inc"
    bodyHash := "sha256:body-a"
    erasedWordTypeHash := "sha256:word-type-a"
    specHash := "sha256:spec-a"
    calleeContractHashes := ["sha256:callee-a"]
    predicateDefinitionHashes := ["sha256:predicate-a"]
    normaliserVersion := "normaliser-v1"
    vcGeneratorVersion := "vc-v1"
    leanToolchainHash := "sha256:toolchain-a"
    proofModuleHash := "sha256:proof-module-a"
    toolchainRevision := "firth-a"
    source := { path := "inc.firth", span := { start := position 10, stop := position 14 } }
    expectedStack := integerStack [.intLt (.literal 0) (.variable "y")]
    actualStack := integerStack [.intEq (.variable "y") (.add (.variable "x") (.literal 1))] }

private def premises (pre semantics post : List Predicate) : BodyTypingPremises :=
  { context := testContext
    precondition := { conjuncts := pre }
    bodySemantics := { conjuncts := semantics }
    declaredPostcondition := { conjuncts := post } }

private def xPositive : Predicate := .intLt (.literal 0) (.variable "x")
private def successor : Predicate := .intEq (.variable "y") (.add (.variable "x") (.literal 1))
private def yPositive : Predicate := .intLt (.literal 0) (.variable "y")

/-- The obligation the suite discharges: open to the direct procedure, inside
QF_LIA, and therefore eligible for the checked adapter. -/
private def eligibleEntry : IO SmtQueueEntry := do
  match (checkBodyRefinements "request-a" (premises [xPositive] [successor] [yPositive])).smtQueue with
  | [entry] => pure entry
  | queue => fail s!"expected one eligible SMT queue entry, got {repr queue}"

/-- An obligation whose conclusion is false under a model the solver can find,
so the `sat` path has a counterexample to validate. -/
private def refutableEntry : IO SmtQueueEntry := do
  let result := checkBodyRefinements "request-a"
    (premises [.intEq (.variable "x") (.literal 1)] []
      [.intLt (.variable "x") (.literal 0)])
  match result.smtQueue with
  | [entry] => pure entry
  | queue => fail s!"expected one refutable SMT queue entry, got {repr queue}"

/-- Runs the pinned solver over a queue entry and reports the answer through
the refinement-discharge result boundary, which is the path a first discharge
actually takes. -/
private def discharge (runner : SolverRunner) (entry : SmtQueueEntry) :
    IO (Except Refusal PipelineResult) := do
  let some request := entry.request | fail "an eligible queue entry carries a request"
  match ← solve runner entry.profile request with
  | .error refusal => pure (.error refusal)
  | .ok result => pure (.ok (recordExternalOutcome "request-a" entry result))

private def expectDischarged (runner : SolverRunner) (entry : SmtQueueEntry)
    (message : String) : IO PipelineResult := do
  match ← discharge runner entry with
  | .ok result => pure result
  | .error refusal => fail s!"{message}: the invocation was refused with {repr refusal}"

/-- Asserts that an answer was a deferred non-success naming `reason` and
`code`, and that nothing became evidence. -/
private def expectDeferred (result : PipelineResult) (reason : LeanEscalationReason)
    (code : String) (message : String) : IO Unit := do
  expectEq result.dischargeRecords.length 0 s!"{message}: no record may be created"
  expectEq result.leanRecords.length 0 s!"{message}: no proof record may be created"
  match result.leanQueue with
  | [queued] => expectEq queued.reason reason s!"{message}: Lean escalation reason"
  | queue => fail s!"{message}: expected one Lean obligation, got {repr queue}"
  match result.diagnostics with
  | [diagnostic] =>
      let obligation ← expectAt diagnostic.body.obligations 0 message
      expectEq obligation.status .deferred s!"{message}: deferred status"
      expectEq obligation.data.value [("reason", code)] s!"{message}: diagnostic reason"
  | diagnostics => fail s!"{message}: expected one diagnostic, got {repr diagnostics}"

private def checkedUnsatTests : IO Unit := do
  let entry ← eligibleEntry
  let some request := entry.request | fail "an eligible queue entry carries a request"
  let (runner, seen) ← recordingRunner [answer "unsat"]
  let result ← expectDischarged runner entry "a pinned unsat"
  expectEq result.leanQueue.length 0 "a validated unsat does not queue the obligation for Lean"
  expectEq result.diagnostics.length 0 "a validated unsat raises no diagnostic"
  let record ← expectAt result.dischargeRecords 0 "the discharge record"

  -- The record is content-addressed: every input that determined the discharge
  -- is inside its address, so changing any of them changes the address.
  let address := canonicalDischargeRecord record
  expectTrue (address.length > 0) "a record has an address"
  for (other, field) in [
      ({ record with obligation := { record.obligation with bodyHash := "sha256:other" } },
        "body"),
      ({ record with smt2Hash := "0:" }, "script"),
      ({ record with profile := { defaultSolverProfile with version := "4.0.0" } }, "solver"),
      ({ record with evidenceHash := "0:" }, "evidence")] do
    expectTrue (canonicalDischargeRecord other != address)
      s!"a record differing in its {field} has a different address"

  -- It binds what the spec says a record binds.
  expectEq record.result "unsat" "the record states the result it was created from"
  expectEq record.obligation.obligationId entry.obligation.obligationId
    "the record binds the obligation"
  expectEq record.obligation.wordId testContext.wordId "the record binds the word"
  expectEq record.obligation.sourcePath testContext.source.path
    "the record binds the source location"
  expectEq record.requestIdentity (canonicalRequestIdentity request)
    "the record binds the request that was answered"
  expectEq record.normalisedFormulaHash (canonicalNormalisedFormula request.formula)
    "the record binds the formula the encoder consumed"
  expectEq record.solverExecutableDigest defaultSolverProfile.executableDigest
    "the record binds the pinned executable"
  expectEq record.invocationOptions defaultSolverProfile.invocationOptions
    "the record binds the pinned invocation options"
  expectEq record.translationRuleHashes defaultSmtProofBindings.translationRuleHashes
    "the record binds the translation rules"
  expectEq record.translationSoundnessProofHashes
    defaultSmtProofBindings.translationSoundnessProofHashes
    "the record binds the soundness proofs"

  -- And it rechecks: the request it names is the request the obligation
  -- rebuilds to.
  match recheckRecord entry.obligation record with
  | .ok rebuilt => expectEq rebuilt request "recheck rebuilds the request the record names"
  | .error failure => fail s!"a fresh record failed recheck: {repr failure}"

  -- One decision run, under the pinned options and the pinned bound.
  match ← seen.get with
  | [invocation] =>
      expectEq invocation.options defaultSolverProfile.invocationOptions
        "the invocation carries the pinned options, memory bound included"
      expectEq invocation.bound defaultSolverProfile.wallTimeMilliseconds
        "the invocation carries the pinned wall-clock bound"
      expectEq invocation.script request.smtLib
        "the invocation sends the request's own script"
      expectTrue ((invocation.script.splitOn "(get-model)").length == 1)
        "a decision run never asks for a model, so unsat is never an error"
  | invocations => fail s!"expected one invocation, got {repr invocations}"

private def validatedSatTests : IO Unit := do
  let entry ← refutableEntry
  let (runner, seen) ← recordingRunner
    [answer "sat", answer "sat\n((define-fun i0 () Int 1))"]
  let result ← expectDischarged runner entry "a validated sat"
  expectEq result.dischargeRecords.length 0 "a countermodel is never a discharge record"
  expectEq result.leanRecords.length 0 "a countermodel is never proof evidence"
  expectEq result.leanQueue.length 0 "a validated countermodel is not deferred to Lean"
  let diagnostic ← expectAt result.diagnostics 0 "the countermodel diagnostic"
  let obligation ← expectAt diagnostic.body.obligations 0 "the refuted obligation"
  expectEq obligation.status .failed "a validated countermodel is a failed refinement"
  expectTrue (obligation.data.value.any (fun pair => pair.1 == "model"))
    "the diagnostic carries the model that refuted the obligation"
  expectTrue (obligation.data.value.any (fun pair => pair.1 == "result" && pair.2 == "sat"))
    "the diagnostic names the solver result it came from"
  -- Deterministic: the same answer produces the same diagnostic, byte for byte.
  let (again, _) ← recordingRunner [answer "sat", answer "sat\n((define-fun i0 () Int 1))"]
  let repeated ← expectDischarged again entry "a repeated validated sat"
  expectEq repeated.diagnostics result.diagnostics
    "the same countermodel produces the same diagnostic"
  -- A model costs a second bounded run, and both are bounded.
  match ← seen.get with
  | [decision, model] =>
      expectEq decision.bound defaultSolverProfile.wallTimeMilliseconds
        "the decision run is bounded"
      expectEq model.bound defaultSolverProfile.wallTimeMilliseconds
        "the model run is bounded too"
      expectTrue ((model.script.splitOn "(get-model)").length == 2)
        "the second run is the one that asks for a model"
  | invocations => fail s!"expected a decision run and a model run, got {repr invocations}"

private def deferredOutcomeTests : IO Unit := do
  let entry ← eligibleEntry
  let refutable ← refutableEntry
  for (transcripts, reason, code, description) in [
      ([answer "unknown"], LeanEscalationReason.externalUnknown, "external-unknown",
        "an undecided answer"),
      ([{ answer "" with timedOut := true }],
        .externalTimeout defaultSolverProfile.wallTimeMilliseconds,
        s!"external-timeout:{defaultSolverProfile.wallTimeMilliseconds}",
        "a decision run that reached its bound"),
      ([answer "(error \"out of memory\")"], .externalResourceExhausted,
        "external-resource-exhausted", "a reported resource limit"),
      ([answer "maybe"], .externalMalformed, "external-malformed",
        "an answer outside the profile's vocabulary"),
      ([answer ""], .externalMalformed, "external-malformed", "silence"),
      ([{ answer "unsat" with outputLimitExceeded := true }], .externalMalformed,
        "external-malformed", "output past the runner's bound"),
      ([answer "unsat" 9], .externalCrash, "external-crash",
        "an answer with a non-zero exit"),
      ([answer "sat", answer "sat\n((define-fun i9 () Int 1))"], .externalMalformed,
        "external-malformed", "a model naming a symbol the request never declared"),
      ([answer "sat", { answer "" with timedOut := true }],
        .externalTimeout defaultSolverProfile.wallTimeMilliseconds,
        s!"external-timeout:{defaultSolverProfile.wallTimeMilliseconds}",
        "a model run that reached its bound")] do
    let (runner, _) ← recordingRunner transcripts
    let result ← expectDischarged runner entry description
    expectDeferred result reason code description
  -- A model that parses but does not refute the obligation is not a
  -- counterexample, and is deferred rather than believed.
  let (incomplete, _) ← recordingRunner
    [answer "sat", answer "sat\n((define-fun i0 () Int 7))"]
  let incompleteResult ← expectDischarged incomplete refutable "a model that does not refute"
  expectDeferred incompleteResult .invalidCountermodel "invalid-countermodel"
    "a model that does not refute"

private def untrustedResultTests : IO Unit := do
  let entry ← eligibleEntry
  let some request := entry.request | fail "an eligible queue entry carries a request"
  let identity := canonicalRequestIdentity request
  -- An `unsat` that has not been through the checked adapter is deferred, and
  -- the reason names which binding did not hold. Since `smt-discharge-record-recheck`
  -- the adapter runs at this boundary, so "unchecked" is exactly "did not pass
  -- one of these".
  for (result, reason, code, description) in [
      ({ profile := { defaultSolverProfile with version := "4.0.0" }
         requestIdentity := identity, outcome := ExternalOutcome.uncheckedUnsat "unsat" },
        LeanEscalationReason.externalProfileMismatch, "external-profile-mismatch",
        "an unsat from an unpinned profile"),
      ({ profile := defaultSolverProfile
         proofBindings := { defaultSmtProofBindings with translationRuleHashes := [] }
         requestIdentity := identity, outcome := .uncheckedUnsat "unsat" },
        .externalProofMismatch, "external-proof-mismatch",
        "an unsat carrying incomplete translation bindings"),
      ({ profile := defaultSolverProfile, requestIdentity := "request(0:)"
         outcome := .uncheckedUnsat "unsat" },
        .externalRequestIdentityMismatch, "external-request-identity-mismatch",
        "an unsat bound to another request"),
      ({ profile := defaultSolverProfile, requestIdentity := "", outcome := .uncheckedUnsat "unsat" },
        .externalRequestIdentityMismatch, "external-request-identity-mismatch",
        "an unsat bound to no request at all"),
      ({ profile := defaultSolverProfile, requestIdentity := identity
         outcome := .checkedUnsat "unsat" },
        .dischargeRecordRejected, "firth.smt.pre-promoted-result",
        "a result that arrives already promoted")] do
    expectDeferred (recordExternalOutcome "request-a" entry result) reason code description
  -- Nor does an unpinned binary get to answer at all: a refusal is not an
  -- outcome, so nothing it said reaches the boundary.
  for (digest, path, description) in [
      (some "sha256:00", some "/impostor/z3", "an executable that is not the pinned one"),
      (some defaultSolverProfile.executableDigest, none, "a pinned solver that is absent"),
      (none, some "/pinned/z3", "an executable whose digest cannot be established")] do
    let (runner, _) ← recordingRunner [answer "unsat"] (digest := digest) (path := path)
    match ← discharge runner entry with
    | .error _ => pure ()
    | .ok result => fail s!"{description} produced a result: {repr result}"

private def unsupportedInputTests : IO Unit := do
  -- An obligation the translator cannot express never reaches a solver: it is
  -- refused before invocation and escalated to Lean with the fragment named.
  let result := checkBodyRefinements "request-a"
    (premises [] [] [.worldSensitive "effect"])
  expectEq result.smtQueue.length 0 "an untranslatable obligation is never queued for SMT"
  expectEq result.dischargeRecords.length 0 "an untranslatable obligation creates no record"
  expectEq result.leanRecords.length 0 "an untranslatable obligation creates no proof record"
  let queued ← expectAt result.leanQueue 0 "the untranslatable obligation"
  expectEq queued.reason (.outsideSmtFragment .worldEffect)
    "an untranslatable obligation names the fragment that stopped it"
  let nonlinear := checkBodyRefinements "request-a"
    (premises [] [] [.nonlinear "x*y"])
  expectEq nonlinear.smtQueue.length 0 "a nonlinear obligation is never queued for SMT"
  let nonlinearQueued ← expectAt nonlinear.leanQueue 0 "the nonlinear obligation"
  expectEq nonlinearQueued.reason (.outsideSmtFragment .nonlinearArithmetic)
    "a nonlinear obligation names the fragment that stopped it"

def runTests : IO Unit := do
  checkedUnsatTests
  validatedSatTests
  deferredOutcomeTests
  untrustedResultTests
  unsupportedInputTests
  IO.println "all SMT adapter integration tests passed"

end Firth.AdapterIntegrationTest

def main : IO Unit := Firth.AdapterIntegrationTest.runTests
