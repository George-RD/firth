---
node: firth.toolchain.agent
status: done
created: 2026-09-28
---

# The locals-order hint can suggest a block that leaves a name unresolved

Found by Codex on #161 (review comment on
`src/agent/Firth/Agent/ElaboratorDiagnostics.lean`). The
`firth.name.locals-order` hint suggests replacing a misordered opening block
with the stack effect's input names. When the block binds only some of the
inputs, the body can still use a name the suggestion drops: for inputs `a b`,
`locals { a } { drop a }` gets the suggestion `locals { b }`, and applying it
leaves `a` unresolved (the refused case is in `src/elaborator/FirthNamesTest.lean`).
Repeated input names in the stack effect could likewise make it suggest
duplicate binders.

## Goal

Every block the hint suggests makes its fixture check, or the hint says
what else must change (renaming the body's uses). The `a b` case and a
repeated-name case become diagnostic fixtures whose suggested edit is
applied and checked.

Also owed to `meta/decisions/locals-input-order.md` (#161 review): "29 of
the 33" should read 29 of 34; 640 and 129 should read 743 and 216 (or say
what the 640 covers); the `2026-09-28-mvp` line should say the rule refuses
none of those answers.

## Resolution

The suggested block binds the inputs from the deepest one the old block names
up to the top, named as `locals` can bind them. A repeated label, or one the
body already uses for a word or a local, gets a number nothing else uses.
Each declared name in the old block keeps the input it names. The values the
old block left on the stack are read as the deepest inputs no name claims,
and the body starts by pushing them. Each other name stands for one of the
remaining unclaimed inputs, and the body writes that input's name for it. A
plain reordering keeps the body.

The pipeline applies each edit to the word and checks it before stating it.
An edit that makes an accepted word refused, or brings a refusal earlier in
the source, is not stated, and the report says only that the body must be
rewritten for the names it binds. It says the same when an inner `locals`
block binds a name to rename again, and a block that repeats a name is left
to `firth.name.duplicate-local`. Binders avoid the body's names as written,
before vocabulary names are resolved. Of the 40 recorded refusals, 39 state their
edit. The other (`count-below`, whose `main` body was written for the names
as bound) falls back.

`ElaboratorDiagnosticsTest` reads the edit out of the hint text for seven
fixtures: a reordering, a fresh name, a declared name for a deeper input, a
repeated label, an input label that names a word the body calls (once in a
rename, once in a prelude), and an edit beside another word's error. It
applies the edit and requires the result to check and to compute a value
worked out by hand on sample inputs. Three cases whose edit would be refused
must take the fallback. The decision record's figures are corrected.
