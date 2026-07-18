---
node: firth.toolchain.elaborator
status: open
created: 2026-07-18
---

Requires: elaborator-named-local-erasure kernel-spec-freeze kernel-metatheory quotation-typing-prior-art

# Stack-effect inference

## Objective

Implement Lean 4 inference and checking for erased kernel programs, including prenex row-polymorphic stack effects, usage-aware linearity, quotation typing, and typed-hole state.

## Acceptance criteria

- Infer or check every frozen kernel atom and dictionary word against declared stack effects, with deterministic fresh-row allocation and occurs-checking.
- Reject stack mismatches, linear duplication, linear discard, invalid quotation use, and many-only literal violations; accept valid polymorphic and recursive dictionaries under the frozen rules.
- Produce typed-hole records containing the exact inferred stack state and add executable positive and negative tests for rows, quotations, recursion, effects, and linear ownership; the implementation contains no `sorry`, `admit`, TODO placeholder, or unimplemented branch.

## Verification

- `lake build`
- `lake test`
- `! rg -n '\b(sorry|admit)\b|TODO|unimplemented|placeholder' src/elaborator`
- `git diff --check`

## Non-goals

- Do not implement SMT translation, refinement solving, compiler lowering, runtime execution, or final diagnostic-envelope serialisation.
- Do not add higher-rank polymorphism, subtyping, overloading, or new kernel typing rules.
