import agent.Firth.Agent.DiagnosticEnvelope
import elaborator.Firth.Parser
import elaborator.Firth.Erasure
import elaborator.Firth.StackEffect
import elaborator.Firth.Refinement
import elaborator.Firth.Pipeline

namespace Firth.Agent

open Lean

structure EmissionContext where
  payloadId : String
  requestId : String
  source : LocationSource
  obligations : List Obligation := []
  proposedFixes : List ProposedFix := []
  related : List Related := []
  groupId : Option String := none

private def locationFromSpan (source : LocationSource)
    (span : Firth.Elaborator.Span) : Location := {
  source
  range := {
    start := { line := span.start.line, column := span.start.column }
    stop := { line := span.stop.line, column := span.stop.column } } }

private def lastSegment (code : String) : String :=
  code.splitOn "." |>.reverse |>.head?.getD "unknown"

private def messageKey (code : String) : String :=
  "diagnostic." ++ (lastSegment code).replace "-" "_"

private def namedParams (name : String) : Json :=
  .mkObj [("name", .str name)]

private def stackValue (stack : Firth.Elaborator.StackEffect.AStack) : Opaque := {
  encoding := "opaque"
  value := .mkObj [
    ("lean_repr", .str s!"{repr stack}"),
    ("firth", .str (Firth.Elaborator.StackEffect.renderStack stack))]
  displayHint := some "firth" }

private def opaqueJson (value : Opaque) : Json :=
  let fields := [("encoding", Json.str value.encoding), ("value", value.value)]
  let fields := match value.displayHint with
    | none => fields
    | some hint => fields ++ [("display_hint", .str hint)]
  .mkObj fields

private def envelope (context : EmissionContext) (body : Diagnostic) : Envelope :=
  .diagnostic context.payloadId context.requestId {
    body with
    obligations := context.obligations
    proposedFixes := context.proposedFixes
    related := context.related
    groupId := context.groupId }

private def parseCause : Firth.Elaborator.ParseCause → String
  | .lexical => "lexical"
  | .grammar => "grammar"
  | .delimiter => "delimiter"
  | .validation => "validation"

private def parseCauseData (error : Firth.Elaborator.ParseError) : Json :=
  let fields := match error.expected with
    | none => []
    | some expected => [("expected", Json.str expected)]
  let fields := match error.actual with
    | none => fields
    | some actual => fields ++ [("actual", Json.str actual)]
  .mkObj fields

private def definitionShape : String :=
  "A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`."

/-- A plain-language sentence and a repair hint for a syntax or name error. -/
private def parseParams (error : Firth.Elaborator.ParseError) : Json :=
  let actual := error.actual.map (s!"`{·}`") |>.getD "the end of the input"
  let (message, hint) := match error.code with
    | "firth.name.unresolved" =>
        (s!"{actual} is not a defined word, primitive or local.",
          "Define it (definitions may appear in any order), fix the spelling, or write primitives as `prim +`, `prim -`, `prim *`, `prim <`, `prim =`. " ++ definitionShape)
    | _ =>
        let expected := match error.expected with
          | some expected => s!", expected `{expected}`"
          | none => ""
        (s!"Unexpected {actual}{expected}.", definitionShape)
  .mkObj [("message", .str message), ("hint", .str hint)]

def parserEnvelope (context : EmissionContext)
    (error : Firth.Elaborator.ParseError) : Envelope :=
  envelope context {
    code := error.code
    severity := "error"
    messageKey := messageKey error.code
    messageParams := parseParams error
    location := locationFromSpan context.source error.primary
    cause := { kind := parseCause error.cause, data := parseCauseData error }
    expectedStack := none
    actualStack := none }

def encodeParseError (context : EmissionContext)
    (error : Firth.Elaborator.ParseError) : String :=
  encode (parserEnvelope context error)

private structure ErasureDiagnostic where
  code : String
  cause : String
  params : Json
  span : Firth.Elaborator.Span

