import smt.Firth.SmtBoundary

/-!
Bounded invocation of the pinned solver, and strict classification of what it
says.

`spec/smt/refinement-discharge-architecture.md` §6 makes the pin mandatory:
the solver's identity, version, executable digest, invocation options and
resource bounds are part of the toolchain lockfile and of every discharge
record. This module is where those become operational rather than declarative.

Four properties shape the design.

*The invocation is refused before it happens* when anything about the pinned
identity does not hold: an unrecognised profile, a missing executable, a
digest that does not match the pin, or a request that does not rebuild to
itself. A solver that is not the pinned solver is not a weaker oracle, it is
a different one, and nothing it says may enter evidence.

*Classification is total and deterministic.* Every transcript maps to exactly
one `ExternalOutcome`, and everything that is not an answer the profile
supports maps to a deferred outcome rather than to silence. A bare `unsat`
maps to `uncheckedUnsat`: promoting it belongs to the checked adapter in
`SmtBoundary`, and doing it here would put an unrechecked result into evidence.
The second, model-fetching run is classified by the same rule as the decision
run before its output is parsed, so a crash, a resource limit or a changed
answer on that run is never turned into a counterexample.

*The runner is injected, and the seam is visible in the type.* `SolverRunner`
is a seam, so classification, model parsing and the refusal rules are all
testable without a fetched binary on a particular platform, and `lake test`
stays reproducible on a host that has no solver at all. `processRunner` is the
production implementation; nothing else in the module spawns a process, and
`solvePinned` is its only production caller. Every result and every rerun
verdict leaves this module wrapped in `Attested`, whose constructor is private
to this module: the wrapper says which path produced the value, and only
`solvePinned` and `rerunPinned`, which resolve the pinned executable, verify
its digest and spawn it in this process, produce `Provenance.pinnedProcess`.
A caller-supplied runner, however faithfully it reports the pinned digest,
produces `Provenance.injectedRunner`, and the refinement boundary admits a
discharge record only from the former. The digest pin authenticates the
binary; the sealed type authenticates that the pin was actually exercised
here. `private` is a naming discipline rather than a proof: in-repository
metaprogramming around the mangled constructor name is refused by
`tools/loop/check_smt_attestation.py`, and out-of-repository Lean callers are
outside the trusted computing base.

A model is fetched by a second bounded invocation rather than by appending
`(get-model)` to the decision script, because a solver answering `unsat` to a
script containing `(get-model)` emits an error line, and tolerating that would
blunt exactly the malformed-output classification this module exists to make
sharp. The decision script is therefore unchanged, and its serialiser theorems
still describe the bytes that are sent.
-/

namespace Firth.Smt.Solver

open Firth.Smt

/-- One completed invocation, in the only terms a record may quote. A measured
duration is deliberately absent: it would make an otherwise deterministic
record vary between runs. -/
structure Transcript where
  /-- Process exit code. -/
  exitCode : UInt32
  /-- Captured standard output, bounded by the runner. -/
  stdout : String
  /-- Captured standard error, bounded by the runner. -/
  stderr : String
  /-- Whether the wall-clock bound was reached before exit. -/
  timedOut : Bool := false
  /-- Whether the runner's output bound was reached. -/
  outputLimitExceeded : Bool := false
  deriving Repr, BEq, Inhabited

/-- The bounded invocation seam.

`run` receives the pinned invocation options, the script to feed on standard
input, and the wall-clock bound in milliseconds. -/
structure SolverRunner where
  /-- Runs one bounded invocation. -/
  run : List String → String → Nat → IO Transcript
  /-- The digest of the pinned executable, or `none` when it cannot be
  established. -/
  executableDigest : IO (Option String)
  /-- Whether the pinned executable is present. -/
  executablePath : IO (Option String)

/-- Which path in this module produced a value.

The two cases are not two grades of trust in the same runner; they are two
different producers. `pinnedProcess` means `solvePinned` or `rerunPinned`
resolved the pinned executable, verified its digest against the pin and
spawned it in this process. `injectedRunner` means a caller supplied the
`SolverRunner`, or the value was wrapped by `injected`; nothing about it has
been established here, whatever digest the runner reported. -/
inductive Provenance where
  /-- Produced by `solvePinned` or `rerunPinned`: a digest-verified executable,
  spawned here. -/
  | pinnedProcess
  /-- Produced through a caller-supplied `SolverRunner`, or by `injected`: a
  test seam that never admits a discharge record. -/
  | injectedRunner
  deriving Repr, BEq, DecidableEq

