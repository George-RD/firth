# Tasks: smt-proof-region-validation

- [x] Capture the scope without changing source or proof pins.
- [x] Reproduce unpaired-stage and malformed-marker acceptance.
- [x] Enforce marker and declared region coverage validation.
- [x] Isolate write-mode tests and reject misspelled CLI flags.
- [x] Run the Python regressions and read-only proof-binding checks.
- [ ] Verify the exact candidate through Lean, Rust and Cairn CI.

The parent `language-01-smt-record-admission` task remains open. The last
checkbox requires a successful CI run for the published code candidate; local
Python results do not substitute for the unavailable Lean, Rust and Cairn tools.

## Reproduction and local verification

Baseline: PR #109 head `f2792da75683c325b8448ee63676262a4c8b78a7`.

Before changing the generator, the new parsing/coverage suite ran 20 test
methods and reported 26 failing subcases. Two real-CLI regressions also failed:
`test_check_rejects_misspelled_new_region` and
`test_write_mode_rejects_unpaired_stage_without_repinning`. The original CLI
returned success in both cases; the latter rewrote the temporary fixture's
bindings despite the missing proof region. No original proof pin was rewritten.

After the change, the expanded SMT suite passed all 30 test methods. The
read-only generator check still matches the original four rule and six
soundness hashes. Zero-admit, agent-input schema, coverage validation, selector
validation and changed-line whitespace checks also passed.

All 14 Python suite files were run locally. Thirteen passed. The unchanged
`test_coverage.py` failed only `test_timed_out_gate_cannot_orphan_children`
with `gate never started its child` before its one-second deadline. The same
failure was reproduced separately against the untouched baseline snapshot.
Neither the test nor its timeout was changed. Record the exact remote CI result
in the PR handoff rather than describing this local run as fully green.
