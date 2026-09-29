---
node: firth.toolchain.agent
status: open
created: 2026-09-29
---

# Say "type-checks" or run refinements before an edit's hint says "checks"

Raised by Codex on #185. A hint that offers a checked edit ends with
"With that edit `w` checks." when `outcomeAlone` (`src/elaborator/Firth/Pipeline.lean`)
finds no error. `outcomeAlone` runs erasure and the type checker only. When a
caller supplies a `PipelineConfig.refinementBuilder`, the edited word can
still fail its refinements, so "checks" says more than was checked.

The three kinds of checked edit share this sentence: call order
(`withCallAccount`), `locals` order (`checkLocalsEdits`) and refused `if`s
(`staleEdit`, `missingEdit`, via `editOutcome`). With the default empty
refinement builder, which the eval and the agent interface use, the two
agree.

## To do

- Either run the refinement stage in `outcomeAlone` when a builder is set, or
  word the outcome as type-checking ("With that edit `w` type-checks") for all
  three kinds at once.
- Add a test with a refinement builder whose obligation the edited word fails,
  so the sentence cannot claim more than was run (planted failure).
