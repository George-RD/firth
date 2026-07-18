# Design: elaborator-stack-effect-review-fixes

## Approach

Snapshot the incoming stack once when dispatching an atom. Keep that diagnostic
snapshot separate from the source stack consumed by each pop, so later pops in
swap, dip, compose, and if cannot replace it with a partial stack. Other error
payload fields continue to use the substitution state at the actual failure.

Exercise quotation usage meet through composed quotations with many and linear
captures. In addition to checking all three linear truth-table cases directly,
drop a composed quotation whose meet must be linear. Replacing meet with many
would make that negative test pass and therefore fail the suite.

## Changes

ADDED:
- Mutation-resistant regression cases in `src/elaborator/FirthStackEffectTest.lean`.

MODIFIED:
- `src/elaborator/Firth/StackEffect.lean`
- `src/elaborator/FirthStackEffectTest.lean`

REMOVED:
- None.

RENAMED:
- None.
