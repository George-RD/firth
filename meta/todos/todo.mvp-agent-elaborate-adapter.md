---
node: firth.toolchain.agent
status: done
created: 2026-09-03
---

# MVP agent elaborate adapter

Requires: mvp-agent-guide diagnostic-schema elaborator-implementation

## Goal

Provide the gate-required `firth.elaborate.v1` adapter over the checked
elaborator pipeline. `tools/loop/mvp_agent_manifest.toml` pins four adapters;
`reference_run`, `compile` and `vm_run` exist, and `elaborate` is the one the
gate cannot rebuild an application without. No todo owned it, so this one is
authored as a prerequisite and appended to `todo.mvp-agent-gate`.

## Acceptance criteria

- The adapter reads one `firth.source.v1` object from stdin and prints exactly
  one `firth.elaboration.v1` object on stdout: `request_id`, `status`, and
  either `checked_words`, `erased_word_types`, `kernel_programs` and
  `warnings`, or `diagnostics`.
- `checked_words` and `erased_word_types` are byte-compatible with the
  `firth.checked-kernel.v1` request the compile adapter accepts, and
  `kernel_programs` is the artefact the reference-run request carries, so the
  gate joins adapters rather than reconstructing records.
- The manifest `[gamma]` primitives resolve, so a source using `prim +`
  elaborates instead of failing with an unresolved effect.
- Failure emits the versioned diagnostic envelopes from
  `dec.agent-diagnostic-envelope`, not a Lean representation.
- Malformed JSON, a duplicate member, an unknown member, an empty request id,
  and an unsupported language or gamma version each fail closed.

## Verification

- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability

Prerequisite for `todo.mvp-agent-gate`; implements the elaborate boundary
pinned by `dec.mvp-gate-provenance`.
