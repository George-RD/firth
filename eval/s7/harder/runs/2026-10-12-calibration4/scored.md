# Harder tier, next scored run: pre-registration

Written 12 October 2026, before any calibration author has run and before
any candidate task has been sent to a model. It fixes the next scored run:
its subjects, samples, order, outcomes, voids and analysis. The task set is
the six candidates that `calibration.md` selects; this file is written
before that selection is known, so nothing in it is fitted to calibration
results. It is not changed after the pin below; anything learnt during the
run is reported, not folded back in.

**Status: draft. Not pinned. No author has run.** The run starts only when
everything in "Before the pin" is met.

Where this file says a section of `../scored-run/preregistration.md`
applies, it means that section as pinned on 11 October 2026 in
`runs/2026-10-11-scored/`, with the set's name and the sample counts
replaced by this file's. That file is frozen, so its text cannot drift
under this one.

## What it measures

S7 as written in `docs/roadmap.md`: is the pass rate materially higher in
Firth than on equivalent tasks in Python? Each subject gets the same six
tasks in both languages, and two measures are reported:
- correct within two attempts (round 2), the primary measure;
- correct on the first attempt (round 1), the secondary measure.

Alongside them come the guarantees Firth adds (roadmap, "S7 baseline and
eval subjects") and whether the run showed any of them catching a real
error. A result at the ceiling in both languages is parity. It does not
meet S7 and is not called a pass. Measured and proved stay separate
(`AGENTS.md` rule 8).

## Task set

The six candidates `calibration.md` selects from
`eval/s7/harder/candidates.py`, by its selection rule, with their
descriptions, hidden tests and bounds as merged in #253. No task,
description, hidden test or bound changes after calibration starts. If
calibration selects fewer than six, or its stop rule finds the selected
six at Sonnet's Python ceiling, this run does not start, and that outcome
is reported instead (`calibration.md`, "Stop rule after calibration").

If the selected set lands at the ceiling anyway, the result is reported as
it stands and the set is not edited or replaced.

What the set leaves out is stated in `calibration.md` ("The Firth step
budget shaped the set"): compute-heavy tasks and tasks with large values.
The report repeats it beside the result.

## Subjects and samples

| Subject | Role | How it runs | Python | Firth |
| --- | --- | --- | --- | --- |
| Sonnet 5.5 | primary | Agent-tool sub-agent, type `s7-harder-author`, model `sonnet` | 12 | 12 |
| DeepSeek v4.1 Flash | secondary, the non-Anthropic check | `deepseek_sample.py`, ollama.com chat API, the connected key | 8 | 8 |

- That is 40 kept samples planned, and every sample answers all six tasks.
- Samples are named `<subject>-<lang>-<n>`, for example `sonnet-firth-3`.
- Haiku is not run. In the 11 October run its Firth cell reached the void
  cap with 2 of 5 samples and its row was not a result
  (`runs/2026-10-11-scored/results.md`); the coordinator's design of
  11 October 2026 drops it from this tier. The roadmap's line on Haiku
  4.5 stays open, as before, and is not changed.
- Calibration authors are never scored here, and none of their answers is
  shown to an author of this run.
- They run one at a time, with no other author or worker running in the
  session, in the order "Run order" fixes.

## How a sample runs

**Sonnet (sub-agents).** The tier's protocol (`README.md`, "Protocol"),
with the author tool set, steps 1 to 4 (`README.md`, "Author tool set"):
the agent type `s7-harder-author` and nothing else, the working directory
fixed before the first author, the tool probe (`author_tools.py --probe`
must print `ok` before the first sample) and the per-author record
(`author_tools.py --ids --cwd` after each author). The author is started
with the text in `../scored-run/preregistration.md`, "How a sample runs",
and round 2 runs as that section says: `repair-1.md`, the same author, only
the listed tasks taken. An author whose answers all passed their examples
gets no round 2.

**A refused tool record.** If `author_tools.py` refuses, the run stops
before the next author. The refused author is void with cause "tool list",
and the run resumes only after the cause is found and fixed in its own
reviewed change. A tool-list void counts against its cell like any other
void.

**DeepSeek.** `deepseek_sample.py` as in
`../scored-run/preregistration.md`, "How a sample runs", streamed as
merged in #246, with the same prompt file as the Firth or Python
sub-agents. A round is asked once and never retried.

## Outcomes

As in `../scored-run/preregistration.md`, "Outcomes": each task in each
round passes (every hidden test passes) or fails, and a failure is
reported under exactly one cause: no answer, a Firth answer the checker
refuses, a wrong result, a runtime error, out of steps (the 1,000,000-step
budget), a timeout (300 seconds per Firth case, 30 per Python case), or a
reply cut off at the length limit (DeepSeek, with that section's rule).

One count is added, reported beside the causes and never changing a score:
**constant answers**, a task's answer that gives the same result on every
hidden test while the meaning's results differ across them. In the
11 October run 7 of 8 DeepSeek Firth authors hard-coded constants
(`runs/2026-10-11-scored/results.md`); the count shows whether that recurs.

## Voids, crashes and replacement

The causes of a void and of a crash are those of
`../scored-run/preregistration.md`, "Voids, crashes and replacement", with
one more void cause, "tool list" (above), and with the known injected
items of "Context" below. A crash caused by an author's answer is a harness
bug and stops the run as that section says.

**Replacement.**
- A void or crashed sample keeps its number and is reported with its
  cause.
- Its replacement takes the next unused number for the same subject and
  language, and runs after the last planned sample, in the order the voids
  happened.
- The first, second and third void or crash in a cell (one subject and
  language) are replaced. A fourth is not: the cell then has fewer than its
  planned samples, and that subject's comparison is reported as
  incomplete, not as a result.
- Voids and crashes are counted per arm and by cause (audit flag, context,
  tool list, transport, missing prompt count, crash). If a subject's two
  arms differ by 2 or more, the report says so beside its result.

**No early stop on results.** A stop is allowed only on void or crash
status as above, on a crash caused by an answer, on a refused tool record,
and on a toolchain failure (`ToolchainError`).

## Context

- **Sub-agents** see the session's system prompt, tool list and reminders,
  including the repository's `AGENTS.md` through `CLAUDE.md` (an S7
  input), and read the prompt with a tool. Their tools are exactly Read,
  Write and `SubagentHandback`, checked as above.
- **DeepSeek** sees only the prompt text, and in round 2 its own earlier
  reply and the feedback.
- Firth answers run beside a copy of `stdlib/`, so they may import
  `stdlib/core.firth` (`README.md`, Files, `tier.py`); Python answers have
  Python's builtins. The context is stated, not equalised, and the
  Firth-minus-Python difference is not compared across subjects.

Each sub-agent's raw log is scanned as in
`../scored-run/preregistration.md`, "Context" (`context_seen.py --sample`
and the search for every other sample's name, agent id and directory).
The known injected items are those listed in `calibration.md`, "Known
injected items", recorded in `runs/2026-10-11-tool-probe/notes.md`. Any
other injected item, a project message, or another author's name or id
voids the sample.

## A reading nobody listed

As in `../scored-run/preregistration.md`, "A reading nobody listed":
every failed hidden test is traced to its rule, the independent reviewer
rules on any other reading, and a task the ruling admits is left out only
in a sensitivity result beside the headline, never in it.

## Analysis (fixed now)

As in `../scored-run/preregistration.md`, "Analysis (fixed now)", for each
subject, with these sample sizes:
- **Primary measure:** the difference in mean tasks passed per author
  within two rounds, Firth minus Python; round 1 is the secondary measure.
- **Tests:** the two-sided exact permutation test over the authors' labels
  (2,704,156 splits for 12 and 12, 12,870 for 8 and 8), and a 95%
  percentile bootstrap interval (10,000 resamples within each arm, seed 0).
- **Material:** a difference of at least 1 task of 6 per author, the
  interval excluding 0 and p below 0.05; the same the other way is
  reported as Python higher.
- **Ceiling and floor:** both arms at 5.5 or more of 6 within two rounds
  is parity at the ceiling; both at 0.5 or fewer is parity at the floor.
  Neither is a result either way.
- **S7 is judged on Sonnet.** DeepSeek's row shows whether the result
  holds for a non-Anthropic model.

**Sample size.** `power.py` next to this file simulates the rule
(binomial tasks, 2,000 replicates, seed 0; `power-output.txt`):

| True means (higher arm vs lower) | 8 per arm (DeepSeek) | 12 per arm (Sonnet) |
| --- | --- | --- |
| 5.5 vs 4.5 (1 task) | 0.40 | 0.54 |
| 5.5 vs 4.0 (1.5 tasks) | 0.76 | 0.90 |
| 5.5 vs 3.5 (2 tasks) | 0.93 | 0.99 |
| 5.75 vs 4.38 (1.37 tasks) | 0.74 | 0.90 |

**The effect size this run is powered for** is the gap the 11 October run
measured for Sonnet on the first attempt, Python 5.75 against Firth 4.38
(`runs/2026-10-11-scored/results.md`): at 12 per arm the rule finds a
true gap of that size with power 0.90. It is underpowered for a gap of one
task, the smallest material one (0.54 at 12 per arm, 0.40 at 8). So a
result that is not material, where the true gap may be near one task, is
not evidence of parity. Calibration is there to
choose tasks where Sonnet's Python arm sits below the ceiling; if it does
not, the ceiling rule decides the row whatever the sample size. A
difference that is not material is reported with its interval and is not
evidence of parity beyond it. The calibration means on the selected set,
with `power.py`'s estimate at those means, are reported before the first
scored sample (`calibration.md`).

**Voids beside every result.** Each subject's row gives its voids and
crashes per arm and by cause, next to its difference, so a lopsided void
pattern is visible where the result is read.

**The guarantees, and sorting a case's error:** as in
`../scored-run/preregistration.md`, with its table of diagnostic codes. If
none of the six tasks has a Lean cost contract, the report says that no
proved bound applies.

The numbers are computed by a script committed with the results, which
reads only the run directory's kept files, as that section lists, plus
`author-tools.txt` and `tool-probe.txt`. Its permutation test and bootstrap
are checked against hand-worked examples in its own test, with planted
bugs it must reject.

## Run order

One sample at a time. In rounds 1 to 8 each subject runs both arms back to
back and the subjects take turns; rounds 9 to 12 run Sonnet only. Python
goes first in odd rounds and Firth in even ones. Replacements run after
sample 40, in the order the voids happened.

1. `sonnet-python-1`, 2. `sonnet-firth-1`, 3. `deepseek-python-1`,
4. `deepseek-firth-1`,
5. `sonnet-firth-2`, 6. `sonnet-python-2`, 7. `deepseek-firth-2`,
8. `deepseek-python-2`,
9. `sonnet-python-3`, 10. `sonnet-firth-3`, 11. `deepseek-python-3`,
12. `deepseek-firth-3`,
13. `sonnet-firth-4`, 14. `sonnet-python-4`, 15. `deepseek-firth-4`,
16. `deepseek-python-4`,
17. `sonnet-python-5`, 18. `sonnet-firth-5`, 19. `deepseek-python-5`,
20. `deepseek-firth-5`,
21. `sonnet-firth-6`, 22. `sonnet-python-6`, 23. `deepseek-firth-6`,
24. `deepseek-python-6`,
25. `sonnet-python-7`, 26. `sonnet-firth-7`, 27. `deepseek-python-7`,
28. `deepseek-firth-7`,
29. `sonnet-firth-8`, 30. `sonnet-python-8`, 31. `deepseek-firth-8`,
32. `deepseek-python-8`,
33. `sonnet-python-9`, 34. `sonnet-firth-9`,
35. `sonnet-firth-10`, 36. `sonnet-python-10`,
37. `sonnet-python-11`, 38. `sonnet-firth-11`,
39. `sonnet-firth-12`, 40. `sonnet-python-12`.

## The pin

Calibration's prompts are built at one main commit, after the hints PR
merges, and committed in `runs/<date>-calibration4/` (`calibration.md`,
"Pin"). This run is pinned at the merge of the selection PR, which adds
the selected six as a set the tools can name, the analysis script, and
this file's copy in `runs/<date>-scored2/`. That PR changes nothing but
files under `eval/s7/harder/`; the checker, `stdlib/` and the S7 inputs
(`docs/getting-started.md`, `docs/firth-agent-guide.md`,
`examples/programs/README.md`, `AGENTS.md`) must be identical to the
calibration pin, checked by `git diff --quiet` between the two commits on
`src/`, `stdlib/` and those four files, with the output in the run
directory. If any of them differs, the calibration result is stale
(`calibration.md`) and this run does not start from it.

## Before the pin

- [ ] Calibration completed under `calibration.md`, its selection made and
  committed (`selection.md`), and its stop rule passed.
- [ ] The selection PR merged: the selected set nameable by `tier.py`,
  `audit.py` and `deepseek_sample.py`, and the analysis script with its
  self-test.
- [ ] The S7 inputs, `src/` and `stdlib/` identical to the calibration pin
  (above).
- [ ] The prompts built at the pin and committed with `commit.txt`, this
  file and the input check's output in the run directory.
