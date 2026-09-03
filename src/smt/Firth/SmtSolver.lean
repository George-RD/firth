import smt.Firth.SmtBoundary

/-!
Bounded invocation of the pinned solver, and strict classification of what it
says.

`spec/smt/refinement-discharge-architecture.md` §6 makes the pin mandatory:
the solver's identity, version, executable digest, invocation options and
resource bounds are part of the toolchain lockfile and of every discharge
record. This module is where those become operational rather than declarative.

Three properties shape the design.

*The invocation is refused before it happens* when anything about the pinned
identity does not hold: an unrecognised profile, a missing executable, a
digest that does not match the pin, or a request that does not rebuild to
itself. A solver that is not the pinned solver is not a weaker oracle, it is
a different one, and nothing it says may enter evidence.

*Classification is total and deterministic.* Every transcript maps to exactly
one `ExternalOutcome`, and everything that is not an answer the profile
supports maps to a deferred outcome rather than to silence. A bare `unsat`
maps to `uncheckedUnsat`: promoting it is the next unit's job, and doing it
here would put an unrechecked result into evidence.

*The runner is injected.* `SolverRunner` is a seam, so classification, model
parsing and the refusal rules are all testable without a fetched binary on a
particular platform, and `lake test` stays reproducible on a host that has no
solver at all. `processRunner` is the production implementation; nothing else
in the module spawns a process.

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

/-- Why an invocation was refused before the solver was ever spawned. -/
inductive Refusal where
  /-- The profile is not the pinned profile. -/
  | unpinnedProfile
  /-- The request does not rebuild to itself under the checked adapter. -/
  | unpinnedRequest
  /-- The pinned executable is absent at the resolved path. -/
  | executableMissing (path : String)
  /-- The host has no usable digest tool, so identity cannot be established. -/
  | digestUnavailable
  /-- The executable is present but is not the pinned one. -/
  | executableDigestMismatch (expected actual : String)
  deriving Repr, BEq

/-- A stable code for a refusal, for diagnostics and records. -/
def Refusal.code : Refusal → String
  | .unpinnedProfile => "firth.smt.unpinned-profile"
  | .unpinnedRequest => "firth.smt.unpinned-request"
  | .executableMissing _ => "firth.smt.executable-missing"
  | .digestUnavailable => "firth.smt.digest-unavailable"
  | .executableDigestMismatch _ _ => "firth.smt.executable-digest-mismatch"

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

private def firstLine (text : String) : String :=
  (text.splitOn "\n").headD "" |>.trim

private def lines (text : String) : List String :=
  (text.splitOn "\n").map String.trim |>.filter (fun line => !line.isEmpty)

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

private def parseInt (token : String) : Option Int :=
  if token.isEmpty then none
  else if token.front == '-' then
    let digits := token.drop 1
    if digits.isEmpty || !digits.all Char.isDigit then none
    else some (-(Int.ofNat digits.toNat!))
  else if token.all Char.isDigit then some (Int.ofNat token.toNat!)
  else none

private def sourceName (bindings : List SmtBinding) (sort : SmtSort) (symbol : String) :
    Option String :=
  (bindings.find? fun binding => binding.sort == sort && binding.symbol == symbol).map
    (·.sourceName)

/-- Parses a `(get-model)` response into a valuation over source names.

The grammar accepted is deliberately narrow: a flat sequence of
`(define-fun <symbol> () Int <integer>)` and
`(define-fun <symbol> () Bool true|false)` entries, with a negative integer
written either as `-3` or as `(- 3)`. Anything else, including a symbol the
request never declared, is a parse failure, which the caller classifies as
malformed output rather than as a counterexample. -/
def parseModel (bindings : List SmtBinding) (text : String) : Except String Valuation := do
  let mut integers : List (String × Int) := []
  let mut booleans : List (String × Bool) := []
  let mut tokens := tokenise text
  while !tokens.isEmpty do
    match tokens with
    | "(" :: "define-fun" :: symbol :: "(" :: ")" :: sort :: rest =>
        match sort with
        | "Int" =>
            let (value, rest) ←
              match rest with
              | "(" :: "-" :: digits :: ")" :: rest =>
                  match parseInt digits with
                  | some value => pure (-value, rest)
                  | none => .error s!"model: {symbol} has a non-integer value"
              | token :: rest =>
                  match parseInt token with
                  | some value => pure (value, rest)
                  | none => .error s!"model: {symbol} has a non-integer value"
              | [] => .error "model: truncated integer definition"
            match rest with
            | ")" :: rest =>
                match sourceName bindings .integer symbol with
                | some name =>
                    integers := integers ++ [(name, value)]
                    tokens := rest
                | none => .error s!"model: {symbol} was never declared"
            | _ => .error s!"model: {symbol} is not closed"
        | "Bool" =>
            match rest with
            | value :: ")" :: rest =>
                let flag ←
                  if value == "true" then pure true
                  else if value == "false" then pure false
                  else .error s!"model: {symbol} has a non-boolean value"
                match sourceName bindings .boolean symbol with
                | some name =>
                    booleans := booleans ++ [(name, flag)]
                    tokens := rest
                | none => .error s!"model: {symbol} was never declared"
            | _ => .error s!"model: {symbol} is not closed"
        | sort => .error s!"model: unsupported sort {sort}"
    | "(" :: rest | ")" :: rest =>
        -- The response is wrapped in one outer pair, and some solvers add a
        -- `model` keyword. Skipping a bare delimiter keeps the parser flat.
        tokens := rest
    | "model" :: rest => tokens := rest
    | token :: _ => .error s!"model: unexpected token {token}"
    | [] => tokens := []
  pure { integers, booleans }

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

private def readBoundedText (handle : IO.FS.Handle) (limit : Nat) : IO (Option String) := do
  let bytes ← handle.read (USize.ofNat (limit + 1))
  if bytes.size > limit then pure none
  else pure (String.fromUTF8? bytes)

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
    stdin.putStr script
    stdin.flush
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
        let stdout ← readBoundedText child.stdout outputLimit
        let stderr ← readBoundedText child.stderr outputLimit
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

/-- Runs one obligation's request against the pinned solver.

The pin is verified first, the decision script is run under the profile's
bound, and only a `sat` answer costs a second invocation, whose model is
parsed back onto the request's source names. A model that does not parse is
malformed output, never a counterexample. -/
def solve (runner : SolverRunner) (profile : SolverProfile) (request : SmtRequest) :
    IO (Except Refusal SmtResult) := do
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
            if modelRun.timedOut then
              pure (.timeout profile.wallTimeMilliseconds)
            else if modelRun.outputLimitExceeded then
              pure (.malformed "model output limit exceeded")
            else
              let body := String.intercalate "\n"
                ((lines modelRun.stdout).filter fun line => line != "sat")
              match parseModel request.bindings body with
              | .ok model => pure (.sat model)
              | .error detail => pure (.malformed detail)
        | outcome => pure outcome
      return .ok
        { profile
          proofBindings := request.proofBindings
          requestIdentity := canonicalRequestIdentity request
          outcome }

end Firth.Smt.Solver
