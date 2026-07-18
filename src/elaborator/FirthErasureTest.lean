import elaborator.Firth.Erasure

open Firth.Elaborator
open Firth.Interpreter

private def fail {α : Type} (message : String) : IO α := throw <| IO.userError message

private def parsed (source : String) : IO WordDefinition :=
  match parse source with
  | .success { declarations := [.word word], .. } => pure word
  | other => fail s!"expected one word, got {repr other}"

private def join (head : String) : List String → String
  | [] => head
  | next :: rest => join (head ++ "," ++ next) rest

mutual
  def atomShape : Atom → String
    | .dup => "dup"
    | .drop => "drop"
    | .swap => "swap"
    | .dip => "dip"
    | .prim name => "prim:" ++ name
    | .word name => "word:" ++ name
    | .quotation body => "[" ++ programShape body ++ "]"
    | .lit _ => "lit"
    | .quote => "quote"
    | .call => "call"
    | .compose => "compose"
    | .ifThenElse => "if"
    | .push _ => "push"

  def programShape : Program → String
    | .empty => ""
    | .cons head tail => join (atomShape head) (match programShape tail with | "" => [] | text => [text])
end

private def shapes (program : KernelProgram) : List String :=
  program.map (fun item => atomShape item.atom)

private def atomProgram : List Atom → Program
  | [] => .empty
  | atom :: rest => .cons atom (atomProgram rest)

private def arithmetic : EffectEnv :=
  { primitive := fun name => if name == "+" then some { input := [.many, .many], output := [.many] } else none }

private def usageEnv : EffectEnv :=
  { primitive := fun name => if name == "consume" then some { input := [.many], output := [] } else none }

private def wideEnv : EffectEnv :=
  { primitive := fun name => if name == "wide" then
      some { input := [.many, .many, .many, .many, .many, .many], output := [.many] }
    else none }

private def expectShapes (word : WordDefinition) (expected : List String) : IO Unit :=
  match erase arithmetic word.effect word.body with
  | .ok result =>
      let actual := shapes result.program
      if actual != expected then fail s!"kernel mismatch: {repr actual} != {repr expected}" else pure ()
  | .error error => fail s!"unexpected erasure error: {repr error}"

private def expectKernelAtoms (word : WordDefinition) (expected : List Atom) : IO Unit :=
  match erase arithmetic word.effect word.body with
  | .ok result =>
      let actual := result.program.map (·.atom)
      if actual != expected then fail s!"kernel golden mismatch: {repr actual} != {repr expected}"
      else pure ()
  | .error error => fail s!"unexpected golden erasure error: {repr error}"

private def expectErrorAt (word : WordDefinition) (expected : ErasureError → Bool) (span : Span) : IO Unit :=
  match erase arithmetic word.effect word.body with
  | .error error =>
      if expected error then
        let actual := match error with
          | .duplicateLocal _ actual | .unboundLocal _ actual | .unsupportedCapture _ actual
          | .missingStackValue actual | .linearCopy _ actual | .linearUnused _ actual
          | .unresolvedEffect _ actual | .effectUnderflow _ actual | .unsupportedLiteral actual
          | .unsupportedAtom _ actual | .usageMismatch _ actual => actual
        if actual == span then pure () else fail s!"span mismatch for {repr error}: {repr actual} != {repr span}"
      else fail s!"wrong error: {repr error}"
  | .ok _ => fail "expected erasure failure"

