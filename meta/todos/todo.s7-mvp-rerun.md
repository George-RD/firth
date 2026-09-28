---
node: firth.toolchain.agent
status: open
created: 2026-09-28
---

# Re-run the S7 MVP set after the diagnostic fixes

Carried over from `todo.s7-untracked-local-misreport`. Run 5 measured the
unresolved-name hint (#142) but ran before the branch-mismatch fix (#145),
so nothing yet measures whether reporting the mismatch at the `if` helps
an author repair it.

## Acceptance criteria

- A separate scored run of the 20 MVP tasks on a main that has #145 (and
  #148 if it has merged), recorded under `eval/s7/runs/` and in
  `eval/s7/README.md`, with the same sub-agent method and transcript audit
  as run 5.
- The run reports how many last-round failures are still
  `firth.elaboration.untracked-local` and whether branch-mismatch
  diagnostics were repaired.
