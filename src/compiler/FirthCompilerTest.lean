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

private def scheme (output : String) : String :=
  "{\"row_variables\":[],\"input\":{\"row\":null,\"items\":[]},\"output\":" ++ output ++ "}"

private def intOutput : String :=
  "{\"row\":null,\"items\":[{\"kind\":\"base\",\"name\":\"Int\",\"usage\":\"many\"}]}"

private def request (name program : String) (type : String := scheme intOutput) : String :=
  "{\"request_id\":\"r1\",\"checked_words\":[{\"name\":\"" ++ name
    ++ "\",\"checking_state\":\"checked\",\"proof_state\":\"available\",\"program\":" ++ program
    ++ "}],\"erased_word_types\":[{\"word\":\"" ++ name ++ "\",\"type\":" ++ type
    ++ "}],\"gamma_version\":\"0.1\",\"target_version\":\"0.1\"}"

private def literal (value : Nat) : String :=
  "{\"kind\":\"lit\",\"value\":{\"type\":\"nat\",\"value\":" ++ toString value ++ "}}"

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
  expectEqual "boolean tag" "0101" (Digest.toHex (Target.canonicalValue (.bool true)))
  expectEqual "world tag" "05" (Digest.toHex (Target.canonicalValue .world))
  expectEqual "quotation then call" "0201010000120006"
    (Digest.toHex (Target.canonicalCode [.pushQuote [.pushLiteral (.int 9)] [] [], .call]))
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

def main : IO Unit := do
  encodingWitnesses
  mangleWitnesses
  wordTypeWitnesses

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
  expectContains "debug locations map instructions to atoms"
    (request "conditional"
      ("[{\"kind\":\"lit\",\"value\":{\"type\":\"bool\",\"value\":false}},"
        ++ "{\"kind\":\"quotation\",\"body\":[" ++ literal 42 ++ "]},"
        ++ "{\"kind\":\"quotation\",\"body\":[" ++ literal 0 ++ "]},{\"kind\":\"if\"}]"))
    "{\"word\":\"conditional\",\"target_word\":\"conditional\",\"instruction\":3,\"kernel_atom\":3}"
  expectContains "every control atom lowers"
    (request "control"
      "[{\"kind\":\"dup\"},{\"kind\":\"drop\"},{\"kind\":\"swap\"},{\"kind\":\"dip\"},\
        {\"kind\":\"call\"},{\"kind\":\"compose\"},{\"kind\":\"quote\"}]"
      (scheme "{\"row\":null,\"items\":[]}"))
    "\"status\":\"success\""
  expectContains "the plus primitive lowers to the target registry name"
    (request "add" ("[" ++ literal 1 ++ "," ++ literal 2 ++ ",{\"kind\":\"prim\",\"name\":\"+\"}]"))
    "\"primitive\":\"addNat\""

  -- Fail-closed cases. Each is reported as a structured compile failure, not
  -- as a target program that would run.
  expectContains "unit literal has no target value"
    (request "u" "[{\"kind\":\"lit\",\"value\":{\"type\":\"unit\"}}]")
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