private def erasureDiagnostic : Firth.Elaborator.ErasureError → ErasureDiagnostic
  | .duplicateLocal name span =>
      { code := "firth.name.duplicate-local", cause := "name-resolution", params := namedParams name, span }
  | .unboundLocal name span =>
      { code := "firth.name.unbound-local", cause := "name-resolution", params := namedParams name, span }
  | .unsupportedCapture name span =>
      { code := "firth.elaboration.unsupported-capture", cause := "elaboration", params := namedParams name, span }
  | .missingStackValue span =>
      { code := "firth.type.stack-underflow", cause := "type-checking", params := .mkObj [], span }
  | .linearCopy name span =>
      { code := "firth.linearity.copy", cause := "linearity", params := namedParams name, span }
  | .linearUnused name span =>
      { code := "firth.linearity.unconsumed-resource", cause := "linearity", params := namedParams name, span }
  | .unresolvedEffect name span =>
      { code := "firth.name.unresolved-effect", cause := "name-resolution", params := namedParams name, span }
  | .effectUnderflow name span =>
      { code := "firth.type.stack-underflow", cause := "type-checking", params := namedParams name, span }
  | .usageMismatch name span =>
      { code := "firth.linearity.usage-mismatch", cause := "linearity", params := namedParams name, span }
  | .unsupportedLiteral span =>
      { code := "firth.elaboration.unsupported-literal", cause := "elaboration", params := .mkObj [], span }
  | .unsupportedAtom name span =>
      { code := "firth.elaboration.unsupported-atom", cause := "elaboration", params := namedParams name, span }

private def erasureExplanation (code name : String) : String × String :=
  match code with
  | "firth.name.duplicate-local" =>
      (s!"The local `{name}` is bound twice in one `locals` block.", "Give each local a different name.")
  | "firth.name.unbound-local" =>
      (s!"`{name}` is not a local in scope here.", "Bind it with `locals { name } { ... }`, which takes values from the top of the stack, or fix the spelling.")
  | "firth.elaboration.unsupported-capture" =>
      (s!"The nested `locals` block uses the outer local `{name}`.", "Pass the value in on the stack instead, or bind it in the inner block.")
  | "firth.type.stack-underflow" =>
      match name with
      | "" => ("A `locals` block or an operation here needs more values than the stack holds.",
          "`locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.")
      | "quotation" => ("The checker could not work out how many values a quotation here uses.",
          "Check that every word inside the quotation has its inputs available. If the program is correct, this is a checker limit: move the quotation's body into a named word.")
      | "erasure-depth" => ("This definition is nested too deeply for the checker.",
          "Split the definition into smaller named words.")
      | _ => (s!"`{name}` needs more values than the stack holds here.",
          s!"Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `{name}` and in what order.")
  | "firth.name.unresolved-effect" =>
      (s!"`prim {name}` is not a primitive.", "The available primitives are `prim +`, `prim -`, `prim *`, `prim <` and `prim =`.")
  | "firth.linearity.copy" =>
      (s!"The linear local `{name}` is used more than once.", "A linear value must be used exactly once.")
  | "firth.linearity.unconsumed-resource" =>
      (s!"The linear local `{name}` is never used.", "A linear value must be used exactly once.")
  | _ => ("", "")

def erasureEnvelope (context : EmissionContext)
    (error : Firth.Elaborator.ErasureError) : Envelope :=
  let diagnostic := erasureDiagnostic error
  envelope context {
    code := diagnostic.code
    severity := "error"
    messageKey := messageKey diagnostic.code
    messageParams :=
      let name := (diagnostic.params.getObjValAs? String "name").toOption.getD ""
      match erasureExplanation diagnostic.code name with
      | ("", _) => diagnostic.params
      | (message, hint) => diagnostic.params.mergeObj
          (.mkObj [("message", .str message), ("hint", .str hint)])
    location := locationFromSpan context.source diagnostic.span
    cause := { kind := diagnostic.cause }
    expectedStack := none
    actualStack := none }

def encodeErasureError (context : EmissionContext)
    (error : Firth.Elaborator.ErasureError) : String :=
  encode (erasureEnvelope context error)

