# Design: elaborator-pipeline-tests

## Approach

Add deterministic integration cases to the existing pipeline executable. Each
case calls the public pure boundary, matches the typed result, and checks
observable output rather than private stage state. Keep fixtures small and
reuse the existing configuration hooks for external words and refinement
premises.

## Changes

ADDED:
- Integration assertions for success, failures, recursive dictionary success
  and failure, refinement escalation, spans, and repeatability.

MODIFIED:
- `src/elaborator/FirthPipelineTest.lean`.

REMOVED:
- None.

RENAMED:
- None.
