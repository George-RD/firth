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
