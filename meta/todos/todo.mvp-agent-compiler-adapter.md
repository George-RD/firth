---
node: firth.toolchain.compiler
status: done
created: 2026-08-10
---
Requires: rust-vm-implementation

# MVP agent compiler adapter
## Goal
Provide the gate-required `firth.compile.v1` adapter that lowers checked kernel programs to the target image format without bypassing the checked representation.

## Acceptance criteria
- The adapter consumes structured checked-kernel records and emits deterministic target-program records for the manifest contract.
- Unknown atoms, words, primitives, malformed records, and stale evidence fail closed.
- The compiler adapter runs in the isolated MVP gate workspace and has conformance coverage against the reference interpreter and VM target.

## Traceability
Prerequisite for `todo.mvp-agent-gate`; implements the compiler boundary pinned by `dec.mvp-gate-provenance`.
