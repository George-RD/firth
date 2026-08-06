---
id: dec.elaborator-pipeline-failures
nodes:
  - firth.toolchain.elaborator
  - firth.toolchain.agent
status: accepted
date: 2026-08-06
informed_by:
  - res.firth-prd.summary
---

# Integrated pipeline diagnostics

Autonomous author: loop/todo.elaborator-pipeline-failures

Keep the pure elaborator pipeline and its internal `ElaborationResult` unchanged. Add the integration boundary in the agent module, where the existing stage adapters already depend on both the pipeline types and the accepted diagnostic envelope. The bridge invokes the pure boundary once and returns a typed success-or-failure result: successful checked programs remain available as Lean values, while failures retain every pipeline diagnostic as an envelope.

Use one emission context for request identity and source location. Reuse the existing parser, erasure, stack-effect, refinement, and typed-hole adapters rather than introducing a second mapping or protocol. The invariant internal branch emits the stable `firth.elaboration.internal` diagnostic with its originating span. This preserves validation semantics and keeps compiler, VM, LSP, and CLI behaviour out of scope.
