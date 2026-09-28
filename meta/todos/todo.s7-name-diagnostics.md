---
node: firth.toolchain.agent
status: open
created: 2026-09-28
---

# Name diagnostics that steer an author to `locals`

Found in S7 run 4 (`eval/s7/runs/2026-09-28-mvp/`, see `eval/s7/README.md`).
Haiku 4.5 failed all 20 MVP tasks in all three answers for one reason. It
used a word's stack-effect names (`xs`, `n`) in the body outside any `locals`
block. It was given the checker's feedback twice and never found the fix.

## Goal

- **The unresolved-name hint names the cause.** When a name that fails to
  resolve (`firth.name.unresolved`) is one of the enclosing word's
  stack-effect names, the hint says that stack-effect names only label the
  signature and that `locals { xs } { ... }` binds them. Today it says "`xs`
  is not a defined word, primitive or local", and its hint is about spelling
  and `prim`. The message comes from `src/agent/Firth/Agent/ElaboratorDiagnostics.lean`.
- **The primitive list in hints is current.** Both hints in
  `ElaboratorDiagnostics.lean` (the `unresolved` hint and the
  `unresolved-effect` hint, around lines 166 and 320) list only `prim +`, `-`,
  `*`, `<` and `=`. The list leaves out `and`, `or`, `not` (#131) and the
  `seq-int.*` and `seq-bool.*` primitives. The hint should be built from the
  registry rather than written by hand, so that it cannot go stale again.
- **The getting-started guide says it plainly.** Line 88 says the names "are
  not ordinary mutable variables", which reads as if they were variables of
  another kind. The guide should say that they cannot be used in the body,
  and show `locals` as the way to use them.

## Acceptance criteria

- A diagnostics test has a planted program that uses a stack-effect name
  outside `locals`, and it asserts that the hint names `locals`.
- A test fails when a registered primitive is missing from the hint.
- The S7 MVP set is re-run afterwards as a separate scored run.
