---
node: firth.toolchain.elaborator
status: open
created: 2026-08-09
---

# Scope Toolchain Elaborator
Requires: elaborator-parser elaborator-named-local-erasure elaborator-stack-effect-inference elaborator-refinement-discharge elaborator-pipeline-boundary

## Goal
Complete the PRD 4.2 elaborator boundary from Firth surface programs to checked kernel terms.

## Acceptance criteria
- Integrate the accepted parser, erasure, inference, and refinement stages behind one deterministic public elaborator boundary.
- Preserve deterministic checked terms and diagnostics for valid programs and type, linearity, or proof-obligation failures.
- Verify the boundary without new kernel semantics or unimplemented branches.

## Traceability
Serves the PRD 4.2 elaborator obligation.

## Verification
- `lake build`
- `lake test`
- `python3 tools/loop/test_select_unit.py`
- `python3 tools/loop/test_coverage.py`
