# Proposal: pr109-baseline-acceptance

Discharge `todo.language-05-baseline-acceptance` as far as a branch can, so
PR #109 can be judged on evidence rather than on a green check.

The task has four acceptance criteria: reconcile every PR #109 review finding,
audit each active obligation for specification-only or stale completion
evidence, run the full gate set on the exact candidate, and, after merge,
rerun acceptance on main and record candidate verification and landed
acceptance separately.

The first three are branch work and are discharged here. The fourth cannot be
met on a branch by construction: it names a commit that does not exist until
the merge happens. The todo therefore stays `open` and this record states
exactly what a merged-main record must still add.

Nothing in this unit weakens a requirement, a gate or a test. Where a review
finding is not fixed, it is either dismissed with source evidence or carried
by a linked open todo, per the completion discipline in `docs/roadmap.md`.
