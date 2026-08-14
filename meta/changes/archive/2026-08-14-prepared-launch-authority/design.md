# Design: prepared-launch-authority

## Approach

Adopt the governed operator policy's normal transition graph as the source of
truth. Regenerate the Firth projection from the operator manifest, then make
the Firth coordinator validate the same graph before requesting any transition.
The fresh path performs one state request and independent observation per edge:
mirror fetch, CAS branch creation, linked worktree creation, prepared host
launch, and lease grant.

`normal.prepared-launch` receives only immutable repository, incident, unit,
branch, head, mirror, and worktree bindings. Its observed result must provide
new non-empty `container_id` and `cgroup_id` identities and the expected
prepared-running/no-writer facts. The subsequent `normal.lease.grant` request
includes those observed identities, and its response must bind them unchanged.
Any missing, reused, or inconsistent identity is a closed refusal.

The projection validators share the installed projection's digest and
canonical structure. `prepare_iteration.py` enforces the exact governed normal
template IDs and request field sets used by the coordinator; `landing_gate.py`
pins the installed projection bytes/digest and top-level schema, and validates
the normal-template map's canonical structure rather than carrying a stale
subset of template IDs. Tests use state fakes to prove the launch call occurs
before lease and that lease cannot proceed from invented or stale runtime
identities.

## Changes

ADDED:
- Accepted decision amendment for the prepared-launch identity boundary.
- `normal.prepared-launch` in the Firth projection and coordinator chain.
- Focused tests for fresh launch observation and lease identity propagation.

MODIFIED:
- `tools/loop/prepare_iteration.py` to validate the five-stage chain and bind
  observed runtime identities into lease requests.
- `tools/loop/landing_gate.py` to accept the governed normal template set,
  including prepared launch.
- `tools/loop/authority-policy.projection.json` to exact generated operator
  policy bytes.
- `tools/loop/test_prepare_iteration.py` and `tools/loop/test_landing_gate.py`
  for the changed contract.

REMOVED:
- The direct worktree-to-lease transition in fresh preparation.

RENAMED:
- None.
