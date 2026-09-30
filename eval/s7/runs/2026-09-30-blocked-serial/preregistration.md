# Run 14 pre-registration: does running the checker help authors? (blocked calls, one author at a time)

Not final. Prompts are not built, nothing is pinned and no author has
started. This file and the author agent file merge first, and the hook
half of the smoke test (see "Smoke test") then runs in a fresh session:
a session loads only the agent files present when it starts, and a fresh
session starts from `main`. The smoke's result, any change it forces, the
built prompts and `pinned.txt` go in the pin PR, and no author of the run
starts until that PR is approved and merged. Nothing here changes after
the first answer is scored; any departure is reported as one.

## Question

Run 14 asks runs 12 and 13's question again. Does letting Haiku run the
checker on its own answer file, as often as it likes before each hand-in,
raise how many MVP tasks it passes?

Run 13 (`eval/s7/README.md`, "Run 13") stopped at its early look with no
result:

- 7 of its first 10 arm B samples were audit voids. The audit refused 25
  calls: 8 shell forms outside the allowlist, 2 Reads of the harness's saved
  copy of the author's own checker output, and 15 others, mostly `grep`,
  `ls`, `wc` or `tail` of the author's own answer. None reached another
  sample's files or a hidden test.
- The context rule fell on arm B only (7 of 10 samples, arm A 0). Every
  `task_status` line naming another author arrived within 35 ms of a
  context compaction of the author that received it, and only arm B
  authors, whose context filled with checker output, were compacted
  (inferred from the logs, not documented).

Run 14 changes three things, and nothing else about the question:

- **Blocking.** An off-list call is stopped before it runs and is not a
  void. Both arms get the same hook.
- **One author at a time.** A session runs one author at a time, so a
  compaction has no other author to list. Several sessions run in
  parallel, each with both arms in a fixed, blocked order.
