# Verification: differential execution

## Implemented and verified

Implementation commits:
- `52696f539b99aef57bd53d55ce067b0c97119d34`: executable source generator,
  real adapter driver, strict comparison, failure records, replay and shrinking.
- `2d415d46d6a29c011cdfb9fab4eacd748ecce9ac`: source erasure corrections
  exposed by the new campaign and real failure replay/shrinking integration.

Full repository CI run `34309308469` passed for the second commit. All three
jobs succeeded: Python regressions; Lean, Rust and source-to-execution gates;
and Cairn architecture/governance. `language-diagnostics` artefact `10087820982`
retains the run's observations, summaries and expected-failure records.

## Executed evidence

- All 16 Python suites passed, including 37 new harness regressions. The fake
  subprocess adapters in that unit suite test plumbing, not compiler correctness.
- The actual source campaign passed all 72 cases: seeds 0, 1 and 20260909,
  24 per seed. Both external Boolean branches and all 12 generated fragment
  families occurred. Comparison used successful pure observations and kernel
  cost, not raw VM cost or equal traps.
- The real zero-fuel case executed all four adapters and reported
  `bounded-fuel-inconclusive`. Nine candidate reductions were accepted before
  the implemented reduction rules reached a fixed point. Both original and
  reduced records replayed the same failure signature, with no toolchain drift
  and non-passing exit codes. These cases are not counted among the 72 successes.
- The pinned Lean build and full test driver, five new exact erasure goldens,
  zero-admit check, source/compiled proof-binding checks, Rust formatting,
  Clippy and tests, kernel fixtures, real solver pipes, existing trust-boundary
  cases, authored MVP applications, documented examples, bounded cost witness
  and every pinned coverage gate passed. Final checks did not rewrite evidence.

## Red-to-green evidence

Run `34308325332` on the first commit rejected all 72 cases at `[ dup drop ]`.
Retained artefact `10087491235` contains their original source and diagnostics.
Quotation inference omitted kernel atom input demand, and direct source `dip`
was absent from erasure. Those implementation defects were corrected; the
source generator, seeds, comparison rules and original cases were not changed.
The fix and actual pinned proof-artifact rebuild are documented separately in
`meta/changes/quotation-erasure-regressions/verification.md`.

## Scope and remaining work

This is a finite pure source-fragment campaign, not a compiler theorem, the
sustained S2 campaign, effectful/linear World equivalence, returned quotation
comparison or arbitrary grammar coverage. Shrinking's fixed point refers only
to its implemented reductions, not a global minimum. No fresh independent
review is claimed. SMT and compiler evidence admission, runtime review and
baseline acceptance remain open; `loop_exhausted_valid` remains false.

The bounded implementation is branch-verified, not merged or accepted on main.
The following status/docs commit records this evidence; its own CI remains the
source of truth for the final branch head.
