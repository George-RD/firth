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

## Resolution

(Answer the question here, then flip `status` to `accepted` or delete this file.)
