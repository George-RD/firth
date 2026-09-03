import elaborator.Firth.Refinement
import smt.Firth.SmtSolver

/-!
Integrity of SMT discharge records, end to end.

`spec/smt/refinement-discharge-architecture.md` §3 says a stale, missing or
mismatched record is an open obligation and not a cached success, and §5 says a
changed body, predicate definition, translation dependency, solver profile or
Lean revision invalidates the affected records. This suite is where that is
enforced rather than described: every way a record can stop matching what the
obligation rebuilds to is driven through the real recheck, the real rerun and
the real refinement-discharge result boundary, and the assertion is on what
crosses that boundary.

It lives with the elaborator because the boundary does. `Firth.Smt` owns the
record and its recheck, `Firth.Smt.Solver` owns the rerun, and only the
elaborator owns the `PipelineResult` all three have to reach; a suite in
`src/smt` reaching back for it would invert the dependency.

Every case runs against an injected runner, so a host with no solver runs the
whole suite. That is not a convenience: the pinned profile names one platform
and one executable digest, so most hosts cannot run the pinned solver even in
principle.
-/

namespace Firth.RecordIntegrityTest

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

private def xPositive : Predicate := .intLt (.literal 0) (.variable "x")
private def successor : Predicate := .intEq (.variable "y") (.add (.variable "x") (.literal 1))
private def yPositive : Predicate := .intLt (.literal 0) (.variable "y")

/-- The queue entry the whole suite discharges: an open verification condition
the direct procedure cannot decide, so it is eligible for the checked adapter. -/
private def queueEntry : IO SmtQueueEntry := do
  let result := checkBodyRefinements "request-a"
    { context := testContext
      precondition := { conjuncts := [xPositive] }
      bodySemantics := { conjuncts := [successor] }
      declaredPostcondition := { conjuncts := [yPositive] } }
  match result.smtQueue with
  | [entry] => pure entry
  | queue => fail s!"expected one SMT queue entry, got {repr queue}"

/-- The pinned answer the record is built from, as it arrives from the runner:
unchecked, and promoted only by the boundary. -/
private def pinnedResult (entry : SmtQueueEntry) : SmtResult :=
  { profile := entry.profile
    requestIdentity :=
      match entry.request with
      | some request => canonicalRequestIdentity request
      | none => ""
    outcome := .uncheckedUnsat "unsat" }

/-- Drives one record through the real rerun and the real result boundary, and
returns what crossed it. -/
private def rerun (runner : SolverRunner) (obligation : Obligation)
    (record : DischargeRecord) (formula : Option Formula := none) : IO PipelineResult := do
  let verdict ← rerunDischargeRecord runner (obligationBinding obligation)
    (formula.getD obligation.formula) record
  pure (recordRerunVerdict "request-a" obligation verdict)

/-- Asserts that a rerun was a deferred non-success naming `code`, and that
nothing reached the discharge boundary. -/
private def expectDeferred (result : PipelineResult) (code : String)
    (message : String) : IO Unit := do
  expectEq result.dischargeRecords.length 0 s!"{message}: no record may be exposed"
  expectEq result.leanRecords.length 0 s!"{message}: no proof record may be created"
  match result.leanQueue with
  | [queued] =>
      expectEq queued.reason .dischargeRecordRejected s!"{message}: Lean escalation reason"
  | queue => fail s!"{message}: expected one Lean obligation, got {repr queue}"
  match result.diagnostics with
  | [diagnostic] =>
      let entry ← expectAt diagnostic.body.obligations 0 message
      expectEq entry.status .deferred s!"{message}: deferred status"
      expectEq entry.data.value [("reason", code)] s!"{message}: diagnostic reason"
  | diagnostics => fail s!"{message}: expected one diagnostic, got {repr diagnostics}"

