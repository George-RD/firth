# Proposal: de-codex-loop-docs

## Motivation

The loop machinery under `firth.governance.loop` is written as a Codex-specific
launch contract: the runbook pins a Codex CLI version and its approval flags,
the injected command asserts "this harness (Codex) has no Skill tool", and the
`dec.autonomous-loop` record calls the runbook Codex-facing. Development is no
longer driven by orchestrating Codex agents, so the harness name is now stale
provenance masquerading as a requirement. The one-unit-per-session loop itself
stays: only the harness coupling in the prose is wrong.

## Scope

- Rewrite `docs/loop-runbook.md` as a harness-neutral launch contract: state
  the harness requirements as capabilities (non-interactive session, fixed
  re-injected prompt, workspace write, network for `git push` and `gh`) and
  give the driver loop in terms of a caller-supplied agent command.
- De-Codex `.claude/commands/firth-loop.md`: frontmatter description and tags,
  and the required-reading preamble that justified reading files by path.
- Fix the `AGENTS.md` pointer to the runbook.
- Amend `meta/decisions/autonomous-loop.md` wording so the accepted decision
  describes the runbook and selector without naming a harness.

## Out of scope

- No change to the loop procedure, terminal tokens, preflight gates, recovery
  or landing skills, or `tools/loop/` behaviour.
- No blueprint change: `firth.governance.loop` already claims `.claude`,
  `tools/loop`, and `docs` at path level, and no file is added, moved, or
  removed.
- No rewriting of `meta/changes/autonomous-loop/`; a landed proposal records
  what was proposed at the time.
- No product source, spec, or todo changes.
