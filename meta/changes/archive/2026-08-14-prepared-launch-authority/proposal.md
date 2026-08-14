# Proposal: prepared-launch-authority

## Motivation

The normal preparation chain currently grants the model worktree lease directly
after worktree creation. That leaves the lease bound to an identity supplied by
the same transition rather than an independently observed fresh prepared
container and cgroup. A stale or replaced runtime could therefore receive the
model writer lease before the launch boundary has been reconciled.

## Outcome

A fresh normal iteration is admitted only after the ordered chain
`mirror-current -> branch-created -> worktree-created -> prepared-launched ->
model-leased`. The host-owned prepared-launch effect is followed by an
independent observation that binds a fresh `container_id` and `cgroup_id`; the
lease request consumes those exact observed identities. The installed Firth
projection is byte-for-byte generated from the governed operator policy.

## Acceptance boundary

The acceptance boundary is `tools/loop/prepare_iteration.py` with the installed
`tools/loop/authority-policy.projection.json` and its focused tests. A valid
fresh fixture must issue requests in the five-stage order and carry the observed
container and cgroup identities from `normal.prepared-launch` into
`normal.lease.grant`. Missing, stale, or mismatched launch identities must fail
closed before a lease request.

## Evidence

- `python3 tools/loop/test_prepare_iteration.py` passes the fresh-chain and
  rejection cases, including launch identity binding and request ordering.
- `python3 tools/loop/test_landing_gate.py` remains the changed-contract gate
  for projection/template-shape compatibility.
- The projection generator output from the governed operator policy is installed
  verbatim and its policy/projection digests remain bound.

## Out of scope

- Host adapter implementation, container creation, lease ACL mutation, or state
  ticket issuance in the operator repository.
- Legacy marker-absent loop behavior, recovery semantics, or the landing skill.
- Any broad Firth, Lean, Rust, Cairn, or deployment validation battery.
