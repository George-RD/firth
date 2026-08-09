---
id: dec.reference-interpreter-conformance
nodes:
  - firth.toolchain.interpreter
status: accepted
date: 2026-08-09
informed_by:
  - res.firth-kernel-spec.summary
  - res.firth-prd.summary
---

# Typed target conformance boundary

## Context

Autonomous author: loop/todo.reference-interpreter-conformance.

The reference interpreter and target use different execution accounting. The
interpreter reports kernel steps and the target reports concrete κ cost. The
conformance boundary must compare semantic observations without making those
accounting systems identical. Target traps and target rejection are distinct
from a reference stuck result, and equal-budget fuel exhaustion is
inconclusive rather than a proven match.

## Decision

Represent the target report with explicit terminal, stuck, fuel-exhausted,
trap, and rejection statuses. Compare fuel exhaustion only as inconclusive
when both sides exhaust the same budget. Require matching non-fuel outcome
classes, residual stack and program, and observed `World` state. Validate the
target's aggregated κ cost against the expected target cost independently of
reference interpreter steps. Keep compiler lowering, wire encoding, and Rust
VM integration outside this unit.

This preserves the Lean oracle as the behavioural authority while making every
accepted or rejected target observation explicit and machine-checkable.
