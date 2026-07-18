# Proposal: erasure-proof-independence

## Motivation

The relational local-erasure proof currently reuses executable helper functions
as specification premises. A defect in those helpers can therefore change both
the implementation and its claimed semantics. The exported soundness theorems
also depend on `Classical.choice` and `Quot.sound`, beyond the permitted
propositional extensionality axiom, and one determinism test only compares an
erasure result with itself.

## Scope

- Define independent constructive judgements for canonical focus and demand
  expansion, transcribed from the surface syntax specification.
- Prove the executable focus, demand-program, and demand-state helpers correct
  against those judgements and use the proofs in relational erasure soundness.
- Restrict exported erasure soundness theorems to the `propext` axiom.
- Replace the self-comparison test with fixed golden kernel programs.
- Re-run the reported findings, all Lean and Cairn gates, and an independent
  in-session review.

## Out of scope

- No change to the surface syntax, erasure policy, diagnostic contract, kernel
  semantics, or optimisation behaviour.
- No push, pull request, or archival of the broader named-local-erasure todo.