private def driftTests (entry : SmtQueueEntry) (record : DischargeRecord) : IO Unit := do
  let obligation := entry.obligation
  let runner ← stubRunner [answer "unsat"]
  -- A record that still matches is confirmed, so every refusal below is about
  -- the mutation and not about the fixture.
  expectEq (← rerun runner obligation record).dischargeRecords.length 1
    "an unmutated record is confirmed by a rerun"
  for (mutated, code, reason) in [
      ({ record with obligation := { record.obligation with wordId := "other" } },
        "firth.smt.record-stale", "a record for another word"),
      ({ record with obligation := { record.obligation with bodyHash := "sha256:other" } },
        "firth.smt.record-stale", "a record for another body"),
      ({ record with obligation := { record.obligation with specHash := "sha256:other" } },
        "firth.smt.record-stale", "a record for another specification"),
      ({ record with
         obligation := { record.obligation with predicateDefinitionHashes := [] } },
        "firth.smt.record-stale", "a record for another predicate definition"),
      ({ record with obligation := { record.obligation with toolchainRevision := "firth-b" } },
        "firth.smt.record-stale", "a record from another toolchain revision"),
      ({ record with obligation := { record.obligation with sourceStopColumn := 99 } },
        "firth.smt.record-stale", "a record naming another source span"),
      ({ record with result := "sat" },
        "firth.smt.result-not-unsat", "a record that does not carry an unsat"),
      ({ record with profile := { defaultSolverProfile with version := "4.0.0" } },
        "firth.smt.profile-drift", "a record produced under another solver version"),
      ({ record with profile := { defaultSolverProfile with solverId := "cvc5" } },
        "firth.smt.profile-drift", "a record produced by another solver"),
      ({ record with solverExecutableDigest := "sha256:00" },
        "firth.smt.digest-drift", "a record naming another executable"),
      ({ record with invocationOptions := ["-in"] },
        "firth.smt.option-drift", "a record produced under other invocation options"),
      ({ record with solverId := "cvc5" },
        "firth.smt.record-tampered", "a record whose solver name was edited"),
      ({ record with solverVersion := "4.0.0" },
        "firth.smt.record-tampered", "a record whose solver version was edited"),
      ({ record with translationRuleHashes := ["sha256:x"] },
        "firth.smt.translation-drift", "a record produced under other translation rules"),
      ({ record with translationRuleHashes := [] },
        "firth.smt.translation-drift", "a record naming no translation rules"),
      ({ record with translationSoundnessProofHashes := ["sha256:x"] },
        "firth.smt.translation-drift", "a record produced under other soundness proofs"),
      ({ record with translationSoundnessProofHashes := [] },
        "firth.smt.translation-drift", "a record naming no soundness proofs"),
      ({ record with
         translationSoundnessProofHashes :=
           defaultSmtProofBindings.translationSoundnessProofHashes.drop 1 },
        "firth.smt.translation-drift", "a record missing one soundness proof"),
      ({ record with normalisedFormulaHash := "formula(0[]0[])" },
        "firth.smt.record-tampered", "a record naming another formula"),
      ({ record with smt2Hash := "0:" },
        "firth.smt.record-tampered", "a record naming another script"),
      ({ record with requestIdentity := "request(0:)" },
        "firth.smt.request-mismatch", "a record naming another request")] do
    let stub ← stubRunner [answer "unsat"]
    expectDeferred (← rerun stub obligation mutated) code reason

private def untranslatableTests (entry : SmtQueueEntry) (record : DischargeRecord) : IO Unit := do
  -- An obligation that no longer translates cannot be rechecked at all, and
  -- that is a deferred non-success rather than a silent cache hit.
  let worldFormula : Formula :=
    { premises := [.worldSensitive "effect"], conclusions := [.truth] }
  let worldRecord := { record with
    normalisedFormulaHash := canonicalNormalisedFormula worldFormula }
  let runner ← stubRunner [answer "unsat"]
  expectDeferred (← rerun runner entry.obligation worldRecord (some worldFormula))
    "firth.smt.untranslatable" "an obligation outside the supported fragment"

