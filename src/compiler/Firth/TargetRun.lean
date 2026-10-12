import Lean.Data.Json
import agent.Firth.Agent.JsonMembers
import compiler.Firth.TargetSemantics

/-!
The Lean target runner: a `firth.vm-run.v1` request in, the fields of the
VM's `firth.observation.v1` response that the two hosts are compared on out,
computed by `TargetSemantics.execute` instead of by the Rust VM.

The request is the one `firth-vm vm-run` reads (`adapter_request.rs`): the
`target_program` that `firthCompile` emits, a portable `initial_stack`
(bottom to top), an `image` and a `fuel`. The runner decodes it with the same
strictness: an unknown or missing member, a wrong type, an integer outside
`i64`, a malformed or non-lowercase hex string, a body digest that is not the
canonical one, a quotation breaking the target bounds, a duplicate word name
and a missing entry word are refused with an error, never guessed at.

The response keeps the VM's member names and value shapes for `request_id`,
`status`, `stack`, `cost`, `trap` and `trap_subcode`. The VM's `cost` reports
`steps`, `total` and `kernel`; this runner reports those three and also the
split by kind the semantics keeps (`instructions`, `word_entries`,
`primitives`), which the VM's adapter response does not carry. A run the
semantics gives no meaning to ends with `status` `unsupported`, a value the VM
never reports, so it can never be read as agreement.

Nothing here is trusted by anything but a test: it is the second
implementation the VM is compared against.
-/

namespace Firth.Compiler.TargetRun

open Lean
open Firth.Compiler
open Firth.Compiler.Target
open Firth.Compiler.TargetSemantics

/-- The `gamma_version` the request states, as the VM's adapter checks it. -/
def gammaVersion : String := "0.8"

/-- The target registry version (`GAMMA_VERSION` in the VM). -/
def targetGammaVersion : Nat := 8

/-- The frozen target image format version. -/
def formatVersion : Nat := 1

/-- The VM's adapter fuel bound (`MAX_FUEL`). -/
def maxFuel : Nat := 1000000

private def err (message : String) : Except String α := .error message

private def fields (context : String) : Json → Except String (List (String × Json))
  | .obj values => pure values.toList
  | _ => err s!"{context}: expected object"

private def field (name : String) : List (String × Json) → Option Json
  | [] => none
  | (key, value) :: rest => if key == name then some value else field name rest

/-- An object with exactly the listed members, as the VM's `object` demands. -/
private def object (context : String) (value : Json) (allowed : List String) :
    Except String (List (String × Json)) := do
  let values ← fields context value
  if values.any (fun (key, _) => !allowed.any (· == key)) then err s!"{context}: unknown member"
  else if allowed.any (fun key => (field key values).isNone) then err s!"{context}: missing member"
  else pure values

private def required (context name : String) (values : List (String × Json)) :
    Except String Json :=
  match field name values with
  | some value => pure value
  | none => err s!"{context}: missing {name}"

private def str (context : String) : Json → Except String String
  | .str value => pure value
  | _ => err s!"{context}: expected string"

private def nonemptyStr (context : String) (value : Json) : Except String String := do
  let text ← str context value
  if text.isEmpty then err s!"{context}: empty string" else pure text

private def array (context : String) : Json → Except String (List Json)
  | .arr values => pure values.toList
  | _ => err s!"{context}: expected array"

private def int (context : String) (value : Json) : Except String Int :=
  match value with
  | .num _ =>
      match value.getInt? with
      | .ok number => pure number
      | .error _ => err s!"{context}: expected an integer"
  | _ => err s!"{context}: expected an integer"

private def int64 (context : String) (value : Json) : Except String Int := do
  let number ← int context value
  if isInt64 number then pure number else err s!"{context}: integer outside the signed 64-bit range"

private def nat (context : String) (value : Json) : Except String Nat := do
  let number ← int context value
  if number < 0 then err s!"{context}: expected a non-negative integer" else pure number.toNat

private def bool (context : String) : Json → Except String Bool
  | .bool value => pure value
  | _ => err s!"{context}: expected boolean"

private def hexDigit (character : Char) : Option Nat :=
  if '0' ≤ character && character ≤ '9' then some (character.toNat - '0'.toNat)
  else if 'a' ≤ character && character ≤ 'f' then some (character.toNat - 'a'.toNat + 10)
  else none

