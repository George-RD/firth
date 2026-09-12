# Tasks: smt-record-promotion

- [x] Reproduce fabricated checked-result and stale rerun admission against faf2ba7.
- [x] Move promotion into record construction and migrate both production callers.
- [x] Recheck rerun records at the current refinement obligation boundary.
- [x] Cover successful construction and fabricated, stale, mismatched and non-unsat inputs.
- [x] Check unchanged source-region hashes and regenerate compiled bindings from the pinned build.
- [x] Run the full Lean build and test driver, retaining failing-before and passing-after evidence.
- [x] Record the bounded verification and retain the parent admission todo as open.
- [ ] Complete trusted solver provenance and the remaining parent acceptance criteria.

The clean PR candidate must also pass the complete repository CI. Its exact-head
result and independent-review status are recorded in PR #109, not inferred from
this isolated Lean run. Parent completion and baseline acceptance remain open.
