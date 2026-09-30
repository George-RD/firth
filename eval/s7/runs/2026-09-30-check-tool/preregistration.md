# Run 12 pre-registration: does running the checker help authors?

Written and committed before the first author starts. Nothing here changes
after the first answer is scored; any departure is reported as one.

## Question

Run 11's failure analysis (`eval/s7/README.md`, "Run 11 failure analysis")
found that most checker-visible mistakes in final answers never reached the
author:

- A final answer's own errors get no feedback, because the third answer is the
  last.
- Of the 52 failing final answers the checker offers an edit for, 38 had no
  edit shown on that task in either feedback round. Those 38 include 13 of
  the 15 answers the edits make pass (`causes/shown.txt`).
- When an edit was shown, the next answer applied it 141 of 170 times.
- The checker refused 195 of arm A's 246 failing final answers and 162 of
  arm B's 223 (`causes/rank.txt`).

Feedback arrives only twice, and only on the visible example. Run 12 asks
whether letting the author run the checker on its own answer file, as often
as it likes before each hand-in, raises how many MVP tasks Haiku passes. That
is how an agent would use Firth outside the eval, with the checker in its own
loop.

## Design

- **Two arms.** They differ in one tool, and in the sentences that grant it.
  - Arm A is run 11's arm A protocol, unchanged. Its prompt is
    `harness.py prompt --lang firth --tier mvp --rounds 2`, which is
    byte-identical to run 11's arm A prompt (checked with `cmp` at `6b0f482`).
  - Arm B's prompt is the same command with `--check-tool`. It replaces arm
    A's tool sentence with a paragraph that allows reading, writing and editing
    the answer file, and running
    `python3 /home/user/firth-r12/eval/s7/harness.py check --lang firth <your answer file>`.
    Nothing else in the prompt changes (`make_prompts.py --check`, whose
    self-test plants an extra word, a stale arm A and a command naming another
    harness).
- **What `check` does.** `harness.py check` reads the answer file, extracts
  every `### task:` block as scoring does, and checks each block with
  `tools/loop/firth_run.py check`.
  - For each task it prints `ok`, or the checker's diagnostics in the form
    feedback shows them (`compact` and `readable`: code, word, line and
    column, message, expected, actual, hint).
  - It runs no program. It never sees an example, an expected result or a
    hidden test. A planted program that checks but would trap when run reads
    `ok` (`test_mvp.py`).
  - It refuses an answer file that is a link.
  - A toolchain build failure stops it with a message saying so, not a
    diagnostic.
- **Instructions.** Each arm's author instructions are fixed in
  `instructions-templates.json`: the first dispatch and two feedback rounds.
  - Arm A's are run 11's word for word, with only the paths changed.
  - Arm B's name the same files, allow Read, Write and Edit of the answer
    file, and give the exact check command for that round's answer file.
  - `instructions.py --check` fails unless every author received exactly its
    arm's templates. Its self-test plants a swapped arm, an added hint and a
    missing round.
- **Build.** Both arms use one worktree, `/home/user/firth-r12`, detached at
  main's head when authoring starts (the pinned commit). It is never fetched
  or checked out during the run.
  - Both arms are scored, and arm B checks, with that worktree's harness and
    checker. So nothing that merges during the run reaches either arm.
  - The prompts in this directory were built in that worktree at this PR's
    head, since arm B's names the harness by its absolute path. At the pinned
    commit, `make_prompts.py --check` is run again. If it fails, authoring
    does not start, and this file is amended and reviewed again.
  - Before the first author starts, `pinned.txt` records:
    - the worktree's `git rev-parse HEAD`;
    - the output of `make_prompts.py --check`;
    - the SHA-256 of both prompts and of `instructions-templates.json`;
    - the `AGENTS.md` and `CLAUDE.md` blobs of the pinned commit and of the
      main checkout.
  - The toolchain is built in the worktree before any author starts, and a
    `check` of a scratch file there must print `ok`.
- **Author.** `claude-haiku-4-5-20251001`, as an Agent-tool sub-agent (model
  `haiku`) with no API key. Each author is started with the description
  `Run 12 author <arm><n>` and gives three answers: the first answer and two
  feedback rounds.
