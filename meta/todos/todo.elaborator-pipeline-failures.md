---
node: firth.toolchain.elaborator
status: open
created: 2026-08-06
---

Requires: elaborator-pipeline-boundary elaborator-diagnostic-envelope

# Elaborator Pipeline Failures

## Objective

Connect the integrated elaborator boundary to the diagnostic envelope so typed holes, refinement escalation, recursive dictionary failures, and source locations remain structured end to end.

## Acceptance criteria

- Every supported failure class is represented by the approved diagnostic contract and retains its originating source location.
- Successful results and failures are distinguishable without string parsing or discarded validation details.
- The implementation does not weaken parser, erasure, inference, refinement, or SMT checks and does not add compiler, VM, or LSP scope.

## Verification

- `lake build`
- The complete existing Lean test driver passes.
- `git diff --check`

