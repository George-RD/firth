# Run 13 pre-registration: does running the checker help authors? (retry)

Written and committed before the first author starts. Nothing here changes
after the first answer is scored; any departure is reported as one.

## Question

Run 13 asks run 12's question again. Does letting Haiku run the checker on
its own answer file, as often as it likes before each hand-in, raise how many
MVP tasks it passes?

Run 12 (`eval/s7/README.md`, "Run 12") stopped early for feasibility and has
no result:

- All 8 of its arm B samples were void. 2 were toolchain voids, from a PATH
  fault fixed during the run. 6 were rule voids, B1 among them: it worked
  round the fault with `source ~/.elan/env`.
- Of arm B's 91 Bash calls, only 8 were the allowed command exactly as
  written. Most of the rest added `2>&1`, piped the output to `grep`, `head`
  or `tail`, or began with `cd /home/user/firth-r12 &&`. None of them
  reached another sample's files or the hidden tests.

Run 13 changes three things, and nothing else about the question:

- It asks arm B to run the command exactly as written.
- It allows a closed set of harmless forms of that command.
- It makes the start-order analysis co-primary.

## Design

- **Two arms.** They differ in one tool, and in the sentences that grant it.
  - Arm A is run 12's arm A protocol, unchanged. Its prompt is `harness.py
    prompt --lang firth --tier mvp --rounds 2` at the pinned commit. At
    `e381708` that is byte-identical to run 11's and run 12's arm A prompts
    (SHA-256 `9251deb1…`). #195 (comparison primitives, merged as
    `a74f498`) changes `docs/getting-started.md` and
    `examples/programs/README.md`, so both arms' prompts changed with it and
    run 13's arm A is no longer run 12's: it is run 12's arm A prompt plus
    #195's text on `<=`, `>` and `>=` (SHA-256 `116198b3…` at this PR's
    head; arm B's is `ade31f79…`).
  - Arm B's prompt is the same command with `--check-tool`. That is run
    12's arm B prompt with one sentence added after "It does not run your
    programs.":

    > It already prints everything, so run it exactly as written: add no
    > `2>&1`, no pipe such as `| head` or `| grep`, no redirection and no
    > `cd`.

    - `make_prompts.py --check` fails unless arm B differs from arm A only in
      the tool paragraph, and that paragraph names this checkout's harness
      and carries that sentence. Its self-test plants an extra word, a stale
      arm A, another harness, and run 12's paragraph without the sentence.
    - Run 12's `make_prompts.py --check` now fails at main, as intended:
      run 12's arm B prompt, which lacks the sentence, is kept in its run
      directory and was checked at its pinned commit (`pinned.txt`).
- **What `check` does.** Unchanged from run 12:
  - It checks each `### task:` block of the answer file and prints `ok` or
    the diagnostics in feedback's form.
  - It runs no program and never sees an example or a hidden test.
- **Instructions.** Each arm's author instructions are fixed in
  `instructions-templates.json`: the first dispatch and two feedback rounds.
  - Arm A's are run 12's, with only the paths changed.
  - Arm B's are run 12's with the same sentence added to the first message,
    and "Run it exactly as written." added to each feedback round.
  - `instructions.py --check` fails unless every author received exactly its
    arm's templates. Its self-test plants a swapped arm, an added hint, a
    missing round, and checks that every arm B template carries the
    sentence.
- **Build.** Both arms use one worktree, `/home/user/firth-r13`, detached at
  main's head when authoring starts (the pinned commit). It is never fetched
  or checked out during the run.
  - The pin comes after #195 (merged as `a74f498`), so the run measures the
    language with `<=`, `>` and `>=`.
  - Both arms are scored, and arm B checks, with that worktree's harness and
    checker, so nothing that merges during the run reaches either arm.
  - The prompts in this directory were built in that worktree at this PR's
    head, since arm B's names the harness by its absolute path. At the pinned
    commit, `make_prompts.py --check` is run again. If it fails, authoring
    does not start, and this file is amended and reviewed again.
  - Before the first author starts, `pinned.txt` records:
    - the worktree's `git rev-parse HEAD`;
    - the output of `make_prompts.py --check`;
    - the SHA-256 of both prompts and of `instructions-templates.json`;
    - the `AGENTS.md` and `CLAUDE.md` blobs of the pinned commit and of the
      main checkout;
    - the Lake and Lean versions, both in the driver's shell and under
      `env -i` with the authors' default PATH.
  - The toolchain is built in the worktree before any author starts. A
    `check` of a scratch file must print `ok` there.
