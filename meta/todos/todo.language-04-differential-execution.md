---
node: firth.toolchain.diffharness
status: done
created: 2026-09-08
---

Requires: language-00-boundary-regressions

## Goal

Implement the differential harness, not just its strategy.

## Acceptance criteria

- Generate varied well-typed source programs and inputs with deterministic seeds, including multiword calls, quotations, conditionals, locals and qualified names.
- Execute the actual elaborator/compiler/Rust VM/Lean interpreter and compare supported observations and kernel cost. Classify traps, overflow and exhaustion explicitly.
- Save source, input, seed, toolchain identities and diagnostics for failures; implement replay and bounded shrinking that preserves the same failure class.
- Run a bounded seeded suite in CI. Document unsupported features; a small pure suite does not discharge the sustained S2 campaign or effectful equivalence.

## Traceability

Reopens implementation missing from scope-toolchain-diffharness; diffharness-fuzz-strategy is design evidence only. PRD G6/R5/S2.

## Implementation slice: executable portable source campaign

`meta/changes/differential-execution/` implements a Python driver over the
actual checked adapters, deterministic typed source generation, explicit
non-success classes, retained process diagnostics and identities, replay and
bounded same-failure shrinking. Usage and limits are in
`src/diffharness/README.md`. The finite seed matrix is wired into repository CI.

## Verification

Implemented and branch-verified at `2d415d46d6a29c011cdfb9fab4eacd748ecce9ac`,
full CI run `34309308469`. The actual adapters agreed on all 72 original seeded
cases. The deliberately exhausted real case shrank through nine accepted
reductions; both original and reduced records replayed the same non-passing
outcome without toolchain drift. All three repository CI jobs passed.

See `meta/changes/differential-execution/verification.md` for evidence and limits.
This closes the bounded implementation task, not SMT/compiler evidence
admission, runtime review, baseline acceptance or the sustained S2 campaign.
The work is not yet merged or accepted on main.