private def stableWarningCode (code : String) : String :=
  match code with
  | "LOCAL_DEPTH" => "firth.elaboration.local-depth"
  | "STACK_JUGGLE" => "firth.elaboration.stack-juggle"
  | _ => "firth.elaboration.warning"

def erasureWarningEnvelope (context : EmissionContext)
    (warning : Firth.Elaborator.LintWarning) : Envelope :=
  let code := stableWarningCode warning.code
  envelope context {
    code
    severity := "warning"
    messageKey := messageKey code
    messageParams := if code == "firth.elaboration.warning" then
      .mkObj [("producer_code", .str warning.code)]
    else .mkObj []
    location := locationFromSpan context.source warning.span
    cause := { kind := "elaboration" }
    expectedStack := none
    actualStack := none }

def encodeErasureWarning (context : EmissionContext)
    (warning : Firth.Elaborator.LintWarning) : String :=
  encode (erasureWarningEnvelope context warning)

private def causeForCode (code : String) : String :=
  match code.splitOn "." with
  | "firth" :: "type" :: _ => "type-checking"
  | "firth" :: "linearity" :: _ => "linearity"
  | "firth" :: "name" :: _ => "name-resolution"
  | _ => "elaboration"

open Firth.Elaborator.StackEffect in
private def plural (count : Nat) (noun : String) : String :=
  if count == 1 then s!"1 {noun}" else s!"{count} {noun}s"

open Firth.Elaborator.StackEffect in
private def renderValues (values : List AType) : String :=
  if values.isEmpty then "nothing" else " ".intercalate (values.map renderType)

open Firth.Elaborator.StackEffect in
/-- The first position, counted from the top, where two value lists differ. -/
private def firstDifference (expected actual : List AType) : Option (Nat × AType × AType) :=
  let rec go (depth : Nat) : List AType → List AType → Option (Nat × AType × AType)
    | expectedTop :: expectedRest, actualTop :: actualRest =>
        if renderType expectedTop == renderType actualTop then go (depth + 1) expectedRest actualRest
        else some (depth, expectedTop, actualTop)
    | _, _ => none
  go 0 expected.reverse actual.reverse

private def ordinalFromTop : Nat → String
  | 0 => "the top value"
  | 1 => "the second value from the top"
  | 2 => "the third value from the top"
  | depth => s!"value {depth + 1} from the top"

private def capitalize (text : String) : String :=
  match text.toList with
  | first :: rest => String.ofList (first.toUpper :: rest)
  | [] => text

private def operandsNeeded : String → Option Nat
  | "dup" | "drop" | "call" | "quote" => some 1
  | "swap" | "dip" | "compose" => some 2
  | "if" => some 3
  | _ => none

