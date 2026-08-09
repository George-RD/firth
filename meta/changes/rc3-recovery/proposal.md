# Proposal: rc3-recovery

## Motivation

Non-quota driver rc 3 stops parked the loop container for a human even
when the cause was transient infrastructure, defeating unattended
operation. Separately, delegate-granted relaunches reused the halted
run's extracted driver, so driver fixes on origin/main never reached
the relaunched loop.

## Scope

- Supervisor: quota-gated delegation of non-quota rc 3 to the existing
  recovery delegate; shared refresh-and-re-extract on every relaunch
  path.
- Executor: rc gate widened to {2, 3}; bounds unchanged.
- Mandate and launcher-clause amendments; dec.rc3-recovery.
- Supervisor scenario tests and executor tests.

## Out of scope

- The delegate's verb allowlist and every dec.halt-recovery bound.
- Wedge (rc 4), operator stop, pre-start configuration errors.
