# Run 14 pre-registration: does running the checker help authors? (blocked calls, one author at a time)

Not final. Prompts are not built, nothing is pinned and no author has
started. This file merges only after the hook half of the smoke test
passes in a fresh session (see "Smoke test"), and that waits for the
maintainer's go-ahead on the author agent file and its hook. Nothing here
changes after the first answer is scored; any departure is reported as
one.

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

- An agent definition, `s7-author`, carries a `PreToolUse` hook in its
  frontmatter. Hooks there run only while that sub-agent runs, so they
  never touch the driving session's own calls. Both arms' authors are
  started with that agent type, so they have the same tools available and
  the same hook; the arms still differ only in their prompts.
- The hook runs `eval/s7/author_hook.py --state STATE`. The driver writes
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
  hooks:
    PreToolUse:
      - matcher: "*"
        hooks:
          - type: command
            command: python3 /home/user/firth-r14/eval/s7/author_hook.py --state /home/user/r14-hook/state.json
            timeout: 30
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
- **Needs the maintainer.** Writing the agent file needs the maintainer's
  words naming it. Until then nothing here is installed.
- **Open.** Whether a session started after the agent file exists picks
  it up, and whether its cwd makes the project's or the user's agents
  directory the one read, is checked in the smoke test before this file is
  final.

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
- **Edit replay.** Only arm B can Edit, so a void because "an edit of it
  could not be replayed" can fall only on arm B. It has not happened in
  runs 12 and 13. It is reported with the voids by cause.
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

1. **Setup.** Create the worktree `/home/user/firth-r14` at the pinned
   commit (the path the prompts name). Build the toolchain there; a `check`
   of a scratch file must print `ok`. Confirm the `s7-author` agent type is
   available. Record `pinned.txt` as run 13 did, plus the session's name.
2. **Preflight, before each author.** The check on a scratch file in the
   authors' default shell, as run 13. And the hook: with STATE pointed at a
   scratch sample, a planted off-list call must be denied and the check on
   the scratch answer allowed (`author_hook.py` fed the JSON, and once
   through a real `s7-author` at session start).
3. **Nothing else runs.** From an author's start until its `final.md`,
   the session runs nothing but that author: no other agent (a worker
   included), no background shell and no monitor. Scoring, the audit and
   the scans run in the foreground between rounds. A compaction lists the
   session's running tasks, so any of these could reach a compacted
   author, and only arm B compacts.
4. **Queue.** The session's blocks in the order above. For each sample:
   write STATE (`/home/user/r14-hook/state.json`, the path the agent file
   names), start one `s7-author` (model `haiku`, description
   `Run 14 author <session>-<arm><n>`), and send its two feedback rounds
   from the arm's templates. Score each round, then run the audit and the
   scans, as run 13's driver. Write `final.md` after the third answer. Start
   the next sample only when this one has `final.md`.
5. **Results.** Each sample's directory, the hook log, `state.md` and the
   sample-to-author map go to `/mnt/project-files/s7-eval/run14/<session>/`
   after each `final.md`. The run 14 driver copies them into this run
   directory, checks them with `analyse.py`, and does the analysis.
6. **Stop.** On the driver's word (early look, stop and review,
   feasibility, or 40 counted per arm), finish the current sample's rounds and start no other.

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
- **Hook half (waits for the maintainer).** In a fresh session started
  after the agent file exists: the `s7-author` agent type is available; its
  hook runs (the same documentation says a project sub-agent's frontmatter
  hooks run only once the folder's workspace trust is accepted); the hook
  denies a planted off-list call and lets an allowed one through; the
  author's log shows the hook's mark in the stopped call's result, as
  `hook_denials` expects, both for a denial and for the fail-closed path
  (a STATE file that cannot be read); and the audit with `--hook-log`
  keeps the stopped calls unflagged. If the result's shape differs, `hook_denials` and its
  plants are changed here before this file merges.
