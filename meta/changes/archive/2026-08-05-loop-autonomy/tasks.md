# Tasks: loop-autonomy

- [x] Author meta/decisions/loop-autonomy.md (accepted, governance nodes).
- [x] Amend .claude/commands/firth-loop.md per clauses 2-6, including the language-gates binding (camel-case `testDriver`, nested VM crate gates, no root cargo).
- [x] Refresh docs/loop-runbook.md: cairn prerequisite, Lean and Rust toolchain prerequisites, omp launch, driver exit-status contract, completion semantics, dry-run snapshot with product gates.
- [x] Correct stale AGENTS.md state claims and add the dec.loop-autonomy pointer.
- [x] Verify: control-plane tests, cairn scan zero Errors with findings identical to baseline modulo this change's artefacts, cairn hook all exit 0, lake build and lake test exit 0, VM crate fmt/clippy/test exit 0, omp print-mode token contract demonstrated, and every driver stop path exercised against a stub harness.
