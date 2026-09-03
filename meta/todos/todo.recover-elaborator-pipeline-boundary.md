---
node: firth.toolchain.elaborator
status: done
created: 2026-08-06
---

# Recovery record

Branch: `loop/todo.elaborator-pipeline-boundary`
Tip: `4298015952a29201f8d4304cadb95950e456d6b6`
PR state: no PR (`gh pr list --state all --head loop/todo.elaborator-pipeline-boundary` returned an empty list).

The surviving branch changes the Lake package wiring, adds a Cairn change proposal and an accepted elaborator pipeline decision, updates the test driver and stack-effect export, and adds `src/elaborator/Firth/Pipeline.lean`, `src/elaborator/FirthPipelineCli.lean`, and `src/elaborator/FirthPipelineTest.lean`. The diff is 12 files with 388 insertions and 4 deletions versus `origin/main`; it preserves the branch's existing pipeline-boundary implementation for maintainer resolution.

External-evidence: maintainer disposition of branch `loop/todo.elaborator-pipeline-boundary` (tip 4298015952a2): retain or discard the preserved 12-file pipeline-boundary diff against the pipeline implementation that later landed on main.

## Disposition

Discarded, per `dec.elaborator-pipeline-boundary-recovery-disposition`. The
branch tip has since moved to `54ff8e3f4081`, and a file-by-file comparison
with `main` over the fourteen files its commits touch found nothing `main`
lacks: `Pipeline.lean`, `StackEffect.lean`, `FirthElaborator.lean`,
`FirthPipelineCli.lean`, the decision and the archived change are
byte-identical, `FirthPipelineTest.lean` and `FirthAllTest.lean` are strictly
extended on `main`, and the only other difference is a `defaultTargets` list
that the current one extends. The branch ref is left in place for a
maintainer to remove.
