---
node: firth.toolchain.smt
status: open
created: 2026-08-06
---

# Smt Solver Profile Binding

Requires:

## Goal
Pin a permissively licensed, reproducible SMT solver profile for all later adapter work.

## Acceptance criteria
- Select one solver and record its licence, version, executable digest, and reproducible acquisition source.
- Define immutable invocation options, resource bounds, and supported theory profile fields.
- Provide a typed profile binding carried by every request and result without invoking the solver.

## Verification
- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability
Serves the solver identity and profile obligations of `todo.smt-adapter-integration`.
