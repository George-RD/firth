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
- A call result: a word imported from another file whose effect leaves
  `b:Bool`, packed into an `Int` field.
- A quotation result: a `Bool` built by a quotation, run with `call` or `dip`,
  then packed into an `Int` field.
- The accepted twins of each (an `Int` where an `Int` is wanted) stay accepted.
- `spec/surface/syntax.md` 3.1 stops listing these as untracked.

## Progress

- 29 October 2026: found in review of the first records PR. Tracked today:
  literals, declared effects, primitive results (from the typing environment,
  `Int` and `Bool` only) and locals. Not tracked: the three cases above. It is
  a missed refusal, not an unsoundness: the kernel still checks the erased
  program, and a mistyped value cannot cross a word boundary because the
  declared effect is flattened and checked.

## Traceability

PRD G3; `dec.typed-records-and-variants`.
