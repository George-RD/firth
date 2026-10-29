---
node: firth.toolchain.elaborator
status: open
created: 2026-10-29
---

## Goal

Reports and lints about a word that uses records name what the author wrote,
not the `locals` blocks the elaborator emits for record operations.

## Acceptance criteria

- The `LOCAL_DEPTH` and `STACK_JUGGLE` lints are decided per written item: a
  record operation the author wrote as one item does not trigger a lint about
  locals the author did not write.
- An error in the erasure of a word with records names slots as field paths
  (`Stock.reserved`) or as the written value, never as an internal binder; a
  `dip`, `quote` or `compose` of a record whose quotation erasure cannot track
  is reported at the item the author wrote.
- Edit hints on a word that uses records are checked against the lowered word
  or withheld, as `dec.locals-input-order` requires of a hint's edit.
- Planted-bug tests show each report can fail.

## Progress

- 29 October 2026: found while adding records
  (`dec.typed-records-and-variants`). Slots are named by field paths and every
  generated item keeps the span of the item it came from, but the lints and the
  erasure's tracker still see the emitted `locals` blocks, and `quote` of a
  composite builds its quotation from atoms the tracker cannot follow
  (`firth.elaboration.untracked-local` can then name a generated slot).

## Traceability

PRD G3, S7; `dec.typed-records-and-variants`.

## Scalar types through erased pack and unpack

`pack` and `unpack` erase to nothing, so the kernel never sees a field's type.
The lowering tracks `Int` and `Bool` for literals, declared effects, primitive
results and locals, and refuses a mismatch with `firth.type.mismatch`. It does
not track the result types of calls to dictionary words (the erasure signature
has usage only), values taken from below an open stack row (`ρ -- ρ` with
`R.pack R.unpack` is accepted), or quotation results. Such a value packed into a
field of the wrong type and unpacked again in the same word is not refused.
Carry types through the erasure signature and close this.
