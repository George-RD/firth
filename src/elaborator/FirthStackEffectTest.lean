import elaborator.Firth.StackEffect

open Firth.Elaborator
open Firth.Elaborator.StackEffect
open Firth.Interpreter

private def fail (message : String) : IO α := throw <| IO.userError message

private def point (offset : Nat) : Position :=
  { offset, line := 1, column := offset + 1 }

private def span (start stop : Nat) : Span :=
  { start := point start, stop := point stop }

private def located (offset : Nat) (atom : Atom) (childSpans : List Span := [])
    (children : KernelProgram := []) : LocatedKernel :=
  { span := span offset (offset + 1), atom, childSpans, children }

private def stack (tail : AStack) (values : List AType) : AStack :=
  values.foldl AStack.snoc tail

private def rigid (name : String := "ρ") : AStack := .row (.rigid name)
private def intType : AType := .base "Int" .many
private def boolType : AType := .base "Bool" .many
private def handleType : AType := .base "Handle" .linear

private def scheme (input output : List AType) : Scheme :=
  { rowVariables := ["ρ"], input := stack rigid input, output := stack rigid output }

private def exactScheme (input output : List AType) : Scheme :=
  { rowVariables := [], input := stack .empty input, output := stack .empty output }

private def primitives : String → Option Scheme
  | "add" => some (scheme [intType, intType] [intType])
  | "not" => some (scheme [boolType] [boolType])
  | "open" => some (scheme [] [handleType])
  | "close" => some (scheme [handleType] [])
  | "consumeWorld" => some (scheme [.base "World" .linear] [])
  | _ => none

private def env : Env := { literal := defaultLiteralType, primitive := primitives }

private def expectEq [BEq α] [Repr α] (actual expected : α) (message : String) : IO Unit :=
  if actual == expected then pure () else fail s!"{message}\nactual: {repr actual}\nexpected: {repr expected}"

private def expectEffect (name : String) (program : KernelProgram) (expected : Effect) : IO Unit :=
  match infer env program with
  | .ok actual => expectEq actual expected name
  | .error diagnostic => fail s!"{name}: unexpected diagnostic {repr diagnostic}"

private def expectFailure (name code : String) (expectedOffset : Nat)
    (result : Except Diagnostic α) : IO Unit :=
  match result with
  | .ok _ => fail s!"{name}: expected {code}"
  | .error diagnostic => do
      expectEq diagnostic.code code s!"{name}: code"
      expectEq diagnostic.primary.start.offset expectedOffset s!"{name}: primary span"

private def expectFailureState (name code : String) (expectedOffset : Nat)
    (expectedState : AStack) (result : Except Diagnostic α) : IO Unit :=
  match result with
  | .ok _ => fail s!"{name}: expected {code}"
  | .error diagnostic => do
      expectEq diagnostic.code code s!"{name}: code"
      expectEq diagnostic.primary.start.offset expectedOffset s!"{name}: primary span"
      expectEq diagnostic.state expectedState s!"{name}: pre-atom stack"

private def expectTopQuotationUsage (name : String) (program : KernelProgram)
    (expected : AUsage) : IO Unit :=
  match infer env program with
  | .ok { output := .snoc _ (.quotation _ _ actual), .. } =>
      expectEq actual expected name
  | .ok effect => fail s!"{name}: expected a quotation output, got {repr effect}"
  | .error diagnostic => fail s!"{name}: unexpected diagnostic {repr diagnostic}"

private def expectCheckSuccess (name : String) (declared : Scheme)
    (program : KernelProgram) : IO Unit :=
  match check env declared program (span 90 91) with
  | .ok _ => pure ()
  | .error diagnostic => fail s!"{name}: unexpected diagnostic {repr diagnostic}"

private def parserWord (source : String) : IO WordDefinition :=
  match parse source with
  | .success { declarations := [.word word], .. } => pure word
  | .success _ => fail s!"expected one word: {source}"
  | .failure errors => fail s!"parse failed: {repr errors}"

private def erased (effects : EffectEnv) (word : WordDefinition) : IO KernelProgram :=
  match erase effects word.effect word.body with
  | .ok result => pure result.program
  | .error error => fail s!"erasure failed: {repr error}"

private def declaration (source : String) (effects : EffectEnv) : IO Definition := do
  let word ← parserWord source
  pure { name := word.name, declared := word.effect, program := ← erased effects word, span := word.span }