open Firth.Elaborator.StackEffect in
/-- A plain-language sentence and a repair hint for a checker diagnostic,
written for an author who sees only this message and the source. -/
private def explain (diagnostic : Firth.Elaborator.StackEffect.Diagnostic) : String × String :=
  let at_ := diagnostic.subject.getD "this operation"
  let inWord := match diagnostic.word with
    | some word => s!" in `{word}`"
    | none => ""
  let before := renderStack diagnostic.state
  let expected := diagnostic.expected.map stackValues
  let actual := diagnostic.actual.map stackValues
  let rowNote := " Here ρ stands for the caller's values that this word must leave untouched."
  match diagnostic.code, expected, actual with
  | "firth.type.declared-effect-mismatch", some (declared, _), some (left, _) =>
      let word := diagnostic.word.getD "this word"
      let base := s!"`{word}` declares that it leaves {(diagnostic.expected.map renderStack).getD "?"} but its body leaves {(diagnostic.actual.map renderStack).getD "?"}."
      if left.length > declared.length then
        let extra := left.length - declared.length
        (base, s!"The body leaves {plural extra "extra value"} on top ({renderValues (left.drop declared.length)}). Consume or `drop` {if extra == 1 then "it" else "them"} before the end of the word, or declare {if extra == 1 then "it" else "them"} in the signature's output." ++ rowNote)
      else if left.length < declared.length then
        let missing := declared.length - left.length
        (base, s!"The body leaves {plural missing "value"} fewer than declared. Something consumes a value it should keep: copy it first with `dup`, or fix the signature." ++ rowNote)
      else match firstDifference declared left with
        | some (depth, want, got) =>
            (base, s!"{capitalize (ordinalFromTop depth)} is {renderType got} but the signature says {renderType want}. Convert it or change the declared output type.")
        | none => (base, "The stack shapes differ; compare the declared output with the body's result value by value.")
  | "firth.type.primitive-input-mismatch", some (wanted, _), some (present, row)
  | "firth.type.word-input-mismatch", some (wanted, _), some (present, row) =>
      let base := s!"`{at_}`{inWord} needs {renderValues wanted} on top of the stack, but the stack before it is {before}."
      if present.length < wanted.length && row.isSome then
        (base, s!"`{at_}` takes {plural wanted.length "value"} but only {plural present.length "value"} {if present.length == 1 then "is" else "are"} available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature." ++ rowNote)
      else match firstDifference wanted present with
        | some (depth, want, got) =>
            (base, s!"{capitalize (ordinalFromTop depth)} is {renderType got} but `{at_}` expects {renderType want}. Check the argument order (`swap` exchanges the top two values) or the operation.")
        | none => (base, s!"The inputs to `{at_}` do not match its signature {renderValues wanted}.")
  | "firth.type.stack-underflow", _, _ =>
      let count := match operandsNeeded at_ with
        | some count => s!" needs {plural count "value"} and"
        | none => ""
      (s!"`{at_}`{inWord}{count} ran out of values: the stack before it is {before}.",
        "A word can only use values declared as inputs in its signature or pushed earlier in its body. Add the missing input to the signature or push it first." ++ rowNote)
  | "firth.type.expected-bool", _, _ =>
      (s!"`if`{inWord} needs a Bool condition under its two quotations, but the stack before it is {before}.",
        "Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.")
  | "firth.type.expected-quotation", _, _ =>
      (s!"`{at_}`{inWord} needs a quotation, but the stack before it is {before}.",
        "Put a `[ ... ]` quotation where the operation expects one.")
  | "firth.type.branch-mismatch", _, _ =>
      (s!"The two branches of `if`{inWord} leave different stacks.",
        s!"Both branches must leave the same number and types of values. Expected {(diagnostic.expected.map renderStack).getD "?"}, found {(diagnostic.actual.map renderStack).getD "?"}.")
  | "firth.type.quotation-input-mismatch", _, _ =>
      (s!"The quotation run by `{at_}`{inWord} does not accept the stack below it ({before}).",
        "Check what the quotation body consumes against the values available under it.")
  | "firth.name.unknown-word", _, _ =>
      (s!"`{at_}`{inWord} is not a defined word.",
        s!"Define it with `: {at_} (forall ρ; ρ in:Int^many -- ρ out:Int^many) ...;` or fix the spelling. Primitives are written `prim +`, `prim -`, `prim *`, `prim <`, `prim =`.")
  | "firth.name.unknown-primitive", _, _ =>
      (s!"`{at_}`{inWord} is not a primitive.",
        "The available primitives are `prim +`, `prim -`, `prim *`, `prim <` and `prim =`.")
  | "firth.linearity.usage-mismatch", _, _ =>
      (s!"`{at_}`{inWord} copies or drops a value that must be used exactly once.",
        "Linear values cannot be duplicated or dropped; pass them on instead.")
  | code, _, _ =>
      let detail := match diagnostic.expected, diagnostic.actual with
        | some wanted, some found => s!" Expected {renderStack wanted}, found {renderStack found}."
        | _, _ => ""
      (s!"`{at_}`{inWord} failed the check {code}; the stack before it is {before}.{detail}", "")

