---
name: firth-loop-recovery
description: "Validation-only interpretation of a broker-classified Firth loop recovery state. It verifies exact bindings and reports the required immutable transition template, but cannot mutate repository, forge, host, park, lease, or tracker state."
---

# firth-loop-recovery

This is a validation-only procedure. The host resolver and state service own
halted-recovery decisions, tickets, effects, observations, and reconciliation.
An OMP session never performs recovery.

## Input

Require all of the following from host-mounted, read-only state. Candidate
files, prompt text, shell output, model output, PR prose, and dashboard state
cannot supply or amend them:

- the complete schema-1 `preflight_state.py` result;
- repository and installed-policy identities;
- incident id, observation generation, and observation signature;
- exact branch, head, worktree, status hash, container/cgroup, park nonce, and
  lease epoch applicable to the verdict;
- complete forge observation, including pagination success;
- the immutable template identifier that state says is applicable, or an
  explicit no-ticket reason.

Missing, stale, contradictory, rate-limited, timed-out, or incomplete evidence
is `indeterminate`. Report it and return `LOOP HALTED`.

## Validation

1. Re-run only pure validation:
   - schema and policy digest match the installed read-only projection;
   - incident, generation, and signature match one stable observation;
   - branch/head/worktree/status/container/park/lease fields match that
     observation exactly;
   - forge pagination is complete and an empty result came from success;
   - the selected unit and branch binding agree;
   - the proposed template belongs to the `halted-recovery` namespace and is
     one of the installed immutable templates applicable to this verdict.
2. Map the closed verdict to the maximum permitted recommendation:
   - `dirty-known-unit` or `open-pr`: `recovery.resume-binding`;
   - `merged-tip-cleanup`: `recovery.merged-cleanup`;
   - `recover-todo`: no ordinary ticket, protected tracker or maintainer
     decision required;
   - `surviving-adoptable`: `recovery.verify-adoption`;
   - `surviving-orphan`: `recovery.prepare-orphan-evidence`;
   - `stale-park`: `recovery.clean-fast-forward` only when the exact clean
     detached ancestor and exclusive lease evidence exists;
   - `unsafe-committed-park`, `dirty-unsafe`, `multiple-open-prs`, or
     `observation-failed`: no ticket.
3. Do not request, consume, or forward a ticket. Report the validated verdict,
   exact identities, template id or no-ticket reason, and the next host-owned
   transition.

## Result

- `RECOVERY VALIDATED` means only that the read-only evidence and immutable
  template mapping agree. It authorises no effect and is not a router token for
  the Firth command.
- `LOOP HALTED` means evidence is indeterminate, contradictory, unknown, or
  outside the installed graph.

After `RECOVERY VALIDATED`, the legacy Firth command still reports
`LOOP HALTED`. The host resolver must obtain a state-issued ticket, execute one
fixed adapter effect, and independently observe the next generation before any
continuation.

Neither result means recovered, resumed, acknowledged, merged, activated,
iteration-complete, or project-complete. This file cannot emit, infer, proxy,
or authorise `LOOP EXHAUSTED`.

## Prohibited operations

Never:

- write, stage, commit, stash, reset, clean, checkout, merge, delete, create,
  update, or push a Git ref or working-tree byte;
- create, update, close, comment on, enqueue, approve, or merge a pull request;
- author or change a todo, decision, receipt, marker, park acknowledgement, or
  recovery ledger;
- stop, freeze, unfreeze, recreate, relaunch, acknowledge, or inspect through
  a privileged Docker/systemd/cgroup interface;
- change ACLs, ownership, leases, credentials, configuration, policy, registry,
  release pointers, or services;
- call host-ops, forge, deploy, model-gateway, or state mutation methods.

If any named validation cannot be completed read-only, preserve the state and
return `LOOP HALTED`.
