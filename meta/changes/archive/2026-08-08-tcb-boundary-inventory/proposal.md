# Proposal: tcb-boundary-inventory

# Problem

The accepted component boundary map is human-readable, but it does not give
the loop or CI a complete inventory to validate. Components such as caches,
translators, standard library, language server, runtime image, and
specification tooling can therefore be added without a machine-checkable
statement of which trusted boundary revalidates their outputs.

## Motivation

Keep the trusted computing base limited to the Lean kernel, the approved SMT
solver when its strict conditions hold, and the VM. Make omissions and
unvalidated outputs fail in an automated boundary check.

## Scope

- Add a versioned TOML inventory covering every architecture component and
  named non-TCB subcomponent in the R8 acceptance criteria.
- Record each emitted artefact, its trusted revalidator, evidence gate, and
  the conditional SMT trust policy.
- Add a dependency-free Python checker and adversarial tests for missing,
  unknown, and improperly trusted entries.
- Link the machine-readable inventory from the accepted component boundary
  specification.

## Out of scope

- Changing the frozen kernel calculus or its Lean mechanisation.
- Adding a trusted helper, changing solver profiles, or implementing planned
  compiler, cache, runtime image, patch, standard-library, or LSP modules.
- Replacing existing Lean, SMT, VM, Cairn, or loop acceptance gates.
