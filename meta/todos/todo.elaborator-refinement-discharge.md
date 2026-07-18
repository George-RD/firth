---
node: firth.toolchain.elaborator
status: done
created: 2026-07-18
---

Requires: elaborator-stack-effect-inference refinement-discharge-design kernel-metatheory

# Refinement discharge bridge

## Objective

Implement the Lean-discharge slice of the approved refinement architecture at
the public `(WordType, Spec)` boundary, including typed obligations, durable
Lean proof records, deterministic diagnostics, and a conservative queue for a
future checked SMT adapter.

## Acceptance criteria

- Represent the provisional refinement predicate fragment and generate body,
  replacement-subsumption, and totality obligations from the refinement typing
  premises fixed by the architecture.
- Discharge the closed decidable slice with a proved Lean procedure. Durable
  `LeanProofRecord` values store the instantiated structured proof term, bind
  the theorem and semantic inputs, and reconstruct a theorem module that the
  Lean kernel checks during recheck. Stale or tampered records fail recheck.
- Queue only eligible typed obligations at an exact, conservative SMT boundary.
  This unit creates no SMT success record and treats unknown, timeout,
  resource exhaustion, malformed output, crashes, unchecked unsat, unsupported
  translations, and invalid countermodels as non-success.
- Add deterministic diagnostics and mutation-resistant positive, negative,
  conservative-boundary, Lean-escalation, and must-fail undischargeable tests.
  The implementation contains no `sorry`, `admit`, TODO placeholder, or
  unimplemented branch.

Per the Foreman adjudication of 2026-07-18, checked external SMT adapters,
solver selection, translation soundness proofs, and SMT discharge records are
split to `todo.smt-adapter-integration`. This todo remains done only for the
Lean-discharge and conservative-queue scope above.

## Verification

- `lake build`
- `lake test`
- `! rg -n '\b(sorry|admit)\b|TODO|unimplemented|placeholder' src/elaborator src/smt`
- `git diff --check`

## Non-goals

- Do not implement the external SMT adapter or its discharge records in this
  unit; see `todo.smt-adapter-integration`.
- Do not enlarge the trusted computing base, invent a predicate language,
  accept unchecked solver output, or implement patch admission.
- Do not change stack-effect inference or the frozen kernel representation.