- **Sample size.** 20 counted samples per arm, as in run 11. The counted
  samples in an arm are its first 20 non-void samples by start order
  (`analyse.py` uses run 11's `counted()`, whose self-test plants a 21st
  sample).
  - No new sample starts in an arm once 20 of its non-void samples have
    started. After that, a sample starts only to replace one found void.
  - Authoring stops when both arms have 20 counted, fully scored samples. No
    test is run before then, and `analyse.py` refuses to print any statistic
    until then.
  - **Feasibility stop.** If 20 samples of either arm are void before that
    arm has 20 counted, authoring stops. The run is reported as not feasible
    under this protocol, with every sample's scores and no test.
- **Interleaving.** Samples start in the order A1, B1, A2, B2, and so on.
  - At most six authors run at a time, three per arm.
  - A void sample's replacement starts in the next slot of its own arm.
  - Samples are numbered `haiku-firth-1`, `haiku-firth-2`, and so on, in each
    arm in start order; a replacement takes the next number.
  - The driver counts non-void starts per arm from the directories before
    each start, not from memory. Run 11 started three arm A samples late
    after a miscount.
- **Scoring.** As in run 11:
  - `harness.py score --lang firth --tier mvp --jobs 4` in the worktree, with
    the build warmed first.
  - The harness stops on a toolchain failure. Results are also searched for
    toolchain text, and a round with any is rescored before its feedback is
    sent.

## Validity of a sample

A sample is void, and replaced, if any of these holds:

