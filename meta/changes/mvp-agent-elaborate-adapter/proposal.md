# Proposal: mvp-agent-elaborate-adapter

## Motivation

`tools/loop/mvp_agent_manifest.toml` pins four adapters. Three now exist. The
fourth, `elaborate`, had no owner: `todo.mvp-agent-gate` required the guide,
the examples and the compile, reference and VM adapters, but nothing required
an executable that turns source into a checked-kernel record.

The `firth` CLI prints `repr (CheckedProgram)`, a Lean pretty-print whose
width depends on the formatter, and its failure path throws an uncaught
exception. The manifest says so itself. It also passes no environments, so
`prim +` fails with an unresolved effect even though the manifest's `[gamma]`
declares the primitive.

Scope rerouted rather than expanded: this todo was authored as a prerequisite
and appended to `todo.mvp-agent-gate`'s `Requires`.

## Scope

- The `firth.elaborate.v1` adapter and its `firthElaborate` executable.
- Resolving the manifest's `[gamma]` primitives into the elaborator's erasure
  and typing environments.
- Emitting failures as the versioned diagnostic envelopes that
  `Firth.Agent.elaboratePipeline` already produces but no executable reached.

## Out of scope

- Any change to elaboration, checking, or the diagnostic envelope schema. The
  three manifest-pinned interface files are untouched, so their hashes stand.
- The `firth` CLI, which keeps its Lean-representation output as a developer
  convenience.
- The refinement predicates the manifest declares. They belong to the
  refinement surface, not to the stack vocabulary this adapter resolves.
