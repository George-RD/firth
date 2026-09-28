import agent.Firth.Agent.ElaboratorDiagnostics
import agent.Firth.Agent.ElaborateAdapter
import agent.Firth.Agent.Validation
import agent.Firth.Agent.DiagnosticEnvelopeTest
import elaborator.Firth.Refinement

namespace Firth.Agent.Test

open Firth.Agent
open Firth.Elaborator

private def point (line column : Nat) : Firth.Elaborator.Position :=
  { offset := column - 1, line, column }

private def span (line start stop : Nat) : Span :=
  { start := point line start, stop := point line stop }

private def location : Location := .path "main.fth" {
  start := { line := 1, column := 1 }
  stop := { line := 1, column := 2 } }

private def fix : ProposedFix := {
  fixId := "fix-1"
  kind := "replace"
  titleKey := "fix.replace"
  applicability := "needs-review"
  edits := [{ location, replacement := "dup" }] }

private def context (payloadId : String) : EmissionContext := {
  payloadId
  requestId := "request-1"
  source := .path "main.fth"
  proposedFixes := [fix]
  related := [{ relation := "origin", location }] }

private def contextWithSource (payloadId path : String) : EmissionContext :=
  { context payloadId with source := .path path }

private def expectSortedFirst (name expected : String) (left right : Envelope) : IO Unit :=
  match sortDiagnosticEnvelopes [left, right] with
  | first :: _ => expectEqual name first.payloadId expected
  | [] => fail s!"{name}: diagnostic sorting dropped both envelopes"

private def expectValidCode (name expectedCode source : String) : IO Unit := do
  match validate source with
  | .error error => fail s!"{name}: invalid emitted envelope {error.code}"
  | .ok _ =>
      match Lean.Json.parse source with
      | .error parseError => fail s!"{name}: emitted invalid JSON {parseError}"
      | .ok json =>
          match json.getObjVal? "body" >>= (·.getObjVal? "code") >>= (·.getStr?) with
          | .ok code => expectEqual name code expectedCode
          | .error jsonError => fail s!"{name}: missing code {jsonError}"

private def expectedStackState (stack : Firth.Elaborator.StackEffect.AStack) : Lean.Json :=
  .mkObj [
    ("encoding", .str "opaque"),
    ("value", .mkObj [
      ("lean_repr", .str s!"{repr stack}"),
      ("firth", .str (Firth.Elaborator.StackEffect.renderStack stack))]),
    ("display_hint", .str "firth")]

private def expectCauseState (name source : String)
    (expected : Firth.Elaborator.StackEffect.AStack) : IO Unit :=
  match Lean.Json.parse source with
  | .error parseError => fail s!"{name}: emitted invalid JSON {parseError}"
  | .ok json =>
      match json.getObjVal? "body" >>= (·.getObjVal? "cause") >>=
          (·.getObjVal? "data") >>= (·.getObjVal? "state") with
      | .ok state =>
          expectEqual name state.compress (expectedStackState expected).compress
      | .error jsonError => fail s!"{name}: missing cause.data.state {jsonError}"

private def warningByCode (code : String) : List Firth.Elaborator.LintWarning →
    Option Firth.Elaborator.LintWarning
  | [] => none
  | warning :: rest => if warning.code == code then some warning else warningByCode code rest

