# Verification, 8 September 2026

## Scope

This is the promotion/current-binding slice of
`language-01-smt-record-admission`, not proof of solver provenance, completion of
the parent todo, or permission to merge PR #109. Baseline:
`faf2ba7fd8075586337a8af799dbeccb452d2410`.

## Failing before, passing after

Run https://github.com/George-RD/firth/actions/runs/34259313405 applied only the
regression patch to the unchanged baseline and built it with the pinned Lean
4.30.0 toolchain. Both expected failures were then required explicitly:

- `lake exe smtSolverTest`: `fabricated checked-unsat produced a record` for a
  false formula and a caller-created checked marker, without invoking a solver.
- `lake exe firthRecordIntegrityTest`: a caller-selected rerun marker for another
  word exposed a record where zero records were expected.

The same job then applied the implementation patch, rebuilt, passed zero-admit
and unchanged source-region proof-binding checks, regenerated the compiled
manifest, checked that manifest, and passed the full `lake test` driver. Only
the refinement and SMT boundary module hashes changed in the six-module
manifest. No translation-rule or soundness-region hash changed.

The source candidate is `8e199e5fef608cb823114807d9fa992cadf56da4`, tree
`22fa170c4cef6079e5fc8f1633584ab4cfe2b414`. Its seven source/test/manifest
changes exactly match the reviewed local diff. Temporary validation workflows
are excluded from the clean PR commit, as is their bootstrap history.

Evidence artifact: `10069270517`, SHA-256
`100c388d34cb224df9ee32e3b223dd244deae2e6ec0787d29ecb2907373622c1`.
The downloaded archive was checked against that digest and inspected. It
contains both patches, both baseline failure logs, both build logs, the final
Lean test log, the compiled-manifest diff and the published candidate identity.
The original validation attempts failed on patch transport and an incorrect
Lake target name; those runs are not passing product evidence.

## Other checks and limits

Local whitespace, zero-admit, source bindings, selector and coverage validation
passed. Thirteen of fourteen local Python scripts passed; `test_coverage.py`
failed its child-start timing assertion in this container. No Python source or
timeout expectation was changed. Full Python, Rust, application, process and
Cairn checks remain the responsibility of the clean candidate's complete CI;
the latest exact-head result is recorded on PR #109.

Public raw results and rerun verdicts remain data, not proof capabilities.
A caller able to fabricate a matching raw `uncheckedUnsat` value is not made
trustworthy by this patch. The parent todo explicitly retains trusted runner
provenance and transitive translation-helper proof binding as remaining work.
