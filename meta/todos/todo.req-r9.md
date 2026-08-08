---
node: firth.language.kernel
status: done
created: 2026-08-08
---

# Per-Word Proof Obligation Decomposition
Requires: kernel-metatheory

## Goal
Make verification incremental by decomposing proof obligations per word, with
each obligation independently checkable from the word body and referenced
signatures.

## Acceptance criteria
- Define a machine-readable obligation record containing the word identity,
  body, referenced signatures, required premises, checker, and result.
- Implement Lean-side checking that validates each well-formed word obligation
  independently and composes checked results for a vocabulary.
- Demonstrate that a changed word invalidates only its own obligation and the
  obligations of words that depend on it, without accepting an unchecked
  obligation.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.


## Traceability
Satisfies PRD R9 and obligation `req-r9`.
