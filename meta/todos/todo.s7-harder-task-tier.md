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
  the planned primary subject is not at the ceiling. The scored tier is
  frozen before any scored trial, and no scored task is run during
  calibration, so tasks are never swapped after a ceiling result.
- A fixed scored task set, written before any scored trial, where the
  primary subject does not sit at the ceiling in Python or in Firth. Several
  tasks at allocator weight. If the frozen set lands at the ceiling anyway,
  it is kept and its result reported as it stands, not edited or replaced;
  a further tier would be a new frozen set, reported alongside it.
- Sonnet 5.5 is the planned primary subject (roadmap, "Subject models");
  the choice is confirmed before the scored tier is frozen. Haiku 4.5 stays
  as a secondary check of how learnable the language is for a small model.
- A cheap non-Anthropic subject (DeepSeek Flash) is added only if it can be
  reached without new credentials. If it cannot, say so here and leave it
  out.

## Progress

- Calibration pool: `eval/s7/harder/calibration.py`, eight tasks with
  Python and Firth reference solutions, hidden tests and planted mutants
  (`eval/s7/harder/test_harder.py`). Protocol and calibration results in
  `eval/s7/harder/README.md`.
- Calibration, 2 October 2026 (three Sonnet 5.5 authors per language): the
  pool is at the ceiling in Python (24 of 24 on the first attempt) and near
  it in Firth (21, then 22, of 24). A second, harder calibration pool comes
  before the scored tier is written.
- DeepSeek Flash: `deepseek-v4.1-flash` is listed at ollama.com, whose key
  is already connected to this project, so it can be reached without new
  credentials. Whether to spend that account on it is the maintainer's call.
