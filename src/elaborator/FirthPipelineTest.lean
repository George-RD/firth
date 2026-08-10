import elaborator.Firth.Pipeline

open Firth.Elaborator
open Firth.Elaborator.StackEffect
open Firth.Elaborator.Refinement
open Firth.Smt
open Firth.Interpreter


private def refinementPremises (sourcePath : String) (word : WordDefinition)
    (scheme : Scheme) (declaredPostcondition : RefinementSet)
    (totality : Option TotalityTypingPremises) : BodyTypingPremises :=
  let stack : RefinedStack :=
    { erased := scheme.input, refinements := {} }
  let context : ObligationContext :=
    { wordId := word.name
      bodyHash := "pipeline-test-body"
      erasedWordTypeHash := "pipeline-test-type"
      specHash := "pipeline-test-spec"
      normaliserVersion := "pipeline-test-v1"
      vcGeneratorVersion := "pipeline-test-v1"
      leanToolchainHash := "pipeline-test-lean"
      proofModuleHash := "pipeline-test-proof"
      toolchainRevision := "pipeline-test-revision"
      source := { path := sourcePath, span := word.span }
      expectedStack := stack
      actualStack := { stack with erased := scheme.output } }
  { context
    precondition := {}
    bodySemantics := {}
    declaredPostcondition
    totality }

private def refinementConfig (bodyPredicate : Predicate) : PipelineConfig :=
  { requestId := "pipeline-test"
    sourcePath := "configured-pipeline.firth"
    refinementBuilder := fun _ sourcePath word _ scheme =>
      refinementPremises sourcePath word scheme { conjuncts := [bodyPredicate] } none }

private def totalityEscalationConfig : PipelineConfig :=
  { requestId := "pipeline-test"
    sourcePath := "configured-pipeline.firth"
    refinementBuilder := fun _ sourcePath word _ scheme =>
      refinementPremises sourcePath word scheme {}
        (some
          { premises := {}
            conclusion := { conjuncts := [.nonlinear "terminates"] } }) }

private def mixedUsageConfig : PipelineConfig :=
  let signature : Signature := { input := [.linear], output := [] }
  let scheme : Scheme :=
    { rowVariables := ["ρ"]
      input := .snoc (.row (.rigid "ρ")) (.base "Int" .linear)
      output := .row (.rigid "ρ") }
  { erasureEnv :=
      { primitive := fun name =>
          if name == "consumeLinear" then some signature else none }
    typingEnv :=
      { literal := defaultLiteralType
        primitive := fun name =>
          if name == "consumeLinear" then some scheme else none } }

private def linearUsageConfig : PipelineConfig :=
  let signature : Signature := { input := [.linear], output := [] }
  let scheme : Scheme :=
    { rowVariables := ["ρ"]
      input := .snoc (.row (.rigid "ρ")) (.base "Handle" .linear)
      output := .row (.rigid "ρ") }
  { erasureEnv :=
      { primitive := fun name =>
          if name == "consumeLinear" then some signature else none }
    typingEnv :=
      { literal := defaultLiteralType
        primitive := fun name =>
          if name == "consumeLinear" then some scheme else none } }

private def externalWordConfig : PipelineConfig :=
  let signature : Signature := { input := [], output := [] }
  let scheme : Scheme := { rowVariables := [], input := .empty, output := .empty }
  { erasureEnv :=
      { word := fun name =>
          if name == "helper" then some signature else none }
    typingEnv :=
      { literal := defaultLiteralType
        word := fun name =>
          if name == "helper" then some scheme else none } }

private def fail (message : String) : IO α := throw <| IO.userError message

