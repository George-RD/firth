import compiler.Firth.Compile

namespace Firth.CompilerTest

open Firth.Compiler

private def fail (message : String) : IO Unit := throw <| IO.userError message

private def expectContains (name input needle : String) : IO Unit := do
  match Compile.runRequest input with
  | .ok output =>
      if output.contains needle then pure ()
      else fail s!"{name}: missing {needle}\n{output}"
  | .error error => fail s!"{name}: unexpected error {error}"

private def expectMissing (name input needle : String) : IO Unit := do
  match Compile.runRequest input with
  | .ok output =>
      if output.contains needle then fail s!"{name}: unexpected {needle}\n{output}" else pure ()
  | .error error => fail s!"{name}: unexpected error {error}"

private def expectError (name input : String) : IO Unit := do
  match Compile.runRequest input with
  | .ok output => fail s!"{name}: accepted an invalid request\n{output}"
  | .error _ => pure ()

private def expectEqual (name expected actual : String) : IO Unit :=
  if expected == actual then pure () else fail s!"{name}: expected {expected}, got {actual}"

private def expectBool (name : String) (expected actual : Bool) : IO Unit :=
  if expected == actual then pure () else fail s!"{name}: expected {expected}, got {actual}"

private def scheme (output : String) : String :=
  "{\"row_variables\":[],\"input\":{\"row\":null,\"items\":[]},\"output\":" ++ output ++ "}"

private def intOutput : String :=
  "{\"row\":null,\"items\":[{\"kind\":\"base\",\"name\":\"Int\",\"usage\":\"many\"}]}"

private def request (name program : String) (type : String := scheme intOutput) : String :=
  "{\"request_id\":\"r1\",\"checked_words\":[{\"name\":\"" ++ name
    ++ "\",\"checking_state\":\"checked\",\"proof_state\":\"available\",\"program\":" ++ program
    ++ "}],\"erased_word_types\":[{\"word\":\"" ++ name ++ "\",\"type\":" ++ type
    ++ "}],\"gamma_version\":\"0.1\",\"target_version\":\"0.1\"}"

/-- A source-bound request for a single word named `main`, whose kernel body
and type must match the re-elaboration of `source`. -/
private def sourceRequest (source program : String) (type : String := scheme intOutput) : String :=
  (request "main" program type).replace "\"gamma_version\":\"0.1\",\"target_version\":\"0.1\"}"
    ("\"gamma_version\":\"0.1\",\"target_version\":\"0.1\",\"source\":{\"source_path\":\"test.firth\","
      ++ "\"source_text\":" ++ (Lean.Json.str source).compress ++ ",\"language_version\":\"0.1\"}}")

/-- Inserts a `spans` member into the single checked word of a request. -/
private def withSpans (input spans : String) : String :=
  input.replace "\"program\":" ("\"spans\":" ++ spans ++ ",\"program\":")

private def literal (value : Nat) : String :=
  "{\"kind\":\"lit\",\"value\":{\"type\":\"nat\",\"value\":" ++ toString value ++ "}}"

private def quotation (body : String) : String :=
  "{\"kind\":\"quotation\",\"body\":[" ++ body ++ "]}"

private def span (startLine startColumn stopLine stopColumn : Nat) : String :=
  "{\"start\":{\"line\":" ++ toString startLine ++ ",\"column\":" ++ toString startColumn
    ++ "},\"end\":{\"line\":" ++ toString stopLine ++ ",\"column\":" ++ toString stopColumn ++ "}}"

/-- `literal 1` wrapped in `depth` quotations, then called `depth` times, so
the word still leaves one `Int` whatever the depth. -/
private def nested (depth : Nat) : String :=
  let rec wrap : Nat → String
    | 0 => literal 1
    | n + 1 => quotation (wrap n)
  "[" ++ wrap depth ++ String.join (List.replicate depth ",{\"kind\":\"call\"}") ++ "]"

