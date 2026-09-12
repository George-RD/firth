---
node: firth.toolchain.smt
status: done
created: 2026-08-06
---

# Smt Bounded Solver Results

Requires: smt-lean-adapter-proofs

## Goal
Implement bounded solver invocation and strict result classification.

## Acceptance criteria
- Bind solver identity, profile, request hash, resource bounds, and invocation options to every request and result.
- Enforce timeout and resource limits and classify crashes, malformed output, unknown, and exhaustion deterministically.
- Accept only a complete validated `sat` model as a counterexample and emit its deterministic diagnostic; keep unchecked `unsat` out of proof evidence.

## Verification
- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability
Serves the invocation and deferred-outcome obligations of `todo.smt-adapter-integration`.
