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
  `callees`, words it calls that have errors of their own. The edit its hint
  offers was checked against the effects of `edits` too, other such words
  the report itself does not depend on. -/
  | assumes (word : String) (callees edits : List String) (inner : PipelineDiagnostic)
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
  /-- Whether a hint's edit is applied and checked before it is offered
  (`withCallAccount`, `checkLocalsEdits`). -/
  checkEdits : Bool := true

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
  | .assumes _ _ _ inner => inner.span?

/-- The stage that made a report, in the order the stages run: names and
`locals` order, erasure, typing, refinements. -/
private def PipelineDiagnostic.stage : PipelineDiagnostic → Nat
  | .parse _ | .unchecked .. => 0
  | .erasure .. => 1
  | .stackEffect _ => 2
  | .refinement .. | .internal _ => 3
  | .assumes _ _ _ inner => inner.stage

/-- The end of the `locals` block that binds the name at `span`, if one in
`items` does. -/
private def bindingBlockEnd (span : Span) : List Item → Option Nat
  | [] => none
  | .locals names body block :: rest =>
      if names.any (·.span == span) then some block.stop.offset
      else (bindingBlockEnd span body).orElse fun _ => bindingBlockEnd span rest
  | .quotation body _ :: rest => (bindingBlockEnd span body).orElse fun _ => bindingBlockEnd span rest
  | _ :: rest => bindingBlockEnd span rest

/-- How far checking got in its stage when it made a report, as a source
offset: a stage checks a word's body in order, and a construct once it has
checked what is inside it, so most reports are made where they end. Two are
placed before the point they are made at. The comparison with the declared
effect is at the signature but comes after the body, and a `locals` name left
on the stack is found where its block ends. -/
private def PipelineDiagnostic.reached (word : WordDefinition) : PipelineDiagnostic → Nat
  | .stackEffect diagnostic =>
      if diagnostic.code == "firth.type.declared-effect-mismatch" then word.span.stop.offset
      else diagnostic.primary.stop.offset
  | .erasure _ (.linearUnused _ span) | .erasure _ (.untrackedStack _ span _) =>
      (bindingBlockEnd span word.body).getD span.stop.offset
  | .assumes _ _ _ inner => inner.reached word
  | other => (other.span?.map (·.stop.offset)).getD 0

/-- The words whose declared effects were read to check the edit a report's
hint offers: a misordered `locals` block (`checkLocalsEdits`), whose hint
says either that the edit fixes the word or that the body was written for the
names as they are, a call handed its values out of order
(`withCallAccount`), a refused `if` (`branchEdit`), or a condition written
after its quotations (`conditionEdit`). -/
private def PipelineDiagnostic.editConsulted : PipelineDiagnostic → List String
  | .parse error => (error.localsBlocks.flatMap (·.consulted)).eraseDups
  | .stackEffect diagnostic =>
      ((diagnostic.callAccount.bind (·.edit)).map (·.consulted)).getD [] ++
        ((diagnostic.ifAccount.bind (·.edit)).map (·.consulted)).getD [] ++
        ((diagnostic.conditionEdit.map (·.consulted)).getD [])
  | .erasure _ (.branchShape _ _ _ _ (some account)) => ((account.edit.map (·.consulted)).getD [])
  | .assumes _ _ _ inner => inner.editConsulted
  | _ => []

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

