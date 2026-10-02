# The harder S7 tier

Sonnet scored 19 to 20 of 20 on the MVP tasks, and Python scored 20 of 20
for both Sonnet and Haiku (run 4, `eval/s7/README.md`). At that ceiling
neither the Python baseline (`todo.s7-python-baseline`) nor a Sonnet-primary
run can show a difference, so this tier is harder (`todo.s7-harder-task-tier`).

It has two task sets, kept apart:

- **The calibration pool** (`calibration.py`): eight tasks, run only to find
  out whether the planned primary subject sits at the ceiling on tasks of
  this kind. They are never scored as S7 evidence.
- **The scored tier**: a different set, written after calibration and frozen
  before any scored trial. No scored task is run during calibration, so no
  task is swapped out after a ceiling result. If the frozen set lands at the
  ceiling anyway, it is kept and its result reported as it stands; a further
  tier would be a new frozen set, reported alongside it. Not written yet.

Nothing here changes what an S7 run on the earlier tiers measures: the tier
has its own directory, task ids and scorer, and does not edit `harness.py`,
`tasks.py`, `mvp_tasks.py` or any document an author is shown.

## What makes it harder

Every task needs several cooperating words, a nested loop or a rebuilt
sequence, and most return more than one value. The pool spans seven kinds
of difficulty: rules with an exception (`bowling`), state over a sequence of
events (`lru`), an evaluator with error codes (`rpn`), a two-dimensional
dynamic program (`edit-cost`), a graph search with a tie-break
(`shortest-hops`), sorting then merging (`merge-ranges`), an interpreter
(`tiny-vm`), and a reconstruction with a tie-break (`lis-smallest`).

Each task has 10 to 15 hidden tests, against 4 to 8 on the MVP tier, chosen
for the edge cases a careful author can still miss. `test_harder.py` shows
that each task's hidden tests fail a planted answer with one such mistake
(a Python mutant per task: division that floors, a cache hit that does not
refresh the key, ranges next to each other left unmerged, and so on), so a
pass means more than the visible example.

Each description states its input bounds, so an author can tell whether a
quadratic loop fits the step budget (1,000,000 steps per run, the MVP
tier's). Values are `Int`, `Bool`, `Seq Int` and `Seq Bool`, the only ones
the portable runner passes in and reads back.

## Files

- `calibration.py`: the pool. Each task's `ref` is its meaning, in plain
  Python written independently of any Firth code.
- `reference/calibration/<id>.firth` and `<id>.py`: a Firth and a Python
  reference solution per task. The Python ones are written separately from
  the refs, so they check them.
- `tier.py`: `prompt`, `extract`, `score`, `repair` and `report` for this
  tier. It reuses the MVP harness's runners, comparison, sandbox and
  diagnostics. Scoring records the hashes of the task set and the scorer as
  they were imported, and refuses if they or the Firth tree change while it
  runs. Python answers run in the harness's sandbox, which needs root.
- `audit.py`: the MVP tier's transcript audit (`audit_subagent.py`), with
  this tier's feedback for the check that each `repair-<n>.md` is what the
  author was shown.
- `test_harder.py`: hand-worked values for every task, both reference
  solutions on every case, the mutants, and a check that the prompt carries
  no hidden input and repair shows only the example. CI runs it.

```sh
python3 eval/s7/harder/test_harder.py
python3 eval/s7/harder/tier.py prompt --set calibration --lang firth > prompt.md
python3 eval/s7/harder/tier.py extract answer-1.md > solutions-1.json
python3 eval/s7/harder/tier.py score --set calibration --lang firth solutions-1.json > results-1.json
python3 eval/s7/harder/tier.py repair --set calibration --lang firth solutions-1.json results-1.json > repair-1.md
```

## Protocol

The MVP tier's sub-agent protocol, unchanged: the author is a sub-agent told
to read only its prompt file and to write only its answer file, answers every
task in one file, and is then shown how each answer did on its task's visible
example (`repair`) and may fix it once. Round 1 is "correct on the first
attempt"; round 2 is "correct within two attempts", the two measures
`todo.s7-python-baseline` names. The Firth prompt carries the MVP documents.
Each transcript is audited with `audit.py`; a flagged author is void.

## Calibration plan

Written before any calibration author started.

- Subject: Sonnet 5.5, the planned primary subject, as an Agent-tool
  sub-agent. The model id each transcript records is reported.
- Three authors per language (Firth, Python), each answering all eight
  tasks, run one at a time with no other agent running in this session, so
  no author's context can name another.
- Reported per language: tasks passed in round 1 and in round 2, per author
  and in total, and which tasks failed and why.
- What it is for: deciding how hard the scored tier must be. The scored tier
  should not be at the ceiling in either language for the primary subject.
  If Sonnet passes nearly everything in Python within two attempts, the
  scored tier needs harder kinds of task than the pool's; if it fails most
  of them in both languages, easier ones. Calibration results are never
  S7 evidence and are not compared between languages as a result.

## Calibration results

Not run yet.
