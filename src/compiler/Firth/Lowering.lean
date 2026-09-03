import Firth.Interpreter
import compiler.Firth.Target
import compiler.Firth.WordType

/-!
Total, deterministic lowering of a checked kernel program into target code.

`src/runtime/vm/target-spec.md` §3 gives the lowering table and states that it
is total over the frozen atom grammar. This file implements exactly that table
and nothing else: concatenation lowers by concatenating, an empty program
lowers to an empty sequence, and every atom maps to the single instruction
sequence the table names.

Three things the table cannot cover are refused rather than approximated,
because the alternative is putting a claim into an image that the checked
program never made:

* the `unit` literal, which has no value in the v0.1 target algebra (§2);
* a `World` value pushed as data, since the frozen kernel says the token
  compiles to nothing and it is never a target value;
* a primitive with no entry in the target registry.

Names are mangled because the two grammars differ. Firth surface words may
contain characters such as `-` that the frozen target `Name` grammar
(`[A-Za-z_][A-Za-z0-9_]*`) excludes, so `literal-int` cannot be a target word
name as written.
-/

namespace Firth.Compiler.Lowering

open Firth.Interpreter

/-- Why a checked program could not be lowered. Every case is a refusal that
names the word it came from, so a caller can report it against a source. -/
inductive CompileError where
  /-- A literal with no v0.1 target representation. -/
  | unsupportedLiteral (word : String) (detail : String)
  /-- A value with no v0.1 target representation. -/
  | unsupportedValue (word : String) (detail : String)
  /-- A dictionary word the request never defined. -/
  | unknownWord (word : String) (name : String)
  /-- A primitive outside the language registry. -/
  | unknownPrimitive (word : String) (name : String)
  /-- A declared primitive with no target implementation yet. -/
  | unsupportedPrimitive (word : String) (name : String)
  /-- A source name that cannot be mangled into a target name. -/
  | invalidName (word : String) (detail : String)
  /-- Two words that mangle to the same target name. -/
  | collidingName (word : String) (name : String)
  /-- An erased word type that could not be rendered canonically. -/
  | invalidWordType (word : String) (detail : String)
  deriving Repr, BEq

/-- The stable code a refusal reports on the wire. -/
def CompileError.code : CompileError → String
  | .unsupportedLiteral .. => "firth.compile.unsupported-literal"
  | .unsupportedValue .. => "firth.compile.unsupported-value"
  | .unknownWord .. => "firth.compile.unknown-word"
  | .unknownPrimitive .. => "firth.compile.unknown-primitive"
  | .unsupportedPrimitive .. => "firth.compile.unsupported-primitive"
  | .invalidName .. => "firth.compile.invalid-name"
  | .collidingName .. => "firth.compile.colliding-name"
  | .invalidWordType .. => "firth.compile.invalid-word-type"

/-- The word a refusal came from. -/
def CompileError.word : CompileError → String
  | .unsupportedLiteral word _ | .unsupportedValue word _
  | .unknownWord word _ | .unknownPrimitive word _
  | .unsupportedPrimitive word _ | .invalidName word _
  | .collidingName word _ | .invalidWordType word _ => word

/-- A deterministic message naming what was refused. -/
def CompileError.message : CompileError → String
  | .unsupportedLiteral _ detail => s!"literal has no v0.1 target representation: {detail}"
  | .unsupportedValue _ detail => s!"value has no v0.1 target representation: {detail}"
  | .unknownWord _ name => s!"unknown dictionary word: {name}"
  | .unknownPrimitive _ name => s!"unknown primitive: {name}"
  | .unsupportedPrimitive _ name => s!"primitive has no v0.1 target implementation: {name}"
  | .invalidName _ detail => s!"name cannot be mangled into a target name: {detail}"
  | .collidingName _ name => s!"two source words mangle to the same target name: {name}"
  | .invalidWordType _ detail => s!"erased word type is not canonical: {detail}"

private def hexDigits : Array Char :=
  #['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

private def isTargetAlpha (byte : UInt8) : Bool :=
  (65 ≤ byte && byte ≤ 90) || (97 ≤ byte && byte ≤ 122)

private def isTargetDigit (byte : UInt8) : Bool := 48 ≤ byte && byte ≤ 57

/-- Mangles one source byte into target-name characters.

The mapping is injective by construction: an underscore in the result is
always a tag prefix, never a source underscore, so no two distinct source
names can produce the same target name. `_` becomes `_u`, `-` becomes `_h`,
and every other byte becomes `_x` followed by two lowercase hex digits. -/
private def mangleByte (byte : UInt8) : String :=
  if isTargetAlpha byte || isTargetDigit byte then
    String.singleton (Char.ofNat byte.toNat)
  else if byte == 95 then "_u"
  else if byte == 45 then "_h"
  else
    "_x" ++ String.singleton hexDigits[byte.toNat / 16]!
      ++ String.singleton hexDigits[byte.toNat % 16]!

/-- Maps a Firth surface word name onto a canonical target word name.

A mangled name that would start with a digit is prefixed with `_d`, which no
mangled source name can otherwise produce, so injectivity survives the fix. -/
def mangle (name : String) : Except String String := Id.run do
  let bytes := name.toUTF8
  if bytes.size == 0 then return .error "empty name"
  let mut mangled := ""
  for index in [0:bytes.size] do
    mangled := mangled ++ mangleByte (bytes.get! index)
  if isTargetDigit (bytes.get! 0) then
    mangled := "_d" ++ mangled
  return .ok mangled