open Firth.Elaborator.StackEffect in
private def stackEffectParams (diagnostic : Firth.Elaborator.StackEffect.Diagnostic) : Json :=
  let (message, hint) := explain diagnostic
  let fields := [("message", Json.str message), ("state", .str (renderStack diagnostic.state))]
  let fields := match diagnostic.word with
    | some word => ("word", .str word) :: fields
    | none => fields
  let fields := match diagnostic.subject with
    | some subject => fields ++ [("at", .str subject)]
    | none => fields
  let fields := match diagnostic.expected with
    | some stack => fields ++ [("expected", .str (renderStack stack))]
    | none => fields
  let fields := match diagnostic.actual with
    | some stack => fields ++ [("actual", .str (renderStack stack))]
    | none => fields
  let fields := if hint.isEmpty then fields else fields ++ [("hint", .str hint)]
  .mkObj fields

def stackEffectEnvelope (context : EmissionContext)
    (diagnostic : Firth.Elaborator.StackEffect.Diagnostic) : Envelope :=
  let state := stackValue diagnostic.state
  envelope context {
    code := diagnostic.code
    severity := "error"
    messageKey := messageKey diagnostic.code
    messageParams := stackEffectParams diagnostic
    location := locationFromSpan context.source diagnostic.primary
    cause := {
      kind := causeForCode diagnostic.code
      data := .mkObj [("state", opaqueJson state)] }
    expectedStack := diagnostic.expected.map stackValue
    actualStack := diagnostic.actual.map stackValue }

def encodeStackEffectDiagnostic (context : EmissionContext)
    (diagnostic : Firth.Elaborator.StackEffect.Diagnostic) : String :=
  encode (stackEffectEnvelope context diagnostic)

private def refinementPairs (values : List (String × String)) : Json :=
  .mkObj (values.map fun (name, value) => (name, .str value))

private def refinementData
    (data : Firth.Elaborator.Refinement.OpaqueData) : Json :=
  .mkObj [
    ("encoding", .str data.encoding),
    ("value", refinementPairs data.value)]

private def refinementStack
    (stack : Firth.Elaborator.Refinement.OpaqueStack) : Opaque := {
  encoding := stack.encoding
  value := .mkObj [("lean_repr", .str s!"{repr stack.value}")] }

private def refinementStatus : Firth.Elaborator.Refinement.ObligationStatus → String
  | .deferred => "deferred"
  | .failed => "failed"

private def refinementLocation
    (location : Firth.Elaborator.Refinement.DiagnosticLocation) : Location :=
  locationFromSpan (.path location.path) location.range

private def refinementObligation
    (obligation : Firth.Elaborator.Refinement.DiagnosticObligation) : Obligation := {
  obligationId := obligation.obligationId
  kind := obligation.kind.canonical
  status := refinementStatus obligation.status
  data := refinementData obligation.data }

private def refinementEdit
    (edit : Firth.Elaborator.Refinement.DiagnosticEdit) : Edit := {
  location := refinementLocation edit.location
  replacement := edit.replacement }

private def refinementFix
    (fix : Firth.Elaborator.Refinement.ProposedFix) : ProposedFix := {
  fixId := fix.fixId
  kind := fix.kind
  titleKey := fix.titleKey
  applicability := fix.applicability
  edits := fix.edits.map refinementEdit }

private def refinementRelated
    (related : Firth.Elaborator.Refinement.RelatedDiagnostic) : Related := {
  relation := related.relation
  location := refinementLocation related.location
  payloadId := related.payloadId }

def refinementEnvelope
    (diagnostic : Firth.Elaborator.Refinement.RefinementDiagnostic) : Envelope :=
  .diagnostic diagnostic.payloadId diagnostic.requestId {
    code := diagnostic.body.code
    severity := diagnostic.body.severity
    messageKey := diagnostic.body.messageKey
    messageParams := refinementPairs diagnostic.body.messageParams
    location := refinementLocation diagnostic.body.location
    cause := {
      kind := diagnostic.body.cause.kind
      data := refinementData diagnostic.body.cause.data }
    expectedStack := some (refinementStack diagnostic.body.expectedStack)
    actualStack := some (refinementStack diagnostic.body.actualStack)
    obligations := diagnostic.body.obligations.map refinementObligation
    proposedFixes := diagnostic.body.proposedFixes.map refinementFix
    related := diagnostic.body.related.map refinementRelated
    groupId := some diagnostic.body.groupId }

