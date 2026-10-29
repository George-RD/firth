---
node: firth.language.types
status: open
created: 2026-10-29
---

## Goal

`R.pack` and `R.unpack` erase to nothing, so the kernel never sees a record
field's type. The lowering (`src/elaborator/Firth/Records.lean`) refuses a
scalar of the wrong type only where it knows the value's type: literals,
declared stack effects, primitive results and locals. Make it know the type of
every value, so that a `Bool` packed into an `Int` field is always refused.

## Acceptance criteria

Each program below is refused with `firth.type.mismatch` (or a stated
stable code), with a case in `src/compiler/FirthRecordsTest.lean` that fails
without the change. Today each is accepted.

- A value taken from below an open stack row: `record R { x:Int }` and
  `: f (forall ρ; ρ -- ρ) R.pack R.unpack ;`. The type of a value the word
  takes from its row is not declared, so either the word's effect must declare
  it or the lowering must refuse the pack; the decision is part of this todo.
- A result from a word defined in another file: `lib.firth` holds
  `: isb ( -- b:Bool ) true ;` and `export isb;`, and the importer has
  `record R { x:Int }` and `: f ( -- ) isb R.pack R.unpack drop ;`. The kernel
  refuses the form whose result is kept (`declared-effect-mismatch`) and the
  lowering already refuses the same word defined in the same file, so the gap is
  a call to an imported word whose result is packed and then dropped.
- A value a quotation takes from below: `record R { x:Int }` and
  `: f ( b:Bool -- ) [ R.pack drop ] call ;`. A quotation is analysed alone, so
  the value it takes is one unknown slot, and `call` does not compare it with
  the `Bool` it is run on. Accepted today.
- The accepted twins of each (an `Int` where an `Int` is wanted) stay accepted.
- `spec/surface/syntax.md` 3.1 stops listing these as untracked.

## Progress

- 29 October 2026: found in review of the first records PR. Tracked today:
  literals, declared effects, primitive results (from the typing environment,
  `Int` and `Bool` only), locals, and a quotation's scalar result
  (`: f ( -- ) [ true ] call R.pack drop ;` is refused). Not tracked: the three
  cases above. It is
  a missed refusal, not an unsoundness: the kernel still checks the erased
  program, and a mistyped value cannot cross a word boundary because the
  declared effect is flattened and checked.

## Traceability

PRD G3; `dec.typed-records-and-variants`.