private def rerunAnswerTests (entry : SmtQueueEntry) (record : DischargeRecord) : IO Unit := do
  let obligation := entry.obligation
  -- The record's inputs all hold, and the rerun still decides what happens.
  for (transcripts, code, reason) in [
      ([answer "unknown"], "firth.smt.not-unsat", "a rerun that no longer decides"),
      ([answer "sat", answer "sat\n((define-fun i0 () Int 5))"],
        "firth.smt.not-unsat", "a rerun that disproves the obligation"),
      ([answer "maybe"], "firth.smt.not-unsat", "a rerun that answers outside the vocabulary"),
      ([{ answer "" with timedOut := true }],
        "firth.smt.not-unsat", "a rerun that reached its wall-clock bound"),
      ([answer "(error \"out of memory\")"],
        "firth.smt.not-unsat", "a rerun that exhausted its resources"),
      ([answer "unsat" 1], "firth.smt.not-unsat", "a rerun that crashed after answering")] do
    let stub ← stubRunner transcripts
    expectDeferred (← rerun stub obligation record) code reason
  -- A solver that is not the pinned solver never gets to answer.
  let impostor ← stubRunner [answer "unsat"] (digest := some "sha256:00")
  expectDeferred (← rerun impostor obligation record)
    "firth.smt.executable-digest-mismatch" "a solver that is not the pinned one"
  let absent ← stubRunner [answer "unsat"] (path := none)
  expectDeferred (← rerun absent obligation record)
    "firth.smt.executable-missing" "a pinned solver that is not installed"
  let undigested ← stubRunner [answer "unsat"] (digest := none)
  expectDeferred (← rerun undigested obligation record)
    "firth.smt.digest-unavailable" "a solver whose identity cannot be established"

private def evidenceTests (entry : SmtQueueEntry) (record : DischargeRecord) : IO Unit := do
  let obligation := entry.obligation
  let some request := entry.request | fail "an eligible queue entry carries a request"
  -- An unchecked unsat is not evidence, however well-formed everything else is.
  match makeDischargeRecord (obligationBinding obligation) request (pinnedResult entry) with
  | .error .notUnsat => pure ()
  | result => fail s!"an unchecked unsat produced a record: {repr result}"
  -- Nor is a result that arrives claiming to have been checked elsewhere.
  let prePromoted := recordExternalOutcome "request-a" entry
    { pinnedResult entry with outcome := .checkedUnsat "unsat" }
  expectDeferred prePromoted "firth.smt.pre-promoted-result" "a pre-promoted result"
  -- Incomplete proof bindings are refused at promotion, before a record exists.
  for (bindings, reason) in [
      ({ defaultSmtProofBindings with translationSoundnessProofHashes := [] },
        "no soundness proofs"),
      ({ defaultSmtProofBindings with translationRuleHashes := [] }, "no translation rules"),
      ({ defaultSmtProofBindings with
         translationRuleHashes := defaultSmtProofBindings.translationRuleHashes.drop 1 },
        "one translation rule missing")] do
    match checkUnsat request { pinnedResult entry with proofBindings := bindings } with
    | .error .proofBindingsMismatch => pure ()
    | result => fail s!"a result carrying {reason} was promoted: {repr result}"
  -- And the record that does exist is the one the rerun confirms.
  expectEq record.translationSoundnessProofHashes
    defaultSmtProofBindings.translationSoundnessProofHashes
    "a record binds the soundness proofs it was produced under"
  expectTrue (record.translationSoundnessProofHashes.length >= 3)
    "the soundness bindings cover the encoder, the serialiser and the adapter"

def runTests : IO Unit := do
  let entry ← queueEntry
  let discharged := recordExternalOutcome "request-a" entry (pinnedResult entry)
  let record ← expectAt discharged.dischargeRecords 0 "the fixture's discharge record"
  driftTests entry record
  untranslatableTests entry record
  rerunAnswerTests entry record
  evidenceTests entry record
  IO.println "all SMT record integrity tests passed"

end Firth.RecordIntegrityTest

def main : IO Unit := Firth.RecordIntegrityTest.runTests
