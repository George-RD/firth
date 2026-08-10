---
id: dec.review-mandatory
nodes: [firth.governance.loop]
status: accepted
related: [dec.loop-autonomy, dec.loop-driver-contract]
date: 2026-08-09
---

# Pre-submit Review Is Mandatory, with Head-bound Evidence

## Context

The landing skill made two-lens pre-submit review mandatory with one
prose escape hatch: "a single-line documentation change may skip this".
On 2026-08-09 an iteration flipped one todo-status line, merged, and
then could not establish whether that clause covered todo metadata. It
fail-closed with LOOP HALTED after a clean merge, and the recovery
delegate rightly refused to adjudicate a landed procedural question.
One vague word parked an unattended loop for a day. The review
obligation was also purely procedural: nothing durable proved a review
happened before a merge.

## Decision

1. The exemption is deleted, not narrowed. Every loop merge takes both
   lenses, including the open-PR recovery row. Tracker and governance
   metadata are load-bearing (a `meta/todos/` status flip discharges an
   obligation in the completion matrix) and the runbook carries the
   loop's executable driver, so no diff class is routine prose; the
   lenses cost cents per iteration, and any classifier would
   reintroduce the ambiguity that caused the halt.
2. Review evidence is durable and head-bound: each lens posts one PR
   comment whose first line is `review: correctness <sha>` or
   `review: simplicity <sha>` for the reviewed head, body carrying the
   adjudicated findings.
3. Enforcement is mechanical and pre-merge: the Cleanup script the
   session runs verbatim resolves the PR's `headRefOid` and refuses to
   merge unless both comments exist for that exact SHA. A commit after
   review invalidates the evidence and requires a fresh pass.

## Consequences

- `.claude/skills/firth-loop-landing/SKILL.md` carries the comment
  step and the Cleanup verification verbatim; the prose clause is gone.
- The 2026-08-09 halt class (review-exemption ambiguity) cannot recur,
  and "forgot the review" becomes a pre-merge refusal instead of a
  post-merge halt.
- Honest limit: the comments are session-authored attestations; the
  gate proves their presence and head binding, not review quality. The
  transcript remains the audit trail, and the PR now carries the
  findings where a human can read them.
