# Landed baseline acceptance

Recorded 14 September 2026 from GitHub's completed post-merge run, not inferred
from candidate checks and not a claim of a new local Lean/Rust execution.

## Identities

- PR #109 merged on 12 September 2026 at 15:36:50 UTC (19:36:50 UAE).
- Candidate head: `03b88422c168491b0ac4c058ce577951f3a90c2b`.
- Merged main: `c6b1a19c5a94eacf13d2b9679b2bbbf1eba33ff7`.
- Source tree: `02b63845f454800c11f3589332447c916176b24b`.
- Post-merge push run: [34702764110](https://github.com/George-RD/firth/actions/runs/34702764110), completed successfully at 15:39:56 UTC on 12 September.
- Workflow definition: [.github/workflows/ci.yml at the accepted commit](https://github.com/George-RD/firth/blob/c6b1a19c5a94eacf13d2b9679b2bbbf1eba33ff7/.github/workflows/ci.yml).

The run is bound to merged main, not a pull-request merge preview. Its source
snapshot was retrieved, checked against GitHub's archive digest, extracted,
and independently reconstructed as Git tree `02b63845...`, matching the
accepted commit's tree. Candidate reconciliation remains separately recorded
in `verification.md` and the PR discussion.

## Post-merge evidence

The existing workflow covers Python regressions, Lean build/tests, Rust
format/lint/tests, proof-binding checks without rewrites, kernel fixtures,
public adapter refusal/conformance checks, seeded differential execution and
failure replay/shrinking, the pinned arm64 SMT process, Cairn scan/hooks and
all pinned coverage gates.

The downloaded execution diagnostics establish:

- 29 public trust-boundary cases passed, none failed.
- 50 compiler-admission cases passed, none failed.
- 10 successful language-example cases and 7 refusal cases passed; both then-
  documented public CLI commands passed.
- Coverage reports 22 complete obligations and 20 in flight, with no failing
  or missing gates and `loop_exhausted_valid: false`. The complete unedited
  output is retained in `landed-main-coverage.json`.
- Cairn scan and hooks completed with the existing advisory warnings. This is
  not a claim of zero findings or a warning-free architecture.

Retrieved archive identities (SHA-256):

| Artifact | GitHub ID | Digest |
| --- | --- | --- |
| source-snapshot | 10301240561 | `767e46da745aaf32ca34a9c0016f69eb0a2562b86dec306fe3997f12c695b684` |
| language-diagnostics | 10301125988 | `f0b333a063468feeae4905a6d6f4c7d2ea6c7770a9241281d5cc419aa62f61dc` |
| governance-diagnostics | 10300439689 | `0e28280baff3b85fb48984456d1c68a70aa4bd2b1e429068579c22b899d58793` |

All three archives were checked against the digests returned by GitHub.
Artifacts have seven-day retention; the commit/run identities and raw coverage
are retained here rather than relying solely on a temporary download.

## Scope of acceptance

This closes criterion 4 of `todo.language-05-baseline-acceptance`, not M1, M2
or the full language. Source refinement execution, useful arithmetic/data,
the Firth inventory implementation, broader authoring tools and the fresh-
agent pilot remain open. No source corpus, expected result, proof pin or
acceptance requirement was rewritten to obtain this result.