/-- The first error erasure or the type checker finds in `word` among
`words`, as it is found: `none` when the word is accepted. The other words are
given by their declared effects only, so an error of theirs is never charged
to `word`. One whose declared effect is no type scheme is left out of typing:
its own report says so, and collecting the schemes would otherwise fail on it
before `word` is checked. -/
private def firstErrorAlone (config : PipelineConfig) (words : List WordDefinition)
    (word : WordDefinition) : Option PipelineDiagnostic :=
  let others := words.filter (·.name != word.name)
  match erase (makeErasureEnv config (word :: others)) word.effect word.body with
  | .error error => some (.erasure word.name error)
  | .ok erased =>
      let typed := others.filter fun other => (schemeOfEffect other.effect).toOption.isSome
      let definitions : List StackEffect.Definition :=
        { name := word.name, declared := word.effect, program := erased.program, span := word.span } ::
          typed.map fun other => { name := other.name, declared := other.effect, program := [], span := other.span }
      match checkDictionary config.typingEnv definitions with
      | .ok _ => none
      -- The word is checked first, so an error charged to another word
      -- means it passed.
      | .error diagnostic =>
          if diagnostic.word.isSome && diagnostic.word != some word.name then none
          else some (.stackEffect diagnostic)

/-- What erasure and the type checker make of `word` among `words`: `none`
when it is accepted, else where in the source its first error is, as the
author would see it. -/
private def outcomeAlone (config : PipelineConfig) (source : String) (words : List WordDefinition)
    (word : WordDefinition) : Option Nat :=
  (firstErrorAlone config words word).map fun
    | .stackEffect diagnostic =>
        (withFirstMisfed config source (word :: words.filter (·.name != word.name)) diagnostic).primary.start.offset
    | other => (other.span?.map (·.start.offset)).getD 0

/-- The words whose declared effects checking `word` among `words` read.
Typing runs only on a body erasure got through, and erasure reads the effect
of every call it gets to, so these are the calls erasure read. A call is read
when erasing without that word's effect comes out otherwise: a report is not
always placed where erasure stopped (a linear local used twice is found at its
first use and reported at its second), so the report's place cannot say. -/
private def consultedWords (config : PipelineConfig) (words : List WordDefinition)
    (word : WordDefinition) : List String :=
  let env := makeErasureEnv config (word :: words.filter (·.name != word.name))
  let erased := erase env word.effect word.body
  let read (name : String) : Bool :=
    match erased, erase { env with word := fun other => if other == name then none else env.word other }
        word.effect word.body with
    | .error error, .error without => error != without
    | _, _ => true
  ((calledWords [] word.body).map (·.1)).eraseDups.filter fun name => name != word.name && read name

/-- The text of `source` from byte `start` to byte `stop`. -/
private def bytesText (source : String) (start stop : Nat) : String :=
  (String.fromUTF8? (source.toUTF8.extract start stop)).getD ""

/-- The line and column of byte `offset` in `source`, counting from 1. -/
private def lineColumn (source : String) (offset : Nat) : Nat × Nat :=
  (bytesText source 0 offset).foldl (fun (line, column) c =>
    if c == '\n' then (line + 1, 1) else (line, column + 1)) (1, 1)

private def collapseSpace (text : String) : String :=
  " ".intercalate (((text.map fun c => if c.isWhitespace then ' ' else c).splitOn " ").filter (!·.isEmpty))

/-- Where an edit from byte `start` to byte `stop` of `source` is, for a hint
that says "in place of `written` on line L": the line, and the column too
when `written`, as whole items, is found more than once on the lines the
edit spans, as `candidate 1 prim + n collect-primes` is in both branches of
`[ result candidate prim seq-int.push candidate 1 prim + n collect-primes ]
[ candidate 1 prim + n collect-primes ] if`. -/
private def editPlace (source : String) (start stop : Nat) (written : String) : Nat × Option Nat :=
  let (line, column) := lineColumn source start
  let lastLine := (lineColumn source stop).1
  let lines := ((source.splitOn "\n").drop (line - 1)).take (lastLine + 1 - line)
  let items (text : String) := ((collapseSpace text).splitOn " ").filter (!·.isEmpty)
  let text := items ("\n".intercalate lines)
  let wanted := items written
  let found := (List.range (text.length + 1)).countP fun i =>
    !wanted.isEmpty && (text.drop i).take wanted.length == wanted
  (line, if found > 1 then some column else none)

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
        if !config.checkEdits then none else
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
        -- resolve.
        let (resolved, _) ← (resolveEach file.declarations (fun name => (config.erasureEnv.word name).isSome)).toOption
        let editedWords := resolved.map (·.1)
        let word ← (resolved.find? fun (word, error) => word.name == name && error.isNone).map (·.1)
        let operation := ((diagnostic.primary.start.offset : Int) + shift).toNat
        let after ← match outcomeAlone config edited editedWords word with
          | none => some none
          | some offset =>
              if offset ≤ operation then none
              -- In the source as edited: the author applies the edit, and
              -- a replaced text that spans lines leaves fewer of them.
              else some (some (lineColumn edited offset))
        let written := collapse (bytesText source start stop)
        let (line, column) := editPlace source start stop written
        pure { start, stop, line, column, written, replacement, after
               consulted := consultedWords config editedWords word }
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

