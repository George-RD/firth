# The harder S7 tier

Sonnet scored 19 to 20 of 20 on the MVP tasks, and Python scored 20 of 20
for both Sonnet and Haiku (run 4, `eval/s7/README.md`). At that ceiling
neither the Python baseline (`todo.s7-python-baseline`) nor a Sonnet-primary
run can show a difference, so this tier is harder (`todo.s7-harder-task-tier`).

It has two task sets, kept apart:

- **The calibration pools**: `calibration.py` (eight tasks),
  `calibration2.py` (eight harder ones, written after the first was at the
  ceiling) and `calibration3.py` (five much larger programs, written after
  the second was at the ceiling too), run only to find out whether the planned primary subject sits
  at the ceiling on tasks of their kinds. They are never scored as S7
  evidence.
- **The scored tier**: a different set, written after calibration and frozen
  before any scored trial. No scored task is run during calibration, so no
  task is swapped out after a ceiling result. If the frozen set lands at the
  ceiling anyway, it is kept and its result reported as it stands; a further
  tier would be a new frozen set, reported alongside it. `scored.py` (see
  "The scored set").

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

- `calibration.py`, `calibration2.py` and `calibration3.py`: the pools,
  `scored.py`: the scored set, and `candidates.py`: the candidates for the
  next scored set (below, "The candidate set"). Each task's `ref` is its meaning, in plain
  Python written independently of any Firth code.
- `reference/<pool>/firth/<id>.firth` and `reference/<pool>/python/<id>.py`:
  a Firth and a Python reference solution per task. The Python ones are
  written separately from the refs, so they check them. The second and
  third pools' were written by Sonnet workers from the descriptions alone,
  without seeing the refs, the hidden tests or each other's code.
- `tier.py`: `prompt`, `extract`, `score`, `repair` and `report` for this
  tier. It reuses the MVP harness's runners, comparison, sandbox and
  diagnostics. Scoring records the hashes of the task set and the scorer as
  they were imported, and refuses if they or the Firth tree change while it
  runs. Each Firth answer runs as `answer.firth` in its own source root,
  beside a copy of `stdlib/`. So `import "stdlib/core.firth";` works, the
  Firth prompt shows the library, and the library's files are among the
  hashes (since the scored run of 11 October 2026, whose answers ran alone
  and could import nothing). Every task's input and output names are valid
  in both Firth and Python (no `_`, no `-`), so both arms see the same
  names. Python answers run in the harness's sandbox, which needs root.
  The sandbox's own scan for copies of hidden files knows only the MVP
  tier's, so before scoring Python `tier.py` scans what the sandbox would
  show for copies of this tier's hidden files, committed runs and
  `test_harder.py` (a file with the content of one, a directory named
  `eval/s7/harder`, or git storage holding any revision of them) and
  refuses if it finds one.
- `author_tools.py`: the check that every sub-agent author had
  exactly Read, Write and the hand-back, in one working directory (below,
  "Author tool set"); `test_author_tools.py` checks it on planted logs.
- `audit.py`: the MVP tier's transcript audit (`audit_subagent.py`), with
  this tier's feedback for the check that each `repair-<n>.md` is what the
  author was shown, and this tier's `take` for the check that each
  `solutions-<n>.json` holds the answers the round may take.
- `deepseek.py`: the DeepSeek author's driver (below, "DeepSeek").
- `deepseek_sample.py`: one DeepSeek sample through both rounds, scored
  (below, "DeepSeek").
- `test_harder.py`: hand-worked values for every task, both reference
  solutions on every case, the mutants, a check that every second- and
  third-pool input keeps to its description's bounds and every integer fits in an
  `Int`, and a check that the prompt carries no hidden input and repair
  shows only the example. CI runs it.

```sh
python3 eval/s7/harder/test_harder.py
python3 eval/s7/harder/tier.py prompt --set calibration --lang firth > prompt.md
python3 eval/s7/harder/tier.py take --set calibration answer-1.md > solutions-1.json
python3 eval/s7/harder/tier.py score --set calibration --lang firth solutions-1.json > results-1.json
python3 eval/s7/harder/tier.py repair --set calibration --lang firth solutions-1.json results-1.json > repair-1.md
python3 eval/s7/harder/tier.py take --set calibration answer-2.md \
    --after solutions-1.json results-1.json > solutions-2.json
```

## Protocol

The MVP tier's sub-agent protocol, with one step changed (below): the
author is a sub-agent told to read only its prompt file and to write only
its answer file, answers every
task in one file, and is then shown how each answer did on its task's visible
example (`repair`) and may fix it once. An author whose answers all passed
their examples is shown nothing, since nothing it could see failed, and no
round is run; its result within two attempts is its first result. Round 1 is "correct on the first
attempt"; round 2 is "correct within two attempts", the two measures
`todo.s7-python-baseline` names. The Firth prompt carries the MVP documents.
Each transcript is audited with `audit.py`; a flagged author is void.

