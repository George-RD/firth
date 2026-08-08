---
id: res.kernel-cost-semantics-claims
nodes: [firth.language.kernel]
sources: [src.firth-prd, src.firth-kernel-spec-draft]
date: 2026-08-08
---

PRD R10 requires timing and memory claims to be derivable from stated cost
semantics rather than measurement alone. The kernel cost implementation defines
an explicit parameterised `CostTable`, charges atoms from that table, and sums
step costs over finite traces. The kernel source therefore supports semantic
execution-cost claims, including compositional trace costs.

The VM target specification distinguishes semantic charged cost from host
wall-clock and allocation counters. Those counters may be exposed as
diagnostics, but they are not semantic cost. The current governed cost model
has no independent memory metric. A conservative R10 implementation must keep a
closed registry of supported claim forms, derive registered claims from the
cost table and traces, and reject unsupported memory or measurement-only claims
until a separately governed memory metric exists.
