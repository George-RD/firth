# The harder S7 tier

Sonnet scored 19 to 20 of 20 on the MVP tasks, and Python scored 20 of 20
for both Sonnet and Haiku (run 4, `eval/s7/README.md`). At that ceiling
neither the Python baseline (`todo.s7-python-baseline`) nor a Sonnet-primary
run can show a difference, so this tier is harder (`todo.s7-harder-task-tier`).

It has two task sets, kept apart:

- **The calibration pools**: `calibration.py` (eight tasks) and
  `calibration2.py` (eight harder ones, written after the first was at the
  ceiling), run only to find out whether the planned primary subject sits
  at the ceiling on tasks of their kinds. They are never scored as S7
  evidence.
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
whether a quadratic loop fits the step budget, and whether a result fits in
an `Int`. Several do not:

- Sizes: `rpn` does not bound the number of tokens, nor `tiny-vm` the
  program's length (only the instructions executed). `tiny-vm` gives
  `limit` no lower bound either, and a negative one has two readings: the
  task's meaning and the Firth reference stop only when the count equals
  it (so never), the Python reference as soon as the count reaches it (at
  once). No hidden test has a negative `limit` (the least is 0).
- Values: five descriptions allow inputs whose answer does not fit in a
  64-bit `Int`, which no Firth answer can return while the Python meaning
  can. `rpn` and `tiny-vm` do not bound operands (the largest `Int` times
  two; `rpn` also allows the smallest `Int` divided by -1), `edit-cost`
  does not bound the costs (`edit-cost([], [0, 0], 2^63 - 1, 1, 1)` is
  2^64 - 2), `shortest-hops` does not bound the weights, so a path's total
  can overflow, and `merge-ranges` does not bound the endpoints (one range
  from the smallest to the largest `Int` covers 2^64). `bowling`, `lru`
  and `lis-smallest` cannot overflow.

No hidden test reaches any of these: every expected result fits in an
`Int`, since both hosts' runs of the Firth references give it
(`test_harder.py`). The pool was run as written, so this is recorded here
rather than edited; the second pool states every bound, value bounds
included (see "The second calibration pool"). Both pools have 1,000,000
steps per run, the MVP tier's. Values are `Int`,
`Bool`, `Seq Int` and `Seq Bool`, the only ones the portable runner passes
in and reads back.

## Files

- `calibration.py` and `calibration2.py`: the pools. Each task's `ref` is
  its meaning, in plain Python written independently of any Firth code.
- `reference/<pool>/firth/<id>.firth` and `reference/<pool>/python/<id>.py`:
  a Firth and a Python reference solution per task. The Python ones are
  written separately from the refs, so they check them. The second pool's
  were written by Sonnet workers from the descriptions alone, without
  seeing the refs, the hidden tests or each other's code.
- `tier.py`: `prompt`, `extract`, `score`, `repair` and `report` for this
  tier. It reuses the MVP harness's runners, comparison, sandbox and
  diagnostics. Scoring records the hashes of the task set and the scorer as
  they were imported, and refuses if they or the Firth tree change while it
  runs. Python answers run in the harness's sandbox, which needs root.
  The sandbox's own scan for copies of hidden files knows only the MVP
  tier's, so before scoring Python `tier.py` scans what the sandbox would
  show for copies of this tier's hidden files, committed runs and
  `test_harder.py` (a file with the content of one, a directory named
  `eval/s7/harder`, or git storage holding any revision of them) and
  refuses if it finds one.
- `audit.py`: the MVP tier's transcript audit (`audit_subagent.py`), with
  this tier's feedback for the check that each `repair-<n>.md` is what the
  author was shown.
- `test_harder.py`: hand-worked values for every task, both reference
  solutions on every case, the mutants, a check that every second-pool
  input keeps to its description's bounds and every integer fits in an
  `Int`, and a check that the prompt carries no hidden input and repair
  shows only the example. CI runs it.

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

## The second calibration pool

`calibration2.py`: eight tasks, each a larger program with many rules that
interact, of the kind where a careful author still gets one corner wrong:
comparing poker hands (`poker`), a league table with a once-only
head-to-head tie-break (`league-table`), a bank ledger with overdraft
limits, fees, freezing and month-end interest (`bank-ledger`), a trading
order book with price-time priority, market orders and cancels
(`order-book`), a spreadsheet with cycles, error propagation and a count
that ignores errors (`spreadsheet`), a lift simulation (`elevator`),
calendar arithmetic (`date-diff`) and a best-fit memory allocator
(`heap-alloc`). Each has 15 to 23 hidden tests and a Python mutant that
passes the example and fails at least one of them (`test_harder.py`).

Every description states every bound: each input's size and each value's
range, so every result fits in an `Int`. `test_harder.py` checks every
example, hidden test and hand value against those bounds. Writing the
references found two places where the spreadsheet description could be
read two ways (whether a cell that only leads to a cycle has an error, and
whether a cell with an out-of-range reference follows its other
references); both were reworded before any author saw the pool, and each
reading now has a hidden test and a hand value. On the example and hidden
tests the Firth references use at most 70,071 kernel steps on a case
(`elevator`); on the largest inputs the descriptions allow, the workers
who wrote them measured at most 156,505 (`elevator` again), within a
quarter of the budget.

