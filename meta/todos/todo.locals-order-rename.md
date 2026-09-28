---
node: firth.toolchain.agent
status: open
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
