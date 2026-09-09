---
node: firth.toolchain.compiler
status: done
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

## Completion: compiler-input admission, 9 September 2026

Implemented in `meta/changes/compiler-admission-recheck/`. Every compiler
invocation rechecks all supplied kernel bodies, types and ownership with the
existing Lean checker. Source-backed callers additionally pass exact source
bytes for fresh elaboration and dictionary comparison. Public checking flags
and code/type hashes cannot replace those checks. Direct kernel compilation
reports that it has no source binding, and both modes report refinements as
not checked.

The unchanged old compiler accepted all 15 invalid typed/linear inputs in the
retained reproduction. The corrected candidate passed all 45 compiler-admission
cases, the unchanged 72-case real-adapter campaign and the full language,
Python and Cairn gates. Exact candidate identities and before/after evidence
are recorded in `meta/changes/compiler-admission-recheck/verification.md`.
The acceptance gate is linked in the active obligations matrix and CI.

This is branch-verified M0 compiler-input acceptance, not acceptance on merged
main. Legacy target digest slots remain unauthenticated content identifiers;
untrusted-image and verified-patch admission remain open under
`language-03-runtime-conformance`. SMT provenance and the final requirement/
TCB audit remain under `language-01-smt-record-admission` and
`language-05-baseline-acceptance`. No source contract or compiler-correctness
proof is claimed, and PRD R8 is not discharged by this task alone.
