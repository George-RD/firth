---
node: firth.language.types
status: open
created: 2026-10-13
---

## Goal

Allow a `Seq` of records that hold sequences (and so `Seq (Seq Int)`), and a
`Seq` of a variant with a non-scalar payload (for example
`variant V { none some:Seq Int }`), which the typed-records design cannot erase
to the current flat columns.

## Acceptance criteria

- A record with a `Seq Int` field can be the element type of a `Seq`, with
  construction, indexing, update and length checked and erased.
- A variant whose payload holds a `Seq` can be the element type of a `Seq`
  with the same operations; today `Seq V` is refused because `V` is not
  scalar-flat.
- The representation is chosen in an accepted decision. `dec.typed-records-and-variants`
  notes that it needs a `Γ` change, so it needs the maintainer (AGENTS.md
  rule 7) before any build.
- Planted-bug tests cover the new representation, and the VM and reference
  interpreter agree on every example.

## Progress

- 13 October 2026: gap named in `dec.typed-records-and-variants`. Until it
  lands, a program that needs it is blocked on this todo; the design rejects
  the stride encoding because it loses names and checking.
