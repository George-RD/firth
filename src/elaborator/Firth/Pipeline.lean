import elaborator.Firth.Parser
import elaborator.Firth.Names
import elaborator.Firth.Erasure
import elaborator.Firth.StackEffect
import elaborator.Firth.Account
import elaborator.Firth.Refinement

namespace Firth.Elaborator

open Firth.Elaborator.StackEffect

abbrev RefinementBuilder :=
  String → String → WordDefinition → KernelProgram → Scheme →
    Refinement.BodyTypingPremises

private def emptyRefinementBuilder (_requestId sourcePath : String)
    (word : WordDefinition) (_program : KernelProgram) (scheme : Scheme) :
    Refinement.BodyTypingPremises :=
  let stack : Refinement.RefinedStack :=
    { erased := scheme.input, refinements := {} }
  let context : Refinement.ObligationContext :=
    { wordId := word.name
      bodyHash := "pipeline-source-body"
      erasedWordTypeHash := "pipeline-erased-word-type"
      specHash := "pipeline-empty-spec"
      normaliserVersion := "pipeline-v1"
      vcGeneratorVersion := "pipeline-v1"
      leanToolchainHash := "pipeline-default"
      proofModuleHash := "pipeline-default"
      toolchainRevision := "pipeline-default"
      source := { path := sourcePath, span := word.span }
      expectedStack := stack
      actualStack := { stack with erased := scheme.output } }
  { context
    precondition := {}
    bodySemantics := {}
    declaredPostcondition := {}
    totality := none }

structure PipelineConfig where
  erasureEnv : EffectEnv := {}
  typingEnv : Env := { literal := defaultLiteralType }
  requestId : String := "firth.elaborator"
  sourcePath : String := "<source>"
  refinementBuilder : RefinementBuilder := emptyRefinementBuilder

structure CheckedWord where
  name : String
  scheme : Scheme
  program : KernelProgram
  warnings : List LintWarning := []
  refinement : Refinement.PipelineResult
  deriving Repr, BEq

structure CheckedProgram where
  words : List CheckedWord
  deriving Repr, BEq

inductive PipelineDiagnostic where
  | parse (error : ParseError)
  | erasure (word : String) (error : ErasureError)
  | stackEffect (diagnostic : StackEffect.Diagnostic)
  | refinement (word : String) (diagnostic : Refinement.RefinementDiagnostic)
  | internal (span : Span)
  deriving Repr, BEq

inductive ElaborationResult where
  | success (program : CheckedProgram)
  | failure (diagnostics : List PipelineDiagnostic)
  deriving Repr, BEq

private def signatureUsages : List StackItem → List Usage
  | [] => []
  | .row _ _ :: rest => signatureUsages rest
  | .value _ type _ :: rest => type.usage :: signatureUsages rest

private def signatureRows : List StackItem → List String
  | [] => []
  | .row name _ :: rest => name :: signatureRows rest
  | .value .. :: rest => signatureRows rest

private def signatureOfEffect (effect : StackEffect) : Signature :=
  -- Surface effects are bottom-to-top; erasure states and signatures are top-first.
  { input := signatureUsages effect.input.reverse
    output := signatureUsages effect.output.reverse
    rowPreserving := signatureRows effect.input == signatureRows effect.output }

private def lookupSignature (name : String) : List (String × Signature) → Option Signature
  | [] => none
  | (candidate, signature) :: rest =>
      if candidate == name then some signature else lookupSignature name rest

private def makeErasureEnv (config : PipelineConfig)
    (words : List WordDefinition) : EffectEnv :=
  let localSignatures :=
    words.map (fun word => (word.name, signatureOfEffect word.effect))
  { config.erasureEnv with
    word := fun name =>
      match lookupSignature name localSignatures with
      | some signature => some signature
      | none => config.erasureEnv.word name }

private def eraseWords (env : EffectEnv) :
    List WordDefinition → Except (String × ErasureError) (List (WordDefinition × ErasureResult))
  | [] => .ok []
  | word :: rest =>
      match erase env word.effect word.body with
      | .error error => .error (word.name, error)
      | .ok result =>
          match eraseWords env rest with
          | .error error => .error error
          | .ok tail => .ok ((word, result) :: tail)

private def definitionsOf :
    List (WordDefinition × ErasureResult) → List StackEffect.Definition
  | [] => []
  | (word, erased) :: rest =>
      { name := word.name
        declared := word.effect
        program := erased.program
        span := word.span } :: definitionsOf rest

private def refinementDiagnostics (word : String) :
    Refinement.PipelineResult → List PipelineDiagnostic
  | result => result.diagnostics.map (PipelineDiagnostic.refinement word)

private def finishWords (config : PipelineConfig)
    (erased : List (WordDefinition × ErasureResult))
    (checked : List CheckedDefinition) : ElaborationResult :=
  match erased, checked with
  | [], [] => .success { words := [] }
  | (word, result) :: erasedRest, checkedWord :: checkedRest =>
      let premises := config.refinementBuilder config.requestId config.sourcePath
        word result.program checkedWord.effect
      let refinement := Refinement.checkBodyRefinements config.requestId premises
      let issues := refinementDiagnostics word.name refinement
      if !issues.isEmpty then
        .failure issues
      else if !refinement.leanQueue.isEmpty || !refinement.smtQueue.isEmpty then
        .failure [.internal word.span]
      else
        match finishWords config erasedRest checkedRest with
        | .failure diagnostics => .failure diagnostics
        | .success tail =>
            .success { words :=
              { name := word.name
                scheme := checkedWord.effect
                program := result.program
                warnings := result.warnings
                refinement } :: tail.words }
  | (word, _) :: _, _ => .failure [.internal word.span]
  | _, _ :: _ => .failure [.internal { start := { offset := 0, line := 1, column := 1 }, stop := { offset := 0, line := 1, column := 1 } }]

