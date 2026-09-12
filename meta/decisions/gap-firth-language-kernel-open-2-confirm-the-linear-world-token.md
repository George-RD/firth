---
id: dec.gap-firth-language-kernel-open-2-confirm-the-linear-world-token
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: OPEN-2 the linear World token under preservation

## Question

OPEN-2: confirm the linear World token effect model during preservation

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "OPEN-2: confirm the linear World token effect model during preservation"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

Confirmed. Section 7 of the kernel specification fixes effects as the
single ordered linear `World` thread through primitive signatures
`Σ · World^linear · args → Σ · World^linear · results`; section 4 requires
each `δ_π` to return linear results only where its signature declares them
and never to duplicate or silently discard a linear value; section 6 item 2
requires preservation over such steps. The mechanisation proves
`KernelMetatheory.preservation_prim` under the `PrimitivesPreserve`
premise, so a well-typed prim step yields a well-typed configuration with
the declared `World` position, and `Linearity.finite_trace_at_most_once`
covers primitive events through `PrimitiveOwnershipPolicy`, so the token is
consumed at most once per event. The default `Gamma` in `Interpreter.lean`
(`makeWorldDelta`, `consumeWorldDelta`) is the executable instance. What
remains outside the freeze is observational refinement of effectful word
replacement, recorded separately in
`dec.gap-firth-runtime-patch-should-effectful-verified-patch-compatibility-use-an`.
