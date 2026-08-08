---
id: dec.kernel-non-local-effect-isolation
nodes: [firth.language.kernel]
status: accepted
date: 2026-08-08
informed_by: [res.firth-kernel-spec.summary]
---

# Kernel effect and dependency boundary

## Context

Autonomous author: loop/todo.req-r11. R11 requires a word's semantics to be
locally determined by its body and the signatures of referenced words. The
existing typing judgement resolves dictionary words and primitives, but the
resolved dependency set was not an executable artefact.

## Decision

Represent each resolved dictionary-word reference with its `WordType` and each
resolved primitive reference with its input and output `StackType`s. Collect
these dependencies recursively through sequences, quotations, pushed values,
and nested quotation bodies. A kernel effect boundary packages the word body,
its declared stack effect, the dependency list, and the `ProgramTyping` proof.

Primitive implementation deltas remain behind the existing `PrimitiveSpec` and
`PrimitivesPreserve` contract. A body whose declared stack effect cannot type a
primitive's effect is rejected by `ProgramTyping`, rather than being accepted
with an untracked effect. The boundary is intentionally syntactic and direct:
transitive dictionary closure remains represented by each referenced word's
signature and is not duplicated into the caller's list.

## Consequences

Well-typed bodies have a mechanically resolved boundary for every external
lookup, including recursive references. Unresolved dictionary or primitive
lookups cannot produce a boundary. The frozen kernel specification and runtime
semantics remain unchanged.