def runElaboratorDiagnosticTests : IO Unit := do
  let parseError : ParseError := {
    code := "firth.syntax.unterminated-string"
    primary := span 2 3 7
    expected := some "closing quote"
    actual := some "end of input"
    cause := .delimiter }
  let parserJson := encodeParseError (context "parser-1") parseError
  expectValidCode "parser adapter" "firth.syntax.unterminated-string" parserJson
  if parserJson.contains "\"cause\":{\"kind\":\"delimiter\"" &&
      parserJson.contains "\"proposed_fixes\":[{\"fix_id\":\"fix-1\"" &&
      parserJson.contains "\"related\":[{\"relation\":\"origin\"" then pure ()
  else fail "parser adapter omitted cause, fix, or related information"

  let erasureJson := encodeErasureError (context "erasure-1")
    (.linearUnused "handle" (span 3 1 7))
  expectValidCode "erasure adapter" "firth.linearity.unconsumed-resource" erasureJson
  if erasureJson.contains "\"message_params\":{\"hint\":" && erasureJson.contains "\"name\":\"handle\"" then pure ()
  else fail "erasure adapter omitted the local name"

  let warningJson := encodeErasureWarning (context "warning-1") {
    code := "LOCAL_DEPTH", span := span 3 2 4 }
  expectValidCode "erasure warning adapter" "firth.elaboration.local-depth" warningJson
  if warningJson.contains "\"severity\":\"warning\"" then pure ()
  else fail "erasure warning adapter did not preserve warning severity"

  let intStack : Firth.Elaborator.StackEffect.AStack :=
    .snoc .empty (.base "Int" .many)
  let stackDiagnostic : Firth.Elaborator.StackEffect.Diagnostic := {
    code := "firth.type.stack-mismatch"
    primary := span 4 2 5
    state := intStack
    expected := some (.snoc .empty (.base "Bool" .many))
    actual := some (.snoc .empty (.base "Int" .many)) }
  let stackJson := encodeStackEffectDiagnostic (context "stack-1") stackDiagnostic
  expectValidCode "stack-effect adapter" "firth.type.stack-mismatch" stackJson
  expectCauseState "stack-effect adapter pre-atom state" stackJson intStack
  if stackJson.contains "\"expected_stack\":{\"encoding\":\"opaque\",\"value\":" &&
      stackJson.contains "\"actual_stack\":{\"encoding\":\"opaque\",\"value\":" then pure ()
  else fail "stack-effect adapter omitted expected or actual state"

  let hole : Firth.Elaborator.StackEffect.TypedHole := {
    span := span 5 6 7
    state := .snoc (.row (.rigid "rho")) (.base "Int" .many) }
  let holeJson := encodeTypedHole (context "hole-1") "h-1" hole
  match validate holeJson with
  | .ok envelope => expectEqual "typed-hole adapter kind" envelope.payloadKind "typed_hole"
  | .error error => fail s!"typed-hole adapter invalid: {error.code}"

  let inferredHoleInput : Firth.Elaborator.StackEffect.AStack :=
    .row (.rigid "rho")
  let inferredHoleProgram : Firth.Elaborator.KernelProgram := [{
    span := span 5 1 2
    atom := .lit (.int 7) }]
  match Firth.Elaborator.StackEffect.typedHole
      { literal := Firth.Elaborator.StackEffect.defaultLiteralType }
      inferredHoleInput inferredHoleProgram (span 5 3 3) with
  | .ok inferredHole =>
      let inferredHoleJson := encodeTypedHole (context "inferred-hole-1")
        "h-inferred" inferredHole
      match validate inferredHoleJson with
      | .ok envelope =>
          expectEqual "inferred typed-hole adapter kind" envelope.payloadKind "typed_hole"
      | .error error => fail s!"inferred typed-hole adapter invalid: {error.code}"
  | .error error => fail s!"typed-hole inference failed: {repr error}"

  let refinedStack : Firth.Elaborator.Refinement.RefinedStack := {
    erased := intStack
    refinements := {} }
  let refinementContext : Firth.Elaborator.Refinement.ObligationContext := {
    wordId := "math.increment"
    bodyHash := "sha256:body"
    erasedWordTypeHash := "sha256:word-type"
    specHash := "sha256:spec"
    normaliserVersion := "normaliser-v1"
    vcGeneratorVersion := "vc-v1"
    leanToolchainHash := "lean-toolchain"
    proofModuleHash := "sha256:proof-module"
    toolchainRevision := "firth-a"
    source := { path := "main.fth", span := span 6 2 8 }
    expectedStack := refinedStack
    actualStack := refinedStack }
  let refinementResult := Firth.Elaborator.Refinement.checkBodyRefinements
    "request-refinement" {
      context := refinementContext
      precondition := {}
      bodySemantics := {}
      declaredPostcondition := { conjuncts := [.boolVariable "open"] } }
  match refinementEnvelopes refinementResult with
  | [refinementDiagnostic] =>
      let emitted := encode refinementDiagnostic
      expectValidCode "refinement path emission" "firth.refinement.not-decided" emitted
      if emitted.contains "\"cause\":{\"kind\":\"refinement\"" &&
          emitted.contains "\"obligation_id\":" &&
          emitted.contains "\"kind\":\"body\",\"status\":\"deferred\"" &&
          emitted.contains "\"expected_stack\":{\"encoding\":\"opaque\"" &&
          emitted.contains "\"actual_stack\":{\"encoding\":\"opaque\"" &&
          emitted.contains "\"group_id\":\"refinement(" then pure ()
      else fail "refinement adapter omitted governed diagnostic fields"
  | diagnostics =>
      fail s!"refinement adapter fixture expected one diagnostic, got {diagnostics.length}"

  expectSortedFirst "diagnostic source sorting" "source-a"
    (parserEnvelope (contextWithSource "source-z" "z.fth") parseError)
    (parserEnvelope (contextWithSource "source-a" "a.fth") parseError)
  expectSortedFirst "diagnostic start sorting" "start-a"
    (parserEnvelope (context "start-z") { parseError with primary := span 9 1 2 })
    (parserEnvelope (context "start-a") { parseError with primary := span 1 1 2 })
  expectSortedFirst "diagnostic end sorting" "end-a"
    (parserEnvelope (context "end-z") { parseError with primary := span 1 1 4 })
    (parserEnvelope (context "end-a") { parseError with primary := span 1 1 2 })
  expectSortedFirst "diagnostic code sorting" "code-a"
    (parserEnvelope (context "code-z") { parseError with code := "firth.syntax.z" })
    (parserEnvelope (context "code-a") { parseError with code := "firth.syntax.a" })
  expectSortedFirst "diagnostic payload sorting" "payload-a"
    (parserEnvelope (context "payload-z") parseError)
    (parserEnvelope (context "payload-a") parseError)

  match parse "\"unterminated" with
  | .success _ => fail "parser integration fixture unexpectedly succeeded"
  | .failure (error :: _) =>
      expectValidCode "parser path emission" error.code
        (encodeParseError (context "parser-path") error)
  | .failure [] => fail "parser integration fixture produced no diagnostic"

  match parse ": unbound ( a:Int^many -- ) locals { a } { missing } ;" with
  | .success { declarations := [.word word], .. } =>
      match erase {} word.effect word.body with
      | .ok _ => fail "erasure integration fixture unexpectedly succeeded"
      | .error error =>
          let emitted := encodeErasureError (context "erasure-path") error
          match validate emitted with
          | .ok _ => pure ()
          | .error validation => fail s!"erasure path emitted invalid JSON: {validation.code}"
  | .success _ => fail "erasure integration fixture parsed the wrong declaration shape"
  | .failure errors => fail s!"erasure integration fixture did not parse: {repr errors}"

  match parse ": deep ( a:Int^many b:Int^many c:Int^many d:Int^many e:Int^many -- ) locals { a b c d e } { } ;" with
  | .success { declarations := [.word word], .. } =>
      match erase {} word.effect word.body with
      | .error error => fail s!"erasure warning fixture failed: {repr error}"
      | .ok result =>
          match warningByCode "LOCAL_DEPTH" result.warnings with
          | none => fail "erasure warning path produced no LOCAL_DEPTH warning"
          | some warning =>
              expectValidCode "erasure warning path emission" "firth.elaboration.local-depth"
                (encodeErasureWarning (context "erasure-warning-path") warning)
  | .success _ => fail "erasure warning fixture parsed the wrong declaration shape"
  | .failure errors => fail s!"erasure warning fixture did not parse: {repr errors}"

  let seed : Firth.Elaborator.LocatedKernel := {
    span := span 6 1 5
    atom := .prim "seed" }
  let missing : Firth.Elaborator.LocatedKernel := {
    span := span 6 6 13
    atom := .word "missing" }
  let seedScheme : Firth.Elaborator.StackEffect.Scheme := {
    rowVariables := []
    input := .empty
    output := intStack }
  let stackEnv : Firth.Elaborator.StackEffect.Env := {
    primitive := fun name => if name == "seed" then some seedScheme else none }
  match Firth.Elaborator.StackEffect.infer stackEnv [seed, missing] with
  | .ok _ => fail "stack-effect integration fixture unexpectedly succeeded"
  | .error diagnostic =>
      let emitted := encodeStackEffectDiagnostic (context "stack-path") diagnostic
      expectValidCode "stack-effect path emission" diagnostic.code emitted
      expectCauseState "stack-effect path pre-atom state" emitted intStack

  let pipelineContext := contextWithSource "pipeline-1" "main.fth"
  match elaboratePipeline pipelineContext ": id ( -- ) ;" with
  | .success program =>
      match program.words with
      | [word] => expectEqual "pipeline success word" word.name "id"
      | _ => fail "pipeline success returned the wrong word count"
  | .failure _ => fail "pipeline success returned diagnostics"

  match elaboratePipeline pipelineContext ":" with
  | .failure [envelope] =>
      expectValidCode "pipeline parser path" "firth.syntax.unexpected-eof" (encode envelope)
      match envelope.body with
      | .diagnostic diagnostic =>
          expectEqual "pipeline parser source" diagnostic.location.source (.path "main.fth")
          expectEqual "pipeline parser line" diagnostic.location.range.start.line 1
      | _ => fail "pipeline parser result was not a diagnostic payload"
  | _ => fail "pipeline parser result was not singular"

  -- An unknown word reference carries the normative resolver code; only a
  -- primitive the environment does not declare is an unresolved effect.
  match elaboratePipeline pipelineContext ": bad ( -- ) missing ;" with
  | .failure [envelope] =>
      expectValidCode "pipeline name-resolution path" "firth.name.unresolved" (encode envelope)
  | _ => fail "pipeline name-resolution result was not singular"

  match elaboratePipeline pipelineContext ": bad ( -- ) prim nope ;" with
  | .failure [envelope] =>
      expectValidCode "pipeline erasure path" "firth.name.unresolved-effect" (encode envelope)
  | _ => fail "pipeline erasure result was not singular"

  match elaboratePipeline pipelineContext ": bad ( -- ) 1 ;" with
  | .failure [envelope] =>
      expectValidCode "pipeline stack-effect path"
        "firth.type.declared-effect-mismatch" (encode envelope)
      -- The message names the word and both whole stacks, and the hint says
      -- how many values are left over, so an author can repair it unaided.
      let emitted := encode envelope
      if emitted.contains "declares that it leaves (empty) but its body leaves Int" &&
          emitted.contains "1 extra value on top (Int)" &&
          emitted.contains "\"word\":\"bad\"" then pure ()
      else fail s!"pipeline stack-effect message was not explanatory: {emitted}"
  | _ => fail "pipeline stack-effect result was not singular"

  match elaboratePipeline pipelineContext ": bad ( -- ) missing ;" with
  | .failure [envelope] =>
      if (encode envelope).contains "`missing` is not a defined word" then pure ()
      else fail "pipeline name-resolution message did not name the word"
  | _ => fail "pipeline name-resolution result was not singular"

  -- A stack-effect name used as a variable, the mistake that stopped every
  -- attempt of a weaker model in the authoring eval: the hint says effect
  -- names are not variables and shows the `locals` block that binds the
  -- inputs, in declared order.
  let effectSource := ": second (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Int^many)\n  xs 1 prim seq-int.at n prim + ;"
  match elaboratePipeline pipelineContext effectSource with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "effect-name path" "firth.name.unresolved" emitted
      if emitted.contains "`xs` is a name in the word's stack effect" &&
          emitted.contains "they are not variables" &&
          emitted.contains "`locals { xs n } { ... }`" &&
          emitted.contains "the last name from the top" then pure ()
      else fail s!"an effect input used as a variable did not point to locals: {emitted}"
  | _ => fail "effect-name result was not singular"

  match elaboratePipeline pipelineContext ": double (forall ρ; ρ n:Int^many -- ρ r:Int^many) 2 prim * r ;" with
  | .failure [envelope] =>
      let emitted := encode envelope
      if emitted.contains "`r` names an output in the word's stack effect" &&
          emitted.contains "leave the result on the stack" &&
          emitted.contains "`locals { n } { ... }`" then pure ()
      else fail s!"an effect output used as a variable was not explained: {emitted}"
  | _ => fail "effect-output result was not singular"

  -- A stack effect may repeat a label, but `locals` refuses a repeated name,
  -- so the hint numbers the repeats. The suggested block is checked by the
  -- real checker, which refused the unnumbered `locals { n n }` it used to
  -- suggest with `firth.name.duplicate-local`.
  let agentConfig : Firth.Elaborator.PipelineConfig :=
    { erasureEnv := Elaborate.gammaErasure, typingEnv := Elaborate.gammaTyping }
  let repeated := "(forall ρ; ρ n:Int^many n:Int^many -- ρ r:Int^many)"
  match elaboratePipeline pipelineContext s!": pair {repeated} n n prim + ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      if emitted.contains "`locals { n n2 } { ... }`" &&
          emitted.contains "the repeats are numbered" then pure ()
      else fail s!"a repeated effect name got a duplicate-binder hint: {emitted}"
  | _ => fail "repeated-effect-name result was not singular"
  match elaboratePipeline pipelineContext
      s!": pair {repeated} locals \{ n n2 } \{ n n2 prim + } ;" agentConfig with
  | .success _ => pure ()
  | .failure diagnostics =>
      fail s!"the suggested locals block does not check: {diagnostics.map encode}"
  match elaboratePipeline pipelineContext
      s!": pair {repeated} locals \{ n n } \{ n n prim + } ;" agentConfig with
  | .failure [envelope] => expectValidCode "duplicate local" "firth.name.duplicate-local" (encode envelope)
  | _ => fail "a repeated local name was accepted"
  expectEqual "binders keep distinct names" (localBinders ["xs", "n"]) ["xs", "n"]
  expectEqual "binders skip a name an input uses" (localBinders ["n", "n", "n2"]) ["n", "n3", "n2"]
  expectEqual "binders number every repeat" (localBinders ["a", "a", "a"]) ["a", "a2", "a3"]

  -- An `if` inside `locals` whose branches change the stack depth by
  -- different amounts, with a local used after it. Erasure loses track of
  -- the stack at the `if` and used to report the later use of `x` as an
  -- untracked local, with a hint saying such quotations are fine. The real
  -- error is the branch mismatch, reported at the `if` with both branches.
  let branchSource := ": keep-positive (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } { 0 x prim < [ x ] [ ] if x prim + } ;"
  match elaboratePipeline pipelineContext branchSource agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "branch shape" "firth.type.branch-mismatch" emitted
      if emitted.contains "the true branch pushes 1 value, and the false branch leaves the stack as it is. So the true branch leaves 1 value more than the false branch." &&
          emitted.contains "If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more" &&
          emitted.contains "in `keep-positive`" &&
          emitted.contains "\"start\":{\"line\":2,\"column\":39}" &&
          !emitted.contains "untracked" && !emitted.contains "are fine" then pure ()
      else fail s!"an if with branches of different depths was not reported at the if: {emitted}"
  | _ => fail "branch-shape result was not singular"
  -- The same mistake inside a quotation that is then called: the quotation's
  -- effect is unknown because of the inner `if`, and the report still points
  -- at that `if`, not at the `call` that runs it.
  let nestedSource := ": keep-positive (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } { [ true [ 1 ] [ ] if ] call x prim + } ;"
  match elaboratePipeline pipelineContext nestedSource agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "nested branch shape" "firth.type.branch-mismatch" emitted
      if emitted.contains "\"start\":{\"line\":2,\"column\":35}" && !emitted.contains "untracked" then pure ()
      else fail s!"an if with branches of different depths inside a called quotation was not reported at the if: {emitted}"
  | _ => fail "nested branch-shape result was not singular"
  -- The mismatched `if` two and three levels down, inside a branch of an
  -- outer `if` whose own branches have unknown effects because of it. The
  -- report is at the innermost mismatched `if`, whatever the nesting.
  let expectInnerIf (label source : String) (line column : Nat) : IO Unit := do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        expectValidCode label "firth.type.branch-mismatch" emitted
        unless emitted.contains s!"\"start\":\{\"line\":{line},\"column\":{column}}" &&
            !emitted.contains "untracked" do
          fail s!"{label}: not reported at the innermost if: {emitted}"
    | _ => fail s!"{label}: result was not singular"
  expectInnerIf "two levels"
    ": g (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } {\n    0 x prim <\n    [ 1 x prim < [ x ] [ ] if ]\n    [ 0 ]\n    if\n    x prim + } ;"
    4 28
  -- Bound to a local first, then called: the mismatch is still found at the
  -- inner `if`, since erasure refuses the `if` itself, wherever it sits.
  expectInnerIf "bound to a local"
    ": g (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } {\n    [ true [ 1 ] [ ] if ] locals { q } { q call } x } ;"
    3 22
  -- Outside `locals` too, with the same message. The type checker reported
  -- this one too, but inside a quotation its report was an occurs check.
  expectInnerIf "outside locals"
    ": g (forall ρ; ρ -- ρ r:Int^many)\n  0 1 prim < [ 1 ] [ ] if ;"
    2 24
  expectInnerIf "outside locals, in a quotation"
    ": g (forall ρ; ρ -- ρ r:Int^many)\n  [ 0 1 prim < [ 1 ] [ ] if ] call ;"
    2 26
  -- Branches bound to locals keep their exact effects, so the `if` is
  -- refused before the later use of `x` could report an untracked local.
  expectInnerIf "branches from locals"
    ": g (forall ρ; ρ -- ρ r:Int^many)\n  [ 1 ] [ ] 5 locals { t f x } { true t f if x prim + } ;"
    2 43
  expectInnerIf "three levels"
    ": g (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } {\n    0 x prim <\n    [ 1 x prim < [ 2 x prim < [ x ] [ ] if ] [ 0 ] if ]\n    [ 0 ]\n    if\n    x prim + } ;"
    4 41

  -- Branch mismatches as the authoring eval met them. Each report must say
  -- what each branch does, which one leaves more and by how many, and an edit
  -- that makes them agree. `branchReport` holds those checks, and the reports
  -- the eval recorded before this change must fail them.
  let branchReport (label source : String) (needles : List String) : IO Unit := do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        expectValidCode label "firth.type.branch-mismatch" emitted
        for needle in needles do
          unless emitted.contains needle do
            fail s!"{label}: the report does not say {needle}: {emitted}"
    | .failure envelopes => fail s!"{label}: expected one diagnostic, got {envelopes.length}"
    | .success _ => fail s!"{label}: the program was accepted"
  let needlesMissing (report : String) (needles : List String) : Bool :=
    needles.any (!report.contains ·)
  -- longest-run (eval/s7/runs/2026-09-28-haiku-cec3707/haiku-firth-2,
  -- answer 1): the loop is called with one argument too few, so the false
  -- branch takes a value from below the `if`.
  let longestRun := [
    "The two branches of `if` in `main` leave different numbers of values",
    "the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value",
    "The false branch takes 1 value from below the `if` that this code does not have",
    "Push what the branch needs inside the branch"]
  branchReport "longest-run" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)\n  locals { xs } {\n    xs prim seq-int.len 0 prim =\n    [ 0 ]\n    [ xs 0 prim seq-int.at 1 1 xs longest-run-loop ] if\n  };\n\n: longest-run-loop\n  (forall ρ; ρ prev:Int^many curr-run:Int^many max-run:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { prev curr-run max-run idx xs } {\n    idx xs prim seq-int.len prim =\n    [ max-run curr-run prim < [ curr-run ] [ max-run ] if ]\n    [\n      xs idx prim seq-int.at dup prev prim =\n      [ curr-run 1 prim + ] [ 1 swap ] if\n      idx 1 prim +\n      xs\n      longest-run-loop\n    ]\n    if\n  };" longestRun
  -- keep-positive (the same run, answer 1): the false branch pushes the
  -- sequence on top of the element it means to append, so it takes a Seq Int
  -- where there is an Int. Both answers are copied verbatim.
  let keepPositive := [
    "The false branch of `if` in `keep-positive-loop` cannot run on the stack it is given",
    "The top value there is Int, but the false branch expects Seq Int",
    "`swap` exchanges the top two"]
  branchReport "keep-positive" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)\n  locals { xs } { prim seq-int.empty 0 xs keep-positive-loop };\n\n: keep-positive-loop\n  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)\n  locals { result idx xs } {\n    idx xs prim seq-int.len prim =\n    [ result ]\n    [\n      xs idx prim seq-int.at dup 0 prim <\n      [ drop result ]\n      [ result prim seq-int.push ] if\n      idx 1 prim +\n      xs\n      keep-positive-loop\n    ]\n    if\n  };" keepPositive
  -- The same depth, different types.
  let differentTypes := [
    "the true branch leaves ρ Int and the false branch leaves ρ Bool",
    "the top value is Int after the true branch and Bool after the false branch"]
  branchReport "different types" ": g (forall ρ; ρ -- ρ r:Int^many)\n  0 1 prim < [ 1 ] [ true ] if ;" differentTypes
  -- Two values too many: the hint gives both `drop`s.
  let twoExtra := ["So the true branch leaves 2 values more than the false branch",
    "either add `drop drop` at the end of the true branch"]
  branchReport "two extra" ": g (forall ρ; ρ -- ρ r:Int^many)\n  0 1 prim < [ 1 2 3 ] [ 4 ] if ;" twoExtra
  -- A branch, or the `if` itself, reaching for a local as if it were on the
  -- stack, or below everything the word was given: the commonest mistake in
  -- the authoring eval. Evening out the branches with a `drop` or a push only
  -- moves it, so the report must not suggest either, and the edit it does
  -- suggest must make the program check. Each case also carries the edit the
  -- earlier report suggested, which must still be refused: that is the
  -- planted wrong suggestion. The answers are copied verbatim from
  -- eval/s7/runs (and `p q` from 2026-09-27-plus-only/haiku-firth,
  -- solutions-1.json, task `and`).
  let noEvening (label : String) (source : String) : IO Unit := do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        if emitted.contains "either add `drop" || emitted.contains "push 1 value more" then
          fail s!"{label}: the report still suggests evening out the branches: {emitted}"
        else pure ()
    | _ => fail s!"{label}: expected one diagnostic"
  let checks (label source : String) (expected : Bool) : IO Unit :=
    match elaboratePipeline pipelineContext source agentConfig with
    | .success _ => unless expected do fail s!"{label}: the program was accepted"
    | .failure _ => if expected then fail s!"{label}: the program was refused" else pure ()
  let fixtures : List (String × String × List String × String × String) := [
    ("p q", ": main\n  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)\n  locals { p q } { [ q ] [ drop false ] if };",
      ["looked for where the local `p` would be, but a local is not a value on the stack",
        "Write the condition just before the two quotations"],
      -- The suggested edit: the condition written before the quotations, and
      -- the local used by name instead of taken with `drop`.
      ": main\n  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)\n  locals { p q } { p [ q ] [ false ] if };",
      -- The earlier suggestion: a `drop` to even out the branches.
      ": main\n  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)\n  locals { p q } { [ q drop ] [ drop false ] if };"),
    ("lcm (2026-09-27-hard/haiku-firth-2, answer 1)", ": lcm\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    a b gcd\n    a b prim *\n    swap\n    prim -\n    0 prim =\n    [\n      a b prim *\n    ]\n    [\n      a b prim * swap prim -\n    ]\n    if\n  };\n\n: gcd\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    b 0 prim =\n    [ a ]\n    [\n      a b prim =\n      [ b ]\n      [\n        b a b prim - gcd\n      ]\n      if\n    ]\n    if\n  };",
      ["The false branch takes 1 value from below the `if` that this code does not have",
        "computing the value there"],
      -- The value the false branch reaches for, computed inside it.
      ": lcm\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    a b gcd\n    a b prim *\n    swap\n    prim -\n    0 prim =\n    [\n      a b prim *\n    ]\n    [\n      a b prim * a b gcd prim -\n    ]\n    if\n  };\n\n: gcd\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    b 0 prim =\n    [ a ]\n    [\n      a b prim =\n      [ b ]\n      [\n        b a b prim - gcd\n      ]\n      if\n    ]\n    if\n  };",
      ": lcm\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    a b gcd\n    a b prim *\n    swap\n    prim -\n    0 prim =\n    [\n      a b prim * drop\n    ]\n    [\n      a b prim * swap prim -\n    ]\n    if\n  };\n\n: gcd\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    b 0 prim =\n    [ a ]\n    [\n      a b prim =\n      [ b ]\n      [\n        b a b prim - gcd\n      ]\n      if\n    ]\n    if\n  };"),
    ("digit-sum (2026-09-27-hard/haiku-firth-2, answer 2)", ": digit-sum-loop\n  (forall ρ; ρ s:Int^many n:Int^many -- ρ r:Int^many)\n  locals { s n } {\n    n 0 prim =\n    [\n      s\n    ]\n    [\n      n 10 prim -\n      0 prim =\n      [\n        s n prim +\n      ]\n      [\n        s n prim - prim +\n        n 10 prim -\n        digit-sum-loop\n      ]\n      if\n    ]\n    if\n  };\n\n: main\n  (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } {\n    0 n digit-sum-loop\n  };",
      ["The false branch takes 1 value from below the `if` that this code does not have",
        "remove the operation that takes it if it should not be there"],
      -- The operation that takes it, removed.
      ": digit-sum-loop\n  (forall ρ; ρ s:Int^many n:Int^many -- ρ r:Int^many)\n  locals { s n } {\n    n 0 prim =\n    [\n      s\n    ]\n    [\n      n 10 prim -\n      0 prim =\n      [\n        s n prim +\n      ]\n      [\n        s n prim -\n        n 10 prim -\n        digit-sum-loop\n      ]\n      if\n    ]\n    if\n  };\n\n: main\n  (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } {\n    0 n digit-sum-loop\n  };",
      ": digit-sum-loop\n  (forall ρ; ρ s:Int^many n:Int^many -- ρ r:Int^many)\n  locals { s n } {\n    n 0 prim =\n    [\n      s\n    ]\n    [\n      n 10 prim -\n      0 prim =\n      [\n        s n prim + drop\n      ]\n      [\n        s n prim - prim +\n        n 10 prim -\n        digit-sum-loop\n      ]\n      if\n    ]\n    if\n  };\n\n: main\n  (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } {\n    0 n digit-sum-loop\n  };")]
  for (label, source, needles, fixed, earlier) in fixtures do
    branchReport label source needles
    noEvening label source
    checks s!"{label}, with the suggested edit" fixed true
    checks s!"{label}, with the earlier suggested edit" earlier false
  noEvening "longest-run" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)\n  locals { xs } {\n    xs prim seq-int.len 0 prim =\n    [ 0 ]\n    [ xs 0 prim seq-int.at 1 1 xs longest-run-loop ] if\n  };\n\n: longest-run-loop\n  (forall ρ; ρ prev:Int^many curr-run:Int^many max-run:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { prev curr-run max-run idx xs } {\n    idx xs prim seq-int.len prim =\n    [ max-run curr-run prim < [ curr-run ] [ max-run ] if ]\n    [\n      xs idx prim seq-int.at dup prev prim =\n      [ curr-run 1 prim + ] [ 1 swap ] if\n      idx 1 prim +\n      xs\n      longest-run-loop\n    ]\n    if\n  };"
  -- A branch that cannot run on the stack it is given keeps the compared
  -- stacks in the envelope and in the `expected` and `actual` params, which
  -- the authoring harness prints as its expected: and actual: lines.
  -- filter-helper, copied verbatim from the keep-positive answer in
  -- eval/s7/runs/2026-09-28-haiku-470c6d0/haiku-firth-2/answer-2.md.
  match elaboratePipeline pipelineContext ": filter-helper\n  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ filtered:Seq Int^many)\n  locals { i result xs } {\n    i xs prim seq-int.len prim <\n    [ \n      xs i prim seq-int.at\n      dup 0 prim <\n      [ drop result ]\n      [ result prim seq-int.push ]\n      if\n      i 1 prim + swap xs filter-helper\n    ]\n    [ result ]\n    if\n  };\n\n: main\n  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)\n  locals { xs } { 0 prim seq-int.empty xs filter-helper };" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "filter-helper" "firth.type.branch-mismatch" emitted
      for needle in ["The false branch of `if` in `filter-helper` cannot run on the stack it is given",
          "\"expected\":\".. Seq Int\"", "\"actual\":\".. Seq Int Int Int\""] do
        unless emitted.contains needle do
          fail s!"filter-helper: the report does not say {needle}: {emitted}"
      if emitted.contains "\"expected_stack\":null" || emitted.contains "\"actual_stack\":null" then
        fail s!"filter-helper: the compared stacks are missing from the envelope: {emitted}"
  | _ => fail "filter-helper: expected one diagnostic"
  -- Counts and types both differ: the locals pass knows only the counts, so
  -- its drop-or-push edit is offered only on condition that the values below
  -- already agree (`[ 1 true ]` against `[ false ]` would still leave Int
  -- against Bool after a `drop`).
  branchReport "counts and types" ": g (forall ρ; ρ -- ρ r:Int^many)\n  0 1 prim < [ 1 true ] [ false ] if ;"
    ["If the values below those already agree, either add `drop`",
      "If they do not, the branches also leave different types"]
  -- The reports these programs got before this change: the two the eval
  -- recorded at cec3707, verbatim, and the locals-pass report that main gave
  -- longest-run from #145 on. Each must fail the checks above, or the checks
  -- prove nothing.
  let recordedBefore := [
    ("longest-run at cec3707", "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `main` leave different stacks.\nexpected: ρ\nactual: .. Int\nhint: Both branches must leave the same number and types of values. Expected ρ, found .. Int.", longestRun),
    ("keep-positive at cec3707", "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `keep-positive-loop` leave different stacks.\nexpected: Int\nactual: Seq Int\nhint: Both branches must leave the same number and types of values. Expected Int, found Seq Int.", keepPositive),
    ("longest-run on main", "The two branches of `if` leave different numbers of values: the true branch leaves 1 more value than it takes, and the false branch leaves as many values as it takes. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.", longestRun)]
  for (label, report, needles) in recordedBefore do
    unless needlesMissing report needles do
      fail s!"{label}: the recorded report from before this change passes the branch checks"
  -- The type checker's own report of a depth mismatch, which erasure does
  -- not see when the program has no `locals` and no word: both branch stacks,
  -- with their types, and the value to drop or push.
  let lit (column : Nat) (literal : Firth.Interpreter.Literal) : Firth.Elaborator.LocatedKernel :=
    { span := span 1 column (column + 1), atom := .lit literal }
  let twoInts := Firth.Interpreter.Program.cons (.lit (.int 1)) (.cons (.lit (.int 2)) .empty)
  let oneInt := Firth.Interpreter.Program.cons (.lit (.int 3)) .empty
  match Firth.Elaborator.StackEffect.infer { literal := Firth.Elaborator.StackEffect.defaultLiteralType } [lit 1 (.bool true),
      { span := span 1 3 4, atom := .quotation twoInts },
      { span := span 1 5 6, atom := .quotation oneInt },
      { span := span 1 7 9, atom := .ifThenElse }] with
  | .ok _ => fail "an if whose branches leave 2 and 1 values was accepted"
  | .error diagnostic =>
      let emitted := encodeStackEffectDiagnostic (context "branch-depth") diagnostic
      expectValidCode "branch depth" "firth.type.branch-mismatch" emitted
      for needle in ["the true branch leaves .. Int Int and the false branch leaves .. Int",
          "The true branch leaves 1 more value than the false branch (Int on top)",
          "Either add `drop` at the end of the true branch, or push a value of the same type at the end of the false branch (for example `0`)"] do
        unless emitted.contains needle do
          fail s!"branch depth: the report does not say {needle}: {emitted}"
      -- The compared stacks stay in the structured fields: the true branch's
      -- output as expected, the false branch's as actual.
      if emitted.contains "\"expected_stack\":null" || emitted.contains "\"actual_stack\":null" then
        fail s!"branch depth: the compared stacks are missing from the envelope: {emitted}"
  -- The same in the type checker, which does know the types: when the values
  -- both branches leave differ, it offers no drop or push, and says where
  -- they differ.
  let intBool := Firth.Interpreter.Program.cons (.lit (.int 1)) (.cons (.lit (.bool true)) .empty)
  let bool := Firth.Interpreter.Program.cons (.lit (.bool false)) .empty
  match Firth.Elaborator.StackEffect.infer { literal := Firth.Elaborator.StackEffect.defaultLiteralType } [lit 1 (.bool true),
      { span := span 1 3 4, atom := .quotation intBool },
      { span := span 1 5 6, atom := .quotation bool },
      { span := span 1 7 9, atom := .ifThenElse }] with
  | .ok _ => fail "an if whose branches leave Int Bool and Bool was accepted"
  | .error diagnostic =>
      let emitted := encodeStackEffectDiagnostic (context "branch-depth-types") diagnostic
      expectValidCode "branch depth and types" "firth.type.branch-mismatch" emitted
      unless emitted.contains "the top value of the values both leave is Int after the true branch and Bool after the false branch" &&
          !emitted.contains "add `drop`" do
        fail s!"branch depth and types: the report offers a drop or does not say where the values differ: {emitted}"

  -- A quotation of unknown effect still gives untracked-local, now naming
  -- the atom that lost track and its line.
  let unknownSource := ": call-unknown-effect\n  (forall ρ; ρ z:Int^many a:Int^many b:Int^many -- ρ z:Int^many r:Int^many)\n  locals { a b } { a [ 1 prim + ] [ call ] call b prim - };"
  match elaboratePipeline pipelineContext unknownSource agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "unknown effect" "firth.elaboration.untracked-local" emitted
      if emitted.contains "used after `call` on line 3 ran a quotation" then pure ()
      else fail s!"an untracked local did not name the atom that lost track: {emitted}"
  | _ => fail "unknown-effect result was not singular"

  -- A quotation that loses track inside its own body, run later: the
  -- message names the inner `call` (line 3), not the outer one (line 4).
  let innerSource := ": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    a [ [ 1 prim + ] [ call ] call ]\n    call b prim - } ;"
  match elaboratePipeline pipelineContext innerSource agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "inner unknown effect" "firth.elaboration.untracked-local" emitted
      unless emitted.contains "used after `call` on line 3 ran a quotation" do
        fail s!"an untracked local did not name the inner call: {emitted}"
  | _ => fail "inner-unknown-effect result was not singular"

  -- The same quotation bound to a local and run from it, once and through a
  -- copy made for a second use: the local keeps where its body lost track,
  -- so the message still names the inner `call` on line 3, not the `call`
  -- that runs the local on line 5.
  for (label, use) in [("bound", "q call"), ("copied", "q q drop call")] do
    let source := s!": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals \{ a b } \{\n    a [ [ 1 prim + ] [ call ] call ]\n    locals \{ q } \{\n      {use} b prim - } } ;"
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        expectValidCode s!"{label} unknown effect" "firth.elaboration.untracked-local" emitted
        unless emitted.contains "used after `call` on line 3 ran a quotation" do
          fail s!"{label}: an untracked local did not name the inner call: {emitted}"
    | _ => fail s!"{label}: unknown-effect result was not singular"

  -- A word typed `ρ -- ρ2` may leave a stack of any depth, so a branch
  -- running it has no exact effect and erasure does not refuse the `if`;
  -- the type checker accepts this program, as it did before the refusal.
  let rowSource := ": w (forall ρ ρ2; ρ -- ρ2) w ;\n: main (forall ρ; ρ -- ρ r:Int^many) true [ w ] [ 1 ] if ;"
  match elaboratePipeline pipelineContext rowSource agentConfig with
  | .success _ => pure ()
  | .failure envelopes =>
      fail s!"a branch running a row-changing word was refused: {envelopes.map encode}"
  -- The same through a quotation that calls one, and through `compose`:
  -- both are accepted outright, as on main.
  for (label, body) in [("nested", "true [ [ w ] call ] [ 1 ] if"),
      ("composed", "true [ w ] [ ] compose [ 1 ] if")] do
    let source := s!": w (forall ρ ρ2; ρ -- ρ2) w ;\n: main (forall ρ; ρ -- ρ r:Int^many) {body} ;"
    match elaboratePipeline pipelineContext source agentConfig with
    | .success _ => pure ()
    | .failure envelopes =>
        fail s!"{label}: a branch running a row-changing word was refused: {envelopes.map encode}"

  -- A name that is not in the stack effect keeps the general hint, which
  -- now also mentions `locals`.
  match elaboratePipeline pipelineContext ": double (forall ρ; ρ n:Int^many -- ρ r:Int^many) 2 prim * dobule ;" with
  | .failure [envelope] =>
      let emitted := encode envelope
      if !emitted.contains "stack effect" && emitted.contains "bind it as a local with `locals" then pure ()
      else fail s!"a misspelt word got the stack-effect hint: {emitted}"
  | _ => fail "misspelt-word result was not singular"

  -- Every hint that lists primitives lists all of them. The expected names
  -- are written out here, not read from `languagePrimitives`, so a hint
  -- that falls behind the language fails.
  let everyPrimitive := ["+", "-", "*", "<", "=", "div", "mod", "and", "or", "not",
    "seq-int.empty", "seq-int.len", "seq-int.at", "seq-int.push", "seq-int.set",
    "seq-bool.empty", "seq-bool.len", "seq-bool.at", "seq-bool.push", "seq-bool.set", "send"]
  -- The list is the checker's: each name has a signature in the agent Gamma,
  -- which refuses a name that is not a primitive.
  for name in everyPrimitive do
    if (Elaborate.gammaTyping.primitive name).isNone || (Elaborate.gammaErasure.primitive name).isNone then
      fail s!"`prim {name}` is listed but the agent Gamma has no signature for it"
  if (Elaborate.gammaTyping.primitive "nope").isSome then
    fail "the agent Gamma gave `prim nope` a signature"
  if (Elaborate.gammaErasure.primitive "nope").isSome then
    fail "the agent erasure Gamma gave `prim nope` a signature"
  -- The World primitives come from `worldPrimitiveSchemes` alone. Their
  -- signatures are written out here, not read from that table, so a scheme
  -- that drifts, or an erasure signature that disagrees with its typing,
  -- fails.
  expectEqual "world primitives" worldPrimitives ["send"]
  let row : Firth.Elaborator.StackEffect.AStack := .row (.rigid "ρ")
  expectEqual "send typing" (Elaborate.gammaTyping.primitive "send")
    (some { rowVariables := ["ρ"]
            input := .snoc (.snoc (.snoc row (.base "World" .linear))
              (.base "Handle" .linear)) (.base "Bytes" .linear)
            output := .snoc row (.base "World" .linear) })
  expectEqual "send erasure" (Elaborate.gammaErasure.primitive "send")
    (some { input := [.linear, .linear, .linear], output := [.linear] })
  let listsEvery (label emitted : String) : IO Unit := do
    for name in everyPrimitive do
      unless emitted.contains s!"`prim {name}`" do
        fail s!"the {label} hint leaves out `prim {name}`: {emitted}"
  match elaboratePipeline pipelineContext ": bad ( -- ) prim nope ;" with
  | .failure [envelope] => listsEvery "unresolved-effect" (encode envelope)
  | _ => fail "unresolved-effect result was not singular"
  match elaboratePipeline pipelineContext ": bad ( -- ) missing ;" with
  | .failure [envelope] => listsEvery "unresolved-name" (encode envelope)
  | _ => fail "unresolved-name result was not singular"
  -- The checker's own unknown-word and unknown-primitive hints, for a
  -- diagnostic the type checker reports itself rather than the resolver.
  let unknownWord : Firth.Elaborator.StackEffect.Diagnostic := {
    code := "firth.name.unknown-word", primary := span 1 14 21, state := .empty
    subject := some "missing", word := some "bad" }
  listsEvery "unknown-word" (encodeStackEffectDiagnostic (context "unknown-word") unknownWord)
  let unknownPrimitive : Firth.Elaborator.StackEffect.Diagnostic := {
    code := "firth.name.unknown-primitive", primary := span 1 14 23, state := .empty
    subject := some "prim nope", word := some "bad" }
  listsEvery "unknown-primitive"
    (encodeStackEffectDiagnostic (context "unknown-primitive") unknownPrimitive)
  if languagePrimitives.length != everyPrimitive.length then
    fail s!"the language has {languagePrimitives.length} primitives but this test lists {everyPrimitive.length}; add the new ones above"

end Firth.Agent.Test
