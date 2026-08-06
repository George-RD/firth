# Design: elaborator-pipeline-boundary

## Approach

Expose one pure `elaborator.Firth.Pipeline` module. It flattens vocabulary
declarations once, derives the erasure signatures needed by the surface
lowering stage, lowers every word exactly once, checks the resulting
dictionary with the existing stack-effect checker, then invokes the existing
refinement discharge API for each checked word. The public result contains
located kernel programs and stage-tagged diagnostics. A caller-supplied
refinement builder owns authoritative proof metadata; the default builder
represents source with no refinement predicates.

The CLI is a thin IO adapter around the pure API. It accepts either stdin or
one source path, prints deterministic `Repr` output, exits successfully only
for a fully checked program, and reports usage or IO errors without changing
elaboration semantics.

## Changes

ADDED:
- `src/elaborator/Firth/Pipeline.lean`
- `src/elaborator/FirthPipelineTest.lean`
- `src/elaborator/FirthPipelineCli.lean`
- `meta/decisions/elaborator-pipeline-boundary.md`

MODIFIED:
- `src/elaborator/FirthElaborator.lean`
- `lakefile.toml`

REMOVED:
- None.

RENAMED:
- None.
