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
up to the top, named as `locals` can bind them (a repeated label gets a
number no input uses). Each declared name in the old block keeps the input it
names. The values the old block left on the stack are read as the deepest
inputs no name claims, and the body starts by pushing them. Each other name
stands for one of the remaining unclaimed inputs, and the body writes that
input's name for it. A plain reordering keeps the body. `ElaboratorDiagnosticsTest`
reads the edit out of the hint text, applies it to four fixtures (a
reordering, a fresh name, a declared name for a deeper input, a repeated
label), and requires the result to check and to compute the value worked out
by hand on sample inputs. The decision record's figures are corrected. The 67
misordered blocks in the recorded answers are all reorderings, so their hint
is unchanged.
