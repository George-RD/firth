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
  /-- `word` was not type-checked: at `span` it calls `callee`, whose
  declared effect is not a type scheme, so there is nothing to check the
  call against. -/
  | unchecked (word callee : String) (span : Span)
  | internal (span : Span)
  /-- `inner`, a report in `word` that depends on the declared effects of
  `callees`, words it calls that have errors of their own. -/
  | assumes (word : String) (callees : List String) (inner : PipelineDiagnostic)
  deriving Repr, BEq

structure PipelineConfig where
  erasureEnv : EffectEnv := {}
  typingEnv : Env := { literal := defaultLiteralType }
  requestId : String := "firth.elaborator"
  sourcePath : String := "<source>"
  refinementBuilder : RefinementBuilder := emptyRefinementBuilder
  /-- Whether two reports read the same. A caller that renders reports
  compares what it renders, so that a difference no reader sees does not
  count. -/
  sameReport : PipelineDiagnostic → PipelineDiagnostic → Bool := (· == ·)

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

private def refinementDiagnostics (word : String) :
    Refinement.PipelineResult → List PipelineDiagnostic
  | result => result.diagnostics.map (PipelineDiagnostic.refinement word)

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

/-- Where in the source a report is. -/
private def PipelineDiagnostic.span? : PipelineDiagnostic → Option Span
  | .parse error => some error.primary
  | .erasure _ error => some (erasureSpan error)
  | .stackEffect diagnostic => some diagnostic.primary
  | .refinement _ diagnostic => some diagnostic.body.location.range
  | .unchecked _ _ span | .internal span => some span
  | .assumes _ _ inner => inner.span?

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
        -- Other words keep whatever errors they have: only this one must
        -- resolve. They keep the effects they are checked against, `words`.
        let (resolved, _) ← (resolveEach file.declarations (fun name => (config.erasureEnv.word name).isSome)).toOption
        let word ← (resolved.find? fun (word, error) => word.name == name && error.isNone).map (·.1)
        let operation := ((diagnostic.primary.start.offset : Int) + shift).toNat
        let after ← match outcomeAlone config edited (word :: words.filter (·.name != name)) word with
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

/-- The dictionary words a body calls, where, outside the `locals` that
shadow them. -/
private partial def calledWords (bound : List String) : List Item → List (String × Span)
  | [] => []
  | .word name span :: rest =>
      (if bound.contains name then [] else [(name, span)]) ++ calledWords bound rest
  | .quotation items _ :: rest => calledWords bound items ++ calledWords bound rest
  | .locals names items _ :: rest =>
      calledWords (names.map (·.name) ++ bound) items ++ calledWords bound rest
  | _ :: rest => calledWords bound rest

/-- What checking one word came to. -/
private inductive WordOutcome where
  | checked (word : CheckedWord)
  /-- The word's first error, or for refinements the obligations it failed. -/
  | refused (diagnostics : List PipelineDiagnostic)
  /-- Not type-checked: it calls a word whose declared effect is not a type
  scheme, so there is nothing to check its call against. -/
  | skipped (callee : String) (span : Span)

/-- One word, stage by stage, as the whole-program pipeline would check it:
names, the `locals` order, source refinements, erasure, the declared effect,
typing and refinements. A word that calls a word whose effect is refused is
skipped before erasure, unless its own effect is refused too. The other words are trusted to have their declared
effects, whatever their bodies do, so an error in one word is never charged
to another. `words` are all the file's words, resolved where they could be. -/
private def checkWord (config : PipelineConfig) (source : String)
    (words written : List WordDefinition) (env : EffectEnv) (typing : Env)
    (unusable : List String) (word : WordDefinition) (resolution : Option ParseError) :
    WordOutcome :=
  match resolution with
  | some error => .refused [.parse error]
  | none =>
  match checkInputLocals [word] (written.filter (·.name == word.name)) with
  | .error error => .refused [.parse (checkLocalsEdits config source words error)]
  | .ok () =>
  match unsupportedSourceRefinements word with
  | diagnostic :: _ => .refused [diagnostic]
  | [] =>
  -- Before erasure: erasing a call to a word whose effect is refused reads
  -- that effect's shape all the same, and an underflow it finds there says
  -- nothing about this word. The word's own effect is its own error.
  match (calledWords [] word.body).find? (unusable.contains ·.1), schemeOfEffect word.effect with
  | some _, .error diagnostic => .refused [.stackEffect diagnostic]
  | some (callee, span), .ok _ => .skipped callee span
  | none, _ =>
  match erase env word.effect word.body with
  | .error error => .refused [withAccount config source words (.erasure word.name error)]
  | .ok erased =>
  match schemeOfEffect word.effect with
  | .error diagnostic => .refused [.stackEffect diagnostic]
  | .ok declared =>
  match check typing declared erased.program word.effect.span with
  | .error diagnostic =>
      let diagnostic := withFirstMisfed config source words { diagnostic with word := some word.name }
      .refused [withCallAccount config source words (withAccount config source words (.stackEffect diagnostic))]
  | .ok _ =>
      let premises := config.refinementBuilder config.requestId config.sourcePath
        word erased.program declared
      let refinement := Refinement.checkBodyRefinements config.requestId premises
      let issues := refinementDiagnostics word.name refinement
      if !issues.isEmpty then .refused issues
      else if !refinement.leanQueue.isEmpty || !refinement.smtQueue.isEmpty then
        .refused [.internal word.span]
      else .checked
        { name := word.name
          scheme := declared
          program := erased.program
          warnings := erased.warnings
          refinement }

