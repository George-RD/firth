import elaborator.Firth.Erasure

open Firth.Elaborator
open Firth.Interpreter

private def fail {α : Type} (message : String) : IO α := throw <| IO.userError message

private def parsed (source : String) : IO WordDefinition :=
  match parse source with
  | .success { declarations := [.word word], .. } => pure word
  | other => fail s!"expected one word, got {repr other}"

private def atomTag : LocatedKernel → String
  | { atom := .dup, .. } => "dup"
  | { atom := .drop, .. } => "drop"
  | { atom := .swap, .. } => "swap"
  | { atom := .dip, .. } => "dip"
  | { atom := .prim name, .. } => "prim:" ++ name
  | { atom := .word name, .. } => "word:" ++ name
  | { atom := .quotation _, .. } => "quotation"
  | { atom := .lit _, .. } => "lit"
  | { atom := .quote, .. } => "quote"
  | { atom := .call, .. } => "call"
  | { atom := .compose, .. } => "compose"
  | { atom := .ifThenElse, .. } => "if"
  | { atom := .push _, .. } => "push"

private def arithmetic : EffectEnv :=
  { primitive := fun name => if name == "+" then some { input := [.many, .many], output := [.many] } else none }

private def expectAtoms (word : WordDefinition) (expected : List String) : IO Unit :=
  match erase arithmetic word.effect word.body with
  | .ok result =>
      let actual := result.program.map atomTag
      if actual != expected then fail s!"atoms mismatch: {repr actual} != {repr expected}" else pure ()
  | .error error => fail s!"unexpected erasure error: {repr error}"

private def expectError (source : String) (expected : ErasureError → Bool) : IO Unit := do
  let word ← parsed source
  match erase arithmetic word.effect word.body with
  | .error error => if expected error then pure () else fail s!"wrong error: {repr error}"
  | .ok _ => fail "expected erasure failure"

def main : IO Unit := do
  let add ← parsed ": add ( a:Int^many b:Int^many -- r:Int^many ) locals { a b } { a b prim + } ;"
  expectAtoms add ["swap", "swap", "prim:+"]

  let repeated ← parsed ": repeated ( a:Int^many -- ) locals { a } { a a a } ;"
  match erase arithmetic repeated.effect repeated.body with
  | .ok result =>
      let copies := result.program.countP (fun item => match item.atom with | .dup => true | _ => false)
      if copies == 2 then pure () else fail s!"expected two deterministic copies, got {copies}"
  | .error error => fail s!"repeated selection failed: {repr error}"

  let deepFocus ← parsed ": deep-focus ( a:Int^many b:Int^many c:Int^many -- ) locals { a b c } { a } ;"
  match erase arithmetic deepFocus.effect deepFocus.body with
  | .ok result =>
      if result.program.any (fun item => match item.atom with | .dip => true | _ => false) then pure () else fail "missing nested dip focus"
  | .error error => fail s!"nested focus failed: {repr error}"

  let quoted ← parsed ": quoted ( a:Int^many -- q:Quote^many ) locals { a } { [ 1 ] } ;"
  expectAtoms quoted ["quotation", "swap", "drop"]

  let shadow ← parsed ": shadow ( a:Int^many b:Int^many -- a:Int^many b:Int^many ) locals { a b } { locals { a } { a } } ;"
  match erase arithmetic shadow.effect shadow.body with
  | .ok _ => pure ()
  | .error error => fail s!"shadowing failed: {repr error}"

  let deterministic := erase arithmetic add.effect add.body
  if toString (repr deterministic) != toString (repr (erase arithmetic add.effect add.body)) then fail "erasure was not deterministic"

  expectError ": duplicate ( a:Int^many -- ) locals { a a } { a } ;" (fun error => match error with | .duplicateLocal name _ => name == "a" | _ => false)
  expectError ": unbound ( a:Int^many -- ) locals { a } { missing } ;" (fun error => match error with | .unboundLocal name _ => name == "missing" | _ => false)
  expectError ": capture ( a:Int^many -- ) locals { a } { [ a ] } ;" (fun error => match error with | .unsupportedCapture name _ => name == "a" | _ => false)
  expectError ": lin ( h:Handle^linear -- ) locals { h } { h h } ;" (fun error => match error with | .linearCopy name _ => name == "h" | _ => false)
  expectError ": unused-h ( h:Handle^linear -- ) locals { h } { } ;" (fun error => match error with | .linearUnused name _ => name == "h" | _ => false)

  let deep ← parsed ": deep ( a:Int^many b:Int^many c:Int^many d:Int^many e:Int^many -- ) locals { a b c d e } { } ;"
  match erase arithmetic deep.effect deep.body with
  | .ok result => if result.warnings.any (fun warning => warning.code == "LOCAL_DEPTH") then pure () else fail "missing LOCAL_DEPTH warning"
  | .error error => fail s!"depth lint unexpectedly failed: {repr error}"

  IO.println "erasure tests passed"
