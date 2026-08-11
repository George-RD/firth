---
id: dec.healer-delegate
nodes: [firth.governance.loop]
status: accepted
related: [dec.halt-recovery, dec.escalation-surfacing, dec.review-mandatory, dec.split-todo-form]
date: 2026-08-10
---

# Healer Delegate: Bounded Self-Heal Above the Park

## Context

dec.escalation-surfacing made stay-downs park and wait for a host-side
ack, surfacing one metadata-only issue per incident. In practice every
park through 2026-08-10 was resolved the same way: a human asked their
agent to diagnose the halt, repair the repository through governed
changes, and acknowledge the park. The halts themselves fell into
recurring, machine-recognisable classes (stale tracker state, contract
defects later fixed by decision, transient infrastructure). Requiring a
human round-trip for each recurrence is the availability bottleneck the
CTO has asked to remove; the in-stack recovery delegate
(dec.halt-recovery) deliberately cannot fill it because it is
credential-less, and nothing in-stack survives a dead container.

## Decision

1. **A healer layer above the loop is sanctioned.** It is host-side and
   independent of the loop's own stack, watching the durable park state
   and container lifecycle.

2. **Judgement and execution are split.** A model session (the healer
   delegate) runs in an isolated container with its own transcript, the
   published mandate, the incident evidence, and model access only: NO
   git, GitHub, or ack credential of any kind. It diagnoses (the
   repository is public and readable over https) and, when the root
   cause is a repairable repository defect, proposes the precise repair
   in its rationale for a credentialed agent to land through the loop's
   reviewed landing path (dec.review-mandatory; the goal layer and the
   anti-shortcut charter of dec.loop-autonomy bind any such landing in
   full). Its verdict is advice, not action.

3. **Only a deterministic wrapper acts, from an allowlist.**
   - `resume`: write the park's nonce to the host ack file, only if the
     observed nonce is still the live park (compare-and-act) AND
     selection on a fresh clone of current `origin/main` validates and
     yields an eligible or in-progress unit. The supervisor's own gates
     still apply after the ack (a quota park re-enters the bounded
     quota wait).
   - `relaunch`: `compose up -d` for a container that exited with a
     genuine failure code, or `compose up -d --force-recreate
     firth-loop` when durable state says `parked` but the park marker is
     missing. The forced recreation invokes the supervisor's
     fail-closed startup reconstruction path and mints a new nonce
     before driver work. Operator stops (143/137), clean exits (0),
     `stopped_by_operator` state, and the durable `healer-off` sentinel
     are never overridden.
   - `leave`: the default and the fail-closed interpretation of any
     malformed answer.

4. **Bounds.** One healer attempt per incident key (park nonce,
   missing-marker state fingerprint, or container death id), a global
   daily attempt cap, and every attempt ledgered host-side before the
   session starts (a crash mid-session burns the key). The session
   cannot reach the ack channel, the Docker socket, the wrapper's
   ledger, or any write credential.

5. **Amendment of dec.escalation-surfacing.** The ack channel remains
   host-side and operator-owned; the healer wrapper is an operator
   instrument running under this decision, so its gated ack is an
   operator ack. A human can silence it at any time
   (`touch control/healer-off`) and every park still surfaces its
   GitHub issue either way.

## Consequences

- Recurring machine-classifiable halts (the observed majority) resolve
  without a human in the loop, with the same review and gate discipline
  as any loop iteration.
- Genuinely novel or authority-class incidents still park, still
  surface, and still wait: the healer's fail-closed default keeps the
  escalation contract intact.
- The healer's implementation, mandate, and hermetic behaviour tests
  live in the operator's infrastructure repository; this decision
  defines the authority boundary the loop can rely on.
