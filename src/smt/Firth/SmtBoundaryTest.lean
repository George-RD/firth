import smt.Firth.SmtBoundary

namespace Firth.Smt

-- Every theorem the translation-soundness hashes cover is audited here, so a
-- proof that grew a new dependency is visible in the build output.
#print axioms encodeSort_preserves
#print axioms encodeIntExpr_sound
#print axioms encodePredicate_semantics
#print axioms encodePredicates_conjunction_sound
#print axioms encodePredicates_anyFalse_sound
#print axioms encodeFormula_semantics
#print axioms renderIntExpr_encode
#print axioms renderPredicate_of_encode
#print axioms renderPredicates_of_encode
#print axioms renderSmtLib_of_encodeFormula
#print axioms evalInt_isSome
#print axioms evalPredicate_isSome
#print axioms encodePredicates_mem
#print axioms evalConjunction_of_all_true
#print axioms evalAnyFalse_isSome
#print axioms evalAnyFalse_of_not_all_true
#print axioms checkedSmtRequest_formula
#print axioms validUnderBinding_of_scriptUnsatisfiable
#print axioms validUnderBinding_of_checkedRequest
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
  -- The adapter bridge's hypotheses, exercised concretely. The theorems
  -- themselves are Props and cannot be run; what a suite can check is that the
  -- facts they are stated over behave as the proofs assume.
  let bridgeFormula : Formula :=
    { premises := [.intLt (.literal 0) (.variable "x")]
      conclusions := [.intLt (.literal 0) (.add (.variable "x") (.literal 1))] }
  match checkedSmtRequest defaultSolverProfile bridgeFormula with
  | .error error => fail s!"a QF_LIA obligation was rejected: {repr error}"
  | .ok request =>
      expectEq request.formula bridgeFormula
        "the checked adapter does not rewrite the formula it was asked about"
      expectEq request.proofBindings defaultSmtProofBindings
        "every request carries the translation-rule and soundness-proof hashes"
      expectTrue (validSmtRequest request)
        "a request the checked adapter produced rebuilds to itself"
  -- A binding valuation makes every QF_LIA predicate evaluable; a valuation
  -- missing a variable leaves it unevaluable rather than false, which is the
  -- gap between the two model theories that `ValidUnderBinding` names.
  let bound : Valuation := { integers := [("x", 1)], booleans := [] }
  let unbound : Valuation := { integers := [], booleans := [] }
  for predicate in bridgeFormula.premises ++ bridgeFormula.conclusions do
    expectTrue (evalPredicate bound predicate).isSome
      "a binding valuation evaluates every translatable predicate"
    expectEq (evalPredicate unbound predicate) none
      "an unbound variable leaves a predicate unevaluable, not false"
  expectEq (evalConjunction bound bridgeFormula.premises) (some true)
    "the premises hold under the binding valuation"
  expectEq (evalAnyFalse bound bridgeFormula.conclusions) (some false)
    "no conclusion is falsified under the binding valuation"
  expectEq (evalAnyFalse unbound bridgeFormula.conclusions) none
    "an unevaluable conclusion is not reported as falsified"
  expectEq (evalAnyFalse bound [Predicate.falsity, .truth]) (some true)
    "a false conclusion is reported, which is the model the script asks for"
  expectEq (evalAnyFalse bound [Predicate.truth, .worldSensitive "effect"]) none
    "an untranslatable conclusion is unevaluable rather than satisfied"

  -- A record's formula address separates formulas. Without this the field
  -- could be a constant and every drift test would still pass, because they
  -- all compare a mutation against whatever the constant happened to be.
  expectTrue
    (canonicalNormalisedFormula { premises := [], conclusions := [.truth] } !=
      canonicalNormalisedFormula { premises := [], conclusions := [.falsity] })
    "two formulas do not share a normalised-formula address"
  expectTrue
    (canonicalNormalisedFormula { premises := [.truth], conclusions := [.truth] } !=
      canonicalNormalisedFormula { premises := [], conclusions := [.truth, .truth] })
    "premises and conclusions are not interchangeable in a formula address"

  -- The failure codes travel in diagnostics and records, so they are part of
  -- the boundary's contract and not free to be reworded.
  expectEq (CheckFailure.unpinnedProfile.code) "firth.smt.unpinned-profile" "check code"
  expectEq (CheckFailure.unpinnedRequest.code) "firth.smt.unpinned-request" "check code"
  expectEq (CheckFailure.requestIdentityMismatch.code)
    "firth.smt.request-identity-mismatch" "check code"
  expectEq (CheckFailure.proofBindingsMismatch.code)
    "firth.smt.proof-bindings-mismatch" "check code"
  expectEq ((CheckFailure.unsupportedFragment .worldEffect).code)
    "firth.smt.unsupported-fragment" "check code"
  expectEq (CheckFailure.notUnsat.code) "firth.smt.not-unsat" "check code"
  expectEq (RecheckFailure.recordStale.code) "firth.smt.record-stale" "recheck code"
  expectEq ((RecheckFailure.recordTampered "smt2").code)
    "firth.smt.record-tampered" "recheck code"
  expectEq (RecheckFailure.profileDrift.code) "firth.smt.profile-drift" "recheck code"
  expectEq (RecheckFailure.digestDrift.code) "firth.smt.digest-drift" "recheck code"
  expectEq (RecheckFailure.optionDrift.code) "firth.smt.option-drift" "recheck code"
  expectEq (RecheckFailure.requestMismatch.code) "firth.smt.request-mismatch" "recheck code"
  expectEq (RecheckFailure.translationDrift.code) "firth.smt.translation-drift" "recheck code"
  expectEq (RecheckFailure.resultNotUnsat.code) "firth.smt.result-not-unsat" "recheck code"
  expectEq ((RecheckFailure.untranslatable (.unsupportedFragment .worldEffect)).code)
    "firth.smt.untranslatable" "recheck code"
  expectEq (Refusal.digestUnavailable.code) "firth.smt.digest-unavailable" "refusal code"
  expectEq ((RecheckVerdict.driftedRecord .profileDrift).code)
    "firth.smt.profile-drift" "a verdict reports the drift's own code"
  expectEq ((RecheckVerdict.refused .digestUnavailable).code)
    "firth.smt.digest-unavailable" "a verdict reports the refusal's own code"
  expectEq (Fragment.qfLia.canonical) "qf-lia" "fragment name"

  IO.println "all SMT encoder translation proof tests passed"

 end Firth.Smt

 def main : IO Unit := Firth.Smt.runTests