/-- A value together with the provenance of the path that produced it.

The constructor is private to this module, which is the one module that
spawns the solver. Outside it a caller can read both fields and can obtain an
`injectedRunner` value through `injected`, but cannot build a `pinnedProcess`
value by any construction the elaborator accepts: the anonymous constructor,
structure instance notation, the named constructor and `with` updates all fail
to elaborate. That is what lets the refinement boundary take `provenance` as a
statement about this process rather than as a field a caller filled in.

`private` is a naming discipline: the constructor still exists under a mangled
name, and metaprogramming could reach it. In this repository
`tools/loop/check_smt_attestation.py` refuses such constructions, the source
envelope binds every Lean file, and the compiled proof-module manifest binds
the built module; Lean callers outside the repository are outside the trusted
computing base. -/
structure Attested (α : Type) where
  private mk ::
  /-- Which path produced `value`. -/
  provenance : Provenance
  /-- The result or verdict itself. -/
  value : α
  deriving Repr, BEq

/-- A solver result and the provenance of the path that produced it. -/
abbrev AttestedResult := Attested SmtResult

/-- A rerun verdict and the provenance of the path that produced it. -/
abbrev AttestedVerdict := Attested RecheckVerdict

/-- Wraps a value as coming from a test seam. This is the only way outside
this module to build an `Attested` value, and what it builds never admits a
discharge record: the refinement boundary defers it with
`unattestedProvenanceCode`. -/
def injected (value : α) : Attested α := ⟨.injectedRunner, value⟩

/-- The stable diagnostic code for a result that passed every metadata check
but was not produced by the pinned process. -/
def unattestedProvenanceCode : String := "firth.smt.unattested-provenance"

/-- The environment variable that names the pinned executable when no explicit
path is given. -/
def pinnedSolverVariable : String := "FIRTH_SMT_SOLVER"

/-- Resolves where the pinned executable is expected to be.

An explicit absolute path wins. Otherwise `FIRTH_SMT_SOLVER` must hold an
absolute path. A relative path, whether explicit or from the environment, is
refused rather than resolved against the working directory or searched on
`PATH`: which file is meant must not depend on where the process was started.
Resolution says nothing about what is at the path; only the digest pin,
verified by `verifyPin` before any invocation, authenticates what is found
there. -/
def pinnedExecutable (explicit : Option System.FilePath := none) :
    IO (Option System.FilePath) := do
  let candidate ← match explicit with
    | some path => pure (some path)
    | none => do
        match ← IO.getEnv pinnedSolverVariable with
        | some value => pure (some (System.FilePath.mk value))
        | none => pure none
  match candidate with
  | some path =>
      if path.toString.isEmpty || !path.isAbsolute then pure none else pure (some path)
  | none => pure none

private def firstLine (text : String) : String :=
  (text.splitOn "\n").headD "" |>.trim

/-- Whether the transcript reports the solver giving up on a resource bound
rather than on the problem. The pinned profile passes `-memory:` and `-T:`, so
the solver may report the limit itself before the runner's own bound fires. -/
private def containsSubstring (haystack needle : String) : Bool :=
  (haystack.splitOn needle).length > 1

private def reportsResourceLimit (transcript : Transcript) : Bool :=
  let haystack := transcript.stdout ++ "\n" ++ transcript.stderr
  containsSubstring haystack "memory" || containsSubstring haystack "canceled" ||
    containsSubstring haystack "resource"

/-- Classifies one decision-script transcript.

