---
id: dec.firth-blueprint
nodes: [firth, firth.language, firth.language.kernel, firth.language.surface, firth.language.types, firth.toolchain, firth.toolchain.elaborator, firth.toolchain.interpreter, firth.toolchain.compiler, firth.toolchain.diffharness, firth.toolchain.smt, firth.toolchain.agent, firth.runtime, firth.runtime.vm, firth.runtime.image, firth.runtime.patch, firth.ecosystem, firth.ecosystem.stdlib, firth.ecosystem.lsp, firth.ecosystem.specs]
status: accepted
date: 2026-07-16
informed_by: [res.firth-prd.summary, res.firth-kernel-spec.summary]
---

# Decision

Adopt a four-layer architecture for Firth: language and specification, toolchain, runtime, and ecosystem. The System node is the integration boundary and owns the flat Cairn artefact directories under `meta/`. The language layer owns the current design files and future language specifications. The other layers declare the intended Lean 4, VM, and Firth implementation paths even though this repository is still in the spec phase.

## Rationale for the layers

The language layer isolates the permanent verified core. The kernel module owns the PRD and draft kernel specification in `files/`, plus the future kernel specification path. Surface syntax and the type system are separate modules because all surface constructs must desugar to kernel terms (R2), while stack effects, row polymorphism, linearity, and refinements define the checking boundary (R3, R4, R15). This separation keeps the kernel small enough for Lean metatheory with zero admitted lemmas (G1 and S1), without making the surface language part of the trusted semantics.

The toolchain layer contains the elaborator, reference interpreter, compiler, differential harness, SMT integration, and agent interface. The elaborator is the Lean 4 boundary where surface programs become checked kernel terms. The interpreter is deliberately independent and defines behaviour, as required by R5. A compiler divergence is therefore a compiler bug, not a change of semantics. The differential harness compares both executions under fuzzing, supporting G6 and S2. SMT is an optional discharge mechanism for refinement obligations, while the agent interface keeps diagnostics, typed holes, and signature search structured and machine-parseable (R12, R13, and R16). These boundaries support the R8 trusted computing base: Lean's kernel, the SMT solver where used, and the VM remain trusted, while the other components produce checkable artefacts.

The runtime layer keeps execution auditable and small. The VM is the Forth-class target and the image model is the live word dictionary. The patch protocol is separate because a replacement must be rechecked for compatible stack effects and refinements before it is swapped into a running image (G5, R6, and R7). The design therefore makes the verified live patch an explicit protocol rather than an incidental VM feature. The VM and image model remain distinct so target semantics and mutable deployment state can be reasoned about separately.

The ecosystem layer contains the Firth standard library, language server, and reimplementable kernel and VM specifications. The standard library is source in Firth and must pass the same elaboration and verification gates. The language server consumes structured toolchain feedback. The specification module records the public conformance surface needed for third-party VM implementations and S6, without enlarging the kernel or runtime implementation boundary.

## Data flow and boundaries

The normative path is source through surface syntax and the elaborator, to kernel terms, through the compiler, to the Forth-class target and VM. Type and linearity checking and refinement discharge occur during elaboration. The kernel module is the semantic centre, and the interpreter executes those terms directly as the behavioural oracle. The differential harness depends on both compiler and interpreter so agreement remains an independently checked property.

The verified-patch protocol depends on both elaboration and the VM: it re-elaborates and checks the replacement, then admits it to the live image hosted by the VM. The standard library enters through elaboration, and the language server and agent interface expose the same local, structured feedback to authors. Specification edges point to the kernel and VM they describe. These edges express data flow and verification dependencies, while containment expresses ownership and does not imply an implementation language.

All current files under `files/` are claimed by `firth.language.kernel`; future paths are intentionally declared under the owning leaf modules so implementation can proceed without orphaned source files. Lean 4 and a Forth-class VM are the intended stack. Cairn 0.1.x path reconciliation is therefore treated as a declaration of intent until those paths contain implementation files.
