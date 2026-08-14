---
id: dec.prepared-launch-authority
nodes: [firth.governance.loop]
status: accepted
related: [dec.resolver-skill-registry]
date: 2026-08-14
---
# Prepared Launch Identity Before Lease

## Context

dec.resolver-skill-registry establishes a prepared normal iteration and a
worktree lease, but its initial transition description allowed the lease to
follow worktree creation directly. A lease grants the model writer authority.
That authority must bind an independently observed fresh runtime, not an
identity asserted by the lease request or inherited from a stale container.
The operator policy now defines `normal.prepared-launch` as the fixed host
transition between worktree creation and lease grant.

## Decision

This decision amends dec.resolver-skill-registry's normal preparation chain at
its launch boundary only. The chain is exactly:

`mirror-current -> branch-created -> worktree-created -> prepared-launched ->
model-leased`.

After `normal.worktree.create`, state issues one
`normal.prepared-launch` ticket for the exact repository, policy, incident,
unit, branch, head, mirror, and worktree identities. The fixed host adapter
starts the prepared service. An independent observer must then reconcile the
operation as `prepared-launched` and return fresh, non-empty `container_id`
and `cgroup_id` values bound to every immutable field through `worktree_id`.

Only after that observation may state issue `normal.lease.grant`. Its request
must consume the observed container and cgroup identities exactly, along with
the same immutable fields. The lease postcondition must bind those identities
unchanged and prove model-only working-tree write access with Git metadata
read-only. Missing, stale, reused, contradictory, or unobserved runtime
identity fails closed and cannot be repaired by retrying the adapter call.

The prepared envelope and OMP session are downstream of `model-leased`; they
must contain the same observed runtime identities. Recovery, legacy
marker-absent behavior, finalisation, forge publication, and completion
authority remain unchanged. This amendment adds no new authority namespace or
capability.

## Rationale

A worktree can outlive its container, and container names or configured model
identities are not proof that a fresh process/cgroup is running. Observing the
host effect before granting the writer lease makes the lease bind to the exact
runtime that can write, while preserving intent, effect, and independent
reconciliation for each protected transition.
