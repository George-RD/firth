---
node: firth.toolchain.agent
status: open
created: 2026-09-28
---

# Name the author's operation, not the checker's, in type errors

Found while checking the branch-mismatch fixtures from run 7
(`eval/s7/runs/2026-09-28-haiku-c6a964a/haiku-firth-2`). After the edit
each branch-mismatch report suggests, the next report is often about code
the checker wrote, not the author:

- `firth.type.quotation-compose-mismatch` names a `compose` the author
  never wrote, shows erasure's quotation effects with type variables, and
  has an empty hint. `ledger` (answer 3, false branch using the new
  balance) reaches it because `i xs prim seq-int.at` has its operands in
  the wrong order inside a branch.
- `firth.type.primitive-input-mismatch` for the same operand order shows
  the stack as `.. Int Int ?t27 ?t26 Int ?t27` (`reverse`, answer 2, with
  the extra `result` removed).
- `firth.type.stack-underflow` from erasure can name a `swap` that erasure
  inserted to reach a local.
- `firth.type.word-input-mismatch` in `main` shows types only, without the
  values' sources (4 of 20 last-round failures in run 7's sample 2).
- A branch-mismatch report whose operation is inside a quotation in the
  branch ("inside a quotation in that branch") points `at:` the outer `if`
  and does not say which inner quotation holds the operation (keep-positive
  19:5 and longest-run 23:15 in the #164 review).
- The branch account (`Account.lean`) compares values by label. In the
  branch-mismatch hint, a value a branch takes and one it leaves with the
  same label ("the result of `prim +`") count as one value put back, which
  can blame the wrong branch (the cec3707 ledger answer 1 in the #164
  review, where the hint still came out right). Giving each walk entry an
  identity, such as a counter, instead of comparing labels would fix it.
- `firth.name.locals-order` (#165) states an edit when the edited word is
  refused no earlier in the source than the word as written. That compares
  only first errors, so an edit can add an error hidden behind an earlier,
  independent one: for inputs `xs:Seq Int n:Int`,
  `locals { xs } { true prim + drop xs prim seq-int.at }` is told to start
  the body with `n`, and once `true prim + drop` is removed the body is
  refused (review of #165). Stating only edits whose word is accepted moves
  23 of the 40 recorded refusals to the fallback. The reviewer's suggestion:
  keep the edit and add "after this edit, `w` is still refused at L:C".
- `firth.name.locals-order` (#165, found by Codex after approval; fixed in
  the next PR from `main`): a bare call inside a vocabulary is resolved
  before binders are chosen, so a new binder can shadow it in the source; an
  opening block that repeats a name gets contradictory renames and hides
  `firth.name.duplicate-local`; and the edit check renames an inner block's
  own binder of a renamed name.

## Goal

Each of these reports names the operation as written and the values it
gets by their sources, as the branch-mismatch report now does, with a
hint whose edit makes the fixture check. Each case above becomes a
fixture.
