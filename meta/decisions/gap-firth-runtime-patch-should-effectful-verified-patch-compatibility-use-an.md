---
id: dec.gap-firth-runtime-patch-should-effectful-verified-patch-compatibility-use-an
nodes: [firth.runtime.patch]
status: proposed
date: 2026-07-16
gap: true
informed_by: [res.patch-compat-prior-art]
---

# Gap: Should effectful verified-patch compatibility use an abstract World pre-state/post-state relation, an event trace, or both to define observational refinement?

## Question

Should effectful verified-patch compatibility use an abstract World pre-state/post-state relation, an event trace, or both to define observational refinement?

## Context

Node: `firth.runtime.patch` (state: Ghost)

Pure and refinement-typed word replacement is defined by
`res.patch-compat-prior-art`. Equal erased `World` positions prove linear
threading but do not define which external actions a replacement may add,
remove or reorder.

Opened by `cairn gap firth.runtime.patch --question "Should effectful verified-patch compatibility use an abstract World pre-state/post-state relation, an event trace, or both to define observational refinement?"`.

## Status, 9 September 2026

Genuinely open and post-mvp. The frozen kernel specification (sections 7 and
9) excludes effectful-word observational refinement from v0.1 and names this
gap as its owner, so the frozen artefacts do not answer the question and the
gap stays `proposed`. It belongs to obligation `sc-s3` (PRD S3, milestone
`post-mvp`) and roadmap milestone M3; it is never selected while the `mvp`
profile is active and does not hold `loop_exhausted_valid` false. Evidence
binding for pure and refinement-typed replacements is separate work under
`patch-refinement-evidence-admission` (obligations `req-r7` and
`scope-runtime-patch`). Recorded by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`.

## Resolution

(Answer the question here, then flip `status` to `accepted` or delete this file.)
