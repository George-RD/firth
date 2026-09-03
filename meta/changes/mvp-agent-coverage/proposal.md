# Proposal: mvp-agent-coverage

## Motivation

`coverage.py` already executes any pinned gate under `--run-gates`, and
`test_coverage.py` already covers that mechanism over synthetic trees: a
missing gate, a failing gate, a hung gate, and a passing gate each behave as
`dec.mvp-completion` clause 4 requires. What was untested is the live binding.
Nothing asserted that the real matrix names the real gate, that the manifest
agrees with it, that the completion profile had not moved, or that the pinned
acceptance hashes still match their files.

A stale hash would previously surface only when the gate ran, which needs a
Lean and a Rust toolchain. That is the wrong place to discover it.

## Scope

- `tools/loop/test_mvp_agent_coverage.py`: the live bindings, and a staleness
  check over every pinned acceptance input.
- The `mvp-agent-authoring` obligation, which these two units together
  discharge.

## Out of scope

- Any change to `coverage.py`. Its gate mechanism is already correct and
  already tested; this unit adds the binding assertions around it.
- Any change to `completion.profile` or the milestone tags. They are goal
  layer under `dec.loop-autonomy` clause 2a, and one of the new tests pins
  them precisely so that a wiring change cannot move them.