The mapping is total: an answer outside the profile's vocabulary is
`malformed`, not a silent deferral, and a bare `unsat` is `uncheckedUnsat`
because nothing here has rechecked it. -/
def classifyTranscript (profile : SolverProfile) (transcript : Transcript) :
    ExternalOutcome :=
  if transcript.timedOut then
    .timeout profile.wallTimeMilliseconds
  else if transcript.outputLimitExceeded then
    .malformed "output limit exceeded"
  else if reportsResourceLimit transcript then
    .resourceExhausted
  else
    match firstLine transcript.stdout with
    | "unsat" =>
        if transcript.exitCode == 0 then .uncheckedUnsat transcript.stdout.trim
        else .crashed s!"exit {transcript.exitCode}"
    | "sat" =>
        if transcript.exitCode == 0 then .sat { integers := [], booleans := [] }
        else .crashed s!"exit {transcript.exitCode}"
    | "unknown" =>
        if transcript.exitCode == 0 then .unknown
        else .crashed s!"exit {transcript.exitCode}"
    | answer =>
        if transcript.exitCode != 0 then
          .crashed s!"exit {transcript.exitCode}: {firstLine transcript.stderr}"
        else if answer.isEmpty then
          .malformed "empty answer"
        else
          .malformed s!"unrecognised answer: {answer}"

/-- The model script: the decision script with `(get-model)` before `(exit)`.

Sent only after a `sat` answer, so a solver answering `unsat` never sees a
`(get-model)` it must reject. -/
def modelScript (request : SmtRequest) : String :=
  String.intercalate "\n"
    ((request.smtLib.splitOn "\n").flatMap fun line =>
      if line == "(exit)" then ["(get-model)", "(exit)"] else [line])

private def tokenise (text : String) : List String :=
  let spaced := text.foldl (init := "") fun out character =>
    if character == '(' || character == ')' then out ++ " " ++ character.toString ++ " "
    else out ++ character.toString
  (spaced.splitOn " ").map String.trim
    |>.flatMap (fun token => (token.splitOn "\n").map String.trim)
    |>.filter (fun token => !token.isEmpty)

/-- A non-empty run of decimal digits, as a natural number. -/
private def parseDigits (token : String) : Option Nat :=
  if token.isEmpty || !token.all Char.isDigit then none else some token.toNat!

/-- A bare integer token: `digits` or `-digits`. -/
private def parseInt (token : String) : Option Int :=
  if token.isEmpty then none
  else if token.front == '-' then
    (parseDigits (token.drop 1).copy).map fun digits => -(Int.ofNat digits)
  else (parseDigits token).map Int.ofNat

private def sourceName (bindings : List SmtBinding) (sort : SmtSort) (symbol : String) :
    Option String :=
  (bindings.find? fun binding => binding.sort == sort && binding.symbol == symbol).map
    (·.sourceName)

/-- Parses a `(get-model)` response into a valuation over source names.

The grammar accepted is deliberately narrow, and it is a grammar rather than a
scan for entries:

```
model := "(" ["model"] entry* ")" EOF
entry := "(" "define-fun" symbol "(" ")" ("Int" int | "Bool" ("true" | "false")) ")"
int   := digits | "-" digits | "(" "-" digits ")"
```

