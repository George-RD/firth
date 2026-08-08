# Design: per-word-proof-obligations

## Approach

Use the existing `KernelEffectDependency` traversal as the canonical source
for a word body's referenced signatures and premises. A checked word record is
constructed only from a `ProgramTyping` proof and the corresponding resolved
dependency boundary, so its result is `accepted` only when Lean has checked
that word independently. Vocabulary composition propagates `rejected` and
`unchecked` results and accepts only an all-accepted list. A bounded fixed-point
walk over recorded references computes the changed word's transitive
dependants; invalidation rewrites exactly those records to `unchecked`.

## Changes

ADDED:
- Per-word kernel obligation and vocabulary result structures in
  `src/interpreter/Firth/KernelMetatheory.lean`.
- Runtime assertions covering record construction, composition, and
  transitive invalidation in `src/interpreter/FirthTest.lean`.

MODIFIED:
- `src/interpreter/Firth/KernelMetatheory.lean` gains independent checking,
  composition, and invalidation helpers.
- `src/interpreter/FirthTest.lean` exercises the new contract.

REMOVED:
- None.

RENAMED:
- None.
