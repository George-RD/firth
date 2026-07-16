---
id: res.firth-prd.summary
nodes: [firth]
sources: [src.firth-prd]
date: 2026-07-16
---

## Vision

Firth is a concatenative programming language in the Forth tradition whose programs carry machine-checked guarantees. Source is elaborated through Lean 4 (where types and proof obligations are discharged), then compiled to a minimal Forth-class target for execution. The long-range thesis is that such a language is the natural substrate for large-scale machine-generated software: concatenative programs compose by concatenation, word-level granularity keeps changes small and independent, and a mechanical checker rather than human review is the arbiter of correctness. Machine authorship is a first-class design constraint, not a hoped-for side effect. Firth resolves the difficulty models have with implicit stack state by making machine state explicit and reasoning local everywhere: mandatory signatures, structured feedback designed for agent loops, and no dependence on distant context.

## Goals

- **G1 (provable core).** A kernel calculus of approximately a dozen combinators with fully specified typing rules and small-step operational semantics, small enough for mechanised metatheory in Lean.
- **G2 (stack effects).** Every word has a machine-checked stack effect; row polymorphism handles the rest of the stack. Stack imbalance is a compile-time error.
- **G3 (linearity).** Duplication and destruction of values are explicit. Resources cannot be silently leaked or aliased. The stack is the ownership model; no separate borrow checker.
- **G4 (refinements).** Stack effects may carry refinements discharged via SMT or interactive Lean proof. Verification effort is progressive from untyped-feeling code to full functional correctness.
- **G5 (live-patchable runtime).** A minimal Forth-class VM with word-level hot redefinition. The defining workflow is the verified live patch.
- **G6 (semantics preservation).** The compiler carries a mechanised proof or a clear path to one; until proven, enforced by differential testing against a reference interpreter.
- **G7 (cost model).** The kernel semantics admit cost annotations so that bounds on execution time and memory can be stated and checked.
- **G8 (machine-native authorship).** Mandatory stack-effect signatures, local reasoning, short words as the norm, named locals as the sanctioned escape, and a toolchain with structured machine-parseable diagnostics and typed holes.
- **G9 (staged generality).** The verified kernel is the permanent centre; breadth arrives by expanding the library, targets, and tooling around it. Successive stages: embedded and control systems, protocol and systems components, general server-side, mainstream application work.

## Non-Goals

Breadth before depth; a new proof assistant; legacy Forth compatibility; whole-program object systems, garbage collection, or heavyweight runtimes; mandatory proofs everywhere.

## Scope Layers

**Language:** kernel calculus, surface syntax (Forth-flavoured, point-free by default, named locals as sugar), type system (stack effects, row polymorphism, linearity, refinements), first-class quotations, vocabulary layering, specification predicates as words, naming grammar, module and word visibility.

**Toolchain:** elaborator embedded in Lean 4, reference interpreter in Lean, compiler to Forth-class target, differential test harness, SMT integration, agent interface (structured diagnostics, typed holes, signature search).

**Runtime:** minimal permissively-licensed VM, image model with word-level hot redefinition, verified-patch protocol.

**Ecosystem:** standard library written in Firth, language server and editor support, specification documents for kernel and VM.

## Requirements (grouped)

**Kernel and type system (R1–R4):** minimal combinator set (R1), every surface construct desugars to kernel terms (R2), decidable type checking with no annotations beyond word-level stack effects (R3), linearity violations as compile-time errors (R4).

**Semantics and verification (R5–R10):** reference interpreter as behavioural oracle (R5), individually replaceable compiled words in a running image (R6), replacement accepted only if stack effect and refinements are compatible (R7), TCB limited to Lean kernel, SMT solver, and VM (R8), proof obligations decomposable per word (R9), timing and memory claims derivable from cost semantics (R10).

**Local reasoning and tooling (R11–R17):** word semantics fully determined by body and callee signatures (R11), structured machine-parseable diagnostics (R12), typed holes reporting inferred stack state (R13), lintable stack manipulation depth with named locals as refactoring target (R14), refinement predicates as defined words (R15), dictionary searchable by signature (R16), word names checkable against naming grammar (R17).

## Success Criteria

- **S1.** Kernel metatheory mechanised in Lean with zero admitted lemmas.
- **S2.** Zero behavioural divergence between compiler and interpreter across sustained fuzzing.
- **S3.** Verified live patch demonstrated end to end.
- **S4.** Standard library self-hosted and checked by the toolchain.
- **S5.** A non-trivial program executed on the VM within a bounded cost envelope.
- **S6.** Third-party VM reimplementation from the specification alone passes the conformance suite.
- **S7.** Machine authorship demonstrated at a measured pass rate materially higher than on equivalent tasks in a mainstream language.

## Risks

Quotation typing (the hardest known design problem in typed concatenative languages); proof search stalls; readability of point-free code at scale; model fluency is engineered not assumed; generality without dilution; patch compatibility semantics under refinement types; cost model fidelity to real hardware.

## Licensing

Apache-2.0 for the toolchain and specifications. MIT/Apache-2.0 dual for the standard library, runtime, and code emitted into user programs. Nothing GPL is bundled or linked.

## Artefact Chain

PRD (this document) → kernel specification → Lean mechanisation (validates the spec, becomes normative) → component specifications (elaborator, compiler, VM, patch protocol, agent interface). The kernel specification is the single point where care concentrates; every downstream artefact inherits its correctness or its mistakes.
