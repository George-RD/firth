---
node: firth.runtime.vm
status: done
created: 2026-08-10
---
Requires: rust-vm-implementation

# MVP agent VM adapter
## Goal
Provide the gate-required `firth.vm-run.v1` adapter over the Rust VM image and execution APIs.

## Acceptance criteria
- The adapter accepts manifest VM execution records, validates the target image and fuel budget, and emits deterministic structured observations.
- Malformed images, unknown instructions or words, invalid primitives, stack faults, and fuel exhaustion are classified as specified rather than treated as success.
- The adapter runs in the isolated MVP gate workspace and preserves the target/interpreter comparison fields required by the manifest.

## Traceability
Prerequisite for `todo.mvp-agent-gate`; implements the VM boundary pinned by `dec.mvp-gate-provenance`.
