import compiler.Firth.ExportLean
import exports.All

/-!
Checks that every kernel export under `src/exports/` is bound to its source
and to the VM image.

For each exported word this lowers the Lean `body` term again with
`Lowering.bodyDigest` and requires the recorded `bodyDigest`, then
re-elaborates the source and requires the elaborator's program to equal the
Lean term structurally. The first ties the definition a proof would mention to
the image's digest; the second catches a rendering that would print stably but
denote a different program.
-/

namespace Firth.ExportsTest

open Firth.Compiler
open Firth.Interpreter

private def fail (message : String) : IO Unit := throw <| IO.userError message

private def digestOf (names : List String) (name : String) (program : Program) :
    Except String String :=
  match Lowering.bodyDigest names name program with
  | .ok digest => .ok (Digest.toHex digest)
  | .error error => .error error.message

private def checkModule (module source : String)
    (words : List (String × Program × String × String)) :
    IO Unit := do
  let names := words.map (·.1)
  if words.isEmpty then fail s!"{module}: exports no words"
  for (name, program, digest, _) in words do
    match digestOf names name program with
    | .error message => fail s!"{module}.{name}: does not lower: {message}"
    | .ok actual =>
        if actual != digest then
          fail s!"{module}.{name}: body lowers to {actual}, recorded {digest}"
  let sourceText ← IO.FS.readFile source
  match ExportLean.exportedWords source sourceText with
  | .error message => fail s!"{module}: {source} no longer exports: {message}"
  | .ok fresh =>
      if fresh.map (·.name) != names then
        fail s!"{module}: {source} now defines {fresh.map (·.name)}, exported {names}"
      for (word, (_, program, digest, erasedType)) in fresh.zip words do
        if word.program != program then
          fail s!"{module}.{word.name}: the Lean body differs from the elaborator's program"
        if word.bodyDigest != digest then
          fail s!"{module}.{word.name}: the source now compiles to {word.bodyDigest}"
        if word.erasedType != erasedType then
          fail s!"{module}.{word.name}: the source now has erased type {word.erasedType}"

/-- The check must be able to fail: one changed atom changes the digest. -/
private def checkDigestSeesEdits : IO Unit := do
  let names := Firth.Exports.Programs.Fib.words.map (·.1)
  let edited : Program := .cons .drop Firth.Exports.Programs.Fib.«fib».body
  match digestOf names "fib" edited with
  | .ok digest =>
      if digest == Firth.Exports.Programs.Fib.«fib».bodyDigest then
        fail "an edited body kept the recorded digest"
  | .error message => fail s!"edited body did not lower: {message}"

/-- The exported dictionary runs under the reference runner's registry. -/
private def checkRuns : IO Unit := do
  let config : Config :=
    { stack := [.literal (.int 20)], program := .cons (.word "fib") .empty }
  match run Firth.ReferenceRun.adapterGamma Firth.Exports.Programs.Fib.dictionary defaultCosts
      100000 config with
  | .terminal final _ _ =>
      if final.stack != [.literal (.int 6765)] then
        fail s!"fib 20 from the export left {repr final.stack}"
  | _ => fail "fib 20 from the export did not terminate"

def main : IO Unit := do
  if Firth.Exports.all.isEmpty then fail "no kernel exports"
  for (module, source, words) in Firth.Exports.all do
    checkModule module source words
  checkDigestSeesEdits
  checkRuns
  IO.println s!"kernel exports: {Firth.Exports.all.length} modules bound to their sources and digests"

end Firth.ExportsTest

def main : IO Unit := Firth.ExportsTest.main
