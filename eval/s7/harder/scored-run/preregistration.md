# Harder tier, scored run: pre-registration

Written 10 October 2026, before any scored author has started and before
any scored task has been sent to a model. This file and `run-plan.md`
next to it fix the run. Neither is changed after the pin below; anything
learnt during the run is reported, not folded back in.

**Not yet pinned.** The run is option (a) on the maintainer's open
decision card, the scored head-to-head, which the card recommends. Under
the maintainer's standing instruction to proceed on the recommended option,
it goes ahead unless the maintainer answers otherwise. It starts only after
all of the following:
- the project's coordinator confirms that the S7 inputs are settled and
  freezes them (`docs/getting-started.md`,
  `docs/firth-agent-guide.md`, `examples/programs/README.md`, `AGENTS.md`);
- the prompts are built at one main commit and committed, with that
  commit, in the run directory `eval/s7/harder/runs/<date>-scored/`
  (`commit.txt`, `prompt-firth.md`, `prompt-python.md`), together with a
  copy of this file and `run-plan.md`.

That commit is the pin. Every author is scored at it, whatever merges
during the run.

## What it measures

S7 as written in `docs/roadmap.md`: is the pass rate materially higher in
Firth than on equivalent tasks in Python? Each subject gets the same six
tasks in both languages, and two measures are reported:
- correct on the first attempt (round 1);
- correct within two attempts (round 2).

