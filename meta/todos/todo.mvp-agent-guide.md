---
node: firth.toolchain.agent
status: done
created: 2026-08-10
---
Requires: diagnostic-schema


# Mvp Agent Guide
## Goal
Provide the self-contained agent-facing language guide and checked-in interface manifest used by the MVP acceptance gate.

## Acceptance criteria
- The guide, kept under an existing blueprint documentation path, covers surface syntax, stack effects, quotations, refinements, the diagnostic loop, elaboration, compilation, VM execution, and worked basic applications without implicit repository context.
- The interface manifest lists the machine-facing commands, schemas, versioned entry points, and exact guide/interface paths consumed by the gate.
- A deterministic validation check proves the guide and manifest are present, internally consistent, and suitable as the model's only language and interface inputs.

## Traceability
Discharges the guide and interface slice of obligation `mvp-agent-authoring`, under `dec.mvp-gate-provenance`.
