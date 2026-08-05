# Proposal: loop-autonomy

## Motivation

The loop is moving to unattended operation to project completion with no
maintainer making decisions. Three things prevent that today. The command
parks decision-shaped blockers as maintainer-blocked todos that the selector
never auto-unblocks, while blocked obligations make `LOOP EXHAUSTED`
invalid, leaving an unattended run with no eligible unit and no valid
terminal token. The runbook pins a cairn series (`0.3.x`) that is not
installed and whose 0.9.0 replacement has an unreachable `change accept`
battery in this repository. And the runbook's launch and expected-results
sections predate the current backlog and tree (the root Lake package and VM
crate now exist), and name no verified harness invocation for omp, the
harness that will drive the loop.

## Scope

- Add `meta/decisions/loop-autonomy.md`: completion definition bound to
  `coverage.py`'s `loop_exhausted_valid`, typed decision authority (goal
  layer immutable to the loop, frozen specs evidence-ratified,
  implementation decisions loop-accepted with autonomous-author
  provenance), maintainer-blocking reserved for environment, authority,
  and external-evidence dependencies, a fail-closed starved-selector rule,
  the acceptance-gate substitution while cairn's battery is unreachable,
  an anti-shortcut charter, and fail-closed halts.
- Amend `.claude/commands/firth-loop.md` to implement clauses 2-6: replace
  the maintainer-decision parking rule, add Firth policy (vi), add the
  fail-closed starved-selector row to Backlog generation, tie
  `LOOP EXHAUSTED` to `loop_exhausted_valid`, point the selector's
  maintainer-blocked semantics at the decision, and fix the language-gates
  binding for the tree that actually exists: camel-case `testDriver`
  detection, VM crate gates run from `src/runtime/vm`, and no root cargo
  commands.
- Refresh `docs/loop-runbook.md`: cairn prerequisite as verified behaviour,
  Lean and Rust toolchain prerequisites, a verified omp launch example with
  the generic-pack exclusion, a driver whose exit status distinguishes
  exhaustion, halt, unknown token or harness failure, and fuse,
  run-to-completion guidance, completion semantics in the token table, and
  current dry-run expected results including the product gates.
- Correct stale state claims in `AGENTS.md` (`src/` exists and its gates
  are live) and add the dec.loop-autonomy pointer.

## Out of scope

- No changes to `tools/loop/` code: selector and coverage behaviour are
  contracts other text depends on, and the starved-selector rule is
  deliberately fail-closed rather than a new selection state.
- No forks of the generic cairn skills under `.claude/skills/cairn-*` or
  `.omp/`; the command's Firth policy owns repo-local exceptions, and the
  generic `/cairn-loop` contract (including its receipt protocol) never
  drives this repository.
- No blueprint change: every touched path is already claimed by
  `firth.governance.loop`.
- No todo or backlog content changes; the loop generates those itself.
