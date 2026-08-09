# Design: driver-noop-retry

The discriminator is deliberately narrow: harness exit 0 and every
non-empty, CR-stripped log line is exactly `Working...` (an empty log
qualifies). Any assistant output at all disqualifies the run and keeps
the fail-closed token rule. The retry sleeps `FIRTH_LOOP_NOOP_BACKOFF`
(default 60s, injectable only so the test suite stays fast); `nfail`
counts consecutive no-ops, bounded at 2, reset by any non-no-op run.
The watchdog-timeout counter stays independent.
