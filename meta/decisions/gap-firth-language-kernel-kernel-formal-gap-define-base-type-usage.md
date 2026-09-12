---
id: dec.gap-firth-language-kernel-kernel-formal-gap-define-base-type-usage
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: base-type usage attachment in the ValueType grammar

## Question

Kernel formal gap: define base-type usage attachment in ValueType grammar

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "Kernel formal gap: define base-type usage attachment in ValueType grammar"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

Defined and frozen. Section 3 of the kernel specification gives
`β ::= ι^u` and `τ ::= β | [Σ₁ → Σ₂]^u` with `u ::= many | linear`, states
that the usage of `β = ι^u` is `u`, requires `Bool^many` in `Γ`, and fixes
literal constants at `many`. The mechanisation attaches usage on both
`ValueType` constructors (`ValueType.base type usage` and
`ValueType.quotation input output usage` in `Interpreter.lean`), and
`KernelMetatheory.quotationUsage_of_typing`, `usageMeet_assoc`,
`usageMeet_many_left` and `usageMeet_many_right` prove the meet algebra the
`(COMPOSE)` and `(QUOTE)` rules rely on. `preservation_lit` proves the
many-only literal invariant.
