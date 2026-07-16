# Design: autonomous-loop

## Approach

Port Cairn's one-unit-per-session architecture for unattended Codex execution:
a read-only first-match preflight, persistent ../firth-loop worktree, derived
loop/* branches, fail-closed recovery, explicit staging, one squash commit,
and typed terminal tokens. Codex reads the named procedure files in full
because it has no Skill tool.

The installed Cairn binary is bound and verified. The selector tool validates
todo frontmatter and Requires edges, detects cycles and malformed files, and
returns stable JSON. Lint Errors retain precedence. A maintainer-blocked
todo is never auto-unblocked. Language gates remain staged for the future Lean
project, with expected empty-path language warnings non-blocking.

The Governance container owns loop machinery outside Firth's four product
layers. The Loop module claims .claude, tools/loop, and docs. Selector tests use
stdlib unittest with temporary synthetic todo trees, never the repository's
real tracker. The Codex-facing runbook is descriptive; the injected command
remains normative. The accepted decision
records why this operational boundary exists and identifies
meta/changes/autonomous-loop as its provenance.

## Changes

ADDED:
- .claude/commands/firth-loop.md
- .claude/skills/firth-loop-recovery/SKILL.md
- .claude/skills/firth-loop-landing/SKILL.md
- tools/loop/select_unit.py
- tools/loop/test_select_unit.py
- tools/loop/obligations.toml
- tools/loop/coverage.py
- tools/loop/test_coverage.py
- docs/loop-runbook.md
- Governance container and Loop module paths in cairn.blueprint
- meta/decisions/autonomous-loop.md

MODIFIED:
- AGENTS.md (Development Commands pointer to the runbook)
- .claude/commands/firth-loop.md (selector test verification gate)
- .claude/skills/firth-loop-landing/SKILL.md (selector and coverage gates)
<!-- host-language-decision is owned by graph-remediation, not this change -->

REMOVED:
- None.

RENAMED:
- None.

## Known Cairn 0.3.0 limitation

`cairn scan` reports `CAIRN_PATH_GITIGNORED` for `.claude` even though
`git check-ignore -v .claude` reports no match, and the dot-directory contents
are consequently treated as unreconciled or Ghost paths. This was recorded with
`cairn feedback`; it is a known Cairn 0.3.0 reconciliation limitation, not a
loop blueprint error.

## Provenance boundary

Edge reversal, Requires backfill, new todos, and gap registrations belong to
the concurrent graph-remediation change, not this change. This change consumes
the resulting graph state but does not claim those edits.
