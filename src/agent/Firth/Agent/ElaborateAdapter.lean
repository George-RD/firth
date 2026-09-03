import Lean.Data.Json
import agent.Firth.Agent.ElaboratorDiagnostics
import agent.Firth.Agent.JsonMembers

/-!
The `firth.elaborate.v1` adapter: one `firth.source.v1` request in, one
`firth.elaboration.v1` response out, as pinned by
`tools/loop/mvp_agent_manifest.toml`.

This is the entry point the MVP gate elaborates an application through. Its
output is shaped to be joined, not reconstructed: `checked_words` and
`erased_word_types` are byte-compatible with the `firth.checked-kernel.v1`
request the compile adapter accepts, and `kernel_programs` carries the
programs the reference-run request needs. The gate therefore hands one
adapter's output to the next rather than building records of its own, which is
where drift between two hand-written encoders would otherwise creep in.

Failure emits the versioned diagnostic envelopes of
`dec.agent-diagnostic-envelope` through `Firth.Agent.elaboratePipeline`, which
already sorts them. Nothing here prints a Lean representation.

The manifest's `[gamma]` primitives are resolved into the elaborator's
environments, so a source using `prim +` elaborates. `send` is declared with
its `World`-threading effect for the same reason: the language has it, and the
compiler refusing to lower it is a separate, honest fact about the v0.1
target.
-/

namespace Firth.Agent.Elaborate

open Lean
open Firth.Elaborator
open Firth.Elaborator.StackEffect

/-- The language version this adapter speaks. -/
def languageVersion : String := "0.1"

/-- The `Gamma` version this adapter speaks. -/
def gammaVersion : String := "0.1"

private def err (message : String) : Except String α := .error message

private def fields (context : String) : Json → Except String (List (String × Json))
  | .obj values => pure values.toList
  | _ => err s!"{context}: expected object"

private def field (name : String) : List (String × Json) → Option Json
  | [] => none
  | (key, value) :: rest => if key == name then some value else field name rest

private def object (context : String) (value : Json) (allowed : List String) :
    Except String (List (String × Json)) := do
  let values ← fields context value
  if values.any (fun (key, _) => !allowed.any (· == key)) then
    err s!"{context}: unknown member"
  else if allowed.any (fun key => (field key values).isNone) then
    err s!"{context}: missing member"
  else pure values

private def reqStr (context name : String) (values : List (String × Json)) :
    Except String String :=
  match field name values with
  | some (.str value) => pure value
  | some _ => err s!"{context}.{name}: expected string"
  | none => err s!"{context}: missing {name}"

private def nonempty (context value : String) : Except String String :=
  if value.isEmpty then err s!"{context}: empty string" else pure value

/-- One decoded `firth.source.v1` request. -/
structure Request where
  requestId : String
  sourcePath : String
  sourceText : String

/-- Decodes a `firth.source.v1` request. -/
def decodeRequest (value : Json) : Except String Request := do
  let values ← object "request" value
    ["request_id", "source_path", "source_text", "language_version", "gamma_version"]
  if (← reqStr "request" "language_version" values) != languageVersion then
    err "request: unsupported language version"
  if (← reqStr "request" "gamma_version" values) != gammaVersion then
    err "request: unsupported gamma version"
  pure { requestId := ← nonempty "request.request_id" =<< reqStr "request" "request_id" values
         sourcePath := ← nonempty "request.source_path" =<< reqStr "request" "source_path" values
         sourceText := ← reqStr "request" "source_text" values }

private def rowTail : AStack := .row (.rigid "ρ")

private def intMany : AType := .base "Int" .many

/-- The manifest's `[gamma.primitive]` table, as the elaborator's erasure
signature. Only the ownership classes matter at erasure time. -/
def gammaErasure : EffectEnv :=
  { primitive := fun name =>
      if name == "+" then some { input := [.many, .many], output := [.many] }
      else if name == "send" then some { input := [.linear, .linear, .linear], output := [.linear] }
      else none }

