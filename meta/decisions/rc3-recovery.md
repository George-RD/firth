---
id: dec.rc3-recovery
nodes: [firth.governance.loop]
status: accepted
related: [dec.halt-recovery, dec.loop-autonomy, dec.driver-noop-retry, dec.loop-driver-contract]
date: 2026-08-09
---

# Non-quota rc 3 Stops Get the Bounded Delegate

## Context

dec.halt-recovery automates one bounded intervention for `rc=2`
(LOOP HALTED). Driver `rc=3` was split: quota exhaustion had a
machine-checked relaunch path, and every other rc 3 parked the
container for a human. On 2026-08-09 that parked the loop twice in one
day on harness no-op runs - infrastructure blips no agent ever saw -
while the CTO direction is unattended operation with in-loop decision
authority. A second defect surfaced the same day: delegate-granted
relaunches reused the halted run's extracted driver, so a driver fix
landed on origin/main never reached the relaunched loop, which then
halted on the exact failure the fix addressed.

## Decision

1. On driver rc 3 the supervisor consults its machine-checked quota
   gate first. `wait <reset>` keeps the existing bounded quota-relaunch
   path and never reaches the delegate. `unknown` (unreadable or empty
   usage report) stays down. Only a positive `ok` verdict routes the
   stop to the recovery delegate, invoked with rc 3.
2. The executor (recovery.py) accepts rc 2 and rc 3 and nothing else.
   The incident signature already embeds the rc, so rc 2 and rc 3
   incidents at the same tips are distinct signatures; every bound of
   dec.halt-recovery (max 2 per signature, max 2 with main parked,
   history-rewrite refusal, append-before-act ledger) applies unchanged.
3. Every relaunch path - quota, rc 2 grant, rc 3 grant - refreshes the
   launch checkout to origin/main and re-extracts the driver before the
   new run, exactly like a fresh launch (dec.loop-driver-contract
   clause 6). A grant with an unrefreshable checkout stays down; the
   grant remains ledgered.
4. Wedge (`rc=4`), operator stop, and pre-start configuration errors
   remain human decisions.

## Consequences

- `supervisor.sh`: quota-gated rc 3 delegation; shared
  `refresh_for_relaunch` on all three relaunch paths.
- `recovery.py`: rc gate widened to {2, 3}; mandate text amended so the
  delegate knows which class it is reading.
- Tests: supervisor scenarios prove quota exhaustion and unreadable
  quota never call the delegate and a granted rc 3 relaunches once;
  executor tests prove rc 3 is ledgered with its own signature bounds
  and all other rcs are refused.
