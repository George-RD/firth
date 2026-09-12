# Baseline obligation audit

## Motivation

`language-05-baseline-acceptance` requires an audit of every active
obligation for specification-only or stale completion evidence, with
implementation tasks created wherever needed and no requirement weakened to
close the audit. PR #109 review also found that the TCB inventory promoted the
compiler to `implemented` on evidence that never executes the Lean compiler,
and the trustworthy-language-baseline handoff left the Cairn gap and
provenance warnings without disposition.

## Scope

Land the audit's artefacts at `80a9d41`: four new implementation todos for
obligations that were discharged by design documents alone (naming grammar,
configurable stack-depth threshold, evidence-bound patch admission, kernel
minimality evidence); `satisfied_by` links from existing implementation todos
to the rows they actually serve; compiler gate evidence pinned in
`specs/tcb-boundary.toml` and its validator; stale `planned` statuses
corrected; the eleven kernel gap decisions resolved against the frozen
specification and metatheory; provenance links repaired.

No source code, example, frozen specification, proof pin, transcript pin or
existing todo text is changed. Rows are only ever added to `satisfied_by`.
The change does not mark `language-05` done and does not change
`loop_exhausted_valid`.

## Verification

Run the matrix and selector validators, the coverage report, every Python
control-plane suite, the TCB boundary checker and tests, Cairn scan with zero
Errors and `cairn hook all`, and `git diff --check`. Lean and Rust gates are
untouched by this change and are not re-run here; the exact candidate must
still pass ordinary PR CI before landing.
