---
node: firth.toolchain.agent
status: open
created: 2026-08-10
---
Requires: mvp-agent-guide mvp-agent-examples mvp-agent-elaborate-adapter mvp-agent-compiler-adapter mvp-agent-reference-adapter mvp-agent-vm-adapter

# Mvp Agent Gate
## Goal
Add the deterministic MVP agent gate that validates provenance, rebuilds the examples in isolation, and compares VM results with the reference interpreter.

## Acceptance criteria
- `tools/loop/mvp_agent_gate.py` fails closed without the manifest or any required guide, interface, transcript, application, per-application source path or SHA-256, or transcript output hash equal to the checked-in application's SHA-256, and on any stale or mismatched entry.
- The gate rebuilds at least three manifest-listed applications in a scratch workspace exposing only each application's source and the toolchain, verifies elaboration, type and linearity checks, compilation, VM execution, and compiler/interpreter agreement.
- The gate is deterministic and is invoked by `python3 tools/loop/coverage.py --run-gates`.

## Traceability
Discharges the executable gate slice of obligation `mvp-agent-authoring`, under `dec.mvp-gate-provenance`.
