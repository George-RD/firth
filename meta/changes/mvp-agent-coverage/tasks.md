# Tasks: mvp-agent-coverage

- [x] Assert that the obligations matrix names the pinned gate, that the gate
      exists, and that it is the only pinned gate.
- [x] Assert that the manifest agrees with the matrix about the gate path.
- [x] Pin `completion.profile` and the authoring row's milestone so a wiring
      change cannot move the goal layer.
- [x] Assert the manifest remains the authoritative inventory: at least the
      declared minimum of applications, and at least three.
- [x] Check every pinned acceptance input for staleness without a toolchain.
- [x] Pin all four entry points at `gate-required`.
- [x] Confirm `python3 tools/loop/coverage.py --run-gates` reports the gate
      present and passing.
