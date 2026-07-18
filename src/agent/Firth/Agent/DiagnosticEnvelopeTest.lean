import agent.Firth.Agent.Validation

namespace Firth.Agent.Test

open Firth.Agent

def fail (message : String) : IO α := throw <| IO.userError message

def expectEqual [BEq α] [Repr α] (name : String) (actual expected : α) : IO Unit :=
  if actual == expected then pure ()
  else fail s!"{name}\nactual: {repr actual}\nexpected: {repr expected}"

private def opaqueValue : Opaque := { encoding := "opaque", value := .mkObj [] }

private def location (line start stop : Nat) : Location :=
  .path "main.fth" {
    start := { line, column := start }
    stop := { line, column := stop } }

def runEnvelopeTests : IO Unit := do
  let diagnostic := Envelope.diagnostic "d1" "r1" {
    code := "firth.type.stack-mismatch"
    severity := "error"
    messageKey := "diagnostic.stack_mismatch"
    messageParams := .mkObj []
    location := location 2 1 4
    cause := { kind := "type-checking", data := .mkObj [] }
    expectedStack := some opaqueValue
    actualStack := some opaqueValue }
  expectEqual "normative diagnostic bytes" (encode diagnostic)
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"diagnostic\",\"payload_id\":\"d1\",\"request_id\":\"r1\",\"body\":{\"code\":\"firth.type.stack-mismatch\",\"severity\":\"error\",\"message_key\":\"diagnostic.stack_mismatch\",\"message_params\":{},\"location\":{\"path\":\"main.fth\",\"range\":{\"start\":{\"line\":2,\"column\":1},\"end\":{\"line\":2,\"column\":4}}},\"cause\":{\"kind\":\"type-checking\",\"data\":{}},\"expected_stack\":{\"encoding\":\"opaque\",\"value\":{}},\"actual_stack\":{\"encoding\":\"opaque\",\"value\":{}},\"obligations\":[],\"proposed_fixes\":[]}}"

  let linearity := Envelope.diagnostic "d2" "r1" {
    code := "firth.linearity.unconsumed-resource"
    severity := "error"
    messageKey := "diagnostic.unconsumed_resource"
    messageParams := .mkObj []
    location := location 3 1 5
    cause := { kind := "linearity", data := .mkObj [] }
    expectedStack := none
    actualStack := none }
  expectEqual "normative linearity diagnostic bytes" (encode linearity)
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"diagnostic\",\"payload_id\":\"d2\",\"request_id\":\"r1\",\"body\":{\"code\":\"firth.linearity.unconsumed-resource\",\"severity\":\"error\",\"message_key\":\"diagnostic.unconsumed_resource\",\"message_params\":{},\"location\":{\"path\":\"main.fth\",\"range\":{\"start\":{\"line\":3,\"column\":1},\"end\":{\"line\":3,\"column\":5}}},\"cause\":{\"kind\":\"linearity\",\"data\":{}},\"expected_stack\":null,\"actual_stack\":null,\"obligations\":[],\"proposed_fixes\":[]}}"

  let hole := Envelope.typedHole "h1" "r2" {
    holeId := "h-1"
    location := location 4 1 2
    inferredStackState := opaqueValue }
  expectEqual "normative typed-hole bytes" (encode hole)
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"typed_hole\",\"payload_id\":\"h1\",\"request_id\":\"r2\",\"body\":{\"hole_id\":\"h-1\",\"location\":{\"path\":\"main.fth\",\"range\":{\"start\":{\"line\":4,\"column\":1},\"end\":{\"line\":4,\"column\":2}}},\"inferred_stack_state\":{\"encoding\":\"opaque\",\"value\":{}},\"obligations\":[]}}"

  let request := Envelope.signatureSearchRequest "search-req-01" "req-02" {
    query := { stackEffect := opaqueValue, refinements := some opaqueValue }
    pageSize := 20
    page := 0 }
  expectEqual "normative search-request bytes" (encode request)
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"signature_search_request\",\"payload_id\":\"search-req-01\",\"request_id\":\"req-02\",\"body\":{\"query\":{\"stack_effect\":{\"encoding\":\"opaque\",\"value\":{}},\"refinements\":{\"encoding\":\"opaque\",\"value\":{}}},\"page_size\":20,\"page\":0}}"

  let response := Envelope.signatureSearchResponse "s1" "r3" {
    page := 0
    pageSize := 10
    nextCursor := none
    results := [{
      wordId := "math.add"
      signature := opaqueValue
      refinements := none
      matchKind := "exact"
      rank := 0 }] }
  expectEqual "normative search-response bytes" (encode response)
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"signature_search_response\",\"payload_id\":\"s1\",\"request_id\":\"r3\",\"body\":{\"page\":0,\"page_size\":10,\"next_cursor\":null,\"matches\":[{\"word_id\":\"math.add\",\"signature\":{\"encoding\":\"opaque\",\"value\":{}},\"refinements\":null,\"match_kind\":\"exact\",\"rank\":0}]}}"

  for (name, value) in [
      ("diagnostic round trip", diagnostic),
      ("typed-hole round trip", hole),
      ("search-request round trip", request),
      ("search-response round trip", response)] do
    let source := encode value
    match validate source with
    | .error error => fail s!"{name}: encoded envelope failed validation: {error.code}"
    | .ok validated => expectEqual name (forward validated) source

  let sorted := Envelope.signatureSearchResponse "s2" "r3" {
    page := 0
    pageSize := 10
    nextCursor := none
    results := [
      { wordId := "z", signature := opaqueValue, refinements := none, matchKind := "exact", rank := 2 },
      { wordId := "b", signature := opaqueValue, refinements := none, matchKind := "exact", rank := 1 },
      { wordId := "a", signature := opaqueValue, refinements := none, matchKind := "exact", rank := 1 }] }
  let encoded := encode sorted
  let a := encoded.splitOn "\"word_id\":\"a\"" |>.head!.length
  let b := encoded.splitOn "\"word_id\":\"b\"" |>.head!.length
  let z := encoded.splitOn "\"word_id\":\"z\"" |>.head!.length
  if a < b && b < z then pure () else fail "search matches were not sorted by rank and word_id"

end Firth.Agent.Test
