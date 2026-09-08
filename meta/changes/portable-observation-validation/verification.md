# Verification, 8 September 2026

## Scope and baseline

This is the portable-comparison sub-slice of
`language-03-runtime-conformance`, not acceptance of that entire task or PR #109.
Baseline head: `9d5aa71e32824f55bdc8701a8fe82e9dff09d2c3`.
The source snapshot from CI run 34161160670 was downloaded and its archive
SHA-256 checked. The original gate's Git blob matched
`c7b3a49543cf62645bf370d53a0e59d8c8a32936`.

## Local evidence

Six direct reproductions passed incorrectly before the fix: quotation metadata,
Boolean/integer payload coercion, an out-of-range integer, an unknown value
kind, a null value, and a Boolean pure-world byte. The final 21-test regression
suite was run against the unchanged baseline gate, where its adversarial
subtests failed, then against the corrected gate, where all 21 tests passed.
Subtest failures are not counted as separate test methods.

All 14 Python regression scripts passed using Python 3.13.5: 214 unittest
methods plus the review-gate script's 12 checks. Agent-input schema validation,
selector validation, coverage validation and changed-line whitespace also
passed. Existing source/transcript pins and governed proof bindings were not
changed. The real-process JSON tests launch a Python subprocess; they do not
stand in for Lean or Rust execution.

## Candidate verification still required

Local `lake`, `cargo` and `cairn` executables are unavailable. Full language,
proof-binding, Rust, source-to-execution and architecture checks must therefore
be confirmed on the exact published candidate in CI. No successful CI result
for this change is claimed by this pre-publication record.

The existing real-binary trust gate now includes four additional fixtures:
closed and value-capturing quotations, each returned and called. Returned
quotations must be explicitly refused by the comparator; called quotations must
produce scalar 42 with matching kernel cost. These use the typed structured
compiler transport because source quotation-output signatures are not yet
supported. They are not source-authorship or proof-admission evidence.

The broader runtime task stays open, as do SMT-record admission, compiler
evidence, differential execution, and baseline review/acceptance. Do not merge
PR #109 on the strength of this narrow comparison fix.
