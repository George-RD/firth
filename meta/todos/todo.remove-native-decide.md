---
node: firth.toolchain.elaborator
status: done
created: 2026-09-28
---

## Goal

Remove the two `native_decide` uses in `src/elaborator/FirthRefinementTest.lean`
(the `generateVc_formula` and `generateVc_identity` side conditions), so no
Lean in the repository relies on the compiler-trusting `Lean.ofReduceBool`
axiom. AGENTS.md rule 11 forbids new uses.

## Acceptance criteria

- The side conditions are closed by `decide`, `rfl`, `simp` or a lemma, or the
  test is restated so they are not needed.
- `grep -rn native_decide src` finds nothing.
- Optionally, `check_zero_admit.py` rejects `native_decide`, with a planted
  case showing it does.

## Traceability

`dec.agent-development-rules`. Owned by whoever owns `src/elaborator`.

## Resolution

Both side conditions now close by `decide`. They could not before because
the bounds traversal in `Refinement.lean` recursed by well-founded recursion,
which `decide` does not unfold; it now recurses structurally on a fuel that
starts one above its two budgets, so accepted formulas are unchanged.
`check_zero_admit.py` rejects `native_decide`, with planted cases in
`tools/loop/test_check_zero_admit.py`.
