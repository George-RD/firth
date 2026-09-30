# Run 12 departures from the pre-registration

1. **Author shell PATH (03:24Z).** B1, B2 and B3 started with no Lean toolchain on the authors' default PATH; every check they ran printed "lake is not on PATH". Voided as toolchain voids; three symlinks added in /usr/local/bin (recorded in pinned.txt, with toolchain versions from both environments). Nothing in the pinned worktree changed. From 03:31Z preflight.sh ran the check in the authors' default shell before an arm B start (logged before B7; B4 to B6 had started at 03:27Z, after the fix; no check by B4 to B8 printed toolchain text).

2. **Early stop for feasibility.**
   - Rule set by the coordinator at 03:39Z (message queued 03:39:31Z), before B5, B6 and B8 finished: start no new samples in either arm; if at least 2 of B5, B6, B8 are rule voids, stop run 12 as "stopped early for feasibility (departure)"; otherwise resume as written.
   - Applied at 03:42Z on void status only: the audit (`audit_subagent.py --check-cmd`) on the logs so far exited 1 for B5 (15 flagged Bash calls) and B6 (26). Under "a sample found void at any point is void", that met the rule.
   - Between 03:39Z and 03:42Z no score of B5, B6 or B8 was read (none had been scored) and no arm total was computed. Two arm A round scores were printed by the driver in that window as part of routine feedback (A9 round 2 and A11 round 2); neither is an arm total and neither bore on the rule, which reads arm B void status only.
   - This anticipates the pre-registered feasibility stop (40 voids in an arm) rather than replacing it: at the observed rate (6 flagged of 8 arm B samples), 40 counted arm B samples would need on the order of 100 or more starts, so the 40-void stop would almost surely fire first.
   - After the stop: no new samples in either arm. Samples already running finish their current work; arm B voids get no further feedback.
