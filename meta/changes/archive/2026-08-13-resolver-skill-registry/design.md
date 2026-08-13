# Design: resolver-skill-registry

## Approach

Land a dormant Firth authority release before implementing or activating the
operator control plane. Firth owns the semantic boundary: closed preflight
classification, ordered preparation requests, the prepared envelope consumed
by OMP, the terminal finaliser contract, validation-only recovery, merge
evidence, and the generated projection of the installed cross-repository
policy.

All mutation remains outside the model process. `prepare_iteration.py` is a
read-only coordinator: it derives exact transition requests but cannot mint
tickets or execute host/forge effects. The state service is the sole ticket
constructor. Each adapter effect is observed before the coordinator advances.
The model receives one selected linked worktree with writable working bytes and
read-only Git metadata. `firth_finalize` submits no caller-provided operational
fields and terminates the session. State then orders model cgroup stop, writer
absence, ACL transfer, lease acquisition, and one stable source snapshot.

The installed `authority-policy.json` in the operator repository is the root
machine-readable manifest. Firth commits only a deterministic generated
projection containing the policy version, policy digest, repository identity,
normal and recovery namespaces, completion TCB, path classes, and transition
template identifiers. Candidate checkouts cannot choose policy.

## Invariants

1. `coverage.py --run-gates` remains the sole authority for
   `LOOP EXHAUSTED`. A ticket, skill, receipt, merge, activation, acknowledgement,
   resume, or UI state is never completion.
2. Normal iteration, halted recovery, and local operator actions occupy
   disjoint issuer namespaces. Only the state service constructs tickets.
3. `recovery-inhibit` blocks ordinary recovery. The only bypass is one
   authenticated `activate-recovery` transaction that validates preparation,
   consumes the already-minted first recovery ticket, commits its exact intent,
   clears the inhibit, and sets the irreversible authority marker atomically.
4. `normal-finalizer-active` and `resolver-authority-active` are absent in this
   dormant release. Existing normal landing and healer authority therefore
   remain temporarily valid.
5. Recovery inside OMP can inspect and validate prepared state but cannot
   stash, reset, delete, push, acknowledge, relaunch, or request mutation.
6. Review receipts are external attestations bound to the exact head and tree.
   They never appear inside the candidate tree they hash.
7. The selected todo can change only through its template-owned expected-state
   to final-state transition. Every other byte of that todo and every other todo
   must remain unchanged.

## Components

### Preflight classifier

`preflight_state.py` accepts canonical repository observations rather than
running commands. It returns schema 1 and exactly one closed verdict:
`fresh`, `dirty-known-unit`, `dirty-unsafe`, `open-pr`,
`multiple-open-prs`, `merged-tip-cleanup`, `recover-todo`,
`surviving-adoptable`, `surviving-orphan`, `stale-park`,
`unsafe-committed-park`, or `observation-failed`.

Forge list observations carry explicit completeness and failure state.
Pagination is performed by the caller until complete. Empty complete data and
failed observation are distinct. Todo parsing and dependency validation reuse
the selector's existing parser.

### Iteration preparer

`prepare_iteration.py` consumes the current main identity, preflight
observation, selector result, and a state-client interface. It requests four
separate transitions in order: sanitized mirror fetch, CAS branch creation,
linked-worktree creation, and lease grant. Each returned observation must bind
the same repository, unit, branch, head, worktree, generation, and policy
digest before the next request. Unsafe or incomplete verdicts return a closed
refusal. Recoverable existing work verifies its bindings without recreating
objects.

The output is a canonical prepared envelope. It contains identities and opaque
receipts only, never repository credentials or mutable ticket fields.

### OMP launch and finalisation

The loop command requires the prepared envelope and installed policy
projection. It does not create branches, worktrees, commits, pushes, PRs, or
merges. It exposes the typed no-argument `firth_finalize` tool. A successful
call is terminal for that OMP session and does not claim iteration or project
completion.

Finalisation follows separate observed transitions:
`seal-requested -> model-stopped -> acl-transferred -> lease-acquired`.
Only then may a no-authority helper snapshot stable working bytes. Publication,
review, merge, acknowledgement, and progress are later transitions.

### Landing admission and recovery

For prepared mode, the host broker invokes the pure
`tools/loop/landing_gate.py::validate_landing` API before any forge effect.
It validates the selected todo's exact sanctioned final state, exact
head/tree finaliser receipt, two external review receipts, installed policy
digest, and merge class. Protected and manual-root changes cannot auto-merge.
The legacy landing skill does not invoke this API and remains unchanged on its
marker-absent path. The recovery skill is reduced to deterministic validation
of an existing prepared envelope and binding; it performs no mutation.

## Changes

ADDED:
- Accepted `dec.resolver-skill-registry` authority decision.
- `tools/loop/preflight_state.py` and exhaustive classifier tests.
- `tools/loop/prepare_iteration.py` and coordinator/finalisation tests.
- Generated installed-policy projection and digest-drift checks.

- `.claude/commands/firth-loop.md` consumes a prepared envelope and terminates
  through `firth_finalize`.
- `.claude/skills/firth-loop-recovery/SKILL.md` becomes validation-only.
- The host broker's `landing_gate.py::validate_landing` API enforces prepared
  final-state and external exact-object admission before forge effects; the
  legacy landing skill remains unchanged.
- Driver, review, and TCB boundary checks cover finalisation and policy drift.
- Runbook and recovery mandate describe namespaces, leases, approvals, cutover,
  and manual recovery.

REMOVED:
- Branch creation and direct publication authority from OMP procedures.
- Recovery mutations from the in-loop recovery skill.

RENAMED:
- None.

## Rollout

This change is dormant. The operator control plane may be installed and tested
only after it lands. Normal cutover later sets `normal-finalizer-active` after
revoking direct model Git credentials. Halted recovery remains inhibited until
the separately authenticated irreversible activation transaction. Legacy
executors are deleted only after both cutovers and parity evidence succeed.
