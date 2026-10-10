---
node: firth.toolchain.agent
status: open
created: 2026-09-29
---

# Say when an underflow comes from a word's declared inputs

Found by S7 run 8 (`eval/s7/README.md`, "Run 8"). In sample 2's round-1
and round-2 answers every `firth.type.stack-underflow` (15, then 9) is a
`main` declared with no inputs, `( -- result:Int^many)`, whose body opens
with `locals { xs } { ... }`
(`eval/s7/runs/2026-09-29-haiku-4c379e0/haiku-firth-2/`). The feedback
points at `xs` and says only

```
code: firth.type.stack-underflow
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.
```

It does not say that the word's stack effect declares no inputs, which is
the mistake. 8 of the 15 failed the same way in the next round, and
sample 2's own summary put the failure down to the elaborator ("cannot
reliably handle multiple locals value references").

## Acceptance criteria

- When a `locals` block or operation underflows and the word's stack
  effect declares fewer inputs than it takes, the diagnostic says how many
  inputs the effect declares and how many the code takes, checked on the
  15 round-1 answers above.
- An underflow in a word whose effect declares enough inputs keeps a
  message that does not blame the effect.

## Progress

A `locals` block that names more values than are on the stack, with no
unused local on it, in a word whose stack effect has no row, now says how
many inputs the effect declares and how many the body takes. For sample 2's
`seq-sum`: "`locals { xs }` in `main` names 1 value, but no value is on the
stack before it. `main` declares no inputs, but its body takes 1 input." A
primitive, or a call to a word whose own effect has a row, handed fewer
values than it takes with no local in scope, gets the same sentence. The count is found by checking the word again with
that many more inputs declared, and says "at least" when the body is then
refused for something else first. All 15 round-1 answers get it
(`runDeclaredInputsTests` has `seq-sum` verbatim). An underflow where an
unused local is on the stack, where a local is in scope at the operation, or
in a word whose effect has a row, keeps its message.

Still open, so this todo stays open. Erasure gives no account of the values
handed to a kernel atom (`if`, `dip`, `call`, `swap`, `dup`, `drop`, `pick`,
`roll`) or to a call to a word whose own effect has no row
(`Account.ofShortCall` makes none), so nothing says whether a local was
meant, and these keep the generic report. For example,
`: f ( -- x:Int^many y:Int^many ) swap ;` declares no inputs and its body
takes two, and with `: g ( a:Int^many b:Int^many -- r:Int^many ) prim + ;`,
`: f ( -- r:Int^many ) 1 g ;` takes one; neither report says so. The answers
under `eval/s7/runs` and in both harder calibration pools have 39 such
reports at `if`, `dip`, `call` or `swap`, and 8 at `pick` or `roll`. A word
whose effect has a row is a separate gap (`todo.locals-binds-row`).
