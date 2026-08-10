import Firth.Interpreter
import agent.Firth.Agent.JsonMembers
import Lean.Data.Json

namespace Firth.ReferenceRun
open Lean
open Firth.Interpreter

private def err (s : String) : Except String α := .error s
private def field (name : String) : List (String × Json) → Option Json
  | [] => none
  | (key, value) :: rest => if key == name then some value else field name rest
private def fields (context : String) : Json → Except String (List (String × Json))
  | .obj values =>
      let values := values.toList
      let rec unique : List (String × Json) → Bool
        | [] => true
        | (key, _) :: rest => !rest.any (fun (other, _) => key == other) && unique rest
      if unique values then pure values else err s!"{context}: duplicate field"
  | _ => err s!"{context}: expected object"
private def object (context : String) (value : Json) (allowed required : List String) :
    Except String (List (String × Json)) := do
  let values ← fields context value
  if values.any (fun (key, _) => !allowed.any (· == key)) then err s!"{context}: unknown field"
  else if required.any (fun key => (field key values).isNone) then err s!"{context}: missing field"
  else pure values
private def exactMembers (context : String) (values : List (String × Json))
    (allowed required : List String) : Except String Unit :=
  if values.any (fun (key, _) => !allowed.any (· == key)) then err s!"{context}: unknown field"
  else if required.any (fun key => (field key values).isNone) then err s!"{context}: missing field"
  else pure ()
private def required (context name : String) (values : List (String × Json)) : Except String Json :=
  match field name values with | some value => pure value | none => err s!"{context}: missing {name}"
private def str (context : String) : Json → Except String String
  | .str value => pure value | _ => err s!"{context}: expected string"
private def nat (context : String) : Json → Except String Nat
  | value => match value.getNat? with | .ok value => pure value | .error _ => err s!"{context}: expected nat"
private def bool (context : String) : Json → Except String Bool
  | .bool value => pure value | _ => err s!"{context}: expected bool"
private def array (context : String) : Json → Except String (List Json)
  | .arr values => pure values.toList | _ => err s!"{context}: expected array"
private def nonempty (context value : String) : Except String String :=
  if value.isEmpty then err s!"{context}: empty string" else pure value
private def reqStr (context name : String) (values : List (String × Json)) : Except String String := do
  str s!"{context}.{name}" (← required context name values)
private def reqNat (context name : String) (values : List (String × Json)) : Except String Nat := do
  nat s!"{context}.{name}" (← required context name values)
private def usage : Json → Except String Usage
  | .str "many" => pure .many | .str "linear" => pure .linear | _ => err "invalid usage"

private def literal (value : Json) : Except String Literal := do
  let values ← object "literal" value ["type", "value"] ["type"]
  match ← reqStr "literal" "type" values with
  | "nat" => .nat <$> nat "literal.value" (← required "literal" "value" values)
  | "bool" => .bool <$> bool "literal.value" (← required "literal" "value" values)
  | "unit" => if (field "value" values).isSome then err "unit has value" else pure .unit
  | kind => err s!"unsupported literal type {kind}"

mutual
  private partial def decodeProgram (value : Json) : Except String Program := do
    let items ← array "program" value
    let rec go : List Json → Except String Program
      | [] => pure .empty
      | item :: rest => .cons <$> decodeAtom item <*> go rest
    go items
  private partial def decodeValue (input : Json) : Except String Value := do
    let values ← object "value" input ["kind", "literal", "body", "usage", "id"] ["kind"]
    let kind ← reqStr "value" "kind" values
    let allowed := if kind == "literal" then ["kind", "literal"]
      else if kind == "quotation" then ["kind", "body", "usage"]
      else if kind == "world" then ["kind", "id"] else ["kind"]
    let _ ← exactMembers "value" values allowed allowed
    match kind with
    | "literal" => .literal <$> literal (← required "value" "literal" values)
    | "quotation" => .quotation <$> decodeProgram (← required "value" "body" values) <*> usage (← required "value" "usage" values)
    | "world" => .world <$> nat "value.id" (← required "value" "id" values)
    | _ => err s!"unsupported value kind {kind}"
  private partial def decodeAtom (input : Json) : Except String Atom := do
    let values ← object "atom" input ["kind", "value", "body", "name"] ["kind"]
    let kind ← reqStr "atom" "kind" values
    let allowed := if kind == "lit" || kind == "push" then ["kind", "value"]
      else if kind == "quotation" then ["kind", "body"]
      else if kind == "word" || kind == "prim" then ["kind", "name"] else ["kind"]
    let _ ← exactMembers "atom" values allowed allowed
    match kind with
    | "lit" => .lit <$> literal (← required "atom" "value" values)
    | "push" => .push <$> decodeValue (← required "atom" "value" values)
    | "quotation" => .quotation <$> decodeProgram (← required "atom" "body" values)
    | "dup" => pure .dup | "drop" => pure .drop | "swap" => pure .swap | "dip" => pure .dip
    | "call" => pure .call | "compose" => pure .compose | "quote" => pure .quote | "if" => pure .ifThenElse
    | "word" => .word <$> (nonempty "atom.name" =<< reqStr "atom" "name" values)
    | "prim" => .prim <$> (nonempty "atom.name" =<< reqStr "atom" "name" values)
    | _ => err s!"unsupported atom kind {kind}"
