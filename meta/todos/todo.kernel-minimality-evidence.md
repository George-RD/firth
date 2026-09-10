---
node: firth.language.kernel
status: open
created: 2026-09-09
---

Requires: kernel-metatheory

## Goal

Give PRD R1's minimality claim checkable evidence instead of prose.
`files/firth-kernel-spec-draft.md` section 2 asserts that the kernel atoms
are minimal for v0.1; the mechanised metatheory proves determinism,
preservation, progress, linearity and cost invariance, which are safety
results, not non-derivability results.

## Acceptance criteria

- For each kernel atom, either a Lean statement that no program over the
  remaining atoms realises a named observable behaviour that the atom does,
  or an explicit dated decision naming which atoms are retained for reasons
  other than expressive power.
- Each statement is proved with zero admits, or left as a sorry-free `Prop`
  declaration that the zero-admit gate lists as an open obligation; never a
  silent assumption.
- The kernel calculus text is unchanged; no frozen rule is amended.
- Link the result to obligation `req-r1`.

## Traceability

PRD R1. The loop may not weaken R1 (dec.loop-autonomy clause 2a); only a
maintainer decision may reclassify it as design-level. Opened by the
baseline obligation audit (`meta/changes/baseline-obligation-audit/`) at
`80a9d41`.
