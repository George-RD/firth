---
id: dec.tcb-boundary-inventory
nodes:
  - firth.language.kernel
  - firth.ecosystem.specs
  - firth.governance.loop
status: accepted
date: 2026-08-08
informed_by:
  - res.firth-prd.summary
  - res.firth-kernel-spec.summary
---
# Machine-readable trusted computing-base boundary

## Context

The accepted component boundary map in `specs/component-spec-boundaries.md`
was complete as human-facing rationale but did not mechanically enumerate
planned components, subcomponents, emitted artefacts, or their revalidators.
That left caches, translators, diagnostic views, and ecosystem components
open to accidental acceptance without evidence from a trusted boundary.

Autonomous author: loop/todo.req-r8.

## Decision

Adopt `specs/tcb-boundary.toml` as the machine-readable companion to the
accepted component boundary map. Its schema has three explicit trusted
component identifiers: `lean-kernel`, conditional `smt-solver`, and `vm`.
Every architecture module and every named translator, cache, harness, and
diagnostic subcomponent has a row. Every emitted artefact names one or more
trusted revalidators and one or more evidence stages. A non-TCB row cannot
have an empty revalidator or evidence set, and cannot name a checker outside
the three trusted identifiers.

The SMT solver is included only for the recorded conditional policy: a pinned
approved profile returns `unsat`, the input and result are content-addressed,
Lean checks the translation-soundness bridge, and the record is regenerated
and rechecked. `sat`, `unknown`, timeout, malformed, and unsupported results
are never trusted.

`tools/loop/check_tcb_boundary.py` validates the schema, component coverage,
trusted revalidators, stage classification, evidence paths, and SMT policy.
It is a checking helper, not a trusted component. Existing Lean, SMT, VM, and
zero-admit gates remain the evidence and are not weakened or replaced.

## Rationale

A declarative inventory makes omission and producer-only acceptance visible to
both the development loop and CI. Keeping trusted identifiers separate from
architecture modules prevents the VM implementation and Lean host tooling from
being confused with the semantic artefacts they validate. A conditional SMT
row preserves the existing refinement-discharge decision without treating
arbitrary solver output as trusted.

The existing `tools/loop/check_kernel_fixtures.sh` gate invokes the boundary
checker and its adversarial test suite before comparing the committed
Lean-generated corpus, so the normal fixture and landing paths cannot skip
inventory validation.

## Consequences

- The Markdown boundary map remains the human-facing normative explanation.
- New components or emitted artefacts must update the inventory and pass its
  validator in the same change.
- The inventory does not implement planned components or alter the frozen
  kernel calculus.
