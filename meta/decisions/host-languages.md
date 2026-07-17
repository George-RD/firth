---
id: dec.host-languages
nodes: [firth.language.kernel, firth.toolchain.elaborator, firth.toolchain.interpreter, firth.toolchain.compiler, firth.toolchain.diffharness, firth.runtime.vm, firth.ecosystem.lsp]
status: accepted
date: 2026-07-17
informed_by: [res.host-language-tradeoffs]
---

# Accepted host-language decision

Use Lean 4 for the elaborator, reference interpreter, compiler, metatheory, and initial language server, with a zero-admit target for the proof-bearing parts. Use a minimal Forth-class VM implemented in Rust for the compiler target. The Rust VM is permissively licensed under MIT or Apache-2.0 dual licensing, hosts the word-level hot-redefinition image model and verified-patch protocol, and remains a trusted but unverified component.

The trusted computing base is therefore unchanged from PRD R8: Lean kernel, SMT solver where used, and VM. Rust reduces memory-unsafety risk within the trusted VM; it does not make the VM untrusted, verified, or outside the TCB. VM semantic correctness remains governed by its specification, tests, conformance suite, and future verification work.

This decision follows the comparison in `res.host-language-tradeoffs`. Rust has no material blocker against the actual VM constraints: a `no_std`-first, dependency-minimal implementation can remain small and portable; code-as-data word objects permit atomic dictionary binding replacement; and Rust's ownership and atomic facilities reduce risks in image and patch handling. The image specification must still define allocation, reclamation, reader quiescence, and in-flight calls.

Alternatives considered and not chosen:

- C is maximally portable and can produce a very small VM, but its manual memory and aliasing discipline increases the risk carried by the trusted component.
- Zig offers explicit allocation, C interoperability, and cross-compilation, but its ecosystem and release stability are less established for this foundational runtime, and it provides less memory-safety assistance than Rust.
- Lean-hosted VM code would maximise proof reuse, but would couple the production runtime to the proof host and work against minimal image/patch ergonomics and independent reimplementation.
- OCaml and Haskell introduce garbage-collected runtime machinery that complicates a minimal image and atomic patch model; neither is needed for the Lean-side proof core.

The initial LSP host is Lean 4 because it can reuse structured elaborator diagnostics without adding another semantic implementation. The LSP is not in the TCB and may later move to Rust if deployment evidence warrants it.

This accepted decision unblocks `firth.runtime.vm` todo `vm-target-spec`, while leaving its target-specific representation and protocol obligations open for that specification. Dependency licence manifests, unsafe-code review, target support, and conformance evidence are gates for accepting the VM implementation and component specifications, not blockers on this host-language architecture decision.