- **Audit.** `audit_subagent.py --rounds 2 --lang firth` flags any call
  (exit 1). Arm B's audit adds `--check-cmd
  /home/user/firth-r12/eval/s7/harness.py`.
  - Arm A may only: Read the arm's `prompt-firth.md` and the sample's own
    `repair-1.md` and `repair-2.md`; Write the sample's own `answer-1.md` to
    `answer-3.md`; and hand back. Rewriting an answer file with different
    content is flagged, as in run 11.
  - Arm B may also:
    - Read, Write and Edit its own `answer-1.md` to `answer-3.md`, as often
      as it likes. The writes and edits are replayed in order, and the file
      they leave must be the kept copy that was scored.
    - Run Bash with exactly `python3 /home/user/firth-r12/eval/s7/harness.py
      check --lang firth <its own answer-N.md>`: no other command, path,
      option or shell syntax, and not in the background.
  - `test_mvp.py` plants each of these, and the audit flags each one:
    - a check of another sample's answer;
    - a check through another harness;
    - a check followed by `; cat` of the hidden tests;
    - a check piped elsewhere;
    - a check of an answer past the round limit;
    - a background check;
    - the harness's `try`;
    - `ls`;
    - an edit of another file;
    - a kept answer that is not what the last write left;
    - an edit that cannot be replayed.
- **Toolchain.** A `check` output in the author's log reports a toolchain
  failure. The author was then shown no diagnostics, through no fault of its
  own. The toolchain is rebuilt before the next start.
- **Agent files.** An `AGENTS.md` or `CLAUDE.md` the author was shown is not
  the pinned commit's blob (`runs/2026-09-29-control/seen_agents.py` on the
  raw log: exit 0 and no `UNMATCHED`).
  - Authors are started from the main checkout `/home/user/firth`, which stays
    on this PR's branch.
  - That branch does not touch either file, and before authoring both blobs
    are checked equal to the pinned commit's.
- **Context.** `context_seen.py --arm-set run12 --arm <arm-a or arm-b>
  --sample haiku-firth-<n> --label <A or B><n>` reports a `cross_sample` item
  put into the author's context before its last answer was written.
  - An item counts as before when its `at` time is earlier than the author's
    last `Write` or `Edit` of `answer-3.md`. An item with no time counts as
    earlier.
  - Run 12's arm set flags, for arm A, arm B's run directory, the text
    `harness.py check`, and every clause of arm B's tool paragraph. For arm B,
    it flags arm A's run directory.
  - An item that arrives after the last answer cannot change a scored answer.
    It is reported, not voiding.
- **Answers.** The author did not write all three answers.

Void samples are reported with their scores and not counted. Validity is
judged on these rules alone, never on scores.

After each round, the audit and the scans run on the log so far. A sample
found void at any point is void. A sample's validity is final when they have
run on its complete log after its third answer is scored.

## Outcomes

`analyse.py` computes all of these with run 11's exact tests. Its self-test
runs run 11's, and plants a trap and a wrong value that must not read as
refusals. It also checks that refusal read from the results agrees with a
fresh check on all 800 of run 11's counted final answers.

- **Primary:** tasks passed after round 2 per counted sample (all cases of the
  task, `results-3.json`). One-sided exact Mann-Whitney U, arm B greater than
  arm A, at alpha 0.05.
- **Secondary 1:** checker runs per arm B sample, from its audited log, per
  answer file. Reported without a test, since arm A has none by design.
- **Secondary 2:** per sample, the share of answered tasks whose final answer
  the checker accepts (`results-3.json`, no case error carrying a checker
  code). One-sided exact Mann-Whitney U, B greater. This is the check tool's
  direct effect, so it works as the manipulation check.
- **Secondary 3:** tasks passed in the first answer per sample
  (`results-1.json`). One-sided exact Mann-Whitney U, B greater. Arm B's
  first answer is the only one where the tool is the sole difference, since
  feedback that follows depends on it.
- **Reported without a test:** samples passing at least one task after round
  2, with run 11's one-sided Fisher p.

## Reading the result

- **Primary significant and secondary 2 significant.** Letting the author run
  the checker raised Haiku's MVP passes at the pinned build.
  - This is a finding about the eval's protocol and the checker's value in an
    author's loop. It is not a change to the language.
  - Whether later runs give authors the checker is a separate decision, and
    it changes what runs 12 onward measure against runs 4 to 11.
  - It is not evidence for any other model.
- **Primary significant, secondary 2 not.** The gain is reported, but not
  attributed to answers that check.
- **Primary not significant.** Reported as inconclusive, with both arms'
  counts and the p value, never as "no effect".
  - If secondary 2 is significant, the write-up says that answers the checker
    accepts more often produced no gain in passes large enough to detect at
    20 per arm.
  - The power table below says how large that is.
- **Whatever the result.** Both arms' tables, the per-sample scores, every
  void sample and the checker runs are reported. Run 12's arm A is not pooled
  with run 11's arm A: the prompts match, but the builds differ, since #185
  changed the branch hints.

## Changes from the brief, and why

The brief (the coordinator's note starting this run) fixed the arms, the
primary and secondary outcomes, 20 per arm, the audit-based enforcement and
the context marker. These choices are mine:

- **The check command.** Arm B runs `harness.py check` on its answer file,
  not `tools/loop/firth_run.py check` on a `.firth` file.
  - The raw command prints one line of JSON: diagnostic envelopes with
    several kilobytes of `lean_repr` terms. That is a different format from
    the feedback both arms read. Arm B would then differ from arm A in two
    ways: when it sees checker output, and what that output looks like.
  - `harness.py check` shows the same `compact` view as feedback, over the
    whole answer file the author already writes. So the arms differ only in
    access to the checker.
  - The cost is transfer. A model using Firth outside the eval sees the raw
    line. That gap is filed as `todo.checker-cli-text-output`.
- **Arm B's reads, writes and edits.** Arm B may read and edit its own
  answer file. Checking and then fixing an answer needs both, and run 11
  voided 8 of its 9 void samples for rewriting or re-reading their own
  answer file. Arm A keeps run 11's rules unchanged, as the brief says.
- **Rejected: the harness's `try`.** It runs the program on the task's
  example and shows the expected result. The brief allows the checker only.
- **Added: a feasibility stop.** Bash is the call most likely to go outside
  the rules, and arm B's voids may outnumber arm A's by far.

## Power

`power.py` uses a fixed seed and 2,000 simulated runs per row, and takes about
8 minutes.

- Final passes are drawn from run 11's 20 counted arm A samples, whose prompt
  is the same as this run's arm A.
- An arm B sample then passes each task it failed with probability q.

| q | mean gain per sample | power, one-sided MWU, 20 per arm |
| --- | --- | --- |
| 0.00 | +0.0 | 0.05 |
| 0.05 | +0.7 | 0.12 |
| 0.10 | +1.2 | 0.23 |
| 0.15 | +1.9 | 0.34 |
| 0.20 | +2.4 | 0.49 |

- The model of the effect is a guess, and the real power may be lower.
- In run 11, making the offered edits turned 37 refused final answers into
  answers that check, and only 15 of them passed (`causes/recover.py`). So a
  large gain in answers that check can come with a small gain in passes.
- At 20 per arm, this run can detect a gain of about +2.4 tasks per sample
  half the time. A null result is read that way.

## Enforcement

Authors run with the after-the-fact audit only, as in runs 10 and 11. The
maintainer has not answered on a PreToolUse hook limiting authors to their own
files, so none is used, and no session settings or hooks are changed.
