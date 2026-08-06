---
node: firth.toolchain.elaborator
status: blocked
created: 2026-08-06
---

# Recovery record

Branch: `loop/todo.elaborator-pipeline-boundary`
Tip: `4298015952a29201f8d4304cadb95950e456d6b6`
PR state: no PR (`gh pr list --state all --head loop/todo.elaborator-pipeline-boundary` returned an empty list).

The surviving branch changes the Lake package wiring, adds a Cairn change proposal and an accepted elaborator pipeline decision, updates the test driver and stack-effect export, and adds `src/elaborator/Firth/Pipeline.lean`, `src/elaborator/FirthPipelineCli.lean`, and `src/elaborator/FirthPipelineTest.lean`. The diff is 12 files with 388 insertions and 4 deletions versus `origin/main`; it preserves the branch's existing pipeline-boundary implementation for maintainer resolution.
