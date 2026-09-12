---
node: firth.toolchain.elaborator
status: open
created: 2026-09-10
---

Requires: elaborator-diagnostic-envelope

## Goal

Carry related spans on name diagnostics, as `spec/surface/syntax.md` section 2
requires: every colliding declaration behind `firth.name.duplicate-canonical`
and `firth.name.duplicate-alias`, and every candidate behind
`firth.name.ambiguous-use`, sorted by canonical key then source range.

## Why this is a todo and not a fix

The accepted envelope (`meta/decisions/agent-diagnostic-envelope.md`,
`Firth.Agent.Related` in `src/agent/Firth/Agent/DiagnosticEnvelope.lean`)
already has the `related` member, so no schema change is needed. The blocker
is the wiring: `parserEnvelope` in
`src/agent/Firth/Agent/ElaboratorDiagnostics.lean` fills `related` only from
the per-request `EmissionContext`, and that file is a frozen model-facing
input whose SHA-256 is pinned in `tools/loop/mvp_agent_manifest.toml`
(`[[inputs.interface]]`). Commit 74703e9 reverted an earlier edit to it for
exactly that reason. Attaching per-diagnostic related spans therefore needs
a deliberate, hash-updating change to a frozen input, which this review-fix
unit does not make.

## Acceptance criteria

- `ParseError` (`src/elaborator/Firth/Parser.lean`) gains an optional
  `related : List (String × Span) := []`, or name resolution gets its own
  diagnostic constructor, without changing any existing code or primary span.
- `src/elaborator/Firth/Names.lean` keeps declaration spans alongside keys:
  `checkUnique` attaches the earlier declaration's span for duplicate
  canonical names and aliases, and the ambiguous branch of `resolveWord`
  attaches every candidate's span, sorted by canonical key then range.
- `parserEnvelope` maps those entries to `Related` values with documented
  relation labels (a new relation value must be documented in the envelope
  decision before use), and the manifest interface hash is regenerated in the
  same change with the frozen-input owner's sign-off.
- `src/elaborator/FirthNamesTest.lean` asserts the related labels and spans
  for the ambiguous-use and both duplicate cases;
  `src/agent/Firth/Agent/ElaboratorDiagnosticsTest.lean` asserts the encoded
  envelope carries two candidate entries in canonical-key order; and
  `tools/loop/check_trust_boundaries.py` pins the count through the public
  `firthElaborate` binary.

## Traceability

PR #109 review thread PRRT_kwDOTaQpDM6gsCL4 (`src/elaborator/Firth/Names.lean`,
name diagnostics carry no related spans); `spec/surface/syntax.md` section 2
(name diagnostics); `meta/decisions/agent-diagnostic-envelope.md` (locations
and linkage); `meta/changes/pr109-review-fixes/`.