/-- Whether a refused `if` at byte `ifStart` is shown checked when, after an
edit, the word's next error is at byte `offset`, found by typing when
`typing` and by erasure otherwise. Erasure and typing each check the body
from the start, so an error after the `if` means that stage got past it. A
type error before it, as a misordered `prim seq-int.at` in source the edit
left as it was, shows the `if` got past erasure, when erasure refused it
(`byErasure`): typing runs only on a body erasure got through. Anything else
at or before the `if` may have stopped the check short of it. -/
def editGetsPast (byErasure typing : Bool) (ifStart offset : Nat) : Bool :=
  offset > ifStart || (offset < ifStart && byErasure && typing)

/-- The edit applied to `source` and `word` checked again: where the word's
next error is, as a line and column of the edited source, or `none` inside
when it then checks. `none` when the check does not show the edit gets past
the refused `if` at `ifStart`: the next error is at the `if` or anywhere
before it that checking reaches first, or the edited source does not parse
or resolve. `byErasure` says the `if` was refused by erasure: then a type
error anywhere comes after it, as typing runs only on a body erasure got
through. Also the words whose effects the check read. -/
private def checkBranchEdit (config : PipelineConfig) (source wordName : String) (byErasure : Bool)
    (ifStart start stop : Nat) (replacement : String) :
    Option (Option (Nat × Nat) × List String) := do
  let edited := bytesText source 0 start ++ replacement ++ bytesText source stop source.utf8ByteSize
  let shift : Int := (replacement.utf8ByteSize : Int) - ((stop - start : Nat) : Int)
  let file ← match parse edited with
    | .success file => some file
    | .failure _ => none
  let (resolved, _) ← (resolveEach file.declarations (fun name => (config.erasureEnv.word name).isSome)).toOption
  let editedWords := resolved.map (·.1)
  let word ← (resolved.find? fun (word, error) => word.name == wordName && error.isNone).map (·.1)
  let at_ := ((ifStart : Int) + shift).toNat
  let after ← match firstErrorAlone config editedWords word with
    | none => some none
    | some error =>
        let offset := (outcomeAlone config edited editedWords word).getD 0
        let typing := match error with
          | .stackEffect _ => true
          | _ => false
        if editGetsPast byErasure typing at_ offset then some (some (lineColumn edited offset))
        else none
  pure (after, consultedWords config editedWords word)

