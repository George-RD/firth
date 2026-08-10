# Proposal: review-mandatory

## Motivation

A one-line todo-status merge halted the loop because the pre-submit
review exemption was prose ("a single-line documentation change may
skip this") and the session could not establish whether it applied.
The ambiguity, not the diff, cost the outage; and nothing durable
proved any review happened before any merge.

## Scope

- Delete the exemption: two-lens review is mandatory for every merge,
  including the open-PR recovery row.
- Durable evidence: one PR comment per lens, first line binding the
  reviewed head SHA.
- Executable gate: the Cleanup merge script verifies both comments
  against the PR's headRefOid and exits before merging otherwise.
- dec.review-mandatory.

## Out of scope

- The two-lens review procedure itself.
- Post-merge halt semantics for genuinely omitted reviews (unchanged).