/-- Lowercase hexadecimal into bytes, refusing odd length and any other digit. -/
private def hexBytes (context : String) (text : String) : Except String ByteArray := do
  let rec go : List Char → Array UInt8 → Except String (Array UInt8)
    | [], out => pure out
    | high :: low :: rest, out =>
        match hexDigit high, hexDigit low with
        | some high, some low => go rest (out.push (UInt8.ofNat (high * 16 + low)))
        | _, _ => err s!"{context}: expected lowercase hex"
    | [_], _ => err s!"{context}: odd-length hex"
  pure ⟨← go text.toList #[]⟩

private def decodeList {α : Type} (decode : Json → Except String α) :
    List Json → Except String (List α)
  | [] => pure []
  | item :: rest => do pure ((← decode item) :: (← decodeList decode rest))

mutual

  /-- A value in the request operand grammar (`adapter_operand_value`). -/
  private partial def decodeOperand (context : String) (value : Json) : Except String Value := do
    let values ← fields context value
    match ← str s!"{context}.kind" (← required context "kind" values) with
    | "int" =>
        let values ← object context value ["kind", "value"]
        pure (.int (← int64 s!"{context}.value" (← required context "value" values)))
    | "bool" =>
        let values ← object context value ["kind", "value"]
        pure (.bool (← bool s!"{context}.value" (← required context "value" values)))
    | "bytes" =>
        let values ← object context value ["kind", "value"]
        let text ← str s!"{context}.value" (← required context "value" values)
        pure (.bytes (← hexBytes s!"{context}.value" text))
    | "quotation" =>
        let (code, captures, consumed) ← decodeQuotation context value
        pure (.quotation code captures consumed)
    | "primitive" =>
        let values ← object context value ["kind", "tag", "bytes"]
        let tag ← nat s!"{context}.tag" (← required context "tag" values)
        let text ← str s!"{context}.bytes" (← required context "bytes" values)
        pure (.primitiveValue tag (← hexBytes s!"{context}.bytes" text))
    | _ => err s!"{context}: unknown value kind"

  /-- One quotation object: code, captures, and one unconsumed flag per
  capture (`adapter_quotation`). -/
  private partial def decodeQuotation (context : String) (value : Json) :
      Except String (List Instruction × List Value × List Bool) := do
    let values ← object context value ["kind", "code", "captures", "consumed"]
    if (← str s!"{context}.kind" (← required context "kind" values)) != "quotation" then
      err s!"{context}: expected a quotation"
    let code ← decodeCode context (← required context "code" values)
    let captures ← decodeOperands context
      (← array s!"{context}.captures" (← required context "captures" values))
    let flags ← decodeList (bool s!"{context}.consumed")
      (← array s!"{context}.consumed" (← required context "consumed" values))
    if captures.length != flags.length then
      err s!"{context}: capture state length must match captures"
    if flags.any id then err s!"{context}: a static quotation cannot carry a consumed capture"
    pure (code, captures, flags)

  private partial def decodeOperands (context : String) :
      List Json → Except String (List Value)
    | [] => pure []
    | item :: rest => do pure ((← decodeOperand context item) :: (← decodeOperands context rest))

  private partial def decodeCode (context : String) (value : Json) :
      Except String (List Instruction) := do
    decodeInstructions context (← array s!"{context}.code" value)

  private partial def decodeInstructions (context : String) :
      List Json → Except String (List Instruction)
    | [] => pure []
    | item :: rest => do
        pure ((← decodeInstruction context item) :: (← decodeInstructions context rest))

  /-- One instruction (`adapter_instruction`). -/
  private partial def decodeInstruction (context : String) (value : Json) :
      Except String Instruction := do
    let values ← fields context value
    match ← str s!"{context}.op" (← required context "op" values) with
    | "push-literal" =>
        let values ← object context value ["op", "literal"]
        pure (.pushLiteral (← decodeOperand context (← required context "literal" values)))
    | "push-quote" =>
        let values ← object context value ["op", "quotation"]
        let (code, captures, consumed) ←
          decodeQuotation context (← required context "quotation" values)
        pure (.pushQuote code captures consumed)
    | "push-capture" =>
        let values ← object context value ["op", "index"]
        pure (.pushCapture (← nat s!"{context}.index" (← required context "index" values)))
    | "pick" =>
        let values ← object context value ["op", "depth"]
        pure (.pick (← nat s!"{context}.depth" (← required context "depth" values)))
    | "roll" =>
        let values ← object context value ["op", "depth"]
        pure (.roll (← nat s!"{context}.depth" (← required context "depth" values)))
    | "call-word" =>
        let values ← object context value ["op", "name"]
        pure (.callWord (← nonemptyStr s!"{context}.name" (← required context "name" values)))
    | "prim" =>
        let values ← object context value ["op", "primitive"]
        pure (.prim (← nonemptyStr s!"{context}.primitive" (← required context "primitive" values)))
    | bare =>
        let _ ← object context value ["op"]
        match bare with
        | "dup" => pure .dup
        | "drop" => pure .drop
        | "swap" => pure .swap
        | "call" => pure .call
        | "dip" => pure .dip
        | "compose" => pure .compose
        | "quote" => pure .quote
        | "if" => pure .ifThenElse
        | _ => err s!"{context}: unknown instruction"