/-- A well-typed body of exactly `count` atoms leaving one `Int`, for even
`count` at least 4 or odd `count` at least 1. -/
private def atoms (count : Nat) : String :=
  let pair := ",{\"kind\":\"dup\"},{\"kind\":\"drop\"}"
  if count % 2 == 0 then
    "[" ++ literal 1 ++ "," ++ literal 2 ++ ",{\"kind\":\"swap\"},{\"kind\":\"drop\"}"
      ++ String.join (List.replicate ((count - 4) / 2) pair) ++ "]"
  else
    "[" ++ literal 1 ++ String.join (List.replicate (count / 2) pair) ++ "]"

/-- The canonical encoding must agree with `src/runtime/vm/src/encoding.rs`
byte for byte, because the VM recomputes every `body_digest` when it decodes
an image. These vectors were taken from the Rust encoder. -/
private def encodingWitnesses : IO Unit := do
  expectEqual "empty code" "00" (Digest.toHex (Target.canonicalCode []))
  expectEqual "one literal" "01000054"
    (Digest.toHex (Target.canonicalCode [.pushLiteral (.int 42)]))
  expectEqual "literal body digest"
    "cc39e41375f446f36c58235bdc93f919a6152b63443864eea5cb60626210b4a6"
    (Digest.toHex (Target.bodyDigest [.pushLiteral (.int 42)]))
  expectEqual "zig-zag negative" "0001" (Digest.toHex (Target.canonicalValue (.int (-1))))
  expectEqual "zig-zag positive" "0002" (Digest.toHex (Target.canonicalValue (.int 1)))
  expectEqual "multi-byte leb128" "00d804" (Digest.toHex (Target.canonicalValue (.int 300)))
  -- The largest `i64` is the ten-byte LEB128 form the Rust reader accepts:
  -- its final payload byte is 1.
  expectEqual "i64 max zig-zag" "00feffffffffffffffff01"
    (Digest.toHex (Target.canonicalValue (.int 9223372036854775807)))
  expectEqual "boolean tag" "0101" (Digest.toHex (Target.canonicalValue (.bool true)))
  expectEqual "world tag" "05" (Digest.toHex (Target.canonicalValue .world))
  expectEqual "quotation then call" "0201010000120006"
    (Digest.toHex (Target.canonicalCode [.pushQuote [.pushLiteral (.int 9)] [] [], .call]))
  -- §7 order: code, capture count, consumed bitmap, then each capture.
  expectEqual "one consumed capture" "030001010002"
    (Digest.toHex (Target.canonicalValue (.quotation [] [.int 1] [true])))
  expectEqual "call word" "010b046d61696e"
    (Digest.toHex (Target.canonicalCode [.callWord "main"]))
  -- FIPS 180-4 vectors, so a digest change is caught here and not only where
  -- it happens to matter.
  expectEqual "sha256 of the empty string"
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    (Digest.hexOfString "")
  expectEqual "sha256 of abc"
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    (Digest.hexOfString "abc")

/-- The library predicates the lowering relies on: the `i64` domain, capture
well-formedness and the VM admission bounds. -/
private def admissionWitnesses : IO Unit := do
  expectBool "i64 max is representable" true (Target.isInt64 9223372036854775807)
  expectBool "2^63 is not representable" false (Target.isInt64 9223372036854775808)
  expectBool "i64 min is representable" true (Target.isInt64 (-9223372036854775808))
  expectBool "below i64 min is not representable" false (Target.isInt64 (-9223372036854775809))
  expectBool "matched capture lists are well formed" true
    (Target.wellFormedCode [.pushQuote [] [.int 1] [true]])
  expectBool "extra consumed flags are malformed" false
    (Target.wellFormedCode [.pushQuote [] [] [true]])
  expectBool "missing consumed flags are malformed" false
    (Target.wellFormedCode [.pushLiteral (.quotation [] [.int 1] [])])
  expectBool "a malformed quotation inside a body is found" false
    (Target.wellFormedCode [.pushQuote [.pushLiteral (.quotation [] [] [true])] [] []])
  expectBool "a malformed captured quotation is found" false
    (Target.wellFormedCode [.pushQuote [] [.quotation [] [] [true]] [false]])
  expectBool "4096 instructions are within bounds" true
    (Target.boundViolation (List.replicate 4096 .dup)).isNone
  expectBool "4097 instructions exceed the bound" true
    (Target.boundViolation (List.replicate 4097 .dup)).isSome
  expectBool "4097 instructions inside a quotation exceed the bound" true
    (Target.boundViolation [.pushQuote (List.replicate 4097 .dup) [] []]).isSome
  let rec deep : Nat → List Target.Instruction
    | 0 => [.pushLiteral (.int 1)]
    | n + 1 => [.pushQuote (deep n) [] []]
  expectBool "32 nested quotations are within bounds" true (Target.boundViolation (deep 32)).isNone
  expectBool "33 nested quotations exceed the bound" true (Target.boundViolation (deep 33)).isSome
  let rec captured : Nat → Target.Value
    | 0 => .int 1
    | n + 1 => .quotation [] [captured n] [false]
  expectBool "32 nested captured quotations are within bounds" true
    (Target.boundViolation [.pushLiteral (captured 32)]).isNone
  expectBool "33 nested captured quotations exceed the bound" true
    (Target.boundViolation [.pushLiteral (captured 33)]).isSome

