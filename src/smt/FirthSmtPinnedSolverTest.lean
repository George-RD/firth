import elaborator.Firth.Refinement
import smt.Firth.SmtSolver

/-!
The positive, record-producing branch of the SMT slice, against the pinned
solver binary itself. This is the one test that admits a discharge record, and
it can only run on the platform the pin names: `FIRTH_SMT_SOLVER` must name
the z3 5.0.0 linux-arm64-glibc-2.38 executable whose digest is pinned in
`defaultSolverProfile`. CI runs it in the `smt-pinned-solver` job on an arm64
runner after verifying that digest with the host's own `sha256sum`; on any
other host `solvePinned` refuses, and
`src/smt/FirthSmtPinnedRefusalTest.lean` covers the refusals.

It lives with the solver tests because it is about the solver process, and it
drives the elaborator's result boundary because that boundary is where a
record is admitted or deferred: a driver that stopped at the solver could not
show that a pinned result is published while the same data through the
injected seam is not. It is run with `lake env lean --run`, not built as a
library module, so no library depends on it.

What it shows, in order: a provable obligation through `solvePinned` and
`recordExternalOutcome` yields exactly one discharge record and an empty Lean
queue; the same request through `solve` with a stub reporting the pinned
digest yields the same data and no record; a refutable obligation yields a
failed diagnostic carrying the countermodel; and `rerunPinned` on the record
confirms it and publishes it again through `recordRerunVerdict`, while the
same verdict's data through the injected seam does not.
-/

open Firth.Elaborator
open Firth.Elaborator.Refinement
open Firth.Elaborator.StackEffect
open Firth.Smt
open Firth.Smt.Solver

private def fail (message : String) : IO α := throw (IO.userError message)

private def expectEq [BEq α] [Repr α] (actual expected : α) (message : String) : IO Unit :=
  if actual == expected then pure ()
  else fail s!"{message}\nactual: {repr actual}\nexpected: {repr expected}"

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

/-- The queue entry for one body obligation built through the real pipeline. -/
private def queueEntry (pre semantics post : List Predicate) : IO SmtQueueEntry := do
  let result := checkBodyRefinements "request-a"
    { context := testContext
      precondition := { conjuncts := pre }
      bodySemantics := { conjuncts := semantics }
      declaredPostcondition := { conjuncts := post } }
  match result.smtQueue with
  | [entry] => pure entry
  | queue => fail s!"expected one SMT queue entry, got {repr queue}"

/-- A runner that reports the pinned digest and answers `unsat`: the test seam
saying everything a pinned process would, without being one. -/
private def stubRunner : SolverRunner :=
  { run := fun _ _ _ => pure { exitCode := 0, stdout := "unsat", stderr := "" }
    executableDigest := pure (some defaultSolverProfile.executableDigest)
    executablePath := pure (some "/pinned/z3") }

private def expectUnattested (result : PipelineResult) (message : String) : IO Unit := do
  expectEq result.dischargeRecords.length 0 s!"{message}: no record may be published"
  match result.leanQueue with
  | [queued] => expectEq queued.reason .unattestedProvenance s!"{message}: escalation reason"
  | queue => fail s!"{message}: expected one Lean obligation, got {repr queue}"
  match result.diagnostics with
  | [diagnostic] =>
      expectEq (diagnostic.body.obligations.map (·.data.value))
        [[("reason", "firth.smt.unattested-provenance")]] s!"{message}: diagnostic reason"
  | diagnostics => fail s!"{message}: expected one diagnostic, got {repr diagnostics}"

