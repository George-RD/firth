import smt.Firth.SmtBoundary

namespace Firth.Smt

#print axioms encodeSort_preserves
#print axioms encodeIntExpr_sound
#print axioms encodePredicate_semantics
#print axioms encodeFormula_semantics
private def fail (message : String) : IO α :=
  throw <| IO.userError message

private def expectEq [BEq α] [Repr α] (actual expected : α) (message : String) : IO Unit :=
  if actual == expected then pure ()
  else fail s!"{message}\nactual: {repr actual}\nexpected: {repr expected}"

private def expectTrue (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else fail message

 def runTests : IO Unit := do
  let valuation : Valuation :=
    { integers := [("x", 3), ("y", 5)]
      booleans := [("flag", true)] }
  let expression := IntExpr.add (.variable "x") (.scale 2 (.literal 4))
  expectEq (evalQfLiaInt valuation (encodeIntExpr expression))
    (evalInt valuation expression)
    "integer encoding preserves source evaluation"
  let predicates : List Predicate :=
    [ .truth
    , .falsity
    , .boolVariable "flag"
    , .not (.boolVariable "flag")
    , .and (.intLt (.variable "x") (.variable "y")) .truth
    , .or .falsity (.boolVariable "flag")
    , .intEq expression (.literal 11)
    , .intNe (.variable "x") (.literal 0)
    , .intLe (.variable "x") (.literal 3)
    , .intLt (.variable "x") (.literal 4) ]
  for predicate in predicates do
    expectEq (evalEncodedPredicate valuation (encodePredicate predicate))
      (evalPredicate valuation predicate)
      "registered pure predicate encoding preserves source evaluation"
  let formula : Formula :=
    { premises := [.intLt (.variable "x") (.variable "y")]
      conclusions := [.intEq expression (.literal 11)] }
  match encodeFormula formula with
  | none => fail "supported formula was rejected by QF_LIA encoding"
  | some encoded =>
      expectEq (evalEncodedFormula valuation (some encoded))
        (evalFormula valuation formula)
        "formula evaluation uses encoded premises and conclusions"
  expectEq (encodeSort .integer) QfLiaSort.integer
    "integer sort has an explicit QF_LIA correspondence"
  expectEq (encodeSort .boolean) QfLiaSort.boolean
    "boolean sort has an explicit QF_LIA correspondence"
  match serialiseQfLia
      { premises := [.intEq (.variable "x") (.literal 3)]
        conclusions := [.boolVariable "flag"] } with
  | .ok smtLib =>
      expectTrue (smtLib.contains "(declare-fun i0 () Int)")
        "integer binding uses the encoded QF_LIA sort"
      expectTrue (smtLib.contains "(declare-fun b0 () Bool)")
        "boolean binding uses the encoded QF_LIA sort"
  | .error error => fail s!"supported binding sorts were rejected: {repr error}"
  for predicate in [
      Predicate.named "math.unknown" "1" [],
      Predicate.nonlinear "x * x",
      Predicate.worldSensitive "read-world" ] do
    expectEq (encodePredicate predicate) none
      "unsupported predicate is excluded from QF_LIA encoding"
    expectTrue (classify { premises := [], conclusions := [predicate] } != .qfLia)
      "unsupported predicate is excluded from the classified QF_LIA fragment"
  match checkedSmtRequest defaultSolverProfile
      { premises := [], conclusions := [.worldSensitive "effect"] } with
  | .error (.unsupportedFragment .worldEffect) => pure ()
  | result => fail s!"effectful predicate was accepted: {repr result}"
  IO.println "all SMT encoder translation proof tests passed"

 end Firth.Smt

 def main : IO Unit := Firth.Smt.runTests
