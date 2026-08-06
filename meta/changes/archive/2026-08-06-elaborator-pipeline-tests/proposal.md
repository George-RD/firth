# Proposal: elaborator-pipeline-tests

## Motivation

The public elaborator pipeline currently has only narrow smoke coverage. Its
integration contract must cover successful checked output, every diagnostic
stage, recursive dictionary success and failure, refinement escalation, and
deterministic repeated runs.

## Scope

- Extend `src/elaborator/FirthPipelineTest.lean` through the public
  `elaborate` and `elaborateWith` boundaries.
- Assert source spans, structured diagnostics, checked kernel output, and
  repeatability.
- Keep the test driver and production pipeline unchanged unless a failing
  public contract exposes a real implementation defect.

## Out of scope

- Private stage tests, compiler or VM behaviour, and new source syntax.
- Changes to the frozen kernel specification or blueprint structure.