end

/-- One word entry of the target program, with its stated body digest checked
against the canonical one, as the VM's image decoder does. -/
private def decodeWord (value : Json) : Except String WordEntry := do
  let context := "target_program.words"
  let values ← object context value
    ["name", "erased_word_type", "code", "body_digest", "kernel_evidence_digest",
     "refinement_evidence_digest", "generation"]
  let name ← nonemptyStr s!"{context}.name" (← required context "name" values)
  let erasedWordType ←
    nonemptyStr s!"{context}.erased_word_type" (← required context "erased_word_type" values)
  let code ← decodeCode context (← required context "code" values)
  let stated ← hexBytes s!"{context}.body_digest"
    (← str s!"{context}.body_digest" (← required context "body_digest" values))
  if stated != bodyDigest code then
    err s!"{context}: body_digest of {name} is not the canonical digest of its code"
  let kernel ← hexBytes s!"{context}.kernel_evidence_digest"
    (← str s!"{context}.kernel_evidence_digest" (← required context "kernel_evidence_digest" values))
  let refinement ← hexBytes s!"{context}.refinement_evidence_digest"
    (← str s!"{context}.refinement_evidence_digest"
      (← required context "refinement_evidence_digest" values))
  let generation ← nat s!"{context}.generation" (← required context "generation" values)
  if !wellFormedCode code then err s!"{context}: {name} has a quotation with mismatched capture state"
  if let some detail := boundViolation code then err s!"{context}: {name}: {detail}"
  pure { name, erasedWordType, code, kernelEvidenceDigest := kernel,
         refinementEvidenceDigest := refinement, generation }

/-- A portable initial-stack value (`adapter_reference_value`). Sequences are
the primitive values of §2 with their canonical bytes. -/
private def decodeInitial (value : Json) : Except String Value := do
  let context := "request.initial_stack"
  let values ← fields context value
  match ← str s!"{context}.kind" (← required context "kind" values) with
  | "literal" =>
      let values ← object context value ["kind", "literal"]
      let literal := ← required context "literal" values
      let members ← fields context literal
      match ← str s!"{context}.type" (← required context "type" members) with
      | "int" =>
          let members ← object context literal ["type", "value"]
          pure (.int (← int64 s!"{context}.value" (← required context "value" members)))
      | "bool" =>
          let members ← object context literal ["type", "value"]
          pure (.bool (← bool s!"{context}.value" (← required context "value" members)))
      | "seq-int" =>
          let members ← object context literal ["type", "value"]
          let items ← array s!"{context}.value" (← required context "value" members)
          let numbers ← decodeList (int64 s!"{context}.value") items
          pure (.primitiveValue seqIntTag (seqIntBytes numbers))
      | "seq-bool" =>
          let members ← object context literal ["type", "value"]
          let items ← array s!"{context}.value" (← required context "value" members)
          let flags ← decodeList (bool s!"{context}.value") items
          pure (.primitiveValue seqBoolTag (seqBoolBytes flags))
      | "unit" => err s!"{context}: the unit literal has no v0.1 target representation"
      | _ => err s!"{context}: unknown literal type"
  | "quotation" =>
      err s!"{context}: a kernel quotation must be lowered by the compiler before execution"
  | "world" => err s!"{context}: World is administrative and is never supplied as an initial value"
  | _ => err s!"{context}: unknown value kind"

/-- A decoded request: the admitted image, the entry word, the initial stack
(top first) and the fuel. -/
structure Request where
  requestId : String
  image : List WordEntry
  entry : String
  stack : List Value
  fuel : Nat

