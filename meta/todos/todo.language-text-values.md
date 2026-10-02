---
node: firth.language.types
status: open
created: 2026-10-02
---

## Goal

Firth has no string, character or byte values. A program that has to read or
compare text cannot be written in Firth, so that work falls to the host.

The inventory allocator hits this. The spec gives JSON and ID syntax to the
host, and the per-ID encoding (each ID as four base-65 Ints) exists only so
that a Firth program can compare IDs. `todo.inventory-host-proof` proved that
encoding in Lean and runs it from Lean (`src/proofs/Inventory/Host.lean`),
because moving it into Firth needed text values. With text values, the
component could take the ID strings themselves and the encoding would go.

## Acceptance criteria

- A text type (or a byte sequence with the operations text needs: length,
  indexing, equality) in the kernel's value set and the surface language,
  with its typing rules, reference semantics, VM support and costs, under the
  kernel-change rule (`AGENTS.md` rule 7).
- The inventory allocator takes ID strings, with the duplicate-ID proof
  stated on them, and the host's encoding removed.

## Traceability

Found by `todo.inventory-host-proof` (2 October 2026).
