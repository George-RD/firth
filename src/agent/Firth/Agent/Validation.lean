import agent.Firth.Agent.DiagnosticEnvelope

namespace Firth.Agent

open Lean

structure ValidationError where
  code : String
  field : String
  deriving Repr, BEq

structure ValidatedEnvelope where
  source : String
  payloadKind : String
  payloadId : String
  requestId : String

private abbrev ValidateM := Except ValidationError

private def invalid (code field : String) : ValidateM α :=
  .error { code, field }

private def expectObject (field : String) : Json → ValidateM Unit
  | .obj _ => pure ()
  | _ => invalid "firth.protocol.invalid-body" field

private def required (object : Json) (field : String) : ValidateM Json :=
  match object.getObjVal? field with
  | .ok value => pure value
  | .error _ => invalid "firth.protocol.missing-field" field

private def optional (object : Json) (field : String) : Option Json :=
  match object with
  | .obj fields => fields.get? field
  | _ => none

private def asString (field : String) (value : Json) : ValidateM String :=
  match value.getStr? with
  | .ok text => pure text
  | .error _ => invalid "firth.protocol.invalid-body" field

private def requiredString (object : Json) (field : String) : ValidateM String := do
  asString field (← required object field)

private def nonemptyString (object : Json) (field : String) : ValidateM String := do
  let value ← requiredString object field
  if value.isEmpty then invalid "firth.protocol.invalid-body" field else pure value

private def asNat (field : String) (value : Json) : ValidateM Nat :=
  match value.getNat? with
  | .ok number => pure number
  | .error _ => invalid "firth.protocol.invalid-body" field

private def requiredNat (object : Json) (field : String) : ValidateM Nat := do
  asNat field (← required object field)

private def asArray (field : String) (value : Json) : ValidateM (Array Json) :=
  match value.getArr? with
  | .ok items => pure items
  | .error _ => invalid "firth.protocol.invalid-body" field

private def requiredArray (object : Json) (field : String) : ValidateM (Array Json) := do
  asArray field (← required object field)

private def validateOptionalString (object : Json) (field : String) : ValidateM Unit :=
  match optional object field with
  | none => pure ()
  | some value => do
      let text ← asString field value
      if text.isEmpty then invalid "firth.protocol.invalid-body" field else pure ()

private def validateVersion (version : String) : ValidateM Unit :=
  match version.splitOn "." with
  | [major, minor] =>
      if major == "1" && minor.toNat?.isSome then pure ()
      else invalid "firth.protocol.unsupported-version" "schema_version"
  | _ => invalid "firth.protocol.unsupported-version" "schema_version"

private def positionBeforeOrEqual (left right : Position) : Bool :=
  left.line < right.line || (left.line == right.line && left.column <= right.column)

private def validatePosition (field : String) (value : Json) : ValidateM Position := do
  expectObject field value
  let line ← requiredNat value "line"
  let column ← requiredNat value "column"
  if line == 0 || column == 0 then invalid "firth.protocol.invalid-location" field
  else pure { line, column }

private def validateLocation (value : Json) : ValidateM Unit := do
  expectObject "location" value
  let uri ← match optional value "uri" with
    | none => pure none
    | some raw => pure (some (← asString "uri" raw))
  let path ← match optional value "path" with
    | none => pure none
    | some raw => pure (some (← asString "path" raw))
  if uri.all (·.isEmpty) && path.all (·.isEmpty) then
    invalid "firth.protocol.invalid-location" "location"
  let range ← required value "range"
  expectObject "range" range
  let start ← validatePosition "range.start" (← required range "start")
  let stop ← validatePosition "range.end" (← required range "end")
  if positionBeforeOrEqual start stop then pure ()
  else invalid "firth.protocol.invalid-location" "range"

private def validateOpaque (field : String) (value : Json) : ValidateM Unit := do
  expectObject field value
  let encoding ← requiredString value "encoding"
  if encoding.isEmpty then invalid "firth.protocol.invalid-body" field
  let _ ← required value "value"
  validateOptionalString value "display_hint"