end

private structure Request where
  requestId : String
  program : Program
  stack : Stack
  dictionary : Dictionary
  gamma : Gamma
  fuel : Nat

private def marker (context : String) (values : List (String × Json)) : Except String Unit := do
  if (← reqStr context "checking_state" values) != "checked" then err s!"{context}: checking unavailable"
  if (← reqStr context "proof_state" values) != "available" then err s!"{context}: proof unavailable"

private def adapterGamma : Gamma :=
  { defaultGamma with
    primitive := fun primitive =>
      if primitive == "+" then defaultGamma.primitive "addNat" else none }

private def decodeDictionary (value : Json) : Except String (Dictionary × List Program) := do
  let entries ← fields "dictionary" value
  let rec go : List (String × Json) → Except String (List (String × WordEntry))

    | [] => pure []
    | (name, entryJson) :: rest => do
        let context := s!"dictionary.{name}"
        let values ← object context entryJson ["checking_state", "proof_state", "program"]
          ["checking_state", "proof_state", "program"]
        marker context values
        let body ← decodeProgram (← required context "program" values)
        let tail ← go rest
        pure ((name, { type := { rowVariables := ["ρ"], input := .row "ρ", output := .row "ρ" }, body := body }) :: tail)
  let entries ← go entries
  let dictionary : Dictionary := fun name => entries.find? (fun (entry, _) => entry == name) |>.map (·.2)
  pure (dictionary, entries.map (fun (_, entry) => entry.body))

mutual
  private partial def validateProgram (gamma : Gamma) (dictionary : Dictionary) : Program → Except String Unit
    | .empty => pure ()
    | .cons head tail => do
        validateAtom gamma dictionary head
        validateProgram gamma dictionary tail
  private partial def validateValue (gamma : Gamma) (dictionary : Dictionary) : Value → Except String Unit
    | .literal _ | .world _ => pure ()
    | .quotation body _ => validateProgram gamma dictionary body
  private partial def validateAtom (gamma : Gamma) (dictionary : Dictionary) : Atom → Except String Unit
    | .push value => validateValue gamma dictionary value
    | .quotation body => validateProgram gamma dictionary body
    | .word name => if dictionary name |>.isSome then pure () else err s!"unknown dictionary word {name}"
    | .prim name => if gamma.primitive name |>.isSome then pure () else err s!"unknown primitive {name}"
    | _ => pure ()
end

private def decodeRequest (value : Json) : Except String Request := do
  let values ← object "request" value
    ["request_id", "checked_kernel", "initial_stack", "dictionary", "gamma_version", "fuel"]
    ["request_id", "checked_kernel", "initial_stack", "dictionary", "gamma_version", "fuel"]
  let requestId ← nonempty "request_id" =<< reqStr "request" "request_id" values
  let version ← reqStr "request" "gamma_version" values
  if version != "0.1" then err "unsupported gamma version"
  let kernel ← object "checked_kernel" (← required "request" "checked_kernel" values)
    ["checking_state", "proof_state", "gamma_version", "program"]
    ["checking_state", "proof_state", "gamma_version", "program"]
  marker "checked_kernel" kernel
  if (← reqStr "checked_kernel" "gamma_version" kernel) != version then err "gamma version mismatch"
  let body ← decodeProgram (← required "checked_kernel" "program" kernel)
  let jsonStack ← array "initial_stack" (← required "request" "initial_stack" values)
  let rec stack : List Json → Except String Stack
    | [] => pure []
    | item :: rest => .cons <$> decodeValue item <*> stack rest
  let decodedStack ← stack jsonStack
  let initialStack := decodedStack.reverse
  let (dictionary, dictionaryBodies) ← decodeDictionary (← required "request" "dictionary" values)
  let rec validateStack : Stack → Except String Unit
    | [] => pure ()
    | value :: rest => do
        validateValue adapterGamma dictionary value
        validateStack rest
  validateStack initialStack
  validateProgram adapterGamma dictionary body
  for dictionaryBody in dictionaryBodies do
    validateProgram adapterGamma dictionary dictionaryBody
  let fuel ← reqNat "request" "fuel" values
  pure { requestId, program := body, stack := initialStack, dictionary, gamma := adapterGamma, fuel }

private structure TraceEntry where
  config : Config
  cost : Nat
private structure Execution where
  status : String
  trap : Option String
  config : Config
  trace : List TraceEntry
  steps : Nat
  cost : Nat
