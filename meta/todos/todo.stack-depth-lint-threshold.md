---
node: firth.language.surface
status: open
created: 2026-09-09
---

Requires: elaborator-named-local-erasure

## Goal

Make the `LOCAL_DEPTH` and `STACK_JUGGLE` lint threshold an explicit,
validated input of the public elaboration interface, with the specification
value as the default. PRD R14 requires a configurable threshold;
`spec/surface/syntax.md` section 5.1 fixes "more than four" and
`src/elaborator/Firth/Erasure.lean` hard-codes `> 4` for both codes.
Neither `erase`, `PipelineConfig` nor the `firth.source.v1` request carries a
threshold at `80a9d41`.

## Acceptance criteria

- Add a threshold parameter to the public elaboration interface with the
  specification's value as the default; out-of-range values are structured
  validation failures, not silent clamps.
- Existing lint tests pass unchanged at the default; add tests at one lower
  and one higher threshold showing the warning set moves with the threshold.
- Named locals remain the proposed fix carried by the warning; erasure output
  and checked kernel terms are unchanged at every threshold.
- Update `spec/surface/syntax.md` and the agent documentation together so the
  default and the range are stated once.

## Traceability

PRD R14; obligation `req-r14`. Opened by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`.