/-- For a refused `if` whose longer branch leaves one value more than the
other, below the result of a call: when that value was computed by an
operation handed exactly one local of the value's type, and the call was
then handed that same local once more, as in
`result prim seq-int.push xs idx 1 prim - result rev-iter`, the edit that
binds the new value to the local's name for the call:
`prim seq-int.push locals { result } { xs idx 1 prim - result rev-iter }`.
The local must appear just once between the operation and the call, and the
source between them must close every bracket it opens, so the new block
holds the call and nothing else changes. -/
private def staleEdit (config : PipelineConfig) (source : String)
    (wordName : String) (byErasure : Bool) (ifSpan : Span) (account : IfAccount) : Option BranchEdit := do
  let net (branch : BranchAccount) : Int :=
    (branch.leaves.length : Int) - ((branch.took.length + branch.missing : Nat) : Int)
  let longer ← if net account.onTrue == net account.onFalse + 1 then some account.onTrue
    else if net account.onFalse == net account.onTrue + 1 then some account.onFalse else none
  -- The value left behind is the lowest the longer branch leaves, and the
  -- call's result is just above it.
  let computed ← (longer.made[0]?).join
  let call ← (longer.made[1]?).join
  let type ← computed.type
  let name ← match (computed.locals.filter (·.2 == some type)).map (·.1) |>.eraseDups with
    | [name] => some name
    | _ => none
  if (call.locals.filter (·.1 == name)).length != 1 then none else
  let start := computed.span.start.offset
  let middle := computed.span.stop.offset
  let callStart := call.span.start.offset
  let stop := call.span.stop.offset
  if middle > callStart then none else
  let between := collapseSpace (bytesText source middle callStart)
  let tokens := (between.splitOn " ").filter (!·.isEmpty)
  if tokens.count name != 1 then none else
  -- Every bracket opened between them is closed there, and none closed
  -- that was opened before.
  let balanced := tokens.foldl (init := some (0 : Nat)) fun depth token =>
    depth.bind fun depth =>
      if token == "[" || token == "{" then some (depth + 1)
      else if token == "]" || token == "}" then (if depth == 0 then none else some (depth - 1))
      else some depth
  if balanced != some 0 then none else
  let replacement := s!"{collapseSpace (bytesText source start middle)} locals \{ {name} } \{ {between} {collapseSpace (bytesText source callStart stop)} }"
  let (after, consulted) ← checkBranchEdit config source wordName byErasure ifSpan.start.offset start stop replacement
  let written := collapseSpace (bytesText source start stop)
  let (line, column) := editPlace source start stop written
  pure { fix := .stale name computed.operation call.operation, start, stop, line, column
         written, replacement, after, consulted }

