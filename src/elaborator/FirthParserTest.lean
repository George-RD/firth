import elaborator.Firth.Parser

open Firth.Elaborator

private def fail (message : String) : IO Unit := panic! message

private def success (source : String) : IO SourceFile :=
  match parse source with
  | .success file => pure file
  | .failure errors => do
      IO.println (repr errors)
      throw (IO.userError "expected success")

private def failureCode (source : String) : Option String :=
  match parse source with
  | .success _ => none
  | .failure (error :: _) => some error.code
  | .failure [] => none

private def expectFailure (source code : String) : IO Unit :=
  if failureCode source == some code then pure () else fail s!"expected {code} for {source}"

private def expectEq [BEq α] (actual expected : α) (message : String) : IO Unit :=
  if actual == expected then pure () else fail message

def runParserTests : IO Unit := do
  let source := "\\ ignored comment\nuse core.math as math;\nvocab demo { : inc (forall ρ; ρ n:Int^many{positive n} -- ρ n:Int^many) 1 prim math.add [ false ] if ; }"
  let file ← success source
  expectEq file.span.start.offset 0 "source start offset"
  expectEq file.span.stop.offset source.length "source trailing extent"
  expectEq file.span.stop.line 3 "source end line"
  expectEq file.span.stop.column 105 "source end column"
  match file.declarations with
  | [.use useDecl, .vocabulary vocabName [.word wordDecl] vocabSpan] =>
      expectEq useDecl.name "core.math" "use name"
      expectEq useDecl.alias (some "math") "use alias"
      expectEq useDecl.span.start.offset 18 "use start"
      expectEq useDecl.span.stop.offset 40 "use closing semicolon"
      expectEq vocabName "demo" "vocabulary name"
      expectEq vocabSpan.start.offset 41 "vocabulary start"
      expectEq vocabSpan.stop.offset source.length "vocabulary closing brace"
      expectEq wordDecl.name "inc" "word name"
      expectEq wordDecl.span.start.offset 54 "word start"
      expectEq wordDecl.span.stop.offset 143 "word closing semicolon"
      expectEq wordDecl.effect.rowBinders.length 1 "row binder"
      expectEq wordDecl.effect.rows ["ρ", "ρ"] "row references"
      expectEq wordDecl.effect.input.length 2 "input stack shape"
      expectEq wordDecl.effect.output.length 2 "output stack shape"
      match wordDecl.effect.input, wordDecl.effect.output, wordDecl.body with
      | [.row "ρ" _, .value "n" inputType _], [.row "ρ" _, .value "n" outputType _],
          [.literal _ _, .primitive "math.add" _, .quotation [.literal _ _] _, .atom "if" _] =>
          expectEq inputType.name "Int" "input type"
          expectEq inputType.usage Usage.many "input usage"
          expectEq inputType.refinements.length 1 "refinement shape"
          expectEq (inputType.refinements.head? |>.map (·.tokens)) (some ["positive", "n"]) "refinement tokens"
          expectEq outputType.usage Usage.many "output usage"
      | _, _, _ => fail "deep AST shape"
  | _ => fail "declaration shape"

  let commentFile ← success "\\ abcdef\n: q ( -- ) ;"
  match commentFile.declarations with
  | [.word word] => expectEq word.span.start.offset 9 "line comment offset"
  | _ => fail "comment declaration"

  expectFailure ": foo.bar ( -- ) ;" "firth.syntax.invalid-name"
  expectFailure "vocab outer { vocab inner { } }" "firth.syntax.nested-vocabulary"
  expectFailure ": true ( -- ) ;" "firth.syntax.invalid-name"
  expectFailure ": x (forall ρ ρ -- ρ) ;" "firth.syntax.missing-forall-separator"
  expectFailure ": x (ρ -- ρ) ;" "firth.syntax.unbound-row"
  expectFailure ": x (forall ρ; ρ -- ρ -- ρ) ;" "firth.syntax.multiple-separators"
  expectFailure ": x ( -- ) locals { } { } ;" "firth.syntax.empty-locals"
  expectFailure ": x (forall ρ; ρ n:Int^banana -- ρ) ;" "firth.syntax.invalid-usage"
  expectFailure ": x (forall ρ; ρ n:Int^many{positive,} -- ρ) ;" "firth.syntax.invalid-refinement"
  expectFailure ": x (forall ρ; ρ n:Int^many{positive n -- ρ) ;" "firth.syntax.unterminated-refinement"
  expectFailure ": x ( -- )" "firth.syntax.unexpected-eof"
  expectFailure "\\ abcdef\n: x ( -- )" "firth.syntax.unexpected-eof"
  expectFailure ": x ( -- ) ^banana ;" "firth.syntax.invalid-item"
  IO.println "parser tests passed"

def main : IO Unit := runParserTests
