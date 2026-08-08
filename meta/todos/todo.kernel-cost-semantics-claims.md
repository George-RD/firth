---
node: firth.language.kernel
status: done
created: 2026-08-08
---

# Kernel Cost Semantics Claims
# Goal
Make every timing or memory claim a derivation from the governed kernel cost semantics rather than measurement alone.

Requires: metatheory-cost-invariance

## Acceptance criteria
- Inventory the timing and memory claim forms exposed by existing kernel-facing tooling and register their supported forms.
- Define each registered claim in terms of the parameterised cost table and finite execution traces; reject memory claims when no governed memory metric exists.
- Prove each registered claim and add executable checks that reject unregistered or measurement-only claims.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.

## Traceability
Satisfies PRD R10 and obligation `req-r10`.
