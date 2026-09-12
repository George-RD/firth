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

## Pre-publication verification boundary

Local `lake`, `cargo` and `cairn` executables are unavailable. Full language,
proof-binding, Rust, source-to-execution and architecture checks must therefore
be confirmed on the exact published candidate in CI. The first candidate and
verified follow-up results below record that distinction.

The existing real-binary trust gate now includes four additional fixtures:
closed and value-capturing quotations, each returned and called. Returned
quotations must be explicitly refused by the comparator; called quotations must
produce scalar 42 with matching kernel cost. These use the typed structured
compiler transport because source quotation-output signatures are not yet
supported. They are not source-authorship or proof-admission evidence.

The broader runtime task stays open, as do SMT-record admission, compiler
evidence, differential execution, and baseline review/acceptance. Do not merge
PR #109 on the strength of this narrow comparison fix.

## First candidate exposed a runtime projection defect

Code candidate `9a47ebf35216b76aa3149891293a17c56494a9a3` ran in
https://github.com/George-RD/firth/actions/runs/34246577859.
Python and Cairn jobs passed. Lean build/tests, proof bindings, kernel fixtures,
name/solver-pipe tests and Rust format/clippy/tests passed. The trust gate passed
23 cases and failed the captured-quotation call: reference kernel cost 3, VM
reported kernel cost 4. Downstream execution gates were correctly skipped.
This run is failure evidence, not a green candidate.

The diagnostics archive was downloaded and SHA-256 verified. The unchanged
reference S-PUSH rule is zero-cost. The follow-up records per-step kernel charges
and projects out capture restoration as well as word entry, without reducing
VM totals, instructions, traces or fuel. Four Rust regressions and the new
`quoted-value.firth` source example exercise the distinction. The original
24-case trust gate remains unchanged and must pass in full on the follow-up.

Cairn retained 0 errors, 43 warnings and 26 informational findings. Those
existing governance findings and the proposed S-PUSH cost-table gap are not
resolved or suppressed by this change. Automated CodeRabbit review was skipped
because the full PR exceeds its file-count limit; this is not independent
review approval.

## Verified runtime follow-up

Code candidate `5c2e5043876aeeb1d52873357c269af3608617ed` passed all three
jobs in https://github.com/George-RD/firth/actions/runs/34248449207.
CI checked merge ref `698626afb4245f86bd2e404c6e2750a33a01387d`, whose tree
`c889d9a10b08bbab538ae7f0606a3c384549e291` exactly equals the code candidate
and local verified tree. This is not a merge onto main.

The full Lean build/suites, unchanged proof bindings, canonical fixture check,
name/solver-pipe tests, Rust formatting/clippy/tests, and all pinned coverage
gates passed. All 24 real-host trust-boundary cases passed, including the
previously failing captured-quotation call. All four pinned MVP applications
rebuilt and agreed. The documented source gate passed 10 successful cases,
seven refusals and two CLI commands, including `42 quote call` returning 42.
The bounded cost witness retained result 4, kernel cost 25 and target cost 31.

The language diagnostics archive (artifact 10065052424) was downloaded,
inspected and verified against SHA-256
`a1bef150b4d76833b24bb203dba486f078381dbf71631af88bb3d79de593bc25`.
Cairn scan and hooks passed with the existing warnings still visible; tracked
evidence was not rewritten. No solver/compiled proof binding or original
corpus expectation changed. The active roadmap intentionally keeps
`loop_exhausted_valid` false.

This completes verification of this narrow implementation slice, not parent
`language-03-runtime-conformance`, independent review, or baseline acceptance.
The raw proof-record and compiler-evidence admission blockers remain next.
