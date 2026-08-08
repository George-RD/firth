# Proposal: driver-token-tail

## Motivation

The driver read its control token from the last non-empty output line
only. Two otherwise-sound runs were discarded by that reading: a
blocked-progress yield on 2026-08-06, and on 2026-08-08 a fully
successful iteration that landed PR #60, printed `ITERATION COMPLETE`,
and appended its report below the token. rc 3 after a landed unit means
a manual relaunch inside an unattended loop.

## Scope

- The runbook driver block's token acceptance: exactly one distinct
  token as a whole line among the last 15 non-empty lines for
  `ITERATION COMPLETE` and `LOOP HALTED`; `LOOP EXHAUSTED` stays strict
  final-line. Ambiguity, absence, burial, or non-final exhaustion stay
  rc 3, fail closed.
- dec.driver-token-tail (accepted, maintainer-authored), amending
  dec.loop-driver-contract's token reading only.
- `tools/loop/test_driver_tokens.py`: hermetic adversarial tests of the
  extracted driver block over stubbed git and harness.
- Terminal-tokens prose in `docs/loop-runbook.md`.

## Out of scope

- The authoring contract in `.claude/commands/firth-loop.md` (the session
  must still end with the token).
- Every other clause of dec.loop-driver-contract: clean-exit rule, typed
  exits, watchdog, wedge window, prompt freshness.
