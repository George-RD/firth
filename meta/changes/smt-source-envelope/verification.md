# Verification: SMT source envelope

Baseline: `2e8b1c4e4bd0fcf4672efa4aefb512b1c5c74e4e`. Pinned validation run: https://github.com/George-RD/firth/actions/runs/34277879521.
The clean candidate identity and full patch are in the run's evidence artifact;
the temporary validation workflow is not part of the candidate tree.

## Failing before, passing after

The unchanged baseline checker accepted a mutation reversing the bindings
assembled by an unmarked `checkedSmtRequest` helper. The same mutation is
rejected by the new source-envelope regression. All 24 new envelope tests
and the 30 existing proof-binding tests passed, together with every other
Python regression suite. The patch digest was checked before application.

## Product checks

The pinned Lean 4.30.0 build, zero-admit check, Lean suites, kernel fixtures,
lexical-name tests and real solver-pipe tests passed. The Rust formatter,
strict Clippy and VM tests passed. Trust-boundary regressions, rebuilt MVP
applications, documented examples, bounded-cost witness, selector, coverage
validation and every pinned coverage gate passed. Cairn scan and all hooks
gate candidate publication; their logs are retained in the same artifact.

All four marked translation-rule bodies and all six marked soundness-proof
bodies are unchanged from the baseline. Only the source hash construction
changed. The six-module compiled manifest was regenerated from actual build
output; only SmtBoundary changed. Both source and compiled
manifest checks then passed without rewriting them.

## Limits

This closes the identified helper/source integrity gap within the declared,
dependency-free Lake build. It does not authenticate public raw solver
outcomes or rerun verdicts, prove compiler correctness, complete
`language-01-smt-record-admission`, or authorise merging PR #109.
Conservative binding includes unrelated Lean tests and comments; their
edits intentionally invalidate old records. External packages and source
layouts outside `src/` are rejected rather than silently omitted.
