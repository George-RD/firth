---
id: dec.component-spec-boundaries
nodes:
  - firth.ecosystem.specs
  - firth.language.kernel
  - firth.toolchain.elaborator
  - firth.toolchain.compiler
  - firth.toolchain.interpreter
  - firth.toolchain.smt
  - firth.runtime.vm
  - firth.runtime.image
  - firth.runtime.patch
  - firth.toolchain.agent
  - firth.toolchain.diffharness
status: accepted
date: 2026-07-17
informed_by:
  - res.firth-kernel-spec.summary
  - res.firth-prd.summary
---

# Accepted component specification boundaries

Adopt `specs/component-spec-boundaries.md` as the v0.1 boundary map. The
frozen kernel specification owns language meaning. The VM target specification
owns the concrete target contract. The elaborator owns typing, linearity,
proof obligations, and the public `(WordType, Spec)` contract. The diagnostic
envelope owns the agent-interface wire format. The differential harness owns
the reproducible compiler/interpreter agreement oracle.

The document's dependency order is normative for authoring and review. It
prevents compiler, patch, diagnostics, and harness specifications from
silently outrunning the kernel or VM contracts. Its conformance evidence and
change-control rules apply to future component specifications and their
implementations.
