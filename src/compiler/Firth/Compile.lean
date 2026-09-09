import Lean.Data.Json
import FirthReferenceRun
import agent.Firth.Agent.JsonMembers
import compiler.Firth.Lowering

/-!
The `firth.compile.v1` adapter: one `firth.checked-kernel.v1` request in, one
`firth.target-program.v1` response out, as pinned by
`tools/loop/mvp_agent_manifest.toml`.

Caller-supplied checking/proof markers are compatibility assertions, not
proof. Every body and declared type is rechecked against the whole dictionary
by `Lowering.compileWords`. An optional `source` envelope additionally triggers
real re-elaboration and exact dictionary comparison before lowering. The
source runner and differential harness always supply that envelope.

Kernel-only compilation is supported, but does not claim source origin.
Neither mode claims discharged source refinements or authenticates a target
image. Response verification metadata states these distinctions explicitly.
Malformed/unsupported transport and representations still fail closed.

The response carries the target program, the body digest of every word, and
the debug locations §5 asks for so a harness can aggregate target instructions
back to kernel atoms. Because the §3 table maps each atom to exactly one
instruction, that mapping is an index correspondence and the adapter checks it
rather than asserting it.
-/

namespace Firth.Compiler.Compile

open Lean
open Firth.Compiler

/-- The language `Gamma` version this adapter speaks. -/
def gammaVersion : String := "0.1"

/-- The target contract version this adapter compiles to. -/
def targetVersion : String := "0.1"

/-- The frozen target image format version (`target-spec.md` §7). -/
def formatVersion : Nat := 1

private def err (message : String) : Except String α := .error message

private def fields (context : String) : Json → Except String (List (String × Json))
  | .obj values => pure values.toList
  | _ => err s!"{context}: expected object"

private def field (name : String) : List (String × Json) → Option Json
  | [] => none
  | (key, value) :: rest => if key == name then some value else field name rest

private def object (context : String) (value : Json) (allowed : List String)
    (optional : List String := []) :
    Except String (List (String × Json)) := do
  let values ← fields context value
  if values.any (fun (key, _) => !(allowed ++ optional).any (· == key)) then
    err s!"{context}: unknown member"
  else if allowed.any (fun key => (field key values).isNone) then
    err s!"{context}: missing member"
  else pure values

private def required (context name : String) (values : List (String × Json)) :
    Except String Json :=
  match field name values with
  | some value => pure value
  | none => err s!"{context}: missing {name}"

private def str (context : String) : Json → Except String String
  | .str value => pure value
  | _ => err s!"{context}: expected string"

private def array (context : String) : Json → Except String (List Json)
  | .arr values => pure values.toList
  | _ => err s!"{context}: expected array"

private def reqStr (context name : String) (values : List (String × Json)) :
    Except String String := do
  str s!"{context}.{name}" (← required context name values)

private def nonempty (context value : String) : Except String String :=
  if value.isEmpty then err s!"{context}: empty string" else pure value

private def usage (context : String) : Json → Except String WordType.Usage
  | .str "many" => pure .many
  | .str "linear" => pure .linear
  | _ => err s!"{context}: expected \"many\" or \"linear\""

mutual

  private partial def decodeValueType (value : Json) : Except String WordType.ValueType := do
    let values ← fields "value_type" value
    match ← str "value_type.kind" (← required "value_type" "kind" values) with
    | "base" =>
        let values ← object "value_type" value ["kind", "name", "usage"]
        pure (.base (← nonempty "value_type.name" =<< reqStr "value_type" "name" values)
          (← usage "value_type.usage" (← required "value_type" "usage" values)))
    | "quotation" =>
        let values ← object "value_type" value ["kind", "input", "output", "usage"]
        pure (.quotation
          (← decodeStackType (← required "value_type" "input" values))
          (← decodeStackType (← required "value_type" "output" values))
          (← usage "value_type.usage" (← required "value_type" "usage" values)))
    | kind => err s!"value_type: unknown kind {kind}"

  private partial def decodeItems : List Json → Except String (List WordType.ValueType)
    | [] => pure []
    | item :: rest => do pure ((← decodeValueType item) :: (← decodeItems rest))

  /-- A stack shape: an optional row variable at the bottom, then the value
  items in bottom-to-top order, which is the order the canonical target string
  writes them in. -/
  private partial def decodeStackType (value : Json) : Except String WordType.StackType := do
    let values ← object "stack_type" value ["row", "items"]
    let row ←
      match ← required "stack_type" "row" values with
      | .null => pure none
      | .str name => pure (some (← nonempty "stack_type.row" name))
      | _ => err "stack_type.row: expected string or null"
    pure (.mk row (← decodeItems (← array "stack_type.items" (← required "stack_type" "items" values))))

