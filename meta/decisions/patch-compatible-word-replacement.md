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
are compatible with the word it replaces. R9 requires independently checkable
word-level obligations. Exact contract equality is unnecessarily restrictive,
while whole-image contextual equivalence defeats incremental verification.

## Decision

Propose that a v1 compatible patch retain the old public `WordType` and replace
only the dictionary body. Accept the body when its inferred contract is a
behavioural subtype of the old contract: old inputs imply new inputs, new
outputs imply old outputs under old-valid inputs, and the erased calling
convention, row shape and usage annotations remain equal.

## Rationale

Stable public signatures preserve the existing dictionary well-formedness
proof and allow self-recursion and mutual recursion to keep using the contracts
against which callers were checked. Behavioural subtyping admits safe input
weakening and output strengthening while reducing refinement compatibility to
Lean or SMT implication obligations. Representation or interface changes stay
explicit through versioned words, adapters or a future image-transition
protocol.

## Consequences

Kernel-spec-freeze must define the replacement theorem and version-cut
semantics. The verified-patch protocol must bind proof artefacts to old and new
contract and body hashes, verify target correspondence before an atomic swap,
and retain rollback state. This decision remains proposed until the effect
contract chooses an abstract state relation, an event trace, or both for
observational refinement of the linear `World` thread.
