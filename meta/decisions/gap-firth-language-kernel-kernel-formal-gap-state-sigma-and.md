---
id: dec.gap-firth-language-kernel-kernel-formal-gap-state-sigma-and
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: Sigma and delta well-formedness for determinism and progress

## Question

Kernel formal gap: state Sigma and delta_pi well-formedness for determinism and progress

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "Kernel formal gap: state Sigma and delta_pi well-formedness for determinism and progress"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

Stated and frozen. The closing paragraphs of section 4 of the kernel
specification require dictionary well-formedness (`Γ;D ⊢ p : T` for every
entry under the declared erased signatures) and primitive-signature
well-formedness (one typed input and output shape, a deterministic total
`δ_π` on that shape, ownership consistent with the usage annotations), and
state that these, with the syntax-directed rules, are the assumptions used
by determinism and progress. The mechanisation names them as premises:
`Progress.progress` takes `LiteralTypingSound`, `DictionaryWellTyped` and
`PrimitivesWellFormed` (`PrimitivesPreserve ∧ PrimitivesTotal`);
`KernelMetatheory.preservation` takes `DictionaryWellTyped` and
`PrimitivesPreserve`; `KernelMetatheory.step_deterministic` follows from
`step` being a function of the configuration once `δ_π` is deterministic.