def main : IO Unit := do
  -- The first two swaps are the canonical bottom-to-top selections. A mutation
  -- that adds the old leading swap or chooses an older copy changes this list.
  let add ← parsed ": add ( a:Int^many b:Int^many -- r:Int^many ) locals { a b } { a b prim + } ;"
  expectShapes add ["swap", "swap", "prim:+"]

  let deepFocus ← parsed ": deep-focus ( a:Int^many b:Int^many c:Int^many -- ) locals { a b c } { a } ;"
  expectShapes deepFocus ["[swap]", "dip", "swap", "swap", "drop", "swap", "drop"]
  let focusSpan := match deepFocus.body with
    | [.locals _ [.word _ span] _] => span
    | _ => panic! "focus fixture changed"
  match erase arithmetic deepFocus.effect deepFocus.body with
  | .ok { program := first :: _, .. } =>
      if first.childSpans == [focusSpan] then pure () else fail "focus quotation lost source provenance"
  | .ok _ => fail "focus fixture emitted no kernel"
  | .error error => fail s!"focus provenance failed: {repr error}"

  -- Every demand selects the most recently produced remaining identity.
  let repeated ← parsed ": repeated ( a:Int^many -- ) locals { a } { a a a } ;"
  expectShapes repeated ["dup", "dup", "swap", "[swap]", "dip", "swap"]

  let quoted ← parsed ": quoted ( a:Int^many -- q:Quote^many ) locals { a } { [ 1 ] } ;"
  expectShapes quoted ["[lit]", "swap", "drop"]

  -- The inner a shadows the outer a, and the outer identity is restored after
  -- the inner scope. The remaining outer b is then cleaned up canonically.
  let shadow ← parsed ": shadow ( a:Int^many b:Int^many -- ) locals { a b } { locals { a } { } a } ;"
  expectShapes shadow ["drop"]

  let shadowLinear ← parsed ": shadow-linear ( a:Int^many b:Handle^linear -- ) locals { a b } { locals { a } { a } a } ;"
  let shadowLinearSpan := match shadowLinear.body with
    | [.locals _ [.locals _ _ _, .word _ span] _] => span
    | _ => panic! "shadow-linear fixture changed"
  expectErrorAt shadowLinear (fun error => match error with
    | .linearUnused name _ => name == "a"
    | _ => false) shadowLinearSpan

  let inferred ← parsed ": inferred ( -- ) [ 1 2 prim + ] ;"
  match erase arithmetic inferred.effect inferred.body with
  | .ok { program := [quotation], .. } =>
      if quotation.childSpans.length == 3 then pure () else fail "quotation child spans were lost"
  | .ok result => fail s!"unexpected inferred quotation: {repr result.program}"
  | .error error => fail s!"quotation inference failed: {repr error}"

  -- The exact Except.ok shadowing probe: once the innermost `a` is consumed,
  -- resolution must fail instead of falling through to the outer `a`.
  let exhaustedShadow ← parsed ": exhausted-shadow ( a:Int^many -- ) locals { a } { locals { a } { a } a } ;"
  match erase arithmetic exhaustedShadow.effect exhaustedShadow.body with
  | .error (.unboundLocal name _) => if name == "a" then pure () else fail "wrong exhausted-shadow name"
  | .error error => fail s!"wrong exhausted-shadow error: {repr error}"
  | .ok result => fail s!"exhausted shadow incorrectly succeeded: {repr result}"

  -- Quotation inference must widen from the body shape to the six inputs
  -- required by this single primitive.
  let wide ← parsed ": wide ( -- ) [ prim wide ] ;"
  match erase wideEnv wide.effect wide.body with
  | .ok { program := [quotation], .. } =>
      if shapes [quotation] == ["[prim:wide]"] then pure () else fail "wide quotation shape changed"
  | .ok result => fail s!"unexpected wide quotation: {repr result.program}"
  | .error error => fail s!"wide quotation inference failed: {repr error}"

  -- Fixed kernel goldens transcribed from the normative focus, demand, cleanup,
  -- and quotation rules. None of these expected programs is produced by `erase`.
  expectKernelAtoms add [.swap, .swap, .prim "+"]
  expectKernelAtoms deepFocus
    [.quotation (atomProgram [.swap]), .dip, .swap, .swap, .drop, .swap, .drop]
  expectKernelAtoms repeated
    [.dup, .dup, .swap, .quotation (atomProgram [.swap]), .dip, .swap]
  expectKernelAtoms shadow [.drop]
  expectKernelAtoms inferred
    [.quotation (atomProgram [.lit (.nat 1), .lit (.nat 2), .prim "+"])]

  -- Capture is checked recursively and the diagnostic retains the child use span.
  let capture ← parsed ": capture ( a:Int^many -- ) locals { a } { [ [ a ] ] } ;"
  let captureSpan := match capture.body with
    | [.locals _ [.quotation [.quotation [.word _ span] _] _] _] => span
    | _ => panic! "capture fixture changed"
  expectErrorAt capture (fun error => match error with
    | .unsupportedCapture name _ => name == "a"
    | _ => false) captureSpan

  let duplicate ← parsed ": duplicate ( a:Int^many -- ) locals { a a } { a } ;"
  let duplicateSpan := match duplicate.body with
    | [.locals [_, second] _ _] => second.span
    | _ => panic! "duplicate fixture changed"
  expectErrorAt duplicate (fun error => match error with
    | .duplicateLocal name _ => name == "a"
    | _ => false) duplicateSpan

  let unbound ← parsed ": unbound ( a:Int^many -- ) locals { a } { missing } ;"
  let unboundSpan := match unbound.body with
    | [.locals _ [.word _ span] _] => span
    | _ => panic! "unbound fixture changed"
  expectErrorAt unbound (fun error => match error with
    | .unboundLocal name _ => name == "missing"
    | _ => false) unboundSpan

  let linearCopy ← parsed ": lin ( h:Handle^linear -- ) locals { h } { h h } ;"
  let linearCopySpan := match linearCopy.body with
    | [.locals _ [.word _ _, .word _ span] _] => span
    | _ => panic! "linear-copy fixture changed"
  expectErrorAt linearCopy (fun error => match error with
    | .linearCopy name _ => name == "h"
    | _ => false) linearCopySpan

  let linearUnused ← parsed ": unused-h ( h:Handle^linear -- ) locals { h } { } ;"
  let linearBindingSpan := match linearUnused.body with
    | [.locals [binding] _ _] => binding.span
    | _ => panic! "linear-unused fixture changed"
  expectErrorAt linearUnused (fun error => match error with
    | .linearUnused name _ => name == "h"
    | _ => false) linearBindingSpan

  let explicitDrop ← parsed ": explicit-drop ( h:Handle^linear -- ) locals { h } { h drop } ;"
  let dropSpan := match explicitDrop.body with
    | [.locals _ [.word _ _, .atom _ span] _] => span
    | _ => panic! "explicit-drop fixture changed"
  expectErrorAt explicitDrop (fun error => match error with
    | .linearUnused name _ => name == "h"
    | _ => false) dropSpan

  let usage ← parsed ": usage ( h:Handle^linear -- ) locals { h } { h prim consume } ;"
  let usageSpan := match usage.body with
    | [.locals _ [.word _ _, .primitive _ span] _] => span
    | _ => panic! "usage fixture changed"
  match erase usageEnv usage.effect usage.body with
  | .error (.usageMismatch name span) =>
      if name == "consume" && span == usageSpan then pure () else fail "usage mismatch span was incorrect"
  | .error error => fail s!"wrong usage error: {repr error}"
  | .ok _ => fail "linear value was accepted by many input"

  let deep ← parsed ": deep ( a:Int^many b:Int^many c:Int^many d:Int^many e:Int^many -- ) locals { a b c d e } { } ;"
  match erase arithmetic deep.effect deep.body with
  | .ok result => if result.warnings.any (fun warning => warning.code == "LOCAL_DEPTH") then pure () else fail "missing LOCAL_DEPTH warning"
  | .error error => fail s!"depth lint unexpectedly failed: {repr error}"

  let nestedDepth ← parsed ": nested-depth ( -- ) [ locals { a b c d e } { a b c d e } ] ;"
  match erase arithmetic nestedDepth.effect nestedDepth.body with
  | .ok result =>
      if result.warnings.any (fun warning => warning.code == "LOCAL_DEPTH") then pure ()
      else fail "missing nested LOCAL_DEPTH warning"
  | .error error => fail s!"nested depth lint unexpectedly failed: {repr error}"

  IO.println "erasure tests passed"

#print axioms Firth.Elaborator.erase_sound_under
#print axioms Firth.Elaborator.erase_sound
