---
node: firth.toolchain.elaborator
status: done
created: 2026-07-18
---

Requires: elaborator-parser surface-erasure-determinism surface-syntax-spec kernel-spec-freeze

# Deterministic named-local erasure

## Objective

Implement the surface-to-kernel erasure pass for named locals, using the landed deterministic copy-identity rule and emitting only frozen kernel atoms with source provenance retained for later diagnostics.

## Acceptance criteria

- Erase every supported named-local construct to kernel terms without introducing binders, variables, or new runtime semantics.
- Make copy identities, generated names, and expansion order deterministic across repeated runs and independent of hash-map iteration.
- Add golden and property tests covering shadowing, nested quotations, linear values, depth-limit lint cases, and rejection of unsupported captures; the implementation contains no `sorry`, `admit`, TODO placeholder, or unimplemented branch.

## Verification

- `lake build`
- `lake test`
- `! rg -n '\b(sorry|admit)\b|TODO|unimplemented|placeholder' src/elaborator`
- `git diff --check`

## Non-goals

- Do not infer stack effects, solve refinements, define user-facing diagnostic JSON, or execute erased programs.
- Do not extend the surface grammar or add optimisation passes that could obscure deterministic source mapping.
