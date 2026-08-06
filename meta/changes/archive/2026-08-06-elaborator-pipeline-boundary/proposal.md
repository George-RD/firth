# Proposal: elaborator-pipeline-boundary

## Motivation

The elaborator currently exposes independent parser, erasure, stack-effect,
and refinement libraries, but no governed boundary composes them. Callers must
reimplement stage ordering and cannot receive one deterministic result for
source text.

## Scope

- Add a stable Lean API from source text to checked kernel words or structured
  stage diagnostics.
- Run parsing, deterministic erasure, dictionary stack-effect checking, and
  refinement discharge in that order.
- Add a deterministic `firth` CLI that reads stdin or one source path and
  returns a stable success or failure exit status.
- Add focused tests for successful composition and each early failure boundary.

## Out of scope

- New surface-language syntax or refinement syntax.
- Compiler, VM, LSP, agent-envelope, or SMT-adapter implementation changes.
- Persisting proof records or implementing an external SMT client.