### Calibration plan

Written before any second-pool author started; as for the first pool,
except as stated.

- Subject: Sonnet 5.5 as an Agent-tool sub-agent; three authors per
  language, run one at a time in the order Python 1, Firth 1, Python 2,
  Firth 2, Python 3, Firth 3, with no other agent running in this session.
- Protocol: the MVP tier's sub-agent protocol with one feedback round, as
  above; each transcript audited with `audit.py --set calibration2`.
- Context: each raw log is scanned as the first pool's were. The first
  pool's authors were shown two project messages as queued context; the
  workers started from this session for the second pool's references
  were shown none (their logs have no `queued_command`), so the authors
  are expected to see none either, and the scan checks it. The session's
  `hook_non_blocking_error` items (a hook path on the maintainer's machine
  that does not exist here) are known in advance and name no author.
- Reported: per language, tasks passed in round 1 and within two rounds,
  per author and in total, and why each failure failed.
- What it decides: if Sonnet is below the ceiling in both languages, the
  scored tier is written from these kinds of task at this size. If it is
  still at the ceiling in Python, the scored tier needs harder tasks again.
  These results are calibration only, never S7 evidence.

## Second pool results: 2 October 2026

Run as planned above, in the planned order. Every transcript records
`claude-sonnet-5-5` and passed `audit.py --set calibration2` with nothing
flagged. Everything is in `runs/2026-10-02-calibration2/`. The prompts were
built at `f1b5537`, and every author was scored with the same task set and
scorer hashes (`eval_sha256` in each result). Python 1 was scored at
`81b9c52`; the others with uncommitted edits to `test_harder.py` and a todo
only, which scoring does not read (the `-dirty` commit in their results).

The context scan, as for the first pool: each raw log through
`eval/s7/context_seen.py` (`context-seen.json`), and a search of the whole
log for the other five authors' directory names and agent ids,
`task_status`, task notifications, compaction and `queued_command`. None
has any of them. Unlike the first pool's authors, none was shown a project
message. Every author was shown the same injected items: the session's
system prompt, tool list and reminders, and the pre-registered
`hook_non_blocking_error` items.

| | round 1 | within two rounds |
| --- | --- | --- |
| Python, 3 authors | 22 of 24 | 22 of 24 |
| Firth, 3 authors | 20 of 24 | 20 of 24 |

Only Firth 3 had an answer that failed its example, so only Firth 3 had a
feedback round.

The failures:

- `spreadsheet`, five of six authors (Python 2 and 3, all three Firth
  authors): each fails one hidden test, `([5, 1], [1, 1], [1, 50])`, and
  only that one. Cell 1 refers to cell 50, outside the sheet, so it has an
  error, and its reference to itself is not followed; cell 0 counts it and
  has no error. Each answer follows cell 1's in-range reference, finds a
  cycle, and gives cell 0 an error too. The description says such a cell's
  references, "even those inside 0 to n - 1, are then not followed at
  all", but the parenthesis comes right after the `a` greater than `b`
  condition, so it can be read as applying to that condition only. This is
  either a dropped rule or a description that can be read two ways; the
  results cannot tell which.
- `elevator`, Firth 3: round 1's `main` left one extra `Int` on the stack
  (`firth.type.declared-effect-mismatch`, shown on the example). Round 2
  passed the example and 14 of 15 hidden tests, and trapped with
  `call-depth-exceeded` on the 30-request case (rerun with
  `tools/loop/firth_run.py`). Its `arrive` loop calls itself inside a
  `locals` block nested in its own, the same non-tail call as the first
  pool's `tiny-vm` failures (`todo.locals-self-call-not-tail`). That is a
  defect in the toolchain, not an authoring miss: the docs say a call that
  is a word's last action is a tail call, the checker accepts the program,
  and erasure keeps a copy of an outer local after the call. #213 fixes it
  (open when this was written). Whether this answer passes with the fix
  was not checked.

No author failed `order-book` or `heap-alloc`, including their hidden
tests whose cancel or free names the operation itself or a later one. The
descriptions' "earlier operation" does not allow those, though their stated
ranges and "otherwise nothing changes" do (review of #214). A later pool
states the range without "earlier".

### What this says about the scored tier

The pool is still effectively at the ceiling for Sonnet in Python. Seven
of the eight tasks were passed by every author in both languages, and every
Python failure, and three of the four Firth failures, is the same one
hidden test on one clause. A tier whose only separation is one clause
measures how that clause was worded, not how well a model writes the
language, so the scored tier cannot be built from these tasks at this size
either. In Firth, the one failure of its own is again the non-tail
self-call that the checker accepts silently.

What the two pools show is that Sonnet writes rule-heavy programs of this
size correctly when every rule is stated plainly, in either language (the
longest answers were about 100 lines of Python and 250 of Firth). It is
inferred, not measured, that what would separate it is size: rules it must
hold together across a much longer program, such as a whole interpreter or
a scheduler with many interacting constraints, still within Firth's step
budget and 256-frame limit. That is a design question for the next pool,
not a result. These results are calibration only: they are not S7
evidence, and the Python and Firth columns are not a comparison of the
languages.

The next pool is calibrated only after #213 is on main, so the non-tail
self-call cannot decide a Firth result there.
