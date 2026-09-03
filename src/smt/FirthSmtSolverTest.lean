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

def runTests : IO Unit := do
  classificationTests
  modelScriptTests
  parseModelTests
  refusalTests
  solveTests
  IO.println "all SMT solver runner tests passed"

end Firth.SmtSolverTest

def main : IO Unit := Firth.SmtSolverTest.runTests
