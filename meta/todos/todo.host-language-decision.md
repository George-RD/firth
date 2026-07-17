---
node: firth.runtime.vm
status: done
created: 2026-07-16
---


## Goal
Ratify or supersede the proposed host-language decision.

## Acceptance criteria
- Validate the proposed VM, compiler, diffharness, and LSP hosts against the research note.
- Record an accepted decision or an explicit superseding decision before any `src/` implementation todo depends on it.
- Keep the gate blocking implementation-phase todos; leave spec-phase todos actionable once this decision is recorded.

## Traceability
Serves G5, G6, G8 and requirements R6, R8, R10; enables S3 and S6.

Resolved by accepted decision `dec.host-languages`; this todo is complete and unblocks the VM target specification.
