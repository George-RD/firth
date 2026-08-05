# Design: de-codex-loop-docs

## Approach

Treat the harness as a capability contract rather than a named product. Every
Codex-specific claim in the loop prose reduces to one of four capabilities:
run a session non-interactively, re-inject one fixed prompt per iteration,
write to the workspace, and reach the network for `git push` and `gh`. The
runbook states those capabilities and drives iterations through a
maintainer-supplied `AGENT` command, so any harness that satisfies them can run
the loop without the runbook being rewritten again.

The injected command keeps its normative status. Its "no Skill tool" preamble
becomes harness-independent: read the named files by exact path, in full, and
never assume a skill-loading mechanism exists. That instruction is strictly
safer than the Codex-conditioned version, because a harness that does have a
Skill tool still reads the same files.

`dec.autonomous-loop` keeps its substance (Governance container, Loop module,
path claim, command trio, deterministic selector) and loses the harness name in
two phrases. No status change: the decision is still accepted, and the module
claim it justifies is unchanged.

## Changes

ADDED:
- None.

MODIFIED:
- `docs/loop-runbook.md`: harness capability prerequisites replace the
  `codex --help` check; launch section drives a caller-supplied `AGENT`
  command instead of `codex exec -a never -s workspace-write`; the Codex
  version note and `--full-auto` alias section are dropped. Terminal tokens,
  health review, and dry-run preflight are unchanged.
- `.claude/commands/firth-loop.md`: frontmatter `description` and `tags`, the
  "sole normative orchestrator" phrasing, and the required-reading preamble.
- `AGENTS.md`: the Development Commands pointer to the runbook.
- `meta/decisions/autonomous-loop.md`: two harness-naming phrases.

REMOVED:
- Codex CLI version and flag guidance in the runbook, which documented a
  specific installation rather than the loop contract.

RENAMED:
- None.