end

private def decodeScheme (value : Json) : Except String WordType.Scheme := do
  let values ← object "scheme" value ["row_variables", "input", "output"]
  let rows ← array "scheme.row_variables" (← required "scheme" "row_variables" values)
  let rec names : List Json → Except String (List String)
    | [] => pure []
    | item :: rest => do
        pure ((← nonempty "scheme.row_variables" =<< str "scheme.row_variables" item) :: (← names rest))
  pure { rowVariables := ← names rows
         input := ← decodeStackType (← required "scheme" "input" values)
         output := ← decodeStackType (← required "scheme" "output" values) }

/-- A checked word exactly as the request states it, before lowering. -/
private structure RequestWord where
  name : String
  program : Firth.Interpreter.Program
  atoms : Nat

private def countAtoms : Firth.Interpreter.Program → Nat
  | .empty => 0
  | .cons _ tail => 1 + countAtoms tail

private def decodeCheckedWord (value : Json) : Except String RequestWord := do
  let values ← object "checked_word" value ["name", "checking_state", "proof_state", "program"]
  if (← reqStr "checked_word" "checking_state" values) != "checked" then
    err "checked_word: checking unavailable"
  if (← reqStr "checked_word" "proof_state" values) != "available" then
    err "checked_word: proof unavailable"
  let program ← Firth.ReferenceRun.decodeProgram (← required "checked_word" "program" values)
  pure { name := ← nonempty "checked_word.name" =<< reqStr "checked_word" "name" values
         program
         atoms := countAtoms program }

private def decodeErasedType (value : Json) : Except String (String × WordType.Scheme) := do
  let values ← object "erased_word_type" value ["word", "type"]
  pure (← nonempty "erased_word_type.word" =<< reqStr "erased_word_type" "word" values,
        ← decodeScheme (← required "erased_word_type" "type" values))

/-- One decoded `firth.checked-kernel.v1` request. -/
structure Request where
  requestId : String
  entry : String
  words : List Lowering.CheckedWord
  atomCounts : List Nat
  source : Option Firth.Agent.Elaborate.Request := none

private def pairWords (words : List RequestWord) (types : List (String × WordType.Scheme)) :
    Except String (List Lowering.CheckedWord × List Nat) := do
  if words.length != types.length then
    err "erased_word_types does not cover checked_words"
  let mut checked : List Lowering.CheckedWord := []
  let mut counts : List Nat := []
  for word in words do
    match types.find? (fun entry => entry.1 == word.name) with
    | none => throw s!"erased_word_types is missing {word.name}"
    | some (_, scheme) =>
        checked := checked ++ [{ name := word.name, scheme, program := word.program }]
        counts := counts ++ [word.atoms]
  pure (checked, counts)

/-- Decodes a `firth.checked-kernel.v1` request. -/
def decodeRequest (value : Json) : Except String Request := do
  let values ← object "request" value
    ["request_id", "checked_words", "erased_word_types", "gamma_version", "target_version"]
    ["entry", "source"]
  let requestId ← nonempty "request.request_id" =<< reqStr "request" "request_id" values
  if (← reqStr "request" "gamma_version" values) != gammaVersion then
    err "request: unsupported gamma version"
  if (← reqStr "request" "target_version" values) != targetVersion then
    err "request: unsupported target version"
  let rec decodeWords : List Json → Except String (List RequestWord)
    | [] => pure []
    | item :: rest => do pure ((← decodeCheckedWord item) :: (← decodeWords rest))
  let rec decodeTypes : List Json → Except String (List (String × WordType.Scheme))
    | [] => pure []
    | item :: rest => do pure ((← decodeErasedType item) :: (← decodeTypes rest))
  let words ← decodeWords (← array "request.checked_words" (← required "request" "checked_words" values))
  if words.isEmpty then err "request: checked_words is empty"
  let names := words.map (·.name)
  if names.eraseDups.length != names.length then err "request: duplicate checked word"
  let types ← decodeTypes
    (← array "request.erased_word_types" (← required "request" "erased_word_types" values))
  let typeNames := types.map (·.1)
  if typeNames.eraseDups.length != typeNames.length then err "request: duplicate erased word type"
  let (checked, counts) ← pairWords words types
  let entry ← match field "entry" values with
    | some value => nonempty "request.entry" =<< str "request.entry" value
    | none => match words with
      | [word] => pure word.name
      | _ => err "request.entry: required for multiple checked words"
  if !names.any (· == entry) then err s!"request.entry: unknown word {entry}"
  let source : Option Firth.Agent.Elaborate.Request ← match field "source" values with
    | none => pure none
    | some value =>
        let members ← object "source" value ["source_path", "source_text", "language_version"]
        if (← reqStr "source" "language_version" members) != Firth.Agent.Elaborate.languageVersion then
          err "source: unsupported language version"
        let sourcePath ← nonempty "source.source_path" =<< reqStr "source" "source_path" members
        let sourceText ← reqStr "source" "source_text" members
        pure (some { requestId, sourcePath, sourceText })
  pure { requestId, entry, words := checked, atomCounts := counts, source }

