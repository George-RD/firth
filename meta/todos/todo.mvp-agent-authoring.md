---
node: firth.toolchain.agent
status: done
created: 2026-08-10
---

# MVP agent authoring

## Goal
Discharge the MVP acceptance obligation with a machine-checked agent-facing language guide, minimal example applications, and a pinned gate proving that a code model can use only the guide and agent interface to build and run basic Firth applications.

Requires: diagnostic-schema mvp-agent-guide mvp-agent-examples mvp-agent-gate mvp-agent-coverage

## Acceptance criteria
- Provide the agent-facing guide and the checked-in interface manifest used by the gate, with no implicit repository context.
- Provide at least three basic applications authored by the model from only the guide and agent interface, plus the model transcript and provenance manifest required by `dec.mvp-gate-provenance`.
- Add `tools/loop/mvp_agent_gate.py` to verify the manifest hashes, rebuild each application in an isolated workspace, elaborate and check it, compile it, run it on the VM, and compare its result with the reference interpreter.
- Make the gate deterministic, fail closed on missing or stale guide, interface, transcript, application, or hash entries, and invoke it from `python3 tools/loop/coverage.py --run-gates`.

## Traceability
Discharges obligation `mvp-agent-authoring` and the MVP reading of PRD S5 and S7 recorded by `dec.mvp-gate-provenance`.
