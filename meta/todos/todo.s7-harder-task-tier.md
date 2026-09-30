---
node: firth.toolchain.agent
status: open
created: 2026-09-30
---

# A harder S7 task tier, and more eval subject models

Sonnet already scores 19 to 20 of 20 on the MVP tasks and Python scored 20
of 20 for both Sonnet and Haiku, so neither the Python baseline
(`todo.s7-python-baseline`) nor a Sonnet-primary eval can separate anything
until the tasks get harder.

## Acceptance criteria

- A calibration pool, separate from the scored tier, used to check that
  Sonnet is not at the ceiling. The scored tier is then frozen and unseen
  before its results are observed, so tasks are never swapped after a
  ceiling result.
- A fixed task set, written before any trial, where Sonnet does not sit at
  the ceiling in Python or in Firth. Several tasks at allocator weight.
- Sonnet 5.5 is the primary subject. Haiku 4.5 stays as a secondary check
  of how learnable the language is for a small model.
- A cheap non-Anthropic subject (DeepSeek Flash) is added only if it can be
  reached without new credentials. If it cannot, say so here and leave it
  out.
