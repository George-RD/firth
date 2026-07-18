import agent.Firth.Agent.Validation
import agent.Firth.Agent.DiagnosticEnvelopeTest

namespace Firth.Agent.Test

open Firth.Agent

private def expectInvalid (name code source : String) : IO Unit :=
  match validate source with
  | .ok _ => fail s!"{name}: malformed envelope was accepted"
  | .error error => expectEqual name error.code code

def runValidationTests : IO Unit := do
  let future := "{\"schema_version\":\"1.7\",\"payload_kind\":\"typed_hole\",\"payload_id\":\"h1\",\"request_id\":\"r1\",\"body\":{\"hole_id\":\"h-1\",\"location\":{\"path\":\"main.fth\",\"range\":{\"start\":{\"line\":1,\"column\":1},\"end\":{\"line\":1,\"column\":2}}},\"inferred_stack_state\":{\"encoding\":\"future\",\"value\":{},\"future_stack_field\":true},\"obligations\":[],\"future_body_field\":{\"x\":1}},\"future_envelope_field\":[1,2]}"
  match validate future with
  | .error error => fail s!"forward-compatible envelope failed: {error.code}"
  | .ok envelope => expectEqual "unknown optional fields survive forwarding" (forward envelope) future

  let unknownEnums := "{\"schema_version\":\"1.0\",\"payload_kind\":\"diagnostic\",\"payload_id\":\"d1\",\"request_id\":\"r1\",\"body\":{\"code\":\"firth.type.future-condition\",\"severity\":\"future-severity\",\"message_key\":\"diagnostic.future\",\"message_params\":{},\"location\":{\"path\":\"main.fth\",\"range\":{\"start\":{\"line\":1,\"column\":1},\"end\":{\"line\":1,\"column\":2}}},\"cause\":{\"kind\":\"future-cause\",\"data\":{}},\"expected_stack\":null,\"actual_stack\":null,\"obligations\":[{\"obligation_id\":\"o1\",\"kind\":\"future\",\"status\":\"future-status\",\"data\":{}}],\"proposed_fixes\":[{\"fix_id\":\"f1\",\"kind\":\"future\",\"title_key\":\"fix.future\",\"applicability\":\"future-applicability\",\"edits\":[]}]}}"
  match validate unknownEnums with
  | .ok _ => pure ()
  | .error error => fail s!"extensible enum failed: {error.code}"

  expectInvalid "malformed JSON" "firth.protocol.malformed-json" "{"
  expectInvalid "duplicate envelope member" "firth.protocol.duplicate-member"
    "{\"schema_version\":\"2.0\",\"schema_version\":\"1.0\",\"payload_kind\":\"typed_hole\",\"payload_id\":\"h1\",\"request_id\":\"r1\",\"body\":{\"hole_id\":\"h\",\"location\":{\"path\":\"x\",\"range\":{\"start\":{\"line\":1,\"column\":1},\"end\":{\"line\":1,\"column\":2}}},\"inferred_stack_state\":{\"encoding\":\"opaque\",\"value\":{}},\"obligations\":[]}}"
  expectInvalid "duplicate nested member" "firth.protocol.duplicate-member"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"signature_search_request\",\"payload_id\":\"s1\",\"request_id\":\"r1\",\"body\":{\"query\":{\"stack_effect\":{\"encoding\":\"opaque\",\"value\":{},\"value\":[]}},\"page_size\":10,\"page\":0}}"
  expectInvalid "escaped duplicate member" "firth.protocol.duplicate-member"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"signature_search_request\",\"payload_id\":\"s1\",\"request_id\":\"r1\",\"body\":{\"query\":{\"stack_effect\":{\"encoding\":\"opaque\",\"value\":{},\"\\u0076alue\":[]}},\"page_size\":10,\"page\":0}}"
  expectInvalid "missing body" "firth.protocol.missing-field"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"typed_hole\",\"payload_id\":\"h1\",\"request_id\":\"r1\"}"
  expectInvalid "unsupported major" "firth.protocol.unsupported-version"
    "{\"schema_version\":\"2.0\",\"payload_kind\":\"typed_hole\",\"payload_id\":\"h1\",\"request_id\":\"r1\",\"body\":{}}"
  expectInvalid "malformed version" "firth.protocol.unsupported-version"
    "{\"schema_version\":\"1\",\"payload_kind\":\"typed_hole\",\"payload_id\":\"h1\",\"request_id\":\"r1\",\"body\":{}}"
  expectInvalid "empty ID" "firth.protocol.invalid-id"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"typed_hole\",\"payload_id\":\"\",\"request_id\":\"r1\",\"body\":{}}"
  expectInvalid "unknown payload kind" "firth.protocol.unknown-payload-kind"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"future\",\"payload_id\":\"p1\",\"request_id\":\"r1\",\"body\":{}}"
  expectInvalid "invalid code namespace" "firth.protocol.invalid-code"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"diagnostic\",\"payload_id\":\"d1\",\"request_id\":\"r1\",\"body\":{\"code\":\"firth.unknown.failure\",\"severity\":\"error\",\"message_key\":\"x\",\"message_params\":{},\"location\":{\"path\":\"x\",\"range\":{\"start\":{\"line\":1,\"column\":1},\"end\":{\"line\":1,\"column\":2}}},\"cause\":{\"kind\":\"x\",\"data\":{}},\"expected_stack\":null,\"actual_stack\":null,\"obligations\":[]}}"
  expectInvalid "zero location" "firth.protocol.invalid-location"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"typed_hole\",\"payload_id\":\"h1\",\"request_id\":\"r1\",\"body\":{\"hole_id\":\"h\",\"location\":{\"path\":\"x\",\"range\":{\"start\":{\"line\":0,\"column\":1},\"end\":{\"line\":1,\"column\":2}}},\"inferred_stack_state\":{\"encoding\":\"opaque\",\"value\":{}},\"obligations\":[]}}"
  expectInvalid "reversed location" "firth.protocol.invalid-location"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"typed_hole\",\"payload_id\":\"h1\",\"request_id\":\"r1\",\"body\":{\"hole_id\":\"h\",\"location\":{\"path\":\"x\",\"range\":{\"start\":{\"line\":2,\"column\":2},\"end\":{\"line\":2,\"column\":1}}},\"inferred_stack_state\":{\"encoding\":\"opaque\",\"value\":{}},\"obligations\":[]}}"
  expectInvalid "page size zero" "firth.protocol.invalid-pagination"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"signature_search_request\",\"payload_id\":\"s1\",\"request_id\":\"r1\",\"body\":{\"query\":{\"stack_effect\":{\"encoding\":\"opaque\",\"value\":{}}},\"page_size\":0,\"page\":0}}"
  expectInvalid "page size too large" "firth.protocol.invalid-pagination"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"signature_search_request\",\"payload_id\":\"s1\",\"request_id\":\"r1\",\"body\":{\"query\":{\"stack_effect\":{\"encoding\":\"opaque\",\"value\":{}}},\"page_size\":1001,\"page\":0}}"
  let maximumPage := "{\"schema_version\":\"1.0\",\"payload_kind\":\"signature_search_request\",\"payload_id\":\"s-max\",\"request_id\":\"r1\",\"body\":{\"query\":{\"stack_effect\":{\"encoding\":\"opaque\",\"value\":{}}},\"page_size\":1000,\"page\":0}}"
  match validate maximumPage with
  | .ok _ => pure ()
  | .error error => fail s!"maximum valid page size failed: {error.code}"
  expectInvalid "unsorted matches" "firth.protocol.invalid-order"
    "{\"schema_version\":\"1.0\",\"payload_kind\":\"signature_search_response\",\"payload_id\":\"s1\",\"request_id\":\"r1\",\"body\":{\"page\":0,\"page_size\":10,\"matches\":[{\"word_id\":\"z\",\"signature\":{\"encoding\":\"opaque\",\"value\":{}},\"refinements\":null,\"match_kind\":\"exact\",\"rank\":2},{\"word_id\":\"a\",\"signature\":{\"encoding\":\"opaque\",\"value\":{}},\"refinements\":null,\"match_kind\":\"exact\",\"rank\":1}]}}"

  let duplicate := "{\"schema_version\":\"1.0\",\"payload_kind\":\"signature_search_request\",\"payload_id\":\"s1\",\"request_id\":\"r1\",\"body\":{\"query\":{\"stack_effect\":{\"encoding\":\"opaque\",\"value\":{}}},\"page_size\":10,\"page\":0}}"
  match validateBatch [duplicate, duplicate] with
  | .ok _ => fail "duplicate payload ID was accepted within one request"
  | .error error => expectEqual "duplicate payload ID" error.code "firth.protocol.duplicate-id"

end Firth.Agent.Test
