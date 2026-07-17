---
id: dec.kernel-metatheory-shared-library
nodes: [firth.language.kernel, firth.toolchain.interpreter]
status: accepted
date: 2026-07-17
---

# Shared kernel metatheory library

The interpreter remains the executable owner of the v0.1 syntax and transition
definitions.  The first metatheory module is therefore colocated in the Lean
library under `src/interpreter/Firth`, imports those definitions, and is also
claimed explicitly by the kernel module in the blueprint.  This avoids a
second, divergent syntax or step relation while the project is still small.

The current landed interpreter has no typing judgement, typed configurations,
or ownership-trace relation.  Consequently this unit records only the
determinism and generic sequence-cost lemmas that can be proved against the
actual executable definitions.  Preservation, progress, finite-trace
linearity, conditional exact-once, and program-level cost invariance remain
deferred until those frozen-spec structures are added in a subsequent governed
implementation wave.
