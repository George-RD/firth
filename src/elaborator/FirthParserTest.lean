import elaborator.Firth.Parser

open Firth.Elaborator

private def fail (message : String) : IO Unit := throw <| IO.userError message

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

private def expectEofFailure (source code : String) (position : Position) : IO Unit :=
  match parse source with
  | .failure [error] => do
      expectEq error.code code "EOF failure code"
      expectEq error.primary (Span.mk position position) "EOF failure span"
  | _ => fail s!"expected one EOF failure for {source}"

def runParserTests : IO Unit := do
  let source := "\\ ignored comment\nuse core.math as math;\nvocab demo { : inc (forall ρ; ρ n:Int^many{positive n} -- ρ n:Int^many) 1 prim math.add [ false ] if ; }"
  let file ← success source
  expectEq file.span.start.offset 0 "source start offset"
  expectEq file.span.stop.offset source.toUTF8.size "source trailing extent"
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
      expectEq vocabSpan.stop.offset source.toUTF8.size "vocabulary closing brace"
      expectEq wordDecl.name "inc" "word name"
      expectEq wordDecl.span.start.offset 54 "word start"
      expectEq wordDecl.span.stop.offset 146 "word closing semicolon byte offset"
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

  let trailingTrivia := "\\ comment\n: q ( -- ) ;  \t(* trailing *)\n"
  let trailingFile ← success trailingTrivia
  expectEq trailingFile.span.stop.offset trailingTrivia.toUTF8.size "trailing trivia byte extent"
  expectEq trailingFile.span.stop.line 3 "trailing trivia line"
  expectEq trailingFile.span.stop.column 1 "trailing trivia column"

  let multiRow ← success ": rows (forall ρ ρ2; ρ ρ2 a:Int{positive a,nonzero a} -- ρ2 ρ) ;"
  match multiRow.declarations with
  | [.word word] =>
      expectEq (word.effect.rowBinders.map (fun binder => binder.name)) ["ρ", "ρ2"] "multiple row binders"
      expectEq word.effect.input.length 3 "multiple row input"
      match word.effect.input with
      | [_, _, .value "a" type _] =>
          expectEq type.refinements.length 1 "single refinement block"
          expectEq (type.refinements.head? |>.map (·.tokens)) (some ["positive", "a", ",", "nonzero", "a"]) "comma-separated predicates"
      | _ => fail "multiple row input shape"
  | _ => fail "multiple row declaration shape"

  let escapedControls ← success ": chars ( -- ) '\\n' '\\r' '\\t' '\\\\' ;"
  match escapedControls.declarations with
  | [.word word] => expectEq word.body.length 4 "escaped character literals"
  | _ => fail "escaped character declaration"

  let qualifiedBody ← success ": qualified ( -- ) foo.bar.baz ;"
  match qualifiedBody.declarations with
  | [.word word] =>
      match word.body with
      | [.word "foo.bar.baz" _] => pure ()
      | _ => fail "qualified body name"
  | _ => fail "qualified body declaration"

  expectFailure ": foo.bar ( -- ) ;" "firth.syntax.invalid-name"
  expectFailure "vocab outer { vocab inner { } }" "firth.syntax.nested-vocabulary"
  expectFailure ": true ( -- ) ;" "firth.syntax.invalid-name"
  expectFailure ": as ( -- ) ;" "firth.syntax.invalid-name"
  expectFailure ": ρfoo ( -- ) ;" "firth.syntax.invalid-name"
  expectFailure ": x (forall ρ ρ -- ρ) ;" "firth.syntax.duplicate-row"
  expectFailure ": x (forall ρ; forall ρ2; ρ -- ρ) ;" "firth.syntax.repeated-forall"
  expectFailure ": x (forall ; ρ -- ρ) ;" "firth.syntax.missing-row-binder"
  expectFailure ": x (forall ρ ρ2 ρ -- ρ) ;" "firth.syntax.duplicate-row"
  expectFailure ": x (forall ρ ρ2 -- ρ) ;" "firth.syntax.missing-forall-separator"
  expectFailure ": x (ρ -- ρ) ;" "firth.syntax.unbound-row"
  expectFailure ": x (forall ρ; ρ -- ρ -- ρ) ;" "firth.syntax.multiple-separators"
  expectFailure ": x ( -- ) locals { } { } ;" "firth.syntax.empty-locals"
  expectFailure ": x (forall ρ; ρ n:Int^banana -- ρ) ;" "firth.syntax.invalid-usage"
  expectFailure ": x (forall ρ; ρ n:Int^many{positive,} -- ρ) ;" "firth.syntax.invalid-refinement"
  expectFailure ": x (forall ρ; ρ n:Int{,positive} -- ρ) ;" "firth.syntax.invalid-refinement"
  expectFailure ": x (forall ρ; ρ n:Int{positive}{nonzero} -- ρ) ;" "firth.syntax.multiple-refinements"
  expectFailure ": x (forall ρ; ρ n:Int{positive,,nonzero} -- ρ) ;" "firth.syntax.invalid-refinement"
  expectFailure ": x (forall ρ; ρ n:Int^many{positive n -- ρ) ;" "firth.syntax.unterminated-refinement"
  expectFailure ": x ( -- )" "firth.syntax.unexpected-eof"
  expectFailure "\\ abcdef\n: x ( -- )" "firth.syntax.unexpected-eof"
  let malformedWithTrivia := ": x ( -- )   (* trailing *)\n"
  expectEofFailure malformedWithTrivia "firth.syntax.unexpected-eof"
    { offset := malformedWithTrivia.toUTF8.size, line := 2, column := 1 }
  expectFailure ": x ( -- ) ^banana ;" "firth.syntax.invalid-item"
  expectFailure ": x ( -- ) dup.foo ;" "firth.syntax.invalid-name"
  expectFailure ": x ( -- ) forall ;" "firth.syntax.invalid-name"
  expectFailure ": x ( -- ) '\n' ;" "firth.syntax.invalid-character"
  expectFailure ": x ( -- ) '\r' ;" "firth.syntax.invalid-character"
  expectFailure (": x ( -- ) '" ++ String.singleton (Char.ofNat 1) ++ "' ;") "firth.syntax.invalid-character"
  expectFailure (": x ( -- ) '" ++ String.singleton (Char.ofNat 133) ++ "' ;") "firth.syntax.invalid-character"
  expectFailure (": x ( -- ) \"" ++ String.singleton (Char.ofNat 1) ++ "\" ;") "firth.syntax.invalid-character"
  IO.println "parser tests passed"

def main : IO Unit := runParserTests