- **Forms.** Run 13's forms of the check command, with `$` also allowed
  before `)` in a grep pattern (3 of B7's refusals were `"^(## |ok$)"`).

## Design

Unchanged from run 13 (`../2026-09-30-check-forms/preregistration.md`)
except where this section says otherwise: the two arms, their prompts
(rebuilt at the pinned commit), what `check` does, the instructions, three
answers per author, scoring, the sample size (40 counted per arm), the
outcomes and how they are read.

### Blocking

- A project skill, `.claude/skills/s7-author-hook`, registers a
  `PreToolUse` hook for the rest of the session once the runner invokes it
  (runbook step 2). The hook sees every call in the session but decides
  only for calls whose hook input has `agent_type` `s7-author`, the agent
  definition every author is started with; every other call, the runner's
  own included, passes untouched (exit 0, no output). Both arms' authors
  are started with that agent type, so they have the same tools available
  and the same hook; the arms still differ only in their prompts.
  (Amended before any author started; see "Amendment" below.)
- The hook runs `eval/s7/author_hook.py --state STATE --only s7-author`,
  guarded by a test that the script exists. The driver writes
  STATE before it starts each author: the arm's prompt, the sample's
  directory, the rounds, the check command (arm B) or none (arm A), and the
  hook log's path.
- The hook decides with `audit_subagent.allowed`, the function the audit
  itself uses, with run 14's forms. A call on the list runs as before. Any
  other call is denied with the same reason in both arms, which the author
  sees: "This call is not allowed in this evaluation, so it did not run.
  Use only the tools, files and command your instructions name." A denial
  is exit code 2 with that reason on stderr, which becomes the stopped
  call's result. Every decision is logged with the call's `tool_use_id`.
- The hook fails closed on anything it can catch: a state or input it
  cannot read, and an audit it cannot import (the import runs inside the
  hook's `try`). It denies in the same way, with the same reason. A crash or
  a timeout it cannot catch lets the call run: Claude Code's hooks
  documentation (`code.claude.com/docs/en/hooks`, read 30 September) says
  an exit code other than 0 or 2 is a non-blocking error, and a timed-out
  `PreToolUse` command hook does not block the call. The audit then flags the call, which voids the
  sample, and the void is reported under its own cause, "hook failure".
  Such failures grow with the number of calls, so they would fall mostly
  on arm B. The explicit timeout below is 30 seconds, and a decision takes
  under a second (0.6 seconds measured, including Python's start).
- **Registered, or no author.** A hook that is not registered would let
  every call run, so `session.py` checks it before any author starts. The
  hook records each call it passes as not an author's in `seen.jsonl`
  beside STATE, and `hookcheck` and `next` stop (`STOP:`) unless that file
  records the very Bash call that is running them: a record of that
  command from the last 30 seconds, newer than the record the session's
  previous check used (kept in the session's `state.json`), so an earlier
  call's record, such as that of a `next` that stopped and is retried,
  cannot stand in for this one. The hook fires before a call runs, so a
  new record is there if and only if the hook is registered for this call. If the script is missing the guarded
  command exits 1, a non-blocking error, and records nothing, so this
  check stops the session. The hook check (runbook step 2) then shows an
  author's off-list call stopped. Planted in `session.py --self-test`: no
  record, one 45 seconds old, another session's, an author's own call, a
  missing file, and the record the previous check already used (5 seconds
  old) each make `hookcheck` and `next` stop. Planted in
  `author_hook.py --self-test`: the runner's calls and another sub-agent
  type's pass and are recorded; an author's off-list call is denied, and
  an author's call with no STATE file is denied; the skill's own command
  line, run by a shell with its paths pointed at a scratch directory,
  exits 0 for the runner, 2 with the mark for an author's off-list call,
  and 1 with the script missing.
- **The skill** is `.claude/skills/s7-author-hook/SKILL.md`, and `setup`
  checks that the main checkout's copy is the pinned one. Authors may see
  it in their session's skill list, beside the repository's `cairn-*`
  skills; that is the same in both arms, and the hook denies an author's
  `Skill` call, which is off the list.
- **The agent file** is `.claude/agents/s7-author.md` in the pinned
  worktree, exactly as follows. It has no `tools` line, so the author has
  the tools a `general-purpose` author had in run 13. Its body replaces
  that agent's system prompt in both arms alike and says nothing about the
  tasks:

  ```
  ---
  name: s7-author
  description: An author in the S7 evaluation. Started only by the S7 eval driver.
  model: haiku
  ---
  You are an author in a programming evaluation. Follow the instructions
  you are given.
  ```
- The audit (`audit_subagent.py --hook-log`) keeps a stopped call in the
  trimmed log, marked `blocked`, and does not flag it. A call counts as
  stopped only when the hook log denied its id and the author's log shows
  the hook's mark in that call's result. Flagged, and so voiding: a call
  off the list that was not stopped (the hook failed), a denial the
  author's log does not show, a marked result the hook did not deny, and a
  call on the list that the hook stopped.
- Planted in `author_hook.py --self-test` (18 calls in arm B, 5 in arm A,
  a missing state file, unreadable input, and, run as a process, a denial,
  an allowed call and a copy of the hook beside an `audit_subagent.py`
  that cannot be imported, which must exit 2 with the mark) and in `test_mvp.py` (each half
  of the stopped-call evidence alone, a stopped call on the list, run 14's
  `$)` form allowed while run 13's forms still flag it, and `"ok$x"`,
  `"$(id)"` and `"$HOME"` still flagged). Run 13's 20 raw logs re-audited
  with the refactored audit give the same trimmed logs, apart from the new
  `blocked_calls` count (0).
- Blocked calls per sample and per arm are reported (secondary 6). Arm B
  can make more blockable calls than arm A. That is not a void, so it
  cannot void one arm, but a block costs the author a turn, which is part
  of arm B's treatment as run.
- **The maintainer's go-ahead.** The maintainer wrote "go ahead with the
  S7 author agent file and its PreToolUse hook" in the S7 thread at
  16:41Z on 30 September. The file is `.claude/agents/s7-author.md`,
  byte for byte the text above. Those words named the agent file's hook;
  the amendment moves the same hook, with the same decisions, into a skill.
- **Amendment (30 September, 17:40Z, before any author started).** As
  merged in #200, the hook was in the agent file's frontmatter. The first
  hook-half smoke (below) showed it never ran: Claude Code does not use a
  project sub-agent's frontmatter hooks in a session that has not accepted
  workspace trust, and a `claude -p` or SDK session never shows the trust
  dialog (`code.claude.com/docs/en/permissions`, "What runs before you
  trust a folder", read 30 September; the same table says a project
  skill's hooks are used there). A cloud session is such a session. The
  hook's command, its decisions, its log and the audit are unchanged; what
  changed is how it is registered (the skill), that it passes non-author
  calls (`--only`), the registration check, and the frontmatter's `hooks`
  block, removed so that nothing else decides an author's calls. The
  easier option, dropping the hook and relying on the audit alone as run
  13 did, was rejected: run 13's arm B lost 7 of its first 10 samples to
  voids, and blocking before a call runs is this run's fix for the audit
  half of that.
- **Open.** Whether a skill's `PreToolUse` hook fires for a sub-agent's
  tool calls with `agent_type` set is not stated in the documentation
  read; the hook-half smoke checks it. If it does not, `hookcheck` stops
  the session and no author is scored.

### One author at a time, in parallel sessions

- 5 sessions, each running one author at a time, both arms. With no other
  author of the same session running, a compaction lists no other author.
  Each session is its own container, so no author sees another session's
  authors.
- **Order.** Each session runs blocks of two samples, one per arm, in this
  order. Each session has four `AB` blocks and four `BA` blocks, shuffled
  with Python `random.Random(14)`, one `shuffle` per session, sessions 1 to
  5 in turn, so each arm goes first in half of every session's blocks:

  | Session | Blocks 1 to 8 |
  |---|---|
  | s1 | AB AB AB BA BA BA BA AB |
  | s2 | BA BA AB AB AB AB BA BA |
  | s3 | BA BA AB AB AB AB BA BA |
  | s4 | BA AB AB AB BA BA AB BA |
  | s5 | AB AB BA BA BA BA AB AB |

  Blocks beyond 8 are needed only to replace voids, and a session starts
  one only when the driver says so. The driver draws each one's order from
  the same generator, continued after the five shuffles:
  `choice(("AB", "BA"))`, one draw per extra block in the order the driver
  assigns them, and records the draw in `driver/state.md` before the block
  starts.
- **Start order across sessions.** Samples are ordered by block, then
  session, then position in the block. The counted samples in an arm are
  its first 40 non-void ones in that order, and co-primary 2 takes the
  first 40 started ones. 5 sessions of 8 blocks start exactly 40 per arm.
- **Time.** Run 13's active author times were arm A 3.5 to 6 minutes and
  arm B 6 to 32, about 17, plus 1 to 2 minutes of scoring a round. A
  session's 8 blocks take about 3.5 hours.
- **Session effect.** Every session runs both arms in the same number, so a
  session effect cannot favour one arm. Per-session sums are reported
  without a test.

### Validity

As run 13, with these changes:

- **Audit.** Arm B's audit adds `--check-cmd <pinned harness>
  --run14-forms`, and both arms add `--hook-log <session hook log>`.
- **Context.** Unchanged. `context_seen.py` still scans every author's
  log, including for anything that names another session. It now also
  counts compactions per author, reported per arm as a descriptive
  covariate (secondary 5).
  - A compaction also puts back context that an uncompacted author saw
    only once: `AGENTS.md` and `CLAUDE.md` (the agent-files check covers
    their blobs), the session's user and organisation details, its URL
    and attribution lines, and the sub-agent system prompt (seen in the
    smoke author's compaction at 06:08:35Z on 30 September). None of it is
    task or sample data. `AGENTS.md` and `CLAUDE.md` are not new to a
    compacted author: every author in both arms gets them as an
    `instructions` attachment when it starts (run 13's A1 and B3, and the
    smoke author, each at the seventh line of its log), and again as
    `nested_memory` when it reads a file in the worktree. So a compaction
    repeats guidance both arms already have; it adds none. Since mainly arm
    B compacts, this is reported with the covariate, not as a void.
  - In the smoke, one arm B author compacted with no other author running,
    and the compaction carried no `task_status` line.
- **Edit replay.** The rule exists so that the scored answer is tied to
  the author's own calls: the audit replays an author's writes and edits
  and requires the result to be the kept copy that was scored. Arm A has
  the same rule in its Write form (each answer's hash must match the kept
  copy); only arm B can Edit, so the replay form, "an edit of it could not
  be replayed", can fall only on arm B, which the design rule forbids for
  a rule that could void one arm. It cannot be made symmetric, since arm A
  has no edits to replay, and it stays a void, because an answer the audit
  cannot rebuild from the author's calls has an unchecked origin. Runs 12
  and 13 replayed 523 Edit calls (188 in run 12's 8 arm B samples, 335 in
  run 13's 10), and none failed (no `could not be replayed` in either
  run's files). **Triage:** if one fails, the driver checks whether the
  replayer is at fault (for example curly quotes, noted in the audit's
  docstring). If it is, the replayer is fixed with a planted case, both
  arms' samples are re-audited, and the change is recorded as a
  departure. Three things keep it from biasing the result. It is reported
  with the voids by cause, per arm. Co-primary 2 (inherited from run 13)
  keeps every rule void, this one included, scored on its third answer,
  and a gain is claimed only when both co-primaries are significant, so a
  void that falls on arm B alone cannot produce the claim. And any edit
  replay void goes to the driver as a departure, with the replay failure
  shown, before the next early look or analysis.
- **Stop and review.** If `context_seen.py` finds a `cross_sample` item
  in any sample's log, authoring stops in every session after the current
  sample. Nothing starts again until the item's source is found and the
  remedy is recorded as a departure. This reads void status only. It
  catches run 13's mechanism the first time it comes back, not at the
  early look.
- **Early look.** Taken once, when the first 10 arm B samples in the start
  order above all have final validity. If 6 or more are rule voids of any
  cause, authoring stops in every session. With blocking, an audit void
  means the hook failed. The look reads void status only.

### Runbook for each session

**Runner and driver.** Each of the 5 sessions is a thread session of this
project run by Sonnet 5.5, the same model in all five; a session run by any
other model is a departure. Its authors are Haiku, as in every run. The
driver is the S7 thread's own session (the one that wrote this file). It
receives every `STOP:` line, decides departures and the early look, copies
the results from the shared folder into this run directory, and runs the
analysis there. The runner follows this runbook exactly and makes no
judgment of its own: every choice is made by `session.py` in this
directory, which prints what to do next.

Commands name the runner script by its full path,
`/home/user/firth-r14/eval/s7/runs/2026-09-30-blocked-serial/session.py`,
written `session.py` below. `SESSION` is the session's name (`s1` to `s5`)
and `PIN` the pinned commit, both given in the session's brief.

1. **Setup.** Run each of these with the Bash tool, one at a time. The
   build can take longer than one Bash call allows, so run the third with
   `run_in_background: true` and wait for it to finish; no author is
   running yet.
   - `git -C /home/user/firth fetch origin main`
   - `git -C /home/user/firth worktree add --detach /home/user/firth-r14 PIN`
   - A fresh cloud container has no Lean toolchain, so install it for the
     authors' default shell (as the driver's container has it):
     `mkdir -p /tmp/r14-elan && curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o /tmp/r14-elan/elan-init.sh && sh /tmp/r14-elan/elan-init.sh -y --default-toolchain none`,
     then `/root/.elan/bin/elan toolchain install leanprover/lean4:v4.30.0`,
     then `ln -s /root/.elan/bin/elan /root/.elan/bin/lake /root/.elan/bin/lean /usr/local/bin/`.
   - `python3 session.py setup SESSION --pin PIN`

   `setup` records the versions in the authors' shell (`lake --version`,
   `lean --version`, `cargo --version`) in `pinned.txt`, and stops unless
   they are run 13's: Lake `5.0.0-src+d024af0`, Lean 4.30.0 at commit
   `d024af09` and cargo 1.93.0.

   `setup` checks the pin, that the main checkout's `AGENTS.md`,
   `CLAUDE.md` and agent file are the pinned ones (authors see the main
   checkout's), the prompts (`make_prompts.py --check`), and that the
   check of a scratch answer prints `ok` in the authors' own shell
   environment, which builds the toolchain. It writes the session's
   `pinned.txt`.
2. **Hook check.** Invoke the skill `s7-author-hook` with the Skill tool,
   once; it registers the hook for the rest of the session. Then
   `python3 session.py hookcheck SESSION`, which stops unless the hook
   recorded that very call, prints a test
   author to start (an `s7-author` told to make one off-list call and the
   allowed check). Start it as printed; when it hands back, run
   `python3 session.py hookcheck SESSION <its agent id>`, which passes only
   if the hook stopped the off-list call, with its mark in the result and
   its denial in the hook log, and let the check run.
3. **Nothing else runs.** From an author's start until its `final.md`, the
   session runs nothing but that author: no other agent (a worker
   included), no background shell and no monitor. `session.py` runs in the
   foreground. A compaction lists the session's running tasks, so any of
   these could reach a compacted author, and only arm B compacts.
4. **The loop.** Repeat until `session.py` prints `DONE`, `STOPPED` or
   `STOP:`:
   - `python3 session.py next SESSION`. It runs the preflight (the scratch
     check in the authors' shell, and the hook fed a planted off-list call
     and the allowed check), writes STATE for the next sample in the order
     above, and prints the Agent tool call to make: `subagent_type`
     `s7-author`, `model` `haiku`, description `Run 14 author
     <SESSION>-<arm><N>`, and the prompt text to paste unchanged.
   - Make that call, then run `python3 session.py started SESSION <agent
     id>` with the id the Agent tool returned.
   - End the turn and wait for the author's hand-back. Do nothing about its
     content.
   - `python3 session.py round SESSION`. It scores the newest answer, runs
     the audit (with the hook log, and for arm B the check command and run
     14's forms), `seen_agents.py` and `context_seen.py` on the author's log
     so far, and records every exit status in the sample's `checks.json`.
     After answers 1 and 2 it prints the feedback to send with SendMessage
     to the author, unchanged; after answer 3 it writes `final.md` and
     copies the sample, the session's state and the hook log to
     `/mnt/project-files/s7-eval/run14/SESSION/`.
5. **Exit codes.** Every `session.py` command exits 0 when the runner
   should do what it printed, and 1 after printing a `STOP:` line. Inside
   `round`, each check's exit code decides validity, and nothing else does:

   | Check | 0 | 1 | anything else |
   |---|---|---|---|
   | `audit_subagent.py` (both arms `--hook-log`; arm B also `--check-cmd <pinned harness> --run14-forms`) | clean | rule void, cause `audit` | STOP |
   | `seen_agents.py <log> <worktree> <pinned AGENTS.md and CLAUDE.md blobs>` | clean | rule void, cause `agent-files` | STOP |
   | `context_seen.py <log> --arm-set run14 --arm <arm> --sample <dir> --label <SESSION>-<arm><N>` (for example `s2-B7`, as in the author's description) | clean | rule void, cause `context`; a `cross_sample` item also writes the shared STOP file | STOP |
   | `harness.py score` | scored | toolchain void | toolchain void |

   A rule void writes the sample's `void.md` in the form `analyse.py`
   reads: one header line `rule: <causes>: exit codes of the checks, by
   round below (session.py)`, with the causes of every round so far merged
   in the order `audit, agent-files, context`, then for each round a line
   `  round <R> at <UTC time>: <causes>` and the audit's flagged lines. The
   sample keeps its slot and gets all its rounds, as in run 13.
   A toolchain void writes `void.md` and `final.md` each starting
   `toolchain: stopped <UTC time>`, and stops the session. Otherwise
   `final.md` is the one line `final <UTC time>: audit and scans run on
   the complete log after answer 3 was scored`, written after the third
   round's checks.
6. **Stops.** The runner sends the driver the `STOP:` line, or says what
   happened, and then does nothing else until the driver answers, on any
   of these:
   - any `STOP:` line: a failed setup, preflight or hook check; a check's
     exit code other than 0 or 1; a toolchain or scoring failure; a
     toolchain failure reported in an author's own check; a hook error (an
     entry with `error` in the hook log for the current sample); a missing
     answer file; a template that does not fit; an unreadable
     `extra-blocks.txt`;
   - an author that errors, stops without handing back, or whose id was
     not recorded;
   - the runner's own session restarting or losing its context mid-sample;
   - anything this runbook does not cover.
7. **Stop file.** A `cross_sample` item from `context_seen.py` writes
   `/mnt/project-files/s7-eval/run14/STOP` (stop and review), which every
   session's `next` reads: the current sample finishes its rounds and no
   session starts another. The driver writes the same file for the early
   look, feasibility or 40 counted per arm. Extra blocks start only when the
   driver lists them in `/mnt/project-files/s7-eval/run14/extra-blocks.txt`.
8. **Numbering.** Block k (1 to 8) of session j is sample (k - 1) × 5 + j
   in each arm, so an arm's samples 1 to 40 are its start order (block,
   then session) and the sessions' results never share a directory. Extra
   blocks carry the numbers the driver gives them, from 41.
9. **Results.** The driver copies each session's samples from the shared
   folder into this run directory and runs `analyse.py` in it (`python3
   runs/2026-09-30-blocked-serial/analyse.py`, and `--early-look` for the
   look). It is run 13's analysis applied to this directory, with the early
   look counting rule voids of any cause and with the voids by cause,
   compactions and blocked calls added; its self-test runs `session.py`'s
   writers into its readers and a synthetic run through both modes. It checks each
   `void.md` against `checks.json` but does not relabel: a label differs
   from the exit codes only as a recorded departure.

`session.py --self-test` checks the order table against `Random(14)`, the
numbering (each arm's samples 1 to 40, once each, in start order), the
driver's extra-block lines (five malformed ones planted and refused) and
that the texts it prints are run 13's templates with run 14's paths.
`setup`, `hookcheck`, `next`, `started` and `round` run for the first time
in the hook half of the smoke test, which goes through one sample of each
arm with them before this file is final.

## Smoke test, before this file is final

One author per arm, one at a time, through all three rounds, with run 13's
prompts in a scratch directory (`runs/smoke-r14` in run 13's worktree, not
kept):

- **Serial half (done).** The arm B author ran 05:58:59 to
  06:13:24Z on 30 September with nothing else running in the session. It
  was compacted once, at 06:08:35Z, and `context_seen.py` found no
  `task_status` line and no cross-sample item in its complete log (exit
  0). The audit with run 14's forms flagged nothing (exit 0); it ran the
  check 14 times. The arm A author ran the same way, 06:14:20 to
  06:19:47Z: no compaction, no `task_status` line and no cross-sample
  item (`context_seen.py`, exit 0), and the audit flagged nothing in its 9
  calls (exit 0). Both arms' authors were sent the harness's
  `[handback-send-enforce]` reminder on their feedback turns, so it falls
  on both arms. Scores (smoke only, not a result): arm A 0, 7 and 9 of 20
  by `harness.py score` over its three answers (arm B: 14 on its third).
- **Hook half, first attempt (17:06 to 17:23Z, 30 September; stopped,
  no author scored).** A fresh Sonnet 5.5 session on `main` at the merge
  commit `d1209ac` of #200. Its container had no Lean toolchain: `setup`
  stopped with "lake is not on PATH". After the install now in runbook
  step 1, `lake --version` in the authors' shell printed
  `Lake version 5.0.0-src+d024af0 (Lean version 4.30.0)` and `setup`
  passed. The hook-check author (agent type `s7-author`, confirmed by its
  `meta.json`) then ran its Glob call unstopped: `hookcheck` stopped with
  "the Glob call was not stopped by the hook", and the hook log held only
  the dry run's two decisions, so the frontmatter hook had never run (see
  "Amendment"). A logging-only probe of a skill's hook in that session was
  refused by the session's permission check when it tried to write the
  skill file, so it was dropped; the committed skill is tested in the
  second attempt instead.
- **Hook half (after this file merges).** In a fresh session started
  from `main` once this file and the agent file are on it, run by Sonnet
  5.5 as a runner would be and following the runbook above with
  `session.py` (one sample of each arm, `PIN` the merge commit, with
  `make_prompts.py` run in the worktree before `setup`, since the prompts
  are built only at the pin). Every smoke command runs with
  `R14_SHARED=/mnt/project-files/s7-eval/run14-smoke`, so its samples,
  state and any STOP file go there and never reach the run's folder
  (`session.py --self-test` checks that nothing reaches it). The run's own
  sessions leave `R14_SHARED` unset, and `setup` refuses to start while the
  run's folder holds a STOP file or any sample of its session. Checked: the `s7-author` agent type is available; its
  hook runs (the same documentation says a project sub-agent's frontmatter
  hooks run only once the folder's workspace trust is accepted); the hook
  denies a planted off-list call and lets an allowed one through; the
  author's log shows the hook's mark in the stopped call's result, as
  `hook_denials` expects, both for a denial and for the fail-closed path
  (a STATE file that cannot be read); and the audit with `--hook-log`
  keeps the stopped calls unflagged. The skill is invoked as runbook
  step 2 says, and `hookcheck` and `next` must find the hook registered.
  If the result's shape differs,
  `hook_denials` and its plants are changed in the pin PR, with the
  smoke's evidence, before any author starts.