There is exactly one outer list; the `model` keyword some solvers emit is
accepted only immediately after the opening paren; nothing may follow the
closing paren; a bare delimiter anywhere else is an error rather than something
to skip; every symbol must have been declared by the request for the sort it is
defined at; and a symbol defined twice is an error. Anything else is a parse
failure, which the caller classifies as malformed output rather than as a
counterexample. -/
def parseModel (bindings : List SmtBinding) (text : String) : Except String Valuation := do
  let mut integers : List (String × Int) := []
  let mut booleans : List (String × Bool) := []
  let mut defined : List String := []
  let opened ← match tokenise text with
    | "(" :: rest => pure rest
    | [] => throw "model: empty response"
    | token :: _ => throw s!"model: expected ( but found {token}"
  let mut tokens := match opened with
    | "model" :: rest => rest
    | rest => rest
  let mut closed := false
  while !closed do
    match tokens with
    | ")" :: rest =>
        closed := true
        tokens := rest
    | "(" :: "define-fun" :: symbol :: "(" :: ")" :: sort :: rest =>
        if defined.contains symbol then throw s!"model: {symbol} is defined twice"
        defined := defined ++ [symbol]
        match sort with
        | "Int" =>
            let (value, rest) ←
              match rest with
              | "(" :: "-" :: digits :: ")" :: rest =>
                  match parseDigits digits with
                  | some magnitude => pure (-(Int.ofNat magnitude), rest)
                  | none => throw s!"model: {symbol} has a non-integer value"
              | "(" :: _ => throw s!"model: {symbol} has a non-integer value"
              | token :: rest =>
                  match parseInt token with
                  | some value => pure (value, rest)
                  | none => throw s!"model: {symbol} has a non-integer value"
              | [] => throw "model: truncated integer definition"
            let some name := sourceName bindings .integer symbol
              | throw s!"model: {symbol} was never declared"
            match rest with
            | ")" :: rest =>
                integers := integers ++ [(name, value)]
                tokens := rest
            | _ => throw s!"model: {symbol} is not closed"
        | "Bool" =>
            let (flag, rest) ←
              match rest with
              | "true" :: rest => pure (true, rest)
              | "false" :: rest => pure (false, rest)
              | _ :: _ => throw s!"model: {symbol} has a non-boolean value"
              | [] => throw "model: truncated boolean definition"
            let some name := sourceName bindings .boolean symbol
              | throw s!"model: {symbol} was never declared"
            match rest with
            | ")" :: rest =>
                booleans := booleans ++ [(name, flag)]
                tokens := rest
            | _ => throw s!"model: {symbol} is not closed"
        | sort => throw s!"model: unsupported sort {sort}"
    | "(" :: "define-fun" :: _ => throw "model: truncated definition"
    | [] => throw "model: unterminated model"
    | token :: _ => throw s!"model: unexpected token {token}"
  match tokens with
  | [] => pure { integers, booleans }
  | token :: _ => throw s!"model: unexpected token {token} after the model"