One step differs from the MVP tier: how a round's answers become its
solutions (`tier.py take`, the same step for a Sonnet and a DeepSeek
sample). Round 1 takes the set's tasks from the answer. Round 2 starts
from round 1's solutions and takes only the tasks the feedback listed; an
answer to any other task is not taken (decided on 10 October 2026 for the
scored run, `todo.s7-harder-task-tier`), and `take` names it. The MVP tier,
and this tier's calibration pools as run, took every task in the round-2
answer. The three calibration samples with a round 2 answered only listed
tasks, so their kept solutions are the same under both rules, and all 18
calibration samples, Firth and Python, keep the solutions this tier's rule
takes (`test_harder.py`, `take_rule`). `audit.py` rebuilds each kept
`solutions-<n>.json` by this tier's rule.

### Author tool set (from the next tier)

In the scored run of 11 October 2026 the sub-agent authors had whatever
tools the driver's session had, including session-messaging tools (two
Haiku authors called `send_message` and were voided), and that list changed
partway through the run (`runs/2026-10-11-scored/results.md`). Its skill
listing gained five `firth-ds:cairn-*` skills at the same point, probably
because the driver's working directory moved to a `firth-ds` checkout; that
cause is inferred, not shown. From the next tier on, every sub-agent
author in both language arms gets the same fixed set: Read, Write and the
hand-back (`todo.s7-author-tool-set`).

1. **The agent type.** Every author is started as `s7-harder-author`
   (`.claude/agents/s7-harder-author.md`: `tools: Read, Write`, no hooks,
   no model), with the subject's model passed when it is started. The
   harness adds `SubagentHandback` to the listed tools
   (`runs/2026-10-11-tool-probe/notes.md`). No other agent type starts an
   author. A session may not see an agent type added after it started (the
   session that added this one saw it only some minutes later), so the
   driver's session must start with this definition on its checkout. The
   probe of 11 October 2026 shows an author of this type got exactly Read,
   Write and `SubagentHandback` (`runs/2026-10-11-tool-probe/`).
2. **The working directory.** Before the first author starts, the driver
   sets its working directory to the pinned checkout and writes that path
   in `run-notes.md`. Until the last author has handed back it does not
   `cd` anywhere else (it uses absolute paths, `git -C` and subshells) and
   opens no other checkout in that session. It also starts no sub-agent
   other than the probe and the authors: the check below refuses any
   sub-agent log that `agent-ids.txt` does not list. Each line of a
   sub-agent's raw log records the working directory, so the check below
   sees a move.
3. **A probe first.** Still before the first sample, the driver starts one
   author of that type that is not a sample, with a prompt asking it to
   name its tools and write nothing else, and runs

       python3 eval/s7/harder/author_tools.py --logs LOG_DIR --probe AGENT_ID --cwd DIR

   where `LOG_DIR` is the session's `subagents/` log directory under
   `~/.claude/projects/`. The run starts only if this prints `ok`. Its
   output is committed as `tool-probe.txt` in the run directory: it shows
   that the `tools:` line was honoured in the session the samples ran in.
4. **A record per author.** After each author hands back, before it is
   scored, the driver runs

       python3 eval/s7/harder/author_tools.py --logs LOG_DIR --ids RUN/agent-ids.txt --cwd DIR

   which prints, for every author so far, its agent type, model, working
   directory and tool list, and refuses unless every author, voided or
   kept, had exactly Read, Write and `SubagentHandback`, no deferred tool,
   and only that working directory. `agent-ids.txt` lists the probe as the
   row `probe <id>` and every author; a sub-agent log in `LOG_DIR` that the
   list leaves out, or a name or id listed twice, also refuses the run, so
   an author cannot go unchecked by being left off the list. The last output is committed as
   `author-tools.txt`, the run's record of each author's tools. A refusal
   stops the run before the next author starts; the next tier's
   pre-registration says how a refused author counts.

