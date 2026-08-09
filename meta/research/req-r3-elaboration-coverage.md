---
id: res.req-r3-elaboration-coverage
nodes: [firth.toolchain.elaborator, firth.toolchain.agent]
sources: [src.firth-prd, src.firth-kernel-spec-draft]
date: 2026-08-09
---

# R3 elaboration coverage

## Evidence

`Firth.Elaborator.elaborateWith` is already the accepted pure boundary. Its
implementation performs parsing, whole-dictionary erasure, stack-effect
checking, and refinement discharge in that order. `CheckedWord.program` is the
located checked kernel representation, and `PipelineDiagnostic` carries the
stage-specific structured failure.

The pipeline test already covers annotation-free literals, row polymorphism,
recursion, erasure failures, stack mismatches, refinements, and repeated
successful results. It does not directly exercise quotation branch inference
or compare repeated failures. The stack-effect and agent suites separately
cover quotation inference, typed-hole state inference, and typed-hole envelope
encoding.

## Decision input

R3 requires decidable intra-word inference but does not define source-level
hole syntax. Typed-hole reporting is the R13 agent-interface obligation. A
source-hole addition here would create a second cross-module contract and
expand this unit beyond the existing R3 boundary. The smallest evidence-based
completion is therefore to add missing pipeline fixtures while retaining the
existing typed-hole API and envelope adapter for R13.
