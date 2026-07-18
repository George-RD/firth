import elaborator.Firth.Parser

open Firth.Elaborator

private def fail (message : String) : IO Unit := throw <| IO.userError message

private def success (source : String) : IO SourceFile :=
  match parse source with
  | .success file => pure file
  | .failure errors => do
      IO.println (repr errors)
      throw (IO.userError s!"expected success: {source}")

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

private def expectSpanFailure (source code : String) (start stop : Nat) : IO Unit :=
  match parse source with
  | .failure [error] => do
      expectEq error.code code s!"lex failure code for {source}"
      expectEq error.primary.start.offset start s!"lex failure start for {source}: {repr error.primary}"
      expectEq error.primary.stop.offset stop s!"lex failure stop for {source}: {repr error.primary}"
      expectEq error.primary.start.line 1 "lex failure start line"
      expectEq error.primary.start.column (start + 1) "lex failure start column"
      expectEq error.primary.stop.line 1 "lex failure stop line"
      expectEq error.primary.stop.column (stop + 1) "lex failure stop column"
      if start == stop then fail "lex failure span must be non-zero" else pure ()
  | _ => fail s!"expected one span failure for {source}"

private def expectWordBoundary (source : String) (inputCount outputCount : Nat) : IO Unit :=
  match parse source with
  | .success { declarations := [.word word], .. } => do
      expectEq word.span.start.offset 0 "worked example word start"
      expectEq word.span.stop.offset source.toUTF8.size "worked example word stop"
      expectEq word.effect.input.length inputCount "worked example input shape"
      expectEq word.effect.output.length outputCount "worked example output shape"
  | _ => fail "expected one worked example word"

private def stackItemShape : StackItem → String
  | .row name _ => "row:" ++ name
  | .value name type _ =>
      name ++ ":" ++ type.name ++ match type.usage with | .many => "^many" | .linear => "^linear"