private def quote (value : String) : String := (Json.str value).compress

private def obj (values : List (String × String)) : String :=
  "{" ++ String.intercalate "," (values.map fun (key, value) => quote key ++ ":" ++ value) ++ "}"

private def arr (values : List String) : String :=
  "[" ++ String.intercalate "," values ++ "]"

private def number (value : Nat) : String := toString value

mutual

  private partial def valueJson : Target.Value → String
    | .int value =>
        obj [("kind", quote "int"), ("value", toString value)]
    | .bool value =>
        obj [("kind", quote "bool"), ("value", if value then "true" else "false")]
    | .bytes value =>
        obj [("kind", quote "bytes"), ("value", quote (Digest.toHex value))]
    | .quotation code captures consumed =>
        obj [("kind", quote "quotation"), ("code", codeJson code),
             ("captures", arr (valuesJson captures)),
             ("consumed", arr (consumed.map (fun flag => if flag then "true" else "false")))]
    | .primitiveValue tag value =>
        obj [("kind", quote "primitive"), ("tag", number tag),
             ("bytes", quote (Digest.toHex value))]
    | .world => obj [("kind", quote "world")]

  private partial def valuesJson : List Target.Value → List String
    | [] => []
    | value :: rest => valueJson value :: valuesJson rest

  private partial def instructionJson : Target.Instruction → String
    | .pushLiteral value => obj [("op", quote "push-literal"), ("literal", valueJson value)]
    | .pushQuote code captures consumed =>
        obj [("op", quote "push-quote"),
             ("quotation", obj [("kind", quote "quotation"), ("code", codeJson code),
               ("captures", arr (valuesJson captures)),
               ("consumed", arr (consumed.map (fun flag => if flag then "true" else "false")))])]
    | .pushCapture index => obj [("op", quote "push-capture"), ("index", number index)]
    | .dup => obj [("op", quote "dup")]
    | .drop => obj [("op", quote "drop")]
    | .swap => obj [("op", quote "swap")]
    | .call => obj [("op", quote "call")]
    | .dip => obj [("op", quote "dip")]
    | .compose => obj [("op", quote "compose")]
    | .quote => obj [("op", quote "quote")]
    | .ifThenElse => obj [("op", quote "if")]
    | .callWord name => obj [("op", quote "call-word"), ("name", quote name)]
    | .prim name => obj [("op", quote "prim"), ("primitive", quote name)]

  private partial def instructionsJson : List Target.Instruction → List String
    | [] => []
    | instruction :: rest => instructionJson instruction :: instructionsJson rest

  private partial def codeJson (code : List Target.Instruction) : String :=
    arr (instructionsJson code)

end

private def wordJson (word : Target.WordEntry) : String :=
  obj [("name", quote word.name),
       ("erased_word_type", quote word.erasedWordType),
       ("code", codeJson word.code),
       ("body_digest", quote (Digest.toHex (Target.bodyDigest word.code))),
       ("kernel_evidence_digest", quote (Digest.toHex word.kernelEvidenceDigest)),
       ("refinement_evidence_digest", quote (Digest.toHex word.refinementEvidenceDigest)),
       ("generation", number word.generation)]

/-- The debug metadata §5 asks for: every target instruction back to the
kernel atom it came from. The §3 table emits exactly one instruction per atom,
so the correspondence is by index within the word. -/
private def debugLocationsJson (source : String) (word : Target.WordEntry) : List String :=
  (List.range word.code.length).map fun index =>
    obj [("word", quote source), ("target_word", quote word.name),
         ("instruction", number index), ("kernel_atom", number index)]

private def verificationJson (source : Option Firth.Agent.Elaborate.Request) : String :=
  obj [("schema", quote "firth.compiler-verification.v1"),
    ("method", quote "kernel-type-and-linearity-recheck"),
    ("source_bound", if source.isSome then "true" else "false"),
    ("source_sha256", match source with
      | some request => quote (Digest.hexOfString request.sourceText)
      | none => "null"),
    ("gamma_version", quote gammaVersion), ("target_version", quote targetVersion),
    ("refinements", quote "not-checked"),
    ("image_evidence", quote "legacy-content-identifiers-not-authenticated-proofs")]


