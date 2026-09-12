# Proposal: smt-adapter-integration

## Motivation

`todo.smt-adapter-integration` is the parent of the external SMT slice. Its
eight prerequisites have landed: the pinned solver, the checked adapter, the
translation proofs, bounded invocation, discharge records with their recheck
and rerun, and both coverage units.

Closing it means checking its criteria against what landed rather than against
what the children claimed, and one criterion was not met by any child: §3
requires the proof hashes of five translation stages in every request and
record, and only three were bound.

## Scope

- Extend `tools/loop/update_smt_proof_bindings.py` to hash marked regions in
  `src/elaborator/Firth/Refinement.lean` as well, so the normaliser and the VC
  generator are bound alongside the encoder, the serialiser and the adapter
  bridge.
- Mark those regions, and move `normaliseFormula` beside the other normaliser
  definitions so one region covers the rule set.
- Assert the binding set in `firthRecordIntegrityTest`.

## Out of scope

- Any change to the adapter, the records or the coverage. Everything else the
  parent's criteria ask for was already landed by a child unit and was verified
  against the tree rather than taken on trust.
