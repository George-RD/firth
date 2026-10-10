---
node: firth.toolchain.agent
status: open
created: 2026-10-10
---

# Say when an `if` or `dip` underflow comes from a word's declared inputs

`todo.underflow-names-declared-inputs` made a `locals` block, or a word or
primitive, that runs short of values in a word whose effect has no row say
how many inputs the effect declares and how many the body takes. `if` and
`dip` are left out: erasure reports them as "`if` needs more values than the
stack holds here" with no account of the values they are handed, so there is
nothing to say whether a local was meant. The answers under `eval/s7/runs`
and in both harder calibration pools have 23 such `if` reports and 13 `dip`
ones.

## Acceptance criteria

- An `if` or `dip` that runs short of values, in a word whose effect has no
  row and with no local in scope, says how many inputs the effect declares
  and how many the body takes, as a `locals` block does.
- One with a local in scope keeps a message that does not blame the effect.