def main : IO Unit := do
  let some named ← IO.getEnv pinnedSolverVariable
    | fail s!"{pinnedSolverVariable} must name the pinned solver executable"
  IO.println s!"{pinnedSolverVariable}={named}"

  -- A provable obligation: 0 < x and y = x + 1 entail 0 < y.
  let provable ← queueEntry [.intLt (.literal 0) (.variable "x")]
    [.intEq (.variable "y") (.add (.variable "x") (.literal 1))]
    [.intLt (.literal 0) (.variable "y")]
  let some request := provable.request | fail "an eligible queue entry carries a request"
  let attested ← match ← solvePinned defaultSolverProfile request with
    | .ok attested => pure attested
    | .error refusal => fail s!"the pinned solver was refused: {repr refusal}"
  expectEq attested.provenance .pinnedProcess
    "a result from the pinned process carries the pinned provenance"
  expectEq attested.value.outcome (.uncheckedUnsat "unsat")
    "the pinned solver answers unsat to a provable obligation"
  let discharged := recordExternalOutcome "request-a" provable attested
  expectEq discharged.leanQueue.length 0 "a pinned unsat does not queue the obligation for Lean"
  expectEq discharged.diagnostics.length 0 "a pinned unsat raises no diagnostic"
  let record ← match discharged.dischargeRecords with
    | [record] => pure record
    | records => fail s!"expected exactly one discharge record, got {repr records}"
  expectEq record.solverExecutableDigest defaultSolverProfile.executableDigest
    "the record binds the pinned executable digest"
  expectEq record.requestIdentity (canonicalRequestIdentity request)
    "the record binds the request that was answered"
  match recheckRecord provable.obligation record with
  | .ok rebuilt => expectEq rebuilt request "the published record rechecks to its request"
  | .error failure => fail s!"the published record failed recheck: {repr failure}"
  IO.println "a pinned unsat was published as one discharge record"

  -- The same request through the injected seam: identical data, no record.
  let injectedResult ← match ← solve stubRunner defaultSolverProfile request with
    | .ok attested => pure attested
    | .error refusal => fail s!"the stub runner was refused: {repr refusal}"
  expectEq injectedResult.value attested.value
    "a stub reporting the pin yields the same result data as the pinned process"
  expectEq injectedResult.provenance .injectedRunner "the stub is the test seam"
  expectUnattested (recordExternalOutcome "request-a" provable injectedResult)
    "the same data through an injected runner"
  IO.println "the same unsat through an injected runner was deferred"

  -- A refutable obligation: x = 1 does not entail x < 0, and the model says so.
  let refutable ← queueEntry [.intEq (.variable "x") (.literal 1)] []
    [.intLt (.variable "x") (.literal 0)]
  let some refutableRequest := refutable.request | fail "a refutable queue entry carries a request"
  let refuted ← match ← solvePinned defaultSolverProfile refutableRequest with
    | .ok attested => pure attested
    | .error refusal => fail s!"the pinned solver was refused a refutable obligation: {repr refusal}"
  match refuted.value.outcome with
  | .sat model => expectEq model.integers [("x", (1 : Int))] "the pinned solver's model refutes"
  | outcome => fail s!"the pinned solver did not refute a refutable obligation: {repr outcome}"
  let failed := recordExternalOutcome "request-a" refutable refuted
  expectEq failed.dischargeRecords.length 0 "a countermodel is never a discharge record"
  expectEq failed.leanQueue.length 0 "a validated countermodel is not deferred to Lean"
  match failed.diagnostics with
  | [diagnostic] =>
      match diagnostic.body.obligations with
      | [obligation] =>
          expectEq obligation.status .failed "a validated countermodel is a failed refinement"
          expectEq (obligation.data.value.any fun pair => pair.1 == "model") true
            "the diagnostic carries the countermodel"
      | obligations => fail s!"expected one refuted obligation, got {repr obligations}"
  | diagnostics => fail s!"expected one countermodel diagnostic, got {repr diagnostics}"
  IO.println "a pinned sat was reported as a failed refinement with its countermodel"

  -- The record reruns through the pinned process and is published again; the
  -- same verdict's data through the injected seam is not.
  let verdict ← rerunPinned (obligationBinding provable.obligation) provable.obligation.formula
    record
  expectEq verdict.provenance .pinnedProcess "a verdict from the pinned rerun is pinned"
  match verdict.value with
  | .rechecked rebuilt => expectEq rebuilt record "the pinned rerun rebuilds the same record"
  | other => fail s!"the pinned rerun did not confirm the record: {repr other}"
  let rerun := recordRerunVerdict "request-a" provable.obligation verdict
  expectEq rerun.dischargeRecords [record] "a pinned rechecked verdict publishes the record"
  expectEq rerun.leanQueue.length 0 "a pinned rechecked verdict queues nothing for Lean"
  expectUnattested (recordRerunVerdict "request-a" provable.obligation (injected verdict.value))
    "the same verdict through the injected seam"
  IO.println "all pinned solver discharges passed"
