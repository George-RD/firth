---
id: dec.resolver-skill-registry
nodes:
  - firth.governance.loop
status: accepted
date: 2026-08-13
refines:
  - dec.halt-recovery
  - dec.rc3-recovery
related:
  - dec.healer-delegate
  - dec.recovery-model-credential
  - dec.review-mandatory
  - dec.loop-autonomy
  - dec.mvp-completion
  - dec.tcb-boundary-inventory
---
# Issuer-bound Resolver Authority and Monotonic Skill Registry

## Context

The bounded recovery delegate and host healer split model judgement from a
small deterministic executor, but their authority is distributed across the
loop container, host scripts, prompt procedures, JSONL ledgers, and mutable
checkout state. The unit branch is created after OMP starts. A prompt
instruction, rather than a deterministic launch boundary, therefore separates
startup from the first source write. Recovery, publication, deployment,
acknowledgement, and completion are also represented too loosely to support a
larger repair plane without concentrating credentials.

The resolver needs to reconcile basic state, prepare reviewed repairs, and
learn declarative recovery workflows. Giving a model process shell, Git,
repository, forge, deployment, host, state-store, or upstream model-broker
authority would turn generated text into an execution path. Letting registry
data define adapters or safety checks would let self-improvement widen that
authority.

This decision is maintainer-authored and lands dormant. It defines the
authority that later operator services may implement. It does not activate
those services, revoke the current normal landing path, or disable the healer.

## Decision

### 1. Credential deterministic adapters, never a model process

Models choose among opaque, issuer-bound tickets already constructed by the
state service. They never construct tickets or provide operational fields.
Separate state, host-ops, forge, deploy, and model-gateway services hold
non-overlapping authority. Resolver, controller, worker, reviewer, gate,
dashboard, collector, parser, and model processes are no-authority clients.

The scoped trusted computing base is explicit:

- `firth-resolver-state` is trusted for installed-policy, admission, ticket,
  intent, observation, uniqueness, and audit integrity.
- `firth-host-ops` is trusted only for manifest-listed container, cgroup,
  worktree, ACL, and fixed host effects.
- `firth-forge-broker` is trusted only for the named Firth repository and its
  fixed publication and automatic merge-group RPCs.
- `firth-deploy-broker` is trusted only for manifest-listed immutable release
  and service-lifecycle effects.
- `firth-model-gateway` is trusted only for reservation, immutable model
  identity, destination, call, token, cost, concurrency, and expiry limits.

The host kernel, host root, and each scoped service are trusted for the
authority they hold. This design contains compromise of no-authority clients.
It does not claim to contain a compromised authority service or hostile host
root. A stronger claim requires separate control, forge, model, and actuator
VMs with signed one-use capabilities.

### 2. Authority namespaces are fixed and disjoint

The installed manifest declares three issuer namespaces:

1. The normal Firth controller is the product-development decision principal.
   It may request only the prepared unit's normal launch, finalisation, review,
   publication, merge, acknowledgement, and progress transitions.
2. The host resolver is the halted-recovery and meta-repair decision principal.
   It may request only manifest-listed recovery, repair, registry, and safe
   component-activation transitions for its incident.
3. Authenticated local operator requests form a third namespace. Their exact
   fields and peer identities are fixed in the installed manifest. They cover
   quiesce, protected attestation, recovery activation, and root installation.

`firth-resolver-state` is the sole ticket constructor across every namespace.
It derives exact fields from installed policy and recorded observations.
Controllers, resolver, operator clients, adapters, skills, registries,
receipts, and models cannot mint, alter, copy, or extend a ticket.

A ticket is opaque, single-use, expiring, and authorises at most one protected
external effect. It binds issuer namespace, authenticated requester and peer,
policy and template versions, incident, observation generation and signature,
canonical input and object identities, mandatory preconditions and
postcondition, reservation where applicable, and expiry. A continuation can be
constructed only after state records the next independent observation and the
immutable typestate graph permits the edge.

Normal, operator, and root tickets neither set nor depend on halted-recovery
cutover markers unless their own manifest-listed transition is the cutover.

### 3. Protected effects use intent, effect, and reconciliation

Every protected operation follows:

1. State atomically consumes one ticket and commits the exact operation intent
   and preconditions.
2. One fixed adapter performs one bounded mutation with CAS, lease, and object
   checks.
3. An independent observer records the postcondition and next generation.
4. Timeout, crash, ambiguity, or observation failure records `in_doubt` and
   runs the template's read-only reconciliation probe before any continuation.

