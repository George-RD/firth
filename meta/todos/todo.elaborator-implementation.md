---
node: firth.toolchain.elaborator
status: open
created: 2026-07-18
---

Requires: elaborator-parser elaborator-named-local-erasure elaborator-stack-effect-inference elaborator-refinement-discharge elaborator-diagnostic-envelope

# Elaborator implementation integration

## Objective

Integrate the parser, deterministic erasure, stack-effect inference, refinement bridge, and diagnostic envelope into one Lean 4 elaboration entry point that returns checked kernel terms or structured failures.

## Acceptance criteria

- Provide a stable library and CLI boundary that performs the complete source-to-checked-kernel pipeline in dependency order and preserves source locations through failures.
- Exercise successful programs and each failure class end to end, including typed holes, refinement escalation, recursive dictionaries, and deterministic repeated elaboration.
- Add integration tests and a zero-admit gate for the complete path; the implementation contains no `sorry`, `admit`, TODO placeholder, or unimplemented branch.

## Verification

- `lake build`
- `lake test`
- `! rg -n '\b(sorry|admit)\b|TODO|unimplemented|placeholder' src/elaborator`
- `git diff --check`

## Non-goals

- Do not implement compiler lowering, VM execution, LSP transport, whole-program optimisation, or a new surface feature.
- Do not weaken any child component's validation or bypass the approved SMT and diagnostic contracts.
