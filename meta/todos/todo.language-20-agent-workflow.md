---
node: firth.toolchain.agent
status: open
created: 2026-09-08
---

Requires: language-05-baseline-acceptance

## Goal

Deliver a reproducible, documented authoring workflow.

## Acceptance criteria

- A clean environment can install a pinned release/toolchain and use documented check/run/test commands without reading compiler internals or governance files.
- Document only implemented capabilities as available; execute tutorial commands in CI and publish a versioned supported-feature and diagnostic reference.
- Expose local word signatures, typed-hole/stack feedback and actionable structured diagnostics through the public authoring interface, not just internal schemas.
- Separate development-time reference comparison from the eventual production runtime and measure edit/check latency. Do not drop the reference gate to appear faster.

## Traceability

PRD G8, R12/R13/R14; focused authoring ergonomics, not full LSP or package registry.

## Public test command slice

`meta/changes/public-source-tests/` adds saved input/output suites beside the
public `check` and `run` commands, with strict validation, real dual-host
execution and executable documentation. This addresses part of the workflow
criterion only. Keep this task open: pinned release installation, local
signature/typed-hole discovery and measured edit/check latency remain work,
and the fresh-context pilot has its own task.
