---
id: dec.loop-driver-contract
nodes: [firth.governance.loop]
status: accepted
date: 2026-08-06
---
# Loop Driver Contract

## Context

After dec.loop-autonomy landed, an adversarial hardening chain (PRs #39
through #46) evolved the launch driver in `docs/loop-runbook.md` from a
fixed-fuse token reader into the loop's supervisor. Each step was
smoke-tested against stub harnesses before landing, but the accumulated
contract lived only in the runbook prose and PR history. This decision
records it as graph truth; the paired retroactive change record is
`meta/changes/archive/2026-08-06-loop-driver-hardening/`.

## Decision

The driver in `docs/loop-runbook.md` (the file's first fenced sh block) is
the sole supervisor for unattended runs, with this contract:

1. **Typed exit status.** 0 only for `LOOP EXHAUSTED` (project completion
   per dec.loop-autonomy clause 1); 2 for `LOOP HALTED`; 3 for unknown
   token, harness failure, or observation failure; 4 for a wedge. Pre-start
   configuration aborts exit 1 via parameter-expansion guards, which is why
   the canonical launch is a saved script under non-interactive `sh`, never
   an interactive paste.
2. **Token acceptance requires a clean harness exit.** Any token on a
   nonzero exit is ignored.
3. **Driver-owned watchdog.** Every iteration runs under coreutils
   `timeout` (`MAXTIME` seconds, default 7200, validated as a positive
   integer like `W`). Exits 124 and 137 are watchdog kills: tolerated once,
   because the killed iteration's partial state is exactly what the next
   preflight recovery classifies, and stopped on two consecutive. Every
   other nonzero harness exit stops immediately. Harness-internal deadline
   flags are not relied on: omp's `--max-time` is an in-process deadline
   with unreliable exit semantics (measured exit 1, `Deadline exceeded`).
4. **Progress window, not an iteration cap.** Every honest
   `ITERATION COMPLETE` lands exactly one commit on `origin/main`, so the
   driver runs uncapped while the remote tip advances and stops rc 4 after
   `W` (default 10, validated) consecutive completions that land nothing.
   A failed tip read is retried once, then stops rc 3 as a labelled
   observation failure, never absorbed into the window.
5. **Harness flags.** `--no-skills` is required (the generic cairn pack's
   loop and ratification contract never drive this repository). A
   memory-off overlay (`memory.backend: off` via `--config`) is
   recommended for unattended runs so recall cannot leak prior-session
   context; the tracker and graph stay the only cross-iteration channel.
   All other profile settings are the operator's.
6. **Prompt freshness.** The injected command text is read from
   `origin/main` (`git fetch`, then `git show FETCH_HEAD:`) at every
   iteration, never from the launch checkout's working tree; a failed
   fetch or read stops rc 3. Normative amendments landed mid-run take
   effect on the next iteration; the driver script itself updates only on
   relaunch.

## Rationale

Each clause closes a verified failure: the fixed fuse stopped healthy runs
and was a manual relaunch touchpoint; tokens from killed sessions could
fake completion; a junk `W` silently disabled the wedge guard; an
interactive paste let a failed guard's line die alone while the loop ran
on the invalid value; omp's in-process deadline could kill a week-long run
on one wedged iteration or bypass exit classification entirely; and memory
recall was empirically shown to inject prior context into fresh print-mode
sessions (verified with and without the overlay on omp 17.2.9). Every stop
path was exercised against stub harnesses before landing, including
watchdog-once recovery, watchdog-twice stop, CRLF tokens, and
dirty-harness token suppression.

## Consequences

- The runbook's driver block is normative for launches; changes to its
  stop semantics require a superseding decision or an amendment here.
- A containerised deployment reuses this driver unchanged and treats the
  typed exit statuses as its operational interface.
- Exit-code classification is pinned to coreutils `timeout` semantics
  (124 and 137); replacing the watchdog requires re-verifying the
  classification.