private def mangleWitnesses : IO Unit := do
  let check (name expected : String) : IO Unit :=
    match Lowering.mangle name with
    | .ok mangled => expectEqual s!"mangle {name}" expected mangled
    | .error error => fail s!"mangle {name}: {error}"
  check "conditional" "conditional"
  check "literal-int" "literal_hint"
  check "quotation-call" "quotation_hcall"
  check "under_score" "under_uscore"
  check "v.w" "v_x2ew"
  check "0start" "_d0start"
  -- Injectivity where a naive mapping would collide.
  check "a-b" "a_hb"
  check "a_b" "a_ub"
  match Lowering.mangle "" with
  | .ok mangled => fail s!"mangle accepted an empty name: {mangled}"
  | .error _ => pure ()

/-- The binder names between `forall` and `;` of a rendered word type. -/
private def binderNames (rendered : String) : List String :=
  match rendered.splitOn ";" with
  | binders :: _ => (binders.drop "(forall".length).toString.splitOn ","
  | _ => []

private def wordTypeWitnesses : IO Unit := do
  let render (name : String) (value : WordType.Scheme) (expected : String) : IO Unit :=
    match WordType.render value with
    | .ok rendered => expectEqual name expected rendered
    | .error error => fail s!"{name}: {error}"
  render "empty" { rowVariables := [], input := .mk none [], output := .mk none [] } "(--)"
  render "one result"
    { rowVariables := [], input := .mk none [],
      output := .mk none [.base "Int" .many] } "(--v0:Int^many)"
  render "row polymorphic"
    { rowVariables := ["ρ"], input := .mk (some "ρ") [],
      output := .mk (some "ρ") [.base "Int" .many] } "(forallρ;ρ--ρ,v0:Int^many)"
  render "surface row name is renamed positionally"
    { rowVariables := ["ρ2"], input := .mk (some "ρ2") [],
      output := .mk (some "ρ2") [] } "(forallρ;ρ--ρ)"
  render "two rows"
    { rowVariables := ["ρ", "σ"], input := .mk (some "ρ") [],
      output := .mk (some "σ") [] } "(forallρ,σ;ρ--σ)"
  render "linear quotation item"
    { rowVariables := [], input := .mk none [],
      output := .mk none [.quotation (.mk none []) (.mk none [.base "Int" .many]) .linear] }
    "(--v0:[--v0:Int^many]^linear)"
  match WordType.render
      { rowVariables := [], input := .mk (some "ρ") [], output := .mk none [] } with
  | .ok rendered => fail s!"an unbound row rendered: {rendered}"
  | .error _ => pure ()
  match WordType.render
      { rowVariables := [], input := .mk none [.base "my-type" .many], output := .mk none [] } with
  | .ok rendered => fail s!"a non-canonical type name rendered: {rendered}"
  | .error _ => pure ()
  match WordType.render
      { rowVariables := ["ρ", "ρ"], input := .mk none [], output := .mk none [] } with
  | .ok rendered => fail s!"duplicate binders rendered: {rendered}"
  | .error _ => pure ()
  -- The row-name predicate agrees with the VM's `row_name` parser on every
  -- scalar it could disagree about, and rejects ASCII outright.
  expectBool "the spec's row name" true (WordType.isRowName "ρ")
  expectBool "a comma is a delimiter" false (WordType.isRowName ",")
  expectBool "a space is whitespace" false (WordType.isRowName " ")
  expectBool "an ideographic space is Unicode whitespace" false (WordType.isRowName "　")
  expectBool "a surface row name is two scalars" false (WordType.isRowName "ρ2")
  expectBool "an ASCII letter would read as a Name" false (WordType.isRowName "a")
  expectBool "an empty string is not a row name" false (WordType.isRowName "")
  expectBool "the first generated name" true (WordType.isRowName "一")
  -- The generator keeps the frozen table and continues into the CJK block.
  expectEqual "binder 0" "ρ" (WordType.canonicalRowName 0)
  expectEqual "binder 23" "ς" (WordType.canonicalRowName 23)
  expectEqual "binder 24" "一" (WordType.canonicalRowName 24)
  expectEqual "binder 25" "丁" (WordType.canonicalRowName 25)
  let binders (count : Nat) : List String := (List.range count).map fun index => s!"r{index}"
  let wide (count : Nat) : WordType.Scheme :=
    { rowVariables := binders count, input := .mk (some s!"r{count - 1}") [],
      output := .mk (some s!"r{count - 1}") [.base "Int" .many] }
  for count in [25, 200] do
    match WordType.render (wide count) with
    | .error error => fail s!"{count} binders did not render: {error}"
    | .ok rendered =>
        let names := binderNames rendered
        if names.length != count then
          fail s!"{count} binders rendered {names.length} names: {rendered}"
        if names.eraseDups.length != count then
          fail s!"{count} binders rendered repeated names: {rendered}"
        if !names.all WordType.isRowName then
          fail s!"{count} binders rendered a non-row name: {rendered}"
        if (names.take 24) != WordType.canonicalRowNames.toList then
          fail s!"{count} binders changed the frozen table: {rendered}"
        let last := WordType.canonicalRowName (count - 1)
        if !rendered.endsWith s!";{last}--{last},v0:Int^many)" then
          fail s!"{count} binders did not use the last generated name: {rendered}"
  match WordType.render (wide (WordType.maxRowBinders + 1)) with
  | .ok rendered => fail s!"a scheme beyond the generated block rendered: {rendered.take 40}"
  | .error _ => pure ()

