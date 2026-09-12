# Proposal: mvp-agent-gate

## Motivation

`coverage.py` has listed `tools/loop/mvp_agent_gate.py` under `missing_gates`
since the `mvp-agent-authoring` row was added, and a missing pinned gate holds
`loop_exhausted_valid` false on its own. The four adapters the gate must call
now exist, so the gate is the remaining piece between the tracker and the MVP
acceptance criterion.

## Scope

- `tools/loop/mvp_agent_gate.py`: provenance verification, then an isolated
  rebuild of every manifest-listed application through all four adapters, then
  a comparison on every field `[comparison]` names.
- `tools/loop/test_mvp_agent_gate.py`: seventeen fail-closed cases over
  synthetic trees.
- A fourth application, `add-one`, with its transcript and manifest entry.

## Out of scope

- Any claim about authorship. `dec.mvp-gate-provenance` clause 4 records that
  no gate can prove a transcript was not fabricated, because the loop is
  itself a code model. The provenance half proves byte-level drift detection.
- Any change to the completion profile, the milestone tags, or the four
  adapters. The gate calls them; it does not extend them.
