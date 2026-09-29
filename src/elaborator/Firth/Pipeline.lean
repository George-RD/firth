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

/-- A plain type as the walk writes it (`Int`, `World^linear`) as the
checker's type, when it is one. -/
private def plainType (type : String) : Option AType :=
  if !type.front.isUpper || type.contains '[' then none
  else if type.endsWith "^linear" then some (.base (type.dropEnd 7).toString .linear)
  else some (.base type .many)

/-- A checker error in a word whose body, followed as written, hands an
earlier word or primitive a value it does not take (`Account.firstMisfed`),
or one inside the reported span: reported at that operation instead. The checker infers a quotation's input
from what its body does, so there such a mistake can surface later, at an
operation the author did not get wrong, with inferred types such as `?t27`.
Only when the walk knows the type of every value the operation gets. It never
changes what is accepted: the checker refused the word either way. -/
private def withFirstMisfed (config : PipelineConfig) (source : String)
    (words : List WordDefinition) (diagnostic : StackEffect.Diagnostic) : StackEffect.Diagnostic :=
  let found : Option StackEffect.Diagnostic := do
    -- A refused `if` has its own account (`Account.ofIf`), which names an
    -- operation in a branch handed the wrong values, and says which of them
    -- come from below the `if`.
    if diagnostic.code == "firth.type.branch-mismatch" then none else
    let name ← diagnostic.word
    let word ← words.find? fun (word : WordDefinition) => word.name == name
    let account ← Account.firstMisfed {
      words
      primitive := fun name => (config.typingEnv.primitive name).bind Account.primitiveShape
      external := fun name => (config.erasureEnv.word name).bind fun signature =>
        if !signature.rowPreserving then none else some
        (signature.input.length, signature.output.length)
      source
      target := 0 } word
    -- Earlier in the source than the reported operation, or inside it, as
    -- in the quotation whose `compose` erasure reports.
    if account.span.start.offset == diagnostic.primary.start.offset ||
        account.span.start.offset ≥ diagnostic.primary.stop.offset then none else
    let primitive := account.operation.startsWith "`prim "
    -- A word's inputs are written `name:Type`, a primitive's as types.
    let takes := if primitive then account.inputs
      else account.inputs.map fun (input : String) => ":".intercalate ((input.splitOn ":").drop 1)
    let wanted ← takes.mapM plainType
    let got ← account.types.mapM fun (type : Option String) => type.bind plainType
    let stack (types : List AType) : AStack := types.foldl AStack.snoc (.row (.mvar 0))
    pure { diagnostic with
      code := if primitive then "firth.type.primitive-input-mismatch" else "firth.type.word-input-mismatch"
      primary := account.span
      state := stack got
      expected := some (stack wanted)
      actual := some (stack got)
      subject := some ((account.operation.drop 1).dropEnd 1).toString
      branchOutputs := none
      branchInput := none
      ifAccount := none }
  found.getD diagnostic

/-- What erasure and the type checker make of `word` among `words`: `none`
when it is accepted, else where in the source its first error is. The other words are
given by their declared effects only, so an error of theirs is never charged
to `word`. -/
private def outcomeAlone (config : PipelineConfig) (source : String) (words : List WordDefinition)
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
          -- Where the error is reported, as the author would see it.
          else some (withFirstMisfed config source (word :: others) diagnostic).primary.start.offset

/-- The text of `source` from byte `start` to byte `stop`. -/
private def bytesText (source : String) (start stop : Nat) : String :=
  (String.fromUTF8? (source.toUTF8.extract start stop)).getD ""

/-- The line and column of byte `offset` in `source`, counting from 1. -/
private def lineColumn (source : String) (offset : Nat) : Nat × Nat :=
  (bytesText source 0 offset).foldl (fun (line, column) c =>
    if c == '\n' then (line + 1, 1) else (line, column + 1)) (1, 1)

/-- Where the values `got` (bottom to top) go so that their types are
`wanted`: for each input, a value of its type, first one the source names
by the input's own name (the local `xs` or the input `xs` for an input
`xs`), then among the others the first not yet placed. Also, for each input,
the texts that could fill it: one where that is certain, several where
values of its type pushed by different source are left to fill inputs of
that type and nothing tells which is which. `none` when the types are not
all plain types or do not fit. -/
private def reordering (wanted got : List AType) (names labels texts : List String) :
    Option (List Nat × List (List String)) :=
  let plain : AType → Option String
    | .base name usage => some (renderType (.base name usage))
    | _ => none
  do
    let wanted ← wanted.mapM plain
    let got ← got.mapM plain
    if wanted.length != got.length || texts.length != got.length then none else
    let indices := List.range got.length
    let named (input : Nat) (value : Nat) : Bool :=
      match names[input]? with
      | some name => labels[value]? == some s!"`{name}`" || labels[value]? == some s!"the input `{name}`"
      | none => false
    -- Inputs whose value the source names, first come first.
    let byName : List (Option Nat) := (List.range wanted.length).foldl (init := []) fun placed input =>
      let taken := placed.filterMap id
      placed ++ [indices.find? fun value =>
        !taken.contains value && got[value]? == wanted[input]? && named input value]
    let reserved := byName.filterMap id
    let order ← (List.range wanted.length).foldlM (init := ([] : List Nat)) fun order input => do
      match byName[input]? with
      | some (some value) => pure (order ++ [value])
      | _ =>
          let value ← indices.find? fun value =>
            !order.contains value && !reserved.contains value && got[value]? == wanted[input]?
          pure (order ++ [value])
    let choices := (List.range wanted.length).map fun input =>
      match byName[input]? with
      | some (some value) => texts[value]?.toList
      | _ =>
          let open_ := indices.filter fun value =>
            !reserved.contains value && got[value]? == wanted[input]?
          let distinct := (open_.filterMap (texts[·]?)).eraseDups
          if distinct.length ≤ 1 then ((order[input]?).bind (texts[·]?)).toList else distinct
    pure (order, choices)

