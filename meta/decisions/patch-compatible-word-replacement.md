---
id: dec.patch-compatible-word-replacement
nodes:
  - firth.language.kernel
  - firth.toolchain.elaborator
  - firth.runtime.patch
status: accepted
date: 2026-07-16
informed_by:
  - res.patch-compat-prior-art
---
# Accepted patch-compatible word replacement boundary

## Context

R7 permits a live word replacement only when its stack effect and refinements
are compatible with the word it replaces. Kernel `WordType` contains only the
prenex stack effect, while refinements live in the elaborator. R9 requires
independently checkable word-level obligations across both layers.

## Decision

The public elaborator contract is represented as `(WordType, Spec)`.
For pure and refinement-typed words, a v1 compatible patch retains that pair
and replaces only the kernel dictionary body. Admission has two separate
obligations: exact equality of the erased kernel `WordType`, preserving
dictionary well-formedness, and behavioural subsumption of the replacement
`Spec` by the old public `Spec`.

## Rationale

The separation respects the kernel specification, which excludes refinements.
Stable erased signatures preserve dictionary well-formedness. Stable
elaborator contracts allow self-recursion, mutual recursion and existing
callers to keep using the pair against which they were checked. `Spec`
subsumption admits safe input weakening and output strengthening through Lean
or SMT implication obligations without changing kernel `WordType`.

## Consequences

The kernel dictionary stores only `(WordType, Program)` and no refinements.
The kernel obligation preserves the erased `WordType` and dictionary
well-formedness. The elaborator separately proves refinement subsumption by
weakening inputs and strengthening outputs. The verified-patch protocol must
bind both kinds of evidence to the body and image version before an atomic
swap. Effectful compatibility remains outside v0.1 and is blocked on
`dec.gap-firth-runtime-patch-should-effectful-verified-patch-compatibility-use-an`.
