---
node: firth.toolchain.elaborator
status: done
created: 2026-08-06
---

Requires: elaborator-parser elaborator-named-local-erasure elaborator-stack-effect-inference elaborator-refinement-discharge

# Elaborator Pipeline Boundary

## Objective

Implement the stable Lean library and CLI entry point that composes parsing, deterministic erasure, stack-effect inference, and refinement checking in dependency order.

## Acceptance criteria

- The public boundary accepts source text and returns a checked kernel term or a structured diagnostic result.
- Each child stage is invoked exactly once in the documented order, with no bypass of validation or SMT discharge.
- The CLI boundary has deterministic success and failure exit behaviour without adding compiler, VM, LSP, or surface-language scope.

## Verification

- `lake build`
- The complete existing Lean test driver passes.
- `git diff --check`

