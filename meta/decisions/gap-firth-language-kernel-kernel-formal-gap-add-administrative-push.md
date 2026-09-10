---
id: dec.gap-firth-language-kernel-kernel-formal-gap-add-administrative-push
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: administrative push and its PUSH typing rule

## Question

Kernel formal gap: add administrative push v syntax and its PUSH typing rule

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "Kernel formal gap: add administrative push v syntax and its PUSH typing rule"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

Added and frozen. Section 4 of the kernel specification has the `(PUSH)`
rule `Γ;D ⊢ push v : Σ → Σ · τ` from `Γ;D ⊢ᵥ v : τ`, and section 5 gives
the `S-PUSH` transition and states that `push v` exists only in the
semantics, produced by `S-DIP` and `S-QUOTE`. The mechanisation carries the
constructor `Atom.push`, the typing rule `AtomTyping.push`, the derived
`KernelMetatheory.push_program_typing`, the `push` case of
`KernelMetatheory.preservation`, and
`Linearity.instrumented_step_erases_push` for the ownership trace. The
freeze checklist (section 13) lists the administrative `push` as a point on
which Lean and prose must agree.
