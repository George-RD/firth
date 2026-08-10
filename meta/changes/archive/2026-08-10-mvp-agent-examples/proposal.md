# Proposal: mvp-agent-examples

## Motivation

The MVP acceptance profile needs concrete applications authored through the
agent-facing guide, not only a guide and interface contract. Without a small
checked-in corpus, the later executable gate cannot demonstrate that an agent
can take the published input boundary through elaboration, compilation, and
execution while preserving provenance.

## Scope

- Add three portable Firth application sources under a blueprint-covered
  agent-example path.
- Add one auditable authoring transcript source artefact per application.
- Record each source path, source digest, transcript path, and transcript
  output digest in `tools/loop/mvp_agent_manifest.toml`.
- Record the path decision required by the blueprint extension.

## Out of scope

- The executable `tools/loop/mvp_agent_gate.py`.
- Compiler, reference-interpreter, VM, or adapter construction.
- Changes to the immutable completion profile or the agent-facing guide.