/-- The environments the words are checked in: each word's declared effect,
for erasure and for typing, and the words whose effect is no type scheme. -/
private def environments (config : PipelineConfig) (declared : List WordDefinition) :
    EffectEnv × Env × List String :=
  let schemes := declared.map fun word => (word.name, (schemeOfEffect word.effect).toOption)
  let typing : Env := { config.typingEnv with
    word := fun name =>
      match schemes.find? (·.1 == name) with
      | some entry => entry.2
      | none => config.typingEnv.word name }
  (makeErasureEnv config declared, typing, (schemes.filter (·.2.isNone)).map (·.1))

/-- Stack effects unlike each other and unlike most declared ones: none,
one that takes an Int, one that leaves a Bool, and one that takes three Ints
and leaves a Seq Int. A report that stays the same whichever of them a callee
has does not depend on the callee's effect. -/
private def probeEffects : List StackEffect :=
  match parse (String.intercalate "\n" [
      ": p ( forall ρ; ρ -- ρ ) ;",
      ": p ( forall ρ; ρ x:Int -- ρ ) ;",
      ": p ( forall ρ; ρ -- ρ y:Bool ) ;",
      ": p ( forall ρ; ρ a:Int b:Int c:Int -- ρ r:Seq Int ) ;"]) with
  | .success file => (collectWords file.declarations).map (·.effect)
  | .failure _ => []

/-- Elaborate a file. A parse error, a duplicate name or a bad `use` refuses
the file there. Otherwise every word is checked on its own (`checkWord`), and
the file is refused with each refused word's first error, in source order:
one error per word, so a mistake is reported where it is made and not again
at every later operation it upsets. A word that calls one whose declared
effect is no type scheme is not type-checked, and is reported as unchecked. -/
def elaborateWith (config : PipelineConfig) (source : String) : ElaborationResult :=
  match parse source with
  | .failure errors => .failure (errors.map PipelineDiagnostic.parse)
  | .success file =>
      match resolveEach file.declarations (fun name => (config.erasureEnv.word name).isSome) with
      | .error error => .failure [.parse error]
      | .ok (resolved, stop) =>
          let words := resolved.map (·.1)
          let written := collectWords file.declarations
          -- Every word's declared effect, those after a bad `use` included:
          -- a word before it may call one declared after it, and only the
          -- words before it are checked. The accounts of a report walk the
          -- called words too.
          let declared := words ++ written.filter fun word => !words.any (·.name == word.name)
          let (env, typing, unusable) := environments config declared
          let outcomes := resolved.map fun (word, resolution) =>
            checkWord config source declared written env typing unusable word resolution
          let refused := (resolved.zip outcomes).filterMap fun ((word, _), outcome) =>
            match outcome with
            | .refused _ => some word.name
            | _ => none
          -- A report that depends on the effect of a called word with an
          -- error of its own: checked again with that callee given one of
          -- the probe effects, the word is accepted, or it is refused with
          -- other reports, one of them no later in the source than this one.
          -- A report only after it says nothing about this one: erasure
          -- walks the whole body before typing, so an arity error there
          -- hides a type error before it.
          let dependsOn (word : WordDefinition) (resolution : Option ParseError)
              (callee : String) : PipelineDiagnostic → Bool :=
            let probed := probeEffects.map fun effect =>
              let declared := declared.map fun other =>
                if other.name == callee then { other with effect } else other
              let (env, typing, unusable) := environments config declared
              checkWord config source declared written env typing unusable word resolution
            fun diagnostic => probed.any fun
              | .refused diagnostics =>
                  !diagnostics.any (config.sameReport · diagnostic) && diagnostics.any fun other =>
                    match other.span?, diagnostic.span? with
                    | some found, some report =>
                        found.start.offset ≤ report.start.offset || found.start.offset < report.stop.offset
                    | _, _ => true
              | _ => true
          -- A word left unchecked says so, so that no one reads its
          -- silence as a pass. A report that depends on the effect of a word
          -- with an error of its own says so too: fixing that word's effect
          -- can change it.
          let errors : List PipelineDiagnostic := (resolved.zip outcomes).flatMap
            fun ((word, resolution), outcome) => match outcome with
              | .refused diagnostics =>
                  let probes := (((calledWords [] word.body).map (·.1)).eraseDups.filter
                    fun callee => callee != word.name && refused.contains callee).map
                    fun callee => (callee, dependsOn word resolution callee)
                  diagnostics.map fun diagnostic =>
                    match probes.filterMap fun (callee, depends) =>
                        if depends diagnostic then some callee else none with
                    | [] => diagnostic
                    | callees => .assumes word.name callees diagnostic
              | .skipped callee span => [.unchecked word.name callee span]
              | .checked _ => []
          let tail := (stop.map PipelineDiagnostic.parse).toList
          if !(errors ++ tail).isEmpty then .failure (errors ++ tail)
          else if words.isEmpty then
            .failure [.parse { code := "firth.elaboration.empty-program"
                               primary := file.span, cause := .validation }]
          else
            .success { words := outcomes.filterMap fun
              | .checked word => some word
              | _ => none }

def elaborate (source : String) : ElaborationResult := elaborateWith {} source

end Firth.Elaborator
