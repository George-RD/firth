# Design: elaborator-pipeline-failures

The core `elaborator.Firth.Pipeline` boundary remains pure and unchanged. The agent module owns a thin bridge that invokes the core boundary exactly once, converts its failure constructors through the existing envelope adapters, and returns a typed success-or-failure outcome. The bridge derives the protocol source path and request identity from one `EmissionContext`, so refinement diagnostics and stage diagnostics share the request.

## Changes

ADDED:
- An agent-facing structured pipeline outcome and bridge function.
- An internal-envelope mapping for the pipeline's invariant failure branch.
- Integration assertions for successful output, source locations, and diagnostic validation.

MODIFIED:
- `src/agent/Firth/Agent/ElaboratorDiagnostics.lean`
- `src/agent/Firth/Agent/ElaboratorDiagnosticsTest.lean`

REMOVED:
- None.

RENAMED:
- None.