/-- The same table as a typing scheme. `+` is row polymorphic over two `Int`s;
`send` threads one linear `World` past a `Handle` and a `Bytes`. -/
def gammaTyping : Env :=
  { literal := defaultLiteralType
    primitive := fun name =>
      if name == "+" then
        some { rowVariables := ["ρ"]
               input := .snoc (.snoc rowTail intMany) intMany
               output := .snoc rowTail intMany }
      else if name == "send" then
        some { rowVariables := ["ρ"]
               input := .snoc (.snoc (.snoc rowTail (.base "World" .linear))
                 (.base "Handle" .linear)) (.base "Bytes" .linear)
               output := .snoc rowTail (.base "World" .linear) }
      else none }

private def quote (value : String) : String := (Json.str value).compress

private def obj (values : List (String × String)) : String :=
  "{" ++ String.intercalate "," (values.map fun (key, value) => quote key ++ ":" ++ value) ++ "}"

private def arr (values : List String) : String :=
  "[" ++ String.intercalate "," values ++ "]"

private def number (value : Nat) : String := toString value

mutual

  private def programJson : Firth.Interpreter.Program → String
    | .empty => arr []
    | .cons head tail => arr (atomJson head :: atomsJson tail)

  private def atomsJson : Firth.Interpreter.Program → List String
    | .empty => []
    | .cons head tail => atomJson head :: atomsJson tail

  private def atomJson : Firth.Interpreter.Atom → String
    | .lit value => obj [("kind", quote "lit"), ("value", literalJson value)]
    | .push value => obj [("kind", quote "push"), ("value", valueJson value)]
    | .quotation body => obj [("kind", quote "quotation"), ("body", programJson body)]
    | .dup => obj [("kind", quote "dup")]
    | .drop => obj [("kind", quote "drop")]
    | .swap => obj [("kind", quote "swap")]
    | .dip => obj [("kind", quote "dip")]
    | .call => obj [("kind", quote "call")]
    | .compose => obj [("kind", quote "compose")]
    | .quote => obj [("kind", quote "quote")]
    | .ifThenElse => obj [("kind", quote "if")]
    | .word name => obj [("kind", quote "word"), ("name", quote name)]
    | .prim name => obj [("kind", quote "prim"), ("name", quote name)]

  private def literalJson : Firth.Interpreter.Literal → String
    | .nat value => obj [("type", quote "nat"), ("value", number value)]
    | .bool value => obj [("type", quote "bool"), ("value", if value then "true" else "false")]
    | .unit => obj [("type", quote "unit")]

  private def valueJson : Firth.Interpreter.Value → String
    | .literal value => obj [("kind", quote "literal"), ("literal", literalJson value)]
    | .quotation body usage =>
        obj [("kind", quote "quotation"), ("body", programJson body),
             ("usage", quote (match usage with | .many => "many" | .linear => "linear"))]
    | .world id => obj [("kind", quote "world"), ("id", number id)]

end

/-- The kernel program of a located kernel sequence, in source order. -/
private def kernelProgram (program : KernelProgram) : Firth.Interpreter.Program :=
  program.foldr (fun located rest => .cons located.atom rest) .empty

private def usageJson : AUsage → Except String String
  | .many => pure (quote "many")
  | .linear => pure (quote "linear")
  | .mvar _ => err "unresolved usage variable"
  | .meet left right => do
      -- `usageMeet` is linear unless both sides are many, so a meet is
      -- resolvable exactly when neither side is still a variable.
      match ← usageJson left, ← usageJson right with
      | a, b => pure (if a == quote "many" && b == quote "many" then quote "many" else quote "linear")

