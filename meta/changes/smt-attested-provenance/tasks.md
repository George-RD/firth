# Tasks: smt-attested-provenance

- [x] Record failing-before evidence for fabricated admission, model-run classification and the model grammar against 80a9d41.
- [x] Seal `Attested` in `SmtSolver`, add `solvePinned` and `rerunPinned`, and keep injected runners as the only public seam.
- [x] Gate both record-publishing sites in `Refinement.lean` on `pinnedProcess`, last, with a stable deferred code.
- [x] Classify the model run before parsing it and give `parseModel` one explicit grammar.
- [x] Migrate the four Lean suites, add the pinned refusal driver, the pinned solver driver and the forge lint with its tests.
- [x] Add `SmtSolver` to the governed proof modules and mirror the manifest tool; extend the TCB manifest and its checker in lockstep.
- [x] Wire the lint and both refusal runs into CI and add the arm64 `smt-pinned-solver` job.
- [x] Regenerate source and compiled bindings from the final sources and the pinned build, checking region bodies unchanged.
- [x] Run every gate, record the x64 transcript evidence, and close the parent todo with its residual limitations.
- [ ] Record the first `smt-pinned-solver` run id on the integrating PR.

The clean PR candidate must also pass the complete repository CI, including
the arm64 job, which has not run before this change is integrated. Its run id
is recorded by the integrator on PR #109, not inferred from this worktree.
