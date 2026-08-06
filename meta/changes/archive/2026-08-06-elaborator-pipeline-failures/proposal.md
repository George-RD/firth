# Proposal: elaborator-pipeline-failures

The pure elaborator pipeline currently returns internal `PipelineDiagnostic` values. The agent protocol already defines stage-specific envelope encoders, but no public bridge composes them at the integrated pipeline boundary. Callers therefore must inspect Lean constructors or render `repr` output, which can discard protocol fields.

## Scope

- Add an agent-facing structured outcome for the existing pipeline.
- Map parse, erasure, stack-effect, refinement, and internal pipeline failures to validated diagnostic envelopes.
- Preserve the checked program on success and source locations on every mapped failure.
- Add focused integration coverage for success and representative structured failures.

## Out of scope

- Changes to parser, erasure, inference, refinement, SMT, compiler, VM, LSP, or the envelope schema.
- A second diagnostic protocol or a change to the existing CLI representation.
