# Tasks: autonomous-loop

- [ ] Add .claude/commands/firth-loop.md with Codex orchestration and guards.
- [ ] Add .claude/skills/firth-loop-recovery/SKILL.md.
- [ ] Add .claude/skills/firth-loop-landing/SKILL.md.
- [ ] Add tools/loop/select_unit.py and verify stable selection JSON.
- [ ] Add tools/loop/test_select_unit.py with synthetic-tree unittest coverage.
- [ ] Add tools/loop/obligations.toml, coverage.py, and test_coverage.py for
      deterministic PRD coverage and dependency-gated backlog generation.
- [ ] Wire selector and coverage tests and validation into the command and
      landing verification gates.
- [ ] Add docs/loop-runbook.md and an AGENTS.md Development Commands pointer.
- [ ] Add Governance and Loop path claims to cairn.blueprint.
<!-- host-language-decision is owned by graph-remediation, not this change -->
- [ ] Record scan, hook, selector, and change-accept gate evidence.
- [ ] Keep edge reversal, Requires backfill, new todos, and gap registrations
      in the separate graph-remediation change.
## Gate evidence

- `cairn scan`: exit 0, zero Errors; expected language-unknown warnings remain.
- `cairn hook all`: exit 0.
- `cairn islands`: one island containing `firth` and 22 nodes.
- `python3 tools/loop/test_select_unit.py`: exit 0, all tests green.
- `python3 tools/loop/test_coverage.py`: exit 0, all tests green.
- `python3 tools/loop/coverage.py --validate`: exit 0.
- `python3 tools/loop/select_unit.py --validate`: exit 0.
- Selector default: exit 0, `next` is `diagnostic-schema`;
  `host-language-decision` is blocked and absent from `eligible`.
- `cairn change accept autonomous-loop`: exit 1. Cairn 0.3.0 runs strict
  validation and fails on existing unresolved-gap and governance warnings,
  including uncovered contract and gitignored `.claude` path warnings. Do not
  use accept as this change's gate; the evidence above is the real gate.