/-- Decodes a `firth.vm-run.v1` request as the VM's adapter does. -/
def decodeRequest (json : Json) : Except String Request := do
  let values ← object "request" json
    ["request_id", "target_program", "initial_stack", "image", "gamma_version", "fuel"]
  let requestId ← nonemptyStr "request.request_id" (← required "request" "request_id" values)
  if (← str "request.gamma_version" (← required "request" "gamma_version" values)) != gammaVersion then
    err "request.gamma_version: unsupported gamma version"
  let fuel ← nat "request.fuel" (← required "request" "fuel" values)
  if fuel > maxFuel then err "request.fuel: fuel exceeds the adapter budget"
  let program ← object "target_program" (← required "request" "target_program" values)
    ["format_version", "entry", "words"]
  if (← nat "target_program.format_version" (← required "target_program" "format_version" program))
      != formatVersion then
    err "target_program.format_version: unsupported target format version"
  let entry ← nonemptyStr "target_program.entry" (← required "target_program" "entry" program)
  let words ← decodeList decodeWord
    (← array "target_program.words" (← required "target_program" "words" program))
  let names := words.map (·.name)
  if names.eraseDups.length != names.length then err "target_program.words: duplicate word name"
  if !names.any (· == entry) then err "target_program.entry: the entry word is not in the target program"
  let image ← object "image" (← required "request" "image" values) ["image_version", "gamma_version"]
  let _ ← nat "image.image_version" (← required "image" "image_version" image)
  if (← nat "image.gamma_version" (← required "image" "gamma_version" image)) != targetGammaVersion then
    err "image.gamma_version: unsupported target registry version"
  let initial ← decodeList decodeInitial
    (← array "request.initial_stack" (← required "request" "initial_stack" values))
  pure { requestId, image := words, entry, stack := initial.reverse, fuel }

/-! ## Rendering in the VM's observation grammar -/

private def hex (bytes : ByteArray) : String := Digest.toHex bytes

private def jsonInt (value : Int) : Json := Json.num (JsonNumber.fromInt value)
private def jsonNat (value : Nat) : Json := jsonInt value

private def jsonObject (members : List (String × Json)) : Json := Json.mkObj members

mutual

  /-- A value in the operand grammar (`operand_value_json`): what a capture or
  a literal inside reported code looks like. -/
  private partial def operandJson : Value → Json
    | .int value => jsonObject [("kind", "int"), ("value", jsonInt value)]
    | .bool value => jsonObject [("kind", "bool"), ("value", Json.bool value)]
    | .bytes value => jsonObject [("kind", "bytes"), ("value", hex value)]
    | .quotation code captures consumed => quotationJson code captures consumed
    | .primitiveValue tag value =>
        jsonObject [("kind", "primitive"), ("tag", jsonNat tag), ("bytes", hex value)]
    | .world => jsonObject [("kind", "world")]

  /-- The quotation members that follow the value envelope: body, capture
  slots (a consumed slot is `{"kind":"consumed"}`) and the consumed flags. -/
  private partial def quotationMembers (code : List Instruction) (captures : List Value)
      (consumed : List Bool) : List (String × Json) :=
    let slots := (captures.zip consumed).map fun (value, flag) =>
      if flag then jsonObject [("kind", "consumed")] else operandJson value
    [("code", codeJson code), ("captures", Json.arr slots.toArray),
     ("consumed", Json.arr (consumed.map Json.bool).toArray)]

  private partial def quotationJson (code : List Instruction) (captures : List Value)
      (consumed : List Bool) : Json :=
    jsonObject (("kind", "quotation") :: quotationMembers code captures consumed)

  private partial def instructionJson : Instruction → Json
    | .pushLiteral value =>
        jsonObject [("op", "push-literal"), ("literal", operandJson value)]
    | .pushQuote code captures consumed =>
        jsonObject [("op", "push-quote"), ("quotation", quotationJson code captures consumed)]
    | .pushCapture index => jsonObject [("op", "push-capture"), ("index", jsonNat index)]
    | .pick depth => jsonObject [("op", "pick"), ("depth", jsonNat depth)]
    | .roll depth => jsonObject [("op", "roll"), ("depth", jsonNat depth)]
    | .callWord name => jsonObject [("op", "call-word"), ("name", name)]
    | .prim name => jsonObject [("op", "prim"), ("primitive", name)]
    | .dup => jsonObject [("op", "dup")]
    | .drop => jsonObject [("op", "drop")]
    | .swap => jsonObject [("op", "swap")]
    | .call => jsonObject [("op", "call")]
    | .dip => jsonObject [("op", "dip")]
    | .compose => jsonObject [("op", "compose")]
    | .quote => jsonObject [("op", "quote")]
    | .ifThenElse => jsonObject [("op", "if")]

  private partial def codeJson (code : List Instruction) : Json :=
    Json.arr ((code.map instructionJson).toArray)

