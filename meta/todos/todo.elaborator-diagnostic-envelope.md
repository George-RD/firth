---
node: firth.toolchain.agent
status: in_progress
created: 2026-07-18
---

Requires: elaborator-parser elaborator-stack-effect-inference diagnostic-schema

# Elaborator diagnostic envelope

## Objective

Implement version 1.0 serialisation and validation in the agent interface for elaborator diagnostics, typed holes, and signature-search messages using the accepted machine-readable envelope.

## Acceptance criteria

- Emit required identity, version, location, cause, stack-state, obligation, fix, and stable-code fields with deterministic ordering and one-based half-open ranges.
- Validate required fields, IDs, locations, supported major versions, code namespaces, pagination, and extensible enum values while preserving unknown optional data.
- Add JSON fixture and round-trip tests for diagnostics, typed holes, search requests, search responses, invalid payloads, and deterministic sorting; the implementation contains no `sorry`, `admit`, TODO placeholder, or unimplemented branch.

## Verification

- `lake build`
- `lake test`
- `! rg -n '\b(sorry|admit)\b|TODO|unimplemented|placeholder' src/agent`
- `git diff --check`

## Non-goals

- Do not expose internal AST, unification-variable, kernel-constructor, or solver-trace representations as required schema fields.
- Do not change inference, refinement semantics, editor rendering, or introduce a second diagnostic protocol.
