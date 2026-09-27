# S7 authoring experiment

The PRD's goal S7 exists to test Firth's core bet: that explicit stack
signatures make a language models can write well. This directory is a cheap,
repeatable measurement of that bet. A model that has only read the language
docs solves small tasks in Firth and in Python, and hidden tests score both.

## How it works

- `tasks.py` holds 22 tasks. Each has a description, its input and output
  shape, one visible example, 2 to 6 hidden test inputs and a Python reference
  that computes the expected stack. Values are non-negative integers and
  Booleans, the only values the portable runner can pass in or read back.
  Each task records the capabilities it `needs`. Eleven need only `prim +`,
  stack words, quotations and `if`; the other eleven need subtraction,
  comparison, multiplication or loops, which the runner does not have yet.
- `harness.py prompt` builds the author prompt. For Firth it contains
  `docs/getting-started.md` and `docs/firth-agent-guide.md` verbatim, then the
  tasks. Nothing from `src/`, `tools/` or `examples/` is included, so the
  prompt follows whatever the docs say at the time of the run.
- `harness.py score` runs every answer against the visible example and the
  hidden tests. Firth goes through `tools/loop/firth_run.py run`, so a pass
  also means the VM and the Lean reference interpreter agreed. A task passes
  only when every hidden test returns exactly the expected stack, with no
  Boolean/integer coercion.
- `harness.py repair` builds a second-round prompt showing each failing
  answer's result on the visible example only. Hidden tests are never shown.
- `classify.py` labels why each failed task failed. Tasks that need a
  capability the runner lacks are labelled `missing_primitive` by rule. The
  rest are sent to TypeSafe's Jev classifier (`jev-1.13.0`), which is cheap and
  fast but can only pick from fixed labels. Pass/fail never comes from Jev.
- `reference/firth-today.json` has hand-written Firth solutions for the eleven
  tasks that need only `prim +`, and `reference/firth-all.json` covers all 22
  for the build with the new primitives. They pass 11/11 and 22/22 and check
  the harness itself.
- `prompt --extra-doc FILE` appends a document after the repo docs. Run 2
  used `docs/primitives-pr113.md` because the repo docs had not yet been
  updated for the new primitives.
- `classify.py` also labels a failure `resource_limit` by rule when the run
  hit the step budget, a VM resource fault or overflow, so runtime limits are
  counted apart from authoring mistakes.

```sh
python3 eval/s7/harness.py prompt --lang firth > prompt.md
# give prompt.md to the author model; save its reply as answer.md
python3 eval/s7/harness.py extract answer.md > solutions.json
python3 eval/s7/harness.py score --lang firth solutions.json --label "firth sonnet" > results.json
python3 eval/s7/harness.py report results.json
python3 eval/s7/classify.py solutions.json results.json --available add > modes.json
```

The author model is run separately, as a sub-agent told to read only the
prompt file and to use no other tool. Each run directory keeps a trimmed
transcript (`transcript.json`): the model name, start and finish times, and
every tool call the author made, with written content reduced to a hash of
the `answer-*.md` next to it. In all 18 author sessions the only files read
were the prompt and repair files, and the only files written were the
answers. This is an instruction plus an audit, not a sandbox.

