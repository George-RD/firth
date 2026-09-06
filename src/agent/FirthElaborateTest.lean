import agent.Firth.Agent.ElaborateAdapter

namespace Firth.ElaborateTest

open Firth.Agent.Elaborate

private def fail (message : String) : IO Unit := throw <| IO.userError message

private def expectContains (name input needle : String) : IO Unit := do
  match runRequest input with
  | .ok output =>
      if output.contains needle then pure ()
      else fail s!"{name}: missing {needle}\n{output}"
  | .error error => fail s!"{name}: unexpected error {error}"

private def expectMissing (name input needle : String) : IO Unit := do
  match runRequest input with
  | .ok output =>
      if output.contains needle then fail s!"{name}: unexpected {needle}\n{output}" else pure ()
  | .error error => fail s!"{name}: unexpected error {error}"

private def expectError (name input : String) : IO Unit := do
  match runRequest input with
  | .ok output => fail s!"{name}: accepted an invalid request\n{output}"
  | .error _ => pure ()

/-- Builds a request around a source. The source is embedded as a JSON string
so a test can hold a real multi-line definition. -/
private def request (source : String) : String :=
  "{\"request_id\":\"r1\",\"source_path\":\"test.firth\",\"source_text\":"
    ++ (Lean.Json.str source).compress
    ++ ",\"language_version\":\"0.1\",\"gamma_version\":\"0.1\"}"

private def literalInt : String :=
  ": literal-int\n  ( -- result:Int^many )\n  42;\n"

private def increment : String :=
  ": increment\n  (forall ρ; ρ n:Int^many -- ρ result:Int^many)\n  1 prim +;\n"

private def sendOnce : String :=
  ": send-once\n  (forall ρ; ρ w:World^linear h:Handle^linear b:Bytes^linear\n"
    ++ "    -- ρ w2:World^linear)\n  locals { h b } { h b prim send };\n"

def main : IO Unit := do
  expectContains "a checked source elaborates" (request literalInt) "\"status\":\"success\""
  -- The checked-word entries must be usable verbatim as the compile and
  -- reference-run adapters' request members, evidence markers included.
  expectContains "checked words carry their evidence markers" (request literalInt)
    "\"checking_state\":\"checked\",\"proof_state\":\"available\""
  expectContains "checked words carry the kernel program" (request literalInt)
    "\"program\":[{\"kind\":\"lit\",\"value\":{\"type\":\"nat\",\"value\":42}}]"
  expectContains "erased word types are structured, not rendered" (request literalInt)
    "\"type\":{\"row_variables\":[],\"input\":{\"row\":null,\"items\":[]}"
  expectContains "the erased output stack is bottom-to-top" (request literalInt)
    "\"output\":{\"row\":null,\"items\":[{\"kind\":\"base\",\"name\":\"Int\",\"usage\":\"many\"}]}"
  expectContains "kernel programs are indexed by word" (request literalInt)
    "\"kernel_programs\":[{\"word\":\"literal-int\","
  expectContains "a clean source has no warnings" (request literalInt) "\"warnings\":[]"

  -- The manifest's Gamma primitives resolve. Without them `prim +` fails with
  -- an unresolved effect, which is what the CLI did before this adapter.
  expectContains "the plus primitive resolves" (request increment) "\"status\":\"success\""
  expectContains "a row-polymorphic word keeps its binder" (request increment)
    "\"row_variables\":[\"ρ\"]"
  expectContains "the world-threading primitive resolves" (request sendOnce)
    "\"status\":\"success\""
  expectContains "a linear item keeps its usage" (request sendOnce) "\"usage\":\"linear\""

  -- Failure is structured diagnostics, never a Lean representation.
  expectContains "a type error is reported as a diagnostic"
    (request ": bad\n  ( -- result:Int^many )\n  drop;\n") "\"status\":\"failure\""
  expectContains "a diagnostic is a versioned envelope"
    (request ": bad\n  ( -- result:Int^many )\n  drop;\n") "\"schema_version\":\"1.0\""
  expectContains "a diagnostic carries its request id"
    (request ": bad\n  ( -- result:Int^many )\n  drop;\n") "\"request_id\":\"r1\""
  expectMissing "a failure carries no checked words"
    (request ": bad\n  ( -- result:Int^many )\n  drop;\n") "\"checked_words\""
  expectContains "an unknown primitive is a diagnostic, not an acceptance"
    (request ": bad\n  ( -- result:Int^many )\n  prim nope;\n") "\"status\":\"failure\""
  expectContains "a parse error is a diagnostic" (request ": unterminated\n") "\"status\":\"failure\""

  -- Malformed and stale requests fail closed before elaboration.
  expectError "malformed JSON" "{"
  expectError "duplicate JSON member"
    "{\"request_id\":\"a\",\"request_id\":\"b\",\"source_path\":\"t\",\"source_text\":\"\",\
      \"language_version\":\"0.1\",\"gamma_version\":\"0.1\"}"
  expectError "unknown member"
    "{\"request_id\":\"a\",\"source_path\":\"t\",\"source_text\":\"\",\"extra\":1,\
      \"language_version\":\"0.1\",\"gamma_version\":\"0.1\"}"
  expectError "missing member"
    "{\"request_id\":\"a\",\"source_path\":\"t\",\"language_version\":\"0.1\",\
      \"gamma_version\":\"0.1\"}"
  expectError "empty request id"
    "{\"request_id\":\"\",\"source_path\":\"t\",\"source_text\":\"\",\
      \"language_version\":\"0.1\",\"gamma_version\":\"0.1\"}"
  expectError "empty source path"
    "{\"request_id\":\"a\",\"source_path\":\"\",\"source_text\":\"\",\
      \"language_version\":\"0.1\",\"gamma_version\":\"0.1\"}"
  expectError "unsupported language version"
    "{\"request_id\":\"a\",\"source_path\":\"t\",\"source_text\":\"\",\
      \"language_version\":\"0.2\",\"gamma_version\":\"0.1\"}"
  expectError "unsupported gamma version"
    "{\"request_id\":\"a\",\"source_path\":\"t\",\"source_text\":\"\",\
      \"language_version\":\"0.1\",\"gamma_version\":\"0.2\"}"

end Firth.ElaborateTest

def main : IO Unit := Firth.ElaborateTest.main
