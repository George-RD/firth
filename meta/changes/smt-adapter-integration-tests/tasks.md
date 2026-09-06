# Tasks: smt-adapter-integration-tests

- [x] Run each case from `checkBodyRefinements` through `solve` to
      `recordExternalOutcome`, asserting on the result boundary.
- [x] Cover a checked `unsat`: a content-addressed record that binds the
      obligation, the request, the formula, the script, the pinned executable,
      the options and both proof bindings, and that rechecks.
- [x] Cover a validated `sat`: a failed refinement carrying its model, never a
      record and never proof evidence, and deterministic across repetition.
- [x] Cover unknown, timeout, resource exhaustion, malformed output, silence,
      output past the bound, a crash, a model naming an undeclared symbol, a
      model run that timed out, and a model that does not refute.
- [x] Cover an `unsat` that did not pass the adapter: unpinned profile,
      incomplete bindings, foreign request identity, absent request identity,
      and a result that arrives already promoted.
- [x] Cover a solver that is absent, undigestable or not the pinned binary,
      and assert a refusal never reaches the boundary as an outcome.
- [x] Cover unsupported input where it is refused, for both fragments the
      translator rejects.
- [x] Assert the invocation carries the pinned options, the pinned wall-clock
      bound and the request's own script, and that a model costs a second
      bounded run.
- [x] Run `lake build`, `lake test`, the control-plane suites, `cairn scan` and
      `cairn hook all`.
