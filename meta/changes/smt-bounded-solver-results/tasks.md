# Tasks: smt-bounded-solver-results

- [x] Add the injected `SolverRunner` seam and the production process runner,
      enforcing the wall clock outside the solver.
- [x] Refuse an unpinned profile, an unpinned request, a missing executable, an
      unverifiable digest, and a digest that is not the pin, before invoking.
- [x] Classify every transcript deterministically, with a bare `unsat` staying
      unchecked and an answer outside the vocabulary malformed.
- [x] Fetch a model with a second bounded invocation and parse it back onto
      source names, treating a bad model as malformed output.
- [x] Bind every result to its request's canonical identity and refuse a result
      that is not.
- [x] Cover every case with an injected runner so `lake test` needs no solver.
- [x] Regenerate both manifests and run `lake build`, `lake test`, the
      control-plane suites, `cairn scan` and `cairn hook all`.
