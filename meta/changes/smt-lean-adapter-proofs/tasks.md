# Tasks: smt-lean-adapter-proofs

- [x] State what the emitted script asks for (`ScriptModel`) and what `unsat`
      denies (`ScriptUnsatisfiable`).
- [x] Prove evaluability of a translatable predicate under a binding
      valuation, and the two `evalAnyFalse` lemmas the bridge needs.
- [x] Prove the bridge: an `unsat` verdict on a QF_LIA-encodable formula
      establishes `ValidUnderBinding`.
- [x] Prove that the checked adapter does not rewrite the formula, so a
      verdict on the request is a verdict on the obligation.
- [x] Record why the conclusion is `ValidUnderBinding` and not `Valid`.
- [x] Generate the translation-rule and soundness-proof hashes from marked
      regions, with a `--check` mode and an idempotence test.
- [x] Audit the axioms of every theorem the soundness hashes cover.
- [x] Regenerate the proof-module manifest and run `lake build`, `lake test`,
      the control-plane suites, `cairn scan` and `cairn hook all`.