Adapters are never generically rerun. A bounded external object mutation is one
effect: a worktree lease or ACL epoch, Git ref, PR, comment, check, control
acknowledgement, accepted-registry marker, release pointer, or service
lifecycle. Local content-addressed scratch artifacts, SQLite bookkeeping,
read-only observations, and redacted projections are not authority effects.

Composite procedures are explicit typestate chains. Each direct effect receives
a fresh ticket. Provider auto-merge after one exact merge-group authorization
check is one pending asynchronous consequence. It is reconciled, not invoked a
second time.

### 4. Branch creation and finalisation are launch boundaries

Before OMP exists, a read-only normal controller observes current main and
closed preflight state, selects one unit, then requests separate state-issued
transitions for sanitized mirror fetch, CAS branch creation, linked-worktree
creation, and lease grant. Host and forge adapters execute one transition at a
time. State observes each postcondition before issuing the next ticket.

The model container receives only the selected worktree. Working-tree bytes are
writable and untrusted. The `.git` file, common Git metadata, index, refs,
branch identity, config, credentials, and every other worktree are read-only or
absent. The branch therefore exists before the first model write without
pretending to ban particular editors, generators, shell commands, or Git
plumbing.

The typed `firth_finalize` tool takes no arguments and submits an internal seal
request for only the prepared unit. It is terminal for that OMP session. State
issues a model-cgroup-stop ticket; host-ops terminates the exact cgroup and
descendants; state observes no writer; separate tickets transfer ACL or
ownership and grant the epoch-bound lease. Only after `lease-acquired` may a
no-authority helper snapshot stable working bytes.

Commit, gates, review, publication, merge authorization, provider consequence,
acknowledgement, resumed progress, and project completion remain separate
observed facts. A stopped model cannot report completion.

`.claude/commands/firth-loop.md` consumes the prepared envelope and may not
create branches or publish directly. `.claude/skills/firth-loop-recovery/SKILL.md`
is validation-only and may not stash, reset, delete, push, acknowledge, or
relaunch.

### 5. Recovery cutover is staged and one-way

Two installed markers control migration:

- While `normal-finalizer-active` is absent, the existing normal landing path
  remains authorised. The dormant authority release adds no parallel writer.
- While `resolver-authority-active` is absent and `recovery-inhibit` is set,
  the authority of `dec.halt-recovery`, `dec.rc3-recovery`, and
  `dec.healer-delegate` remains in force.

Recovery preparation under the inhibit is reversible. It may stop and disable
the healer, acquire leases, import evidence, set
`resolver-cutover-prepared`, and mint the first exact recovery ticket, but
ordinary recovery admission cannot consume that ticket.

The only bypass is one authenticated local operator
`activate-recovery` request bound to that opaque first ticket. One serialized
state transaction verifies the installed policy, global switch, prepared
marker, stopped and disabled healer, leases, evidence, incident, generation,
signature, ticket namespace and expiry. It then atomically clears
`recovery-inhibit`, sets the irreversible `resolver-authority-active` marker,
consumes that exact ticket, and commits its exact operation intent.

Failure before that commit leaves observe-only rollback and healer restoration
authorised. Successful commit supersedes the healer delegate and the old
bounded executors for halted recovery. Failure afterward is reconciled or held;
the healer is never restored. Ordinary recovery admission cannot pass the
inhibit, and no other ticket can set or bypass these markers.

### 6. Installed policy is the immutable authority root

Versioned `authority-policy.json` is the sole machine-readable root manifest.
It contains or digest-binds:

- Firth and operator repository identities and forge App identities;
- normal-auto, resolver-auto, protected-human, and manual-root path classes;
- completion TCB projection;
- issuer namespaces, service identities, socket methods, and peer ACLs;
- canonical schema, closed transition graph, templates, adapters, model roles,
  retry rules, invocation caps, and policy version.

Atomic root installation binds the exact Firth authority commit and tree, the
exact operator policy/release commit and tree, predecessor digest, and result
digest. Firth consumes only a deterministic generated projection carrying that
digest. Candidate checkouts cannot provide policy.

Policy classifies the complete base-to-candidate and
active-release-to-target deltas. Normal-auto Firth may change product source
and tests owned by the base graph plus exactly one template-owned transition
for the prepared todo from its expected state to its sanctioned final state.
No other byte of that todo and no other todo may change. Resolver-auto Firth
cannot change tracker or governance. Governance, completion, tracker, decision,
resolver, runtime, supervisor, infrastructure, policy, credential, service,
bootstrap, deployment, unknown, and capability-expanding paths are protected
or manual-root as declared by the installed manifest.

