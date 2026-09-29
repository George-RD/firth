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