private def validateNullableOpaque (field : String) (value : Json) : ValidateM Unit :=
  if value.isNull then pure () else validateOpaque field value

private def validateCause (value : Json) : ValidateM Unit := do
  expectObject "cause" value
  let _ ← nonemptyString value "kind"
  match optional value "data" with
  | none => pure ()
  | some data => expectObject "cause.data" data

private def validateObligation (value : Json) : ValidateM Unit := do
  expectObject "obligation" value
  let _ ← nonemptyString value "obligation_id"
  let _ ← nonemptyString value "kind"
  let _ ← nonemptyString value "status"
  expectObject "obligation.data" (← required value "data")

private def validateObligations (object : Json) : ValidateM Unit := do
  let obligations ← requiredArray object "obligations"
  for obligation in obligations do
    validateObligation obligation

private def validateEdit (value : Json) : ValidateM Unit := do
  expectObject "edit" value
  validateLocation (← required value "location")
  let _ ← requiredString value "replacement"
  pure ()

private def validateFix (value : Json) : ValidateM Unit := do
  expectObject "proposed_fix" value
  let _ ← nonemptyString value "fix_id"
  let _ ← nonemptyString value "kind"
  let _ ← nonemptyString value "title_key"
  let _ ← nonemptyString value "applicability"
  let edits ← requiredArray value "edits"
  for edit in edits do
    validateEdit edit

private def validateFixes (object : Json) : ValidateM Unit :=
  match optional object "proposed_fixes" with
  | none => pure ()
  | some raw => do
      let fixes ← asArray "proposed_fixes" raw
      for fix in fixes do
        validateFix fix

private def validateRelatedEntry (value : Json) : ValidateM Unit := do
  expectObject "related" value
  let _ ← nonemptyString value "relation"
  validateLocation (← required value "location")
  validateOptionalString value "payload_id"

private def validateRelated (object : Json) : ValidateM Unit :=
  match optional object "related" with
  | none => pure ()
  | some raw => do
      let entries ← asArray "related" raw
      for entry in entries do
        validateRelatedEntry entry

private def validCodeAtom (value : String) : Bool :=
  match value.toList with
  | [] => false
  | first :: rest =>
      ('a' <= first && first <= 'z') &&
        rest.all fun character =>
          ('a' <= character && character <= 'z') ||
          ('0' <= character && character <= '9') || character == '-'

private def validateCode (code : String) : ValidateM Unit :=
  match code.splitOn "." with
  | ["firth", namespaceName, condition] =>
      let namespaces := ["type", "linearity", "refinement", "elaboration",
        "syntax", "name", "search", "protocol"]
      if namespaces.contains namespaceName && validCodeAtom condition then pure ()
      else invalid "firth.protocol.invalid-code" "body.code"
  | _ => invalid "firth.protocol.invalid-code" "body.code"

private def validateDiagnostic (body : Json) : ValidateM Unit := do
  expectObject "body" body
  validateCode (← requiredString body "code")
  let _ ← nonemptyString body "severity"
  let _ ← nonemptyString body "message_key"
  expectObject "message_params" (← required body "message_params")
  validateLocation (← required body "location")
  validateCause (← required body "cause")
  validateNullableOpaque "expected_stack" (← required body "expected_stack")
  validateNullableOpaque "actual_stack" (← required body "actual_stack")
  validateObligations body
  validateFixes body
  validateRelated body
  validateOptionalString body "group_id"

private def validateTypedHole (body : Json) : ValidateM Unit := do
  expectObject "body" body
  let _ ← nonemptyString body "hole_id"
  validateLocation (← required body "location")
  validateOpaque "inferred_stack_state" (← required body "inferred_stack_state")
  validateObligations body
  match optional body "expected_stack" with
  | none => pure ()
  | some value => validateNullableOpaque "expected_stack" value
  match optional body "actual_stack" with
  | none => pure ()
  | some value => validateNullableOpaque "actual_stack" value