/-- Entry selection must not depend on definition order. -/
private def entrySelectionTests : IO Unit := do
  let mainWord := "{\"name\":\"main\",\"checking_state\":\"checked\",\"proof_state\":\"available\",\"program\":[{\"kind\":\"word\",\"name\":\"helper-word\"}]}"
  let helperWord := "{\"name\":\"helper-word\",\"checking_state\":\"checked\",\"proof_state\":\"available\",\"program\":[" ++ literal 42 ++ "]}"
  let multi (reverse : Bool) : String :=
    "{\"request_id\":\"r1\",\"entry\":\"main\",\"checked_words\":[" ++
    (if reverse then helperWord ++ "," ++ mainWord else mainWord ++ "," ++ helperWord) ++
    "],\"erased_word_types\":[{\"word\":\"main\",\"type\":" ++ scheme intOutput ++
    "},{\"word\":\"helper-word\",\"type\":" ++ scheme intOutput ++
    "}],\"gamma_version\":\"0.1\",\"target_version\":\"0.1\"}"
  for reverse in [false, true] do
    expectContains "explicit entry is independent of source order" (multi reverse)
      "\"entry\":\"main\""
    expectContains "word calls still resolve forward and backward" (multi reverse)
      "\"op\":\"call-word\",\"name\":\"helper_hword\""
  expectContains "explicit source entry is mangled"
    ((multi false).replace "\"entry\":\"main\"" "\"entry\":\"helper-word\"")
    "\"entry\":\"helper_hword\""
  expectError "multiword request without entry is ambiguous"
    ((multi false).replace "\"entry\":\"main\"," "")
  expectError "unknown entry is refused"
    ((multi false).replace "\"entry\":\"main\"" "\"entry\":\"absent\"")
  expectError "empty entry is refused"
    ((multi false).replace "\"entry\":\"main\"" "\"entry\":\"\"")
  expectError "non-string entry is refused"
    ((multi false).replace "\"entry\":\"main\"" "\"entry\":7")
  expectError "duplicate entry is refused"
    ((multi false).replace "\"entry\":\"main\""
      "\"entry\":\"main\",\"entry\":\"helper-word\"")

