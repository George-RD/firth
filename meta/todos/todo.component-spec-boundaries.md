---
node: firth.ecosystem.specs
status: open
created: 2026-07-16
---

Requires: kernel-spec-freeze, vm-target-spec

## Goal
Define the component-specification boundary for the elaborator, compiler, VM, patch protocol, and agent interface.

## Acceptance criteria
- Map each component specification to the frozen kernel and identify its inputs, checked artefacts, and conformance obligations.
- Define the proof or differential-test evidence required before each component is treated as trustworthy rather than part of the TCB.
- Publish a dependency order that prevents compiler and patch specifications from outrunning the kernel and VM specifications.

## Blockers
Work is eligible once `kernel-spec-freeze` and `vm-target-spec` are both `done`. This todo becomes `done` only when the boundary document lands and its companion decision reaches `accepted` status; then publish the dependency order before component implementation begins.

## Traceability
Serves G6 and G9 and requirements R5, R6, R7, R8, R9, R11 and R12; enables success criteria S2, S3 and S6.