`test_author_tools.py` checks the check on hand-written logs, with planted
logs it must refuse (an extra `send_message` tool, a deferred tool, no
Write, the wrong agent type, no tool list, a moved working directory).
The transcript audit (`audit.py`) still flags any call outside the allowed
ones, as before.

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
example, hidden test and hand value against those sizes and ranges. It
does not check order constraints: `order-book` and `heap-alloc` say a
cancel or free names an "earlier operation", and some of their hidden
tests break that (see the second pool's results). Writing the
references found two places where the spreadsheet description could be
read two ways (whether a cell that only leads to a cycle has an error, and
whether a cell with an out-of-range reference follows its other
references); both were reworded before any author saw the pool, and each
reading now has a hidden test and a hand value. On the example and hidden
tests the Firth references use at most 70,071 kernel steps on a case
(`elevator`). The workers who wrote them also reported a figure for the
largest inputs the descriptions allow, but kept neither those inputs nor
the output, so it is not claimed here.

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
- `elevator`, Firth 3: round 1's `main` pushed `tm` twice, so it left an
  extra `Seq Int` under its three results
  (`firth.type.declared-effect-mismatch`, shown on the example). The hint
  called it an extra `Int` on top, which is wrong
  (`todo.declared-effect-extra-position`). Round 2
  passed the example and 14 of 15 hidden tests, and trapped with
  `call-depth-exceeded` on the 30-request case (rerun with
  `tools/loop/firth_run.py`). Its `arrive` loop calls itself inside a
  `locals` block nested in its own, the same non-tail call as the first
  pool's `tiny-vm` failures (`todo.locals-self-call-not-tail`). That is a
  defect in the toolchain, not an authoring miss: the docs say a call that
  is a word's last action is a tail call, the checker accepts the program,
  and erasure keeps a copy of an outer local after the call. #213 fixes it
  (open when this was written). The reviewer put #213's `Erasure.lean`
  and `Pipeline.lean` (at e88ce99) on this branch and re-scored this
  answer: 15 of 15 hidden tests (review of #214). That is a
  counterfactual and is not scored.

No author failed `order-book` or `heap-alloc`, including their hidden
tests whose cancel or free names the operation itself or a later one. The
descriptions' "earlier operation" does not allow those, though their stated
ranges and "otherwise nothing changes" do (review of #214). A later pool
states the range without "earlier".

### What this says about the scored tier

The pool is still effectively at the ceiling for Sonnet in Python. Six
of the eight tasks were passed by every author in both languages, and every
Python failure, and three of the four Firth failures, is the same one
hidden test on one clause. A tier whose only separation is one clause
measures how that clause was worded, not how well a model writes the
language, so the scored tier cannot be built from these tasks at this size
either. In Firth, the one failure of its own is again the non-tail
self-call that the checker accepts silently.

What the two pools measured is narrow: on these 16 tasks, with three
Sonnet authors per language, every failure left within two rounds was
either the one clause-level spreadsheet hidden test or the toolchain's
nested-`locals` tail-call defect (the longest answers were about 100 lines
of Python and 250 of Firth). It is
inferred, not measured, that what would separate it is size: rules it must
hold together across a much longer program, such as a whole interpreter or
a scheduler with many interacting constraints, still within Firth's step
budget and 256-frame limit. That is a design question for the next pool,
not a result. These results are calibration only: they are not S7
evidence, and the Python and Firth columns are not a comparison of the
languages.

The next pool is calibrated only after #213 is on main, so the non-tail
self-call cannot decide a Firth result there.

## The third calibration pool

`calibration3.py`: five tasks, each a whole program rather than a
function: a 32-bit processor with 25 opcodes, flags set from the exact
result, 64 words of memory, a data stack, a call stack and six ways to
fault (`mini-cpu`); a falling-blocks game with seven pieces in four
rotations, wall kicks, hold, row clears, combos, back-to-back bonuses and
levels (`stacker`); a bank simulated day by day over the Gregorian
calendar, with one-off transactions, standing orders that move to the
month's last day and cancel after two rejections in a row, daily interest
posted at month end, and overdraft fees (`bank-days`); a sheet of formulas
in reverse Polish notation with eight operators, four range functions,
cycles, error propagation and re-evaluation after edits
(`formula-sheet`); and blackjack played by fixed rules from a known shoe,
with a dealer peek, naturals, splits, doubles and a round voided when the
shoe runs out (`blackjack`). Each has 20 to 31 hidden tests, hand values
and a Python mutant that passes the example and fails at least one hidden
test; the `stacker` reference has a Firth mutant (`test_harder.py`).

Size, measured with `wc -l`: the Python references are 94 to 144 lines
(638 in all) against 31 to 77 (358) for the second pool's eight, and the
Firth references 320 to 348 (1,668) against 41 to 194 (1,095). A first
draft of this pool (eight tasks of the second pool's kinds, built and
checked in full) was dropped before any author saw it because its Python
references were 17 to 59 lines, no larger than the second pool's.
Calibrating that draft was the easier option; it would have spent a
calibration run on a pool that could not answer whether size separates
Sonnet from the ceiling. So each task's reference size was measured
before its hidden tests were written.

Independence: a Sonnet worker wrote the Python references from the task
descriptions alone. Before any hidden test existed, they were compared
with the refs on seeded random inputs (400 per task, 2,000 for
`mini-cpu`, and 60 more `stacker` inputs placed to clear rows). They
agreed on every input except that the worker's `mini-cpu` read a shift's
`c` as a register number rather than a count; the committed reference is
fixed and says so in a comment, and its step limit was moved with the
description's (below). The descriptions came through that comparison with
no reading found that differs from the refs. The Firth references were
written the same way by three more Sonnet workers (`mini-cpu`,
`bank-days`, `blackjack`) and two whose sessions ended on an access error
(`stacker`, `formula-sheet`), whose programs were checked after they
stopped; all five pass every case below on both hosts.

Bounds: every description states each input's size and each value's
range, which fields an opcode or token kind uses (the rest are 0), and so
the largest result. `test_harder.py` checks every example, hidden test and
hand value against them, including the constraints between inputs: each
opcode's fields, formula lengths that add up to the token count, edits
that name a cell of the sheet, transaction days within the days
simulated, and a valid start date. No task names an "earlier operation".
Planted inputs that break each kind of constraint are refused.

Step budget: the first descriptions allowed 600 instructions, a 20-row
well and 400 moves, 400 days, 30 cells with 10 edits, and a 312-card shoe
over 50 rounds. At those sizes the `stacker` and `formula-sheet`
references needed 519,840 and 439,985 kernel steps on a case, over the
quarter of the budget a reference may use so that an author's slower but
reasonable program still fits, and the `mini-cpu`, `bank-days` and
`blackjack` references needed 239,938, 193,100 and 204,031 (`bank-days`
only after it was rewritten to skip quiet days). Before any author saw the
pool the sizes were cut to 300 instructions, a 10-row well with 30 pieces
and 100 moves, 120 days, 20 cells of up to 8 tokens with 4 edits, and a
120-card shoe over 20 rounds. That shrinks the inputs, not the programs.
Each Firth reference was then run on seeded inputs at the new largest
sizes (40 per task; for `mini-cpu`, the 19 of 400 random 64-instruction
programs that run all 300 instructions; `stacker` both random and placed
to clear rows), and the costliest of each is kept as the task's last
hidden test. The most kernel steps on any case are 127,746 (`mini-cpu`),
207,659 (`stacker`), 135,382 (`bank-days`, a hand-built 120-day case with
six accounts), 168,852 (`formula-sheet`) and 57,420 (`blackjack`), so a
reference's costliest case is about a fifth to a seventeenth of the
1,000,000-step budget. That is a
measured figure over these inputs, not a bound. A Firth answer that runs
out of steps is recorded as such in the results.

### Calibration plan

Written before any third-pool author started; as for the second pool,
except as stated.

- Subject: Sonnet 5.5 as an Agent-tool sub-agent (confirmed as the
  primary subject on 10 October 2026); three authors per language, run
  one at a time in the order Python 1, Firth 1, Python 2, Firth 2,
  Python 3, Firth 3, with no other agent running in this session.
- Protocol: the MVP tier's sub-agent protocol with one feedback round;
  each transcript audited with `audit.py --set calibration3`.
- Context: each raw log is scanned as the second pool's were
  (`eval/s7/context_seen.py`, plus a search for the other authors'
  directory names and agent ids, `task_status`, task notifications,
  compaction and `queued_command`). No project message is expected in an
  author's context; the session's `hook_non_blocking_error` items are
  pre-registered as known and name no author.
- Toolchain: main at the time the prompts are built, which carries #213,
  so the nested-`locals` tail-call defect cannot decide a Firth result.
- Reported: per language, tasks passed in round 1 and within two rounds,
  per author and in total, why each failure failed, and the length of
  each answer.
- What it decides: if Sonnet is below the ceiling in both languages, the
  scored tier is written from tasks of these kinds at this size. If it is
  still at the ceiling in Python, size alone does not separate it, and
  that is reported as it stands. These results are calibration only,
  never S7 evidence.

## Third pool results: 10 October 2026

Run as planned above, in the planned order, as Agent-tool sub-agents,
except that the Firth row has two valid authors (below).
Everything is in `runs/2026-10-10-calibration3/`. The prompts were built,
and every author was scored, at `7e013b3` (`commit.txt`, `firth_commit` in
each result), with one task set and scorer hash (`eval_sha256`). Every
transcript records `claude-sonnet-5-5`.

The audit (`audit.py --set calibration3`) passed five authors with nothing
flagged. It flagged Firth 3, so Firth 3 is void as the protocol is
written. Firth 3 wrote `answer-1.md` three times, at 7,359, 15,290 and
40,384 characters, and the audit compares every successful write with the
kept copy, which is the last. Each of the first two writes is "not what
the author wrote". It used no tool beyond reading its prompt and repair
file and writing its own answers. Its results are below, marked not
scored.

Firth 1's session was cut off by an API error two minutes after its only
write and before it handed back. The audit passed it, and its kept answer
is the one write its log records.

So the Firth row has two valid authors, not the three planned, and no
replacement was run. The plan's decision turns on Python ("if it is still
at the ceiling in Python, size alone does not separate it"), which had
all three. A replacement would have needed the toolchain at `7e013b3`
rebuilt in a separate checkout, and could not change that decision, so
the Firth result below is reported as incomplete rather than re-run.

The context scan, as for the second pool: each raw log through
`eval/s7/context_seen.py` (`context-seen.json`), and a search of the whole
log for the other five authors' directory names and agent ids,
`task_status`, task notifications, compaction and `queued_command`
(`runs/2026-10-10-calibration3/scan.sh`, its output in `scan-output.txt`).
`context_seen.py` ran without `--sample`, because on this commit it fails
on a Sonnet sample name, so the grep is the cross-sample check. None has
any of them, and no author was shown a project message. Every author was
shown the same kinds of injected item as the second pool's: the session's
system prompt, tool list and reminders (the repository's `AGENTS.md`
among them, an S7 input), and the pre-registered `hook_non_blocking_error`
items: two for each author, and six for Firth 3, which also had a
feedback round. Two Firth authors were also shown items that were not
pre-registered, the three of kind `other` in their `context-seen.json`
(the raw log lines, by line number, are quoted in `scan-output.txt`):
Firth 1 and Firth 3 each hit the output token limit once, and the harness
added "Output token limit hit. Resume directly ... Break remaining work
into smaller pieces." (183 characters); Firth 1's last item is "[Request
interrupted by user]" (29 characters), the API error cut-off after its
write. None names another author or carries a project message. They are
harness continuation text, but they were not pre-registered, and they
reached only two authors; Firth 3's three writes of `answer-1.md` may
follow from its cut-off, which is inferred, not checked. The scored
tier's pre-registration has to list them.

| | round 1 | within two rounds |
| --- | --- | --- |
| Python, 3 authors | 15 of 15 | 15 of 15 |
| Firth, authors 1 and 2 | 10 of 10 | 10 of 10 |
| Firth 3 (void, not scored) | 4 of 5 | 5 of 5 |

Every passing answer passed all of its task's hidden tests. The only
failure was Firth 3's round-1 `mini-cpu`, which did not parse:
`firth.syntax.invalid-item`, a stray `}` at line 148 of the answer.
Shown that, it fixed it, and its round-2 `mini-cpu` passed all 31 hidden
tests.

Answer lengths, in lines per task (`mini-cpu`, `stacker`, `bank-days`,
`formula-sheet`, `blackjack`):

- Python 1: 128, 126, 99, 138, 121 (612 in all).
- Python 2: 136, 127, 98, 141, 116 (618).
- Python 3: 128, 126, 94, 137, 128 (613).
- Firth 1: 119, 159, 128, 184, 208 (798).
- Firth 2: 371, 365, 296, 424, 468 (1,924).
- Firth 3, round 2's set: 188, 207, 173, 238, 230 (1,036).

### What this says about the scored tier

Sonnet is at the ceiling in both languages on this pool (in Firth, on
its two valid authors). Following the
plan, that is reported as it stands: making the programs several times
longer did not separate it. The Python answers are about as long as the
Python references (612 to 618 lines against 638). The valid Firth answers
run from 798 to 1,924 lines, against 1,668 for the references.

Across the three pools, Sonnet's valid authors have failed these things:

- still failing within two rounds: one ambiguously worded clause (pool 2's
  `spreadsheet`), and the nested-`locals` tail-call defect in the
  toolchain, since fixed by #213 (pool 1's `tiny-vm`, pool 2's
  `elevator`);
- fixed by one round of feedback: pool 1's `rpn`, which compared two
  `Bool`s with `prim =` (a gap in Firth,
  `todo.harder-tier-sequence-gaps`), and pool 2's `elevator`, whose round
  1 left an extra value on the stack.

This pool's valid authors failed nothing. The void Firth 3's syntax slip,
fixed by its feedback round, is not scored and is not counted here.

It is inferred, not measured, that fully specified tasks with stated
rules and bounds do not separate this subject at the sizes tried, in
either language. The next design question is not size. These
results are calibration only. They are not S7 evidence, and the Python
and Firth rows are not a comparison of the languages.

## The scored set

`scored.py`: six tasks, written after the third pool's results and not run
in calibration: a warehouse puzzle with undo and dead-box counting
(`sokoban`), draughts played by a fixed rule with forced and multiple
captures and two tie-breaks (`checkers`), a regular expression matcher
with its own grammar and invalid patterns (`regex`), a Swiss-system
tournament with byes, forced rematches, colour rules and Buchholz scores
(`swiss`), a warehouse with expiring lots, backorders, cancellation and
reordering (`warehouse`) and a two-level write-back cache (`cache-sim`).
Its Python references are 47 to 116 lines (466 in all) and its Firth ones
139 to 454 (1,859), measured with `wc -l`. A Sonnet worker wrote the
Python references from the descriptions alone; they agree with the
meanings on 3,000 seeded random inputs per task (`test_harder.py`,
`scored_random_agreement`, with a planted reference that disagrees). Each
example, which the author is shown, also has its result worked out by
hand in `test_harder.py`.

These are not longer programs than the third pool's (its Python references
were 94 to 144 lines): that pool showed size alone does not separate
Sonnet. They are rule-dense instead, each with several interacting rules,
tie-breaks and edge cases a reader must hold together. Who is run on them,
and how, is pre-registered before any trial in
`scored-run/preregistration.md`, with the sample order in
`scored-run/run-plan.md`. Whether any
subject is below the ceiling on them is what the scored run measures; it
is not assumed here.

Before the set was frozen, each description was checked for sentences a
careful reader could take two ways that the hidden tests tell apart (each
other reading was run as a mutant of the meaning). Twelve were made
explicit, and each of their other readings is kept as a mutant that at
least one hidden test tells apart (`test_harder.py`, `scored_readings`,
with the unchanged meaning as a planted case that none does): the solved check before the first `sokoban` move, its dead-box
rule, the `checkers` landing-square tie-break, its starting square during
a capture, losing with no move at the ply limit, which men count as
crowned, what a `regex` postfix operator applies to, a `swiss` player with
no last game, its bye being given before pairing, which units a
`warehouse` cancellation counts, its reorder on a supply's due day, and
how `cache-sim` counts dirty blocks.

Each task has 15 to 25 hidden tests: hand-picked cases aimed at each rule
its description states, a few random inputs and, last, the costliest input
for its Firth reference among a fixed list of candidates at the largest
sizes the description allows: 40 to 50 seeded random inputs per task (and
for `checkers` the opening with each side first), and for `regex` 12
patterns built to be slow, each against 8 strings of 12 letters in three
alphabets. `costliest.py` is that search; its recorded output is
`costliest.tsv`, where every candidate's result also agreed with the
meaning, and `test_harder.py` (`scored_costliest`) checks that each last
hidden test is the record's costliest candidate. The most kernel steps on such an input are 144,953
(`sokoban`), 209,279 (`checkers`), 98,097 (`regex`, `a*` ten times against
strings of twelve `a`s), 108,057 (`swiss`), 179,655 (`warehouse`) and
161,365 (`cache-sim`), all within a quarter of the 1,000,000-step budget.
That is a measured figure over these inputs, not a bound. On a fresh
build, a first run of `costliest.py` or `measure.py`, with several
`firth_run.py` processes starting at once, has recorded `None False` or
`exit 1` for inputs that finish when run again alone (reviewer, #229 and
#231), so any such row is re-run on its own before it is trusted. The first
Firth reference for `regex`, which kept sets of positions as `Seq Bool`,
ran out of the budget on inputs within the drafted bounds (30 tokens, 10
strings of 20 letters): `(a|b|c)*` three times then `.*` three times,
against strings of `a` or of `a`, `b` and `c`, ends with the VM's
`fuel-exhausted` trap after 1,000,000 steps, while `a*` fifteen times
finishes in up to 395,604 (`measure.py --drafted`, recorded in
`drafted.tsv`; `test_harder.py` checks the record and runs one of the
traps again). The bounds were cut to 20 tokens and 8 strings of 12 letters
and the reference rewritten as a position automaton with sets held as bits
in one `Int` (Firth has no bitwise operations, so it ORs through a
literal table). The first version is kept, with its measurement, in
`runs/2026-10-10-regex-seq-bool/` (`measure.py`, `output.tsv`). At the new
bounds, on five patterns built to be slow and the 36 `regex` candidates of
`costliest.py`, it agrees with the meaning on all 41 and costs up to
816,497 steps (`(a|b|c)*` twice and `.*` twice against strings of `a`,
`b` and `c`), so an answer written that way fits the budget on these
inputs, though with less room than the bitset reference. That is a
measurement, not a bound: a slower correct Firth answer can run out of
steps where the same algorithm in Python passes. `test_harder.py`
holds hand values for each task, checks every input against its stated
bounds (structural ones included: the walls around a sokoban floor, the
pieces on a draughts board, string lengths that add up to the letters, a
result for every game, events in day order) with a planted bad input for
each kind, and a Python mutant per task and a Firth `sokoban` mutant that
the hidden tests fail.

One rule cannot be seen in any result: `warehouse` takes stock from lots
with equal expiry in order of arrival, but such lots are always thrown
away together and every output is a total, so no test can tell that
order from another. In `checkers`, taking a jumped piece off at once
cannot be told apart from taking it off at the end of the capture, since
a jump never lands on a square a jumped piece stood on; the rule that the
moving piece's own square is empty during the capture is tested.

## The candidate set

`candidates.py`: nine tasks for the next scored set, none of them yet sent
to a model. The 11 October scored set is not reused, because the checker's
fix hints that followed it were built and tested on that run's programs.
Three candidates are of the rule-dense genre that has sat at Sonnet's Python
ceiling in every pool (`go-game`, Go with captures, suicide, ko and area
scoring; `tennis`, scoring with tiebreaks, no-ad games and serve order;
`kalah`, sowing with captures, extra moves and the end sweep). Six are hard
in another way: `josephus` and `perm-rank` need an algorithm, since direct
simulation or enumeration is too slow at the stated sizes in either
language; `huffman` (a code built in a stated merge order, then made
canonical), `avl-tree` (inserts and deletes with rotations, deleting by the
successor) and `build-sched` (list scheduling by priority on several
workers) are exact procedures with tie-breaks and edge cases; and
`wire-decode` is edge cases in a binary format. Which six become the scored
set, and whether a scored run starts at all, is fixed before any of them is
run, in `next-run/calibration.md`.

Review of the first draft (commit `a6dcf7f`) dropped four candidates under
the close-relative rule (`next-run/calibration.md`): `order-match`,
`stack-vm`, `expr-eval` and `timetable`, each a close relative of an
earlier task Sonnet passed in Python every time. They were replaced by
`huffman`, `avl-tree`, `kalah` and `build-sched`, chosen to need neither
values beyond 64 bits nor compute heavy enough for the Firth step budget to
shape them (`bigint` and a best-rational-approximation task were ruled out
for that reason).

Sonnet workers wrote both references from each task's prompt text alone:
the Python ones (24 to 103 lines, 542 in all, `wc -l`) without access to
the repository, the Firth ones (49 to 211 lines, 1,204) with the docs,
stdlib and examples but not `candidates.py`, the tests or each other's
code. Where a worker's reading differed from the meaning and the
description allowed it, the sentence was made explicit (`tennis`: a match
tiebreak, finished or not, is given as its points so far). The Python
references agree with the meanings on every hidden test and on 3,000
seeded random inputs per task (`test_harder.py`,
`candidates_random_agreement`, with a planted `tennis` reference that
disagrees). Each example has its result worked out by hand; each input
keeps to its description's bounds, with a planted bad input for each kind
of constraint; each task has a Python mutant of its meaning that passes the
example and fails a hidden test; eleven sentences a careful reader could
take two ways are each kept as a reading the hidden tests tell apart
(`candidates_readings`); and a Firth `wire-decode` reference that accepts
field number 0 fails the hidden tests.

Each task's last hidden test is its costliest input for the Firth
reference among a fixed list (`costliest.py --candidates`): every hand case,
20 to 40 seeded random inputs at the largest sizes each description allows,
and inputs built to be slow (circles near 10^12 counting by 12, every digit
twice, the longest records, 400 alternating points, Fibonacci weights with
the longest code repeated, ascending inserts followed by deletes, a long
chain of dependencies). The record is `costliest-candidates.tsv`, where
every result also agreed with the meaning, and `candidates_costliest`
checks that each last hidden test is the recorded costliest and costs at
most a quarter of the 1,000,000-step budget, with a planted record for
each. The most kernel steps on such an input are 74,975 (`go-game`),
207,883 (`josephus`), 36,355 (`perm-rank`, on one of its hand cases, which
the first draft's search left out and so reported 30,421), 47,341
(`wire-decode`), 56,746 (`tennis`), 194,148 (`huffman`), 98,368
(`avl-tree`), 58,192 (`kalah`) and 89,832 (`build-sched`). That is a
measured figure over these inputs, not a bound.

Bounds were cut where the Firth reference ran past a quarter of the
budget on inputs within the drafted ones: `josephus` from 4 questions
counting by up to 20 to 3 counting by up to 12 (459,865 steps near 10^12)
and `huffman` from 40 symbols to 20 (416,163 for the committed reference
with frequencies `s % 7 + 1` and message `s * 13 % 40` for `s` below
40 and 100). Two candidates dropped later under the close-relative
rule had been cut the same way: `order-match` from 40 orders to 30 and
`stack-vm` from a step limit of 2,000 to 800. Making only the
reference faster was rejected: a straightforward Firth answer would then
have had less room than the tier allows, a cost the Python arm never
pays. A tenth candidate, `chess-moves` (count the legal moves in a
position, with castling, en passant and promotions), was dropped for the
same reason. Its first Firth reference took up to 564,839 steps on the
known 218-move positions; a second, which tests a move for check only
when the move could change it, still took 246,739 to 266,812 on those
and up to 264,653 on positions searched for cost with no more than the
starting material and 12 pieces on the board, so no natural bound kept
it within a quarter. The positions, both references, the script and its
output are in `runs/2026-10-11-chess-moves-dropped/`.

## DeepSeek

DeepSeek v4.1 Flash joins the scored tier only, not calibration, through
ollama.com's chat API, billed to the project's ollama.com account
(`todo.s7-harder-task-tier`). The environment's proxy adds the key, so no
key is in the repository, the driver or what it records.

DeepSeek has no tools, so `deepseek.py PROMPT DIR ROUND` is its hands. It
sends the prompt file's text as the user turn and keeps the reply's text,
byte for byte, as `answer-ROUND.md`. In a feedback round it sends the
conversation so far again, with `repair-<n>.md` as the next user turn: the
same files a Sonnet author reads and writes, scored by the same `tier.py`.
A round is asked once: `request-ROUND.json` is created before the request
is sent, and a round whose request file exists is refused. Only a complete
reply is kept as an answer. A reply cut off at the length limit
(`done_reason` `length`, exit 2) is the model's answer running too long, so
the round is a failed answer, not replaced (decided on 10 October 2026,
`todo.s7-harder-task-tier`): nothing in it is scored, so in round 1 every
task counts as unanswered. Its text is kept as `cut-ROUND.md`. Everything
else that is not a complete answer voids the sample (exit 3): a request
that failed (a network error, which may come after the server answered, a
body cut short or not UTF-8, or any HTTP status but 200), a reply that is
not a chat reply, a message not in the `assistant` role, text that cannot
be written as UTF-8, another model's name, `done` not `true`, or any other
`done_reason`. A failed request is never sent again, so no answer is ever
asked for twice. The whole reply, the model's `thinking` included, is kept
in `response-ROUND.json` and is never scored. `deepseek.py
--self-test` checks this against planted replies with no network, and
`test_harder.py` runs it.

`deepseek_sample.py --set scored --lang LANG PROMPT DIR` runs one DeepSeek
sample through both rounds with `tier.py`'s steps, as a Sonnet sample is run
by hand: round 1 is asked, extracted and scored; `tier.py repair`'s feedback
(nothing from a hidden test) is sent as round 2 when any task has no answer
or an answer failed its example; round 2's answers replace round 1's for
the tasks the feedback listed, and the whole set is scored again. Round 2's
answer to a task the feedback did not list is not taken, and `outcome.json`
names it. Nothing in a cut-off reply is taken, whatever it holds: a round-1
cut-off scores every task as unanswered, and a round-2 cut-off keeps round
1's results without scoring again. After a round-1 cut-off the feedback
says the reply was cut off and lists every task, and round 2 resends the
cut text as the model's turn. A void round voids the sample: its reply is
not scored and the sample has no score (round 1's results, when round 2 is
the void one, stay on disk), and `outcome.json` records the round and why. A run that stops part
way leaves `outcome.json` with status `crashed` and the error, never read
as a finished sample. `outcome.json` also records each round's verdict
and which tasks passed in round 1 and within two rounds. `test_harder.py`
runs it against planted replies with a stand-in
scorer, and once end to end with `tier.py`'s scorer on the first
calibration pool's Firth references.

A Sonnet author differs in what else it sees: it is a sub-agent, so its
context also holds the session's system prompt and the repository's
`AGENTS.md` (through `CLAUDE.md`), and it reads the prompt with a tool.
DeepSeek sees only the prompt and, in round 2, its own answer and the
feedback. The scored run's pre-registration states this difference.

A long prompt is read whole: `runs/2026-10-10-deepseek-probe/probe.py` puts
a codeword first, then the three MVP documents twice (91,647 characters,
against 63,949 for the third pool's Firth prompt,
`runs/2026-10-10-calibration3/prompt-firth.md`), and asks for the codeword last.
On 10 October 2026 the reply was the codeword, with `done_reason` `stop`
and 22,632 prompt tokens (`probe.out`). The probe exits 1 unless the
reply is the codeword, complete, from the scored model; `test_harder.py`
plants a wrong reply, a cut-off, another model, `done` false, `done` 1, a
502, a non-JSON body and a network error, and each fails it. That is one probe, not a bound on
the prompt length the server keeps; each scored round's
`prompt_eval_count` is in its `response-ROUND.json`. No task has been sent
to DeepSeek.