/-- The target primitive implementing a language primitive.

The language registry pinned by `tools/loop/mvp_agent_manifest.toml` declares
`+` and `send`. `+` is the target's `addNat`; `send` is declared but has no
v0.1 target implementation, so it is refused here rather than lowered to
something that would run. This registry deliberately matches the reference
interpreter's adapter registry, so the two hosts accept exactly the same
programs. -/
def targetPrimitive (name : String) : Option (Option String) :=
  if name == "+" then some (some "addNat")
  else if name == "send" then some none
  else none

/-- The lowering environment: the word being lowered, for error attribution,
and the mangled name of every word the request defines. -/
structure Context where
  word : String
  words : List (String × String)
  deriving Repr

private def resolveWord (context : Context) (name : String) : Except CompileError String :=
  match context.words.find? (fun entry => entry.1 == name) with
  | some entry => .ok entry.2
  | none => .error (.unknownWord context.word name)

private def lowerLiteral (context : Context) : Literal → Except CompileError Target.Value
  | .nat value =>
      -- The target integer is a signed 64-bit value (§2).
      if value ≤ 9223372036854775807 then .ok (.int (Int.ofNat value))
      else .error (.unsupportedLiteral context.word s!"nat literal exceeds the target integer: {value}")
  | .bool value => .ok (.bool value)
  | .unit => .error (.unsupportedLiteral context.word "unit")

mutual

/-- `lower(p)` for a kernel program, per the §3 table. -/
partial def lowerProgram (context : Context) :
    Firth.Interpreter.Program → Except CompileError (List Target.Instruction)
  | .empty => .ok []
  | .cons head tail => do
      let first ← lowerAtom context head
      let rest ← lowerProgram context tail
      pure (first ++ rest)

private partial def lowerValue (context : Context) :
    Firth.Interpreter.Value → Except CompileError Target.Value
  | .literal value => lowerLiteral context value
  | .quotation body _ => do
      let code ← lowerProgram context body
      pure (.quotation code [] [])
  | .world _ =>
      .error (.unsupportedValue context.word "World is administrative and compiles to nothing")

private partial def lowerAtom (context : Context) :
    Atom → Except CompileError (List Target.Instruction) := fun atom =>
  match atom with
  | .lit value => do pure [.pushLiteral (← lowerLiteral context value)]
  | .push value => do
      match ← lowerValue context value with
      | .quotation code captures consumed => pure [.pushQuote code captures consumed]
      | literal => pure [.pushLiteral literal]
  | .quotation body => do pure [.pushQuote (← lowerProgram context body) [] []]
  | .dup => .ok [.dup]
  | .drop => .ok [.drop]
  | .swap => .ok [.swap]
  | .dip => .ok [.dip]
  | .call => .ok [.call]
  | .compose => .ok [.compose]
  | .quote => .ok [.quote]
  | .ifThenElse => .ok [.ifThenElse]
  | .word name => do pure [.callWord (← resolveWord context name)]
  | .prim name =>
      match targetPrimitive name with
      | none => .error (.unknownPrimitive context.word name)
      | some none => .error (.unsupportedPrimitive context.word name)
      | some (some target) => .ok [.prim target]

end

/-- One checked word as the compiler receives it. -/
structure CheckedWord where
  name : String
  scheme : WordType.Scheme
  program : Firth.Interpreter.Program

/-- Builds the source-to-target name map, refusing an unmanglable or colliding
name before any lowering happens. -/
def nameMap (words : List CheckedWord) : Except CompileError (List (String × String)) := do
  let mut mapping : List (String × String) := []
  for word in words do
    match mangle word.name with
    | .error detail => throw (.invalidName word.name detail)
    | .ok mangled =>
        if mapping.any (fun entry => entry.2 == mangled) then
          throw (.collidingName word.name mangled)
        mapping := mapping ++ [(word.name, mangled)]
  pure mapping

/-- Lowers every checked word into a target word entry.

`kernelEvidenceDigest` binds the canonical encoding of the word's kernel
program and `refinementEvidenceDigest` binds its erased word type. §7 leaves
both payloads to the elaborator boundary and the VM only checks that neither
is all zero, so binding them to the artefacts this compiler actually saw is
the strongest statement it can make on its own. -/
def compileWords (words : List CheckedWord) : Except CompileError (List Target.WordEntry) := do
  let mapping ← nameMap words
  let mut entries : List Target.WordEntry := []
  for word in words do
    let context : Context := { word := word.name, words := mapping }
    let code ← lowerProgram context word.program
    let erased ←
      match WordType.render word.scheme with
      | .error detail => throw (.invalidWordType word.name detail)
      | .ok rendered => pure rendered
    let target ←
      match mapping.find? (fun entry => entry.1 == word.name) with
      | some entry => pure entry.2
      | none => throw (.invalidName word.name "name was not mapped")
    entries := entries ++ [{
      name := target
      erasedWordType := erased
      code
      kernelEvidenceDigest := Digest.sha256 (Target.canonicalCode code)
      refinementEvidenceDigest := Digest.sha256 erased.toUTF8
      generation := 0 }]
  pure entries

end Firth.Compiler.Lowering
