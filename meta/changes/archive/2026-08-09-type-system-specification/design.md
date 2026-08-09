# Design: type-system-specification

The new specification is a companion to the frozen kernel draft. It keeps the
kernel's prenex rows, two usage modes, quotation effects, and ownership
transfers as the erased target. Surface names and refinements are elaborator
metadata. A syntax-directed algorithm assigns fresh row variables, solves
first-order row equations with an occurs check, and generalises only at
dictionary word boundaries. Quotation literals are monomorphic at their use
site, so no local higher-rank inference is introduced.

Typing records obligations rather than guessing unsupported facts. Refinements
are checked against the already accepted specification-predicate contract,
normalised deterministically, and erased after their obligations are recorded.
The document uses the frozen kernel rules as the conformance oracle and states
the Lean lemmas needed for algorithmic soundness, ownership preservation,
deterministic diagnostics, and refinement erasure.

## Changes

ADDED:
- `spec/types/type-system.md`: normative v0.1 surface stack-effect,
  inference, linearity, quotation, callback, refinement, diagnostics, examples,
  and Lean-obligation specification.
- `meta/decisions/type-system-specification.md`: accepted decision pairing the
  normative specification with its prior-art and predicate-contract inputs.

MODIFIED:
- `meta/todos/todo.type-system.md`: mark the selected unit done after the
  specification and gates pass.

REMOVED:
- None.

RENAMED:
- None.
