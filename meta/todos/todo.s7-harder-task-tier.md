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
  tasks at allocator weight. If a frozen set lands at the ceiling anyway,
  it is kept and its result reported as it stands, not edited or replaced,
  and this criterion stays unmet until a further frozen set, reported
  alongside it, meets it.
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
- Second calibration pool: `eval/s7/harder/calibration2.py`, eight larger
  rule-heavy tasks with every size and value bound stated and checked
  (`test_harder.py`), independent Python and Firth references, hand values
  and mutants. Calibrated on 2 October 2026 like the first (README):
  Python 22 of 24 and Firth 20 of 24, but six of eight tasks were passed
  by every author in both languages, and every Python failure is one hidden test on one
  clause, so this pool is effectively at the ceiling too. The next pool
  needs much larger programs, not more rules of this size.
- Pool 2's `order-book` and `heap-alloc` descriptions say a cancel or free
  names an "earlier operation", but their hidden tests include the
  operation itself and later ones (review of #214). The cases are kept as
  calibration only and are never moved into the scored tier as written;
  any task built from them states the target as a range without
  "earlier".
- Pool 2's `spreadsheet` description puts "(such a cell's references,
  even those inside 0 to n - 1, are then not followed at all)" right after
  the `a` greater than `b` condition, so it can be read as covering only
  that condition; five of six authors failed the one hidden test that
  turns on it (review of #214). The task stays calibration only as
  written; a scored version states the rule as its own sentence covering
  every way a cell gets an error from its own references.
- Third calibration pool: `eval/s7/harder/calibration3.py`, five whole
  programs (a processor, a falling-blocks game, a day-by-day bank, a
  formula sheet with edits, blackjack) whose references are 94 to 144
  lines of Python and 320 to 348 of Firth, against 31 to 77 and 41 to 194
  for the second pool. Every bound stated and checked, constraints between
  inputs included; input sizes cut so each Firth reference's costliest
  measured case is at most 207,659 kernel steps. Calibrated on 10 October
  2026 at `7e013b3` (README, "Third pool results"): Python 15 of 15 in
  round 1; Firth 10 of 10 for the two valid authors. Firth 3 was void
  (audit flag; 4 of 5, then 5 of 5, not scored). At the ceiling in both
  languages, so size alone does not separate Sonnet.
- Scored set written 10 October 2026 (`eval/s7/harder/scored.py`,
  README "The scored set"): six rule-dense tasks not run in calibration,
  with Firth and Python references, hand values, bounds checks with order
  and structural constraints, and a mutant per task. Its references' most
  costly hidden test is 98,097 to 209,279 kernel steps. No scored trial has
  run; the pre-registration (subjects, authors per arm, voids, analysis)
  comes before any.
- The audit flags each successful write that differs from the kept copy
  (Firth 3, pool 3). Before a scored run, either pre-register that rule
  as it stands or change the audit to compare only the last write, with
  a planted case.
- `eval/s7/context_seen.py --sample` failed on a Sonnet sample name, so
  the pool-3 scan ran without `--sample` and checked other authors' names
  with a grep (`runs/2026-10-10-calibration3/scan.sh`, `scan-output.txt`).
  Done in #230: Sonnet and DeepSeek names are compared whole, with planted
  cases, and run 14's Haiku call pattern gives byte-for-byte the same
  results (`eval/s7/runs/2026-10-10-context-seen-names/haiku_same.py`).
- Two wording gaps in pool 3's formula-sheet description (review on
  #223, checked against `calibration3.py`): "whose size is more than
  1,000,000,000" does not say size means absolute value, and "An operator
  or function 1 to 3 gives an error when any of its arguments ... is an
  error" leaves operators 4 to 6 and 8 to be inferred. Hidden tests reach
  both (a negative overflow in hidden test 7; error operands of `<`, `=`,
  `/` or negate in hidden tests 13, 14, 18 and 19). The run stands, since
  every author met the meaning, but pool 3's descriptions must be fixed
  before any reuse, and the scored tasks' descriptions checked for the
  same two kinds of gap.
- Subject models (maintainer's decision cards, answered 10 October 2026):
  Sonnet 5.5 is confirmed as the primary subject, and DeepSeek v4.1 Flash
  joins the scored tier only (not calibration), through the connected
  ollama.com key.
- DeepSeek Flash: `curl -sS https://ollama.com/api/tags` from this
  project's cloud environment on 2 October 2026 listed
  `deepseek-v4.1-flash`; the environment's proxy already injects an
  `OLLAMA_API_KEY` for ollama.com, so it can be reached without new
  credentials. No completion request was sent. Whether to spend that account on it is the maintainer's call.
- DeepSeek driver: `eval/s7/harder/deepseek.py` sends a prompt and keeps the
  reply as the answer file and asks each round once; a reply cut off at the
  length limit is a failed answer; failed requests and other incomplete,
  malformed or unexpected replies void the sample; its self-test runs in
  `test_harder.py` (README, "DeepSeek"). A probe on 10 October 2026
  (`runs/2026-10-10-deepseek-probe/`) showed a 91,647-character prompt read
  whole; no task has been sent. The pre-registration must state that a
  DeepSeek author sees the prompt and, on feedback rounds, its prior reply
  and the feedback, while a Sonnet author also sees its session's system
  prompt and `AGENTS.md`.
- Decided on 10 October 2026 by the project's coordinator, under the
  maintainer's delegation, for the scored run: a DeepSeek reply cut off at
  the length limit is scored as a failed answer, not replaced; a void round
  (a failed request or a reply that is not a complete answer) voids the
  whole sample, and only void samples are replaced. A round-1 cut-off gets a feedback round like any other failed
  answer, saying the reply was cut off, on both language arms.
  `eval/s7/harder/deepseek_sample.py` runs a DeepSeek sample by these rules
  (README, "DeepSeek"). The pre-registration, not yet written, must state
  them.

## Before any scored run (reviewer, #209)

- `eval/s7/context_seen.py` knew only Haiku sample names (`SAMPLE`), so
  calibration's cross-author check was a hand search. Sample names are
  done in #230, which edits this run 14 file with the coordinator's go-ahead
  on condition that run 14's calls give the same results (shown there).
  Still open: its labels (`LABEL`, `author [AB]N`) cover only the A/B
  runs; the scored run's pre-registration must name how its authors are
  labelled, and `LABEL` be extended to match, with a planted case.
- Calibration authors were shown two project messages as spawn background
  (George's of 30 September and 2 October), and a session hook's
  `hook_non_blocking_error` text. Neither names an author, but both are
  context the prompt does not give. A scored run keeps the messages out
  (authors started from a session with no queued project messages) or
  lists them, and the hook text, in its pre-registration. It also lists
  the harness's continuation items seen in pool 3 (Firth 1 and Firth 3,
  `runs/2026-10-10-calibration3/scan-output.txt`): "Output token limit
  hit. Resume directly ..." and "[Request interrupted by user]" after an
  API cut-off, and says whether a sample shown one still counts.
- The bounds check in `test_harder.py` covers sizes and value ranges only.
  The scored tier's check also covers order constraints (such as which
  operation a cancel may name), since that wording broke in two pool-2
  tasks (reviewer, #214).
