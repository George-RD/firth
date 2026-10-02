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
  | .unresolvedEffect _ span | .effectUnderflow _ span _ | .usageMismatch _ span
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
(`withCallAccount`), a refused `if` (`branchEdit`), a condition written
after its quotations (`conditionEdit`), or an operation handed fewer values
than it takes (`shortEdit`). -/
private def PipelineDiagnostic.editConsulted : PipelineDiagnostic → List String
  | .parse error => (error.localsBlocks.flatMap (·.consulted)).eraseDups
  | .stackEffect diagnostic =>
      ((diagnostic.callAccount.bind (·.edit)).map (·.consulted)).getD [] ++
        ((diagnostic.ifAccount.bind (·.edit)).map (·.consulted)).getD [] ++
        ((diagnostic.conditionEdit.map (·.consulted)).getD [])
  | .erasure _ (.branchShape _ _ _ _ (some account)) => ((account.edit.map (·.consulted)).getD [])
  | .erasure _ (.effectUnderflow _ _ (some account)) => ((account.edit.map (·.consulted)).getD [])
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
Only when the walk knows the type of every value the operation gets, or the
operation is handed fewer values than it takes (`Account.firstMisfed`),
which is reported as such, with the values it gets. It never changes what
is accepted: the checker refused the word either way. -/
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
    -- in the quotation whose `compose` erasure reports. A `dip` or `compose`
    -- reported where a word or primitive is written is one erasure wrote.
    if (account.span.start.offset == diagnostic.primary.start.offset &&
          !(diagnostic.subject == some "dip" || diagnostic.subject == some "compose")) ||
        account.span.start.offset ≥ diagnostic.primary.stop.offset then none else
    let subject := ((account.operation.drop 1).dropEnd 1).toString
    if account.missing > 0 then
      pure { diagnostic with
             code := "firth.type.stack-underflow"
             primary := account.span
             subject := some subject
             expected := none
             actual := none
             callAccount := some account
             branchOutputs := none
             branchInput := none
             ifAccount := none } else
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
      subject := some subject
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
        -- Up to the last item before the operation: the space after it,
        -- line breaks included, stays as written, as it does when the
        -- author makes the edit, so the next error's line is the one the
        -- author will see.
        let stop := start + (bytesText source start diagnostic.primary.start.offset).trimAsciiEnd.toString.utf8ByteSize
        let texts ← order.mapM fun i => ranges[i]?.map fun (a, b) => bytesText source a b
        let replacement := " ".intercalate (texts.map collapse)
        let edited := bytesText source 0 start ++ replacement ++ bytesText source stop source.utf8ByteSize
        let shift : Int := (replacement.utf8ByteSize : Int) - ((stop - start : Nat) : Int)
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

/-- The items written after the one at `span`, in the list of items it is
written in, searching quotations and `locals` blocks. -/
private partial def itemsAfter (span : Span) : List Item → Option (List Item)
  | [] => none
  | item :: rest =>
      let here := match item with
        | .word _ at_ | .primitive _ at_ => at_ == span
        | _ => false
      if here then some rest else
      let inner := match item with
        | .quotation items _ | .locals _ items _ => itemsAfter span items
        | _ => none
      match inner with
      | some found => some found
      | none => itemsAfter span rest

/-- A call edit applied to `source`, replacing bytes `start` to `stop` with
`replacement`, in which the operation starts `operationAt` bytes in: kept
only when `word` then checks, or is refused only later in the source than
the operation, and saying which. -/
private def checkCallEdit (config : PipelineConfig) (source : String) (word : WordDefinition)
    (start stop : Nat) (replacement : String) (operationAt : Nat) : Option CallEdit := do
  let edited := bytesText source 0 start ++ replacement ++ bytesText source stop source.utf8ByteSize
  let file ← match parse edited with
    | .success file => some file
    | .failure _ => none
  let (resolved, _) ← (resolveEach file.declarations (fun name => (config.erasureEnv.word name).isSome)).toOption
  let editedWords := resolved.map (·.1)
  let editedWord ← (resolved.find? fun (candidate, error) => candidate.name == word.name && error.isNone).map (·.1)
  let operation := start + operationAt
  let outcome := outcomeAlone config edited editedWords editedWord
  let after ← match outcome with
    | none => some none
    | some offset => if offset ≤ operation then none else some (some (lineColumn edited offset))
  -- Where that error is in the source as written: past the edit, the same
  -- item; inside it, the end of the text replaced.
  let reached := outcome.map fun offset =>
    if offset ≥ start + replacement.utf8ByteSize then offset - replacement.utf8ByteSize + stop else stop
  let written := collapseSpace (bytesText source start stop)
  let (line, column) := editPlace source start stop written
  pure { start, stop, line, column, written, replacement, after, reached
         consulted := consultedWords config editedWords editedWord }

