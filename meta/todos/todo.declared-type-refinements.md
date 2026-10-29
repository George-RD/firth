---
node: firth.language.types
status: open
created: 2026-10-13
---

## Goal

Give a refinement on a stack item of a declared record or variant type
(`r:Request{ valid r }`), or on a `Seq` of one (`xs:Seq Request{ valid xs }`), a meaning, so a word boundary can state a predicate
over a whole record.

## Acceptance criteria

- An accepted decision defines how the predicate names the record and its
  fields, how the proof obligation is stated over the flat slots, and how
  the checker discharges it.
- Until then the checker refuses such a refinement with
  `firth.syntax.refinement-in-type`; the implementation keeps that refusal
  and tests it.
- No kernel change; if one proves necessary, it needs its own accepted
  decision.

## Progress

- 13 October 2026: gap named in `dec.typed-records-and-variants`. Until it
  lands, a program that needs a predicate over a whole declared record at a
  word boundary is blocked on this todo.