private def expectEffectShape (source : String) (rows : List String) (input output : List String) : IO Unit :=
  match parse source with
  | .success { declarations := [.word word], .. } => do
      expectEq (word.effect.rowBinders.map (·.name)) ["ρ"] "worked example row binders"
      expectEq word.effect.rows rows "worked example rows"
      expectEq (word.effect.input.map stackItemShape) input "worked example input entries"
      expectEq (word.effect.output.map stackItemShape) output "worked example output entries"
      if word.effect.span.start.offset >= word.effect.span.stop.offset then fail "worked example effect span" else pure ()
  | _ => fail "expected worked example effect"

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
          expectEq (inputType.refinements.head? |>.map (·.tokens))
            (some [TokenKind.identifier "positive", TokenKind.identifier "n"]) "refinement tokens"
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
          expectEq (type.refinements.head? |>.map (·.tokens))
            (some [TokenKind.identifier "positive", TokenKind.identifier "a", TokenKind.symbol ",",
              TokenKind.identifier "nonzero", TokenKind.identifier "a"]) "comma-separated predicates"
      | _ => fail "multiple row input shape"
  | _ => fail "multiple row declaration shape"

  let printableCharacter ← success ": chars ( -- ) 'a' ;"
  match printableCharacter.declarations with
  | [.word { body := [.literal { value := .character 'a', .. } _], .. }] => pure ()
  | _ => fail "printable character declaration"
  let rawBackslash ← success ": slash ( -- ) '\\' ;"
  match rawBackslash.declarations with
  | [.word { body := [.literal { value := .character value, .. } _], .. }] =>
      expectEq value '\\' "raw printable backslash character"
  | _ => fail "raw backslash character shape"

  let payloads ← success ": payloads ( -- ) \"a\\n\\\\b\" 'z' ;"
  match payloads.declarations with
  | [.word word] =>
      match word.body with
      | [.literal { value := .string stringValue, .. } _, .literal { value := .character characterValue, .. } _] =>
          expectEq stringValue "a\n\\b" "decoded string payload"
          expectEq characterValue 'z' "decoded character payload"
      | _ => fail "literal payload shape"
  | _ => fail "literal payload declaration"

  let escapePayloads := ": escapes ( -- ) \"" ++ "\\\"" ++ "\\r" ++ "\\t" ++ "\" ;"
  let escaped ← success escapePayloads
  match escaped.declarations with
  | [.word { body := [.literal { value := .string value, .. } _], .. }] =>
      expectEq value "\"\r\t" "all decoded string escapes"
  | _ => fail "string escape payload shape"

  let refinementPayloads ← success ": payloads ( -- x:Int{\"a\\n\" 'z'} ) ;"
  match refinementPayloads.declarations with
  | [.word word] =>
      match word.effect.output with
      | [.value "x" type _] =>
          expectEq (type.refinements.head? |>.map (·.tokens))
            (some [TokenKind.string "a\n", TokenKind.character 'z']) "refinement literal payloads"
      | _ => fail "refinement payload stack shape"
  | _ => fail "refinement payload declaration"

  let workedInc := ": inc ( forall ρ; ρ n:Int^many -- ρ n:Int^many ) 1 prim + ;"
  let workedChoose := ": choose-inc ( forall ρ; ρ n:Int^many b:Bool^many -- ρ n:Int^many )\n  [ 1 prim + ] [ ] if ;"
  let workedLocals := ": add-top-two ( forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many )\n  locals { a b } { a b prim + } ;"
  let workedLinear := ": send-once ( forall ρ; ρ h:Handle^linear b:Bytes^linear -- ρ )\n  locals { h b } { h b prim send } ;"
  let _ ← success workedInc
  let _ ← success workedChoose
  let _ ← success workedLocals
  let _ ← success workedLinear
  expectWordBoundary workedInc 2 2
  expectWordBoundary workedChoose 3 2
  expectWordBoundary workedLocals 3 2
  expectWordBoundary workedLinear 3 1
  expectEffectShape workedInc ["ρ", "ρ"] ["row:ρ", "n:Int^many"] ["row:ρ", "n:Int^many"]
  expectEffectShape workedChoose ["ρ", "ρ"] ["row:ρ", "n:Int^many", "b:Bool^many"] ["row:ρ", "n:Int^many"]
  expectEffectShape workedLocals ["ρ", "ρ"] ["row:ρ", "a:Int^many", "b:Int^many"] ["row:ρ", "r:Int^many"]
  expectEffectShape workedLinear ["ρ", "ρ"] ["row:ρ", "h:Handle^linear", "b:Bytes^linear"] ["row:ρ"]
  let qualifiedReference ← success ": ref ( -- ) arith.inc ;"
  match qualifiedReference.declarations with
  | [.word { body := [.word "arith.inc" _], .. }] => pure ()
  | _ => fail "qualified worked reference AST shape"
  match parse ": primitive-pi ( -- ) prim π ;" with
  | .success { declarations := [.word { body := [.primitive "π" _], .. }], .. } => pure ()
  | _ => fail "primitive pi AST shape"
  match parse workedInc with
  | .success { declarations := [.word { body := [.literal { value := .integer 1, .. } _, .primitive "+" _], .. }], .. } => pure ()
  | _ => fail "inc worked example AST shape"
  match parse workedChoose with
  | .success { declarations := [.word { body := [.quotation [.literal { value := .integer 1, .. } _, .primitive "+" _] _, .quotation [] _, .atom "if" _], .. }], .. } => pure ()
  | _ => fail "choose-inc worked example AST shape"
  match parse workedLocals with
  | .success { declarations := [.word { body := [.locals [{ name := "a", span := _ }, { name := "b", span := _ }] [.word "a" _, .word "b" _, .primitive "+" _] _], .. }], .. } => pure ()
  | _ => fail "add-top-two worked example AST shape"
  match parse workedLinear with
  | .success { declarations := [.word { body := [.locals [{ name := "h", span := _ }, { name := "b", span := _ }] [.word "h" _, .word "b" _, .primitive "send" _] _], .. }], .. } => pure ()
  | _ => fail "send-once worked example AST shape"

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
  expectSpanFailure ": x ( -- ) \"\\q\" ;" "firth.syntax.invalid-escape" 12 14
  expectSpanFailure ": x ( -- ) '\\q' ;" "firth.syntax.invalid-escape" 11 15
  expectSpanFailure ": x ( -- ) '\\0' ;" "firth.syntax.invalid-escape" 11 15
  expectSpanFailure ": x ( -- ) '\\n' ;" "firth.syntax.invalid-escape" 11 15
  expectSpanFailure ": x ( -- ) '\\r' ;" "firth.syntax.invalid-escape" 11 15
  expectSpanFailure ": x ( -- ) '\\t' ;" "firth.syntax.invalid-escape" 11 15
  expectSpanFailure ": x ( -- ) '\\q" "firth.syntax.invalid-escape" 11 14
  expectSpanFailure ": x ( -- ) 'ab' ;" "firth.syntax.overlong-character" 11 15
  expectSpanFailure ": x ( -- ) 'abcdef' ;" "firth.syntax.overlong-character" 11 19
  expectSpanFailure ": x ( -- ) 'a" "firth.syntax.unterminated-character" 11 13
  expectSpanFailure ": x ( -- ) '" "firth.syntax.unterminated-character" 11 12
  expectSpanFailure ": x ( -- ) 'abc" "firth.syntax.overlong-character" 11 15
  expectSpanFailure ": x ( -- ) \"abc" "firth.syntax.unterminated-string" 11 15
  expectSpanFailure (": x ( -- ) \"abc" ++ "\\") "firth.syntax.unterminated-string" 11 16
  expectSpanFailure ": x ( -- ) (*" "firth.syntax.unterminated-comment" 11 13
  expectSpanFailure ": x ( -- ) @ ;" "firth.syntax.invalid-token" 11 12
  expectSpanFailure (": x ( -- ) \"" ++ String.singleton (Char.ofNat 1))
    "firth.syntax.invalid-character" 12 13
  expectSpanFailure (": x ( -- ) '" ++ String.singleton (Char.ofNat 1) ++ "' ;")
    "firth.syntax.invalid-character" 11 14
  IO.println "parser tests passed"

def main : IO Unit := runParserTests