/-- For an operation handed fewer values than it takes (`CallAccount.missing`),
the edit that moves the values written just after it to before it, when
there are exactly as many of those as it is missing and each is for the
input it would fill: a local of that input's name, or a literal of its type.
`0 0 sum-helper xs` becomes `0 0 xs sum-helper` when `sum-helper`'s last
input is `xs`. A primitive's inputs have no names, so for a primitive which
value is missing is not certain, and there is no edit. The edit is applied
and the word checked again: it is kept only when the word then checks, or is
refused only later in the source than the operation, and says which. -/
private def shortEdit (config : PipelineConfig) (source : String) (word : WordDefinition)
    (account : CallAccount) : Option CallEdit := do
  if !config.checkEdits || account.missing == 0 || account.operation.startsWith "`prim " then none else
  let after ← itemsAfter account.span word.body
  let moved := after.take account.missing
  if moved.length != account.missing then none else
  -- They are for its top inputs, in order. A word's inputs are written
  -- `name:Type`, a primitive's as types.
  let primitive := account.operation.startsWith "`prim "
  let inputs := (account.inputs.drop (account.inputs.length - account.missing)).map fun input =>
    if primitive then ("", input)
    else (((input.splitOn ":").head?).getD "", ":".intercalate ((input.splitOn ":").drop 1))
  let spans ← (moved.zip inputs).mapM fun
    -- The recheck below does not always reach the type checker: when
    -- erasure fails later in the edited word, typing never runs, so a literal
    -- of another type would pass it. Its type is compared here.
    | (.literal literal at_, (_, type)) =>
        let literalType := match literal.value with
          | .integer _ => "Int"
          | .boolean _ => "Bool"
          | _ => ""
        if literalType == type then some at_ else none
    | (.word name at_, (input, _)) => if account.locals.contains name && name == input then some at_ else none
    | _ => none
  let last ← spans.getLast?
  let start := account.span.start.offset
  let stop := last.stop.offset
  let movedText := collapseSpace (bytesText source (← spans.head?).start.offset stop)
  let operationText := collapseSpace (bytesText source start account.span.stop.offset)
  checkCallEdit config source word start stop (movedText ++ " " ++ operationText) (movedText.utf8ByteSize + 1)

