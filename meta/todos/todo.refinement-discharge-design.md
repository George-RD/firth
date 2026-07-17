---
node: firth.toolchain.smt
status: done
created: 2026-07-16
---

Requires:

## Goal
Define the SMT refinement-discharge boundary and its fallback to interactive Lean proofs.

## Acceptance criteria
- Specify which refinement predicates are translated to SMT, the solver result contract, and rejection of unknown or unsound results.
- Define proof-artefact recording, timeout handling, and the Lean escalation path without expanding the trusted base beyond the PRD allowance.
- Give representative positive, negative, and undecidable refinement examples tied to stack effects.

## Blockers
The final predicate language and stack-effect representation must be fixed by the kernel and type-system specifications; research and interface design can proceed now.

## Traceability
Serves G4 and G7 and requirements R8, R9, R10 and R15.
