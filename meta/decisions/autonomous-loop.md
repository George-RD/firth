---
id: dec.autonomous-loop
nodes: [firth.governance, firth.governance.loop]
status: accepted
date: 2026-07-16
---

# Decision

Place Firth's autonomous development loop in a dedicated Governance container,
outside the four product layers (Language, Toolchain, Runtime, and Ecosystem).
The Governance Loop module owns the injected command, recovery and landing
procedures, deterministic todo selector, and its stdlib tests under `.claude/`,
`tools/loop`, and the Codex-facing runbook under `docs/`.

## Rationale

The loop is operational machinery for changing the product graph, not part of
the language, compiler, runtime, or ecosystem delivered by Firth. A dedicated
module gives Cairn an explicit path claim while keeping the four product layers
focused on the language and its implementation. The command trio preserves
one-unit sessions, persistent isolation, fail-closed recovery, explicit
artefact staging, and one squash commit. The selector makes Requires
validation and eligibility reproducible across fresh unattended Codex
sessions instead of relying on prose interpretation.

This decision and the loop artefacts are the governance change proposed in
`meta/changes/autonomous-loop/`; that change is the provenance for the
container and module claim.
