# Design: elaborator-refinement-discharge

## Approach

Keep the SMT module independent of elaborator internals.  It defines only the
provisional typed backend IR, exact canonical request material, fragment
classification, conservative external outcomes, and countermodel validation.
The elaborator module owns refined stacks, specifications, typing-premise to VC
generation, the proved direct Lean procedure, evidence and escalation records,
and agent diagnostics.

The current unit deliberately stops at a queue boundary.  The architecture
requires Lean-checked translation soundness and a pinned solver profile before
an `unsat` result is eligible.  Since neither is selected by the accepted
decision, every non-Lean obligation remains open in the Lean queue.  Eligible
QF_LIA obligations also enter an exact typed SMT queue for a later checked
adapter.  No public value can manufacture an SMT success record.

The direct procedure evaluates only closed formulae and its Lean theorem lifts
those results to validity under every valuation.  Lean proof records can be
rechecked by regenerating the exact obligation and rerunning that proved
decision.  Replacement checks enforce exact erased `WordType` equality before
generating the specified precondition, postcondition, and totality VCs.

Queued SMT entries retain the complete typed obligation and use a length-framed
canonical request binding the body, word type, specification, transitive callee
contracts, predicate definitions, normaliser, VC generator, proof/toolchain
identity, and formula.  External non-success handling consumes only an eligible
queue entry.  It cannot create proof evidence; a validated `sat` countermodel
creates a failed diagnostic with deterministic model data, while every other
outcome remains deferred to Lean.

## Changes

ADDED:
- `src/smt/Firth/SmtBoundary.lean`, the dependency-free backend boundary.
- `src/elaborator/Firth/Refinement.lean`, elaborator integration and discharge.
- `src/elaborator/FirthRefinementTest.lean`, mutation-resistant regression tests.

MODIFIED:
- Lake targets and the aggregate test driver.
- The elaborator library root imports.

REMOVED:
- The rejected monolithic refinement module and its unsafe unchecked SMT
  acceptance path.

RENAMED:
- The refinement test moves from the SMT namespace to the elaborator namespace
  to preserve the declared `elaborator -> smt` dependency direction.
