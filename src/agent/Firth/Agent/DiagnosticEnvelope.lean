import Lean.Data.Json

namespace Firth.Agent

open Lean

structure Position where
  line : Nat
  column : Nat
  deriving Repr, BEq

structure SourceRange where
  start : Position
  stop : Position
  deriving Repr, BEq

inductive LocationSource where
  | uri (value : String)
  | path (value : String)
  | uriAndPath (uri path : String)
  deriving Repr, BEq

structure Location where
  source : LocationSource
  range : SourceRange
  deriving Repr, BEq

namespace Location

def uri (value : String) (range : SourceRange) : Location :=
  { source := .uri value, range }

def path (value : String) (range : SourceRange) : Location :=
  { source := .path value, range }

def uriAndPath (uri path : String) (range : SourceRange) : Location :=
  { source := .uriAndPath uri path, range }

end Location

structure Opaque where
  encoding : String
  value : Json
  displayHint : Option String := none

structure Cause where
  kind : String
  data : Json := .mkObj []

structure Obligation where
  obligationId : String
  kind : String
  status : String
  data : Json

structure Edit where
  location : Location
  replacement : String

structure ProposedFix where
  fixId : String
  kind : String
  titleKey : String
  applicability : String
  edits : List Edit

structure Related where
  relation : String
  location : Location
  payloadId : Option String := none

structure Diagnostic where
  code : String
  severity : String
  messageKey : String
  messageParams : Json
  location : Location
  cause : Cause
  expectedStack : Option Opaque
  actualStack : Option Opaque
  obligations : List Obligation := []
  proposedFixes : List ProposedFix := []
  related : List Related := []
  groupId : Option String := none

structure TypedHole where
  holeId : String
  location : Location
  inferredStackState : Opaque
  obligations : List Obligation := []
  expectedStack : Option Opaque := none
  actualStack : Option Opaque := none

structure SearchQuery where
  stackEffect : Opaque
  refinements : Option Opaque := none

structure SearchRequest where
  query : SearchQuery
  pageSize : Nat
  page : Nat
  cursor : Option String := none

structure SearchMatch where
  wordId : String
  signature : Opaque
  refinements : Option Opaque
  matchKind : String
  rank : Nat

structure SearchResponse where
  page : Nat
  pageSize : Nat
  nextCursor : Option String
  results : List SearchMatch

inductive Body where
  | diagnostic (value : Diagnostic)
  | typedHole (value : TypedHole)
  | signatureSearchRequest (value : SearchRequest)
  | signatureSearchResponse (value : SearchResponse)

structure Envelope where
  payloadId : String
  requestId : String
  body : Body
  producer : Option String := none
  capabilities : Option Json := none

namespace Envelope

def diagnostic (payloadId requestId : String) (body : Diagnostic) : Envelope :=
  { payloadId, requestId, body := .diagnostic body }

def typedHole (payloadId requestId : String) (body : TypedHole) : Envelope :=
  { payloadId, requestId, body := .typedHole body }

def signatureSearchRequest (payloadId requestId : String) (body : SearchRequest) : Envelope :=
  { payloadId, requestId, body := .signatureSearchRequest body }

def signatureSearchResponse (payloadId requestId : String) (body : SearchResponse) : Envelope :=
  { payloadId, requestId, body := .signatureSearchResponse body }

end Envelope

private def encodeString (value : String) : String := (Json.str value).compress

private def encodeField (name value : String) : String := encodeString name ++ ":" ++ value

private def encodeObject (fields : List (String × String)) : String :=
  "{" ++ String.intercalate "," (fields.map fun (name, value) => encodeField name value) ++ "}"

private def encodeArray (items : List String) : String :=
  "[" ++ String.intercalate "," items ++ "]"

private def encodePosition (position : Position) : String :=
  encodeObject [
    ("line", toString position.line),
    ("column", toString position.column)]

private def encodeRange (range : SourceRange) : String :=
  encodeObject [
    ("start", encodePosition range.start),
    ("end", encodePosition range.stop)]

private def encodeLocation (location : Location) : String :=
  let sourceFields := match location.source with
    | .uri uri => [("uri", encodeString uri)]
    | .path path => [("path", encodeString path)]
    | .uriAndPath uri path => [("uri", encodeString uri), ("path", encodeString path)]
  encodeObject (sourceFields ++ [("range", encodeRange location.range)])

private def encodeOpaque (value : Opaque) : String :=
  let fields := [
    ("encoding", encodeString value.encoding),
    ("value", value.value.compress)]
  let fields := match value.displayHint with
    | none => fields
    | some hint => fields ++ [("display_hint", encodeString hint)]
  encodeObject fields

private def encodeCause (cause : Cause) : String :=
  encodeObject [("kind", encodeString cause.kind), ("data", cause.data.compress)]

private def encodeObligation (obligation : Obligation) : String :=
  encodeObject [
    ("obligation_id", encodeString obligation.obligationId),
    ("kind", encodeString obligation.kind),
    ("status", encodeString obligation.status),
    ("data", obligation.data.compress)]

private def encodeEdit (edit : Edit) : String :=
  encodeObject [
    ("location", encodeLocation edit.location),
    ("replacement", encodeString edit.replacement)]