/-- For a refused `if` with a branch whose first operation short of values,
a word, takes them only from where there are none, as in
`candidate 1 prim + n collect-primes` for
`collect-primes ( result:Seq Int candidate:Int n:Int -- ... )` inside
`locals { result candidate n }`: the edit that pushes the word's inputs in
its order, writing each input the branch did not push as the local of its
name and type, `result candidate 1 prim + n collect-primes`. Which input a
pushed value is for is told by the local it stands for (`candidate` for
`candidate 1 prim +`) when every pushed value stands for a different input;
otherwise by types, when the pushed values are the last inputs or the first
in one way alone and none stands for another input. -/
private def missingEdit (config : PipelineConfig) (source : String)
    (wordName : String) (byErasure : Bool) (ifSpan : Span) (account : IfAccount) : Option BranchEdit := do
  let reach ← (account.onTrue.reach.filter (·.missing > 0)) <|> (account.onFalse.reach.filter (·.missing > 0))
  let span ← reach.span
  let pushed := reach.own.length
  if !reach.below.isEmpty || reach.missing + pushed != reach.count || pushed == 0 then none else
  if reach.types.length != reach.count || reach.inputs.length != reach.count then none else
  let lacking := reach.missing
  let inputNames := reach.inputs.map fun input => ((input.splitOn ":").head?).getD ""
  let inputs := inputNames.zip reach.types
  -- The local of an input's name and type, in scope.
  let named (name type : String) : Option (Option Nat × String) :=
    if reach.scope.lookup name == some (some type) then some (none, name) else none
  -- For each input, the pushed value for it (by its index, bottom to top)
  -- or the local to write.
  let byName : Option (List (Option Nat × String)) := do
    let sources ← reach.ownSources.mapM id
    -- Each input is filled once: an effect naming two inputs alike, as
    -- `x:Int x:Int`, would have one pushed value fill both.
    if sources.eraseDups.length != sources.length || !sources.all inputNames.contains
        || inputNames.eraseDups.length != inputNames.length then none else
    inputs.mapM fun (name, type) =>
      match sources.idxOf? name with
      | some j => if reach.ownTypes[j]? == some (some type) then some (some j, name) else none
      | none => named name type
  let byType : Option (List (Option Nat × String)) := do
    let asLast := reach.ownTypes == (reach.types.drop lacking).map some
    let asFirst := reach.ownTypes == (reach.types.take pushed).map some
    if asLast == asFirst then none else
    let order : List (Option Nat) := if asLast
      then List.replicate lacking none ++ (List.range pushed).map some
      else (List.range pushed).map some ++ List.replicate lacking none
    -- A pushed value that stands for a local named like another input, as
    -- a new `result` computed from `result` does, was meant for that
    -- input: the types alone would place it wrong.
    let misplaced := (order.zip inputNames).any fun (value, name) =>
      match value.bind (reach.ownSources[·]?) |>.join with
      | some source => inputNames.contains source && source != name
      | none => false
    if misplaced then none else
    (order.zip inputs).mapM fun (value, name, type) =>
      match value with
      | some j => some (some j, name)
      | none => named name type
  let plan ← byName <|> byType
  let names := plan.filterMap fun (value, name) => if value.isNone then some name else none
  let pieces := plan.filterMap (·.1)
  let reordered := pieces != List.range pushed
  -- Without reordering, the locals go before the pushed values or just
  -- before the word; otherwise every pushed value must have its own piece
  -- of source, one after another up to the word.
  let namesFirst := (plan.take lacking).all (·.1.isNone)
  let namesLast := (plan.drop pushed).all (·.1.isNone)
  let (start, texts) ← if !reordered && namesFirst then do
      let first ← (reach.ownOrigins[0]?).join
      pure (first.1, names ++ [collapseSpace (bytesText source first.1 span.start.offset)])
    else if !reordered && namesLast then
      -- From the first pushed value where the walk knows it, so the text
      -- replaced is more than the word's name.
      match (reach.ownOrigins[0]?).join with
      | some first => pure (first.1, [collapseSpace (bytesText source first.1 span.start.offset)] ++ names)
      | none => pure (span.start.offset, names)
    else do
      let ranges ← reach.ownOrigins.mapM id
      let ends := ranges.map (·.2)
      let starts := (ranges.drop 1).map (·.1) ++ [span.start.offset]
      if !(ends.zip starts).all (fun (a, b) => a ≤ b && (bytesText source a b).all Char.isWhitespace) then none else
      let first ← ranges.head?
      let texts ← plan.mapM fun (value, name) => match value with
        | some j => ranges[j]?.map fun (a, b) => collapseSpace (bytesText source a b)
        | none => some name
      pure (first.1, texts)
  let stop := span.stop.offset
  let replacement := " ".intercalate (texts ++ [collapseSpace (bytesText source span.start.offset stop)])
  let (after, consulted) ← checkBranchEdit config source wordName byErasure ifSpan.start.offset start stop replacement
  let written := collapseSpace (bytesText source start stop)
  let (line, column) := editPlace source start stop written
  pure { fix := .missing names reordered, start, stop, line, column
         written, replacement, after, consulted }

/-- The edit for a refused `if`, when one is found and gets past it: a value
left behind, then inputs lacking. -/
private def branchEdit (config : PipelineConfig) (source wordName : String) (byErasure : Bool)
    (ifSpan : Span) (account : IfAccount) : Option BranchEdit :=
  if !config.checkEdits then none else
  (staleEdit config source wordName byErasure ifSpan account).orElse fun _ =>
    missingEdit config source wordName byErasure ifSpan account

