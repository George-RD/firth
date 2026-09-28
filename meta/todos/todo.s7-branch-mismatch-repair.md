---
node: firth.toolchain.agent
status: open
created: 2026-09-28
---

# Authors rarely repair a reported branch mismatch

Found by run 6 of the S7 eval (`eval/s7/README.md`, "Run 6"). Since #145
and #148 a mismatched `if` is reported at the `if` as
`firth.type.branch-mismatch`, and no failure is misreported as an
untracked local any more. But Haiku seldom fixes one from the message:
of sample 1's 5 branch mismatches in round 1, 4 were still branch
mismatches in round 2, and of sample 2's 10, 9 were. It is the largest
last-round failure group in both samples (6 of 15 and 10 of 14).

The last-round answers that failed this way are fixtures for the
diagnostic, in `eval/s7/runs/2026-09-28-haiku-470c6d0/`:

- `haiku-firth-1/answer-3.md`: `reverse`, `merge-sorted`, `digits`,
  `histogram`, `ledger`, `allocate-batch`.
- `haiku-firth-2/answer-3.md`: `prefix-sums`, `keep-positive`,
  `longest-run`, `has-pair-sum`, `merge-sorted`, `digits`,
  `primes-up-to`, `histogram`, `ledger`, `allocate-batch`.

## Acceptance criteria

- The branch-mismatch diagnostic tells the author what each branch leaves
  and which change would make them agree, checked against these fixtures
  (each fixture's diagnostic names both branch effects).
- A separate scored Haiku rerun of the MVP set after that change, recorded
  under `eval/s7/runs/` and in `eval/s7/README.md`, reports how many
  branch mismatches were repaired between rounds.
- That rerun also takes several first answers on each of the run 5 prompt
  (`cec3707`) and the run 6 prompt (`470c6d0`), so the first-answer `firth.name.unresolved` rise from run 5 to
  run 6 (7 and 19, against 1 and 0) can be put down to sample variance or
  to the prompt's additions (README, "Run 6").

## Progress

- Run 7 (`eval/s7/README.md`, "Run 7"; `runs/2026-09-28-haiku-c6a964a/`)
  is the rerun after #153 and #156. It meets the second and third
  criteria: of 18 resubmitted branch mismatches, 12 failed on it again and
  none passed (run 6: 15 of 23, one pass), and the extra first answers put
  the `firth.name.unresolved` rise down to sample variance (the run 5
  prompt gave 20 and 13).
- The first criterion is Language core's. On `c6a964a`, 15 of the 16
  run 6 fixtures get a message naming what both branches take and leave;
  sample 2's `longest-run` gets "the true branch ... cannot run on the
  stack it is given", which names only the true branch.
- Repair is not better, so the problem this todo is named for remains.
  Sample 2's `answer-3.md` in run 7 holds 10 more last-round fixtures.
