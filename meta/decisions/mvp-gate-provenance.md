---
id: dec.mvp-gate-provenance
nodes: [firth.governance.loop, firth.toolchain.agent]
status: accepted
related: [dec.mvp-completion]
date: 2026-08-08
---
# MVP Gate Pinning and Authorship Provenance

## Context

dec.mvp-completion clause 4 defines the MVP acceptance gate in prose: a
guide, code-model-authored example applications, and "a gate script or
test target" wired into verification. Two gaps remained. First, the gate
had no pinned location, so nothing machine-checkable tied the clause to
a file on `main`. Second, nothing bound the authorship claim, "authored
by a code model given only the guide and the agent interface", to bytes:
hand-written applications could have discharged the row while the
AI-usable endpoint was never exercised.

Two amendments to that clause were briefly published as in-place edits
of the accepted decision (`94cedf8`, `9883900`); that violated the
supersede rule this repository holds decisions to, so this decision
restores the accepted text and carries both amendments properly. This is
maintainer-authored and landed outside the loop.

## Decision

Amends dec.mvp-completion clause 4 only; everything else in that
decision binds unchanged.

1. **Pinned gate.** The gate script lives at
   `tools/loop/mvp_agent_gate.py`. The matrix row carries
   `gate = "tools/loop/mvp_agent_gate.py"`; `coverage.py` holds
   `loop_exhausted_valid` false with `missing_gates` naming the path
   while it is absent, and executes it under `--run-gates` (bounded by
   `COVERAGE_GATE_TIMEOUT`, group-killed on timeout). The driver re-runs
   that command before accepting `LOOP EXHAUSTED`; the Verify battery
   and the dry-run preflight run it too. Done todos alone can never
   discharge the endpoint.

2. **Provenance manifest.** A manifest pinned at
   `tools/loop/mvp_agent_manifest.toml` binds the authorship claim to
   bytes: sha256 of the exact guide and agent-interface files the model
   was given; per application, its source path, sha256, and the
   authoring transcript (stored under `meta/sources/` per the artefact
   rules) whose recorded context lists only the guide, the agent
   interface, and the task, and whose recorded output hashes to the
   checked-in application. Any later hand edit to an application or the
   guide breaks the manifest mechanically.

3. **Gate behaviour.** The gate fails without the manifest, fails on any
   hash mismatch, and then rebuilds and runs each application in a
   scratch workspace exposing only that application's source and the
   toolchain, verifying elaboration, type/linearity checks, compilation,
   VM execution, and compiler/interpreter agreement.

4. **Trust boundary, stated plainly.** No gate can prove a transcript
   was not fabricated: the loop is itself a code model. The manifest
   makes the authorship claim falsifiable and drift-detected, the
   two-lens review and the goal layer guard the process, and a human can
   audit the cited transcript at any time.

## Rationale

Pinning turns clause 4 from prose into paths that coverage, the driver,
and the preflight all check mechanically. Hash-binding does the same for
the authorship claim to the extent the claim admits verification at all;
the residual trust boundary is recorded rather than implied. Restoring
the accepted text and carrying the amendments here keeps the decision
graph append-only, which is what lets the loop treat accepted decisions
as stable ground.

## Consequences

- `meta/decisions/mvp-completion.md` is restored byte-identical to its
  accepted form (`28db8b7`); this decision is the sole carrier of both
  amendments.
- `tools/loop/obligations.toml` row comment points here.
- The backlog-generated todos for `mvp-agent-authoring` must implement
  the manifest and gate as specified; a gate that skips manifest
  verification is a defect, not a discharge.
