# Design: reference-interpreter-conformance

## Approach

Keep the reference oracle as the semantic authority and add a small
representation of the target's canonical report in the interpreter module.
The report carries semantic residual state, observed `World`, an explicit
outcome class, the target fuel budget, and the target's aggregated κ cost.
The comparison first enforces the fuel relation and outcome class, then
compares residual state and `World`. It validates target κ cost independently
from reference step cost, so instruction expansion remains legal.

## Changes

ADDED:
- `TargetStatus`, `TargetObservation`, and `compareTargetObservation` in
  `src/interpreter/Firth/Interpreter.lean`.
- Executable conformance examples in `src/interpreter/FirthTest.lean`.
- Accepted decision `meta/decisions/reference-interpreter-conformance.md`.

MODIFIED:
- The governed proof-module manifest after the Lean build.
- `meta/todos/todo.reference-interpreter-conformance.md` during landing.

REMOVED:
- None.

RENAMED:
- None.
