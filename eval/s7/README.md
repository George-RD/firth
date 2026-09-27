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
prompt file and to use no other tool. The transcripts were checked afterwards:
each author read the prompt file and wrote its answer, and did nothing else.
This is an instruction plus an audit, not a sandbox.

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

## Limits and next steps

- The tasks are still small and single-purpose, and Python is at ceiling for
  both models, so the Python column does not separate the models. Add harder
  tasks (several cooperating words, the inventory allocator's shape) where
  Python is not perfect.
- One sample per task per model is noisy. Haiku passed 7 of the easy tasks in
  run 1 and only 5 in run 2 with near-identical prompts. Run several samples
  per task and report the spread.
- Rerun once the three `locals` bugs are fixed and the step budget is raised,
  using the repo docs alone with no supplement.
