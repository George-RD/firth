import agent.Firth.Agent.ElaboratorDiagnostics
import agent.Firth.Agent.ElaborateAdapter
import agent.Firth.Agent.Validation
import agent.Firth.Agent.DiagnosticEnvelopeTest
import elaborator.Firth.Refinement
import FirthReferenceRun

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

/-- The start of an envelope's structured stack field holding `stack`. -/
private def structuredStack (field stack : String) : String :=
  s!"\"{field}\":\{\"encoding\":\"opaque\",\"value\":\{\"firth\":\"{stack}\""

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

  -- `locals` blocks that bind the inputs top first, the mode that failed
  -- every task of one authoring-eval sample. Copied verbatim from count-below
  -- in eval/s7/runs/2026-09-28-haiku-c6a964a/haiku-firth-1/answer-2.md. The
  -- report names what every misordered block binds, in every word at once,
  -- and the blocks it says to write make the program check.
  let reversedLocals := ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)\n  locals { k xs } {\n    0 0 xs k helper-count\n  };\n\n: helper-count\n  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)\n  locals { k xs idx acc } {\n    idx xs prim seq-int.len prim <\n    [\n      xs idx prim seq-int.at locals { v } {\n        v k prim <\n        [ acc 1 prim + idx 1 prim + xs k helper-count ]\n        [ acc idx 1 prim + xs k helper-count ]\n        if\n      }\n    ]\n    [ acc ]\n    if\n  };\n"
  let localsNeedles := [
    "`locals { k xs }` in `main` gives `k` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int)",
    "`locals { k xs idx acc }` in `helper-count` gives `k` the value the stack effect calls `acc` (Int)",
    "Write `locals { xs k }` in `main`, and `locals { acc idx xs k }` in `helper-count`",
    "Swapping values with `swap` would not help"]
  match elaboratePipeline pipelineContext reversedLocals agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "reversed locals" "firth.name.locals-order" emitted
      for needle in localsNeedles do
        unless emitted.contains needle do
          fail s!"reversed locals: the report does not say {needle}: {emitted}"
  | _ => fail "reversed locals: expected one diagnostic"
  let suggested := (reversedLocals.replace "locals { k xs }" "locals { xs k }").replace
    "locals { k xs idx acc }" "locals { acc idx xs k }"
  match elaboratePipeline pipelineContext suggested agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "reversed locals: the blocks the report suggests do not check"
  -- What the author saw before: a type error at the call, pointing to `swap`.
  let beforeLocals := "code: firth.type.word-input-mismatch\nmessage: `helper-count` in `main` needs Int Int Seq Int Int on top of the stack, but the stack before it is ρ Int Int Int Seq Int.\nhint: The top value is Seq Int but `helper-count` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation."
  if localsNeedles.all (beforeLocals.contains ·) then
    fail "reversed locals: the report from before this change passes the checks"
  -- Same-typed inputs bound in reverse check and compute the wrong value,
  -- so the refusal is the only report such a program gets.
  match elaboratePipeline pipelineContext ": difference\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { b a } { a b prim - };" agentConfig with
  | .failure [envelope] =>
      unless (encode envelope).contains "Write `locals { a b }` in `difference`" do
        fail s!"reversed same-typed locals: {encode envelope}"
  | _ => fail "reversed same-typed locals were accepted"
  -- The hint is applied as written: the test reads the block, the names to
  -- write for others and the names to start the body with out of the hint
  -- text, edits the source with them, and requires the result to check and
  -- to compute, on sample inputs, the value worked out by hand from what
  -- each declared name means. A plain reordering takes no body edits.
  let hintOf (envelope : Envelope) : String :=
    match Lean.Json.parse (encode envelope) with
    | .ok json => (((json.getObjValD "body").getObjValD "message_params").getObjValD "hint").getStr?.toOption.getD ""
    | .error _ => ""
  let upTo (text marker : String) : String := (text.splitOn marker).headD ""
  let applyLocalsHint (source hint : String) : Option String :=
    match (hint.splitOn "Write `locals { ")[1]? with
    | none => none
    | some afterWrite =>
      let block := upTo afterWrite " }`"
      let renames := ((hint.splitOn "write `").drop 1).filterMap fun piece =>
        match piece.splitOn "` for `" with
        | input :: rest :: _ => some (upTo rest "`", input)
        | _ => none
      let prelude := match (hint.splitOn "start the body with `")[1]? with
        | some rest => (upTo rest "`").splitOn " "
        | none => []
      match source.splitOn "locals { " with
      | [head, tail] =>
          match tail.splitOn " } { " with
          | [_, rest] =>
              match rest.splitOn " }" with
              | body :: after =>
                  let tokens := ((body.splitOn " ").filter (· != "")).map fun token =>
                    (renames.lookup token).getD token
                  some (head ++ "locals { " ++ block ++ " } { " ++ " ".intercalate (prelude ++ tokens) ++ " }" ++
                    " }".intercalate after)
              | [] => none
          | _ => none
      | _ => none
  -- Runs `word` of a checked program on the reference interpreter, with
  -- `inputs` given bottom to top, and returns the Int stack it leaves.
  let runWord (program : CheckedProgram) (word : String) (inputs : List Int) : Option (List Int) :=
    let toProgram (kernel : KernelProgram) : Firth.Interpreter.Program :=
      kernel.foldr (fun located rest => .cons located.atom rest) .empty
    let dictionary : Firth.Interpreter.Dictionary := fun name =>
      (program.words.find? (·.name == name)).map fun checked =>
        { type := Firth.ReferenceRun.adapterWordType, body := toProgram checked.program }
    let rec go : Nat → Firth.Interpreter.Config → Option Firth.Interpreter.Stack
      | 0, _ => none
      | fuel + 1, config =>
          match Firth.Interpreter.step Firth.ReferenceRun.adapterGamma dictionary Firth.Interpreter.defaultCosts config with
          | .terminal final => some final.stack
          | .stuck _ => none
          | .stepped next _ => go fuel next
    let start := (inputs.map fun value => Firth.Interpreter.Value.literal (.int value)).reverse
    (go 10000 { stack := start, program := .cons (.word word) .empty }).bind fun stack =>
      (stack.reverse.mapM fun
        | .literal (.int value) => some value
        | _ => none)
  let localsCases : List (String × String × String × List String × List Int × List Int) := [
    -- `b` then `a`: the reordered block alone, `a - b`.
    ("reordered names", "sub",
      ": sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { b a } { a b prim - };",
      ["Write `locals { a b }` in `sub`, and keep the body as it is"], [10, 3], [7]),
    -- `a` claims the input `a`, so `x` stands for `b`: `b - a`.
    ("fresh name beside a declared one", "sub",
      ": sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { x a } { x a prim - };",
      ["Write `locals { a b }` in `sub`", "In its body, write `b` for `x`"], [10, 3], [-7]),
    -- `a` names the deeper input, and the body drops the value it expects
    -- on the stack, `b`: the result is `a`.
    ("declared name for a deeper input", "sub",
      ": sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a } { drop a };",
      ["Write `locals { a b }` in `sub`", "Then start the body with `b`"], [10, 3], [10]),
    -- Inputs `n n n2`: `n` claims the first, `n2` the last, and the body
    -- adds the one left on the stack, the second `n`: 10 + (100 - 1).
    ("repeated label", "rep",
      ": rep\n  (forall ρ; ρ n:Int^many n:Int^many n2:Int^many -- ρ r:Int^many)\n  locals { n2 n } { n2 n prim - prim + };",
      ["Write `locals { n n3 n2 }` in `rep`", "Then start the body with `n3`"], [1, 10, 100], [109]),
    -- The body calls a word `b`, so the input `b` is bound as `b2`, and
    -- `x` stands for it: (3 + 10) + 1.
    ("input label that names a word the body calls", "sub",
      ": b\n  (forall ρ; ρ v:Int^many -- ρ r:Int^many)\n  1 prim + ;\n\n: sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { x a } { x a prim + b };",
      ["Write `locals { a b2 }` in `sub`", "In its body, write `b2` for `x`"], [10, 3], [14]),
    -- An input labelled like the word `inc` the body calls, below the one
    -- the block names: the prelude pushes it as `inc2`, and `a` is 5 + 1.
    ("input label that names a word, in the prelude", "sub",
      ": inc\n  (forall ρ; ρ v:Int^many -- ρ r:Int^many)\n  1 prim + ;\n\n: sub\n  (forall ρ; ρ a:Int^many inc:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a } { drop drop a inc };",
      ["Write `locals { a inc2 b }` in `sub`", "Then start the body with `inc2 b`"], [5, 7, 9], [6]),
    -- Another word has a type error of its own; the edit for `sub` is
    -- still checked and stated.
    ("edit beside another word's error", "sub",
      ": bad\n  (forall ρ; ρ v:Int^many -- ρ r:Bool^many)\n  1 prim + ;\n\n: sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { x a } { x a prim - };",
      ["Write `locals { a b }` in `sub`", "In its body, write `b` for `x`"], [10, 3], [-7])]
  for (label, word, source, needles, inputs, expected) in localsCases do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        expectValidCode label "firth.name.locals-order" emitted
        for needle in needles do
          unless emitted.contains needle do
            fail s!"{label}: the report does not say {needle}: {emitted}"
        match applyLocalsHint source (hintOf envelope) with
        | none => fail s!"{label}: the hint could not be applied: {emitted}"
        | some edited =>
            match elaboratePipeline pipelineContext edited agentConfig with
            | .success program =>
                let result := runWord program word inputs
                unless result == some expected do
                  fail s!"{label}: the edited program computes {result} instead of {expected}: {edited}"
            | .failure diagnostics =>
                -- A refusal charged only to another word leaves this one's
                -- edit standing; its value cannot then be run.
                let wordOf (envelope : Envelope) : String :=
                  match Lean.Json.parse (encode envelope) with
                  | .ok json => (((json.getObjValD "body").getObjValD "message_params").getObjValD "word").getStr?.toOption.getD ""
                  | .error _ => ""
                unless diagnostics.all (fun envelope => let owner := wordOf envelope; owner != "" && owner != word) do
                  fail s!"{label}: the edit the hint gives does not check: {edited}: {diagnostics.map encode}"
    | _ => fail s!"{label}: expected one diagnostic"
  -- Blocks whose edit, applied to the word, is refused: the old body only
  -- fits the values the names hold now. The report states no edit, and no
  -- hint edit can be read out of it.
  let uncheckedCases : List (String × String × String) := [
    -- The name `xs` holds `n`, and the body relies on it.
    ("body fits the old binding (types)", "get",
      ": get\n  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Int^many)\n  locals { xs } { xs prim seq-int.at };"),
    -- The prelude would push linear `b` where the body drops a `^many` value.
    ("body fits the old binding (linearity)", "sum",
      ": sum\n  (forall ρ; ρ a:Int^many b:Int^linear c:Int^linear -- ρ r:Int^many)\n  locals { c a } { drop a c prim + };"),
    -- The same as the first, with a later mistake of its own (`true prim +`):
    -- the edit brings the refusal earlier, to `prim seq-int.at`.
    ("body fits the old binding, before a later mistake", "get",
      ": get\n  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Int^many)\n  locals { xs } { xs prim seq-int.at true prim + };")]
  for (label, word, source) in uncheckedCases do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        expectValidCode label "firth.name.locals-order" emitted
        unless emitted.contains s!"In `{word}` the body was written for the values the names hold now, so changing the block alone does not fix it" do
          fail s!"{label}: the report does not fall back: {emitted}"
        if (applyLocalsHint source (hintOf envelope)).isSome then
          fail s!"{label}: the report still states an edit: {emitted}"
    | _ => fail s!"{label}: expected one diagnostic"
  match elaboratePipeline pipelineContext
      s!": pair {repeated} locals \{ n n2 } \{ n n2 prim + } ;" agentConfig with
  | .success _ => pure ()
  | .failure diagnostics =>
      fail s!"the suggested locals block does not check: {diagnostics.map encode}"
  match elaboratePipeline pipelineContext
      s!": pair {repeated} locals \{ n n } \{ n n prim + } ;" agentConfig with
  | .failure [envelope] => expectValidCode "duplicate local" "firth.name.duplicate-local" (encode envelope)
  | _ => fail "a repeated local name was accepted"
  expectEqual "binders keep distinct names" (Firth.Elaborator.localBinders ["xs", "n"]) ["xs", "n"]
  expectEqual "binders skip a name an input uses" (Firth.Elaborator.localBinders ["n", "n", "n2"]) ["n", "n3", "n2"]
  expectEqual "binders number every repeat" (Firth.Elaborator.localBinders ["a", "a", "a"]) ["a", "a2", "a3"]

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
      if emitted.contains "The two branches of the `if` in `keep-positive` whose true branch is `[ x ]` leave different numbers of values. The true branch leaves `x`; the false branch leaves nothing." &&
          emitted.contains "`x` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed" &&
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

  -- Branch mismatches as the authoring eval met them. Each report must name
  -- the operation or the values responsible, from the source as written,
  -- and say which `if` it means. `branchReport` holds those checks, and the
  -- reports the eval recorded before this change must fail them.
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
  -- branch takes a value from below the `if`. The report names the call and
  -- the inputs it takes, and what the branch pushed for it.
  let longestRun := [
    "In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `longest-run-loop` needs 5 values (prev:Int, curr-run:Int, max-run:Int, idx:Int, xs:Seq Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.at`, `1`, `1` and `xs`)",
    "where there is none: everything the word was given is bound to locals or already used",
    "Make the branch push, just before `longest-run-loop`, exactly the values it takes, in this order: prev:Int, curr-run:Int, max-run:Int, idx:Int, xs:Seq Int. The branch already pushes the result of `prim seq-int.at`, `1`, `1` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place"]
  branchReport "longest-run" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)\n  locals { xs } {\n    xs prim seq-int.len 0 prim =\n    [ 0 ]\n    [ xs 0 prim seq-int.at 1 1 xs longest-run-loop ] if\n  };\n\n: longest-run-loop\n  (forall ρ; ρ prev:Int^many curr-run:Int^many max-run:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { prev curr-run max-run idx xs } {\n    idx xs prim seq-int.len prim =\n    [ max-run curr-run prim < [ curr-run ] [ max-run ] if ]\n    [\n      xs idx prim seq-int.at dup prev prim =\n      [ curr-run 1 prim + ] [ 1 swap ] if\n      idx 1 prim +\n      xs\n      longest-run-loop\n    ]\n    if\n  };" longestRun
  -- keep-positive (the same run, answer 1): the false branch pushes the
  -- sequence on top of the element it means to append, so it takes a Seq Int
  -- where there is an Int. Both answers are copied verbatim. The report says
  -- what `prim seq-int.push` takes and what it gets, in order.
  let keepPositive := [
    "In the false branch of the `if` in `keep-positive-loop` whose true branch is `[ drop result ]`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.",
    "Check that it gets the values it should, in its order"]
  branchReport "keep-positive" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)\n  locals { xs } { prim seq-int.empty 0 xs keep-positive-loop };\n\n: keep-positive-loop\n  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)\n  locals { result idx xs } {\n    idx xs prim seq-int.len prim =\n    [ result ]\n    [\n      xs idx prim seq-int.at dup 0 prim <\n      [ drop result ]\n      [ result prim seq-int.push ] if\n      idx 1 prim +\n      xs\n      keep-positive-loop\n    ]\n    if\n  };" keepPositive
  -- The same depth, different types.
  let differentTypes := [
    "the true branch leaves ρ Int and the false branch leaves ρ Bool",
    "the top value is Int after the true branch and Bool after the false branch"]
  branchReport "different types" ": g (forall ρ; ρ -- ρ r:Int^many)\n  0 1 prim < [ 1 ] [ true ] if ;" differentTypes
  -- Two values too many: the report names both, and where they are left.
  let twoExtra := ["The true branch leaves 3 values, bottom to top: `1`, `2` and `3`; the false branch leaves `4`.",
    "The true branch leaves 2 values more than the false branch: `1` and `2` are left below `3`."]
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
      ["In the false branch of the `if` in `lcm` whose true branch is `[ a b prim * ]`, `swap` needs 2 values, but the branch has pushed only 1 value before it (the result of `prim *`).",
        "Remove it, or push the values it should work on first."],
      -- The value the false branch reaches for, computed inside it.
      ": lcm\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    a b gcd\n    a b prim *\n    swap\n    prim -\n    0 prim =\n    [\n      a b prim *\n    ]\n    [\n      a b prim * a b gcd prim -\n    ]\n    if\n  };\n\n: gcd\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    b 0 prim =\n    [ a ]\n    [\n      a b prim =\n      [ b ]\n      [\n        b a b prim - gcd\n      ]\n      if\n    ]\n    if\n  };",
      ": lcm\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    a b gcd\n    a b prim *\n    swap\n    prim -\n    0 prim =\n    [\n      a b prim * drop\n    ]\n    [\n      a b prim * swap prim -\n    ]\n    if\n  };\n\n: gcd\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    b 0 prim =\n    [ a ]\n    [\n      a b prim =\n      [ b ]\n      [\n        b a b prim - gcd\n      ]\n      if\n    ]\n    if\n  };"),
    ("digit-sum (2026-09-27-hard/haiku-firth-2, answer 2)", ": digit-sum-loop\n  (forall ρ; ρ s:Int^many n:Int^many -- ρ r:Int^many)\n  locals { s n } {\n    n 0 prim =\n    [\n      s\n    ]\n    [\n      n 10 prim -\n      0 prim =\n      [\n        s n prim +\n      ]\n      [\n        s n prim - prim +\n        n 10 prim -\n        digit-sum-loop\n      ]\n      if\n    ]\n    if\n  };\n\n: main\n  (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } {\n    0 n digit-sum-loop\n  };",
      ["In the false branch of the `if` in `digit-sum-loop` whose true branch is `[ s n prim + ]`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (the result of `prim -`).",
        "If `prim +` should not be in this branch, remove it."],
      -- The operation that takes it, removed.
      ": digit-sum-loop\n  (forall ρ; ρ s:Int^many n:Int^many -- ρ r:Int^many)\n  locals { s n } {\n    n 0 prim =\n    [\n      s\n    ]\n    [\n      n 10 prim -\n      0 prim =\n      [\n        s n prim +\n      ]\n      [\n        s n prim -\n        n 10 prim -\n        digit-sum-loop\n      ]\n      if\n    ]\n    if\n  };\n\n: main\n  (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } {\n    0 n digit-sum-loop\n  };",
      ": digit-sum-loop\n  (forall ρ; ρ s:Int^many n:Int^many -- ρ r:Int^many)\n  locals { s n } {\n    n 0 prim =\n    [\n      s\n    ]\n    [\n      n 10 prim -\n      0 prim =\n      [\n        s n prim + drop\n      ]\n      [\n        s n prim - prim +\n        n 10 prim -\n        digit-sum-loop\n      ]\n      if\n    ]\n    if\n  };\n\n: main\n  (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } {\n    0 n digit-sum-loop\n  };")]
  for (label, source, needles, fixed, earlier) in fixtures do
    branchReport label source needles
    noEvening label source
    checks s!"{label}, with the suggested edit" fixed true
    checks s!"{label}, with the earlier suggested edit" earlier false
  noEvening "longest-run" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)\n  locals { xs } {\n    xs prim seq-int.len 0 prim =\n    [ 0 ]\n    [ xs 0 prim seq-int.at 1 1 xs longest-run-loop ] if\n  };\n\n: longest-run-loop\n  (forall ρ; ρ prev:Int^many curr-run:Int^many max-run:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { prev curr-run max-run idx xs } {\n    idx xs prim seq-int.len prim =\n    [ max-run curr-run prim < [ curr-run ] [ max-run ] if ]\n    [\n      xs idx prim seq-int.at dup prev prim =\n      [ curr-run 1 prim + ] [ 1 swap ] if\n      idx 1 prim +\n      xs\n      longest-run-loop\n    ]\n    if\n  };"
  -- Run 7 (eval/s7/runs/2026-09-28-haiku-c6a964a/haiku-firth-2): answers
  -- copied verbatim, each with the edit its new report suggests and the
  -- report the eval recorded for it, taken from the results file. The edit
  -- must remove the mistake at this `if`: the program either checks or is
  -- refused for something else, elsewhere. Most of these answers have more
  -- than one mistake, so the next report is expected. The recorded report
  -- must fail the needles, which is the planted old message.
  let firstReport (source : String) : Option (String × String) :=
    match elaboratePipeline pipelineContext source agentConfig with
    | .success _ => none
    | .failure [] => none
    | .failure (envelope :: _) =>
        match Lean.Json.parse (encode envelope) with
        | .ok json =>
            let body := json.getObjValD "body"
            some ((body.getObjValD "code").compress,
              ((body.getObjValD "location").getObjValD "range").compress)
        | .error _ => some ("unparsed", "")
  let runSeven : List (String × String × List String × String × String) := [
    ("has-pair-sum (answer 1)",
      ": main\n  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)\n  swap 0 false swap find-pair;\n\n: find-pair\n  (forall ρ; ρ xs:Seq Int^many idx:Int^many found:Bool^many target:Int^many -- ρ found:Bool^many)\n  locals { xs idx found target } {\n    found [\n      true\n    ] [\n      idx xs prim seq-int.len prim < [\n        idx 1 prim + check-pair\n      ] [ false ] if\n    ] if\n  };\n\n: check-pair\n  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many target:Int^many -- ρ found:Bool^many)\n  locals { xs i j target } {\n    j xs prim seq-int.len prim < [\n      i xs prim seq-int.at j xs prim seq-int.at prim + target prim = [\n        true\n      ] [\n        xs i j 1 prim + target check-pair\n      ] if\n    ] [\n      xs i 1 prim + find-pair\n    ] if\n  };\n",
      ["In the true branch `[ idx 1 prim + check-pair ]` of the `if` in `find-pair`, `check-pair` needs 4 values (xs:Seq Int, i:Int, j:Int, target:Int), but the branch has pushed only 1 value before it (the result of `prim +`).",
        "Make the branch push, just before `check-pair`, exactly the values it takes, in this order: xs:Seq Int, i:Int, j:Int, target:Int. The branch already pushes"],
      -- Every input of `check-pair` pushed in the branch, in its order.
      ": main\n  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)\n  swap 0 false swap find-pair;\n\n: find-pair\n  (forall ρ; ρ xs:Seq Int^many idx:Int^many found:Bool^many target:Int^many -- ρ found:Bool^many)\n  locals { xs idx found target } {\n    found [\n      true\n    ] [\n      idx xs prim seq-int.len prim < [\n        xs idx idx 1 prim + target check-pair\n      ] [ false ] if\n    ] if\n  };\n\n: check-pair\n  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many target:Int^many -- ρ found:Bool^many)\n  locals { xs i j target } {\n    j xs prim seq-int.len prim < [\n      i xs prim seq-int.at j xs prim seq-int.at prim + target prim = [\n        true\n      ] [\n        xs i j 1 prim + target check-pair\n      ] if\n    ] [\n      xs i 1 prim + find-pair\n    ] if\n  };\n",
      "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `find-pair` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.\nhint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake."),
    ("sort (answer 1)",
      ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)\n  dup prim seq-int.len 0 insertion-sort;\n\n: insertion-sort\n  (forall ρ; ρ xs:Seq Int^many len:Int^many idx:Int^many -- ρ sorted:Seq Int^many)\n  locals { xs len idx } {\n    idx len prim < [\n      idx xs insert-at xs len idx 1 prim + insertion-sort\n    ] [ xs ] if\n  };\n\n: insert-at\n  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ sorted:Seq Int^many)\n  locals { xs idx } {\n    idx 0 prim = [\n      xs\n    ] [\n      idx 1 prim - xs prim seq-int.at idx xs prim seq-int.at prim < [\n        idx 1 prim - idx xs prim seq-int.at xs prim seq-int.set\n        idx 1 prim - xs prim seq-int.at xs idx 1 prim - prim seq-int.set\n        idx 1 prim - xs insert-at\n      ] [ xs ] if\n    ] if\n  };\n",
      ["The true branch leaves 2 values, bottom to top: the result of `insert-at` and the result of `insertion-sort`; the false branch leaves `xs`.",
        "the result of `insert-at` is left below the result of `insertion-sort`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it"],
      -- The result of `insert-at` passed to `insertion-sort` as its sequence.
      -- The edit also puts `insert-at`'s arguments in its order (`xs idx`),
      -- a second mistake the report does not name.
      ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)\n  dup prim seq-int.len 0 insertion-sort;\n\n: insertion-sort\n  (forall ρ; ρ xs:Seq Int^many len:Int^many idx:Int^many -- ρ sorted:Seq Int^many)\n  locals { xs len idx } {\n    idx len prim < [\n      xs idx insert-at len idx 1 prim + insertion-sort\n    ] [ xs ] if\n  };\n\n: insert-at\n  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ sorted:Seq Int^many)\n  locals { xs idx } {\n    idx 0 prim = [\n      xs\n    ] [\n      idx 1 prim - xs prim seq-int.at idx xs prim seq-int.at prim < [\n        idx 1 prim - idx xs prim seq-int.at xs prim seq-int.set\n        idx 1 prim - xs prim seq-int.at xs idx 1 prim - prim seq-int.set\n        idx 1 prim - xs insert-at\n      ] [ xs ] if\n    ] if\n  };\n",
      "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `insertion-sort` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 1 value. So the true branch leaves 1 value more than the false branch.\nhint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack."),
    ("all-true (answer 2)",
      ": main\n  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)\n  dup prim seq-bool.len 0 prim = [\n    drop true\n  ] [\n    swap 0 true all-loop\n  ] if;\n\n: all-loop\n  (forall ρ; ρ flags:Seq Bool^many idx:Int^many result:Bool^many -- ρ all:Bool^many)\n  locals { flags idx result } {\n    result [\n      idx flags prim seq-bool.len prim < [\n        idx flags prim seq-bool.at [\n          flags idx 1 prim + true all-loop\n        ] [\n          false flags idx 1 prim + all-loop\n        ] if\n      ] [ true ] if\n    ] [ false ] if\n  };\n",
      ["In the false branch of the `if` in `main` whose true branch is `[ drop true ]`, `swap` needs 2 values, but the branch has pushed nothing before it. It would take the input `flags` from below the `if`, and 1 value more that is not there",
        "Check whether `swap` belongs in this branch"],
      -- The `swap` removed.
      ": main\n  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)\n  dup prim seq-bool.len 0 prim = [\n    drop true\n  ] [\n    0 true all-loop\n  ] if;\n\n: all-loop\n  (forall ρ; ρ flags:Seq Bool^many idx:Int^many result:Bool^many -- ρ all:Bool^many)\n  locals { flags idx result } {\n    result [\n      idx flags prim seq-bool.len prim < [\n        idx flags prim seq-bool.at [\n          flags idx 1 prim + true all-loop\n        ] [\n          false flags idx 1 prim + all-loop\n        ] if\n      ] [ true ] if\n    ] [ false ] if\n  };\n",
      "code: firth.type.branch-mismatch\nmessage: The false branch of `if` in `main` cannot run on the stack it is given. Below the condition and the two quotations the stack is ρ Seq Bool, but the false branch takes .. Seq Bool ?t2.\nexpected: .. Seq Bool ?t2\nactual: ρ Seq Bool\nhint: The top value there is Seq Bool, but the false branch expects ?t2. Check the order of the values the branch uses (`swap` exchanges the top two), or what was pushed before the condition. Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack."),
    ("ledger (answer 3)",
      ": main\n  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)\n  0 swap 0 process-txns;\n\n: process-txns\n  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ final-bal:Int^many final-rej:Int^many)\n  locals { balance rejected txs idx } {\n    idx txs prim seq-int.len prim < [\n      balance idx txs prim seq-int.at prim + dup 0 prim < [\n        drop balance rejected 1 prim + txs idx 1 prim + process-txns\n      ] [\n        balance rejected txs idx 1 prim + process-txns\n      ] if\n    ] [ balance rejected ] if\n  };\n",
      ["The true branch takes the result of `prim +` from below the `if` and leaves 2 values, bottom to top: the output `final-bal` of `process-txns` and the output `final-rej` of `process-txns`",
        "The true branch takes the result of `prim +` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there"],
      -- The false branch uses the new balance instead of the old one.
      ": main\n  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)\n  0 swap 0 process-txns;\n\n: process-txns\n  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ final-bal:Int^many final-rej:Int^many)\n  locals { balance rejected txs idx } {\n    idx txs prim seq-int.len prim < [\n      balance idx txs prim seq-int.at prim + dup 0 prim < [\n        drop balance rejected 1 prim + txs idx 1 prim + process-txns\n      ] [\n        rejected txs idx 1 prim + process-txns\n      ] if\n    ] [ balance rejected ] if\n  };\n",
      "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `process-txns` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 2 values, and the false branch pushes 2 values. So the false branch leaves 1 value more than the true branch.\nhint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack."),
    ("reverse (answer 2)",
      ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)\n  dup prim seq-int.len prim seq-int.empty swap 0 reverse-loop;\n\n: reverse-loop\n  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many len:Int^many idx:Int^many -- ρ reversed:Seq Int^many)\n  locals { result xs len idx } {\n    idx len prim < [\n      len idx 1 prim - prim - xs prim seq-int.at result prim seq-int.push\n      result xs len idx 1 prim + reverse-loop\n    ] [ result ] if\n  };\n",
      ["The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-loop`; the false branch leaves `result`.",
        "the result of `prim seq-int.push` is left below the result of `reverse-loop`"],
      -- The pushed sequence passed on instead of the old `result`.
      ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)\n  dup prim seq-int.len prim seq-int.empty swap 0 reverse-loop;\n\n: reverse-loop\n  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many len:Int^many idx:Int^many -- ρ reversed:Seq Int^many)\n  locals { result xs len idx } {\n    idx len prim < [\n      len idx 1 prim - prim - xs prim seq-int.at result prim seq-int.push\n      xs len idx 1 prim + reverse-loop\n    ] [ result ] if\n  };\n",
      "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `reverse-loop` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 1 value. So the true branch leaves 1 value more than the false branch.\nhint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.")]
  for (label, source, needles, fixed, recorded) in runSeven do
    branchReport label source needles
    noEvening label source
    match firstReport source, firstReport fixed with
    | some (_, at_), some (code, again) =>
        if at_ == again then
          fail s!"{label}: the suggested edit leaves a report ({code}) at the same `if`"
    | none, _ => fail s!"{label}: the answer was accepted"
    | some _, none => pure ()
    unless needlesMissing recorded needles do
      fail s!"{label}: the report the eval recorded already says what the new one does"
  -- The planted wrong edit: pushing only some of the values `check-pair`
  -- takes leaves the report at the same `if`, which the check above refuses.
  match runSeven.head? with
  | some (_, source, _, _, _) =>
      let short := source.replace "idx 1 prim + check-pair" "idx 1 prim + target check-pair"
      if short == source then fail "has-pair-sum: the planted edit did not apply"
      match firstReport source, firstReport short with
      | some (_, at_), some (_, again) =>
          unless at_ == again do fail "has-pair-sum: the planted edit moved the report"
      | _, _ => fail "has-pair-sum: the planted edit was accepted"
  | none => fail "run 7: no fixtures"
  -- all-true, answer 1: the true branch drops twice, and only the second
  -- `drop` finds nothing. The report names that `drop` and the input the
  -- first one took; removing it leaves the false branch's `swap`, which the
  -- report then names at the same `if`.
  let allTrueFirst := ": main\n  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)\n  dup prim seq-bool.len 0 prim = [\n    drop drop true\n  ] [\n    swap 0 true all-loop\n  ] if;\n\n: all-loop\n  (forall ρ; ρ flags:Seq Bool^many idx:Int^many result:Bool^many -- ρ all:Bool^many)\n  locals { flags idx result } {\n    result [\n      idx flags prim seq-bool.len prim < [\n        idx flags prim seq-bool.at [\n          flags idx 1 prim + true all-loop\n        ] [\n          false flags idx 1 prim + all-loop\n        ] if\n      ] [ true ] if\n    ] [ false ] if\n  };\n"
  let allTrueNeedles := ["In the true branch `[ drop drop true ]` of the `if` in `main`, `drop` needs 1 value, but the branch has pushed nothing before it. Earlier in the branch, the input `flags` was already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none"]
  branchReport "all-true (answer 1)" allTrueFirst allTrueNeedles
  branchReport "all-true (answer 1, one `drop` removed)"
    (allTrueFirst.replace "drop drop true" "drop true")
    ["In the false branch of the `if` in `main` whose true branch is `[ drop true ]`, `swap` needs 2 values"]
  unless needlesMissing "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 2 values. The `if` takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.\nhint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake." allTrueNeedles do
    fail "all-true (answer 1): the report the eval recorded already says what the new one does"
  -- A word whose effect has no row constrains the whole stack, not only
  -- its inputs, which the account does not model: the report keeps the
  -- checker's own account instead of naming what `h` gets.
  match elaboratePipeline pipelineContext ": h ( x:Int^many -- y:Int^many ) ;\n\n: g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) true [ h ] [ ] if prim + ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "closed word" "firth.type.branch-mismatch" emitted
      unless emitted.contains "The true branch of `if` in `g` cannot run on the stack it is given." do
        fail s!"closed word: the report does not keep the checker's account: {emitted}"
      if emitted.contains "`h` takes" || emitted.contains "`h` needs" then
        fail s!"closed word: the report accounts for `h` as if it kept the stack below: {emitted}"
  | _ => fail "closed word: expected one diagnostic"
  -- A branch that reaches below the `if` with `dup`, which takes a value of
  -- any type, and then fails on the type `prim +` needs: `dup` is not to
  -- blame, so the report keeps the checker's typed account.
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ b:Bool^many -- ρ r:Int^many) true [ dup prim + ] [ drop 0 ] if ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "dup before prim +" "firth.type.branch-mismatch" emitted
      if emitted.contains "`dup` takes" then
        fail s!"dup before prim +: the report blames `dup`: {emitted}"
      unless emitted.contains "cannot run on the stack it is given" do
        fail s!"dup before prim +: the report does not keep the checker's account: {emitted}"
  | _ => fail "dup before prim +: expected one diagnostic"
  -- The first `prim +` takes `b`, an Int as it needs; the second takes `a`,
  -- a Bool. The first is not to blame, so the report keeps the checker's
  -- typed account rather than saying what the first `prim +` gets.
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ a:Bool^many b:Int^many -- ρ r:Int^many) true [ 1 prim + prim + ] [ drop drop 0 ] if ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "second prim +" "firth.type.branch-mismatch" emitted
      if emitted.contains "`prim +` takes" then
        fail s!"second prim +: the report blames the first `prim +`: {emitted}"
  | _ => fail "second prim +: expected one diagnostic"
  -- max, copied verbatim from eval/s7/runs/2026-09-27-plus-only/haiku-firth,
  -- solutions-1.json: the `swap` before the `if` decides which input each
  -- branch takes, so the report names them only if the walk exchanges them.
  branchReport "max (swap before the if)" ": main\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  swap dup [ drop drop ] [ drop ] if;\n"
    ["The true branch takes the input `a` and the input `b` from below the `if` and leaves nothing; the false branch takes the input `a` from below the `if` and leaves nothing."]
  -- A `swap` inside the branch: after it `a` is on top, so the `drop`
  -- uses up `a` and the branch leaves `b`, the value it took and put back.
  branchReport "swap in a branch" ": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) true [ swap drop ] [ ] if ;"
    ["The true branch takes the input `b` and the input `a` from below the `if` and leaves the input `b`; the false branch leaves nothing.",
      "The true branch takes the input `a` from below the `if`, and the false branch leaves it in place"]
  -- A nested `if` whose true path leaves `a` in place and whose false path
  -- takes it and pushes `0`: what the outer true branch takes depends on
  -- which runs, so the walk stops there and the report keeps the checker's
  -- account rather than following the true path alone.
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) true [ true [ ] [ drop 0 ] if ] [ drop ] if ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "nested paths differ" "firth.type.branch-mismatch" emitted
      unless emitted.contains "The two branches of `if` in `g` leave different numbers of values" do
        fail s!"nested paths differ: the report does not keep the checker's account: {emitted}"
      if emitted.contains "the input `a` from below the `if`" || emitted.contains "leaves it in place" then
        fail s!"nested paths differ: the report follows one path of the nested `if`: {emitted}"
  | _ => fail "nested paths differ: expected one diagnostic"
  -- Nested paths whose histories differ, each where following the true
  -- path alone misreports: `a` stays in place on one path and is taken on
  -- the other; one path misses one value and the other two; the paths
  -- first reach below with different operations, or with the same one
  -- after pushing different numbers of values, or taking different values
  -- from below and missing different numbers. Each report keeps the
  -- checker's account.
  let differentNumbers := "The two branches of `if` in `g` leave different numbers of values"
  let threeInputs := ": h (forall ρ; ρ x:Int^many y:Int^many z:Int^many -- ρ r:Int^many) prim + prim + ;\n\n"
  for (label, source) in [
      ("nested paths leave different values in place",
        ": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) true [ true [ drop 0 ] [ drop drop 0 0 ] if ] [ drop ] if ;"),
      ("nested paths miss different numbers",
        ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) true [ true [ drop drop 0 0 ] [ drop drop drop 0 0 0 ] if prim + ] [ ] if ;"),
      ("nested paths reach with different operations",
        ": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) true [ true [ swap drop ] [ prim + ] if ] [ ] if ;"),
      ("nested paths reach after pushing different numbers of values",
        threeInputs ++ ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) true [ true [ 1 h ] [ dup h ] if ] [ ] if ;"),
      ("nested paths reach taking different values below",
        ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) true [ true [ prim + drop drop ] [ drop prim + drop ] if ] [ ] if ;")] do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        expectValidCode label "firth.type.branch-mismatch" emitted
        unless emitted.contains differentNumbers do
          fail s!"{label}: the report does not keep the checker's account: {emitted}"
    | _ => fail s!"{label}: expected one diagnostic"
  -- An `if` before the refused one whose paths first reach below with
  -- different operations (`prim +` and `prim -`, each short of a value)
  -- but leave the same stack, as in `find-longest` (470c6d0 longest-run
  -- answer 2) before its `swap` is followed: the reaches are dropped
  -- when the refused `if`'s branches start, so only the stacks must agree
  -- and the account is kept.
  branchReport "paths reach differently before the refused if"
    ": g (forall ρ; ρ x:Int^many -- ρ r:Int^many) locals { x } { true [ x prim + ] [ x prim - ] if true [ 1 ] [ ] if } ;"
    ["The true branch leaves `1`; the false branch leaves nothing."]
  -- Two quotations whose labels agree, since a label shows only a long
  -- quotation's start, but whose bodies differ: an earlier `if` pushes one
  -- or the other, so a later `call` runs neither body, and the report keeps
  -- the checker's account instead of naming the true path's `prim +`.
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ -- ρ r:Int^many) true [ [ 1 1 1 1 1 1 1 1 drop drop drop drop drop drop drop prim + ] ] [ [ 1 1 1 1 1 1 1 1 drop drop drop drop drop drop drop prim - ] ] if true [ call ] [ ] if ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "quotations with one label" "firth.type.branch-mismatch" emitted
      if emitted.contains "`prim +`" then
        fail s!"quotations with one label: the report runs the true path's quotation: {emitted}"
  | _ => fail "quotations with one label: expected one diagnostic"
  -- The same operation reached after as many values on both paths, which
  -- differ: the report names both.
  branchReport "nested paths push different values"
    ": g (forall ρ; ρ -- ρ r:Int^many) true [ true [ 0 prim + ] [ 1 prim + ] if ] [ ] if ;"
    ["`prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`0` or `1`)."]
  -- A branch that pushes one of the two values `prim +` takes: the hint
  -- keeps `1` and asks for the other, instead of asking for both, which
  -- would leave `1` over.
  let pushedOne := ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) drop true [ 1 prim + ] [ 0 ] if ;"
  branchReport "branch pushed one operand" pushedOne
    ["`prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`).",
      "Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place"]
  match elaboratePipeline pipelineContext pushedOne agentConfig with
  | .failure [envelope] =>
      if (encode envelope).contains "Push every value" then
        fail s!"branch pushed one operand: the hint asks for every value again: {encode envelope}"
  | _ => pure ()
  -- `1` has the type of either input of `prim +`, so the hint does not
  -- say on which side the missing one goes. A pushed value of the wrong
  -- type matches neither side; the hint says to replace it.
  branchReport "branch pushed a Bool operand" ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) drop true [ true prim + ] [ 0 ] if ;"
    ["The branch already pushes `true`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place"]
  -- The pushed value has the type of the operation's last input only, so
  -- the missing first one goes before it: for `prim seq-int.push` after
  -- `1`, the sequence.
  branchReport "branch pushed the top operand" ": g (forall ρ; ρ a:Int^many -- ρ r:Seq Int^many) drop true [ 1 prim seq-int.push ] [ prim seq-int.empty ] if ;"
    ["The branch already pushes `1`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it"]
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ a:Int^many -- ρ r:Seq Int^many) drop true [ prim seq-int.empty 1 prim seq-int.push ] [ prim seq-int.empty ] if ;" agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "branch pushed the top operand: the program following the hint is refused"
  -- The pushed values fit the inputs in one way only, as the first ones,
  -- so the missing last one goes after them.
  let takesThree := ": f (forall ρ; ρ xs:Seq Int^many n:Int^many b:Bool^many -- ρ r:Int^many) locals { xs n b } { n } ;\n\n"
  let pushedFirst := takesThree ++ ": g (forall ρ; ρ xs:Seq Int^many b:Bool^many -- ρ r:Int^many) locals { xs b } { true [ xs 1 f ] [ 0 ] if } ;"
  branchReport "branch pushed the first operands" pushedFirst
    ["The branch already pushes `xs` and `1`, in the place of the first 2 (xs:Seq Int, n:Int): keep each where it has that type and replace it where it does not. Then push the last one (b:Bool) after them"]
  -- Following the hint as written: the name before the colon of the input
  -- it asks for, written after the values the branch pushes.
  match elaboratePipeline pipelineContext pushedFirst agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      match (emitted.splitOn "Then push the last one (").drop 1 with
      | rest :: _ =>
          let name := ((rest.splitOn ":").headD "").trimAscii.toString
          let followed := pushedFirst.replace "[ xs 1 f ]" s!"[ xs 1 {name} f ]"
          match elaboratePipeline pipelineContext followed agentConfig with
          | .success _ => pure ()
          | .failure _ => fail s!"branch pushed the first operands: the program following the hint (`{name}` after `1`) is refused"
      | [] => fail s!"branch pushed the first operands: the hint names no last input: {emitted}"
  | _ => fail "branch pushed the first operands: expected one diagnostic"
  -- A primitive's inputs are compared without their usage, as a word's
  -- inputs are recorded: `w` and `h` are the World and Handle `prim send`
  -- takes first, so the missing Bytes goes after them (Codex on #166).
  branchReport "send short of its Bytes" ": g ( forall ρ; ρ w:World^linear h:Handle^linear b:Bool^many -- ρ w:World^linear ) locals { w h b } { b [ w h prim send ] [ 0 ] if } ;"
    ["The branch already pushes `w` and `h`, in the place of the first 2 (World^linear, Handle^linear): keep each where it has that type and replace it where it does not. Then push the last one (Bytes^linear) after them"]
  -- Where the pushed values fit the inputs in more than one way, the hint
  -- names no side: Haiku's histogram answer at c6a964a (haiku-firth-2,
  -- solutions-1) pushes `0 xs idx` for `count-value (cnt xs idx v)`, which
  -- fits as the first three or with `idx` as `v`, and longest-run above
  -- pushes four values for five inputs, where the missing `idx` goes in the
  -- middle (review of #166), which the right edit shows.
  branchReport "histogram at c6a964a" ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)\n  swap prim seq-int.empty 0 0 build-histogram swap drop;\n\n: build-histogram\n  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many k:Int^many v:Int^many idx:Int^many -- ρ counts:Seq Int^many)\n  locals { xs result k v idx } {\n    v k prim < [\n      0 xs idx count-value result prim seq-int.push xs k v 1 prim + build-histogram\n    ] [ result ] if\n  };\n\n: count-value\n  (forall ρ; ρ cnt:Int^many xs:Seq Int^many idx:Int^many v:Int^many -- ρ count:Int^many)\n  locals { cnt xs idx v } {\n    idx xs prim seq-int.len prim < [\n      idx xs prim seq-int.at v prim = [\n        cnt 1 prim +\n      ] [ cnt ] if\n      xs idx 1 prim + v count-value\n    ] [ cnt ] if\n  };"
    ["The branch already pushes `0`, `xs` and `idx`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place"]
  match elaboratePipeline pipelineContext ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)\n  locals { xs } {\n    xs prim seq-int.len 0 prim =\n    [ 0 ]\n    [ xs 0 prim seq-int.at 1 1 0 xs longest-run-loop ] if\n  };\n\n: longest-run-loop\n  (forall ρ; ρ prev:Int^many curr-run:Int^many max-run:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { prev curr-run max-run idx xs } { max-run } ;" agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "longest-run: the edit that puts `idx` in the middle is refused"
  -- Where an operation is handed values of types no order of its inputs
  -- fits, the walk has handed out values meant for another operation, and
  -- nothing after it is blamed: Haiku's histogram answer at c6a964a
  -- (haiku-firth-2, solutions-3) leaves out `v` in `result 0 xs 0
  -- count-value`, so the walk gives `result` to `count-value` as `cnt`.
  -- Blaming `prim seq-int.push` and asking for `result` before
  -- `count-value`'s result sends the author to an edit that is refused
  -- (review of #166); the checker's account is kept, and the right edit,
  -- the missing `v`, makes `build-histogram` check.
  let histogramMissingV := ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)\n  swap prim seq-int.empty swap 0 0 build-histogram;\n\n: build-histogram\n  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many k:Int^many v:Int^many -- ρ counts:Seq Int^many)\n  locals { xs result k v } {\n    v k prim < [\n      result 0 xs 0 count-value prim seq-int.push xs k v 1 prim + build-histogram\n    ] [ result ] if\n  };\n\n: count-value\n  (forall ρ; ρ cnt:Int^many xs:Seq Int^many idx:Int^many v:Int^many -- ρ count:Int^many)\n  locals { cnt xs idx v } {\n    idx xs prim seq-int.len prim < [\n      idx xs prim seq-int.at v prim = [\n        cnt 1 prim +\n      ] [ cnt ] if\n      xs idx 1 prim + v count-value\n    ] [ cnt ] if\n  };"
  match elaboratePipeline pipelineContext histogramMissingV agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      if (emitted.splitOn "seq-int.push").length > 1 || (emitted.splitOn "push `result`").length > 1 then
        fail s!"histogram missing `v`: the account blames the push: {emitted}"
      if (emitted.splitOn "belongs to the caller").length == 1 then
        fail s!"histogram missing `v`: expected the checker's account: {emitted}"
  | _ => fail "histogram missing `v`: expected one diagnostic"
  -- With `v`, `build-histogram` checks; what is left is a separate
  -- mistake in `main`, which leaves an extra value.
  match elaboratePipeline pipelineContext (histogramMissingV.replace "result 0 xs 0 count-value" "result 0 xs 0 v count-value") agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      if (emitted.splitOn "declared-effect-mismatch").length == 1 || (emitted.splitOn "`main` declares").length == 1 then
        fail s!"histogram missing `v`: with `v`, expected only `main`'s extra value: {emitted}"
  | _ => fail "histogram missing `v`: with `v`, expected one diagnostic about `main`"
  -- The same mistake where `count-value` also takes a value from below the
  -- `if`, `result`: it is misfed too, and the later `prim seq-int.push`,
  -- which reaches past the bottom, replaces it as the reach. The report must
  -- not tell the author to push a Seq Int before `count-value`'s result
  -- (`xs 0 xs 0 count-value` is refused); the fix is the missing `v`
  -- (review of #166).
  let misfedFromBelow := ": w\n  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many v:Int^many c:Bool^many -- ρ r:Seq Int^many)\n  locals { xs v c } { c [ 0 xs 0 count-value prim seq-int.push ] [ ] if };\n\n: count-value\n  (forall ρ; ρ cnt:Int^many xs:Seq Int^many idx:Int^many v:Int^many -- ρ count:Int^many)\n  locals { cnt xs idx v } {\n    idx xs prim seq-int.len prim < [\n      xs idx prim seq-int.at v prim = [\n        cnt 1 prim +\n      ] [ cnt ] if\n      xs idx 1 prim + v count-value\n    ] [ cnt ] if\n  };"
  match elaboratePipeline pipelineContext misfedFromBelow agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      if (emitted.splitOn "prim seq-int.push` needs").length > 1 || (emitted.splitOn "Then push the first").length > 1 then
        fail s!"misfed from below: the report blames the push: {emitted}"
  | _ => fail "misfed from below: expected one diagnostic"
  match elaboratePipeline pipelineContext (misfedFromBelow.replace "0 xs 0 count-value" "0 xs 0 v count-value") agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "misfed from below: the program with `v` is refused"
  -- A reach recorded before the misfed operation is still reported: up to
  -- it, the walk hands out the values the program does.
  branchReport "reach before a misfed operation" ": w\n  (forall ρ; ρ result:Seq Int^many a:Int^many xs:Seq Int^many c:Bool^many -- ρ r:Int^many)\n  locals { xs c } { c [ 1 prim + drop 0 xs 0 count-value drop ] [ drop ] if };\n\n: count-value\n  (forall ρ; ρ cnt:Int^many xs:Seq Int^many idx:Int^many v:Int^many -- ρ count:Int^many)\n  locals { cnt xs idx v } {\n    idx xs prim seq-int.len prim < [\n      xs idx prim seq-int.at v prim = [\n        cnt 1 prim +\n      ] [ cnt ] if\n      xs idx 1 prim + v count-value\n    ] [ cnt ] if\n  };"
    ["The true branch takes the input `a` and the input `result` from below the `if` and leaves nothing; the false branch takes the input `a` from below the `if` and leaves nothing."]
  -- A quotation's locals are those where it was written: `[ a ]` pushes the
  -- outer `a:Int`, though it runs where `a` is the Seq Int. So `a` stands
  -- for the last input of `prim seq-int.push`, and the Seq Int goes before
  -- it (review of #166).
  let captured := ": w (forall ρ; ρ a:Int^many b:Seq Int^many c:Bool^many -- ρ r:Seq Int^many) locals { a b c } { c [ [ a ] b locals { a } { call prim seq-int.push } ] [ b ] if } ;"
  branchReport "captured local" captured
    ["The branch already pushes `a`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it"]
  match elaboratePipeline pipelineContext (captured.replace "{ call prim" "{ a swap call prim") agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "captured local: the program following the hint is refused"
  -- Following the hint, with `2` as the other value, makes the program check.
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) drop true [ 2 1 prim + ] [ 0 ] if ;" agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "branch pushed one operand: the program following the hint is refused"
  -- The same two cases with a word instead of `prim +`: `add` declares
  -- `x:Int y:Int`. Where it gets a Bool from below the `if` it is to blame
  -- and the report says what it gets; where it gets the Int it declares, a
  -- later `prim not` is, and the checker's account is kept.
  let addWord := ": add (forall ρ; ρ x:Int^many y:Int^many -- ρ r:Int^many) prim + ;\n\n"
  branchReport "word given a Bool" (addWord ++ ": g (forall ρ; ρ a:Bool^many -- ρ r:Int^many) true [ 1 add ] [ drop 0 ] if ;")
    ["In the true branch `[ 1 add ]` of the `if` in `g`, `add` takes 2 values (x:Int, y:Int, bottom to top). It gets, bottom to top, the input `a` from below the `if` and `1`."]
  match elaboratePipeline pipelineContext (addWord ++ ": g (forall ρ; ρ a:Bool^many b:Int^many -- ρ r:Int^many) true [ 1 add drop 1 prim + ] [ drop drop 0 ] if ;") agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "word given its Int" "firth.type.branch-mismatch" emitted
      if emitted.contains "`add` takes" then
        fail s!"word given its Int: the report blames `add`: {emitted}"
  | _ => fail "word given its Int: expected one diagnostic"
  -- Values from below the `if` are named bottom to top, as the word's
  -- inputs were given.
  branchReport "two inputs from below"
    ": h (forall ρ; ρ x:Int^many y:Int^many z:Int^many -- ρ r:Int^many) prim + prim + ;\n\n: g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) true [ h ] [ prim + ] if ;"
    ["In the true branch `[ h ]` of the `if` in `g`, `h` needs 3 values (x:Int, y:Int, z:Int), but the branch has pushed nothing before it. It would take the input `a` and the input `b` from below the `if`, and 1 value more that is not there"]
  -- A branch that cannot run on the stack it is given keeps the compared
  -- stacks in the envelope and in the `expected` and `actual` params, which
  -- the authoring harness prints as its expected: and actual: lines.
  -- filter-helper, copied verbatim from the keep-positive answer in
  -- eval/s7/runs/2026-09-28-haiku-470c6d0/haiku-firth-2/answer-2.md.
  match elaboratePipeline pipelineContext ": filter-helper\n  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ filtered:Seq Int^many)\n  locals { i result xs } {\n    i xs prim seq-int.len prim <\n    [ \n      xs i prim seq-int.at\n      dup 0 prim <\n      [ drop result ]\n      [ result prim seq-int.push ]\n      if\n      i 1 prim + swap xs filter-helper\n    ]\n    [ result ]\n    if\n  };\n\n: main\n  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)\n  locals { xs } { 0 prim seq-int.empty xs filter-helper };" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "filter-helper" "firth.type.branch-mismatch" emitted
      for needle in ["In the false branch of the `if` in `filter-helper` whose true branch is `[ drop result ]`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.",
          "\"expected\":\".. Seq Int\"", "\"actual\":\".. Seq Int Int Int\""] do
        unless emitted.contains needle do
          fail s!"filter-helper: the report does not say {needle}: {emitted}"
      unless emitted.contains (structuredStack "expected_stack" ".. Seq Int") &&
          emitted.contains (structuredStack "actual_stack" ".. Seq Int Int Int") do
        fail s!"filter-helper: the envelope's stacks are not the branch's input and the stack below the condition: {emitted}"
  | _ => fail "filter-helper: expected one diagnostic"
  -- Counts and types both differ: the report names the values each branch
  -- leaves and offers no `drop`, which would still leave Int against Bool.
  branchReport "counts and types" ": g (forall ρ; ρ -- ρ r:Int^many)\n  0 1 prim < [ 1 true ] [ false ] if ;"
    ["The true branch leaves 2 values, bottom to top: `1` and `true`; the false branch leaves `false`.",
      "`1` is left below `true`"]
  -- The reports these programs got before this change: the two the eval
  -- recorded at cec3707, verbatim, and the locals-pass report that main gave
  -- longest-run from #145 on. Each must fail the checks above, or the checks
  -- prove nothing.
  let recordedBefore := [
    ("longest-run at cec3707", "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `main` leave different stacks.\nexpected: ρ\nactual: .. Int\nhint: Both branches must leave the same number and types of values. Expected ρ, found .. Int.", longestRun),
    ("keep-positive at cec3707", "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `keep-positive-loop` leave different stacks.\nexpected: Int\nactual: Seq Int\nhint: Both branches must leave the same number and types of values. Expected Int, found Seq Int.", keepPositive),
    ("longest-run at c6a964a", "The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller. Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there.", longestRun),
    ("keep-positive at c6a964a", "The false branch of `if` in `keep-positive-loop` cannot run on the stack it is given. Below the condition and the two quotations the stack is .. Seq Int Int Int, but the false branch takes .. Seq Int. The top value there is Int, but the false branch expects Seq Int. Check the order of the values the branch uses (`swap` exchanges the top two), or what was pushed before the condition.", keepPositive),
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
      unless emitted.contains "\"expected\":\".. Int Int\"" && emitted.contains "\"actual\":\".. Int\"" &&
          emitted.contains (structuredStack "expected_stack" ".. Int Int") &&
          emitted.contains (structuredStack "actual_stack" ".. Int") do
        fail s!"branch depth: expected is not the true branch's output or actual is not the false branch's: {emitted}"
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
