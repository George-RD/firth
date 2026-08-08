# Tasks: mvp-completion-profile

- [x] Author dec.mvp-completion (accepted, maintainer-authored) defining
      the profile mechanism, the MVP boundary, and the acceptance gate.
- [x] Add `[completion]`, milestone tags, and `mvp-agent-authoring` to
      `tools/loop/obligations.toml`.
- [x] Make `coverage.py` profile-aware (termination, generation, node
      gating, todo gate, validation).
- [x] Make `select_unit.py` profile-aware (selection filter,
      cross-profile Requires validation, fail-closed matrix parsing).
- [x] Add boundary tests to `test_coverage.py` and `test_select_unit.py`.
- [x] Update `.claude/commands/firth-loop.md`, `docs/loop-runbook.md`, and
      `AGENTS.md` completion wording.
- [x] Run control-plane suites, both validators, `cairn scan`,
      `cairn hook all`; land on `origin/main` outside the loop.
