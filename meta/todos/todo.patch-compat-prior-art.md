---
node: firth.runtime.patch
status: done
created: 2026-07-16
---

Requires:

## Goal
Define compatible replacement semantics under refinement types.

## Acceptance criteria
- Compare behavioural-subtyping approaches for word-level patch compatibility.
- Recommend variance rules for stack effects and refinements with counterexamples.
- Feed the recommendation into kernel-spec-freeze and the patch protocol.

## Completed scope and dependency

Done for pure and refinement-typed words: erased kernel `WordType` is invariant,
while elaborator-level input refinements are contravariant and output
refinements are covariant. Compatibility for already effectful words is not
defined by this result and is registered as the downstream gap
`dec.gap-firth-runtime-patch-should-effectful-verified-patch-compatibility-use-an`.

## Traceability
Serves G5 and requirements R6, R7 and R9.
