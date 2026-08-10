---
id: dec.escalation-surfacing
nodes: [firth.governance.loop]
status: accepted
related: [dec.halt-recovery, dec.rc3-recovery, dec.loop-autonomy]
date: 2026-08-09
---

# Parks Surface as Issues and Resume Only on a Host-side Nonce Ack

## Context

Every stay-down path ended with the supervisor exiting a container
whose restart policy is `no`. dec.halt-recovery prices an unnecessary
escalation at "one human look", but nothing requested the look: an
escalated park on 2026-08-09 sat silent for 24 hours until the
maintainer happened to ask. An escalation nobody receives is not an
escalation, and an exited container cannot receive the answer.

## Decision

1. A stay-down parks instead of exiting. The supervisor kills the
   driver's process group, writes `parked` into its state file, and
   opens one metadata-only GitHub issue per incident signature
   (deduplicated; a repeat park comments a fresh nonce). No model or
   tool output leaves the host: the issue carries rc, signature,
   timestamp, and the resume instruction.
2. The only resume channel is the host-side control file, mounted
   read-only into the container, whose first line must equal the
   one-time nonce the park minted. No in-container process can write
   the file; nothing staged before the park can contain its nonce; the
   issue is pure notification because the loop and the operator share
   one GitHub identity, so closure proves nothing about who decided.
3. A valid ack resumes through the standard refresh-and-re-extract
   path. For an rc 3 park the machine-checked quota gate is re-run
   first: ok launches, a positive exhaustion verdict re-enters the
   bounded quota wait with a fresh window (the ack is the human look
   that re-opens the budget), unreadable state parks again. The ack
   never adjudicates the incident - the ledger and halt report already
   did - it is exactly the operator restart, made receivable.
4. An operator stop while parked terminates as before. Notification
   failure never converts a park into an exit.

## Consequences

- `supervisor.sh` gains the park loop, nonce handshake, and issue
  surfacing; docker-compose mounts the host control directory
  read-only; the container no longer exits on stay-down.
- Flow tests cover: park on every stay-down class, ack resume through
  refresh, pre-staged ack refused, issue dedupe, quota gate honoured
  across acks, cap re-opened by ack, and refreshed-driver consumption.
