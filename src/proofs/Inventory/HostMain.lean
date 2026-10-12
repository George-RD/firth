import Lean.Data.Json
import proofs.Inventory.Host

/-!
`lake exe inventoryHost`: the inventory allocator's host encoding, run from
the definitions `Host.lean` proves things about. `examples/inventory/run_cases.py`
calls it on JSON over stdin and stdout.

* `inventoryHost encode` reads a JSON array of ID strings and writes the
  component's ID sequence (`encodeIds`): four Ints per ID, in order. It refuses
  (exit 1) unless every ID meets `validId`, so nothing outside the proofs'
  precondition is encoded.
* `inventoryHost answer` reads `{"ids": [...], "stack": [code, remaining,
  allocated, reasons]}`, the request IDs and the component's final stack, and
  writes the host's JSON answer (`hostEncode`). It refuses (exit 1) when an ID
  fails `validId` or the stack is not one the spec allows.
-/

open Lean (Json)
open Firth.Proofs.Inventory.Host

namespace Firth.Proofs.Inventory.HostMain

def strings (j : Json) : Except String (List String) := do
  let items ← j.getArr?
  items.toList.mapM fun item => item.getStr?

def ints (j : Json) : Except String (List Int) := do
  let items ← j.getArr?
  items.toList.mapM fun item => item.getInt?

def encode (input : Json) : Except String Json := do
  let ids ← strings input
  match ids.find? (fun s => !validId s) with
  | some bad => throw s!"not an ID the spec allows: {bad.quote}"
  | none => pure (Json.arr ((encodeIds ids).map fun v => Lean.toJson v).toArray)

def answerJson : Answer → Json
  | .error code => Json.mkObj [("status", "error"), ("code", code)]
  | .ok remaining lines => Json.mkObj [("status", "ok"), ("remaining", Lean.toJson remaining),
      ("allocations", Json.arr (lines.map fun line => Json.mkObj
        [("id", line.id), ("quantity", Lean.toJson line.quantity), ("reason", line.reason)]).toArray)]

def answer (input : Json) : Except String Json := do
  let ids ← strings (← input.getObjVal? "ids")
  if let some bad := ids.find? (fun s => !validId s) then
    throw s!"not an ID the spec allows: {bad.quote}"
  let stack ← (← input.getObjVal? "stack").getArr?
  match stack.toList with
  | [code, remaining, allocated, reasons] =>
    let result := hostEncode ids (← code.getInt?) (← remaining.getInt?) (← ints allocated)
      (← ints reasons)
    match result with
    | some a => pure (answerJson a)
    | none => throw "the component's stack is not one the spec allows"
  | _ => throw "the component's stack does not have four values"

end Firth.Proofs.Inventory.HostMain

open Firth.Proofs.Inventory.HostMain in
def main (args : List String) : IO UInt32 := do
  let run : Json → Except String Json ← match args with
    | ["encode"] => pure encode
    | ["answer"] => pure answer
    | _ => do
      IO.eprintln "usage: inventoryHost encode|answer < input.json"
      return 2
  let text ← (← IO.getStdin).readToEnd
  match Json.parse text >>= run with
  | .ok out =>
    IO.println out.compress
    return 0
  | .error message =>
    IO.eprintln s!"inventoryHost: {message}"
    return 1
