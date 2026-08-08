# Design: tcb-boundary-inventory

## Approach

Keep the accepted Markdown boundary map as the human-facing rationale and
add `specs/tcb-boundary.toml` as its machine-readable companion. The
inventory has three explicit trusted components, a conditional SMT policy,
all architecture modules plus the named translator, cache, and diagnostic
subcomponents, per-output trusted revalidators, and executable evidence
stages.

`tools/loop/check_tcb_boundary.py` parses the inventory with Python's standard
`tomllib`. It rejects duplicate or missing required components, empty output
or evidence rows, unknown trusted revalidators, unclassified stages, missing
evidence paths, and any non-TCB output that is not accepted through Lean, SMT,
or VM. It also enforces the explicit conditional SMT policy.

`tools/loop/test_tcb_boundary.py` exercises the real manifest and mutates
parsed manifests to prove the checker fails closed. Existing Lean, SMT, VM,
and zero-admit gates remain the evidence stages rather than becoming trusted
helpers.

## Changes

ADDED:
- `specs/tcb-boundary.toml`, the complete TCB and artefact inventory.
- `tools/loop/check_tcb_boundary.py`, the fail-closed validator.
- `tools/loop/test_tcb_boundary.py`, adversarial checker tests.
- `meta/decisions/tcb-boundary-inventory.md`, the accepted schema decision.

MODIFIED:
- `specs/component-spec-boundaries.md`, linking the machine-readable
  companion.

REMOVED:
- None.

RENAMED:
- None.
