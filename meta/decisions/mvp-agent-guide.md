---
id: dec.mvp-agent-guide
nodes:
  - firth.toolchain.agent
  - firth.governance.loop
status: accepted
date: 2026-08-10
informed_by:
  - res.firth-prd.summary
related:
  - dec.mvp-completion
  - dec.mvp-gate-provenance
---
# Mvp Agent Guide

## Context

The MVP endpoint requires a code model to author applications from only a
language guide and the agent interface. The language rules, diagnostic
protocol, elaboration boundary, and VM target are otherwise spread across
several repository artefacts. The accepted MVP decisions pin the guide to an
existing documentation path and the provenance manifest to
`tools/loop/mvp_agent_manifest.toml`, but do not define the input sections or
the deterministic preflight that checks them.

Autonomous author: loop/loop/todo.mvp-agent-guide

## Decision

Use `docs/firth-agent-guide.md` as the self-contained model-facing language
guide. Use `tools/loop/mvp_agent_manifest.toml` as the single versioned
machine-facing interface and provenance manifest, with `[inputs]` naming the
guide and interface bytes and `entry_point` tables defining the four
source-to-execution request and response contracts.

## Rationale

The `docs` and `tools/loop` paths are already claimed by the governance module,
so this unit adds no blueprint path or cross-module edge. Keeping one manifest
at the path pinned by `dec.mvp-gate-provenance` avoids a second, conflicting
interface inventory. Logical entry-point identifiers are used instead of
invented host commands because the current repository does not yet provide a
complete compiler and VM adapter. A standard-library checker validates the
declared files, required guide sections, entry-point schemas, and content
hashes before the later executable gate consumes applications.

## Consequences

The guide is the only prose language input and must remain standalone. The
manifest is the stable boundary for future application transcripts, source
hashes, and gate adapters. Adding an application or changing a guide or
interface byte requires the provenance manifest and its hashes to be updated.
The checker proves structural consistency and byte identity, but it cannot
prove that a transcript was genuinely produced by a model, as recorded by
`dec.mvp-gate-provenance`.
