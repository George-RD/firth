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
`check_zero_admit.py` rejects `native_decide` by name, with planted cases in
`tools/loop/test_check_zero_admit.py`. The name is not the only spelling
(`decide +native` and a direct `Lean.ofReduceBool` carry the same trust), so
it also runs `firthAxiomAudit` (`src/compiler/Firth/AxiomAudit.lean`) over the
built environment: every declaration of every `.lean` file under `src` may
rest only on `propext`, `Classical.choice` and `Quot.sound`. Its planted
modules (`decide +native`, `native_decide`, `Lean.ofReduceBool`,
`Lean.ofReduceNat`, `Lean.trustCompiler`, `sorry`, a declared constant
without a proof, and an indirect use) must each be refused before the
repository is audited.
