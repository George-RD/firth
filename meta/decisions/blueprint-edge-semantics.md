---
id: dec.blueprint-edge-semantics
nodes: [firth, firth.language, firth.language.kernel, firth.language.surface, firth.language.types, firth.toolchain, firth.toolchain.elaborator, firth.toolchain.interpreter, firth.toolchain.compiler, firth.toolchain.diffharness, firth.toolchain.smt, firth.toolchain.agent, firth.runtime, firth.runtime.vm, firth.runtime.image, firth.runtime.patch, firth.ecosystem, firth.ecosystem.stdlib, firth.ecosystem.lsp, firth.ecosystem.specs]
status: accepted
date: 2026-07-16
supersedes: [dec.firth-blueprint]
informed_by: [res.firth-prd.summary, res.firth-kernel-spec.summary]
---

# Decision

Cairn blueprint edges use depends-on semantics: `A -> B` means A requires B. The blueprint edges are therefore authored for implementation prerequisites, not merely narrative data flow. The kernel is the foundational semantic artefact. Surface and type specifications depend on it; the elaborator, interpreter, compiler, and VM target contract follow it. The compiler depends on the VM instruction contract, while the VM does not depend on the compiler. The interpreter remains the behavioural oracle, and the differential harness depends on both compiler and interpreter.

This decision supersedes the edge section of `dec.firth-blueprint`, whose arrows described data flow and consequently produced an inverted Cairn order. Temporal freeze gates remain todo-level requirements and are not inferred from module edges.