private def successJson (requestId : String) (entry : Target.WordEntry)
    (sources : List String) (words : List Target.WordEntry)
    (source : Option Firth.Agent.Elaborate.Request) : String :=
  let program :=
    obj [("format_version", number formatVersion),
         ("entry", quote entry.name),
         ("words", arr (words.map wordJson))]
  let digests :=
    obj ((sources.zip words).map fun (source, word) =>
      (source, quote (Digest.toHex (Target.bodyDigest word.code))))
  let debug := arr ((sources.zip words).flatMap fun (source, word) =>
    debugLocationsJson source word)
  obj [("request_id", quote requestId), ("status", quote "success"),
       ("target_program", program), ("word_digests", digests),
       ("debug_locations", debug), ("verification", verificationJson source)]

private def failureJson (requestId : String) (error : Lowering.CompileError) : String :=
  obj [("request_id", quote requestId), ("status", quote "failure"),
       ("compile_error", obj [("code", quote error.code), ("word", quote error.word),
         ("message", quote error.message)])]

/-- Re-elaborates exact source bytes without opening the diagnostic path.
This binds all bodies and types, including unused words, to what was actually
checked. A matching hash or public checking marker cannot substitute for it. -/
private def verifySource (request : Request) : Except String Unit := do
  match request.source with
  | none => pure ()
  | some source =>
      let input := obj [("request_id", quote request.requestId),
        ("source_path", quote source.sourcePath), ("source_text", quote source.sourceText),
        ("language_version", quote Firth.Agent.Elaborate.languageVersion),
        ("gamma_version", quote gammaVersion)]
      let response ← Firth.Agent.Elaborate.runRequest input
      let json ← Json.parse response
      let values ← fields "source elaboration" json
      if (← reqStr "source elaboration" "status" values) != "success" then
        err "source: elaboration failed; no source-bound artefact may be compiled"
      let checked ← required "source elaboration" "checked_words" values
      let types ← required "source elaboration" "erased_word_types" values
      let expected ← decodeRequest (← Json.parse (obj [
        ("request_id", quote request.requestId), ("entry", quote request.entry),
        ("checked_words", checked.compress), ("erased_word_types", types.compress),
        ("gamma_version", quote gammaVersion), ("target_version", quote targetVersion)]))
      if expected.words.length != request.words.length then
        err "source: checked dictionary mismatch"
      for word in request.words do
        match expected.words.find? (·.name == word.name) with
        | some expectedWord =>
            if word != expectedWord then err s!"source: body/type mismatch for {word.name}"
        | none => err s!"source: word not elaborated: {word.name}"


/-- Compiles one decoded request.

The entry is a source word name, not a target name or a position. Multiword
requests must select it explicitly. A single-word request may omit it for
backwards compatibility because its entry is unambiguous. -/
def compileRequest (request : Request) : Except String String := do
  verifySource request
  match Lowering.compileWords request.words with
  | .error error => pure (failureJson request.requestId error)
  | .ok entries =>
      if entries.length != request.atomCounts.length then
        err "internal: compiled word count does not match the request"
      else
        for (entry, atoms) in entries.zip request.atomCounts do
          if entry.code.length != atoms then
            err s!"internal: {entry.name} lowered {entry.code.length} instructions for {atoms} atoms"
        match (request.words.zip entries).find? (fun pair => pair.1.name == request.entry) with
        | none => err s!"request.entry: unknown word {request.entry}"
        | some (_, entry) =>
            pure (successJson request.requestId entry (request.words.map (·.name)) entries request.source)

private def validateJsonMembers (input : String) : Except String Unit :=
  match Firth.Agent.rejectDuplicateMembers input with
  | .ok () => pure ()
  | .error .duplicate => err "duplicate JSON member"
  | .error .malformed => err "malformed JSON"

/-- The whole adapter: request bytes in, response bytes out. -/
def runRequest (input : String) : Except String String := do
  validateJsonMembers input
  let json ← match Json.parse input with
    | .ok value => pure value
    | .error error => err s!"malformed JSON: {error}"
  compileRequest (← decodeRequest json)

/-- Renders a refusal in the same shape the reference-run adapter uses. -/
def errorJson (message : String) : String :=
  obj [("status", quote "error"), ("error", quote message)]

/-- The executable entry point: one request on stdin, one response on stdout. -/
def main (args : List String) : IO Unit := do
  if !args.isEmpty then throw <| IO.userError "firthCompile accepts stdin JSON only"
  let input ← (← IO.getStdin).readToEnd
  match runRequest input with
  | .ok value => IO.println value
  | .error error =>
      IO.eprintln (errorJson error)
      throw <| IO.userError error

end Firth.Compiler.Compile
