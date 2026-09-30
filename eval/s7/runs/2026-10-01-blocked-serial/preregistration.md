# Run 14 pre-registration: does running the checker help authors? (blocked calls, one author at a time)

DRAFT. Not pinned, prompts not built, and no author has started. Authoring
waits for the maintainer's go-ahead on the author agent file and its hook
(see "Blocking"), for the smoke test below, and for this file's review.
Nothing here changes after the first answer is scored; any departure is
reported as one.

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
  Use only the tools, files and command your instructions name." Every
  decision is logged with the call's `tool_use_id`. If the hook cannot read
  its state or input, it denies (fails closed).
- The audit (`audit_subagent.py --hook-log`) keeps a stopped call in the
  trimmed log, marked `blocked`, and does not flag it. A call counts as
  stopped only when the hook log denied its id and the author's log shows
  the hook's mark in that call's result. Flagged, and so voiding: a call
  off the list that was not stopped (the hook failed), a denial the
  author's log does not show, a marked result the hook did not deny, and a
  call on the list that the hook stopped.
- Planted in `author_hook.py --self-test` (18 calls in arm B, 5 in arm A,
  a missing state file, unreadable input) and in `test_mvp.py` (each half
  of the stopped-call evidence alone, a stopped call on the list, run 14's
  `$)` form allowed while run 13's forms still flag it, and `"ok$x"`,
  `"$(id)"` and `"$HOME"` still flagged). Run 13's 20 raw logs re-audited
  with the refactored audit give byte-identical trimmed logs.
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
  order (Python `random.Random(14)`, one choice of `AB` or `BA` per block,
  sessions 1 to 5 in turn):

  | Session | Blocks 1 to 8 |
  |---|---|
  | s1 | AB AB BA BA BA AB BA BA |
  | s2 | BA BA BA AB BA AB BA BA |
  | s3 | BA BA AB AB BA AB AB AB |
  | s4 | AB BA AB AB BA AB BA BA |
  | s5 | BA AB AB BA AB AB BA AB |

  Blocks 9 onwards, needed only to replace voids, continue the same stream.
  A session starts a block beyond 8 only when the driver says so.
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
3. **Queue.** The session's blocks in the order above. For each sample:
   write STATE, start one `s7-author` (model `haiku`, description
   `Run 14 author <session>-<arm><n>`), and send its two feedback rounds
   from the arm's templates. Score each round, then run the audit and the
   scans, as run 13's driver. Write `final.md` after the third answer. Start
   the next sample only when this one has `final.md`.
4. **Results.** Each sample's directory, the hook log, `state.md` and the
   sample-to-author map go to `/mnt/project-files/s7-eval/run14/<session>/`
   after each `final.md`. The run 14 driver copies them into this run
   directory, checks them with `analyse.py`, and does the analysis.
5. **Stop.** On the driver's word (early look, feasibility, or 40 counted
   per arm), finish the current sample's rounds and start no other.

## Smoke test, before this file is final

One author per arm, one at a time, through all three rounds:

- `context_seen.py` finds no `task_status` line, and the number of
  compactions is recorded. The arm B smoke is informative only if it
  compacted.
- The hook denies a planted off-list call and lets an allowed one through,
  and the audit with `--hook-log` keeps the stopped call unflagged.
- The shape of a stopped call's result in the author's log (the hook's
  mark in the tool result) is what `hook_denials` expects.
