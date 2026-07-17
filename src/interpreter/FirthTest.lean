import Firth.Interpreter
import Firth.KernelMetatheory

open Firth.Interpreter

example (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (config next₁ next₂ : Config) :
    HasSuccessor gamma dictionary costs config next₁ →
      HasSuccessor gamma dictionary costs config next₂ → next₁ = next₂ := by
  exact step_deterministic gamma dictionary costs config next₁ next₂

example (costs : CostTable) (left right : List Atom) :
    sequenceCost costs.atom (left ++ right) =
      sequenceCost costs.atom left + sequenceCost costs.atom right := by
  exact atomSequenceCost_append costs left right

def expectTerminalStack (expected : Stack) : RunResult → Bool
  | .terminal config _ _ => config.stack == expected
  | _ => false

def expectTerminalCost (expected : Nat) : RunResult → Bool
  | .terminal _ _ cost => cost == expected
  | _ => false

def expectOutOfFuel (result : RunResult) : Bool :=
  match result with
  | .outOfFuel _ _ _ => true
  | _ => false

def runTest (name : String) (condition : Bool) : IO Unit :=
  if condition then pure () else throw <| IO.userError s!"test failed: {name}"

def main : IO Unit := do
  let gamma := defaultGamma
  let d := emptyDictionary
  let c := defaultCosts
  let lit value := Value.literal (.nat value)
  -- S-LIT, S-DUP, S-DROP, S-SWAP.
  let structural :=
    { stack := ([] : Stack),
      program := .cons (.lit (.nat 7)) (.cons (.lit (.nat 8)) (.cons .drop .empty)) }
  runTest "structural atoms"
    (expectTerminalStack [lit 7] (run gamma d c 20 structural))
  runTest "dup preserves both values"
    (expectTerminalStack [lit 7, lit 7]
      (run gamma d c 20 { stack := [], program := .cons (.lit (.nat 7)) (.cons .dup .empty) }))
  runTest "swap preserves order"
    (expectTerminalStack [lit 7, lit 8]
      (run gamma d c 20 { stack := [], program := (.cons (.lit (.nat 7))
        (.cons (.lit (.nat 8)) (.cons .swap .empty))) }))
  runTest "parameterised cost"
    (expectTerminalCost 3 (run gamma d { c with atom := fun _ => 3 } 10
      { stack := [], program := .cons (.lit (.nat 0)) .empty }))
  -- S-QUOT, S-CALL, and S-PUSH.
  let callResult := run gamma d c 20
    { stack := [], program := .cons (.quotation (.cons (.lit (.nat 9)) .empty))
        (.cons .call .empty) }
  runTest "quotation call" (expectTerminalStack [lit 9] callResult)
  let closedQuotationResult := run gamma d c 20
    { stack := [], program := .cons (.quotation .empty) .empty }
  runTest "S-QUOT closed usage is many" (match closedQuotationResult with
    | .terminal { stack := [.quotation .empty .many], .. } _ _ => true
    | _ => false)
  let nestedCaptureQuotationResult := run gamma d c 20
    { stack := [], program := .cons (.quotation
        (.cons (.push (.world 0)) .empty)) .empty }
  runTest "S-QUOT recursive capture footprint is linear" (match nestedCaptureQuotationResult with
    | .terminal { stack := [.quotation body .linear], .. } _ _ =>
        body == .cons (.push (.world 0)) .empty
    | _ => false)
  -- S-DIP preserves the value by administrative push.
  let dipResult := run gamma d c 20
    { stack := [], program := .cons (.lit (.nat 4))
        (.cons (.quotation (.cons (.lit (.nat 5)) .empty)) (.cons .dip .empty)) }
  runTest "dip" (expectTerminalStack [lit 4, lit 5] dipResult)
  -- S-COMP, then S-CALL.
  let composed := .cons (.quotation (.cons (.lit (.nat 1)) .empty))
    (.cons (.quotation (.cons (.lit (.nat 2)) .empty)) (.cons .compose (.cons .call .empty)))
  runTest "compose" (expectTerminalStack [lit 2, lit 1]
    (run gamma d c 30 { stack := [], program := composed }))
  -- S-QUOTE captures a linear World value and records linear ownership.
  let capture := .cons (.prim "makeWorld") (.cons .quote .empty)
  let captureResult := run gamma d c 20 { stack := [], program := capture }
  let capturedLinear := match captureResult with
    | .terminal { stack := .quotation body .linear :: _, .. } _ _ =>
        body == .cons (.push (.world 0)) .empty
    | _ => false
  runTest "linear quote capture" capturedLinear
  runTest "compose usage meet" (match step gamma d c
    { stack := [.quotation .empty .linear, .quotation .empty .many], program := .cons .compose .empty } with
    | .stepped { stack := [.quotation .empty .linear], program := .empty } 1 => true
    | _ => false)
  runTest "compose many then linear remains linear" (match step gamma d c
    { stack := [.quotation .empty .many, .quotation .empty .linear], program := .cons .compose .empty } with
    | .stepped { stack := [.quotation .empty .linear], program := .empty } 1 => true
    | _ => false)
  runTest "compose many and many remains many" (match step gamma d c
    { stack := [.quotation .empty .many, .quotation .empty .many], program := .cons .compose .empty } with
    | .stepped { stack := [.quotation .empty .many], program := .empty } 1 => true
    | _ => false)
  -- S-IF-T and S-IF-F, with exact selected values.
  let ifProgram condition :=
    .cons (.lit (.bool condition))
      (.cons (.quotation (.cons (.lit (.nat 1)) .empty))
        (.cons (.quotation (.cons (.lit (.nat 2)) .empty)) (.cons .ifThenElse .empty)))
  runTest "if true" (expectTerminalStack [lit 1]
    (run gamma d c 20 { stack := [], program := ifProgram true }))
  runTest "if false" (expectTerminalStack [lit 2]
    (run gamma d c 20 { stack := [], program := ifProgram false }))
  -- S-WORD and S-PRIM.
  let words : Dictionary := fun name =>
    if name == "one" then some { type := { rowVariables := ["ρ"], input := .row "ρ", output := .snoc (.row "ρ") (.base .nat .many) },
                                    body := .cons (.lit (.nat 1)) .empty }
    else none
  runTest "dictionary word" (expectTerminalStack [lit 1]
    (run gamma words c 20 { stack := [], program := .cons (.word "one") .empty }))
  runTest "word cost" (expectTerminalCost 5
    (run gamma words { c with unfold := 4 } 20
      { stack := [], program := .cons (.word "one") .empty }))
  runTest "primitive add" (expectTerminalStack [lit 7]
    (run gamma d c 20 { stack := [], program := (.cons (.lit (.nat 3))
      (.cons (.lit (.nat 4)) (.cons (.prim "addNat") .empty))) }))
  runTest "primitive world" (expectTerminalStack []
    (run gamma d c 20 { stack := [], program := (.cons (.prim "makeWorld")
      (.cons (.prim "consumeWorld") .empty)) }))
  runTest "primitive cost" (expectTerminalCost 10
    (run gamma d { c with primitive := fun _ => 5 } 20
      { stack := [], program := (.cons (.prim "makeWorld")
        (.cons (.prim "consumeWorld") .empty)) }))
  -- A recursive word demonstrates that execution may diverge. Fuel is a driver
  -- artefact that keeps this executable total; it is not kernel semantics, and
  -- genuine kernel divergence remains divergence.
  let loopWords : Dictionary := fun name =>
    if name == "loop" then some { type := { rowVariables := ["ρ"], input := .row "ρ", output := .row "ρ" },
                                    body := .cons (.word "loop") .empty }
    else none
  runTest "fuel-bounded divergence"
    (expectOutOfFuel (run gamma loopWords c 12 { stack := [], program := .cons (.word "loop") .empty }))
  let customGamma := { gamma with
    literalType := fun _ => none
    primitive := fun name => if name == "custom" then
      some { input := .row "ρ", output := .snoc (.row "ρ") (.base .nat .many),
             delta := fun stack => some (.literal (.nat 42) :: stack) }
      else none }
  runTest "Gamma controls literals" (match run customGamma d c 2
    { stack := [], program := .cons (.lit (.nat 1)) .empty } with
    | .stuck _ 0 0 => true
    | _ => false)
  runTest "Gamma controls primitive delta" (expectTerminalStack [lit 42]
    (run customGamma d c 2 { stack := [], program := .cons (.prim "custom") .empty }))
  -- The elaborator is the rejection point for malformed or ill-typed input;
  -- a stuck result here records that the unchecked driver received such input.
  runTest "malformed input is stuck" (match run gamma d c 2
    { stack := [], program := .cons .drop .empty } with
    | .stuck _ 0 0 => true
    | _ => false)
  runTest "S-PUSH has zero kappa cost" (match step gamma d { c with atom := fun _ => 99 }
    { stack := [], program := .cons (.push (.literal (.nat 9))) .empty } with
    | .stepped { stack := [Value.literal (.nat 9)], program := .empty } 0 => true
    | _ => false)
  runTest "one transition with one fuel" (expectTerminalStack [lit 1]
    (run gamma d c 1 { stack := [], program := .cons (.lit (.nat 1)) .empty }))
  runTest "terminal needs no fuel"
    (match run gamma d c 0 { stack := [], program := .empty } with
     | .terminal _ 0 0 => true
     | _ => false)
  IO.println "all interpreter tests passed"
