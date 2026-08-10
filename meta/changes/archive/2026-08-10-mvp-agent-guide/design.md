# Design: mvp-agent-guide

## Approach

Keep the model input boundary explicit and content-addressable:

1. The guide is a self-contained Markdown document. It defines the language
   contract in operational terms and includes small source examples.
2. The pinned TOML manifest is both the machine-facing interface inventory and
   the future provenance envelope. Its `[inputs]` section names exactly the
   guide and interface bytes, while `[entry_point.*]` sections define versioned
   request and response shapes for elaboration, compilation, reference
   execution, and VM execution.
3. The input checker parses TOML with the standard library, resolves only the
   declared paths, checks required guide sections and entry-point fields, and
   emits stable JSON with SHA-256 values. It does not build or execute an
   application.

The manifest deliberately records adapters as named entry points rather than
inventing host commands that do not yet exist. The later gate supplies those
adapters and must fail closed when an adapter is unavailable.

## Changes

ADDED:
- `docs/firth-agent-guide.md`
- `tools/loop/mvp_agent_manifest.toml`
- `tools/loop/check_mvp_agent_inputs.py`
- `meta/decisions/mvp-agent-guide.md`

MODIFIED:
- `meta/changes/mvp-agent-guide/proposal.md`
- `meta/changes/mvp-agent-guide/design.md`
- `meta/changes/mvp-agent-guide/tasks.md`

REMOVED:
- None.

RENAMED:
- None.
