# Verification: quotation erasure regressions

## Red

PR commit `52696f539b99aef57bd53d55ce067b0c97119d34`, CI run `34308325332`,
retained `language-diagnostics` artefact `10087491235`: all 72 original cases
were rejected at the source quotation `[ dup drop ]`. The existing language
suites had passed before this new campaign ran. No cases were filtered out.

## Pinned candidate validation

Run `34308922501` applied patch SHA-256
`28f18ce12e73834a5872c3f2501605193693bbf688e7dfa9ae6b780799f12b13` to
`52696f539b99aef57bd53d55ce067b0c97119d34`. The pinned Lean build, zero-admit
check, full Lean test driver and unchanged 72-case campaign passed. All cases
reported successful observation and kernel-cost agreement. The generator,
comparison rules, seeds and original inputs are unchanged from the red run.

`quotation-validation` artefact `10087687444` contains the exact final patch,
source/blob hashes, actual six-module compiled manifest and execution logs.
The complete local source envelope is
`b96933f62b99b4343ead93348bb02bb0201a05f0791b849378edfdf4f2499af1`.
Source, test and compiled-manifest blobs were checked against the local
candidate before publication. The temporary validation workflow is not part
of the product candidate and never updated any branch reference.

Complete PR CI, including the new real-failure round-trip check and unchanged
source/compiled-pin verification, remains required on the published candidate.
This does not close SMT result authentication, compiler evidence admission,
runtime review or baseline acceptance, and does not authorise merging PR #109.
