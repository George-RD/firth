---
id: dec.patch-compatible-word-replacement
nodes:
  - firth.runtime.patch
status: proposed
date: 2026-07-16
informed_by:
  - res.patch-compat-prior-art
---
# Patch Compatible Word Replacement

## Context

R7 permits a live word replacement only when its stack effect and refinements
are compatible with the word it replaces. Kernel `WordType` contains only the
prenex stack effect, while refinements live in the elaborator. R9 requires
independently checkable word-level obligations across both layers.

## Decision

Propose that a public elaborator contract be represented as `(WordType, Spec)`.
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

Kernel-spec-freeze must define the erased dictionary replacement theorem and
version-cut semantics. The elaborator must separately define `Spec`
subsumption. The verified-patch protocol must bind both kinds of evidence to
the body and image version before an atomic swap. Effectful compatibility is
outside this proposal's completed scope and remains blocked on
`dec.gap-firth-runtime-patch-should-effectful-verified-patch-compatibility-use-an`.
