# Proposal: smt-checked-adapter-pipeline

The SMT queue currently stops at a typed obligation boundary. Eligible QF_LIA
obligations need a deterministic, typed SMT-LIB request before a later bounded
solver unit can invoke the pinned profile. Without this boundary, translation
and serialisation are implicit and unsupported predicates could reach a solver.

## Scope

- Add a checked QF_LIA request builder over the existing typed predicate IR.
- Reject invalid profiles and unsupported fragments before producing a request.
- Generate stable sort-specific symbols and deterministic SMT-LIB2 scripts.
- Bind the generated request to queued obligations and cover supported,
  unsupported, and hostile-input cases in the refinement test suite.

## Out of scope

- Lean translation-soundness proofs and proof hashes.
- Solver process invocation, resource enforcement, result parsing, or discharge
  records. Those are separate dependent todos.