- **Preflight.** Run 12's PATH fault voided three samples. So before every
  arm B start, the driver runs the check on a scratch file in the authors'
  own default shell. It must print exactly `## sum-list` then `ok`. The
  output is logged in `driver/state.md` against the sample it precedes. If
  it prints anything else, no author starts until the toolchain is fixed.
- **Author.** `claude-haiku-4-5-20251001`, as an Agent-tool sub-agent (model
  `haiku`) with no API key. Each author is started with the description
  `Run 13 author <arm><n>` and gives three answers: the first answer and two
  feedback rounds.
  - Every started sample gets both feedback rounds and has its third answer
    scored, whether or not it has been found void. Run 12 stopped a void
    sample's rounds, which would score a sample voided in round 1 on its
    first answer and the rest on their third, so co-primary 2 would measure
    when voids are found. The one exception is a toolchain void whose
    scoring stopped; co-primary 2 leaves those out.
  - A sample found void keeps its slot until its third answer is scored.
    Its replacement starts in its arm's next free slot.
- **Sample size.** 40 counted samples per arm, as in run 12, whose power
  table this run shares (see "Power"). The counted samples in an arm are its
  first 40 non-void samples by start order.
  - No new sample starts in an arm once 40 of its non-void samples have
    started. After that, a sample starts only to replace one found void.
  - Authoring stops when both arms have 40 counted, fully scored samples. No
    test is run before then, and `analyse.py` refuses to print any statistic
    until then.
- **Early feasibility look.** The look is taken once, when the first 10 arm
  B samples by start order, not counting toolchain voids, all have final
  validity (see "Validity of a sample"), and every sample started before the
  10th of them does too. `analyse.py --early-look` reports that it is not
  taken yet until then, and then reads their void status. Once those samples
  are final their void status cannot change, so the reading cannot either,
  and when it is read cannot decide it. Authoring continues while it waits.
  - If 6 or more of those 10 are audit voids, authoring stops.
  - It counts only rule voids the audit found (`rule: audit` in `void.md`,
    whatever else the sample broke), since it asks whether arm B's authors
    keep to the allowed forms. A sample void only for context, such as the
    harness's `task_status` lines, is not counted here; secondary 5 reports
    those. The stop ends both arms, so it cannot favour either. The run is
    reported as not feasible under this protocol, with every sample's scores
    and no test.
  - The look reads void status only, never a score. Its self-test plants 5
    audit voids (continue), a toolchain void (not counted), a context void
    (not counted), 6 audit voids, one of them also a context void (stop), a
    sample in the window without `final.md` (not taken yet), and
    fewer than 10 starts (not taken yet).
  - Run 12's arm B had 6 rule voids in 6 such starts. At that rate, 40
    counted samples would need far more starts than the 40-void stop
    allows. This look ends a run like that after 10.
  - The look is logged in `driver/state.md` as run 12's stop was: the time,
    the output of `analyse.py --early-look` (which names each of those
    samples and its void status), and a statement that no score was read for
    the decision. The run continues or stops on that reading only.
- **Feasibility stop.** If 40 samples of either arm are void before that
  arm has 40 counted, authoring stops, as in run 12.
- **Interleaving.** Samples start in the order A1, B1, A2, B2, and so on.
  - At most six authors run at a time, three per arm.
  - A slot left free in one arm does not go to the other arm. When arm B's
    three slots are busy, arm A waits, so the arms stay in step. In run 12,
    arm A ran five samples ahead because its authors were quicker.
  - A void sample's replacement starts in the next slot of its own arm.
  - Samples are numbered `haiku-firth-1`, `haiku-firth-2`, and so on, in each
    arm in start order; a replacement takes the next number.
  - The driver counts non-void starts per arm from the directories before
    each start, not from memory.
- **Scoring.** As in run 12: `harness.py score --lang firth --tier mvp
  --jobs 4` in the worktree, with the build warmed first. The harness stops
  on a toolchain failure. Results are also searched for toolchain text, and
  a round with any is rescored before its feedback is sent.

## Validity of a sample

