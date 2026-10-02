---
node: firth.toolchain.agent
status: open
created: 2026-09-30
---

# S7 baseline: the same tasks in Firth and Python

Full S7 needs the same tasks in a mainstream language as the baseline
(`docs/roadmap.md`, "S7 baseline"). Runs 1 to 4 scored Python and it was at the ceiling each time (22/22, 9/9,
20/20, `eval/s7/README.md`); runs 5 to 13 are Firth only. On the latest
Python run (run 4, the MVP tier) both Sonnet and Haiku got 20 of 20, so
those tasks cannot tell the two languages apart.

## Acceptance criteria

- A task set harder than the MVP tier (`todo.s7-harder-task-tier`), written
  before any trial, given in both languages with the same subject model.
- Correct on the first attempt and correct within two attempts, per
  language, with retained transcripts naming the model and date. Each is
  measured over several independent samples per task and language, with the
  number and the comparison rule declared before any trial. One sample per
  task does not discharge this (`eval/s7/README.md`, run 4 caveats).
- A plain list of what Firth's checker gives that Python does not (checked
  types, stack effects, linear ownership, declared effects; a measured cost
  per run by the runner, not the checker, and a proved cost bound only
  where a Lean proof exists), and for
  each one whether the run showed it catching a real error.
- S7 is judged as written: a materially higher Firth pass rate on
  equivalent tasks. Parity with Python plus guarantees is reported but is
  not a pass.
- A stated answer to whether Firth is worth reaching for over Python for
  agent-written code a host runs unread. A loss is an acceptable result.
