---
node: firth.toolchain.agent
status: open
created: 2026-07-16
---

## Goal
Define the structured diagnostic and typed-hole schema before elaborator implementation emits user-facing errors.

## Acceptance criteria
- Specify versioned fields for location, cause, expected and actual stack state, obligations, severity, and proposed fixes.
- Specify typed-hole payloads and signature-search requests and results, including stable machine-readable error codes.
- Provide JSON examples and validation rules that can be consumed by an agent loop and rendered by an editor.

## Traceability
Serves G8 and requirements R12, R13 and R16; enables success criterion S7.
