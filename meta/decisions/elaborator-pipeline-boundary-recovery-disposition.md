---
id: dec.elaborator-pipeline-boundary-recovery-disposition
nodes: [firth.toolchain.elaborator, firth.governance.loop]
status: accepted
related: [dec.loop-autonomy, dec.split-todo-form]
date: 2026-09-03
---

# Disposition of the preserved elaborator pipeline-boundary branch

## Context

`todo.recover-elaborator-pipeline-boundary` has carried `status: blocked`
since 6 August with this external-evidence line:

> maintainer disposition of branch `loop/todo.elaborator-pipeline-boundary`
> (tip 4298015952a2): retain or discard the preserved 12-file
> pipeline-boundary diff against the pipeline implementation that later landed
> on main.

Under `dec.loop-autonomy` clause 3 the loop may not resolve this itself, and
under clause 4 a surviving external-evidence blocker holds exhaustion open.
The disposition is a maintainer call, and this decision records it together
with the evidence it rests on.

The branch has moved since the record was written: its tip is now
`54ff8e3f4081`, with `4298015952a2` as its base and two later
`todo.recover-elaborator-pipeline-boundary` commits that preserved additional
work. The evidence below was taken against the current tip, not the recorded
one.

## Evidence

Comparing the branch tip with `main`, restricted to the fourteen files the
branch's three commits touch:

| File | Branch content main lacks |
| --- | --- |
| `src/elaborator/Firth/Pipeline.lean` | none; the two are byte-identical |
| `src/elaborator/Firth/StackEffect.lean` | none; byte-identical |
| `src/elaborator/FirthElaborator.lean` | none; byte-identical |
| `src/elaborator/FirthPipelineCli.lean` | none; byte-identical |
| `src/elaborator/FirthPipelineTest.lean` | none; `main` adds 196 lines |
| `src/agent/FirthAllTest.lean` | none; `main` adds 2 lines |
| `meta/decisions/elaborator-pipeline-boundary.md` | none; byte-identical |
| `meta/changes/archive/2026-08-06-elaborator-pipeline-boundary/*` | none; byte-identical |
| `meta/todos/todo.elaborator-pipeline-boundary.md` | none; byte-identical |
| `lakefile.toml` | one line: a `defaultTargets` list that the current list strictly extends |
| `src/elaborator/refinement-proof-module.sha256` | none of substance; regenerated hashes |

The preserved pipeline-boundary implementation is therefore already on `main`,
character for character, and `main` has since moved ahead in the same files.

## Decision

Discard. The branch holds no content `main` lacks, so retaining it would
preserve nothing, and `todo.recover-elaborator-pipeline-boundary` is
`done`: its purpose was to hold the question open until it could be answered
with evidence, and it now is.

The branch ref itself is left in place. Deleting a `loop/*` ref is a forge
operation the loop's isolation rules reserve, and nothing depends on its
absence; a maintainer may remove it at leisure.

## Consequences

- No external-evidence blocker remains in the tracker, so
  `dec.loop-autonomy` clause 4's classification report is no longer reachable
  through this todo.
- The recovery record in the todo stays as written. It is the historical
  account of what was preserved and why; this decision is the answer to it,
  not a rewrite of it.
