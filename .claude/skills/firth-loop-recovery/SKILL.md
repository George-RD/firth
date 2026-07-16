---
name: firth-loop-recovery
description: "The state-recovery procedure for one firth-loop iteration: resume a dirty surviving loop branch, recover an open loop PR, clear interrupted cleanup, quarantine or adopt an orphaned loop branch, and author a recover-todo. Read in full by the firth-loop command from its preflight verdict table; declares the exit tokens the router keys on. Fail-closed: an unclassifiable state halts."
---

# firth-loop-recovery

Recover firth-loop state for the preflight verdict the command's table
selected. The command owns the verdict table (state classification and the
fail-closed backstops); this file owns the procedure each recovery row expands
into. Run the section matching the verdict and return the token it declares.

## Exit tokens

This file declares the mid-iteration tokens the router keys on. Return exactly
one, as the final line, then let the command's flow continue:

- `RECOVERED` - the state was recovered; continue the iteration at the phase
the calling verdict names (Verify for in-place recovery, Scope for an adopted
branch, or continue preflight after cleanup/quarantine-park).
- `LOOP HALTED` - the state is unclassifiable or unrecoverable by this file
(intent unclear, conflicting evidence, a violation the maintainer must judge).
Touch nothing; report; halt.

Paths that finish the iteration (open-PR recovery after merge, quarantine via
a recover-todo) hand off to `firth-loop-landing`; that file emits the terminal
token (`ITERATION COMPLETE` or `LOOP HALTED`). This file does not re-emit a
terminal token after a successful hand-off.

## 1. Dirty tree on a `loop/*` branch whose slug maps to a known unit

Finishing that unit IS this iteration. Recover in place:

1. Read the full diff against the unit's intent (the todo body or finding
   code): `git diff`, `git log origin/main..HEAD`, and the unit's artefacts.
2. Decide coherence: complete the unfinished work, or trim incomplete work
   back to a single coherent landed unit. Prefer trimming over expanding when
   the diff has sprawled beyond one reviewable PR.
3. Return `RECOVERED`. The command continues at Verify, then Land via
   `firth-loop-landing`. Do not invoke landing from this file.

Invariant (a fail-closed backstop, owned by the command): **no checkout of any
kind until the tree is clean**. If intent is unclear, do not guess; emit
`LOOP HALTED`.

## 2. Clean tree, exactly one open `loop/*` PR

Recovery unit. The diff is already published, so skip the Land publish steps
and enter `firth-loop-landing` at its Pre-submit review / Cleanup:

1. Understand the open PR's diff and its CI/review state
   (`gh pr view <n>`, `gh pr checks <n>`, `gh pr view <n> --comments`).
2. Fix what CI or review requires. Re-push to the same `loop/*` branch.
3. Hand off to `firth-loop-landing` at Cleanup, passing the existing `pr`, plus
   `slug` and `CAIRN`. The landing file's terminal token is this iteration's
   final line; do not emit a recovery token after the hand-off.

## 3. Clean tree, a `loop/*` branch whose tip matches a MERGED PR

This is interrupted cleanup, not work. The PR already merged; only the
branch ref and the park remain:

1. `git checkout --detach origin/main` if the worktree still has the branch
   checked out (clean tree, so a pure ref move).
2. `git branch -D <branch>` (the merged PR at the same tip is the deletion
   evidence).
3. Return `RECOVERED`; the command continues preflight toward fresh-work
   selection.

## Recovery precedence

A surviving branch covered by a non-discharged `todo.recover-<slug>` takes the
quarantine row below even if it also has an open PR. Quarantine outranks the
open-PR recovery row for that branch. When multiple surviving branches qualify
for recovery, process them in lexicographic branch-name order, one per
iteration; never choose by recency or PR number.

## 4. Clean tree, a surviving `loop/*` branch covered by `todo.recover-<slug>`

Branch on the todo's status:

- Status `done` **with** an explicit maintainer discard note in the body:
  cleanup is authorised. Park off the branch if checked out (`git checkout
  --detach origin/main`), then `git branch -D <branch>`, continue preflight.
  Return `RECOVERED`.
- Status `done` **without** a discard note: ambiguous; treat as quarantined
  (below) and report it.
- Any other status (authored `blocked`): QUARANTINED (below).

For QUARANTINED: never delete or commit to the branch. If the worktree has it
checked out, park off it the same way (clean tree, pure ref move; the branch
keeps its commits). Continue preflight as if the branch were absent; it is
the maintainer's via the todo. Return `RECOVERED` (the branch is parked, not
this iteration's unit); the maintainer resolves it through the todo.

## 5. Clean tree, any other surviving `loop/*` branch

(Closed PR with no merge, no PR, or a tip that differs from the merged PR.)

- If its slug maps to an **open todo, live finding, or backlog-generation
  Module**: adopt it as this iteration's unit. For a backlog-generation
  branch, the slug is `backlog.<module-id>` and the uncovered Module is the
  unit. For all three recognised kinds, unconditionally run `git checkout
  loop/<slug>` (clean tree, pure ref move), then return `RECOVERED`; the
  command continues at Scope.
- Otherwise **preserving it IS this iteration's unit**: author
  `todo.recover-<slug>` (status `blocked`) so a local branch ref is not the
  only thing keeping those commits alive. Body must record:
  - the branch name and tip SHA (`git rev-parse loop/<slug>`),
  - PR state (`gh pr list --state all --head <branch>`, or "no PR"),
  - a one-paragraph diff summary (`git diff origin/main...loop/<slug>`
    `--stat` plus prose).
  Then hand off to `firth-loop-landing` (normal Land path: stage the
  recover-todo, commit, PR, merge). The landing file's terminal token is this
  iteration's final line; do not emit a recovery token after the hand-off.

A local branch ref is the only thing keeping those commits alive: never delete
without a MERGED PR at the same tip or an explicit maintainer discard note in
the todo.

## Guardrails

`Requires:` is the authoritative prerequisite format for todos. A blocked
todo without that line is maintainer-blocked and is never auto-unblocked; a
blocked todo with `blocked on sub-todos:` follows the split-parent procedure.

- Never stash, clean, reset, or delete unmerged work. A dirty tree is evidence;
  a surviving branch is someone's commits.
- Branch deletion requires merged evidence (MERGED PR at the same tip) or an
  explicit maintainer discard note in a `done` recover-todo. Nothing else.
- When intent is unclear or evidence conflicts, do not improvise: emit
  `LOOP HALTED` and report. The repeating halt is the durable signal.
- Everything this file writes (a recover-todo) is committed on a `loop/*`
  branch and reaches main only through the Land path, inside one commit.
