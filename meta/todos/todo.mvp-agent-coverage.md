---
node: firth.toolchain.agent
status: done
created: 2026-08-10
---
Requires: mvp-agent-gate


# Mvp Agent Coverage
## Goal
Wire the MVP agent gate into the obligations coverage command and keep its acceptance inputs and hashes synchronised.

## Acceptance criteria
- `python3 tools/loop/coverage.py --run-gates` invokes `tools/loop/mvp_agent_gate.py` and reports its result deterministically.
- The obligations matrix names the pinned gate, while `tools/loop/mvp_agent_manifest.toml` remains the authoritative inventory of guide, interface, transcript, application, and hash artefacts, without changing the immutable completion profile.
- Stale or missing acceptance inputs fail closed before coverage can report completion.

## Traceability
Discharges the coverage integration slice of obligation `mvp-agent-authoring`, under `dec.mvp-gate-provenance`.
