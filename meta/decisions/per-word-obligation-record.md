---
id: dec.per-word-obligation-record
nodes: [firth.language.kernel]
status: accepted
date: 2026-08-08
informed_by: [res.firth-kernel-spec.summary]
---

# Per-word kernel obligation records

Autonomous author: loop/todo.req-r9

The kernel records one checked obligation per dictionary word. The record keeps
its word name and body, the referenced word signatures, the resolved kernel
dependencies used as premises, the checker identifier, and an explicit result.
The existing dependency traversal remains canonical, so references cannot drift
from the kernel body or dictionary.

A word record is accepted only when its `ProgramTyping` proof and resolved
`KernelEffectBoundary` are supplied. Vocabulary composition propagates
rejected and unchecked results and accepts only an all-accepted list. Changing
one word invalidates that word and the transitive dependants discovered from
recorded references. Persistence, hashing, and compiler integration remain
outside this decision.
