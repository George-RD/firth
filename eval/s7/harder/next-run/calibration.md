# Harder tier, next run: calibration and selection (pre-registration)

Written 11 October 2026, before any candidate task has been sent to a
model. It fixes how the next scored set is chosen from the nine candidates
in `eval/s7/harder/candidates.py`, and when the scored run does not start
at all. The scored run's own pre-registration is written separately; it
uses the set this file selects and fresh authors. Neither this file nor the
candidates change after the pin below; anything learnt in calibration is
reported, not folded back in.

**Status: draft. Not pinned. No author has run.** Calibration starts only
when the maintainer has chosen calibrate-then-select over freezing an
unrun set (the coordinator's card of 11 October 2026), and only after the
conditions in "Before the pin" are met.

## Why new tasks, and why calibrate

- **No reuse of the 11 October scored set.** The checker's single-edit fix
  hints for one-value-off stack errors (the language core thread's PR)
  were built and tested on programs from that run. Its tasks would test the
  hints on the cases they were made from, so the next scored set does not
  reuse them, and no candidate is one of them.
- **The Python ceiling.** Fully specified rule-dense tasks have not
  separated Sonnet 5.5 in Python at any size tried: pool 2 passed 22 of 24
  within two rounds, pool 3 15 of 15 (Python answers about 600 lines), and
  the scored set 48 of 48 (`README.md`, pool results;
  `runs/2026-10-11-scored/results.md`). With Python at the ceiling, Firth
  cannot be materially higher on either measure, so a set frozen unrun is
  likely to give parity by construction. Calibration measures where each
  candidate sits before the scored set is fixed.
- **More than one kind of difficulty.** Three candidates are of the genre
  that has sat at the ceiling, simulations with many interacting rules
  (`go-game`, `tennis`, `kalah`). Six test other hypotheses: `josephus`
  and `perm-rank`, where the difficulty is an algorithm (inputs too large
  for direct simulation or enumeration in either language); `huffman`,
  `avl-tree` and `build-sched`, where it is an exact procedure with
  tie-breaks and edge cases (a tree built by a stated order, rebalancing
  with its delete rules, list scheduling); and `wire-decode`, where it is
  edge cases in a binary input format.
- **No close relative of a task already run at the ceiling.** A candidate
  is dropped if an earlier pool or the scored set ran a close relative (the
  same core procedure on the same kind of input) that Sonnet passed in
  Python every time. Every earlier pool task passed in Python every time
  except `spreadsheet` (pool 2, 1 of 3), so every relative counts. Dropped
  under this rule: `lifts`, `recurrence` and `heap-gc` (relatives of pool
  2's `elevator`, `date-diff` and `heap-alloc`) before the first draft of
  this file, and, after review, `order-match` (pool 2's `order-book`),
  `stack-vm` (pool 1's `tiny-vm` and pool 3's `mini-cpu`), `expr-eval`
  (pool 1's `rpn` and pool 3's `formula-sheet`) and `timetable` (pool 1's
  `shortest-hops`: least-cost paths with a second tie-break). `tennis` is
  kept: the nearest earlier task is pool 1's `bowling`, which shares the
  sport's scoring but not the procedure (bowling is one pass with bonuses
  looked up ahead; tennis is nested points, games and sets with
  tiebreaks, deciding-set rules and serve order). The four dropped after
  review are in the commit `a6dcf7f` and were replaced by `huffman`,
  `avl-tree`, `kalah` and `build-sched`, which have no such relative.
- **The Firth step budget shaped the set.** A task is kept only if its
  Firth reference costs at most a quarter of the 1,000,000-step budget on
  its costliest recorded input. To meet that, four bounds were cut (two
  of them on candidates later dropped) and `chess-moves` was dropped
  (`README.md`, "The candidate set"). The replacements were chosen to need
  neither big numbers nor heavy compute (`bigint` and a
  rational-approximation task were ruled out because Python's integers are
  unbounded and Firth's are 64-bit), and even so `huffman` was cut from 40
  symbols to 20. So the set
  leaves out compute-heavy tasks and tasks with large intermediate values,
  where Firth is weaker: a straightforward Firth program costs far more
  steps than the same program in Python, and Python has no step budget at
  all. Whatever the scored run finds, it says nothing about such tasks.
- No candidate is run more than once in calibration, and none is changed
  after it.

## Calibration run

- **Subject:** Sonnet 5.5, the scored run's primary subject, through the
  Agent tool as agent type `s7-harder-author` with model `sonnet`.
- **Samples:** 3 authors per language arm, Python and Firth, every author
  answering all nine candidates. Named `cal-<lang>-<n>`.
- **Protocol:** the tier's protocol (`README.md`, "Protocol"), with the
  author tool set steps 1 to 4 ("Author tool set"), two rounds, round 2
  taking only the listed tasks. The author is started with the scored run's
  text (`scored-run/preregistration.md`, "How a sample runs").
- **Order:** alternating arms, Python first: `cal-python-1`,
  `cal-firth-1`, `cal-python-2`, `cal-firth-2`, `cal-python-3`,
  `cal-firth-3`; replacements at the end in the order the voids happened.
- **Pin:** the prompts are built at one main commit, after the hints PR has
  merged, and committed with `commit.txt` and the stdlib version in the
  run directory `runs/<date>-calibration4/`. The scored run uses the same
  commit, so calibration and scoring see the same checker, docs and
  stdlib. If any S7 input changes before the scored run is pinned, the
  calibration result is reported as stale and the selection is not used.

## Stop rules before and during calibration

- **Tool probe (stop rule).** Before the first sample, in the session the
  samples run in, the driver starts one non-sample `s7-harder-author` and
  runs `author_tools.py --probe`; calibration starts only if it prints
  `ok`, and its output is committed as `tool-probe.txt`.
- **Working directory.** The driver fixes its working directory to the
  pinned checkout before the probe, records it in `run-notes.md`, and does
  not change it until the last author has handed back.
- **Per-author tool record.** After each author, `author_tools.py --ids
  --cwd` over every author so far. A refusal stops calibration before the
  next author; the refused author is void with cause "tool list", and the
  run resumes only after the cause is found and fixed in its own reviewed
  change.
- **Voids and crashes** as the scored run defines them, with the known
  items below. The first and second void or crash in an arm are replaced.
  A third void or crash in an arm is not replaced: calibration is
  incomplete, and the selection is not used.
- **No stop on results.**

## Known injected items

Each is recorded in `runs/2026-10-11-tool-probe/notes.md` (#251), from the
log of a probe author of the same type. These name no author, are the same
for every author in both arms, and do not void a sample. Any other injected item, a project message, or another
author's name or id voids the sample.

- the session's system prompt, tool list and reminders, including the
  repository's `AGENTS.md` through `CLAUDE.md`;
- the session-start attachments: environment, model, instructions, session
  context, date, credential and session-change items;
- an `mcp_instructions_delta` attachment with the session's MCP servers'
  instructions, although the author has none of their tools;
- `hook_non_blocking_error` items from the `omega-memory` PostToolUse hook
  (exit 127, "not found"), after a Read or a Write;
- the system reminder before the author's first call telling it to
  report through `SubagentHandback`;
- `total_tokens_reminder` items;
- the harness's continuation item "Output token limit hit. Resume directly
  ..." and "[Request interrupted by user]" after an API cut-off.

The scored run's other known item, a change in the authors' tool list
partway through the run, is removed rather than listed: every author must
have exactly Read, Write and `SubagentHandback`, checked by
`author_tools.py`, so a changed list refuses the run instead of voiding a
sample.

## Selection rule (fixed now)

For each candidate t, let `pass(t)` be the number of the six calibration
authors (three per arm) whose answer to t passed every hidden test within
two rounds, and `first(t)` the same count for round 1.

1. **Drop the floor.** A candidate no author passed in either arm
   (`pass(t)` = 0) is dropped: it would measure nothing.
2. **Rank.** The remaining candidates are ranked by `pass(t)`, lowest first;
   ties by `first(t)`, lowest first; remaining ties by the candidate's order
   in `candidates.py`.
3. **Select.** The first six are the next scored set, in their
   `candidates.py` order. If fewer than six remain, calibration stops
   there: there is no scored run from this pool.

Both arms count equally in `pass(t)`. Selecting on Python alone would
choose the tasks hardest in Python and lean the comparison toward Firth;
selecting on Firth alone would lean it toward Python. Summing both arms
keeps the selection blind to which language the difficulty is in. (Some
of a task's low count in calibration is chance, so the scored run's fresh
authors are expected to do somewhat better on the selected set in both
arms.)

## Stop rule after calibration (fixed now)

The scored run is not started if, on the six selected tasks, the three
calibration Python authors pass a mean of 5.5 tasks or more of 6 within two
rounds, the scored run's ceiling threshold. In that case the result goes
back to the maintainer as "these candidates do not take Sonnet's Python arm
off the ceiling", with the per-task counts, and no scored sample is run.

If the scored run does start, the calibration means of both arms on the
selected set are reported with `power.py`'s estimate for 12 Sonnet
authors per arm at those means, before the first scored sample.

## Fresh authors

Calibration authors are never scored, and their answers are never shown to
a scored author or folded into any prompt. The scored run's authors are new
sub-agents. Calibration results are not S7 evidence, and its Python and
Firth counts are not a comparison of the languages: they choose the set
and decide whether to run.

## What is recorded

In the run directory: `commit.txt`, the stdlib version, the two prompts,
`tool-probe.txt`, `author-tools.txt`, `agent-ids.txt`, each author's
answers, solutions, results and transcript, the audit and context scan
outputs, `run-notes.md`, and `selection.md`: `pass(t)` and `first(t)` per
candidate per arm, the ranking, the selected six and the stop rule's
outcome, computed by a script committed with it from the kept results only.

## Before the pin

- [ ] The maintainer chooses calibrate-then-select (coordinator's card).
- [ ] The hints PR has merged and the coordinator says the S7 inputs are
  settled.
- [x] #251 (the tool-probe notes) has merged (`d837ac2`).
- [ ] `candidates.py` merged with Python and Firth references, hand values,
  bounds, mutants and costliest inputs (this PR).
- [ ] The prompts built at the pin and committed with `commit.txt` and this
  file in the run directory.
