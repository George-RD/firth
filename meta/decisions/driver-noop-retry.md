---
id: dec.driver-noop-retry
nodes: [firth.governance.loop]
status: accepted
related: [dec.loop-driver-contract, dec.driver-token-tail, dec.halt-recovery]
date: 2026-08-09
---

# Harness No-op Runs Are Retried, Bounded

## Context

On 2026-08-09 the driver stopped rc=3 ("missing or unknown terminal
token, harness exit 0") on an iteration whose entire log was 12 bytes:
the spinner line `Working...`. No session file was persisted and no
harness log was opened - the model never executed. The provider quota
gate reported ok, so the supervisor correctly declined to relaunch and
the loop parked on an infrastructure blip no agent ever saw.

dec.driver-token-tail governs token acceptance for sessions that ran.
It is silent about runs that never started. Treating those identically
conflates two failure classes with opposite correct responses: a model
that produced output without a token must halt fail-closed; a harness
that produced no session at all is the same class as the watchdog
timeout the driver already retries.

## Decision

1. A run is a harness no-op when the harness exits 0 and every
   non-empty, CR-stripped line of the iteration log is exactly
   `Working...` (an empty log qualifies). The discriminator is
   deliberately narrow: any assistant output at all disqualifies it.
2. The driver retries a no-op after a backoff
   (`FIRTH_LOOP_NOOP_BACKOFF`, default 60 seconds; injectable for the
   test suite only). Two consecutive no-ops stop rc=3.
3. A real iteration resets the streak. Token acceptance for real
   iterations is unchanged (dec.driver-token-tail is amended in scope,
   not retired: its acceptance rule now applies to non-no-op runs).
4. The no-op path never resets the watchdog-timeout streak semantics:
   both counters remain independently bounded at 2.

## Consequences

- `docs/loop-runbook.md`: driver block gains the guard; the Terminal
  tokens section documents the classification.
- `tools/loop/test_driver_tokens.py`: three scenarios (retry then
  recover, bounded stop, streak reset) pin the behaviour.
- A tokenless run with any non-spinner output still stops rc=3 on the
  first occurrence; this decision does not widen model-side tolerance.