/-- A refused `if` with its account, and the edit `branchEdit` finds for it. -/
private def withBranchEdit (config : PipelineConfig) (source : String) :
    PipelineDiagnostic → PipelineDiagnostic
  | .erasure word (.branchShape span onTrue onFalse locals (some account)) =>
      let account := { account with edit := branchEdit config source word true span account }
      .erasure word (.branchShape span onTrue onFalse locals (some account))
  | .stackEffect diagnostic =>
      match diagnostic.ifAccount, diagnostic.word with
      | some account, some word =>
          let account := { account with edit := branchEdit config source word false diagnostic.primary account }
          .stackEffect { diagnostic with ifAccount := some account }
      | _, _ => .stackEffect diagnostic
  | other => other

/-- The whitespace-separated items of `source` from byte `start` to byte
`stop`, each with the bytes it spans. -/
private def itemsIn (source : String) (start stop : Nat) : List (String × Nat × Nat) :=
  let text := bytesText source start stop
  let (items, current, _) := text.foldl (init := (([] : List (String × Nat × Nat)), (none : Option (String × Nat)), start))
    fun (items, current, offset) c =>
      let next := offset + c.utf8Size
      if c.isWhitespace then
        match current with
        | some (item, from_) => (items ++ [(item, from_, offset)], none, next)
        | none => (items, none, next)
      else
        match current with
        | some (item, from_) => (items, some (item.push c, from_), next)
        | none => (items, some (String.singleton c, offset), next)
  match current with
  | some (item, from_) => items ++ [(item, from_, stop)]
  | none => items

/-- For an error at `offset` in `word` that lies in the condition of an `if`
written after its two quotations, `[ a ] [ b ] x 0 prim < if`, or at that
`if`: the edit that writes the condition first,
`x 0 prim < [ a ] [ b ] if`. The condition is the items between the second
quotation and the `if`, with no bracket, comment or `;` among them. The
edit is kept only when the edited word then checks, or its next error is
after the `if`. -/
private def conditionEdit (config : PipelineConfig) (source : String) (word : WordDefinition)
    (offset : Nat) : Option CallEdit := do
  if !config.checkEdits then none else
  let items := (itemsIn source word.span.start.offset word.span.stop.offset).toArray
  let opener (close : Nat) : Option Nat :=
    let rec go (i depth : Nat) (fuel : Nat) : Option Nat :=
      match fuel with
      | 0 => none
      | fuel + 1 =>
        let text := (items[i]?.map (·.1)).getD ""
        let depth := if text == "]" then depth + 1 else if text == "[" then depth - 1 else depth
        if text == "[" && depth == 0 then some i
        else if i == 0 then none else go (i - 1) depth fuel
    go close 0 (close + 1)
  let found := (List.range items.size).findSome? fun k => do
    let (text, _, ifStop) ← items[k]?
    if text != "if" then none else
    -- The condition: items back from the `if` to the second quotation.
    let condition := ((List.range k).reverse.takeWhile fun i =>
      let t := (items[i]?.map (·.1)).getD ""
      !(t.any fun c => c == '[' || c == ']' || c == '{' || c == '}' || c == '\\' || c == '(' || c == ';'))
    let first ← condition.getLast?
    if condition.isEmpty then none else
    let close2 := first - 1
    if first == 0 || (items[close2]?.map (·.1)) != some "]" then none else
    let open2 ← opener close2
    if open2 == 0 || (items[open2 - 1]?.map (·.1)) != some "]" then none else
    let open1 ← opener (open2 - 1)
    let (_, conditionStart, _) ← items[first]?
    if offset < conditionStart || offset ≥ ifStop then none else
    let (_, start, _) ← items[open1]?
    let (_, _, quotationsStop) ← items[close2]?
    let (_, _, conditionStop) ← items[k - 1]?
    some (start, ifStop, collapseSpace (bytesText source conditionStart conditionStop),
      collapseSpace (bytesText source start quotationsStop))
  let (start, stop, conditionText, quotations) ← found
  let replacement := s!"{conditionText} {quotations} if"
  let edited := bytesText source 0 start ++ replacement ++ bytesText source stop source.utf8ByteSize
  let file ← match parse edited with
    | .success file => some file
    | .failure _ => none
  let (resolved, _) ← (resolveEach file.declarations (fun name => (config.erasureEnv.word name).isSome)).toOption
  let editedWords := resolved.map (·.1)
  let edited_ ← (resolved.find? fun (w, error) => w.name == word.name && error.isNone).map (·.1)
  let ifStart := start + replacement.utf8ByteSize - 2
  let after ← match firstErrorAlone config editedWords edited_ with
    | none => some none
    | some error =>
        let at_ := (outcomeAlone config edited editedWords edited_).getD 0
        let typing := match error with
          | .stackEffect _ => true
          | _ => false
        if editGetsPast false typing ifStart at_ then some (some (lineColumn edited at_)) else none
  let written := collapseSpace (bytesText source start stop)
  let (line, column) := editPlace source start stop written
  pure { start, stop, line, column, written, replacement, after
         consulted := consultedWords config editedWords edited_ }