/-- The direct Lean admission API must not bypass the wire-level check. -/
private def directAdmissionTests : IO Unit := do
  let invalid : Lowering.CheckedWord :=
    { name := "forged"
      scheme := { rowVariables := [], input := .mk none [], output := .mk none [.base "Int" .many] }
      program := .cons (.lit (.bool true)) .empty }
  match Lowering.compileWords [invalid] with
  | .error (.checkingFailed "forged" _) => pure ()
  | .error error => fail s!"wrong direct admission failure: {repr error}"
  | .ok _ => fail "a caller-constructed CheckedWord bypassed rechecking"
  let valid := { invalid with name := "valid", program := .cons (.lit (.nat 42)) .empty }
  match Lowering.compileWords [valid, invalid] with
  | .error (.checkingFailed "forged" _) => pure ()
  | .error error => fail s!"wrong unused-helper failure: {repr error}"
  | .ok _ => fail "an unused invalid body escaped dictionary rechecking"
  match Lowering.compileWords [valid] with
  | .ok [_] => pure ()
  | _ => fail "a valid direct kernel did not compile"

/-- Debug metadata reaches every nesting level, and source spans travel with
it only when a source is bound. -/
private def debugLocationTests : IO Unit := do
  let conditional := request "conditional"
    ("[{\"kind\":\"lit\",\"value\":{\"type\":\"bool\",\"value\":false}},"
      ++ quotation (literal 42) ++ "," ++ quotation (literal 0) ++ ",{\"kind\":\"if\"}]")
  expectContains "debug locations map instructions to atoms" conditional
    "{\"word\":\"conditional\",\"target_word\":\"conditional\",\"path\":[3],\"kernel_path\":[3]}"
  expectContains "debug locations cover quotation bodies" conditional
    "{\"word\":\"conditional\",\"target_word\":\"conditional\",\"path\":[1,0],\"kernel_path\":[1,0]}"
  expectContains "debug locations cover the second quotation body" conditional
    "{\"word\":\"conditional\",\"target_word\":\"conditional\",\"path\":[2,0],\"kernel_path\":[2,0]}"
  expectContains "debug locations cover two-level nesting" (request "twice" (nested 2))
    "{\"word\":\"twice\",\"target_word\":\"twice\",\"path\":[0,0,0],\"kernel_path\":[0,0,0]}"
  expectMissing "kernel-only requests carry no source span" conditional "\"source_path\""
  -- Source-bound requests report the re-elaborated span of every atom.
  let flat := sourceRequest ": main ( -- n:Int^many ) 42 ;" ("[" ++ literal 42 ++ "]")
  expectContains "source-bound debug locations carry the source path and span" flat
    ("{\"word\":\"main\",\"target_word\":\"main\",\"path\":[0],\"kernel_path\":[0],"
      ++ "\"source_path\":\"test.firth\",\"span\":" ++ span 1 26 1 28 ++ "}")
  let quoted := sourceRequest ": main ( -- n:Int^many ) [ 42 ] call ;"
    ("[" ++ quotation (literal 42) ++ ",{\"kind\":\"call\"}]")
  expectContains "nested source-bound debug locations carry the inner span" quoted
    ("{\"word\":\"main\",\"target_word\":\"main\",\"path\":[0,0],\"kernel_path\":[0,0],"
      ++ "\"source_path\":\"test.firth\",\"span\":" ++ span 1 28 1 30 ++ "}")
  -- A caller may repeat the elaborate adapter's spans verbatim; anything else
  -- is refused.
  expectContains "matching supplied spans are accepted"
    (withSpans flat ("[" ++ span 1 26 1 28 ++ "]")) "\"status\":\"success\""
  expectError "mismatched supplied spans are refused"
    (withSpans flat ("[" ++ span 1 27 1 29 ++ "]"))
  expectContains "kernel-only supplied spans are accepted and not reported"
    (withSpans (request "w" ("[" ++ literal 42 ++ "]")) ("[" ++ span 1 1 1 3 ++ "]"))
    "\"kernel_path\":[0]}"
  expectError "too many spans are refused"
    (withSpans (request "w" ("[" ++ literal 42 ++ "]"))
      ("[" ++ span 1 1 1 3 ++ "," ++ span 1 1 1 3 ++ "]"))
  expectError "a span body on a plain atom is refused"
    (withSpans (request "w" ("[" ++ literal 42 ++ "]"))
      ("[{\"start\":{\"line\":1,\"column\":1},\"end\":{\"line\":1,\"column\":3},\"body\":[]}]"))
  expectError "a quotation atom without a span body is refused"
    (withSpans (request "w" (nested 1)) ("[" ++ span 1 1 1 3 ++ "," ++ span 1 1 1 3 ++ "]"))
  expectError "a malformed span position is refused"
    (withSpans (request "w" ("[" ++ literal 42 ++ "]"))
      "[{\"start\":{\"line\":1},\"end\":{\"line\":1,\"column\":3}}]")

