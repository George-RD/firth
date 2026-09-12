---
id: dec.usable-language-milestones
nodes: [firth.governance.loop, firth.toolchain.elaborator, firth.toolchain.compiler, firth.toolchain.smt, firth.runtime.vm, firth.toolchain.diffharness, firth.toolchain.agent, firth.ecosystem.stdlib, firth.ecosystem.specs]
status: accepted
related: [dec.mvp-completion, dec.loop-autonomy]
date: 2026-09-08
---
# Accept useful language milestones, not an exhausted queue

## Authority and context

Maintainer-authorised outside the unattended loop. The maintainer requested:
"Update roadmap, start working on key elements to make firth a language to be
taken seriously", after discussing trustworthy checks, a useful component and
fresh-agent maintenance. This decision strengthens the active endpoint; it
does not let autonomous iterations edit their own success criteria.

PR #109 at c319e32 had green finite tests but accepted source annotations that
were not translated into obligations. The differential-harness obligation was
linked only to a completed strategy document. Known follow-on work remained in
comments rather than selectable tasks. These are evidence and handoff defects.

## Decision

1. Keep profile `mvp` and the eight existing post-mvp rows unchanged. Extend the
   active acceptance endpoint with trustworthy baseline, useful inventory
   component and public-documentation change-pilot obligations. This amends
   dec.mvp-completion's concrete acceptance scope only; its profile filtering,
   maintainer authority and requirement to accept on main remain binding.
2. Add implementation todos to affected existing obligations. A completed
   specification remains historical design evidence, never sole evidence of
   an implementation. The baseline audit must find and repair other such gaps.
3. Source annotations without a real translation/checking path are refused
   before erasure; a true annotation is no exception. Unsupported linear
   quotation ownership is refused rather than erased. Validate capture shape
   before canonical encoding. These are conservative refusals, not new kernel
   semantics or authenticated evidence mechanisms.
4. Preserve type checking, contract discharge and execution testing as distinct
   claims. The raw adapter proof markers/evidence hashes still need admission
   work; documentation must not upgrade them to proofs.
5. Select the first consumer described in specs/inventory-allocation.md. Keep
   fixed acceptance examples independent of its eventual implementation. Host
   I/O is outside the pure component's proof; no live business integration is
   authorised by this development milestone.
6. Reuse the existing tracker, selector, coverage and CI. Add no orchestration
   framework. Full gate failure or unresolved correctness review blocks a merge;
   open future milestone work correctly keeps project exhaustion false.

## Consequences

`docs/roadmap.md` explains priorities; `meta/todos/` and obligations.toml drive
them. Full source refinement execution, actual differential testing and an
agent-maintained application stay open until their own executable acceptance.
Verified branch work and verified main are recorded separately. The frozen
kernel, original agent corpus, transcript evidence and proof pins are unchanged.
