# Proposal: autonomous-loop

## Motivation

Firth needs a durable one-unit-per-session loop for unattended Codex runs. The
loop must preserve Cairn's fail-closed recovery and landing guards while making
Requires selection deterministic and graph-visible.

## Scope

- Add the Firth loop command, recovery skill, and landing skill.
- Add the stdlib-only deterministic selector at tools/loop/select_unit.py.
- Add selector behaviour tests at tools/loop/test_select_unit.py and the
  obligations matrix, coverage report, and coverage tests at tools/loop/; wire
  all control-plane checks into the loop verification gates.
- Add the Codex-facing launch runbook at docs/loop-runbook.md and a short
  pointer under Development Commands in AGENTS.md.
- Claim .claude, tools/loop, and docs under a Governance container and Loop module.
<!-- host-language-decision is owned by graph-remediation, not this change -->

## Out of scope

- No source implementation, Lean project, or VM work.
- No edge reversal, Requires backfill, new todo generation, or gap registration
  from the concurrent graph-remediation change.
- No commits, PRs, or change acceptance during this drafting session.

Ownership: `todo.host-language-decision.md` is owned by graph-remediation, not by this change (autonomous-loop).