---
node: firth.governance.loop
status: open
created: 2026-09-08
---

Requires: language-00-boundary-regressions language-01-smt-record-admission language-02-compiler-evidence language-03-runtime-conformance language-04-differential-execution

## Goal

Accept and land a trustworthy experimental baseline.

## Acceptance criteria

- Reconcile all PR #109 review findings. Each valid blocker has a tested fix; each dismissal has source evidence. Do not merge based only on old green CI.
- Audit every active obligation for specification-only or stale completion evidence and create implementation tasks wherever needed. Do not mark an audit complete by weakening a requirement.
- Run Lean/Rust/Python, proof bindings, kernel fixture consistency, Cairn scan/hook and coverage --run-gates on the exact candidate. Known future work keeps loop_exhausted_valid false; failing or missing executable gates block landing.
- After verified review and merge, rerun acceptance on main. Record candidate verification and landed acceptance separately with commit identities.

## Traceability

PRD G1-G8; dec.mvp-completion and dec.usable-language-milestones. No requirement for a fully finished ecosystem before this bounded baseline.

## Candidate verification, 10 September 2026

Criteria 1 to 3 are discharged on the candidate branch and recorded in
`meta/changes/pr109-baseline-acceptance/`.

- **Reconcile all review findings.** All 82 threads carry a disposition with
  evidence: 43 fixed on the branch, 31 already fixed at `80a9d41`, 2 partly
  fixed with the remainder carried by an open todo, 3 tracked by a linked open
  todo, and 3 dismissed with source evidence. The seven trust-boundary and
  crash defects are all fixed with regressions that fail on the unchanged head.
- **Audit every active obligation.** `meta/changes/baseline-obligation-audit/`
  classifies each active-profile row, opens five implementation todos where a
  design document was standing in for implementation, links existing
  implementation todos into the rows they serve, and pins executable compiler
  evidence in the trusted-computing-base manifest.
- **Full gates on the exact candidate.** Every `ci.yml` step was reproduced on
  the candidate tree with the pinned toolchains and passes, with no failing or
  missing pinned gates and `loop_exhausted_valid` correctly false.

Criterion 4 is open by construction: rerunning acceptance on merged main names
a commit that does not exist until the merge. **This todo stays `open`.** Its
`Requires` are now all `done`, so `select_unit.py` may surface it; the session
that selects it must not mark it done without the merged-main record, and a
green branch is not that record.
