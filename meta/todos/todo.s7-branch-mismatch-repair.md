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
- That rerun also takes several first answers on the run 6 prompt and on
  its own, so the first-answer `firth.name.unresolved` rise from run 5 to
  run 6 (7 and 19, against 1 and 0) can be put down to sample variance or
  to the prompt's additions (README, "Run 6").
