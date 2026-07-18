import agent.Firth.Agent.DiagnosticEnvelope
import elaborator.Firth.Parser
import elaborator.Firth.Erasure
import elaborator.Firth.StackEffect

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
  value := .mkObj [("lean_repr", .str s!"{repr stack}")] }

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

def parserEnvelope (context : EmissionContext)
    (error : Firth.Elaborator.ParseError) : Envelope :=
  envelope context {
    code := error.code
    severity := "error"
    messageKey := messageKey error.code
    messageParams := .mkObj []
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

def erasureEnvelope (context : EmissionContext)
    (error : Firth.Elaborator.ErasureError) : Envelope :=
  let diagnostic := erasureDiagnostic error
  envelope context {
    code := diagnostic.code
    severity := "error"
    messageKey := messageKey diagnostic.code
    messageParams := diagnostic.params
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

def stackEffectEnvelope (context : EmissionContext)
    (diagnostic : Firth.Elaborator.StackEffect.Diagnostic) : Envelope :=
  let state := stackValue diagnostic.state
  envelope context {
    code := diagnostic.code
    severity := "error"
    messageKey := messageKey diagnostic.code
    messageParams := .mkObj []
    location := locationFromSpan context.source diagnostic.primary
    cause := {
      kind := causeForCode diagnostic.code
      data := .mkObj [("state", opaqueJson state)] }
    expectedStack := diagnostic.expected.map stackValue
    actualStack := diagnostic.actual.map stackValue }

def encodeStackEffectDiagnostic (context : EmissionContext)
    (diagnostic : Firth.Elaborator.StackEffect.Diagnostic) : String :=
  encode (stackEffectEnvelope context diagnostic)

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

end Firth.Agent
