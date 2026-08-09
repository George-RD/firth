---
node: firth.toolchain.elaborator
status: done
created: 2026-08-09
---

# Decidable Stack-Effect Elaboration
# Goal
Deliver the PRD R3 elaboration path: type checking is decidable, word-level stack effects are the only required annotations, and intra-word typing is inferred by the Lean elaborator.

Requires: elaborator-parser elaborator-named-local-erasure elaborator-stack-effect-inference elaborator-refinement-discharge elaborator-diagnostic-envelope elaborator-pipeline-boundary

## Acceptance criteria
- Expose one deterministic source-to-checked-kernel entry point that accepts word-level stack effects and runs parsing, erasure, stack-effect inference, and refinement checking in the accepted pipeline order.
- Infer every intra-word stack state across concatenation, quotations, dictionary references, and recursive words without per-token annotations; reject stack mismatches and unresolved typed holes with structured diagnostics.
- Add integration checks for valid annotation-free words, invalid stack use, quotation and recursion paths, and repeated elaboration yielding identical checked terms and diagnostics.
- Keep the zero-admit check passing with no `sorry`, `admit`, TODO placeholder, or unimplemented branch.

## Traceability
Satisfies PRD R3 and obligation `req-r3`.
