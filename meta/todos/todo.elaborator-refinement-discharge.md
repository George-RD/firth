---
node: firth.toolchain.elaborator
status: open
created: 2026-07-18
---

Requires: elaborator-stack-effect-inference refinement-discharge-design kernel-metatheory

# Refinement discharge bridge

## Objective

Implement the approved SMT-to-elaborator bridge for typed refinement obligations, with Lean escalation and durable discharge records at the public `(WordType, Spec)` boundary.

## Acceptance criteria

- Translate only the closed-world decidable predicate fragment fixed by the refinement-discharge architecture and bind each request to word, specification, obligation, translation, profile, and solver-version hashes.
- Accept only checked successful results, reject unknown, timeout, malformed, unsupported, or unsound translations, and route eligible failures to interactive Lean proof obligations.
- Add deterministic tests for positive, negative, unknown, timeout, malformed, and Lean-escalated obligations; the implementation contains no `sorry`, `admit`, TODO placeholder, or unimplemented branch.

## Verification

- `lake build`
- `lake test`
- `! rg -n '\b(sorry|admit)\b|TODO|unimplemented|placeholder' src/elaborator src/smt`
- `git diff --check`

## Non-goals

- Do not enlarge the trusted computing base, invent a predicate language, accept unchecked solver output, or implement patch admission.
- Do not change stack-effect inference or the frozen kernel representation.
