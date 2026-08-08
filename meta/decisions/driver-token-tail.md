---
id: dec.driver-token-tail
nodes: [firth.governance.loop]
status: accepted
related: [dec.loop-driver-contract]
date: 2026-08-08
---
# Driver Token Tail Acceptance

## Context

dec.loop-driver-contract records the runbook driver as the sole supervisor
for unattended runs and binds token acceptance to a clean harness exit.
The driver read the token from the last non-empty output line only. That
reading discarded two otherwise-sound runs:

- 2026-08-06 16:22: a session yielded a blocked-progress report whose last
  line was prose; the run stopped rc 3 mid-horizon.
- 2026-08-08: a session landed PR #60, printed `ITERATION COMPLETE`, and
  then appended its report below the token; the driver read the report's
  last bullet, stopped rc 3, and a healthy run needed a manual relaunch
  after a fully successful iteration.

One misplaced line discarding a run is the wrong failure mode for
unattended operation; accepting a token anywhere in the output would be
the opposite defect. This is a maintainer-authored amendment landed
outside the loop.

## Decision

The driver accepts `ITERATION COMPLETE` or `LOOP HALTED` iff exactly one
distinct terminal token appears as a whole line, after CR stripping,
among the last 15 non-empty output lines. `LOOP EXHAUSTED` is the
completion claim and keeps the strict reading: it is accepted only as
the final non-empty line, never from deeper in the tail. Zero tokens,
two different tokens in the tail, a token buried deeper than the tail,
or a non-final `LOOP EXHAUSTED` remain rc 3, fail closed. Everything
else in dec.loop-driver-contract binds unchanged: clean-exit requirement
(a token on a nonzero exit is ignored), typed exits, watchdog, progress
window, prompt freshness.

The authoring contract in `.claude/commands/firth-loop.md` is unchanged:
the session must still emit the token as its final non-empty line. Tail
acceptance is driver tolerance for formatting drift, not licence to move
the token.

## Rationale

Exact whole-line matching keeps quoted or discussed tokens inert, the
distinct-token conflict rule keeps ambiguity fail-closed, and the
15-line window bounds the stale-token hazard: a session that prints a
token early and then fails at length pushes the token out of the tail
and stops rc 3. A tolerated false `ITERATION COMPLETE` cannot
manufacture progress: the wedge window advances only when the driver
itself observes `origin/main` move. Exhaustion tolerates nothing because
it is the one token that ends the run claiming completion; it stays
bound to the final line, the coverage boolean, and the maintainer's
preflight confirmation. The alternatives were re-prompting the model
harder (already tried; drift recurred) or keeping manual relaunches in
an unattended loop.

`tools/loop/test_driver_tokens.py` exercises the acceptance rule
adversarially against the extracted driver block with a stubbed harness
and git: token-last, token-then-report, buried token, conflicting
tokens, missing token, halt, exhaustion strictness both ways, and
nonzero-exit paths.

## Consequences

- `docs/loop-runbook.md`: the driver block's token read is the tail scan
  with strict-final exhaustion; the Terminal tokens section states the
  acceptance rule; the driver script still takes effect on relaunch
  (dec.loop-driver-contract clause 6), so the launcher must refresh its
  checkout of `origin/main` before extraction.
- `tools/loop/test_driver_tokens.py` added; run it with the control-plane
  suites whenever the driver block changes.
- The status dashboard mirrors the same acceptance rule for its
  per-iteration outcome column.
