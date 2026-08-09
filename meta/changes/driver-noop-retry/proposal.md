# Proposal: driver-noop-retry

## Motivation

On 2026-08-09 the driver stopped rc 3 twice on iterations whose entire
log was the spinner line `Working...`: the harness exited 0 without
starting a session, persisting a transcript, or opening its own log.
The token rule read that as a missing terminal token and fail-closed on
the first occurrence, parking an unattended loop on an infrastructure
blip the model never saw. (Retroactive record for commit 7294829,
authored with the decision but without this change folder.)

## Scope

- The runbook driver block: classify a spinner-only exit-0 run as a
  harness no-op and retry it after a backoff; two consecutive no-ops
  stop rc 3. Tokenless runs with any real output still stop rc 3 on
  first occurrence.
- dec.driver-noop-retry (accepted), amending dec.driver-token-tail's
  scope to non-no-op runs only.
- `tools/loop/test_driver_tokens.py`: retry-then-recover, bounded stop,
  streak-reset scenarios.
- Terminal-tokens prose in `docs/loop-runbook.md`.

## Out of scope

- Token acceptance for sessions that produced output (unchanged).
- The supervisor's rc handling (dec.rc3-recovery).