private def validatePagination (body : Json) : ValidateM Unit := do
  let pageSize ← requiredNat body "page_size"
  let _ ← requiredNat body "page"
  if pageSize > 0 && pageSize <= 1000 then pure ()
  else invalid "firth.protocol.invalid-pagination" "page_size"

private def validateSearchRequest (body : Json) : ValidateM Unit := do
  expectObject "body" body
  let query ← required body "query"
  expectObject "query" query
  validateOpaque "stack_effect" (← required query "stack_effect")
  match optional query "refinements" with
  | none => pure ()
  | some value => validateOpaque "refinements" value
  validatePagination body
  validateOptionalString body "cursor"

private structure MatchKey where
  rank : Nat
  wordId : String

private def matchKeyBefore (left right : MatchKey) : Bool :=
  left.rank < right.rank || (left.rank == right.rank && left.wordId < right.wordId)

private def validateSearchMatch (value : Json) : ValidateM MatchKey := do
  expectObject "match" value
  let wordId ← nonemptyString value "word_id"
  validateOpaque "signature" (← required value "signature")
  match optional value "refinements" with
  | none => pure ()
  | some refinements => validateNullableOpaque "refinements" refinements
  let _ ← nonemptyString value "match_kind"
  let rank ← requiredNat value "rank"
  pure { rank, wordId }

private def validateMatchOrder : List MatchKey → ValidateM Unit
  | [] | [_] => pure ()
  | first :: second :: rest =>
      if matchKeyBefore first second then validateMatchOrder (second :: rest)
      else invalid "firth.protocol.invalid-order" "matches"

private def validateSearchResponse (body : Json) : ValidateM Unit := do
  expectObject "body" body
  validatePagination body
  match optional body "next_cursor" with
  | none => pure ()
  | some cursor => if cursor.isNull then pure () else validateOptionalString body "next_cursor"
  let rawMatches ← requiredArray body "matches"
  let mut keys := []
  for result in rawMatches do
    keys := keys ++ [← validateSearchMatch result]
  validateMatchOrder keys

private def validateBody (kind : String) (body : Json) : ValidateM Unit :=
  match kind with
  | "diagnostic" => validateDiagnostic body
  | "typed_hole" => validateTypedHole body
  | "signature_search_request" => validateSearchRequest body
  | "signature_search_response" => validateSearchResponse body
  | _ => invalid "firth.protocol.unknown-payload-kind" "payload_kind"

def validate (source : String) : ValidateM ValidatedEnvelope := do
  let json ← match Json.parse source with
    | .ok value => pure value
    | .error _ => invalid "firth.protocol.malformed-json" "envelope"
  expectObject "envelope" json
  let version ← requiredString json "schema_version"
  validateVersion version
  let payloadKind ← requiredString json "payload_kind"
  let payloadId ← requiredString json "payload_id"
  let requestId ← requiredString json "request_id"
  if payloadId.isEmpty || requestId.isEmpty then
    invalid "firth.protocol.invalid-id" "payload_id"
  validateBody payloadKind (← required json "body")
  pure { source, payloadKind, payloadId, requestId }

def forward (envelope : ValidatedEnvelope) : String := envelope.source

private def validateUnique (seen : List (String × String))
    (envelopes : List ValidatedEnvelope) : ValidateM Unit :=
  match envelopes with
  | [] => pure ()
  | envelope :: rest =>
      let key := (envelope.requestId, envelope.payloadId)
      if seen.contains key then invalid "firth.protocol.duplicate-id" "payload_id"
      else validateUnique (key :: seen) rest

def validateBatch (sources : List String) : ValidateM (List ValidatedEnvelope) := do
  let envelopes ← sources.mapM validate
  validateUnique [] envelopes
  pure envelopes

end Firth.Agent
