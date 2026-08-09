# Design: decidable-stack-effect-elaboration

## Approach

Keep `Firth.Elaborator.elaborateWith` as the sole pure stage-ordered
boundary. Add end-to-end fixtures at that boundary rather than introducing
another checker or source representation. Exercise quotations through `if`,
assert the typed branch mismatch, and compare repeated failing results using
the existing `BEq` instances for structured diagnostics.

Typed holes remain an adapter-level R13 concern: `StackEffect.typedHole`
reports inferred state and `Firth.Agent.encodeTypedHole` emits the structured
payload. Add an integration assertion that derives a hole from inference and
validates that payload. This unit does not invent source syntax that would
expand the obligation.


## Changes

ADDED:
- Integration assertions for quotation branch inference and deterministic
  stack-effect failure diagnostics.

MODIFIED:
- `src/elaborator/FirthPipelineTest.lean` coverage for the existing pipeline
  contract.
- `src/agent/Firth/Agent/ElaboratorDiagnosticsTest.lean` coverage for the
  inferred typed-hole envelope contract.

REMOVED:
- None.

RENAMED:
- None.
