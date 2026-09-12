# Design: mvp-agent-coverage

## Approach

The new suite reads repository configuration rather than the todo tracker, and
runs no build. That keeps it inside the spirit of the control-plane convention
while letting it assert the things a synthetic tree cannot: that
`obligation.mvp-agent-authoring` pins `tools/loop/mvp_agent_gate.py`, that the
gate is the only pinned gate, that `mvp_agent_manifest.toml` names the same
path, that `completion.profile` is still `mvp`, and that the authoring row is
inside the active profile.

Staleness is checked here rather than only inside the gate. The guide, the
three pinned interface files, and every application source are hashed and
compared with the manifest, and each transcript's recorded output hash is
compared with the checked-in application it claims to have produced. A stale
hash therefore fails in under a second and without a toolchain, instead of
surfacing only when a Lean and a Rust build have completed.

One test pins the four entry points at `availability = "gate-required"`. All
four adapters exist now, and that is exactly when the temptation to relax the
manifest appears. The manifest records what the gate must exercise, not what
happens to be installed.

## Changes

ADDED:
- `tools/loop/test_mvp_agent_coverage.py`.

MODIFIED:
- `AGENTS.md`: the suite in the command list, with a note on why it is the
  deliberate exception to the synthetic-tree convention.
