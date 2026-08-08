# Design: kernel-non-local-effect-isolation

## Approach

Represent each external reference in a body as a dependency carrying the
resolved `WordType` or primitive input/output signature. Collect dependencies
recursively through sequencing, quotations, pushed quotations, dictionary
words, and primitives. The collector returns `none` when lookup fails.

Add a theorem by induction on `ProgramTyping` showing that a well-typed body
always has a resolved dependency list. Package that list with the body's
stack effect and typing proof as the kernel effect boundary. This keeps
primitive implementation deltas behind their typed `PrimitiveSpec` contract
and makes rejected effect leakage a typing failure.

## Changes

ADDED:
- `KernelEffectDependency`, recursive dependency collection, and
  `KernelEffectBoundary` in `Firth.KernelMetatheory`.
- Executable examples covering direct, nested, recursive, and rejected
  references in `FirthTest`.
- Accepted decision artefact documenting the boundary choice.

MODIFIED:
- `src/interpreter/Firth/KernelMetatheory.lean`
- `src/interpreter/FirthTest.lean`

REMOVED:
- None.

RENAMED:
- None.
