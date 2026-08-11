---
id: dec.split-todo-form
nodes: [firth.governance.loop]
status: accepted
related: [dec.loop-autonomy, dec.halt-recovery]
date: 2026-08-10
---

# Split Todo Form: Open Parents, Requires Edges

## Context

The loop parked fail-closed on 2026-08-10 (incident a17dcb275c6b) with no
eligible unit. Selection starved because four split parents
(`elaborator-implementation`, `smt-adapter-integration`,
`smt-lean-adapter-proofs`, `req-r5`) plus two later ones
(`mvp-agent-gate`, `mvp-agent-authoring`) were `status: blocked` with the
prose line `blocked on sub-todos: <ids>` while their children were long
`done` (the elaborator children merged as PRs #51-#53). The prior split
rule relied on "the iteration completing the last child flips the parent
to `done`": cross-unit bookkeeping outside any child's own scope, which no
iteration ever performed, and a flip to `done` is wrong whenever the
parent carries residual integration criteria. dec.loop-autonomy clause 3
already classifies such parents as defects of the iteration that parked
them; this decision removes the mechanism that keeps producing them.

## Decision

1. **Split parents stay `open`.** A decomposition iteration creates the
   child todos and appends every child slug to the parent's `Requires:`
   line. No status change, no `blocked on sub-todos:` line, no flip
   bookkeeping. The selector's existing validated dependency machinery
   surfaces the parent as `ineligible_open` until the last child is done
   and as eligible immediately after; the parent's own iteration then
   verifies its acceptance criteria (residual integration work, or a
   verified `done` flip as the whole unit).

2. **Scope reroutes use `Requires:` too.** A prerequisite discovered
   during Scope is authored as an open todo and appended to the current
   unit's `Requires:`; the unit stays `open`.

3. **`blocked` is machine-reserved for clause 3 classes.**
   `select_unit.py --validate` rejects any blocked todo that does not
   carry an `External-evidence:` or `Failing-check:` line, so a
   convenience-blocked todo can no longer land. Blocked todos remain
   never selected and never auto-unblocked; the starved-selector rule
   (dec.loop-autonomy clause 4) is unchanged.

4. **Migration.** The six defective parents above move to `open` with
   their children in `Requires:` (three become eligible at once, three
   wait as `ineligible_open` on open children).
   `recover-scope-ecosystem-stdlib`, whose entire preserved diff (four
   stdlib label lines) is verified present on `origin/main` via PR #98,
   resolves `done` with the resolution recorded in its body.
   `recover-elaborator-pipeline-boundary` stays quarantined-blocked - its
   12-file preserved diff is not proven superseded - and gains the
   clause-3 `External-evidence:` line naming the outstanding maintainer
   disposition.

## Consequences

- The selection deadlock class "children done, parent stranded blocked"
  is structurally impossible: no state requires an unowned transition.
- Split decomposition and reroute use one dependency convention
  (`Requires:`), validated for unknown slugs and cycles, instead of a
  parallel prose convention the tools cannot check.
- Legitimately blocked todos are now lint-enforced to name their blocker
  in machine-findable form, which is what the halt classifier and any
  recovery delegate read.