A sample is void, and replaced, if any of these holds:

- **Audit.** `audit_subagent.py --rounds 2 --lang firth` flags any call
  (exit 1). Arm B's audit adds `--check-cmd
  /home/user/firth-r13/eval/s7/harness.py --shell-forms`.
  - Arm A may only: Read the arm's `prompt-firth.md` and the sample's own
    `repair-1.md` and `repair-2.md`; Write the sample's own `answer-1.md` to
    `answer-3.md`; and hand back. Rewriting an answer file with different
    content is flagged.
  - Arm B may also Read, Write and Edit its own `answer-1.md` to
    `answer-3.md`, as often as it likes. The writes and edits are replayed in
    order, and the file they leave must be the kept copy that was scored.
  - Arm B may also run Bash with `python3
    /home/user/firth-r13/eval/s7/harness.py check --lang firth <its own
    answer-N.md>`, not in the background. With `--shell-forms`, that command
    may carry these additions, in this order and nothing else:
    - the prefix `cd /home/user/firth-r13 && `;
    - the suffix ` 2>&1`;
    - one pipe to `head -n N`, `head -N`, `tail -n N` or `tail -N`, or to
      `grep`, with options only from `-n -i -v -c -E -A N -B N -C N` and one
      quoted pattern;
    - after that `grep`, at most one more pipe to `head` or `tail` as above;
    - trailing spaces.
  - The pattern may not start with `-`. In double quotes it may not contain
    a backquote, a backslash may come only before one of `| ( ) . ^ $ [ ]`,
    and `$` only before `"` or `|`, so the shell expands nothing. Everything
    else is flagged, including:
    - a file operand, or any other option (`-f`, `-r`, `--include`);
    - an option hidden in a quoted pattern (`"-r"`);
    - a third pipe, or a `grep` after `head`;
    - `;`, `&&` or `||` anywhere except that `cd` prefix, and a `cd` to any
      other directory;
    - `$(`, a variable, a backquote or an escaped quote;
    - `<`, `>` or `>>`, including a redirect to `/tmp`;
    - any command that is not the check.
  - In double quotes this is stricter than refusing only `$(`, `${` and
    `$name`: every `$` that is not the pattern's last character or before
    `|` is refused, so `"^ok$"` is allowed (planted) and `"$1"` is not.
  - `test_mvp.py` plants 17 allowed forms. Each passes with `--shell-forms`
    and is flagged without it, which is run 12's rule, kept as the default.
    It plants 26 refused forms, each flagged with `--shell-forms`, among them
    all those listed above, `grep -f .../mvp_tasks.py`, `grep "x"
    /some/file`, `| head; cat x` and `cd /eval && <check>`. Run 12's
    plants are all kept: another sample's answer, another harness, a
    background check, the harness's `try`, `ls`, an edit of another file, a
    kept answer not left by the last write, and an unreplayable edit.
- **Toolchain.** A `check` output in the author's log reports a toolchain
  failure. The author was then shown no diagnostics, through no fault of its
  own. The toolchain is fixed and the preflight passes before the next start.
- **Agent files.** An `AGENTS.md` or `CLAUDE.md` the author was shown is not
  the pinned commit's blob (`runs/2026-09-29-control/seen_agents.py` on the
  raw log: exit 0 and no `UNMATCHED`).
  - Authors are started from the main checkout `/home/user/firth`, which is
    not pulled or reset while authoring is under way.
  - Before authoring, both blobs are checked equal to the pinned commit's.
