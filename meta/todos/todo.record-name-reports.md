---
node: firth.toolchain.elaborator
status: open
created: 2026-10-30
---

## Goal

A name clash that involves a record is reported once, at the record or the
alias the author wrote, in the author's terms. Two reports were wrong and one alias check refuses too much.

## Acceptance criteria

Each program below gets the stated report, with a case in
`src/compiler/FirthImportsTest.lean` or `src/compiler/FirthRecordsTest.lean`
that fails without the change.

- **A record declared in two files.** `lib.firth` holds
  `export flat; record R { x:Int } : flat ... ;` and the importer declares its
  own `record R { x:Int }`. It is refused (generated keys are reserved against
  imported declarations) but with five reports (`R.unpack`, `R.pack`, `R`,
  `R.set-x`, `R.x`), each "`R.unpack` is also defined in `lib.firth`", and a
  hint that suggests renaming a word or a key `name.R.unpack`. Report once, at
  the record, naming it as a record in both files, with a hint that renames the
  record or puts it in a vocabulary.
- **An ambiguous type name.** `vocab inv { record R { y:Int } }`,
  `vocab other { record R { z:Int } }`, `use inv; use other;` and
  `: f (forall ρ; ρ r:R -- ρ n:Int) R.y ;` is reported as
  `firth.type.unknown-type` ("`R` in the stack effect of `f` is not a type").
  `R` is a type and is ambiguous: report `firth.name.ambiguous-use`, as for words.
- **An alias refused for a record it cannot see.** The bare-name check in
  `badUse` (`Names.lean`) compares the alias with the last segment of every
  record key in the file. `vocab other { record R { x:Int } }` beside
  `vocab app { use helper as R; ... }` therefore refuses a valid program,
  because `app` cannot see `other.R`. Check only the records visible from the
  alias's scope. Add an accepted case beside the refused ones in
  `FirthRecordsTest.lean`. Over-refusal, not unsoundness; found by CodeRabbit
  on dc98102.

## Progress

- 30 October 2026: found in review of the first records PR, which refuses each
  program correctly but reports it wrongly. Not an unsoundness: nothing is
  accepted that should be refused.

## Traceability

PRD G3, S7; `dec.typed-records-and-variants`.