/-- For a word handed fewer values than it takes, where no value written
after it is for the inputs missing (`shortEdit`): the edit that writes, for
each input missing, the local of its name and type, in that input's place
among the values present. `seq 0 contains-loop` becomes
`seq 0 val contains-loop` when `contains-loop` takes
`seq:Seq Int idx:Int val:Int` and `val` is an Int local. Every value
present must have a known type, and the values present must fill the other
inputs, in order and with their types, in one way alone, where each input
left is named like a local of its type. A value present that stands for a
local named like another input is not for this one. The recheck below does
not always reach the type checker (a later erasure error stops it first),
so the types are compared here. A primitive's inputs have no names, so for
a primitive there is no edit. -/
private def unpushedEdit (config : PipelineConfig) (source : String) (word : WordDefinition)
    (account : CallAccount) : Option CallEdit := do
  if !config.checkEdits || account.missing == 0 || account.operation.startsWith "`prim " then none else
  let present := account.present.length
  if account.types.length != present || account.presentSources.length != present then none else
  let types ← account.types.mapM id
  let inputs := account.inputs.map fun input =>
    (((input.splitOn ":").head?).getD "", ":".intercalate ((input.splitOn ":").drop 1))
  let inputNames := inputs.map (·.1)
  if inputs.length != present + account.missing || inputNames.eraseDups.length != inputNames.length then none else
  -- A local named like an input whose type the walk does not know could be
  -- the one for that input, and the ways counted below would not include
  -- it: no edit, so that one way is one way of all.
  if inputNames.any fun name => account.locals.contains name && (account.localTypes.lookup name).isNone then none else
  -- The ways to fill the inputs, bottom to top: for each input the index
  -- of the value present for it, or `none` where the local of its name is
  -- written. Only whether there is exactly one matters, so each suffix of
  -- the inputs keeps, for each count of values left, how many ways there
  -- are (counted up to 2) and one of them: the work grows with inputs times
  -- values, where listing every way would grow with their binomial.
  let values := ((List.range present).zip (types.zip account.presentSources)).toArray
  let fits (name type : String) (j : Nat) : Bool := match values[j]? with
    | some (_, valueType, stands) =>
        let forOther := match stands with
          | some local_ => inputNames.contains local_ && local_ != name
          | none => false
        valueType == type && !forOther
    | none => false
  let last : Array (Nat × List (Option Nat)) :=
    (Array.range (present + 1)).map fun j => if j == present then (1, []) else (0, [])
  let table := inputs.foldr (init := last) fun (name, type) next =>
    (Array.range (present + 1)).map fun j =>
      let (filledCount, filledPlan) := if fits name type j
        then (next.getD (j + 1) (0, [])) else (0, [])
      let (writtenCount, writtenPlan) := if account.localTypes.lookup name == some type
        then next.getD j (0, []) else (0, [])
      (min 2 (filledCount + writtenCount),
       if filledCount > 0 then some j :: filledPlan else none :: writtenPlan)
  let plan ← match table[0]? with
    | some (1, plan) => some plan
    | _ => none
  let names := (plan.zip inputNames).filterMap fun (value, name) => if value.isNone then some name else none
  let operationStart := account.span.start.offset
  let operationText := collapseSpace (bytesText source operationStart account.span.stop.offset)
  -- With every local after the values present, they are written just
  -- before the operation; otherwise each value present must have its own
  -- piece of source, one after another up to the operation.
  let namesLast := (plan.dropWhile (·.isSome)).all (·.isNone)
  let (start, texts) ← match account.presentPieces with
    | some ranges =>
        let texts ← (plan.zip inputNames).mapM fun
          | (some j, _) => ranges[j]?.map fun (a, b) => collapseSpace (bytesText source a b)
          | (none, name) => some name
        pure (((ranges.head?).map (·.1)).getD operationStart, texts)
    | none => if namesLast then some (operationStart, names) else none
  let prefix_ := " ".intercalate texts
  let replacement := prefix_ ++ " " ++ operationText
  let added := (checkCallEdit config source word start account.span.stop.offset
    replacement (prefix_.utf8ByteSize + 1)).map ({ · with pushedLocals := names })
  -- Where those locals are written just after the operation, in that
  -- order, as in `pos 1 prim + insert-sorted value`, the author may have
  -- meant them for it: written once more, the ones after it are left
  -- over. The edit that moves them into place is offered instead, unless
  -- writing them again gets further: `5 g m prim +` may mean `m` for `+`.
  let after := ((itemsAfter account.span word.body).getD []).take names.length
  let spans := after.filterMap fun
    | .word _ at_ => some at_
    | _ => none
  let trailing := !names.isEmpty && spans.length == names.length && (after.zip names).all fun
    | (.word name _, wanted) => name == wanted
    | _ => false
  let moved := if !trailing then none else do
    let last ← spans.getLast?
    let edit ← checkCallEdit config source word start last.stop.offset replacement (prefix_.utf8ByteSize + 1)
    -- Checking gets at least as far in the source as written as with the
    -- locals written again.
    let asFar := match edit.reached, added.bind (·.reached) with
      | none, _ => true
      | some _, none => added.isNone
      | some movedTo, some addedTo => movedTo ≥ addedTo
    if asFar then some { edit with pushedLocals := names, moved := true } else none
  moved <|> added

/-- The edit for an operation handed fewer values than it takes: the values
written after it moved before it (`shortEdit`), or else the locals of the
inputs missing written (`unpushedEdit`). -/
private def shortOrUnpushed (config : PipelineConfig) (source : String) (word : WordDefinition)
    (account : CallAccount) : Option CallEdit :=
  (shortEdit config source word account).orElse fun _ => unpushedEdit config source word account

/-- An operation handed fewer values than it takes, with `shortOrUnpushed`: as
the checker reports it once `withFirstMisfed` found it, or as erasure
reports it, with the values it gets (`Account.ofShortCall`). It never
changes what is accepted. -/
private def withShortCall (config : PipelineConfig) (source : String)
    (words : List WordDefinition) (word : WordDefinition) : PipelineDiagnostic → PipelineDiagnostic
  | .stackEffect diagnostic =>
      match diagnostic.callAccount.filter (·.missing > 0) with
      | some account =>
          .stackEffect { diagnostic with callAccount := some { account with edit := shortOrUnpushed config source word account } }
      | none => .stackEffect diagnostic
  | .erasure name (.effectUnderflow operation span none) =>
      let account := Account.ofShortCall {
        words
        primitive := fun name => (config.typingEnv.primitive name).bind Account.primitiveShape
        external := fun name => (config.erasureEnv.word name).bind fun signature =>
          if !signature.rowPreserving then none else some
          (signature.input.length, signature.output.length)
        source
        target := span.start.offset } span
      .erasure name (.effectUnderflow operation span
        (account.map fun account => { account with edit := shortOrUnpushed config source word account }))
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

