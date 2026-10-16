---
node: firth.toolchain.agent
status: open
created: 2026-10-12
---

# Give a column where a report names a place by its line alone

Found while reviewing #255, which names the quotation holding a nested
operation by line and column ("the true branch of the `if` at line 72,
column 39"), because S7 answers often write a whole branch on one line and
a line alone can name several `if`s (is-sorted,
`eval/s7/runs/2026-09-29-locals-guide/arm-a/haiku-firth-9/solutions-3.json`,
has three on line 9). Two reports on main still name a place by its line
alone, in `src/agent/Firth/Agent/ElaboratorDiagnostics.lean`:

- `firth.syntax.definition-ended-early`: "up to the `]` on line N" (the
  three `closedBy` hints). A line can hold several `]` or `}`, so the
  reader cannot tell which one closes everything.
- `firth.elaboration.untracked-local`: "used after `call` on line N".
  A line can hold several `call`, `dip` or `if` atoms.

Checked edits already give a column when the text they replace is found
more than once on their lines (`editPlace`).

## Acceptance criteria

- Each of these reports names its place so that only one bracket or atom
  fits, for example by line and column, with a case whose line holds two
  candidates.
- The line-only wording is planted in each case and fails it.
