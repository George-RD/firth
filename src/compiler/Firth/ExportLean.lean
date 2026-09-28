import Lean.Data.Json
import compiler.Firth.Compile

/-!
Exporting a Firth source's erased kernel programs as a Lean module.

A proof about a Firth word has to be about the program the VM runs, not about
a hand-written model of it. This file turns one source file into a Lean module
that defines, for every word, the kernel `Program` the elaborator checked and
the compiler lowered, next to the `body_digest` the compiler put in the image.

The pipeline is the one the compile adapter's source binding already uses:
elaborate the source (`Firth.Agent.Elaborate.runRequest`), decode the checked
dictionary with the compile adapter's own decoder, and pass it through
`Lowering.compileWords`, which rechecks every body's type and ownership. A
source that fails any of those steps exports nothing.

Two checks keep the module honest after it is checked in:

* `tools/loop/update_kernel_exports.py --check` regenerates every module from
  its source and fails on any difference, so an edit to a source, to the
  elaborator or to erasure cannot leave a stale export behind.
* `FirthExportsTest` lowers each exported `body` again with `Lowering.bodyDigest`
  and fails unless it hashes to the recorded `bodyDigest`, so the Lean term
  itself, not only its text, is bound to the image's digest.

The module states nothing about the program. It is the input to proofs, not a
proof.
-/

namespace Firth.Compiler.ExportLean
open Lean (Json)
open Firth.Interpreter

private def err (message : String) : Except String α := .error message

private def quote (value : String) : String := (Json.str value).compress

/-- A Lean term for an integer, parenthesised when negative so it can stand as
an argument. -/
private def intTerm (value : Int) : String :=
  if value < 0 then s!"({value})" else toString value

private def listTerm (items : List String) : String :=
  "[" ++ ", ".intercalate items ++ "]"

private def literalTerm : Literal → String
  | .int value => s!"(.int {intTerm value})"
  | .bool value => s!"(.bool {value})"
  | .unit => ".unit"
  | .intSeq values => s!"(.intSeq {listTerm (values.map intTerm)})"
  | .boolSeq values => s!"(.boolSeq {listTerm (values.map toString)})"

private def usageTerm : Usage → String
  | .many => ".many"
  | .linear => ".linear"

private def atomsOf : Program → List Atom
  | .empty => []
  | .cons head tail => head :: atomsOf tail

mutual
  /-- A program as a right-nested `.cons` chain, one atom per line, so that the
  term is structurally the `Program` value and a diff of two exports reads
  atom by atom. `indent` is the column the chain's atoms start at. -/
  partial def programTerm (indent : Nat) : Program → String
    | .empty => ".empty"
    | program =>
        let atoms := atomsOf program
        let pad := "".pushn ' ' indent
        let lines := atoms.map fun atom => pad ++ s!".cons {atomTerm (indent + 2) atom} <|"
        "\n" ++ "\n".intercalate lines ++ "\n" ++ pad ++ ".empty"

  private partial def valueTerm (indent : Nat) : Value → String
    | .literal literal => s!"(.literal {literalTerm literal})"
    | .quotation body usage => s!"(.quotation ({programTerm indent body}) {usageTerm usage})"
    | .world id => s!"(.world {id})"

  private partial def atomTerm (indent : Nat) : Atom → String
    | .lit literal => s!"(.lit {literalTerm literal})"
    | .push value => s!"(.push {valueTerm indent value})"
    | .quotation body => s!"(.quotation ({programTerm indent body}))"
    | .dup => ".dup"
    | .drop => ".drop"
    | .swap => ".swap"
    | .dip => ".dip"
    | .call => ".call"
    | .compose => ".compose"
    | .quote => ".quote"
    | .ifThenElse => ".ifThenElse"
    | .pick depth => s!"(.pick {depth})"
    | .roll depth => s!"(.roll {depth})"
    | .word name => s!"(.word {quote name})"
    | .prim name => s!"(.prim {quote name})"
end

/-- A word name as one Lean identifier component. Surface names such as
`allocate-from` are not Lean identifiers, so every name is written between
French quotes, which the Lean lexer reads verbatim. A name that could not be
written that way is refused rather than rewritten, because two words must
never share an export name. -/
private def identifier (name : String) : Except String String :=
  if name.any (fun c => c == '«' || c == '»' || c == '\n' || c == '\r' || c == '\t') then
    err s!"word name cannot be written as a Lean identifier: {name}"
  else pure s!"«{name}»"

/-- A Lean module name: dot-separated components, each an ASCII identifier
starting with an upper-case letter, as the files under `src/exports/` use. -/
private def validModule (name : String) : Bool :=
  let parts := name.splitOn "."
  !parts.isEmpty && parts.all fun part =>
    match part.toList with
    | first :: rest => first.isUpper && rest.all (fun c => c.isAlphanum || c == '_')
    | [] => false

/-- One exported word. -/
structure ExportedWord where
  name : String
  program : Program
  erasedType : String
  bodyDigest : String