private def expectTrue (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else fail message

private def expectEq [BEq α] [Repr α] (actual expected : α) (message : String) : IO Unit :=
  if actual == expected then pure ()
  else fail s!"{message}\nactual: {repr actual}\nexpected: {repr expected}"

private def isLinearCopyAtSpan (error : ErasureError) (expectedStart expectedStop : Nat) : Bool :=
  match error with
  | .linearCopy name sourceSpan =>
      name == "h" && sourceSpan.start.offset == expectedStart &&
        sourceSpan.stop.offset == expectedStop
  | _ => false

private def isLinearUnusedAtSpan (error : ErasureError) (expectedStart expectedStop : Nat) : Bool :=
  match error with
  | .linearUnused name sourceSpan =>
      name == "h" && sourceSpan.start.offset == expectedStart &&
        sourceSpan.stop.offset == expectedStop
  | _ => false

def runPipelineTests : IO Unit := do
  match elaborate "vocab core { : id ( a:Int^many -- a:Int^many ) ; }" with
  | .success program =>
      expectEq (program.words.map (·.name)) ["id"] "vocabulary words are flattened"
      expectEq program.words.length 1 "one checked word is returned"
      match program.words with
      | [word] =>
          expectEq word.program.length 0 "empty body lowers to an empty kernel program"
          expectEq word.refinement.leanRecords.length 1
            "the refinement stage discharges the empty specification"
          expectEq word.refinement.diagnostics.length 0
            "successful refinement leaves no diagnostics"
      | _ => fail "checked word is absent"
  | .failure diagnostics => fail s!"valid source failed: {repr diagnostics}"
  let stdlibSource ← IO.FS.readFile "stdlib/core.firth"
  match elaborateWith { sourcePath := "stdlib/core.firth" } stdlibSource with
  | .success { words := [identity, duplicate, discard, exchange, exampleWord] } =>
      expectEq (identity.program.map (·.atom)) []
        "core identity lowers to an empty kernel program"
      expectEq (duplicate.program.map (·.atom)) [.dup]
        "core duplicate-int lowers to dup"
      expectEq (discard.program.map (·.atom)) [.drop]
        "core discard-int lowers to drop"
      expectEq (exchange.program.map (·.atom)) [.swap]
        "core exchange-int lowers to swap"
      expectEq (exampleWord.program.map (·.atom))
        [.lit (.nat 7), .word "duplicate-int", .word "discard-int", .word "identity"]
        "core example uses the checked vocabulary words"
  | .success program => fail s!"unexpected core vocabulary words: {program.words.map (·.name)}"
  | .failure diagnostics => fail s!"core vocabulary failed: {repr diagnostics}"


  match elaborate
      ": id ( forall ρ; ρ -- ρ ) ; : caller ( h:Handle^linear -- h:Handle^linear ) id ;" with
  | .success program =>
      expectEq (program.words.map (·.name)) ["id", "caller"]
        "row-polymorphic words remain usable at concrete linear stacks"
  | .failure diagnostics => fail s!"row-polymorphic word failed: {repr diagnostics}"

  match elaborateWith externalWordConfig ": caller ( -- ) helper ;" with
  | .success program =>
      expectEq (program.words.map (·.name)) ["caller"]
        "configured external words remain available to dictionary checking"
  | .failure diagnostics => fail s!"external word failed: {repr diagnostics}"

  match elaborateWith mixedUsageConfig
      ": producer ( a:Int^linear -- a:Int^linear b:Int^many ) 1 ; : discard ( x:Int^many -- ) drop ; : consume ( x:Int^linear -- ) producer swap prim consumeLinear discard ;" with
  | .success program =>
      expectEq (program.words.map (·.name)) ["producer", "discard", "consume"]
        "referenced mixed-usage outputs retain bottom-to-top source order"
  | .failure diagnostics => fail s!"mixed-usage reference failed: {repr diagnostics}"

  match elaborate
      ": choose ( b:Bool^many -- x:Int^many ) [ 1 ] [ 2 ] if ;" with
  | .success { words := [word] } =>
      match word.program.map (·.atom) with
      | [Atom.quotation (Program.cons (Atom.lit (.nat 1)) Program.empty),
          Atom.quotation (Program.cons (Atom.lit (.nat 2)) Program.empty),
          Atom.ifThenElse] => pure ()
      | atoms => fail s!"quotation branch lowering changed: {repr atoms}"
  | result => fail s!"quotation branch inference failed: {repr result}"

  match elaborate
      ": bad-branch ( b:Bool^many -- x:Int^many ) [ 1 ] [ true ] if ;" with
  | .failure [.stackEffect diagnostic] =>
      expectEq diagnostic.code "firth.type.branch-mismatch"
        "quotation branch mismatches retain the structured stage diagnostic"
  | result => fail s!"quotation branch mismatch was not rejected: {repr result}"
  let duplicateLinear := ": duplicate ( h:Handle^linear -- ) locals { h } { h h } ;"
  match elaborate duplicateLinear with
  | .failure [.erasure "duplicate" error] =>
      expectTrue (isLinearCopyAtSpan error 52 53)
        "duplicate linear use identifies the exact local use and reports its source span"
  | result => fail s!"duplicate linear use was not rejected: {repr result}"

  let discardedLinear := ": discard ( h:Handle^linear -- ) locals { h } { } ;"
  match elaborate discardedLinear with
  | .failure [.erasure "discard" error] =>
      expectTrue (isLinearUnusedAtSpan error 42 43)
        "discarded linear value identifies the exact binding and reports its source span"
  | result => fail s!"discarded linear value was not rejected: {repr result}"

  match elaborateWith linearUsageConfig
      ": single-use ( h:Handle^linear -- ) locals { h } { h prim consumeLinear } ;" with
  | .success { words := [word] } =>
      expectEq (word.program.map (·.atom)) [.prim "consumeLinear"]
        "a linear value consumed exactly once elaborates successfully"
  | result => fail s!"single-use linear value failed: {repr result}"



  match elaborate ": bad ( -- ) missing ;" with
  | .failure [.erasure "bad" (.unresolvedEffect "missing" _)] => pure ()
  | result => fail s!"expected an erasure diagnostic, got {repr result}"

  match elaborate ": bad ( -- ) 1 ;" with
  | .failure [.stackEffect diagnostic] =>
      expectEq diagnostic.code "firth.type.declared-effect-mismatch"
        "stack-effect diagnostics retain the stage code"
  | result => fail s!"expected a stack-effect diagnostic, got {repr result}"

  match elaborate ":" with
  | .failure [.parse error] =>
      expectTrue (error.code.startsWith "firth.syntax") "parse diagnostic retains its syntax code"
  | result => fail s!"expected a parse diagnostic, got {repr result}"
  match elaborate ": one ( -- x:Int ) 1 ;" with
  | .success { words := [word] } =>
      expectEq (word.program.map (·.atom)) [.lit (.nat 1)]
        "literal source lowers to the expected kernel atom"
  | result => fail s!"checked kernel output failed: {repr result}"

  match elaborate ": recursive ( -- ) recursive ;" with
  | .success { words := [word] } =>
      expectEq word.name "recursive" "recursive dictionary word is checked"
      expectEq (word.program.map (·.atom)) [.word "recursive"]
        "recursive reference lowers to the dictionary word atom"
  | result => fail s!"recursive dictionary failed: {repr result}"
  match elaborate ": recursive ( -- ) recursive 1 ;" with
  | .failure [.stackEffect diagnostic] =>
      expectEq diagnostic.code "firth.type.declared-effect-mismatch"
        "invalid recursive body retains its stack-effect diagnostic"
  | result => fail s!"invalid recursive dictionary accepted: {repr result}"

  match elaborateWith (refinementConfig .falsity) ": guarded ( -- ) ;" with
  | .failure [.refinement "guarded" diagnostic] =>
      expectEq diagnostic.requestId "pipeline-test" "refinement request id is retained"
      expectEq diagnostic.body.code "firth.refinement.not-decided"
        "refinement escalation retains its diagnostic code"
      expectEq diagnostic.body.location.path "configured-pipeline.firth"
        "refinement diagnostic source path is retained"
      expectEq diagnostic.body.location.range.start.offset 0
        "refinement diagnostic starts at the word span"
      expectEq diagnostic.body.location.range.stop.offset 18
        "refinement diagnostic preserves the complete word span"
  | result => fail s!"refinement diagnostic failed: {repr result}"

  match elaborateWith totalityEscalationConfig ": total ( -- ) ;" with
  | .failure [.refinement "total" diagnostic] =>
      match diagnostic.body.obligations with
      | [obligation] =>
          expectEq obligation.kind .bodyTotality
            "totality refinement escalation retains obligation kind"
          expectEq obligation.status .deferred
            "totality escalation remains deferred for Lean"
          expectEq diagnostic.body.code "firth.refinement.not-decided"
            "totality escalation retains its diagnostic code"
          expectEq diagnostic.body.location.path "configured-pipeline.firth"
            "totality escalation retains source path"
          expectEq diagnostic.body.location.range.start.offset 0
            "totality escalation starts at the word span"
          expectEq diagnostic.body.location.range.stop.offset 16
            "totality escalation preserves the complete word span"
      | obligations => fail s!"unexpected totality obligations: {repr obligations}"
  | result => fail s!"totality escalation failed: {repr result}"

  let deterministicSource := ": stable ( -- x:Int ) 1 ;"
  expectEq (elaborate deterministicSource) (elaborate deterministicSource)
    "repeated elaboration is deterministic"
  expectEq (elaborateWith externalWordConfig deterministicSource)
    (elaborateWith externalWordConfig deterministicSource)
    "repeated configured elaboration"

  let deterministicFailure := ": unstable ( -- x:Int ) true ;"
  let firstFailure := elaborate deterministicFailure
  let secondFailure := elaborate deterministicFailure
  match firstFailure, secondFailure with
  | .failure [.stackEffect firstDiagnostic], .failure [.stackEffect secondDiagnostic] =>
      expectEq firstDiagnostic.code "firth.type.declared-effect-mismatch"
        "deterministic failure fixture retains the expected diagnostic"
      expectEq firstDiagnostic secondDiagnostic
        "repeated elaboration produces identical structured diagnostics"
  | first, second =>
      fail s!"deterministic failure fixture changed shape: {repr first}, {repr second}"

  IO.println "pipeline tests passed"

def main : IO Unit := runPipelineTests
