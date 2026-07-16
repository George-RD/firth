---
id: dec.host-languages
nodes: [firth.runtime.vm, firth.toolchain.compiler, firth.toolchain.diffharness, firth.ecosystem.lsp]
status: proposed
date: 2026-07-16
informed_by: [res.host-language-tradeoffs]
---

# Proposed decision

Recommend Lean 4 for the compiler and differential harness, C99/C11 for the minimal VM, and Lean 4 as the deferred default for the LSP. This is not accepted: the VM choice is autonomy-critical and must be validated against extraction/FFI, embedded portability, licensing, fuzzing, and third-party reimplementation criteria before ratification. A later decision may ratify or supersede this recommendation.