/-- Source annotations are not yet translated into body-typing premises.
Reject them before erasure can discard the predicates. An injected builder is
an internal test seam, not evidence that the source annotation was checked. -/
private def unsupportedSourceRefinements (word : WordDefinition) : List PipelineDiagnostic :=
  (word.effect.input ++ word.effect.output).flatMap fun item =>
    match item with
    | .row .. => []
    | .value _ type _ =>
        type.refinements.map fun refinement =>
          .parse { code := "firth.refinement.unsupported-source"
                   primary := refinement.span, actual := some word.name, cause := .validation }

/-- A refused `if` recounted from the source, value by value, so its
diagnostic can name the operation and the values responsible. Diagnostics
only: it never changes what is accepted. -/
private def accountFor (config : PipelineConfig) (source : String)
    (words : List WordDefinition) (span : Span) : Option IfAccount :=
  Account.ofIf {
    words
    primitive := fun name => (config.typingEnv.primitive name).bind Account.primitiveShape
    external := fun name => (config.erasureEnv.word name).bind fun signature =>
      if !signature.rowPreserving then none else some
      (signature.input.length, signature.output.length)
    source
    target := span.start.offset } span

private def withAccount (config : PipelineConfig) (source : String)
    (words : List WordDefinition) : PipelineDiagnostic → PipelineDiagnostic
  | .erasure word (.branchShape span onTrue onFalse locals _) =>
      .erasure word (.branchShape span onTrue onFalse locals (accountFor config source words span))
  | .stackEffect diagnostic =>
      if diagnostic.code == "firth.type.branch-mismatch" then
        .stackEffect { diagnostic with ifAccount := accountFor config source words diagnostic.primary }
      else .stackEffect diagnostic
  | other => other

private def erasureSpan : ErasureError → Span
  | .duplicateLocal _ span | .unboundLocal _ span | .unsupportedCapture _ span
  | .missingStackValue span | .linearCopy _ span | .linearUnused _ span
  | .unresolvedEffect _ span | .effectUnderflow _ span | .usageMismatch _ span
  | .unsupportedLiteral span | .unsupportedAtom _ span | .untrackedStack _ span _
  | .branchShape span .. | .hiddenLocal _ span => span

/-- What erasure and the type checker make of `word` among `words`: `none`
when it is accepted, else where in the source its first error is. The other words are
given by their declared effects only, so an error of theirs is never charged
to `word`. -/
private def outcomeAlone (config : PipelineConfig) (words : List WordDefinition)
    (word : WordDefinition) : Option Nat :=
  let others := words.filter (·.name != word.name)
  match erase (makeErasureEnv config (word :: others)) word.effect word.body with
  | .error error => some (erasureSpan error).start.offset
  | .ok erased =>
      let definitions : List StackEffect.Definition :=
        { name := word.name, declared := word.effect, program := erased.program, span := word.span } ::
          others.map fun other => { name := other.name, declared := other.effect, program := [], span := other.span }
      match checkDictionary config.typingEnv definitions with
      | .ok _ => none
      -- The word is checked first, so an error charged to another word
      -- means it passed.
      | .error diagnostic =>
          if diagnostic.word.isSome && diagnostic.word != some word.name then none
          else some diagnostic.primary.start.offset

/-- A misordered `locals` refusal whose suggested edits have been applied and
checked. A block is marked `checked` when its word, edited as the diagnostic
would say, is accepted, or is refused no earlier in the source than the word
as written: most answers carry more than one mistake, and the edit then got
past the first. An edit that turns an accepted word into a refused one, or
brings a refusal earlier, is not stated. -/
private def checkLocalsEdits (config : PipelineConfig) (words : List WordDefinition)
    (error : ParseError) : ParseError :=
  { error with localsBlocks := error.localsBlocks.map fun block =>
      match words.find? (·.name == block.word) with
      | some word =>
          let checked := match outcomeAlone config words (applyLocalsBlock word block),
              outcomeAlone config words word with
            | none, _ => true
            | some edited, some written => edited ≥ written
            | some _, none => false
          { block with checked := checked && !block.rebound }
      | none => block }

def elaborateWith (config : PipelineConfig) (source : String) : ElaborationResult :=
  match parse source with
  | .failure errors => .failure (errors.map PipelineDiagnostic.parse)
  | .success file =>
      match resolveNames file.declarations (fun name => (config.erasureEnv.word name).isSome) with
      | .error error => .failure [.parse error]
      | .ok words =>
          match checkInputLocals words (collectWords file.declarations) with
          | .error error => .failure [.parse (checkLocalsEdits config words error)]
          | .ok () =>
          if words.isEmpty then
            .failure [.parse { code := "firth.elaboration.empty-program"
                               primary := file.span, cause := .validation }]
          else
            let unsupported := words.flatMap unsupportedSourceRefinements
            if !unsupported.isEmpty then .failure unsupported
            else
              let env := makeErasureEnv config words
              match eraseWords env words with
              | .error (word, error) => .failure [withAccount config source words (.erasure word error)]
              | .ok erased =>
                  match checkDictionary config.typingEnv (definitionsOf erased) with
                  | .error diagnostic => .failure [withAccount config source words (.stackEffect diagnostic)]
                  | .ok checked => finishWords config erased checked

def elaborate (source : String) : ElaborationResult := elaborateWith {} source

end Firth.Elaborator
