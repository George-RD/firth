---
node: firth.runtime.vm
status: blocked
created: 2026-07-16
---


## Goal
Ratify or supersede the proposed host-language decision.

## Acceptance criteria
- Validate the proposed VM, compiler, diffharness, and LSP hosts against the research note.
- Record an accepted decision or an explicit superseding decision before any `src/` implementation todo depends on it.
- Keep the gate blocking implementation-phase todos, not spec-phase todos.

## Traceability
Serves G5, G6, G8 and requirements R6, R8, R10; enables S3 and S6.

Maintainer-blocked: ratification of dec.host-languages is a taste call; the loop skips blocked todos without Requires