mutual

  private partial def typeJson : AType → Except String String
    | .base name usage => do
        pure (obj [("kind", quote "base"), ("name", quote name), ("usage", ← usageJson usage)])
    | .quotation input output usage => do
        pure (obj [("kind", quote "quotation"), ("input", ← stackJson input),
                   ("output", ← stackJson output), ("usage", ← usageJson usage)])
    | .mvar _ _ => err "unresolved type variable"

  /-- Flattens the `snoc` spine into bottom-to-top order, which is the order
  the canonical target grammar writes stack items in. -/
  private partial def stackItems : AStack → Except String (Option String × List String)
    | .empty => pure (none, [])
    | .row (.rigid name) => pure (some name, [])
    | .row (.mvar _) => err "unresolved row variable"
    | .snoc rest value => do
        let (row, items) ← stackItems rest
        pure (row, items ++ [← typeJson value])

  private partial def stackJson (stack : AStack) : Except String String := do
    let (row, items) ← stackItems stack
    pure (obj [("row", match row with | none => "null" | some name => quote name),
               ("items", arr items)])

end

private def schemeJson (scheme : Scheme) : Except String String := do
  pure (obj [("row_variables", arr (scheme.rowVariables.map quote)),
             ("input", ← stackJson scheme.input),
             ("output", ← stackJson scheme.output)])

private def spanJson (span : Span) : String :=
  obj [("start", obj [("line", number span.start.line), ("column", number span.start.column)]),
       ("end", obj [("line", number span.stop.line), ("column", number span.stop.column)])]

private def warningsJson (word : CheckedWord) : List String :=
  word.warnings.map fun warning =>
    obj [("word", quote word.name), ("code", quote warning.code),
         ("range", spanJson warning.span)]

/-- Renders a successful elaboration.

`checked_words` carries the evidence markers the compile and reference-run
adapters require, so its entries are usable verbatim as their request
members. -/
def successJson (request : Request) (program : CheckedProgram) : Except String String := do
  let mut checked : List String := []
  let mut erased : List String := []
  let mut kernels : List String := []
  let mut warnings : List String := []
  for word in program.words do
    let body := kernelProgram word.program
    checked := checked ++ [obj [("name", quote word.name),
      ("checking_state", quote "checked"), ("proof_state", quote "available"),
      ("program", programJson body)]]
    erased := erased ++ [obj [("word", quote word.name), ("type", ← schemeJson word.scheme)]]
    kernels := kernels ++ [obj [("word", quote word.name), ("program", programJson body)]]
    warnings := warnings ++ warningsJson word
  pure (obj [("request_id", quote request.requestId), ("status", quote "success"),
             ("checked_words", arr checked), ("erased_word_types", arr erased),
             ("kernel_programs", arr kernels), ("warnings", arr warnings)])

private def failureJson (request : Request) (diagnostics : List Envelope) : String :=
  obj [("request_id", quote request.requestId), ("status", quote "failure"),
       ("diagnostics", arr (diagnostics.map encode))]

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
  let request ← decodeRequest json
  let context : EmissionContext :=
    { payloadId := request.requestId ++ ".elaborate"
      requestId := request.requestId
      source := .path request.sourcePath }
  let config : PipelineConfig :=
    { erasureEnv := gammaErasure
      typingEnv := gammaTyping
      requestId := request.requestId
      sourcePath := request.sourcePath }
  match elaboratePipeline context request.sourceText config with
  | .success program => successJson request program
  | .failure diagnostics => pure (failureJson request diagnostics)

/-- Renders a refusal in the same shape the other adapters use. -/
def errorJson (message : String) : String :=
  obj [("status", quote "error"), ("error", quote message)]

/-- The executable entry point: one request on stdin, one response on stdout. -/
def main (args : List String) : IO Unit := do
  if !args.isEmpty then throw <| IO.userError "firthElaborate accepts stdin JSON only"
  let input ← (← IO.getStdin).readToEnd
  match runRequest input with
  | .ok value => IO.println value
  | .error error =>
      IO.eprintln (errorJson error)
      throw <| IO.userError error

end Firth.Agent.Elaborate