/-- The host digest tools this runner is willing to use, in order. -/
private def digestTools : List (System.FilePath × Array String) :=
  [ (System.FilePath.mk "/usr/bin/shasum", #["-a", "256"])
  , (System.FilePath.mk "/usr/bin/sha256sum", #[])
  , (System.FilePath.mk "/bin/sha256sum", #[]) ]

private def selectDigestTool :
    List (System.FilePath × Array String) → IO (Option (System.FilePath × Array String))
  | [] => pure none
  | candidate :: rest => do
      if ← candidate.1.pathExists then pure (some candidate) else selectDigestTool rest

private def executableDigestOf (executable : System.FilePath) : IO (Option String) := do
  -- The host's own digest tool establishes the executable's identity, the same
  -- way `Refinement.lean` establishes the proof modules'. Hashing it in Lean
  -- would put a second hash implementation on this path for no gain: the value
  -- is compared with a pin, never published as evidence itself.
  match ← selectDigestTool digestTools with
  | none => return none
  | some tool =>
      let output ← IO.Process.output
        { cmd := tool.1.toString, args := tool.2.push executable.toString }
      if output.exitCode != 0 then return none
      let digest := (output.stdout.splitOn " ").headD "" |>.trim
      if digest.isEmpty then return none
      return some s!"sha256:{digest}"

private partial def readBoundedText (handle : IO.FS.Handle) (limit : Nat) :
    IO (Option String) := do
  let rec read (bytes : ByteArray) (overflow : Bool) : IO (Option String) := do
    let chunk ← handle.read 4096
    if chunk.isEmpty then
      pure (if overflow then none else String.fromUTF8? bytes)
    else if overflow || bytes.size + chunk.size > limit then
      -- Continue draining after the limit without retaining more bytes. A
      -- blocked writer must not turn output overflow into a false timeout.
      read bytes true
    else
      read (bytes ++ chunk) false
  read ByteArray.empty false

private def writeInput (handle : IO.FS.Handle) (script : String) : IO Unit := do
  handle.putStr script
  handle.flush
  -- The task owns this handle. Releasing it signals EOF before waiting for
  -- the solver, which may not answer until its input stream is closed.

/-- The production runner: one bounded process per invocation.

The wall clock is enforced here, outside the solver, rather than relying on
the profile's `-T:` option alone: a solver that ignored its own bound would
otherwise hang the pipeline. -/
def processRunner (executable : System.FilePath) (outputLimit : Nat := 65536) :
    SolverRunner where
  run options script timeoutMilliseconds := do
    let child ← IO.Process.spawn
      { cmd := executable.toString
        args := options.toArray
        stdin := .piped
        stdout := .piped
        stderr := .piped
        setsid := true }
    let (stdin, child) ← child.takeStdin
    let stdout ← IO.asTask (readBoundedText child.stdout outputLimit) Task.Priority.dedicated
    let stderr ← IO.asTask (readBoundedText child.stderr outputLimit) Task.Priority.dedicated
    let input ← IO.asTask (writeInput stdin script) Task.Priority.dedicated
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
    | none => pure { exitCode := 0, stdout := "", stderr := "", timedOut := true }
    | some exitCode => do
        -- All streams have been serviced concurrently, including stdin, so
        -- the deadline also covers a solver that stops reading a large input.
        IO.ofExcept input.get
        let stdout ← IO.ofExcept stdout.get
        let stderr ← IO.ofExcept stderr.get
        match stdout, stderr with
        | some stdout, some stderr => pure { exitCode, stdout, stderr }
        | _, _ =>
            pure { exitCode, stdout := "", stderr := "", outputLimitExceeded := true }
  executableDigest := executableDigestOf executable
  executablePath := do
    if ← executable.pathExists then pure (some executable.toString) else pure none

/-- Verifies the pinned identity before any invocation. -/
def verifyPin (runner : SolverRunner) (profile : SolverProfile) (request : SmtRequest) :
    IO (Except Refusal Unit) := do
  if !validSolverProfile profile then return .error .unpinnedProfile
  if !validSmtRequest request || request.profile != profile then
    return .error .unpinnedRequest
  let some path ← runner.executablePath | return .error (.executableMissing profile.solverId)
  let some digest ← runner.executableDigest | return .error .digestUnavailable
  if digest != profile.executableDigest then
    return .error (.executableDigestMismatch profile.executableDigest digest)
  if path.isEmpty then return .error (.executableMissing profile.solverId)
  return .ok ()

/-- A runner standing in for a pinned executable that could not be resolved.

It reports no path, so `verifyPin` refuses with `executableMissing` at the
same point, and after the same profile and request checks, as it would for an
injected runner whose executable is absent. It never answers. -/
private def absentRunner : SolverRunner :=
  { run := fun _ _ _ => pure { exitCode := 0, stdout := "", stderr := "" }
    executableDigest := pure none
    executablePath := pure none }

/-- Runs one obligation's request through `runner` and labels the result with
`provenance`.

The pin is verified first, the decision script is run under the profile's
bound, and only a `sat` answer costs a second invocation. That second run is
classified by the same rule as the first before its output is parsed: a crash,
a resource limit, a bound reached or an answer other than `sat` on the model
run is reported as that, never as a counterexample, and only a `sat` answer
has the line after it parsed as the model, onto the request's source names. A
model that does not parse is malformed output. -/
private def solveWith (provenance : Provenance) (runner : SolverRunner)
    (profile : SolverProfile) (request : SmtRequest) : IO (Except Refusal AttestedResult) := do
  match ← verifyPin runner profile request with
  | .error refusal => return .error refusal
  | .ok () =>
      let decision ← runner.run profile.invocationOptions request.smtLib
        profile.wallTimeMilliseconds
      let outcome := classifyTranscript profile decision
      let outcome ←
        match outcome with
        | .sat _ => do
            let modelRun ← runner.run profile.invocationOptions (modelScript request)
              profile.wallTimeMilliseconds
            match classifyTranscript profile modelRun with
            | .sat _ =>
                -- The first line is the repeated `sat` answer; everything after
                -- it must be the model and nothing else.
                let body := String.intercalate "\n" ((modelRun.stdout.splitOn "\n").drop 1)
                match parseModel request.bindings body with
                | .ok model => pure (.sat model)
                | .error detail => pure (.malformed detail)
            | .timeout milliseconds => pure (.timeout milliseconds)
            | .resourceExhausted => pure .resourceExhausted
            | .crashed detail => pure (.crashed s!"model run: {detail}")
            | .malformed detail => pure (.malformed s!"model run: {detail}")
            | .uncheckedUnsat _ | .checkedUnsat _ | .unknown =>
                pure (.malformed "model run did not answer sat")
        | outcome => pure outcome
      return .ok
        ⟨provenance,
          { profile
            proofBindings := request.proofBindings
            requestIdentity := canonicalRequestIdentity request
            outcome }⟩

/-- Runs one obligation's request through a caller-supplied runner.

This is the test seam. Whatever the runner reports about its executable, the
result is `injectedRunner`: nothing here established that the pinned binary
was spawned, so the refinement boundary defers it rather than publishing a
discharge record from it. -/
def solve (runner : SolverRunner) (profile : SolverProfile) (request : SmtRequest) :
    IO (Except Refusal AttestedResult) :=
  solveWith .injectedRunner runner profile request

/-- Runs one obligation's request against the pinned solver process.

The executable is resolved by `pinnedExecutable`, its digest is verified
against the pin by `verifyPin`, and it is spawned by `processRunner` in this
process. This is the only production caller of `processRunner` and, with
`rerunPinned`, the only producer of `pinnedProcess`. An executable that cannot
be resolved is refused as `executableMissing`, after the same profile and
request checks an injected runner would see. -/
def solvePinned (profile : SolverProfile) (request : SmtRequest)
    (executable : Option System.FilePath := none) : IO (Except Refusal AttestedResult) := do
  match ← pinnedExecutable executable with
  | some path => solveWith .pinnedProcess (processRunner path) profile request
  | none => solveWith .pinnedProcess absentRunner profile request

/-- The full recheck through `runner`, labelled with `provenance`.

`spec/smt/refinement-discharge-architecture.md` §3 is explicit that a cache
hit needs the rerun as well as the bindings, so a record whose inputs still
hold is not yet a remembered success.

The rebuilt record must agree with the recorded one on every input. It is not
required to agree on `evidenceHash`, because evidence is an output: §3 makes a
cache hit conditional on the inputs and the profile matching, and the same
`unsat` may come with a different unsat core on a second run. So the verdict
carries the rebuilt record, whose evidence is what this run said rather than
what the stored one did.

That final equality cannot fail today: `recheckDischargeRecord` has already
pinned every input the rebuild derives from, so the rebuild reproduces them.
It stays because it is the only check that is stated over the whole record, so
a field added to `DischargeRecord` is compared without anyone remembering to
add a comparison for it. -/
private def rerunWith (provenance : Provenance) (runner : SolverRunner)
    (binding : ObligationBinding) (formula : Formula) (record : DischargeRecord) :
    IO AttestedVerdict := do
  match recheckDischargeRecord binding formula record with
  | .error failure => return ⟨provenance, .driftedRecord failure⟩
  | .ok request =>
      match ← solveWith provenance runner record.profile request with
      | .error refusal => return ⟨provenance, .refused refusal⟩
      | .ok result =>
          match makeDischargeRecord binding request result.value with
          | .error failure => return ⟨provenance, .notRechecked failure result.value.outcome⟩
          | .ok rebuilt =>
              if { rebuilt with evidenceHash := record.evidenceHash } == record then
                return ⟨provenance, .rechecked rebuilt⟩
              else return ⟨provenance, .driftedRecord (.recordTampered "rebuild")⟩

/-- The full recheck through a caller-supplied runner: the test seam. Every
drift, refusal and non-`unsat` case is reachable here on a host with no
solver, and a `rechecked` verdict from it is `injectedRunner`, which the
refinement boundary defers rather than admits. -/
def rerunDischargeRecord (runner : SolverRunner) (binding : ObligationBinding)
    (formula : Formula) (record : DischargeRecord) : IO AttestedVerdict :=
  rerunWith .injectedRunner runner binding formula record

/-- The full recheck against the pinned solver process: the other producer of
`pinnedProcess`, resolving and verifying the executable exactly as
`solvePinned` does. The record is rechecked against the obligation before the
executable is consulted, so a drifted record reports its drift whether or not
the solver is installed. -/
def rerunPinned (binding : ObligationBinding) (formula : Formula) (record : DischargeRecord)
    (executable : Option System.FilePath := none) : IO AttestedVerdict := do
  match ← pinnedExecutable executable with
  | some path => rerunWith .pinnedProcess (processRunner path) binding formula record
  | none => rerunWith .pinnedProcess absentRunner binding formula record

end Firth.Smt.Solver
