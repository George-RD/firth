---
node: firth.toolchain.compiler
status: open
created: 2026-09-08
---

Requires: language-05-baseline-acceptance language-10-inventory-contract

## Goal

Deliver the portable arithmetic and comparisons required by allocation.

## Acceptance criteria

- Support subtraction, minimum and comparison through defined primitives or checked words, with consistent parser/type/refinement/reference/compiler/VM behaviour.
- State numeric ranges, underflow and overflow exactly. Resolve the current Int name versus non-negative execution mismatch without silently changing frozen semantics.
- Test boundary values and invalid operands on both hosts, and add generated differential cases.
- Publish runnable examples and a capability table backed by tests. No untested signed/floating-point or general I/O promise.

## Traceability

Consumer-derived slice of PRD G2/G6/G9; supersedes adding arithmetic merely to fill a checklist.
