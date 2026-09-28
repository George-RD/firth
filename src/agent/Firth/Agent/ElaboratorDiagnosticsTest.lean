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
      if emitted.contains "the true branch leaves 1 more value than it takes, and the false branch leaves as many values as it takes" &&
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
  expectInnerIf "three levels"
    ": g (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } {\n    0 x prim <\n    [ 1 x prim < [ 2 x prim < [ x ] [ ] if ] [ 0 ] if ]\n    [ 0 ]\n    if\n    x prim + } ;"
    4 41

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
    "seq-int.empty", "seq-int.len", "seq-int.at", "seq-int.push",
    "seq-bool.empty", "seq-bool.len", "seq-bool.at", "seq-bool.push", "send"]
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
