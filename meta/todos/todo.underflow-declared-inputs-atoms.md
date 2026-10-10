---
node: firth.toolchain.agent
status: open
created: 2026-10-10
---

# Say when a stack atom's underflow comes from a word's declared inputs

`todo.underflow-names-declared-inputs` made two kinds of underflow say how
many inputs the effect declares and how many the body takes: a `locals`
block, and a word or primitive, in a word whose effect has no row. Kernel
atoms are left out: `if`, `dip`, `call`, `swap`, `dup`, `drop`, `pick` and
`roll`. For these, erasure reports "`if` needs more values than the stack
holds here", or, for `pick` and `roll`, "ran out of values". It gives no
account of the values the atom is handed (`Account.ofShortCall` makes
none), so nothing says whether a local was meant. For example,
`: f ( -- x:Int^many y:Int^many ) swap ;` declares no inputs and its body
takes two, but the report says neither. The answers under `eval/s7/runs`
and in both harder calibration pools have 39 such reports at `if`, `dip`,
`call` or `swap`, and 8 at `pick` or `roll`.

## Acceptance criteria

- An atom that runs short of values, in a word whose effect has no row and
  with no local in scope, says how many inputs the effect declares and how
  many the body takes, as a `locals` block does.
- One with a local in scope keeps a message that does not blame the effect.
