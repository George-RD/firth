import elaborator.Firth.Parser
import elaborator.Firth.Names
import elaborator.Firth.Erasure
import elaborator.Firth.StackEffect
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

private def signatureOfEffect (effect : StackEffect) : Signature :=
  -- Surface effects are bottom-to-top; erasure states and signatures are top-first.
  { input := signatureUsages effect.input.reverse
    output := signatureUsages effect.output.reverse }

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

def elaborateWith (config : PipelineConfig) (source : String) : ElaborationResult :=
  match parse source with
  | .failure errors => .failure (errors.map PipelineDiagnostic.parse)
  | .success file =>
      match resolveNames file.declarations with
      | .error error => .failure [.parse error]
      | .ok words =>
          let env := makeErasureEnv config words
          match eraseWords env words with
          | .error (word, error) => .failure [.erasure word error]
          | .ok erased =>
              match checkDictionary config.typingEnv (definitionsOf erased) with
              | .error diagnostic => .failure [.stackEffect diagnostic]
              | .ok checked => finishWords config erased checked

def elaborate (source : String) : ElaborationResult := elaborateWith {} source

end Firth.Elaborator