/-- A type error with the condition-first edit `conditionEdit` finds, when no
reordering edit was found for it. -/
private def withConditionEdit (config : PipelineConfig) (source : String) (word : WordDefinition) :
    PipelineDiagnostic → PipelineDiagnostic
  | .stackEffect diagnostic =>
      if (diagnostic.callAccount.bind (·.edit)).isSome then .stackEffect diagnostic else
      .stackEffect { diagnostic with
        conditionEdit := conditionEdit config source word diagnostic.primary.start.offset }
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
          if !config.checkEdits then { block with checked := false } else
          let edited := applyLocalsBlock word block
          let checked := match outcomeAlone config source words edited,
              outcomeAlone config source words word with
            | none, _ => true
            | some edited, some written => edited ≥ written
            | some _, none => false
          { block with
            checked := checked && !block.rebound
            consulted := if block.rebound then [] else
              (consultedWords config words edited ++ consultedWords config words word).eraseDups }
      | none => block }

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
  | .error error => .refused [withBranchEdit config source (withAccount config source words (.erasure word.name error))]
  | .ok erased =>
  match schemeOfEffect word.effect with
  | .error diagnostic => .refused [.stackEffect diagnostic]
  | .ok declared =>
  match check typing declared erased.program word.effect.span with
  | .error diagnostic =>
      let diagnostic := withFirstMisfed config source words { diagnostic with word := some word.name }
      .refused [withConditionEdit config source word (withCallAccount config source words
        (withBranchEdit config source (withAccount config source words (.stackEffect diagnostic))))]
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

