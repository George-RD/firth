# Proposal: mvp-completion-profile

## Motivation

The loop's termination predicate was whole-matrix: every PRD scope bullet,
R1-R17, and S1-S7 discharged. The maintainer's endpoint for this phase is
narrower and needs to be deterministic: a working Firth language that an
AI, given a language guide and the agent interface, can use to build and
run basic applications. Under the old predicate the run would continue
through editor tooling, signature search, a fuzzing campaign, stdlib
self-hosting, and a pass-rate study, and could never emit `LOOP EXHAUSTED`
while S6 awaits third-party evidence.

## Scope

- A `[completion]` profile and per-row `milestone` tags in
  `tools/loop/obligations.toml`, with the `mvp` profile active.
- Profile-aware `coverage.py` (termination, generation, todo gate) and
  `select_unit.py` (selection filter, cross-profile `Requires` validation),
  with boundary tests in both suites.
- The `mvp-agent-authoring` acceptance row and its definition in
  dec.mvp-completion clause 4.
- Wording updates in `.claude/commands/firth-loop.md`,
  `docs/loop-runbook.md`, and `AGENTS.md`.
- The status dashboard (deployed beside the loop, source in the
  maintainer's infrastructure repository) relabels its completion ring as
  the active profile and shows the post-mvp rows as visible roadmap.

## Out of scope

- Any change to `meta/decisions/loop-autonomy.md` (superseded in part by
  the new decision, text untouched).
- Any change to the PRD, the frozen kernel spec, or product code.
- Discharging or descoping any obligation: post-mvp rows remain in the
  matrix, undischarged and visible.
