---
node: firth.toolchain.elaborator
status: done
created: 2026-08-06
---

Requires: elaborator-pipeline-boundary elaborator-pipeline-failures

# Elaborator Pipeline Tests

## Objective

Add end-to-end integration coverage for successful elaboration, every required failure class, recursive dictionaries, typed holes, refinement escalation, and deterministic repeated elaboration.

## Acceptance criteria

- Tests exercise the public library or CLI boundary rather than private stage implementations.
- Tests cover source-location preservation, structured diagnostics, successful checked kernel output, and repeated-run determinism.
- The elaborator source and tests contain no `sorry`, `admit`, TODO placeholder, or unimplemented branch.

## Verification

- `lake build`
- `lake test`
- `git diff --check`

