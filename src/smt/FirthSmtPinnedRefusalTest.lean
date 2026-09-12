import smt.Firth.SmtSolver

/-!
Refusals of the pinned solver path on a host that does not have the pinned
binary. Run on every CI host with
`lake env lean --run src/smt/FirthSmtPinnedRefusalTest.lean`, twice: once with
`FIRTH_SMT_SOLVER` unset and once with it naming an executable that is not the
pinned solver (`/usr/bin/python3` in CI).

`solvePinned` and `rerunPinned` are the only producers of `pinnedProcess`, so
what this shows is that they cannot be reached with anything but the pinned
binary: a missing executable, a relative path and an executable whose digest
is not the pin are all refused before any invocation. The last case uses a
shell script that answers `unsat`, and the script is first run directly
through `processRunner` to show that it does answer `unsat`, so the refusal is
the digest pin doing its work rather than a broken fixture. No SMT solver is
involved, and nothing here can produce a discharge record.
-/

open Firth.Smt
open Firth.Smt.Solver

private def fail (message : String) : IO α := throw (IO.userError message)

private def ensure (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else fail message

private def obligationFormula : Formula :=
  { premises := [.intLt (.literal 0) (.variable "x")]
    conclusions := [.intLt (.literal 0) (.add (.variable "x") (.literal 1))] }

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

private def expectMissing (label : String) (result : Except Refusal AttestedResult) : IO Unit :=
  match result with
  | .error (.executableMissing _) => IO.println s!"refused {label}: executable missing"
  | .error refusal => fail s!"{label} was refused for another reason: {repr refusal}"
  | .ok attested =>
      fail s!"{label} produced a result with provenance {repr attested.provenance}"

private def expectDigestRefusal (label : String) (result : Except Refusal AttestedResult) :
    IO Unit :=
  match result with
  | .error (.executableDigestMismatch expected actual) => do
      ensure (expected == defaultSolverProfile.executableDigest)
        s!"{label}: the refusal names the pinned digest"
      ensure (actual != expected && actual.startsWith "sha256:")
        s!"{label}: the refusal names the impostor's own digest"
      IO.println s!"refused {label}: digest {actual} is not the pin"
  | result =>
      fail s!"{label} was not refused for its digest: {repr result}"

def main : IO Unit := do
  let request ← match checkedSmtRequest defaultSolverProfile obligationFormula with
    | .ok request => pure request
    | .error error => fail s!"the checked adapter rejected a QF_LIA obligation: {repr error}"

  -- Explicit paths never consult the environment.
  expectMissing "an absent explicit path"
    (← solvePinned defaultSolverProfile request (some "/nonexistent/firth-z3"))
  expectMissing "a relative explicit path" (← solvePinned defaultSolverProfile request (some "z3"))

  -- The environment: unset means no executable; set to anything that is not
  -- the pinned binary means refused, for its digest if it exists and as
  -- missing if it does not.
  match ← IO.getEnv pinnedSolverVariable with
  | none => expectMissing s!"{pinnedSolverVariable} unset" (← solvePinned defaultSolverProfile request)
  | some named =>
      IO.println s!"{pinnedSolverVariable}={named}"
      match ← solvePinned defaultSolverProfile request with
      | .error (.executableMissing _) => IO.println s!"refused {named}: executable missing"
      | .ok attested =>
          fail s!"{pinnedSolverVariable} names an executable the pin accepted \
            ({repr attested.provenance}); this refusal test needs an executable that \
            is not the pinned solver"
      | result => expectDigestRefusal named result

  -- An executable that answers unsat is still refused when its digest is not
  -- the pin, and so is a rerun through it.
  IO.FS.withTempDir fun directory => do
    let script := directory / "impostor-z3"
    IO.FS.writeFile script "#!/bin/sh\ncat > /dev/null\necho unsat\n"
    let chmod ← IO.Process.output { cmd := "chmod", args := #["755", script.toString] }
    ensure (chmod.exitCode == 0) "the impostor script could not be made executable"
    let transcript ← (processRunner script).run defaultSolverProfile.invocationOptions
      request.smtLib defaultSolverProfile.wallTimeMilliseconds
    ensure (!transcript.timedOut && transcript.exitCode == 0 && transcript.stdout == "unsat\n")
      s!"the impostor script must answer unsat when run directly, got {repr transcript}"
    expectDigestRefusal "an executable that answers unsat"
      (← solvePinned defaultSolverProfile request (some script))
    let raw : SmtResult :=
      { profile := defaultSolverProfile
        proofBindings := request.proofBindings
        requestIdentity := canonicalRequestIdentity request
        outcome := .uncheckedUnsat "unsat" }
    let record ← match makeDischargeRecord testBinding request raw with
      | .ok record => pure record
      | .error failure => fail s!"could not build a record: {repr failure}"
    let verdict ← rerunPinned testBinding obligationFormula record (some script)
    match verdict.value with
    | .refused (.executableDigestMismatch _ _) =>
        IO.println "refused a rerun through an executable that answers unsat but is not the pin"
    | other => fail s!"the pinned rerun accepted an impostor: {repr other}"
  IO.println "all pinned solver refusals passed"