Protected publication may open a branch and PR, but cannot enqueue or merge it.
The authenticated maintainer performs provider approval or merge. Manual-root
changes require a later local sudo install that displays and binds the complete
authority delta. A protected merge is not an installation.

### 7. Registry improvement is monotonic by construction

Registry data never defines executable handlers, adapters, ticket fields,
results, stages, paths, mandatory guards, or safety policy. Immutable templates
bind authority domain, source stages, applicability, evidence-to-input
derivation, one adapter effect, independent postcondition, legal successors,
result mapping, retry rule, and invocation cap.

Registry skills may contain only identifier and version, an ordered path of
existing template identifiers, additional conjunctive predicates, lower
attempt or time caps, labels, and prompt version. Validation proves the skill
is an existing path in the immutable graph and cannot add an edge, domain,
object or path, repeat an effect, introduce a cycle, skip review or approval,
weaken a predicate, widen a cap, or map blocked or in-doubt state to success.

The installed policy pins the validator, graph, templates, schema, adapters,
identities, and fixed `registry.advance` transition. State stores the accepted
registry commit, tree, digest, and predecessor. `registry.advance` requires a
merged descendant whose complete tree delta contains only registry index and
skill JSON, successful monotonic validation, exact-object tests and two
reviews, complete matching forge observations, and no active or in-doubt
ticket using the current digest. One CAS updates the accepted fields. A fresh
resolver process loads them; the authoring process cannot.

Applicability is state-owned and tri-state:
`applicable`, `not_applicable`, or `indeterminate`. Registry predicates can
only narrow applicable to not-applicable. Missing, incomplete, rate-limited, or
timed-out safety evidence is indeterminate and blocks fallback. If exactly one
mechanical ticket is available it may execute without a model. Otherwise one
fresh read-only resolver may choose only an opaque ticket ID or leave.

### 8. Existing review, credential, autonomy, and completion authority remains

`dec.recovery-model-credential` remains binding, refined operationally so the
upstream broker credential exists only in the model gateway. Model containers
receive one-use reservation tokens with no repository authority.

`dec.review-mandatory` remains binding. Correctness and simplicity receipts are
durable external attestations bound to exact repository, policy and ruleset
digests, base and head commits and trees, patch hash, incident, lens, immutable
model identity, and verdict. They are checked at merge admission and are never
files inside the candidate head they attest.

`dec.loop-autonomy` and `dec.mvp-completion` remain binding. Goal-layer and
completion-profile authority is unchanged. No resolver, state service,
adapter, skill, registry, model, receipt, candidate, PR, merge, activation,
acknowledgement, recovery result, deployment result, or UI state can emit,
infer, proxy, or authorize `LOOP EXHAUSTED`.

Only the accepted driver token backed by
`python3 tools/loop/coverage.py --run-gates` can establish MVP completion.
`ITERATION COMPLETE`, merged PR, todo transition, skill success, deployment,
resume, later progress, recovery resolution, operator stop, and project
completion are distinct result types.

## Rationale

Credentialing deterministic adapters preserves the current delegate/executor
principle while expanding the set of recoverable workflows. Making state the
sole ticket constructor prevents a model, controller, or registry from turning
text into authority. One-effect tickets and independent observations make
crash recovery explicit and prevent duplicate external mutations.

Creating the branch before OMP and stopping every writer before finalisation
close the two races the prompt-only procedure cannot close. A generated
installed-policy projection prevents a candidate from grading itself.
Monotonic registry paths allow new compositions only inside already-reviewed
authority, so self-improvement cannot create a new capability.

The staged marker design avoids overlapping recovery authority. Before
activation the healer remains the sole mutator. The authenticated atomic
transaction is the one-way boundary after which rollback means reconciliation
or manual hold, never restoration of the old decision plane.

## Consequences

- Firth first lands a dormant authority release with closed classifier,
  preparer, launch/finalisation, recovery, landing, policy, and test contracts.
- Operator services may be implemented and tested only after that release
  lands. Their initial installation is manual-root under a global
  `resolver-off` switch.
- Normal finalisation and halted recovery cut over separately. The recovery
  inhibit stays set while normal tickets run.
- Legacy executors, healer units, exchange volumes, parsers, and upstream model
  token mounts are removed only after parity, cutover, reconciliation, and
  rollback tests succeed.
- The status surface reads only an atomic redacted projection and carries no
  authority.
- New executable code, adapter, schema, policy, credential, service, root
  capability, or broader path class always remains protected and requires a
  separate local root installation where applicable.