Each `results-*.json` records `firth_commit` (the build it was scored on) and
`prompt_docs` (the documents the author's prompt was built from). Failure
messages are kept in compact form: the VM trap class, and the checker's code,
message, expected and actual stacks and hint.

## Run 1: 27 September 2026, `prim +` only

Main at `c6b1a19`. Authors: Claude Sonnet 5 and Claude Haiku 4.5, one answer
per task, all 22 tasks in one prompt. Results and answers are in
`runs/2026-09-27-plus-only/`.

| | Firth, 11 runnable tasks | Firth, 11 tasks needing new primitives | Python, all 22 |
|---|---|---|---|
| Sonnet 5 | 11/11 | 0/11, and flagged all 11 as impossible | 22/22 |
| Haiku 4.5 | 7/11 | 0/11, and flagged all 11 as impossible | 22/22 |

Haiku got one repair round showing its four failing answers' errors on the
visible example. It then passed 10/11. The last failure, `count-true`, was a
real stack-reasoning mistake: it ran `if` three times in a row as though each
Boolean were still on top, and the checker rejected it with
`firth.type.expected-bool` before anything ran. Sonnet needed no repair.
`runs/2026-09-27-plus-only/report.md` has the per-task table.

What this does and does not show:

- The runnable tasks are easy. Python is at ceiling for both models, so the
  Python column only shows the tasks are fair, not that Firth is close to it.
- Sonnet wrote correct Firth first time using only the docs, and stayed
  within the documented profile. It avoided `locals` and used `dip`, `swap`
  and helper words. When it had to guess, it named the missing primitives
  `prim -`, `prim =`, `prim <`, `prim >`, `prim *`, `prim /` and `prim mod`.
- All four Haiku failures came from `locals`, not from stack reasoning. Three
  referenced a local inside a quotation, which the checker rejects with
  `firth.elaboration.unsupported-capture`; the docs do not mention that limit.
  One used `if` inside a `locals` body, which fails with
  `firth.type.quotation-input-mismatch` even when correct. A third gap came up
  while writing the references: selecting the topmost local twice fails with
  `firth.name.unbound-local`, although the guide says repeated `many`
  selections are copied. These are implementation bugs or undocumented limits
  in `src/`, reported to the Language core thread.
- Jev's labels were not reliable enough to use unreviewed. Before the rule for
  missing capabilities was added, it labelled the placeholder answers
  `stack_effect` with confidence up to 0.99, because the checker diagnostic
  dominated the input. On the four real Haiku failures it said `toolchain`
  three times at 0.29 to 0.53 confidence and `stack_effect` once at 0.70; a
  person reading them would say `toolchain` for all four. Use its labels to
  sort failures for review, not as findings.
- It says nothing yet about the bet on programs with arithmetic, comparison
  or loops. That needs the rerun below.

## Run 2: 27 September 2026, with `-`, `*`, `<`, `=` and tail calls

Run against draft PR #113 (`42f00a7`), which adds `prim -`, `prim *`,
`prim <`, `prim =` and tail calls. That branch had not yet updated the two
docs, so the prompt also carried `docs/primitives-pr113.md`: a primitive
table, the tail-call rule and the 4096-step budget, with no example programs.
New author sessions, all 22 tasks, then one repair round. Python results are
reused from run 1. Everything is in `runs/2026-09-27-pr113/`.

| | Firth, first try | Firth, after one repair | Python |
|---|---|---|---|
| Sonnet 5 | 20/22 | 21/22 | 22/22 |
| Haiku 4.5 | 5/22 | 11/22 | 22/22 |

- **Sonnet is close to Python.** Neither first-try miss was an authoring
  mistake. `majority` reused the topmost local, which is the checker's
  `unbound-local` bug. `collatz-steps` is correct but runs out of the 4096-step
  budget on n = 7, because halving has to be a loop without division. After
  the repair, the step budget is its only failure.
- **Haiku is far from Python.** Its first try failed in ways the docs warn
  against. It declared no inputs in four signatures, used the signature's
  value names as variables in five bodies, and put locals inside quotations in
  five more, which hits the checker's capture limit. It gave up on
  `is-even` and gave no answer for `collatz-steps`. After the repair its 11
  remaining failures were real stack mistakes. The checker rejected 6 of them
  before running (`expected-bool`, `branch-mismatch`, `occurs-check`). Four
  ran and returned wrong answers (`max`, `min3`, `gcd`, `collatz-steps`), and
  it still gave up on `is-even`.
- **What this says about the bet.** For a strong model, explicit stack effects
  plus a checker are enough to write small loops and arithmetic from the docs
  alone at nearly the Python rate. For a weaker model they are not. The
  checker catches most of its stack mistakes, but one round of diagnostics
  did not get it to fix them, while the same model wrote all 22 correctly in
  Python.
- **Jev.** On Haiku's post-repair failures its labels were plausible
  (`stack_effect` 7, `logic` 3, `stack_order` 1). It again called a known
  checker bug `invented_syntax` (Sonnet's `majority`, 0.45). It is useful for
  sorting failures, not as the record.

## Run 3: 27 September 2026, harder tasks, three attempts each

Nine harder tasks (`HARD` in `tasks.py`): sort3, median3, triangle-kind,
divmod, isqrt, is-prime, digit-sum, lcm, and one step of the inventory
allocator from `specs/inventory-allocation.md`. They need several cooperating
words and more stack juggling. Loop inputs are small because the step budget
is 4096. A loop over three locals cost about 120 steps per iteration in this
build, so a count-divisors task was dropped: no plain solution fitted.
`reference/firth-hard.json` passes 9/9.

Each model got three fresh author sessions per language. Firth attempts that
failed the visible example got one repair round. The repair showed the
checker's new plain-language `message`, `expected`, `actual` and `hint`
fields rather than the raw envelope. The prompt was built at PR #113
`a8c3337` with the primitives supplement; everything was finally scored at
`ecd724d`, which fixes the nested-`if`-in-`locals` bug the first scoring hit.
Results are in `runs/2026-09-27-hard/`.

| Passed out of 9 | Firth, first try | Firth, after one repair | Python |
|---|---|---|---|
| Sonnet 5, three attempts | 9, 9, 8 | 9, 9, 8 | 9, 9, 9 |
| Haiku 4.5, three attempts | 1, 0, 4 | 1, 2, 3 | 9, 9, 9 |

- **Sonnet matched Python except for one step-budget failure.** Its one miss in 27 was a correct `lcm` that ran
  out of steps on an input Python handles instantly (`resource_limit`). One
  attempt first scored 7/9 on `a8c3337` because correct nested `if`s inside
  `locals` hit a checker bug; after the Language core fix both passed
  unchanged. Sonnet took far longer to write Firth than Python: about 7 to 29
  minutes per attempt, against under 30 seconds.
- **Haiku failed badly in Firth and not at all in Python.** Across its three
  attempts after repair, 21 tasks failed:
  - 9 used syntax that does not exist. Five used primed names such as `q'`,
    which the lexer reports only as `firth.syntax.overlong-character`. Four
    called words they never defined.
  - 5 were stack-shape mistakes that the checker rejected before running
    (`branch-mismatch`, `occurs-check`, `quotation-compose-mismatch`).
  - 6 ran but gave wrong answers. Two attempts got `allocate` wrong when
    requested equals remaining, and there were off-by-one errors in `isqrt`
    and `is-prime`.
  - 1 nested a `locals` block inside a quotation, which is still unsupported.
- **The repair round barely helped Haiku** (5 to 6 of 27), even with the new
  error messages. One attempt got worse. Its first `sort3` error came from the
  since-fixed checker bug, and that bug's hint ("a `locals` block needs more
  values") sent it to strip out locals and break two other tasks. A misleading
  hint costs more than no hint.

## Rescore after the locals rework left PR #113

The locals fixes that run 3 was scored on were taken out of PR #113 at
`b958353`, after review found silent miscompiles in them. They will return
as a separate PR. Every stored Firth answer from runs 2 and 3 was rescored at
`b958353` with no new model calls. The results are in
`runs/rescore-pr113-b958353.json`.

- **Run 2 is unchanged.** All four attempts pass exactly the same tasks, so
  its numbers stand on #113 as it will merge.
- **Run 3 depends on the locals PR.** At `b958353`, Sonnet passes 3 of its
  27 tasks and Haiku passes none. Every task that stopped passing is now
  rejected by the checker (`unsupported-capture` for locals used inside `if`
  branches, `unbound-local` for reusing the top local). None of them run and
  give a wrong answer. These are counted as blocked on the locals PR, not as
  model failures. The nine reference solutions are blocked the same way.
- Run 3's table therefore holds only for a build with working locals. The
  locals miscompile may have let a wrong answer pass at `ecd724d`, and that
  can't be checked until the locals PR lands. Run 3 gets rescored then.

## What the three runs say about the bet

Explicit stack effects did not stop a strong model writing correct Firth from
the docs alone. Sonnet was at Python's level on every task set except for one step-budget
failure, and its only
failures were checker bugs and the step budget. They did not carry a weaker
model: Haiku wrote correct Python every time and mostly failed in Firth, in
ways the checker caught but Haiku could not repair. The checker found most
stack-shape errors before execution. Wrong answers at runtime were logic slips
that a signature cannot catch. So the bet holds for strong models and not yet
for weak ones, and the costs are real: Sonnet spent 20 to 100 times longer per
Firth attempt than per Python attempt. The run 3 half of that evidence waits
on the locals PR (see the rescore above).

## Limits and next steps

- Python is still at ceiling for both models on every task set, so these
  tasks measure Firth's cost relative to an easy baseline, not a hard one.
- Runs 1 and 2 used one sample per task, which is noisy: Haiku passed 7 of
  the easy tasks in run 1 and only 5 in run 2. Run 3 used three.
- The step budget still shapes the task set. Raise it, then add tasks with
  real loops (count-divisors, larger inputs) back.
- The repo docs now cover the new primitives (PR #113 `54387bd`), so the
  next run should drop the supplement and use the docs as they are.
