---
node: firth.language.types
status: open
created: 2026-10-13
---

## Goal

Let a quotation apply structural atoms (`dup`, `drop`, `swap`, `dip`, `quote`) to a
record, variant or sequence-of-record value that the quotation did not build,
as it can for a base type, instead of refusing the application with
`firth.type.composite-in-quotation`.

## Acceptance criteria

- A quotation such as `[ dup ]` applied to a composite value behaves as it
  does for `Int` (a quotation `[ quote ]` on a `Pair` quotes the whole pair): its recorded surface effect carries a width the checker
  resolves at the application, or the elaborator specialises the body per
  application, with a total erasure to kernel atoms.
- `call`, `dip` and `if` accept such quotations on composite stack positions,
  with the same planted-bug tests as the rest of the typed-records work.
- No kernel change; if one proves necessary, it needs its own accepted
  decision.

## Progress

- 13 October 2026: gap named in `dec.typed-records-and-variants`. Until it
  lands, authors move composite handling into a word with a typed signature
  or use `locals`.
