# Proposal: pr109-review-fixes

Fix the review findings on PR #109 that remained valid at its head
(`80a9d41`) in the compiler, the elaborator, the documentation and one
control-plane test. Each fix is bounded to the finding, is covered by a test
that fails on the unchanged head, and changes no existing expectation, corpus
row, fixture or gate.

## Threads addressed

Compiler (`src/compiler`):

- 25 (`PRRT_kwDOTaQpDM6fJhYs`): `debugLocationsJson` emits no locations for
  instructions nested inside quotations, and the one-instruction-per-atom
  check is top-level only.
- 47 (`PRRT_kwDOTaQpDM6fqau4`): the compiler does not enforce the VM
  instruction-count (4096) or nesting (32) bounds.
- 49 (`PRRT_kwDOTaQpDM6fqau8`): debug metadata lacks nested instruction paths
  and the source spans target-spec section 5 asks for.
- 16 (`PRRT_kwDOTaQpDM6fJhYQ`): the target encoder admits arbitrary-precision
  `Int` though the wire domain is `i64`, and the lowering bound is untested.
- 26 (`PRRT_kwDOTaQpDM6fJhYv`): `captureBitmap` silently drops consumed flags
  beyond the capture count.
- 31 (`PRRT_kwDOTaQpDM6fJhY7`): valid schemes with 25 or more row binders are
  refused by a compiler-only 24-name table.
- 40 (`PRRT_kwDOTaQpDM6fJhZh`): `isRowName` is unused and drifts from the VM
  predicate.

Elaborator (`src/elaborator`, `src/agent`):

- 75 (`PRRT_kwDOTaQpDM6gVPtN`): unresolved word references emit
  `firth.name.unresolved-effect` instead of the normative
  `firth.name.unresolved`.
- 57 (`PRRT_kwDOTaQpDM6fqrTz`): `FirthNamesTest` is not a Lean executable and
  not in the `lake test` driver.
- 80 (`PRRT_kwDOTaQpDM6gsCL4`): name diagnostics carry no related spans. Not
  fixed here; `meta/todos/todo.name-diagnostic-related-spans.md` records why.

Documentation:

- 35 (`PRRT_kwDOTaQpDM6fJhZO`): the soundness-bridge decision states two rule
  and three soundness regions; the generator requires four and six.
- 38 (`PRRT_kwDOTaQpDM6fJhZZ`): the bounded-solver proposal claims no
  checked-unsat constructor exists.
- 41 (`PRRT_kwDOTaQpDM6fJhZl`): the elaborate-adapter proposal attributes the
  uncaught-exception claim to the manifest.
- 44 (`PRRT_kwDOTaQpDM6fJhZx`): "five generated hashes" does not match the ten
  in `defaultSmtProofBindings`.

Control plane:

- 71 (`PRRT_kwDOTaQpDM6gBrF1`): `test_open_work_prevents_completion` never
  checks the positive direction.

## Out of scope

Threads 22 and 45 (evidence digests synthesised from code and type) are owned
by the separate `patch-refinement-evidence-admission` todo and are left alone.
The proof pins (`src/elaborator/refinement-proof-module.sha256` and the hash
literals in `src/smt/Firth/SmtBoundary.lean`) are regenerated once by the
integrator after all worktrees merge; this unit does not stage them.