/-- Lowered code that the VM would refuse to load is refused here first. -/
private def targetBoundTests : IO Unit := do
  expectContains "4096 atoms compile" (request "long" (atoms 4096)) "\"status\":\"success\""
  expectContains "4097 atoms exceed the instruction bound" (request "long" (atoms 4097))
    "firth.compile.target-bound-exceeded"
  expectContains "32 nested quotations compile" (request "deep" (nested 32)) "\"status\":\"success\""
  expectContains "33 nested quotations exceed the nesting bound" (request "deep" (nested 33))
    "firth.compile.target-bound-exceeded"
  expectMissing "a bound refusal carries no target program" (request "deep" (nested 33))
    "\"target_program\""

def main : IO Unit := do
  encodingWitnesses
  admissionWitnesses
  mangleWitnesses
  wordTypeWitnesses
  entrySelectionTests
  directAdmissionTests
  debugLocationTests
  targetBoundTests

  expectContains "literal compiles" (request "literal-int" ("[" ++ literal 42 ++ "]"))
    "\"status\":\"success\""
  expectContains "hyphenated name is mangled" (request "literal-int" ("[" ++ literal 42 ++ "]"))
    "\"entry\":\"literal_hint\""
  expectContains "source name keys the digest index"
    (request "literal-int" ("[" ++ literal 42 ++ "]"))
    "\"word_digests\":{\"literal-int\":"
  expectContains "body digest binds the canonical encoding"
    (request "literal-int" ("[" ++ literal 42 ++ "]"))
    "cc39e41375f446f36c58235bdc93f919a6152b63443864eea5cb60626210b4a6"
  expectContains "erased word type is canonical"
    (request "literal-int" ("[" ++ literal 42 ++ "]"))
    "\"erased_word_type\":\"(--v0:Int^many)\""
  expectContains "forged markers cannot validate an underflowing control fixture"
    (request "control"
      "[{\"kind\":\"dup\"},{\"kind\":\"drop\"},{\"kind\":\"swap\"},{\"kind\":\"dip\"},\
        {\"kind\":\"call\"},{\"kind\":\"compose\"},{\"kind\":\"quote\"}]"
      (scheme "{\"row\":null,\"items\":[]}"))
    "firth.compile.typecheck-failed"
  expectContains "the plus primitive lowers to the target registry name"
    (request "add" ("[" ++ literal 1 ++ "," ++ literal 2 ++ ",{\"kind\":\"prim\",\"name\":\"+\"}]"))
    "\"primitive\":\"addNat\""
  expectContains "i64 max literal compiles"
    (request "max" ("[" ++ literal 9223372036854775807 ++ "]")) "\"status\":\"success\""

  -- Fail-closed cases. Each is reported as a structured compile failure, not
  -- as a target program that would run.
  expectContains "unit literal has no target value"
    (request "u" "[{\"kind\":\"lit\",\"value\":{\"type\":\"unit\"}}]")
    "firth.compile.unsupported-literal"
  expectContains "nat literal above i64 max is refused"
    (request "big" ("[" ++ literal 9223372036854775808 ++ "]"))
    "firth.compile.unsupported-literal"
  expectContains "unknown dictionary word"
    (request "w" "[{\"kind\":\"word\",\"name\":\"missing\"}]")
    "firth.compile.unknown-word"
  expectContains "unknown primitive"
    (request "p" "[{\"kind\":\"prim\",\"name\":\"missing\"}]")
    "firth.compile.unknown-primitive"
  expectContains "declared primitive without a target implementation"
    (request "s" "[{\"kind\":\"prim\",\"name\":\"send\"}]")
    "firth.compile.unsupported-primitive"
  expectContains "a target primitive name is not a language primitive"
    (request "p" "[{\"kind\":\"prim\",\"name\":\"addNat\"}]")
    "firth.compile.unknown-primitive"
  expectMissing "a failure carries no target program"
    (request "u" "[{\"kind\":\"lit\",\"value\":{\"type\":\"unit\"}}]")
    "\"target_program\""

  -- Malformed and stale requests are refused before any lowering.
  expectError "malformed JSON" "{"
  expectError "duplicate JSON member"
    "{\"request_id\":\"r1\",\"request_id\":\"r2\",\"checked_words\":[],\"erased_word_types\":[],\
      \"gamma_version\":\"0.1\",\"target_version\":\"0.1\"}"
  expectError "unchecked word"
    ("{\"request_id\":\"r1\",\"checked_words\":[{\"name\":\"w\",\"checking_state\":\"unchecked\",\
      \"proof_state\":\"available\",\"program\":[]}],\"erased_word_types\":[{\"word\":\"w\",\"type\":"
      ++ scheme "{\"row\":null,\"items\":[]}"
      ++ "}],\"gamma_version\":\"0.1\",\"target_version\":\"0.1\"}")
  expectError "unavailable proof"
    ("{\"request_id\":\"r1\",\"checked_words\":[{\"name\":\"w\",\"checking_state\":\"checked\",\
      \"proof_state\":\"deferred\",\"program\":[]}],\"erased_word_types\":[{\"word\":\"w\",\"type\":"
      ++ scheme "{\"row\":null,\"items\":[]}"
      ++ "}],\"gamma_version\":\"0.1\",\"target_version\":\"0.1\"}")
  expectError "unsupported gamma version"
    (("{\"request_id\":\"r1\",\"checked_words\":[],\"erased_word_types\":[],"
      ++ "\"gamma_version\":\"0.2\",\"target_version\":\"0.1\"}"))
  expectError "unsupported target version"
    (("{\"request_id\":\"r1\",\"checked_words\":[],\"erased_word_types\":[],"
      ++ "\"gamma_version\":\"0.1\",\"target_version\":\"0.2\"}"))
  expectError "empty request id"
    ((request "w" "[]" (scheme "{\"row\":null,\"items\":[]}")).replace "\"r1\"" "\"\"")
  expectError "unknown request member"
    ((request "w" "[]" (scheme "{\"row\":null,\"items\":[]}")).replace
      "\"gamma_version\":\"0.1\"" "\"extra\":1,\"gamma_version\":\"0.1\"")
  expectError "no checked words"
    "{\"request_id\":\"r1\",\"checked_words\":[],\"erased_word_types\":[],\
      \"gamma_version\":\"0.1\",\"target_version\":\"0.1\"}"
  expectError "erased word type missing for a checked word"
    ((request "w" "[]" (scheme "{\"row\":null,\"items\":[]}")).replace "\"word\":\"w\"" "\"word\":\"other\"")
  expectError "unknown atom kind"
    (request "w" "[{\"kind\":\"halt\"}]" (scheme "{\"row\":null,\"items\":[]}"))

end Firth.CompilerTest

def main : IO Unit := Firth.CompilerTest.main
