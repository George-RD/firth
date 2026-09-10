---
id: dec.gap-firth-language-kernel-kernel-formal-gap-disambiguate-sigma-notation
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: Gamma for primitive signatures, Sigma for stack rows

## Question

Kernel formal gap: disambiguate Sigma notation for primitive signatures and stack rows

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "Kernel formal gap: disambiguate Sigma notation for primitive signatures and stack rows"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

Disambiguated and frozen. Section 3 of the kernel specification states that
`Γ` is the primitive signature and `Σ` is a stack type, and that they are
distinct judgement components; section 4 writes every judgement as
`Γ;D ⊢ p : Σ₁ → Σ₂` with `(PRIM)` reading `π : Σ₁ → Σ₂ ∈ Γ`. The
mechanisation separates them as `Gamma` (literal typing and
`Prim → Option PrimitiveSpec`) from `StackType` (row or `snoc`), with
`PrimitiveSpec` carrying its own input and output `StackType` and a
`delta`. `KernelMetatheory.preservation_prim` is stated over that
separation. Section 13 lists `Γ` versus `Σ` notation on the freeze
checklist.
