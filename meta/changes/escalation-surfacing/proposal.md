# Proposal: escalation-surfacing

## Motivation

An escalated park exited a `restart: no` container and sat silent for
24 hours. The recovery model prices escalation at one human look but
provided no channel to request the look and no process alive to
receive the answer.

## Scope

- Supervisor park loop: stay alive on stay-down, durable `parked`
  state, deduplicated metadata-only GitHub issue per incident
  signature, resume only on the host-side read-only control file
  carrying the park's one-time nonce, through the standard refresh
  path with the quota gate re-run for rc 3.
- dec.escalation-surfacing; mandate guidance distinguishing inert
  landed violations from live risk; runbook park semantics.

## Out of scope

- Any automatic resume without acknowledgement.
- The delegate's verdict allowlist and intervention bounds.
