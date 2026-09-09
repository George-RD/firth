---
node: firth.runtime.vm
status: open
created: 2026-09-08
---

Requires: language-00-boundary-regressions

## Goal

Close runtime and cross-host comparison gaps.

## Acceptance criteria

- Triage every remaining runtime/conformance review finding with a reproducer or evidence-backed disposition.
- Define comparable quotation results without equating different bodies/captures; either compare a justified normal form or reject unsupported comparisons explicitly.
- Validate malformed image/quotation states before encoding and execution across supported public entry points. Trap/fuel/overflow must not count as successful agreement.
- Add negative and differential tests for return values, costs and observations. Do not claim full trace equivalence from final-stack equality.

## Traceability

PR #109 runtime, quotation and conformance reviews; PRD R5/R7/R8.

## Portable comparison sub-slice, 8 September 2026

`meta/changes/portable-observation-validation/` implements strict scalar-result
and pure-world validation, duplicate/non-finite adapter JSON rejection, and
explicit refusal of returned quotations whose bodies/captures lack a shared
comparison format. Regression tests preserve internal quotation execution.
The verification record distinguishes local Python checks from real-host CI.

This parent remains open. These changes do not validate all Rust image entry
points, reconcile all runtime review findings, authenticate compiler evidence,
or establish full trace equivalence. Complete those acceptance criteria and
the baseline audit before marking the parent done.

## Verified sub-slice: direct runtime ingress bounds

`meta/changes/runtime-ingress-bounds/` addresses bounds on caller-created
images and initial stacks, repeated quotation traversal, and captured-value
depth alignment. Public-API regressions distinguish valid boundary inputs
from oversized or malformed inputs, and a subprocess deadline checks the
nested-code validation path. Production solver provenance, image/patch proof
admission and complete conformance remain open; this is not baseline acceptance.

Validation run `34373202388` reproduced 15 selected baseline failures and
passed all 20 new cases in both std and no_std builds. Exact source identities,
logs and limits are recorded in the change's `verification.md`. Ordinary PR
CI still gates the product head; the parent remains open.

Remaining comparison target from static review: the Rust
`src/runtime/vm/src/conformance.rs` display renderer collapses quotation
bodies/captures, while frame rendering omits resume state. Add public
reproducers and either a justified shared normal form or explicit
unsupported-comparison results. Python's existing portable refusal must not
be treated as closure of the separate Rust comparison surface.

## Verified sub-slice: scalar observation payloads and named reports

`meta/changes/runtime-observation-payloads/` fixes byte/primitive payload
collisions in the Rust stack renderer and incorrect `main` labels in named
report execution. Public-API regressions retain exact scalar representations,
real false-agreement reproducers and report/diagnostic parity. This does not
close quotation/frame projection losses, full trace comparison, image/patch
proof admission, process provenance or baseline acceptance.

Validation run `34378902545` reproduced exactly 13 failures on the unchanged
runtime in both std and no_std configurations, with the positive controls
passing. The candidate passed all 15 std / 14 no_std observation tests, the
full 134-test Rust suite, 309 Python unit tests plus the review-gate script,
and Cairn's strict gate. Exact source identities and limitations are in the
change's `verification.md`. Product-head CI and merged-main acceptance remain
separate; this parent is still open.