/-- A word or primitive the checker refused because the values it was handed
are not the ones it takes, recounted from the source: the values it gets by
their sources and, when they were pushed one after another just before it
but in an order its input types do not allow, an edit that pushes them in
the order those types give. The edit is applied to the source and the word
checked again: it is kept only when the word then checks, or is refused only
later in the source than the operation, and the diagnostic says which. It
never changes what is accepted. -/
private def withCallAccount (config : PipelineConfig) (source : String)
    (words : List WordDefinition) : PipelineDiagnostic → PipelineDiagnostic
  | .stackEffect diagnostic =>
      if diagnostic.code != "firth.type.word-input-mismatch" &&
          diagnostic.code != "firth.type.primitive-input-mismatch" then .stackEffect diagnostic else
      let account := Account.ofCall {
        words
        primitive := fun name => (config.typingEnv.primitive name).bind Account.primitiveShape
        external := fun name => (config.erasureEnv.word name).bind fun signature =>
          if !signature.rowPreserving then none else some
          (signature.input.length, signature.output.length)
        source
        target := diagnostic.primary.start.offset } diagnostic.primary
      let collapse (text : String) :=
        " ".intercalate (((text.map fun c => if c.isWhitespace then ' ' else c).splitOn " ").filter (!·.isEmpty))
      let plan : Option (List Nat × List (List String)) := do
        let account ← account
        let ranges ← account.pieces
        let wanted := (stackValues (← diagnostic.expected)).1
        let present := (stackValues (← diagnostic.actual)).1
        if present.length < wanted.length then none else
        -- Inside a quotation the checker may not know a value's type yet
        -- (`?t27`) where the walk does, from the local or input it is.
        let got := (present.drop (present.length - wanted.length)).zip account.types |>.map fun
          | (.base name usage, _) => AType.base name usage
          | (other, walked) => ((walked.bind plainType).getD other)
        let names := account.inputs.map fun input => ((input.splitOn ":").head?).getD ""
        reordering wanted got names account.values (ranges.map fun (a, b) => collapse (bytesText source a b))
      let edit : Option CallEdit := do
        let account ← account
        let ranges ← account.pieces
        let (order, choices) ← plan
        if order == List.range order.length || choices.any (·.length > 1) then none else
        -- The edit replaces everything from the first piece as written up to
        -- the operation, `swap`s included, with the pieces in order.
        let start ← (ranges.map (·.1)).min?
        let stop := diagnostic.primary.start.offset
        let texts ← order.mapM fun i => ranges[i]?.map fun (a, b) => bytesText source a b
        let replacement := " ".intercalate (texts.map collapse)
        let edited := bytesText source 0 start ++ replacement ++ " " ++ bytesText source stop source.utf8ByteSize
        let shift : Int := (replacement.utf8ByteSize + 1 : Int) - ((stop - start : Nat) : Int)
        let name ← diagnostic.word
        let file ← match parse edited with
          | .success file => some file
          | .failure _ => none
        let editedWords ← (resolveNames file.declarations (fun name => (config.erasureEnv.word name).isSome)).toOption
        let word ← editedWords.find? (·.name == name)
        let operation := ((diagnostic.primary.start.offset : Int) + shift).toNat
        let after ← match outcomeAlone config edited editedWords word with
          | none => some none
          | some offset =>
              if offset ≤ operation then none
              -- In the source as edited: the author applies the edit, and
              -- a replaced text that spans lines leaves fewer of them.
              else some (some (lineColumn edited offset))
        pure { start, stop, written := collapse (bytesText source start stop),
               replacement, after }
      -- Where the types and names leave the order open, the message says
      -- what is certain instead of choosing.
      let assignment := match edit, plan with
        | none, some (order, choices) =>
            if choices.any (·.length > 1) && order != List.range order.length then
              ((account.map (·.inputs)).getD []).zip choices
            else []
        | _, _ => []
      .stackEffect { diagnostic with callAccount := account.map ({ · with edit, assignment }) }
  | other => other

/-- A misordered `locals` refusal whose suggested edits have been applied and
checked. A block is marked `checked` when its word, edited as the diagnostic
would say, is accepted, or is refused no earlier in the source than the word
as written: most answers carry more than one mistake, and the edit then got
past the first. An edit that turns an accepted word into a refused one, or
brings a refusal earlier, is not stated. -/
private def checkLocalsEdits (config : PipelineConfig) (source : String) (words : List WordDefinition)
    (error : ParseError) : ParseError :=
  { error with localsBlocks := error.localsBlocks.map fun block =>
      match words.find? (·.name == block.word) with
      | some word =>
          let checked := match outcomeAlone config source words (applyLocalsBlock word block),
              outcomeAlone config source words word with
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
          | .error error => .failure [.parse (checkLocalsEdits config source words error)]
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
                  | .error diagnostic =>
                      let diagnostic := withFirstMisfed config source words diagnostic
                      .failure [withCallAccount config source words (withAccount config source words (.stackEffect diagnostic))]
                  | .ok checked => finishWords config erased checked

def elaborate (source : String) : ElaborationResult := elaborateWith {} source

end Firth.Elaborator
