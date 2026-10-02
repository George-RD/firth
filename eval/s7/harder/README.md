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
of difficulty, one task each plus a second dynamic program: rules with an exception (`bowling`), state over a sequence of
events (`lru`), an evaluator with error codes (`rpn`), a two-dimensional
dynamic program (`edit-cost`), a graph search with a tie-break
(`shortest-hops`), sorting then merging (`merge-ranges`), an interpreter
(`tiny-vm`), and a reconstruction with a tie-break (`lis-smallest`).

Each task has 10 to 16 hidden tests, against 4 to 8 on the MVP tier, chosen
for the edge cases a careful author can still miss. `test_harder.py` shows
that each task's hidden tests fail a planted answer with one such mistake
(a Python mutant per task: division that floors, a cache hit that does not
refresh the key, ranges next to each other left unmerged, and so on), so a
pass means more than the visible example.

Each description is meant to state its input bounds, so an author can tell
whether a quadratic loop fits the step budget. Some do not: `rpn` does not
bound the number of tokens, nor `tiny-vm` the program's length (only the
instructions executed), and `merge-ranges` does not bound the endpoints,
so for one range from the smallest to the largest `Int` the covered count
is 2^64, which no Firth answer can return (no hidden test comes near it:
the most any covers is 31). The pool was run as written, so this is
recorded here rather than edited; the next pool states every bound,
values included (1,000,000 steps per run, the MVP tier's). Values are `Int`, `Bool`, `Seq Int` and `Seq Bool`, the only ones
the portable runner passes in and reads back.

## Files

- `calibration.py`: the pool. Each task's `ref` is its meaning, in plain
  Python written independently of any Firth code.
- `reference/calibration/firth/<id>.firth` and
  `reference/calibration/python/<id>.py`: a Firth and a Python reference
  solution per task. The Python ones are written separately from
  the refs, so they check them.
- `tier.py`: `prompt`, `extract`, `score`, `repair` and `report` for this
  tier. It reuses the MVP harness's runners, comparison, sandbox and
  diagnostics. Scoring records the hashes of the task set and the scorer as
  they were imported, and refuses if they or the Firth tree change while it
  runs. Python answers run in the harness's sandbox, which needs root.
  The sandbox's own scan for copies of hidden files knows only the MVP
  tier's, so before scoring Python `tier.py` scans what the sandbox would
  show for copies of this tier's hidden files and committed runs (a file
  with the content of one, a directory named `eval/s7/harder`, or git
  storage holding any revision of them) and refuses if it finds one.
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
example (`repair`) and may fix it once. An author whose answers all passed
their examples is shown nothing, since nothing it could see failed, and no
round is run; its result within two attempts is its first result. Round 1 is "correct on the first
attempt"; round 2 is "correct within two attempts", the two measures
`todo.s7-python-baseline` names. The Firth prompt carries the MVP documents.
Each transcript is audited with `audit.py`; a flagged author is void.

## Calibration plan

Written before any calibration author started.

- Subject: Sonnet 5.5, the planned primary subject, as an Agent-tool
  sub-agent. The model id each transcript records is reported.
- Three authors per language (Firth, Python), each answering all eight
  tasks, run one at a time with no other agent running in this session, so
  no author's context can name another. (Serial order alone does not
  ensure that; the scan reported under the results checks it.)
- Reported per language: tasks passed in round 1 and in round 2, per author
  and in total, and which tasks failed and why.
- What it is for: deciding how hard the scored tier must be. The scored tier
  should not be at the ceiling in either language for the primary subject.
  If Sonnet passes nearly everything in Python within two attempts, the
  scored tier needs harder kinds of task than the pool's; if it fails most
  of them in both languages, easier ones. Calibration results are never
  S7 evidence and are not compared between languages as a result.

## Calibration results: 2 October 2026

Run as planned above: six Sonnet authors, one at a time, in the order
Python 1, Firth 1, Python 2, Firth 2, Python 3, Firth 3. Every transcript
records `claude-sonnet-5-5` and passed `audit.py` with nothing flagged
(each author read its prompt, wrote its answer, and, when it had feedback,
read it and wrote once more). Everything is kept in
`runs/2026-10-02-calibration/`: the prompts, and for each author its
answers, the feedback it was shown, the scored results (with the runner's
measured `kernel_cost` and `vm_cost` for every Firth case) and the trimmed
transcript. Authors 1 to 5 were scored at `ecfada9`; Firth 3 at `6b43d6d`,
which adds only a todo file.

Serial order alone does not keep authors apart: run 13's void came from
context the harness put into an author's log (compaction summaries,
`task_status` naming another author), not from authors overlapping. So
each author's raw log was scanned for what it was shown without asking:
`eval/s7/context_seen.py LOG` (each author's `context-seen.json`, run
without `--sample`, whose pattern knows only Haiku sample names), and a
search of the whole raw log for the other five authors' directory names
and agent ids, `task_status`, task notifications and compaction. No log
has a compaction, a `task_status` or a notification, and none names
another author. Every author was shown the same injected items: the
session's system prompt, tool list and reminders, and George's two
project messages that the thread was started with (on Sonnet as the
subject and on idle threads), which name no author.

| | round 1 | within two rounds |
| --- | --- | --- |
| Python, 3 authors | 24 of 24 | 24 of 24 |
| Firth, 3 authors | 21 of 24 | 22 of 24 |

`tier.py report runs/2026-10-02-calibration/*/results-*.json` prints the
table per task and author. Only Firth 1 had an answer that failed its
example, so only Firth 1 had a feedback round; the other five authors'
results within two rounds are their first results (see "Protocol").

The three Firth failures:

- `rpn`, Firth 1, round 1: the answer compared two `Bool`s with `prim =`,
  which takes only `Int`s (`firth.type.primitive-input-mismatch`). The
  feedback showed the diagnostic and round 2 passed. The Sonnet worker that
  wrote the reference hit the same gap (`todo.harder-tier-sequence-gaps`).
- `tiny-vm`, Firth 2 and Firth 3: both answers passed the example and 15
  of 16 hidden tests, and trapped with `resource-fault` on the one that
  runs 300 instructions. Each loops by a self-call placed inside a `locals`
  block nested in the word's own `locals` block. That call is not a tail
  call, because the outer locals are dropped after it, so each instruction
  nests a frame and the VM traps past 256. The checker accepts the program
  and the docs do not say this (`todo.locals-self-call-not-tail`). The
  example runs 19 instructions, so the feedback round could not show it.

### What this says about the scored tier

The pool is at the ceiling for Sonnet in Python: every task passed on the
first attempt, three times out of three. Tasks of these kinds and this size
cannot separate the languages, so the scored tier cannot be more of the
same. In Firth, Sonnet is close to the ceiling too, and both kinds of
failure are Firth pitfalls (a missing operation and a call that silently
is not a tail call), not misread specifications.

The scored tier therefore needs harder kinds of task than this pool has:
larger programs with many interacting rules, where a careful author can
still misread or drop one, at sizes Firth's step budget and 256-frame limit
allow. Because this pool overshot, a second calibration pool of those kinds
is calibrated the same way before the scored tier is written, so the
frozen tier is not a guess. These results are calibration only: they are
not S7 evidence, and the Python and Firth columns are not a comparison of
the languages.
