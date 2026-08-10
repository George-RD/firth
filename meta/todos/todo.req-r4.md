---
node: firth.toolchain.elaborator
status: open
created: 2026-08-10
---

# Compile-Time Linearity Enforcement
# Goal
Deliver PRD R4 by ensuring restricted (`^linear`) values cannot be implicitly duplicated or discarded during elaboration, and violations surface as deterministic compile-time diagnostics.

Requires: elaborator-parser elaborator-stack-effect-inference elaborator-refinement-discharge elaborator-pipeline-boundary

## Acceptance criteria
- The checked-kernel entry point rejects duplicate use, discard, and invalid consumption of `^linear` stack values before a program is accepted.
- Valid programs that consume each restricted value exactly once, including quotation capture and row-polymorphic paths, elaborate successfully without weakening existing usage checks.
- Diagnostics identify the linearity violation and source span through the accepted diagnostic envelope, with deterministic results across repeated elaboration.
- Add or extend integration tests covering duplicate use, discard, and valid single-use paths, with the zero-admit gate passing.

## Traceability
Satisfies PRD R4 and obligation `req-r4`.