- **Context.** `context_seen.py --arm-set run13 --arm <arm-a or arm-b>
  --sample haiku-firth-<n> --label <A or B><n>` reports a `cross_sample` item
  put into the author's context before its last answer was written.
  - An item counts as before when its `at` time is earlier than the author's
    last `Write` or `Edit` of `answer-3.md`. An item with no time counts as
    earlier.
  - Run 13's arm set flags, for arm A, arm B's run directory, the text
    `harness.py check`, and every clause of arm B's tool paragraph, the new
    sentence included (`context_seen.py --self-test`). For arm B, it flags
    arm A's run directory.
  - This includes the harness's own `task_status` lines naming another
    author, which reached three run 12 authors (planted in
    `context_seen.py --self-test` for both arms). They are counted per arm
    and reported, whether or not they void a sample.
  - Preventing them was considered first. The harness sends them to a
    running sub-agent when another sub-agent of the same session changes
    state (inferred from run 12's times, not documented). Preventing that
    means one author at a time, so about 80 or more samples of 5 to 17
    minutes each, one after another, or one session per author, which the
    driver cannot start. So the rule above stays and applies to both arms
    alike: an item before the last answer voids the sample, and one after
    it is reported. The count per arm is secondary 5.
  - An item that arrives after the last answer cannot change a scored
    answer. It is reported, not voiding.
- **Answers.** The author did not write all three answers.

As in run 12:

- A tool call whose result is marked as an error changed nothing. It is not
  replayed and does not void the sample, though its path and command are
  still checked. Only a `tool_result` in a user-type event, carrying that
  call's id, marks a call as failed.
- In both arms, every kept `answer-N.md` must have been made by a successful
  Write or Edit in the author's log.
- Every `void.md` starts with `rule:` or `toolchain:`, then the reason, and
  `analyse.py` refuses any other. After `rule:` come the rules the sample
  broke, comma-separated from `audit`, `agent-files`, `context` and
  `answers` (the headings above), then `:` and the reason, for example
  `rule: audit, context: ...`. `analyse.py` refuses a rule void without
  them (planted).
- Void samples are reported with their scores and not counted. Validity is
  judged on these rules alone, never on scores.
- After each round, the audit and the scans run on the log so far. A sample
  found void at any point is void. A sample's validity is final when they
  have run on its complete log after its third answer is scored. The driver
  then writes `final.md` in its directory with the time, and the early look
  reads only samples that have one.
- Every arm B Bash command is kept verbatim in the sample's
  `bash-calls.json` (`driver/bash_calls.py extract`, run 12's script with
  run 13's paths). The audit shortens a flagged call in `transcript.json`,
  and run 12's first counts taken from those shortened strings were wrong.

## Outcomes

`analyse.py` computes all of these with run 11's exact tests, as in run 12.

- **Co-primary 1:** tasks passed after round 2 per counted sample (all cases
  of the task, `results-3.json`). One-sided exact Mann-Whitney U, arm B
  greater than arm A, at alpha 0.05.
- **Co-primary 2 (start order):** tasks passed per sample by the first 40
  samples started in each arm, in start order, with rule voids kept and
  scored on their third answer like every other sample (`results-3.json`),
  and toolchain voids left out. `analyse.py` refuses a sample in this set
  with no scored third answer.
  One-sided exact Mann-Whitney U, B greater, at alpha 0.05.
  - Arm B has more ways to break a rule, so its voids may be more numerous or
    fall on weaker authors. Dropping them could then favour arm B. This
    analysis keeps them.
  - The void count per arm, by kind, is reported with it.
- **Secondary 1:** checker runs per arm B sample, from its audited log, per
  answer file. Reported without a test. The number of allowed calls that
  used each added form (`2>&1`, `head`, `tail`, `grep`, the `cd` prefix) is
  reported with it.
- **Secondary 2:** per sample, the share of answered tasks whose final answer
  the checker accepts. One-sided exact Mann-Whitney U, B greater. This is the
  manipulation check.
- **Secondary 3:** tasks passed in the first answer per sample
  (`results-1.json`). One-sided exact Mann-Whitney U, B greater.
  - Run 12's void arm B samples passed 50 tasks in 8 first answers, against
    arm A's 1 in 11. That was not a test: the samples were void and the
    arms were not started evenly. This outcome tests it.
- **Secondary 5:** per arm, the samples whose context scan found the
  harness's `task_status` line naming another author, and how many of them
  are void. Reported without a test (`status_leaks`, planted in the
  self-test).
- **Reported without a test:** samples passing at least one task after round
  2, with run 11's one-sided Fisher p.

## Reading the result

- **A gain is claimed only when both co-primaries are significant**, arm B
  greater (`gain_claimed`; its self-test plants each one alone). `analyse.py`
  prints the verdict.
  - If only one is significant, the result is reported as depending on which
    samples were voided, and no gain is claimed.
  - If the two point in opposite directions, `analyse.py` says so.
- **Gain claimed and secondary 2 significant.** Letting the author run the
  checker raised Haiku's MVP passes at the pinned build.
  - This is a finding about the eval's protocol and the checker's value in an
    author's loop. It is not a change to the language.
  - Whether later runs give authors the checker is a separate decision.
  - It is not evidence for any other model.
- **Gain claimed, secondary 2 not.** The gain is reported, but not
  attributed to answers that check.
- **No gain claimed.** Reported as inconclusive, with both arms' counts and
  both p values, never as "no effect".
- **Whatever the result.** Both arms' tables, the per-sample scores, every
  void sample, the checker runs and the forms they used are reported. Run
  13's arm A is not pooled with run 12's or run 11's.

## Changes from run 12, and why

The coordinator decided the reworded sentence, the widened forms, the
refused list, the plants and the co-primary. These choices are mine:

- **`head -N` and `tail -N`** are allowed as well as `-n N`. Run 12's
  authors mostly wrote `head -100`, and neither spelling takes a file
  operand.
- **A second pipe after `grep`, and `\|` in a double-quoted pattern.** As
  first decided, the forms would still have voided every one of run 12's
  five rule-void samples: 30 of the 91 calls stay refused, even with
  `head -N` allowed. This is a counterfactual, applied by hand and not
  scored.
  - Most of the 30 were a `grep` then a `head` (for example `2>&1 | grep -E
    "^## |^ok$|^code:" | head -50`), or `\|` alternation inside a
    double-quoted pattern, which the shell passes to `grep` unchanged.
  - With both allowed, and trailing spaces, 13 calls stay refused, 7 of
    them B1's and B3's during the PATH fault. B4 and B8 would not have been
    void. B5, B6 and B7 would still be void, for a `grep` of their own
    answer file, a `grep` piped to a second `grep`, an option after the
    pattern, and a heredoc, a redirect to `/tmp` and an `ls`.
  - I proposed this to the coordinator when writing it.
  - The rejected easier option was to allow any command that only reads the
    checker's output. It would need a shell parser whose soundness nobody
    could check from the diff, and a mistake in it would let a call read the
    hidden tests. A closed set of exact forms can be checked by reading one
    regular expression and its plants.
- **Arm A waits for arm B's slots**, so the arms stay in step. Run 12's arm A
  ran ahead, which made start order and arm confounded in its partial data.
- **An early feasibility look after 10 arm B starts**, pre-registered, in
  place of run 12's early stop, which was a departure decided mid-run.
- **The preflight is part of the protocol**, not a mid-run fix.

## Power

Run 12's `power.py --n 40 --runs 1000` table, for co-primary 1:

| q | mean gain per sample | power at 40 per arm |
| --- | --- | --- |
| 0.00 | +0.1 | 0.05 |
| 0.05 | +0.7 | 0.20 |
| 0.10 | +1.2 | 0.32 |
| 0.15 | +1.8 | 0.58 |
| 0.20 | +2.5 | 0.76 |

- With no voids, the two co-primaries test the same 40 samples per arm, and
  this table is the power to claim a gain.
- Voids make the two sets differ, and requiring both can only lower the
  power to claim a gain. That was not simulated.
- The model of the effect is run 12's guess, and the real power may be
  lower.

### Feasibility

The run can complete only if the new sentence cuts arm B's rule voids well
below run 12's. Applied by hand to run 12's arm B calls, the final forms
leave 3 audit voids (B5, B6 and B7) among the 6 samples whose checks ran,
before any effect of the sentence; B5 and B6 are also void for `task_status`
lines. So the rule-void rate to expect without an effect is about 0.5, and
there it is about a coin flip whether the run completes. Treating each arm B
start as void independently at a fixed rate (binomial and negative binomial,
computed exactly):

| rule-void rate | P(early look stops) | P(40 voids before 40 counted) | expected arm B starts for 40 counted |
| --- | --- | --- | --- |
| 0.3 | 0.05 | 0.00 | 57 |
| 0.4 | 0.17 | 0.04 | 67 |
| 0.5 | 0.38 | 0.50 | 80 |
| 0.6 | 0.63 | 0.96 | 100 |

The expected starts ignore both stops. Co-primary 2's power at a high void
rate was not simulated.

## Enforcement

Authors run with the after-the-fact audit only, as in runs 10 to 12. The
maintainer has not answered on a PreToolUse hook limiting authors to their own
files, so none is used, and no session settings or hooks are changed.
