---
node: firth.toolchain.compiler
status: open
created: 2026-09-08
---

Requires: language-00-boundary-regressions

## Goal

Bind compiled artefacts to actual checking evidence.

## Acceptance criteria

- Reproduce forged checked/proof_available JSON and code/type hash substitution through the compiler adapter.
- Define and implement the trusted admission boundary: recheck or validate elaborator-owned evidence tied to the exact source/kernel/type/target versions. Hashes of code alone must not be labelled proof.
- Tampered bodies, types, quotation ownership and evidence must be rejected without a target artefact. State the trusted computing base honestly.
- Keep successful typed execution separate from verified refinement claims; update schemas, docs and regression tests together.

## Traceability

PR #109 Lowering.lean evidence review; PRD G6, R8/R9.
