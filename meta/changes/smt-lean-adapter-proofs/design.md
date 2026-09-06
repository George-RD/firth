# Design: smt-lean-adapter-proofs

## Approach

The bridge is stated over two new predicates rather than over
`Firth.Elaborator.Refinement.Valid`, and `dec.smt-adapter-soundness-bridge`
records why: an SMT model is total and a Lean `Valuation` is partial, so an
`unsat` verdict cannot rule out a valuation that satisfies the premises while
leaving a conclusion's variable unbound. `Binds` is the totality condition
`validatesCounterexample` already imposes on a counterexample model, and
`ValidUnderBinding` is validity restricted to those valuations.

`ScriptModel` and `ScriptUnsatisfiable` name what the emitted script asks for,
so the solver's verdict enters the proof as a hypothesis rather than as an
informal appeal.

Getting from "no model" to "the conclusions hold" needs every conclusion to be
evaluable at a binding valuation, which is where the QF_LIA hypothesis earns
its place: `evalPredicate_isSome` proves evaluability from translatability
plus boundedness, and without translatability an untranslatable predicate
would make the script modelless and the theorem vacuous.

The proof-binding generator hashes marked regions rather than the whole file,
which is what makes it a fixed point: the hashes it writes live outside every
region it covers. The idempotence test asserts that property directly.

## Changes

ADDED:
- `Formula.integerVariables`, `Formula.booleanVariables`, `Binds`,
  `ScriptModel`, `ScriptUnsatisfiable`, `ValidUnderBinding` in
  `src/smt/Firth/SmtBoundary.lean`.
- `evalInt_isSome`, `evalPredicate_isSome`, `encodePredicates_mem`,
  `evalConjunction_of_all_true`, `evalAnyFalse_isSome`,
  `evalAnyFalse_of_not_all_true`, `checkedSmtRequest_formula`,
  `validUnderBinding_of_scriptUnsatisfiable`,
  `validUnderBinding_of_checkedRequest`.
- Translation-rule and soundness region markers.
- `tools/loop/update_smt_proof_bindings.py`,
  `tools/loop/test_smt_proof_bindings.py`.
- `meta/decisions/smt-adapter-soundness-bridge.md`.

MODIFIED:
- `defaultSmtProofBindings`: five generated hashes replacing two literals.
- `src/smt/Firth/SmtBoundaryTest.lean`: nineteen audited theorems, and
  concrete witnesses for the bridge's hypotheses.
- `src/elaborator/refinement-proof-module.sha256`: regenerated.
- `AGENTS.md`: the generator, its check, and its drift test.