end

private def literalJson (type : String) (value : Json) : Json :=
  jsonObject [("kind", "literal"), ("literal", jsonObject [("type", type), ("value", value)])]

/-- A stack value as the VM's `value_json` renders it: scalars and the two
sequence types as portable literals, a quotation with its usage and canonical
body digest. -/
private def stackValueJson : Value → Json
  | .primitiveValue tag bytes =>
      if tag == seqIntTag && bytes.size % 8 == 0 then
        literalJson "seq-int" (Json.arr ((decodeSeqInt bytes).map jsonInt).toArray)
      else if tag == seqBoolTag then
        literalJson "seq-bool" (Json.arr ((bytes.data.toList.map fun byte => Json.bool (byte == 1)).toArray))
      else jsonObject [("kind", "primitive"), ("tag", jsonNat tag), ("value", hex bytes)]
  | .int value => literalJson "int" (jsonInt value)
  | .bool value => literalJson "bool" (Json.bool value)
  | .bytes value => jsonObject [("kind", "bytes"), ("value", hex value)]
  | .quotation code captures consumed =>
      let header : List (String × Json) :=
        [("kind", "quotation"), ("usage", if linearValues captures then "linear" else "many"),
         ("body_digest", hex (bodyDigest code))]
      jsonObject (header ++ quotationMembers code captures consumed)
  | .world => jsonObject [("kind", "world")]

/-- The cost report: the VM's `steps`, `total` and `kernel`, then the split
by kind the semantics keeps. -/
private def costJson (cost : Cost) : Json :=
  jsonObject [("steps", jsonNat cost.instructions), ("total", jsonNat cost.total),
    ("kernel", jsonNat cost.kernel), ("instructions", jsonNat cost.instructions),
    ("word_entries", jsonNat cost.wordEntries), ("primitives", jsonNat cost.primitives)]

/-- The observation of one run. `unsupported` is its own status. -/
private def observation (requestId status : String) (stack : List Value) (cost : Cost)
    (trap subcode : Json) : String :=
  (jsonObject [("request_id", requestId), ("status", status),
    ("stack", Json.arr ((stack.reverse.map stackValueJson).toArray)),
    ("cost", costJson cost), ("trap", trap), ("trap_subcode", subcode)]).compress

/-- Runs one decoded request and renders its observation. The semantics keeps
the stack top first; the response lists it bottom to top, as the VM does. -/
def runDecoded (request : Request) : Except String String :=
  match execute request.image request.entry request.stack request.fuel with
  | .halted stack machine =>
      pure (observation request.requestId "success" stack machine.cost Json.null Json.null)
  | .trapped trap machine =>
      let status := if trap == .unsupported then "unsupported" else "trap"
      pure (observation request.requestId status machine.stack machine.cost
        (Json.str trap.code) (Json.str trap.subcode))
  | .outOfBound _ => err "internal: the run exceeded its proved step bound"

private def validateJsonMembers (input : String) : Except String Unit :=
  match Firth.Agent.rejectDuplicateMembers input with
  | .ok () => pure ()
  | .error .duplicate => err "duplicate JSON member"
  | .error .malformed => err "malformed JSON"

/-- The whole runner: request bytes in, response bytes out. -/
def runRequest (input : String) : Except String String := do
  validateJsonMembers input
  let json ← match Json.parse input with
    | .ok value => pure value
    | .error error => err s!"malformed JSON: {error}"
  runDecoded (← decodeRequest json)

/-- Renders a refusal in the shape the other adapters use. -/
def errorJson (message : String) : String :=
  (jsonObject [("status", "error"), ("error", message)]).compress

/-- The executable entry point: one request on stdin, one response on stdout. -/
def main (args : List String) : IO Unit := do
  if !args.isEmpty then throw <| IO.userError "firthTargetRun accepts stdin JSON only"
  let input ← (← IO.getStdin).readToEnd
  match runRequest input with
  | .ok value => IO.println value
  | .error error =>
      IO.eprintln (errorJson error)
      throw <| IO.userError error

end Firth.Compiler.TargetRun
