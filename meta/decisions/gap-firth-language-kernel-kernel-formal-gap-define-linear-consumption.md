---
id: dec.gap-firth-language-kernel-kernel-formal-gap-define-linear-consumption
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: linear consumption and the terminal-stack leak rule

## Question

Kernel formal gap: define linear consumption and terminal-stack leak rule

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "Kernel formal gap: define linear consumption and terminal-stack leak rule"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

Defined and frozen. Section 3 of the kernel specification states that a
linear value may be moved, consumed by a primitive, buried by `dip` or
transferred into a linear quotation, but never duplicated or silently
discarded (`dup` and `drop` require `many`, with no coercion). Section 6
items 4 and 5 fix the two obligations: at-most-once consumption over every
finite trace, and exact-once consumption only under an explicit termination
premise with an empty linear residue, so a terminating trace that leaves a
linear value on the terminal stack is a linearity failure while divergence
may leave a value live. The mechanisation proves exactly these:
`Linearity.finite_trace_at_most_once`,
`Linearity.exact_once_of_terminating_empty_residue` (and its
`_all_born` form), and `Linearity.divergence_may_leave_linear_live` as the
witness that the termination premise is necessary.