/-- For a refused `if` whose longer branch leaves `k` values more than the
other, just below the results of a call: when each of those values is a new value
of a different local (computed from it by an operation handed exactly one
local of its type, where that makes a new value of it, or chosen by an `if`
whose paths both stand for it), and
the call was then handed each of those locals once more, as in
`result prim seq-int.push xs idx 1 prim - result rev-iter`, the edit that
binds the new values to the locals' names for the call:
`prim seq-int.push locals { result } { xs idx 1 prim - result rev-iter }`.
Each local must be
handed to the call as it is, and appear just once between the values and
the call, whose source must close every bracket it opens, so the new block
holds the call and nothing else changes. -/
private def staleEdit (config : PipelineConfig) (source : String)
    (wordName : String) (byErasure : Bool) (ifSpan : Span) (account : IfAccount) : Option BranchEdit := do
  let net (branch : BranchAccount) : Int :=
    (branch.leaves.length : Int) - ((branch.took.length + branch.missing : Nat) : Int)
  let (longer, count) ← if net account.onTrue > net account.onFalse
    then some (account.onTrue, (net account.onTrue - net account.onFalse).toNat)
    else if net account.onFalse > net account.onTrue
    then some (account.onFalse, (net account.onFalse - net account.onTrue).toNat) else none
  -- The values left behind are the lowest the longer branch leaves, and
  -- the call pushed the value just above them.
  let call ← (longer.resultOf[count]?).join
  let names ← (longer.stands.take count).mapM id
  if names.length != count || names.eraseDups.length != count then none else
  -- The operation that pushed the top value, or the `if` that chose it.
  -- Just after it, the values left behind are the top `count`: a value
  -- between two of them would be left behind too.
  let (start, middle) ← match longer.made[count - 1]? with
    | some (some made) => some (made.span.start.offset, made.span.stop.offset)
    | _ => do
        let (_, middle) ← (longer.origins[count - 1]?).join
        if middle ≥ 2 && bytesText source (middle - 2) middle == "if" then some (middle - 2, middle) else none
  let callStart := call.span.start.offset
  let stop := call.span.stop.offset
  if middle > callStart then none else
  if !names.all fun name => (call.locals.filter (·.1 == name)).length == 1 then none else
  let between := collapseSpace (bytesText source middle callStart)
  let tokens := (between.splitOn " ").filter (!·.isEmpty)
  if !names.all (tokens.count · == 1) then none else
  -- Every bracket opened between them is closed there, and none closed
  -- that was opened before.
  let balanced := tokens.foldl (init := some (0 : Nat)) fun depth token =>
    depth.bind fun depth =>
      if token == "[" || token == "{" then some (depth + 1)
      else if token == "]" || token == "}" then (if depth == 0 then none else some (depth - 1))
      else some depth
  if balanced != some 0 then none else
  let replacement := s!"{collapseSpace (bytesText source start middle)} locals \{ {" ".intercalate names} } \{ {between} {collapseSpace (bytesText source callStart stop)} }"
  let (after, consulted) ← checkBranchEdit config source wordName byErasure ifSpan.start.offset start stop replacement
  let written := collapseSpace (bytesText source start stop)
  let (line, column) := editPlace source start stop written
  pure { fix := .stale names (longer.leaves.take count) call.operation, start, stop, line, column
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

/-- The items of a body with quotations and `locals` blocks opened, each with
its span and the locals bound around it. -/
private partial def leafItems (bound : List String) : List Item → List (Item × Span × List String)
  | [] => []
  | .quotation inner _ :: rest => leafItems bound inner ++ leafItems bound rest
  | .locals names inner _ :: rest =>
      leafItems (names.map (·.name) ++ bound) inner ++ leafItems bound rest
  | item@(.literal _ span) :: rest => (item, span, bound) :: leafItems bound rest
  | item@(.word _ span) :: rest => (item, span, bound) :: leafItems bound rest
  | item@(.atom _ span) :: rest => (item, span, bound) :: leafItems bound rest
  | item@(.primitive _ span) :: rest => (item, span, bound) :: leafItems bound rest

/-- Whether a run of items, as written, takes a value from below where it
starts: `some false` when every item's arity is known and none reaches
below, `some true` when one does, `none` when an item's arity is not known
(a higher-order atom, or an effect that does not keep the rest of the
stack). A local or a literal pushes one value. -/
private def takesBelow (env : EffectEnv) (run : List (Item × Span × List String)) : Option Bool := do
  let arity : Item × Span × List String → Option (Nat × Nat)
    | (.literal _ _, _, _) => some (0, 1)
    | (.word name _, _, bound) =>
        if bound.contains name then some (0, 1)
        else (env.word name).bind fun signature =>
          if signature.rowPreserving then some (signature.input.length, signature.output.length) else none
    | (.primitive name _, _, _) => (env.primitive name).bind fun signature =>
        if signature.rowPreserving then some (signature.input.length, signature.output.length) else none
    | (.atom "dup" _, _, _) => some (1, 2)
    | (.atom "drop" _, _, _) => some (1, 0)
    | (.atom "swap" _, _, _) => some (2, 2)
    | _ => none
  let (below, _) ← run.foldlM (init := (false, 0)) fun (below, depth) item => do
    let (takes, gives) ← arity item
    pure (below || takes > depth, depth - takes + gives)
  pure below

/-- For an error at `offset` in `word` that lies in the condition of an `if`
written after its two quotations, `[ a ] [ b ] x 0 prim < if`, or at that
`if`: the edit that writes the condition first,
`x 0 prim < [ a ] [ b ] if`. The condition is the items between the second
quotation and the `if`, with no bracket, comment or `;` among them. The
edit is kept only when the edited word then checks, or its next error is
after the `if`. When the error is at the `if`, the checker accepted the
condition on top of the quotations, so it may act on them, as `swap` in
`[ a ] [ b ] swap x if` exchanges them: moved first, it would act on other
values, and the edit could check with another meaning. So then the edit is
kept only when the condition, as written, takes nothing from below where
it starts. -/
private def conditionEdit (config : PipelineConfig) (source : String) (words : List WordDefinition)
    (word : WordDefinition) (offset : Nat) : Option CallEdit := do
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
    let (_, ifStart, _) ← items[k]?
    let (_, _, conditionStop) ← items[k - 1]?
    if offset ≥ ifStart then
      let run := (leafItems [] word.body).filter fun (_, span, _) =>
        span.start.offset ≥ conditionStart && span.stop.offset ≤ conditionStop
      if takesBelow (makeErasureEnv config words) run != some false then none
    let (_, start, _) ← items[open1]?
    let (_, _, quotationsStop) ← items[close2]?
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
private def withConditionEdit (config : PipelineConfig) (source : String) (words : List WordDefinition)
    (word : WordDefinition) :
    PipelineDiagnostic → PipelineDiagnostic
  | .stackEffect diagnostic =>
      if (diagnostic.callAccount.bind (·.edit)).isSome then .stackEffect diagnostic else
      .stackEffect { diagnostic with
        conditionEdit := conditionEdit config source words word diagnostic.primary.start.offset }
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
          -- A name the edit renames, one that claims no input by its label,
          -- is given the input left over, whatever it held as written. When
          -- that changes its type, only typing can show the body still
          -- fits, so the edit is not stated when an erasure error in the
          -- edited word keeps typing from running. A name the stack effect
          -- declares holds the input of that name, which is the edit's point.
          let inputs := word.effect.input.filterMap fun
            | .value _ type _ => some type.name
            | .row _ _ => none
          let first := inputs.length - block.block.length
          let editedType (name : String) : Option String :=
            let binder := (block.renames.lookup name).getD name
            (block.block.idxOf? binder).bind fun j => inputs[first + j]?
          let typesKept := block.pairs.all fun (name, _, type) =>
            (block.renames.lookup name).isNone || editedType name == some type
          let typed := match firstErrorAlone config words edited with
            | some (.erasure _ _) => false
            | _ => true
          let checked := match outcomeAlone config source words edited,
              outcomeAlone config source words word with
            | none, _ => true
            | some edited, some written => (typesKept || typed) && edited ≥ written
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
  | .error error => .refused [withShortCall config source words word
      (withBranchEdit config source (withAccount config source words (.erasure word.name error)))]
  | .ok erased =>
  match schemeOfEffect word.effect with
  | .error diagnostic => .refused [.stackEffect diagnostic]
  | .ok declared =>
  match check typing declared erased.program word.effect.span with
  | .error diagnostic =>
      let diagnostic := withFirstMisfed config source words { diagnostic with word := some word.name }
      .refused [withShortCall config source words word (withConditionEdit config source words word (withCallAccount config source words
        (withBranchEdit config source (withAccount config source words (.stackEffect diagnostic)))))]
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
