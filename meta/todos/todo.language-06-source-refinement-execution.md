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

## Traceability

PRD G4, R8/R9/R15. The temporary source-refinement refusal is not completion of this task.