def encodeRefinementDiagnostic
    (diagnostic : Firth.Elaborator.Refinement.RefinementDiagnostic) : String :=
  encode (refinementEnvelope diagnostic)

def typedHoleEnvelope (context : EmissionContext) (holeId : String)
    (hole : Firth.Elaborator.StackEffect.TypedHole) : Envelope :=
  .typedHole context.payloadId context.requestId {
    holeId
    location := locationFromSpan context.source hole.span
    inferredStackState := stackValue hole.state
    obligations := context.obligations }

def encodeTypedHole (context : EmissionContext) (holeId : String)
    (hole : Firth.Elaborator.StackEffect.TypedHole) : String :=
  encode (typedHoleEnvelope context holeId hole)

private def sourceKey : LocationSource → String
  | .uri uri | .uriAndPath uri _ => uri
  | .path path => path

private def positionBefore (left right : Position) : Bool :=
  left.line < right.line || (left.line == right.line && left.column < right.column)

private def rangeBefore (left right : SourceRange) : Bool :=
  if left.start == right.start then
    if left.stop == right.stop then false else positionBefore left.stop right.stop
  else positionBefore left.start right.start

private def diagnosticBefore (left right : Envelope) : Bool :=
  match left.body, right.body with
  | .diagnostic leftBody, .diagnostic rightBody =>
      let leftSource := sourceKey leftBody.location.source
      let rightSource := sourceKey rightBody.location.source
      if leftSource != rightSource then leftSource < rightSource
      else if leftBody.location.range != rightBody.location.range then
        rangeBefore leftBody.location.range rightBody.location.range
      else if leftBody.code != rightBody.code then leftBody.code < rightBody.code
      else left.payloadId < right.payloadId
  | .diagnostic _, _ => true
  | _, .diagnostic _ => false
  | _, _ => left.payloadId < right.payloadId

def sortDiagnosticEnvelopes (envelopes : List Envelope) : List Envelope :=
  envelopes.mergeSort diagnosticBefore

def refinementEnvelopes
    (result : Firth.Elaborator.Refinement.PipelineResult) : List Envelope :=
  sortDiagnosticEnvelopes (result.diagnostics.map refinementEnvelope)


inductive StructuredElaborationResult where
  | success (program : Firth.Elaborator.CheckedProgram)
  | failure (diagnostics : List Envelope)

private def sourcePath : LocationSource → String
  | .uri uri => uri
  | .path path => path
  | .uriAndPath uri path => if path.isEmpty then uri else path

private def internalEnvelope (context : EmissionContext) (span : Firth.Elaborator.Span) :
    Envelope :=
  envelope context {
    code := "firth.elaboration.internal"
    severity := "error"
    messageKey := messageKey "firth.elaboration.internal"
    messageParams := .mkObj []
    location := locationFromSpan context.source span
    cause := { kind := "elaboration" }
    expectedStack := none
    actualStack := none }

private def withContextSource (context : EmissionContext) (envelope : Envelope) :
    Envelope :=
  { envelope with
    body := match envelope.body with
    | .diagnostic diagnostic =>
        .diagnostic { diagnostic with
          location := { diagnostic.location with source := context.source } }
    | body => body }

private def pipelineDiagnosticEnvelope (context : EmissionContext) :
    Firth.Elaborator.PipelineDiagnostic → Envelope
  | .parse error => parserEnvelope context error
  | .erasure _ error => erasureEnvelope context error
  | .stackEffect diagnostic => stackEffectEnvelope context diagnostic
  | .refinement _ diagnostic => withContextSource context (refinementEnvelope diagnostic)
  | .internal span => internalEnvelope context span

def elaboratePipeline (context : EmissionContext) (source : String)
    (config : Firth.Elaborator.PipelineConfig := {}) : StructuredElaborationResult :=
  let config := { config with
    requestId := context.requestId
    sourcePath := sourcePath context.source }
  match Firth.Elaborator.elaborateWith config source with
  | .success program => .success program
  | .failure diagnostics =>
      .failure (sortDiagnosticEnvelopes
        (diagnostics.map (pipelineDiagnosticEnvelope context)))

end Firth.Agent
