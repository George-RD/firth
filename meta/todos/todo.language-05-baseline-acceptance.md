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
