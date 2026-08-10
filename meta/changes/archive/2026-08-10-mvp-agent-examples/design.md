# Design: mvp-agent-examples

## Approach

Use three closed, deterministic applications that exercise literals,
quotations, and conditional control without relying on an adapter that is
outside this unit. Each source stays within the syntax and value profile
provided by `docs/firth-agent-guide.md`.

The manifest records the exact application and transcript bytes. Each
transcript lists only the guide, the checked-in agent interface, and the task
as model context, then records the application source as model output and
its SHA-256. The later gate can therefore reject stale or hand-edited corpus
entries before executing them.

The new `examples/mvp` path belongs to the agent interface module because the
files are executable inputs to that interface, rather than documentation or
runtime implementation. The path and its provenance decision land together.

## Changes

ADDED:
- `examples/mvp/literal-int.firth`
- `examples/mvp/quotation-call.firth`
- `examples/mvp/conditional.firth`
- Three `meta/sources/mvp-agent-example-*.md` transcript artefacts.
- `meta/decisions/mvp-agent-examples.md`.

MODIFIED:
- `cairn.blueprint` adds `examples/mvp` to `firth.toolchain.agent`.
- `tools/loop/mvp_agent_manifest.toml` records the three applications and
  provenance digests.
- `meta/changes/mvp-agent-examples/tasks.md` records completed work.

REMOVED:
- None.

RENAMED:
- None.
