---
node: firth.toolchain.agent
status: done
created: 2026-08-10
---
Requires: mvp-agent-guide


# Mvp Agent Examples
## Goal
Provide at least three basic Firth applications and the model-authored transcript and provenance manifest required by the MVP gate.

## Acceptance criteria
- At least three applications are authored using only the agent-facing guide, checked-in interface manifest, and task.
- Each application elaborates with type and linearity checks, compiles, runs on the VM, and has a deterministic expected result matching the reference interpreter.
- The transcript is stored under `meta/sources/`, records only the guide, interface, and task as context, and the provenance manifest records each application's source path and SHA-256 plus the transcript output hash equal to the checked-in application's SHA-256 and exact guide, interface, transcript, and application bytes.

## Traceability
Discharges the application and provenance slice of obligation `mvp-agent-authoring`, under `dec.mvp-gate-provenance`.