private def trap (gamma : Gamma) (dictionary : Dictionary) : Config → String
  | { program := .cons atom _, .. } => match atom with
    | .word name => if dictionary name |>.isSome then "stack-fault" else "unknown-word"
    | .prim name => if gamma.primitive name |>.isSome then "primitive-fault" else "unknown-primitive"
    | .lit _ | .quotation _ => "type-fault"
    | _ => "stack-fault"
  | _ => "stack-fault"
private def execute (request : Request) : Execution :=
  let rec go (fuel : Nat) (config : Config) (trace : List TraceEntry) (steps cost : Nat) : Execution :=
    match step request.gamma request.dictionary defaultCosts config with
    | .terminal final => { status := "success", trap := none, config := final, trace := trace.reverse, steps, cost }
    | .stuck final => { status := "trap", trap := some (trap request.gamma request.dictionary final), config := final, trace := trace.reverse, steps, cost }
    | .stepped next charge => match fuel with
      | 0 => { status := "trap", trap := some "fuel-exhausted", config, trace := trace.reverse, steps, cost }
      | fuel + 1 => go fuel next ({ config, cost := charge } :: trace) (steps + 1) (cost + charge)
  go request.fuel { stack := request.stack, program := request.program } [] 0 0

private def quote (value : String) : String := (Json.str value).compress
private def obj (values : List (String × String)) : String := "{" ++ String.intercalate "," (values.map fun (key, value) => quote key ++ ":" ++ value) ++ "}"
private def arr (values : List String) : String := "[" ++ String.intercalate "," values ++ "]"
private def number (value : Nat) : String := toString value
mutual
  private def programJson : Program → String
    | .empty => arr []
    | .cons head tail => arr (atomJson head :: atomsJson tail)
  private def atomsJson : Program → List String
    | .empty => [] | .cons head tail => atomJson head :: atomsJson tail
  private def atomJson : Atom → String
    | .lit value => obj [("kind", quote "lit"), ("value", literalJson value)]
    | .push value => obj [("kind", quote "push"), ("value", valueJson value)]
    | .quotation body => obj [("kind", quote "quotation"), ("body", programJson body)]
    | .dup => obj [("kind", quote "dup")] | .drop => obj [("kind", quote "drop")] | .swap => obj [("kind", quote "swap")]
    | .dip => obj [("kind", quote "dip")] | .call => obj [("kind", quote "call")] | .compose => obj [("kind", quote "compose")]
    | .quote => obj [("kind", quote "quote")] | .ifThenElse => obj [("kind", quote "if")]
    | .word name => obj [("kind", quote "word"), ("name", quote name)]
    | .prim name => obj [("kind", quote "prim"), ("name", quote name)]
  private def literalJson : Literal → String
    | .nat value => obj [("type", quote "nat"), ("value", number value)]
    | .bool value => obj [("type", quote "bool"), ("value", if value then "true" else "false")]
    | .unit => obj [("type", quote "unit")]
  private def valueJson : Value → String
    | .literal value => obj [("kind", quote "literal"), ("literal", literalJson value)]
    | .quotation body usage => obj [("kind", quote "quotation"), ("body", programJson body),
        ("usage", quote (match usage with | .many => "many" | .linear => "linear"))]
    | .world id => obj [("kind", quote "world"), ("id", number id)]
end
private def stackJson (stack : Stack) : String := arr (stack.reverse.map valueJson)
private def traceJson (trace : List TraceEntry) : String :=
  arr ((trace.zip (List.range trace.length)).map (fun item =>
    let traceEntry := item.1
    let index := item.2
    obj [("index", number index), ("stack", stackJson traceEntry.config.stack),
      ("program", programJson traceEntry.config.program), ("cost", number traceEntry.cost)]))
private def worldJson (config : Config) : String := obj [("ids", arr ((observeWorld config.stack ++ observeWorldProgram config.program).map number))]
private def output (request : Request) (execution : Execution) : String := obj [
  ("request_id", quote request.requestId), ("status", quote execution.status),
  ("stack", stackJson execution.config.stack), ("trace", traceJson execution.trace),
  ("cost", obj [("steps", number execution.steps), ("total", number execution.cost)]),
  ("trap", match execution.trap with | none => "null" | some value => quote value),
  ("world_observation", worldJson execution.config)]

private def validateJsonMembers (input : String) : Except String Unit :=
  match Firth.Agent.rejectDuplicateMembers input with
  | .ok () => pure ()
  | .error .duplicate => err "duplicate JSON field"
  | .error .malformed => err "malformed JSON"

def runRequest (input : String) : Except String String := do
  validateJsonMembers input
  let json ← match Json.parse input with | .ok value => pure value | .error error => err s!"malformed JSON: {error}"
  let request ← decodeRequest json
  pure (output request (execute request))

def main (args : List String) : IO Unit := do
  if !args.isEmpty then throw <| IO.userError "firthReferenceRun accepts stdin JSON only"
  let input ← (← IO.getStdin).readToEnd
  match runRequest input with
  | .ok value => IO.println value
  | .error error => IO.eprintln (obj [("status", quote "error"), ("error", quote error)]); throw <| IO.userError error

end Firth.ReferenceRun
