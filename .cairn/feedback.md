# Cairn feedback log

Friction recorded by `cairn feedback`. Triage entries into upstream issues at
https://github.com/cairn-framework/cairn/issues/new

## 2026-07-16T17:01:15Z (cairn 0.3.0)

Cairn 0.3.0 reports CAIRN_PATH_GITIGNORED for .claude even though git check-ignore -v .claude returns no match; files under .claude are consequently treated as unreconciled or Ghost. Please investigate dot-directory reconciliation.

## 2026-07-17T05:00:55Z (cairn 0.5.0)

select_unit.py silently drops Requires edges written as a ## Requires heading with bullets and fails open (dependents become eligible); parser only accepts inline Requires: lines

## 2026-07-18T10:10:03Z (cairn 0.7.0)

change accept elaborator-stack-effect-inference ran cargo build/clippy/fmt/test at the repository root even though the declared Rust crate is src/runtime/vm; all equivalent crate-local gates pass, but acceptance failed with no root Cargo.toml. Its cairn lint --strict elaborator-stack-effect-inference step also returned only validation failed.

area: acceptance
severity: major

## 2026-08-04T14:01:13Z (cairn 0.9.0)

cairn 0.9.0 change accept runs the cargo battery from the repository root, but this repo has no root Cargo.toml: the only crate is src/runtime/vm. cargo build/clippy/fmt/test therefore report FAILED for every change (verified identical on a pristine origin/main worktree for the already-landed autonomous-loop change), so the acceptance gate is unreachable. Expected: detect nested crate manifests, or skip cargo steps when no root manifest exists. Also, cairn lint --strict exits 1 on pre-existing repository warnings (unresolved gaps, CAIRN_CONTRACT_LEAF_UNCOVERED, CAIRN_PATH_GITIGNORED), which makes the strict step in the battery permanently red.
