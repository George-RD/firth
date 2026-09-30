---
node: firth.toolchain.agent
status: open
created: 2026-09-30
---

# S7 baseline: the same tasks in Firth and Python

Full S7 needs the same tasks in a mainstream language as the baseline
(`docs/roadmap.md`, "S7 baseline"). Nearly every run compares Firth with
Firth. Python has only been scored on the 20 MVP tasks (run-4 table,
`eval/s7/README.md`), where both Sonnet
and Haiku got 20 of 20, so those tasks cannot tell the two languages apart.

## Acceptance criteria

- A task set harder than the MVP tier (`todo.s7-harder-task-tier`), written
  before any trial, given in both languages with the same subject model.
- Correct on the first attempt and correct within two attempts, per
  language, with retained transcripts naming the model and date.
- A plain list of what Firth's checker gives that Python does not (proved
  types, stack effect, linearity, cost bound, declared effects), and for
  each one whether the run showed it catching a real error.
- S7 is judged as written: a materially higher Firth pass rate on
  equivalent tasks. Parity with Python plus guarantees is reported but is
  not a pass.
- A stated answer to whether Firth is worth reaching for over Python for
  agent-written code a host runs unread. A loss is an acceptable result.
