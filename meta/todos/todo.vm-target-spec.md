---
node: firth.runtime.vm
status: open
created: 2026-07-16
---

## Goal
Draft the reimplementable Forth-class VM and target specification before compiler work begins.

## Acceptance criteria
- Specify the instruction set, value and effect representation, dictionary calls, errors, cost hooks, and conformance observables.
- Define the running image format and the boundary between immutable target semantics and mutable word definitions.
- Provide enough detail for an independent implementation and a first conformance test plan.

## Traceability
Serves G5, G6 and G7 and requirements R6, R8 and R10; enables success criteria S3 and S6.