Alongside them come the guarantees Firth adds (roadmap, "S7 baseline and
eval subjects") and whether the run showed any of them catching a real
error.

A result at the ceiling in both languages is parity. It does not meet S7
and is not called a pass. Measured and proved stay separate (`AGENTS.md`
rule 8): a step count from a run is a measurement, not a bound.

## Task set

The six tasks of `eval/s7/harder/scored.py` (`sokoban`, `checkers`,
`regex`, `swiss`, `warehouse`, `cache-sim`), as merged in #229 and
described in `eval/s7/harder/README.md`, "The scored set". None was run
in calibration and no model has seen them. The set is frozen: no task,
description, hidden test or bound changes after this file is merged.

If the set lands at the ceiling anyway, the result is reported as it
stands and the set is not edited or replaced
(`todo.s7-harder-task-tier`).

## Subjects and samples

| Subject | Role | How it runs | Python | Firth |
| --- | --- | --- | --- | --- |
| Sonnet 5.5 | primary | Agent-tool sub-agent, type `general-purpose`, model `sonnet` | 8 | 8 |
| DeepSeek v4.1 Flash | secondary | `deepseek_sample.py`, ollama.com chat API, the connected key | 5 | 5 |
| Haiku 5.5 | secondary, how learnable for a small model | Agent-tool sub-agent, type `general-purpose`, model `haiku` | 5 | 5 |

- That is 36 valid samples in all, and every sample answers all six tasks.
- Sonnet, the primary subject, runs 8 per arm for power ("Analysis",
  "Sample size"). DeepSeek and Haiku run 5 per arm; every comparison is
  within one subject, so their smaller rows cost samples and dilute nothing.
- Samples are named `<subject>-<lang>-<n>`, for example `sonnet-firth-3`.
- The roadmap and `todo.s7-harder-task-tier` name Haiku 4.5. The Agent
  tool offers only `haiku`, which runs Haiku 5.5, so Haiku 4.5 cannot be
  run as a sub-agent here. The Haiku 5.5 row therefore does not meet the
  criterion "Haiku 4.5 stays as a secondary check"; that line stays open
  for this reason, and the criterion is not changed. Each transcript's
  recorded model id is reported.
- The sub-agent type and model are those calibration used for Sonnet. The
  repository's `s7-author` agent belongs to run 14 and is not used.
- They run one at a time, with no other author or worker running in the
  session, in the order `run-plan.md` fixes. The order alternates the two
  language arms within each subject, and runs the subjects in turn, so a
  slow period or an outage falls on both arms.

## How a sample runs

**Sonnet and Haiku (sub-agents).** The tier's sub-agent protocol
(`eval/s7/harder/README.md`, "Protocol").
- `tier.py prompt` builds the prompts once, at the pin.
- The author is started with this text, with the paths filled in:

  > You are the author in a programming evaluation. Use only two tools:
  > Read, to read the file PROMPT, and Write, to write your answer to
  > DIR/answer-1.md. Do not read, list or search any other file, run no
  > commands, and do not use the internet. Read the prompt file (in chunks
  > if it is long), follow its instructions, and write all your answers in
  > the format it asks for to that one answer file. Write the answer file
  > once, when it is complete. Then stop and reply "done".

  This is the calibration text plus one sentence, "Write the answer file
  once, when it is complete.", added because the audit voids an author
  who writes its answer file twice with different content (pool 3's
  Firth 3). The audit rule is kept as it stands. It is not loosened after
  the fact, and the same sentence goes to both arms.
- `tier.py take` builds `solutions-1.json`, and `tier.py score` scores it.
- If any task has no answer or failed its visible example, `tier.py repair`
  writes `repair-1.md`, and the same author is sent this message:

  > Feedback round 1 of 1: read DIR/repair-1.md, which shows how your
  > answers did on each task's example. Write revised answers, only for
  > the tasks listed there and in the same format as before, to
  > DIR/answer-2.md. The same rules apply: only those two tools, no other
  > files, no commands. Write the answer file once, when it is complete.
  > Then reply "done".

- `tier.py take --after` builds `solutions-2.json`. It takes only the tasks
  the feedback listed; an answer to any other task is not taken, and is
  named. Round 2 is then scored. This differs from the MVP tier's protocol,
  and from this tier's calibration as run, which took every task in a
  round-2 answer (README, "Protocol").
- An author whose answers all passed their examples gets no round 2. Its
  result within two attempts is its round-1 result.

**DeepSeek.** `deepseek_sample.py --set scored --lang LANG PROMPT DIR`, as
merged in #234 and #235 (README, "DeepSeek"):
- The same prompt file is sent as the user turn. In round 2, the
  conversation so far is sent again, with `repair-1.md` as the next turn.
- The same `tier.py` steps apply (`take`, `score`, `repair`), so the
  listed-only rule is the same as for a sub-agent.
- The API's defaults are used for every parameter. Each request is kept
  as `request-N.json` and each whole reply as `response-N.json`.
- A round is asked once and never retried.

## Outcomes

Each task in each round is passed (every hidden test passes) or failed.
A failure is reported under one of these causes:
- no answer;
- a Firth answer the checker refuses;
- a wrong result;
- a runtime error;
- **out of steps**, a Firth run that uses up the 1,000,000-step budget;
- a timeout (300 seconds per Firth case, 30 per Python case);
- a reply cut off at the length limit (DeepSeek only, below).

Out of steps is its own category, reported per task as well as overall.
Python answers have no step budget, only the 30-second timeout. So a
correct but slow Firth answer can fail where the same algorithm in Python
passes. A natural `Seq Bool` design for `regex` measured up to 816,497 of
the 1,000,000 steps on the scored inputs; the reference uses 98,097
(README, "The scored set"). Such a loss is reported as out of steps,
never as a wrong answer.

**DeepSeek length cut-off.** A reply cut off at the length limit
(`deepseek.py` exit 2) is a failed answer, not a void, and is not replaced
(coordinator's decision of 10 October 2026, under the maintainer's
delegation; `todo.s7-harder-task-tier`). Nothing in a cut-off reply is
taken:
- **Round 1.** Every task counts as unanswered. The feedback round lists
  every task and says the reply was cut off.
- **Round 2.** The sample keeps its round-1 results.

The rule is the same on both arms.

## Voids, crashes and replacement

A sample is void when:
- the audit (`eval/s7/harder/audit.py --set scored`) flags a call, a
  write or a rebuilt file in its transcript;
- the context scan below finds an item not listed as known;
- for DeepSeek, a round is void (`deepseek.py` exit 3: a failed request,
  any status but 200, a reply that is not a complete chat reply from the
  scored model). A void round voids the whole sample;
- for DeepSeek, round 1's `prompt_eval_count` in `response-1.json` is
  below one token per eight characters of what was sent. That is half the
  rate the probe measured (91,647 characters read as 22,632 tokens), so a
  prompt the server cut short counts as a transport void. The rule is not
  applied to round 2: `prompt_eval_count` counts only the prompt tokens
  the server evaluated, and round 2 repeats round 1's whole prompt as its
  prefix, so a server that reuses a cached prefix can report only the new
  tokens and void a round 2 nothing cut. The probe was one uncached
  request, so it cannot rule this out. Round 2's `prompt_eval_count` is
  still reported.

A sample is **crashed** when the run stopped part way: `outcome.json`
status `crashed` for DeepSeek, or a sub-agent that ended without handing
back. A crash is replaced like a void, and counted with the voids
(coordinator's decision of 10 October 2026).

A crash caused by an author's answer is different: the scorer or the
harness failing on what the model wrote. That is a harness bug. The run
stops, the bug is fixed in its own reviewed PR, and the sample is scored
again from its kept answers at the fixed commit, which is recorded. It is
never silently replaced.

**Replacement.**
- A void or crashed sample keeps its number, and is reported with its
  cause.
- Its replacement takes the next unused number for the same subject and
  language, and runs at the end of the plan, in the order the voids
  happened.
- Replacement stops for a cell (one subject and language) at 3 voids and
  crashes. That cell then has fewer than its planned samples, and the subject's
  comparison is reported as incomplete, not as a result.
- Voids and crashes are counted per arm and by cause:
  - audit flag;
  - context;
  - transport (a DeepSeek request or reply);
  - crash.

  If a subject's voids and crashes differ between its two arms by 2 or
  more, the report says so beside that subject's result, because then the
  samples that survived may differ between arms.

**No early stop on results.** A stop is allowed only:
- on void or crash status as above;
- on a crash caused by an answer;
- on a toolchain failure (`ToolchainError`), which stops scoring.

## Context

What each author sees besides its prompt is fixed here.
- **Sub-agents** also see the session's system prompt, tool list and
  reminders, including the repository's `AGENTS.md` through `CLAUDE.md`
  (an S7 input), and read the prompt with a tool.
- **DeepSeek** sees only the prompt text, and in round 2 its own earlier
  reply and the feedback.

Every comparison in this run is between Python and Firth for one subject,
where both arms see the same context. The Firth-minus-Python difference is
**not** compared across subjects. So the context is stated, not equalised.

Sub-agent authors are started from a session with no queued project
message, and are not given the project's messages.

Each sub-agent's raw log is scanned:
- by `eval/s7/context_seen.py --sample <name>`, which compares whole sample
  names (#230). The statement that run 14's results are unchanged by that
  whole-name comparison holds only for logs that name no `sonnet-` or
  `deepseek-` sample;
- by a search for every other sample's name, agent id and directory,
  `task_status`, task notifications, compaction and `queued_command`.

Authors carry no A/B label. They are named only by their sample name, so
the label check (`LABEL`) does not apply and is not used.

**Known injected items** name no author, are the same for every sub-agent
author, and do not void a sample:
- the session's system prompt, tool list and reminders, as above;
- the session hook's `hook_non_blocking_error` items (pools 2 and 3: two
  per round, `omega-memory` not found);
- the harness's continuation item "Output token limit hit. Resume
  directly ...", and "[Request interrupted by user]" after an API cut-off
  (pool 3, `runs/2026-10-10-calibration3/scan-output.txt`). A sample shown
  one still counts.

Any other injected item, a project message, or another author's name or id
voids the sample.

## A reading nobody listed

The hidden tests define each task's meaning (`scored.py`). An answer that
fails a hidden test because it took a sentence of the description another
way still fails. The steps are fixed:
- **Detection.** Every failed hidden test is traced to the rule it turns
  on, and the report lists any failure whose answer follows a different
  reading of that rule's sentence.
- **Ruling.** The project's independent reviewer rules whether the
  sentence, as written, admits that reading. The person who wrote the task
  does not rule.
- **No exclusion in the main result.** The main result keeps every task as
  scored. If the reviewer rules that a sentence admits the reading, the
  report also gives the result with that task left out for every sample of
  that subject, in both languages. That second result is a sensitivity
  check, never the headline. The sentence is filed as a todo, and the set
  is not edited.

## Analysis (fixed now)

**Per subject and language:**
- tasks passed in round 1 and within two rounds, per author and in total;
- each failure's cause (above), per task;
- answer lengths in characters;
- for DeepSeek, each round's `prompt_eval_count` and `done_reason`.

**Per subject, the S7 question:**
- **Primary measure.** The difference in mean tasks passed per author
  within two rounds, Firth minus Python. Round 1 is the secondary measure.
- **Tests.** A two-sided exact permutation test over the authors' labels
  (every way to split the subject's authors between the arms: 12,870 for
  Sonnet's 8 and 8, 252 for 5 and 5), and a 95% percentile
  bootstrap interval for the difference (10,000 resamples within each
  arm, seed 0).
- **Material.** A difference of at least 1 task of 6 per author, with the
  interval excluding 0 and p below 0.05. Only that counts as materially
  higher in Firth. A difference that is material the other way is
  reported as Python higher.
- **Unpaired, and why.** The test treats the authors as exchangeable
  across arms, so time effects during the run are assumed small next to
  the arm effect. The run plan's same-number pairs are a scheduling
  convenience, not matched units: each author is independent, and a
  replacement breaks the pair. A within-pair permutation over 5 pairs has
  only 32 assignments, so its smallest two-sided p is 0.0625, and no
  result could reach p below 0.05 for DeepSeek or Haiku. As a check on time effects, the report
  gives each arm's results in run order.
- **Sample size.** The chance that this rule finds a material difference,
  simulated by `power.py` next to this file (binomial tasks, 2,000
  replicates, seed 0; output in `power-output.txt`), for a true mean of 5.5
  tasks in the higher arm:

  | True difference | 5 per arm | 8 per arm |
  | --- | --- | --- |
  | 1 task (4.5) | 0.20 | 0.40 |
  | 1.5 tasks (4.0) | 0.42 | 0.74 |
  | 2 tasks (3.5) | 0.67 | 0.93 |

  So Sonnet's row has about 0.75 power only for a true difference near 1.5
  tasks, and DeepSeek's and Haiku's about 0.67 only near 2 tasks. For a
  true difference of 1 task, the smallest material one, power is 0.40 for
  Sonnet and 0.20 for the others; because the observed difference must
  itself reach 1, it stays near 0.5 or below at any size this run could
  afford. Calibration put Sonnet's Python answers at or near the ceiling
  (pools 1 and 3: every author passed every task), so the ceiling rule may
  decide Sonnet's row whatever the sample size. A difference that is not
  material is reported with its interval, and is not evidence of parity
  beyond that interval.
- **Ceiling.** If both arms of a subject average 5.5 tasks or more of 6
  within two rounds, that subject's row is parity at the ceiling, never a
  pass.
- **Floor.** If both arms of a subject average 0.5 tasks or fewer of 6
  within two rounds, that subject's row is parity at the floor, never a
  result either way.
- **Haiku** is a secondary check. Its row is reported the same way, but S7
  is judged on Sonnet, the primary subject. DeepSeek's row shows whether
  the result holds for a non-Anthropic model.

**The guarantees.** For each Firth answer that the checker or the runtime
refused on its visible example, the report says what was caught (a type
or stack-effect error, linearity, a declared effect, the step budget). A
refusal counts as catching a real error only when the author's corrected
answer behaves differently on some hidden test. The rest are reported as
refusals.

These numbers are computed by a script committed with the results, which
reads only the run directory's kept files. Each file is listed with the
outputs that need it:
- `results-N.json`: tasks passed per round, each failure's cause (the
  per-case error, out of steps included), the per-author means, the S7
  difference and its tests, the ceiling and floor rules, and the guarantees (a
  refusal on the visible example in round 1, and whether round 2's
  answer behaves differently on a hidden test);
- `answer-N.md`: answer lengths;
- `outcome.json` (DeepSeek): each round's verdict, length cut-offs, void
  and crash status with its cause, and answers not taken in round 2;
- `response-N.json` (DeepSeek): `prompt_eval_count`, for the
  truncated-prompt void and the report, and `done_reason`;
- `request-N.json` (DeepSeek): the characters sent, for the
  truncated-prompt rule;
- `transcript.json` (sub-agents): audit flags, which are void causes, and
  a sub-agent that ended without handing back, a crash;
- the run directory's context scan output: context voids.

The void and crash counts per arm and by cause come from `outcome.json`,
`response-N.json`, `request-N.json`, `transcript.json` and the context
scan output.
Its permutation test and bootstrap are checked against a hand-worked
example in its own test.

## Before the pin

- [ ] No answer from the maintainer choosing otherwise than option (a).
- [ ] Coordinator confirms the S7 inputs are settled and freezes them;
  asked before the prompts are built.
- [x] `scored.py` merged with references, hidden tests, hand values,
  mutants and bounds checks covering order constraints (#229, #231).
- [x] `context_seen.py` compares Sonnet and DeepSeek sample names whole
  (#230).
- [x] DeepSeek driver and sample runner merged, with planted replies and
  one end-to-end run (#232, #233, #234), and the listed-only round-2 rule
  shared by both paths (#235).
- [x] The take rule checked on all 18 calibration samples (#237).
- [ ] Prompts built at the pin and committed with `commit.txt`, this file
  and `run-plan.md` in the run directory.
