import FirthReferenceRun

namespace Firth.ReferenceRunTest

open Firth.ReferenceRun

private def fail (message : String) : IO Unit := throw <| IO.userError message

private def expectContains (name input needle : String) : IO Unit := do
  match runRequest input with
  | .ok output =>
      if output.contains needle then pure ()
      else fail s!"{name}: missing {needle}\n{output}"
  | .error error => fail s!"{name}: unexpected error {error}"

private def expectError (name input : String) : IO Unit := do
  match runRequest input with
  | .ok output => fail s!"{name}: accepted invalid request\n{output}"
  | .error _ => pure ()

private def request (program stack : String) (fuel : Nat := 8) : String :=
  "{\"request_id\":\"request-1\",\"checked_kernel\":{\"checking_state\":\"checked\",\"proof_state\":\"available\",\"gamma_version\":\"0.5\",\"program\":"
    ++ program ++ "},\"initial_stack\":" ++ stack ++ ",\"dictionary\":{},\"gamma_version\":\"0.5\",\"fuel\":"
    ++ toString fuel ++ "}"

private def validRequest (program : String) (fuel : Nat := 8) : String :=
  request program "[]" fuel

def main : IO Unit := do
  expectContains "literal execution" (validRequest "[{\"kind\":\"lit\",\"value\":{\"type\":\"int\",\"value\":7}}]")
    "\"status\":\"success\""
  expectContains "literal stack" (validRequest "[{\"kind\":\"lit\",\"value\":{\"type\":\"int\",\"value\":7}}]")
    "\"value\":7"
  expectContains "quotation execution"
    (validRequest "[{\"kind\":\"quotation\",\"body\":[{\"kind\":\"lit\",\"value\":{\"type\":\"int\",\"value\":9}}]},{\"kind\":\"call\"}]")
    "\"steps\":3"
  expectError "unknown word rejected"
    (validRequest "[{\"kind\":\"word\",\"name\":\"missing\"}]")
  expectError "unknown primitive rejected"
    (validRequest "[{\"kind\":\"prim\",\"name\":\"missing\"}]")
  expectError "invalid initial stack quotation rejected"
    (request "[]" "[{\"kind\":\"quotation\",\"body\":[{\"kind\":\"word\",\"name\":\"missing\"}]}]")
  expectContains "declared plus primitive executes"
    (request "[{\"kind\":\"prim\",\"name\":\"+\"}]"
      "[{\"kind\":\"literal\",\"literal\":{\"type\":\"int\",\"value\":2}},{\"kind\":\"literal\",\"literal\":{\"type\":\"int\",\"value\":3}}]")
    "\"value\":5"
  expectContains "subtraction goes below zero"
    (request "[{\"kind\":\"prim\",\"name\":\"-\"}]"
      "[{\"kind\":\"literal\",\"literal\":{\"type\":\"int\",\"value\":3}},{\"kind\":\"literal\",\"literal\":{\"type\":\"int\",\"value\":5}}]")
    "\"value\":-2"
  expectContains "negative literal executes"
    (validRequest "[{\"kind\":\"lit\",\"value\":{\"type\":\"int\",\"value\":-7}}]")
    "\"value\":-7"
  expectError "the old nat literal type is refused"
    (validRequest "[{\"kind\":\"lit\",\"value\":{\"type\":\"nat\",\"value\":7}}]")
  expectError "internal primitive name rejected"
    (validRequest "[{\"kind\":\"prim\",\"name\":\"addInt\"}]")
  expectContains "bottom-to-top initial stack"
    (request "[{\"kind\":\"drop\"}]"
      "[{\"kind\":\"literal\",\"literal\":{\"type\":\"int\",\"value\":1}},{\"kind\":\"literal\",\"literal\":{\"type\":\"int\",\"value\":2}}]")
    "\"value\":1"
  expectError "tag-inapplicable field rejected"
    (validRequest "[{\"kind\":\"dup\",\"name\":\"unexpected\"}]")
  expectContains "fuel trap"
    (validRequest "[{\"kind\":\"lit\",\"value\":{\"type\":\"int\",\"value\":7}}]" 0)
    "\"trap\":\"fuel-exhausted\""
  expectError "malformed JSON" "{"
  expectError "unchecked kernel"
    "{\"request_id\":\"request-1\",\"checked_kernel\":{\"checking_state\":\"unchecked\",\"proof_state\":\"available\",\"gamma_version\":\"0.5\",\"program\":[]},\"initial_stack\":[],\"dictionary\":{},\"gamma_version\":\"0.5\",\"fuel\":1}"
  expectError "unsupported Gamma"
    "{\"request_id\":\"request-1\",\"checked_kernel\":{\"checking_state\":\"checked\",\"proof_state\":\"available\",\"gamma_version\":\"0.6\",\"program\":[]},\"initial_stack\":[],\"dictionary\":{},\"gamma_version\":\"0.6\",\"fuel\":1}"

end Firth.ReferenceRunTest

def main (_args : List String) : IO Unit := Firth.ReferenceRunTest.main
