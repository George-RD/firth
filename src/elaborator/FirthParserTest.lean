import elaborator.Firth.Parser

open Firth.Elaborator

private def assertSuccess (source : String) : Option SourceFile :=
  match parse source with
  | .success file => some file
  | .failure _ => none

private def assertFailure (source code : String) : Bool :=
  match parse source with
  | .success _ => false
  | .failure (diagnostic :: _) => diagnostic.body.code == code
  | .failure [] => false

def main : IO Unit := do
  let file := (assertSuccess "\\ comment\n(* block *) : inc (forall ρ; ρ n:Int^many -- ρ n:Int^many) 1 prim addNat ;").getD { declarations := [], span := { start := { offset := 0, line := 1, column := 1 }, stop := { offset := 0, line := 1, column := 1 } } }
  if file.declarations.length != 1 then panic! "definition missing" else pure ()
  let nested := (assertSuccess ": q ( -- ) [ 1 [ false ] ] ;").getD { declarations := [], span := file.span }
  if nested.declarations.length != 1 then panic! "quotation missing" else pure ()
  if !assertFailure ": x ( -- ) [ 1 ;" "firth.syntax.invalid-item" then panic! "delimiter diagnostic" else pure ()
  if !assertFailure ": x ( -- ) 999? ;" "firth.syntax.invalid-token" then panic! "literal diagnostic" else pure ()
  IO.println "parser smoke tests passed"
