# Design: pr109-baseline-acceptance

## Reconciliation

Every one of the 82 review threads on PR #109 was triaged against the exact
head `80a9d41`: the cited code was located, later commits and maintainer
replies were checked, and the finding was re-derived rather than trusted.
Each thread then received one of five dispositions, and the table in
`verification.md` carries all of them with evidence:

- fixed at `80a9d41` by a named commit, with the test or gate that covers it;
- fixed on this branch, in one of the four changes, with its test or gate;
- partly fixed, with the remainder named and carried by an open todo;
- dismissed, with the source evidence that the finding does not hold;
- tracked by a linked open todo, where the fix belongs to later work.

A finding is never closed by assertion. The three dismissals each rest on
something checkable in the tree or the toolchain, not on judgement.

## Audit

`meta/changes/baseline-obligation-audit/` classifies every active-profile
obligation as executable, specification-only or stale, opens four
implementation todos where a design document was standing in for
implementation, links existing implementation todos into the rows they
already serve, and pins executable compiler evidence in the trusted-computing
-base manifest. Adding rows to `satisfied_by` moves obligations from complete
to in flight, which is the honest direction.

## Verification

The candidate is verified by the repository's own gates, run on the exact
tree, not by a summary of them. `verification.md` records each step and its
counts, and compares them with the same run on `80a9d41` so that what grew is
visible. Branch verification and merged-main acceptance are recorded as
separate claims, and neither is described as the other.