/-- Elaborates `sourceText` and accepts its dictionary exactly as the compile
adapter's source binding does, returning every word in declaration order. -/
def exportedWords (sourcePath sourceText : String) : Except String (List ExportedWord) := do
  let request := Json.mkObj [("request_id", "kernel-export"), ("source_path", sourcePath),
    ("source_text", sourceText),
    ("language_version", Firth.Agent.Elaborate.languageVersion),
    ("gamma_version", Compile.gammaVersion)]
  let response ← Json.parse (← Firth.Agent.Elaborate.runRequest request.compress)
  if response.getObjValD "status" != "success" then
    err s!"{sourcePath}: elaboration failed; nothing is exported\n{response.compress}"
  let checked := response.getObjValD "checked_words"
  -- The compile request names an entry word; an export covers every word, so
  -- any member of the dictionary will do and the first is used.
  let entry := match checked.getArrVal? 0 with
    | .ok first => first.getObjValD "name"
    | .error _ => Json.null
  let decoded ← Compile.decodeRequest (Json.mkObj [("request_id", "kernel-export"),
    ("entry", entry), ("checked_words", checked),
    ("erased_word_types", response.getObjValD "erased_word_types"),
    ("gamma_version", Compile.gammaVersion), ("target_version", Compile.targetVersion)])
  match Lowering.compileWords decoded.words with
  | .error error => err s!"{sourcePath}: compile admission failed: {error.message}"
  | .ok entries =>
      if entries.length != decoded.words.length then
        err "internal: compiled word count does not match the dictionary"
      pure ((decoded.words.zip entries).map fun (word, entry) =>
        { name := word.name, program := word.program, erasedType := entry.erasedWordType,
          bodyDigest := Digest.toHex (Target.bodyDigest entry.code) })

/-- The generated module for `sourcePath`, whose contents are `sourceText`. -/
def exportModule (sourcePath sourceText moduleName : String) : Except String String := do
  if !validModule moduleName then err s!"invalid export module name: {moduleName}"
  let words ← exportedWords sourcePath sourceText
  let mut sections : List String := []
  let mut dictionary : List String := []
  let mut listed : List String := []
  let mut entries : List String := []
  for word in words do
    let ident ← identifier word.name
    sections := sections ++ [s!"namespace {ident}

/-- The erased kernel program of `{word.name}`. -/
def body : Program :={programTerm 2 word.program}

/-- The image's `body_digest` for `{word.name}`: SHA-256 of `body` lowered to
target code, hex encoded. -/
def bodyDigest : String := {quote word.bodyDigest}

/-- The erased word type the image records for `{word.name}`. -/
def erasedType : String := {quote word.erasedType}

end {ident}
"]
    dictionary := dictionary ++ [s!"  | {quote word.name} => some \{ type := adapterWordType, body := {ident}.body }"]
    entries := entries ++ [s!"theorem {ident}.entry :
    dictionary {quote word.name} = some \{ type := adapterWordType, body := {ident}.body } := rfl
"]
    listed := listed ++ [s!"  ({quote word.name}, {ident}.body, {ident}.bodyDigest)"]
  let namespaceName := s!"Firth.Exports.{moduleName}"
  pure s!"import FirthReferenceRun

/-!
Generated by `lake exe firthExportLean` from `{sourcePath}`. Do not edit:
`python3 tools/loop/update_kernel_exports.py` regenerates it, and CI fails when
this file differs from what the elaborator produces from that source.

Each word's `body` is the erased kernel program the elaborator checked and the
compiler accepted, and `bodyDigest` is the `body_digest` of that program in the
VM image. `FirthExportsTest` lowers every `body` again and fails unless it
hashes to `bodyDigest`.

`dictionary`, `Firth.ReferenceRun.adapterGamma` and `defaultCosts` are exactly
what the reference runner executes these words with.
-/

namespace {namespaceName}
open Firth.Interpreter
open Firth.ReferenceRun

/-- SHA-256 of the source text these definitions were generated from. -/
def sourceDigest : String := {quote (Digest.hexOfString sourceText)}

{"\n".intercalate sections}
/-- Every word, in declaration order: its name, body and body digest. -/
def words : List (String × Program × String) := [
{",\n".intercalate listed}]

/-- The dictionary the reference runner builds for this source. -/
def dictionary : Dictionary
{"\n".intercalate dictionary}
  | _ => none

/-! Each word's dictionary entry, which a proof unfolding a call to it needs. -/

{"\n".intercalate entries}
end {namespaceName}
"

/-- `firthExportLean SOURCE MODULE`: prints the module for `SOURCE`. -/
def main (args : List String) : IO UInt32 := do
  match args with
  | [sourcePath, moduleName] =>
      let sourceText ← IO.FS.readFile sourcePath
      match exportModule sourcePath sourceText moduleName with
      | .ok text =>
          IO.print text
          pure 0
      | .error message =>
          IO.eprintln message
          pure 1
  | _ =>
      IO.eprintln "usage: firthExportLean SOURCE MODULE"
      pure 2

end Firth.Compiler.ExportLean
