---
node: firth.toolchain.elaborator
status: open
created: 2026-09-08
---

Requires: language-01-smt-record-admission language-02-compiler-evidence

## Goal

Connect source contracts to checked verification conditions.

## Acceptance criteria

- Translate the declared supported source predicates and actual word bodies into obligations; do not use the empty or injected test builder as evidence.
- Check call preconditions, body postconditions and assumptions, with exact source/body/type bindings. False contracts fail, true supported contracts verify, unsupported predicates remain explicit failures.
- Expose type_checked versus contract_verified versus unsupported/inconclusive in versioned agent results. No truth claim for a discarded annotation.
- Test nontrivial positive and negative arithmetic contracts through the public source runner and pinned solver/proof path.

## Scope

This task is the arithmetic, SMT-discharged part of source contracts
(sometimes called 06a). It does not cover properties that need recursion
invariants, sums over sequences or quantifiers, or proved cost bounds: those
are `language-06b-program-property-proofs` and `language-06c-proved-cost-bound`
(split 27 September 2026). S5 and `language-13` depend on those two, not on
this task.

## Traceability

PRD G4, R8/R9/R15. The temporary source-refinement refusal is not completion of this task.
