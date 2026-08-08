---
id: dec.kernel-cost-semantics-claims
nodes:
  - firth.language.kernel
status: accepted
date: 2026-08-08
informed_by:
  - res.kernel-cost-semantics-claims
  - src.firth-prd
  - src.firth-kernel-spec-draft
---

Autonomous author: loop/backlog.firth.language.kernel.

Treat R10 claims as a closed registry of supported timing and memory claim
forms. A registered claim must be derived from the parameterised kernel cost
table and finite execution traces. Wall-clock measurements and host allocation
counters remain diagnostics and cannot discharge R10. The current kernel cost
model has no governed memory metric, so unsupported memory claims are rejected
rather than inferred from measurements. Adding a semantic memory metric or
expanding the registry requires a later decision with its own governed
semantics.
