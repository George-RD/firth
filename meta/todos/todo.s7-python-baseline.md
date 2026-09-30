---
node: firth.toolchain.agent
status: open
created: 2026-09-30
---

# S7 baseline: the same tasks in Firth and Python

Full S7 needs the same tasks in a mainstream language as the baseline
(`docs/roadmap.md`, "S7 baseline"). Every run so far compares Firth with
Firth. Python has only been scored on the 20 MVP tasks, where both Sonnet
and Haiku got 20 of 20, so those tasks cannot tell the two languages apart.

## Acceptance criteria

- A task set harder than the MVP tier (`todo.s7-harder-task-tier`), written
  before any trial, given in both languages with the same subject model.
- Correct on the first attempt and correct within two attempts, per
  language, with retained transcripts naming the model and date.
- A plain list of what Firth's checker gives that Python does not (proved
  types, stack effect, linearity, cost bound, declared effects), and for
  each one whether the run showed it catching a real error.
- A stated answer to whether Firth is worth reaching for over Python for
  agent-written code a host runs unread. A loss is an acceptable result.