/-- `effect` with the same inputs and outputs, of other types: an Int
becomes a Bool, and any other type an Int. First every value changes, then
the outputs only, then each value alone, since fixing a word's effect often
changes only some of its types. A report
that changes under one depends on the types the callee declares, not only on
how many values it takes and leaves. -/
private def swappedTypes (effect : StackEffect) : List StackEffect :=
  let swap : StackItem → StackItem
    | .value name type span =>
        .value name { type with name := if type.name == "Int" then "Bool" else "Int", refinements := [] } span
    | row => row
  let swapWhere (pick : Nat → Bool) : StackEffect :=
    let over (first : Nat) (items : List StackItem) : List StackItem :=
      ((List.range items.length).zip items).map fun (index, item) =>
        if pick (first + index) then swap item else item
    { effect with input := over 0 effect.input, output := over effect.input.length effect.output }
  let count := effect.input.length + effect.output.length
  ([swapWhere (fun _ => true), swapWhere (· ≥ effect.input.length)] ++
      (List.range count).map fun position => swapWhere (· == position)).eraseDups.filter
    (· != effect)

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
          -- A report depends on the effect of a called word with an error of
          -- its own when, made without checking edits and with that callee
          -- given one of the probe effects, or its own effect with other
          -- types, checking gets at least as far as this report and finds
          -- something else: the word is accepted, or is refused with other
          -- reports, one of them from a later stage or from this stage no
          -- earlier in the order it checks (`reached`). A report made before
          -- this one only hides it, and says nothing about it. Apart from
          -- that, a hint whose edit was checked was checked against the
          -- effect of each such word called before that check stopped.
          let unedited := { config with checkEdits := false }
          -- The environments are the file's, with a probed callee's entry
          -- replaced, so that each probe costs one word's check.
          let recheck (declared : List WordDefinition) (probed : Option WordDefinition)
              (word : WordDefinition) (resolution : Option ParseError) : WordOutcome :=
            let (probeEnv, probeTyping, probeUnusable) := match probed with
              | none => (env, typing, unusable)
              | some callee =>
                  let (one, oneTyping, oneUnusable) := environments unedited [callee]
                  ({ env with word := fun name => if name == callee.name then one.word name else env.word name },
                   { typing with word := fun name =>
                      if name == callee.name then oneTyping.word name else typing.word name },
                   unusable.filter (· != callee.name) ++ oneUnusable)
            checkWord unedited source declared written probeEnv probeTyping probeUnusable word resolution
          let changes (word : WordDefinition) (outcome : WordOutcome)
              (diagnostic : PipelineDiagnostic) : Bool :=
            match outcome with
            | .refused diagnostics =>
                !diagnostics.any (config.sameReport · diagnostic) && diagnostics.any fun other =>
                  other.stage > diagnostic.stage ||
                  other.stage == diagnostic.stage && other.reached word ≥ diagnostic.reached word
            | .checked _ => true
            | .skipped .. => false
          -- For each report, as made without checking edits, whether it
          -- depends on `callee`, starting from `marks`. The probes stop once
          -- every report is shown to depend on it.
          let dependsOn (word : WordDefinition) (resolution : Option ParseError)
              (bases : List PipelineDiagnostic) (marks : List Bool) (callee : String) : List Bool :=
            let own := ((declared.find? (·.name == callee)).map (swappedTypes ·.effect)).getD []
            (probeEffects ++ own).foldl (init := marks) fun marks effect =>
              if marks.all id then marks else
              let declared := declared.map fun other =>
                if other.name == callee then { other with effect } else other
              let outcome := recheck declared (declared.find? (·.name == callee)) word resolution
              (marks.zip bases).map fun (mark, base) => mark || changes word outcome base
          -- A word left unchecked says so, so that no one reads its
          -- silence as a pass. A report that depends on the effect of a word
          -- with an error of its own says so too: fixing that word's effect
          -- can change it.
          let errors : List PipelineDiagnostic := (resolved.zip outcomes).flatMap
            fun ((word, resolution), outcome) => match outcome with
              | .refused diagnostics =>
                  let callees := ((calledWords [] word.body).map (·.1)).eraseDups.filter
                    fun callee => callee != word.name && refused.contains callee
                  if callees.isEmpty then diagnostics else
                  let bases := match recheck declared none word resolution with
                    | .refused unchecked => (List.range diagnostics.length).zip diagnostics |>.map
                        fun (index, diagnostic) => unchecked.getD index diagnostic
                    | _ => diagnostics
                  let probes := callees.map fun callee =>
                    (callee, dependsOn word resolution bases (bases.map fun _ => false) callee)
                  (List.range diagnostics.length).zip diagnostics |>.map fun (index, diagnostic) =>
                    let named := probes.filterMap fun (callee, marks) =>
                      if marks.getD index false then some callee else none
                    let edits := callees.filter fun callee =>
                      diagnostic.editConsulted.contains callee && !named.contains callee
                    if named.isEmpty && edits.isEmpty then diagnostic
                    else .assumes word.name named edits diagnostic
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
