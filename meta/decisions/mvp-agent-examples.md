---
id: dec.mvp-agent-examples
nodes: [firth.governance.loop, firth.toolchain.agent]
status: accepted
date: 2026-08-10
informed_by: [src.mvp-agent-example-literal-int, src.mvp-agent-example-quotation-call, src.mvp-agent-example-conditional, src.mvp-agent-example-add-one]
---
# MVP Agent Example Corpus

## Context

The MVP agent-authoring obligation requires checked-in applications and
transcripts, while the executable gate and adapters are a later unit. The
applications need a blueprint path that identifies them as inputs to the
agent interface rather than as general documentation or runtime code.

Autonomous author: loop/todo.mvp-agent-examples

## Decision

Add `examples/mvp` to `firth.toolchain.agent`. Author three closed,
deterministic applications using only literals and kernel atoms already
specified by the guide: a literal result, quotation invocation, and Boolean
conditional. Pin each application to a transcript under `meta/sources/` with
its exact output SHA-256 in `tools/loop/mvp_agent_manifest.toml`.

The executable elaboration, compilation, reference execution, VM execution,
and agreement checks remain the responsibility of the later MVP gate unit.

## Rationale

Keeping the corpus on the agent module makes Cairn ownership match the
machine-facing boundary. Closed examples avoid inventing an adapter command or
relying on a primitive implementation before the gate unit provides those
adapters, while still exercising literals, quotations, and conditionals.

## Provenance note, 9 September 2026

The executable gate unit (`mvp-agent-gate`) added a fourth application,
`examples/mvp/add-one.firth`, because the three original applications never
reached the Gamma primitive profile. Its transcript
`src.mvp-agent-example-add-one` is pinned in
`tools/loop/mvp_agent_manifest.toml` like the other three and is listed here
so the corpus's provenance is complete. The decision text above is unchanged;
this note only records the later addition (baseline obligation audit,
`meta/changes/baseline-obligation-audit/`).
