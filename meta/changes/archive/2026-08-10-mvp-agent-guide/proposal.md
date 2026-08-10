# Proposal: mvp-agent-guide

## Motivation

An agent currently has to reconstruct the language contract from separate
specifications and Lean structures. That is not a valid MVP input boundary:
an application author must receive one self-contained guide and one
machine-readable interface inventory.

## Scope

- Add `docs/firth-agent-guide.md`, a standalone Firth v0.1 authoring guide
  covering the source grammar, stack effects, quotations, ownership,
  refinements, diagnostics, elaboration, compilation, VM execution, and
  worked applications.
- Add `tools/loop/mvp_agent_manifest.toml`, the versioned machine-facing
  interface and provenance-manifest envelope. This unit defines the guide and
  interface inputs, entry-point schemas, and deterministic application
  inventory shape that the later example and gate units will populate.
- Add `tools/loop/check_mvp_agent_inputs.py`, a deterministic preflight that
  validates the guide and interface sections before any application is
  presented to the MVP gate.
- Record the path and schema choice in `dec.mvp-agent-guide`.

## Out of scope

- The three model-authored applications and their transcripts.
- The executable `tools/loop/mvp_agent_gate.py`.
- Coverage wiring, compiler construction, VM adapters, and changes to the
  immutable completion profile.