def runStackEffectTests : IO Unit := do
  expectEffect "literal golden" [located 0 (.lit (.nat 7))]
    { input := .row (.mvar 0), output := stack (.row (.mvar 0)) [intType] }

  expectEffect "dup golden" [located 0 .dup]
    { input := stack (.row (.mvar 1)) [.mvar 0 .many],
      output := stack (.row (.mvar 1)) [.mvar 0 .many, .mvar 0 .many] }

  expectEffect "effect composition golden"
    [located 0 (.lit (.nat 1)), located 1 (.lit (.nat 2)), located 2 (.prim "add")]
    { input := .row (.mvar 0), output := stack (.row (.mvar 0)) [intType] }

  expectCheckSuccess "swap" (scheme [intType, boolType] [boolType, intType])
    [located 0 .swap]
  expectCheckSuccess "drop many" (scheme [intType] []) [located 0 .drop]

  let quoteInt := .cons (.lit (.nat 1)) .empty
  expectCheckSuccess "call" (scheme [] [intType])
    [located 0 (.quotation quoteInt) [span 1 2], located 3 .call]
  expectCheckSuccess "dip" (scheme [] [intType, intType])
    [located 0 (.lit (.nat 9)), located 2 (.quotation quoteInt) [span 3 4], located 5 .dip]
  let quoteBool := .cons (.lit (.bool true)) .empty
  expectCheckSuccess "compose and call" (scheme [] [intType, boolType])
    [located 0 (.quotation quoteInt) [span 1 2],
      located 3 (.quotation quoteBool) [span 4 5], located 6 .compose, located 7 .call]
  expectCheckSuccess "if" (scheme [] [intType])
    [located 0 (.lit (.bool true)), located 2 (.quotation quoteInt) [span 3 4],
      located 5 (.quotation quoteInt) [span 6 7], located 8 .ifThenElse]
  expectCheckSuccess "administrative push" (scheme [] [])
    [located 0 (.push (.world 7)), located 1 (.prim "consumeWorld")]
  expectCheckSuccess "linear quotation call" (scheme [handleType] [handleType])
    [located 0 .quote, located 1 .call]

  let quoteScheme : Scheme := {
    rowVariables := ["ρ", "σ"]
    input := stack (.row (.rigid "ρ")) [handleType]
    output := stack (.row (.rigid "ρ"))
      [.quotation (.row (.rigid "σ")) (stack (.row (.rigid "σ")) [handleType]) .linear] }
  expectCheckSuccess "quote transfers linear usage" quoteScheme [located 0 .quote]

  let quoteBody := .cons (.lit (.nat 1)) .empty
  expectEffect "quotation golden" [located 0 (.quotation quoteBody) [span 1 2]]
    { input := .row (.mvar 0),
      output := stack (.row (.mvar 0))
        [.quotation (.row (.mvar 1)) (stack (.row (.mvar 1)) [intType]) .many] }

  let polyEnv : Env := {
    literal := defaultLiteralType
    word := fun name => if name == "id" then some (scheme [] []) else none
    primitive := primitives }
  match infer polyEnv [located 0 (.lit (.nat 3)), located 1 (.word "id")] with
  | .ok effect => do
      let expected : Effect :=
        { input := .row (.mvar 0), output := stack (.row (.mvar 0)) [intType] }
      expectEq effect expected "prenex row instantiation"
  | .error diagnostic => fail s!"prenex row instantiation: {repr diagnostic}"

  expectFailure "unknown word" "firth.name.unknown-word" 9
    (infer env [located 9 (.word "missing")])
  expectFailure "non-quotation call" "firth.type.expected-quotation" 4
    (infer env [located 0 (.lit (.nat 1)), located 4 .call])
  expectFailure "occurs check" "firth.type.occurs-check" 5
    (infer env [located 0 .dup, located 5 .call])

  let oneIntState := stack .empty [intType]
  let oneIntInput := exactScheme [intType] []
  expectFailureState "swap underflow keeps pre-atom stack" "firth.type.stack-underflow" 7
    oneIntState (check env oneIntInput [located 7 .swap] (span 70 71))
  expectFailureState "dip underflow keeps pre-atom stack" "firth.type.stack-underflow" 8
    oneIntState (check env oneIntInput [located 8 .dip] (span 70 71))
  expectFailureState "compose underflow keeps pre-atom stack" "firth.type.stack-underflow" 9
    oneIntState (check env oneIntInput [located 9 .compose] (span 70 71))
  expectFailureState "if underflow keeps pre-atom stack" "firth.type.stack-underflow" 10
    oneIntState (check env oneIntInput [located 10 .ifThenElse] (span 70 71))

  let badNested := .cons (.lit (.nat 1)) (.cons .call .empty)
  expectFailure "nested quotation span" "firth.type.expected-quotation" 22
    (infer env [located 20 (.quotation badNested) [span 21 22, span 22 23]])
  let inconsistentChildren := located 23 (.quotation .empty) []
    [located 24 (.lit (.nat 1))]
  expectFailure "provenance cannot change quotation semantics"
    "firth.elaboration.provenance-mismatch" 23
    (infer env [inconsistentChildren, located 25 .call])

  let noLiterals : Env := { primitive := primitives }
  expectFailure "literal requires Gamma" "firth.type.unknown-literal" 31
    (infer noLiterals [located 31 (.lit (.nat 1))])
  expectFailure "pushed literal requires Gamma" "firth.type.unknown-literal" 32
    (infer noLiterals [located 32 (.push (.literal (.nat 1)))])
  let linearLiterals : Env := {
    literal := fun _ => some handleType
    primitive := primitives }
  expectFailure "literal must be many" "firth.linearity.literal-not-many" 33
    (infer linearLiterals [located 33 (.lit (.nat 1))])

  let forgedCapture := .cons (.push (.world 1)) .empty
  expectFailure "pushed quotation usage is checked"
    "firth.linearity.invalid-quotation-usage" 34
    (infer env [located 34 (.push (.quotation forgedCapture .many)), located 35 .drop])

  let linearInput := scheme [handleType] []
  expectFailure "linear duplication" "firth.linearity.usage-mismatch" 11
    (check env linearInput [located 11 .dup, located 12 (.prim "close")] (span 20 21))
  expectFailure "linear discard" "firth.linearity.usage-mismatch" 13
    (check env linearInput [located 13 .drop] (span 20 21))
  expectFailure "literal cannot satisfy linear output" "firth.type.declared-effect-mismatch" 30
    (check env (exactScheme [] [handleType]) [located 0 (.lit (.nat 1))] (span 30 31))
  match check env (exactScheme [] [handleType]) [located 0 (.lit (.nat 1))] (span 30 31) with
  | .error { expected := some expected, actual := some actual, .. } => do
      expectEq expected (stack .empty [handleType]) "declared mismatch expected stack"
      expectEq actual (stack .empty [intType]) "declared mismatch actual stack"
  | .error diagnostic => fail s!"declared mismatch omitted expected/actual stacks: {repr diagnostic}"
  | .ok _ => fail "declared mismatch unexpectedly accepted"

  let capturedLinear := .cons (.push (.world 1)) .empty
  expectFailure "quotation capture is linear" "firth.linearity.usage-mismatch" 7
    (infer env [located 0 (.quotation capturedLinear) [span 1 2], located 7 .drop])

  let manyQuotation := Program.empty
  expectTopQuotationUsage "compose usage linear meet many"
    [located 50 (.quotation capturedLinear), located 51 (.quotation manyQuotation),
      located 52 .compose]
    .linear
  expectTopQuotationUsage "compose usage many meet linear"
    [located 53 (.quotation manyQuotation), located 54 (.quotation capturedLinear),
      located 55 .compose]
    .linear
  expectTopQuotationUsage "compose usage linear meet linear"
    [located 56 (.quotation capturedLinear), located 57 (.quotation capturedLinear),
      located 58 .compose]
    .linear
  expectFailure "compose usage meet remains linear" "firth.linearity.usage-mismatch" 62
    (infer env [located 59 (.quotation capturedLinear), located 60 (.quotation manyQuotation),
      located 61 .compose, located 62 .drop])

  let trueLinear := [located 0 .quote, located 2 (.quotation .empty), located 4 .ifThenElse]
  expectFailure "if rejects linear branch" "firth.linearity.usage-mismatch" 4
    (check env (scheme [boolType, handleType] []) trueLinear (span 20 21))

  let intQuote := .cons (.lit (.nat 1)) .empty
  let boolQuote := .cons (.lit (.bool true)) .empty
  expectFailure "if branch effect mismatch" "firth.type.branch-mismatch" 8
    (infer env [located 0 (.lit (.bool true)), located 2 (.quotation intQuote) [span 3 4],
      located 5 (.quotation boolQuote) [span 6 7], located 8 .ifThenElse])

  let notQuote := .cons (.prim "not") .empty
  expectFailure "compose middle mismatch" "firth.type.quotation-compose-mismatch" 8
    (infer env [located 0 (.quotation intQuote) [span 1 2],
      located 4 (.quotation notQuote) [span 5 6], located 8 .compose])

  match typedHole env rigid [located 0 (.lit (.nat 4)), located 2 (.lit (.bool true))] (span 9 9) with
  | .error diagnostic => fail s!"typed hole failed: {repr diagnostic}"
  | .ok hole => do
      expectEq hole.span (span 9 9) "typed hole span"
      expectEq hole.state (stack rigid [intType, boolType]) "typed hole exact state"

  match typedHole env (.row (.mvar 0)) [located 40 .dup] (span 41 41) with
  | .error diagnostic => fail s!"typed hole freshness collision: {repr diagnostic}"
  | .ok hole =>
      expectEq hole.state
        (stack (.row (.mvar 1)) [.mvar 0 .many, .mvar 0 .many])
        "typed hole reserves caller metavariables"

  let effects : EffectEnv := {
    primitive := fun name => if name == "+" then some { input := [.many, .many], output := [.many] }
      else none }
  let increment ← declaration
    ": inc (forall ρ; ρ n:Int -- ρ n:Int) 1 prim + ;" effects
  match schemeOfEffect increment.declared with
  | .error diagnostic => fail s!"surface signature conversion failed: {repr diagnostic}"
  | .ok declared =>
      let checkEnv : Env := {
        literal := defaultLiteralType
        primitive := fun name => if name == "+" then some (scheme [intType, intType] [intType]) else none }
      match check checkEnv declared increment.program increment.declared.span with
      | .ok _ => pure ()
      | .error diagnostic => fail s!"parse-erasure-check integration failed: {repr diagnostic}"

  let invalidRows ← parserWord ": bad (forall ρ; x:Int ρ -- ρ) ;"
  match invalidRows.effect.input with
  | _ :: .row _ rowSpan :: _ =>
      expectFailure "row must be the stack tail" "firth.type.invalid-signature"
        rowSpan.start.offset (schemeOfEffect invalidRows.effect)
  | _ => fail "invalid-row fixture did not preserve the misplaced row"

  let universalIdentity : Scheme := {
    rowVariables := ["ρ"]
    input := .row (.rigid "ρ")
    output := .row (.rigid "ρ") }
  expectFailure "declared row is universal" "firth.type.stack-underflow" 42
    (check env universalIdentity [located 42 .drop, located 43 (.lit (.nat 1))] (span 44 45))
  let distinctRows : Scheme := {
    rowVariables := ["ρ", "σ"]
    input := .row (.rigid "ρ")
    output := .row (.rigid "σ") }
  expectFailure "distinct declared rows stay rigid" "firth.type.declared-effect-mismatch" 46
    (check env distinctRows [] (span 46 47))

  let nestedSource := ": nested (forall ρ; ρ -- ρ) [ [ 1 call ] ] drop ;"
  let nestedWord ← parserWord nestedSource
  let nestedProgram ← erased {} nestedWord
  let innerCallSpan := match nestedWord.body with
    | [.quotation [.quotation [_, .atom "call" callSpan] _] _, .atom "drop" _] => callSpan
    | _ => panic! "deep quotation fixture changed"
  expectFailure "deep quotation keeps atom span" "firth.type.expected-quotation"
    innerCallSpan.start.offset (infer env nestedProgram)

  let loop ← declaration ": loop (forall ρ; ρ -- ρ) loop ;"
    { word := fun name => if name == "loop" then some { input := [], output := [] } else none }
  match checkDictionary env [loop] with
  | .ok [{ name := "loop", .. }] => pure ()
  | .ok checked => fail s!"recursive dictionary shape: {repr checked}"
  | .error diagnostic => fail s!"recursive dictionary rejected: {repr diagnostic}"

  let recursiveEffects : EffectEnv := {
    word := fun name => if name == "left" || name == "right" then some { input := [], output := [] }
      else none }
  let left ← declaration ": left (forall ρ; ρ -- ρ) right ;" recursiveEffects
  let right ← declaration ": right (forall ρ; ρ -- ρ) left ;" recursiveEffects
  match checkDictionary env [left, right] with
  | .ok [_, _] => pure ()
  | .ok checked => fail s!"mutual recursion shape: {repr checked}"
  | .error diagnostic => fail s!"mutual recursion rejected: {repr diagnostic}"

  let duplicateFirst := { left with name := "duplicate", span := span 10 11 }
  let duplicateSecond := { right with name := "duplicate", span := span 20 21 }
  expectFailure "duplicate blames later definition" "firth.name.duplicate-word" 20
    (checkDictionary env [duplicateFirst, duplicateSecond])

  let badLoop ← declaration ": loop (forall ρ; ρ -- ρ) 1 loop ;"
    { word := fun name => if name == "loop" then some { input := [], output := [] } else none }
  match badLoop.program with
  | _ :: _ :: _ =>
      expectFailure "recursive declared mismatch" "firth.type.declared-effect-mismatch"
        badLoop.declared.span.start.offset (checkDictionary env [badLoop])
  | _ => fail "recursive mismatch fixture did not erase to two atoms"

  IO.println "stack-effect tests passed"

def main : IO Unit := runStackEffectTests