private def encodeFix (fix : ProposedFix) : String :=
  encodeObject [
    ("fix_id", encodeString fix.fixId),
    ("kind", encodeString fix.kind),
    ("title_key", encodeString fix.titleKey),
    ("applicability", encodeString fix.applicability),
    ("edits", encodeArray (fix.edits.map encodeEdit))]

private def encodeRelated (related : Related) : String :=
  let fields := [
    ("relation", encodeString related.relation),
    ("location", encodeLocation related.location)]
  let fields := match related.payloadId with
    | none => fields
    | some payloadId => fields ++ [("payload_id", encodeString payloadId)]
  encodeObject fields

private def byObligationId (left right : Obligation) : Bool :=
  left.obligationId < right.obligationId

private def byFixId (left right : ProposedFix) : Bool := left.fixId < right.fixId

private def encodeDiagnostic (diagnostic : Diagnostic) : String :=
  let obligations := diagnostic.obligations.mergeSort byObligationId
  let fixes := diagnostic.proposedFixes.mergeSort byFixId
  let fields := [
    ("code", encodeString diagnostic.code),
    ("severity", encodeString diagnostic.severity),
    ("message_key", encodeString diagnostic.messageKey),
    ("message_params", diagnostic.messageParams.compress),
    ("location", encodeLocation diagnostic.location),
    ("cause", encodeCause diagnostic.cause),
    ("expected_stack", diagnostic.expectedStack.map encodeOpaque |>.getD "null"),
    ("actual_stack", diagnostic.actualStack.map encodeOpaque |>.getD "null"),
    ("obligations", encodeArray (obligations.map encodeObligation)),
    ("proposed_fixes", encodeArray (fixes.map encodeFix))]
  let fields := if diagnostic.related.isEmpty then fields
    else fields ++ [("related", encodeArray (diagnostic.related.map encodeRelated))]
  let fields := match diagnostic.groupId with
    | none => fields
    | some groupId => fields ++ [("group_id", encodeString groupId)]
  encodeObject fields

private def encodeTypedHole (hole : TypedHole) : String :=
  let obligations := hole.obligations.mergeSort byObligationId
  let fields := [
    ("hole_id", encodeString hole.holeId),
    ("location", encodeLocation hole.location),
    ("inferred_stack_state", encodeOpaque hole.inferredStackState),
    ("obligations", encodeArray (obligations.map encodeObligation))]
  let fields := match hole.expectedStack with
    | none => fields
    | some stack => fields ++ [("expected_stack", encodeOpaque stack)]
  let fields := match hole.actualStack with
    | none => fields
    | some stack => fields ++ [("actual_stack", encodeOpaque stack)]
  encodeObject fields

private def encodeSearchQuery (query : SearchQuery) : String :=
  let fields := [("stack_effect", encodeOpaque query.stackEffect)]
  let fields := match query.refinements with
    | none => fields
    | some refinements => fields ++ [("refinements", encodeOpaque refinements)]
  encodeObject fields

private def encodeSearchRequest (request : SearchRequest) : String :=
  let fields := [
    ("query", encodeSearchQuery request.query),
    ("page_size", toString request.pageSize),
    ("page", toString request.page)]
  let fields := match request.cursor with
    | none => fields
    | some cursor => fields ++ [("cursor", encodeString cursor)]
  encodeObject fields

private def searchMatchBefore (left right : SearchMatch) : Bool :=
  left.rank < right.rank || (left.rank == right.rank && left.wordId < right.wordId)

private def encodeSearchMatch (result : SearchMatch) : String :=
  encodeObject [
    ("word_id", encodeString result.wordId),
    ("signature", encodeOpaque result.signature),
    ("refinements", result.refinements.map encodeOpaque |>.getD "null"),
    ("match_kind", encodeString result.matchKind),
    ("rank", toString result.rank)]

private def encodeSearchResponse (response : SearchResponse) : String :=
  let results := response.results.mergeSort searchMatchBefore
  encodeObject [
    ("page", toString response.page),
    ("page_size", toString response.pageSize),
    ("next_cursor", response.nextCursor.map encodeString |>.getD "null"),
    ("matches", encodeArray (results.map encodeSearchMatch))]

private def payloadKind : Body → String
  | .diagnostic _ => "diagnostic"
  | .typedHole _ => "typed_hole"
  | .signatureSearchRequest _ => "signature_search_request"
  | .signatureSearchResponse _ => "signature_search_response"

private def encodeBody : Body → String
  | .diagnostic value => encodeDiagnostic value
  | .typedHole value => encodeTypedHole value
  | .signatureSearchRequest value => encodeSearchRequest value
  | .signatureSearchResponse value => encodeSearchResponse value

def encode (envelope : Envelope) : String :=
  let fields := [
    ("schema_version", encodeString "1.0"),
    ("payload_kind", encodeString (payloadKind envelope.body)),
    ("payload_id", encodeString envelope.payloadId),
    ("request_id", encodeString envelope.requestId),
    ("body", encodeBody envelope.body)]
  let fields := match envelope.producer with
    | none => fields
    | some producer => fields ++ [("producer", encodeString producer)]
  let fields := match envelope.capabilities with
    | none => fields
    | some capabilities => fields ++ [("capabilities", capabilities.compress)]
  encodeObject fields

end Firth.Agent
