---
node: firth.governance.loop
---

# Firth governance loop contract

The governance loop owns the normative one-unit procedure and its deterministic
preflight, selection, preparation, landing, recovery, completion, and boundary
checks. The command and referenced skills are the procedure authority; runbook
documentation is descriptive.

## Execution modes

- Without a valid authenticated prepared envelope, the loop preserves the
  legacy preflight, recovery, branch, Land, Cleanup, and terminal-token path.
- With a valid prepared envelope, the loop validates the host-issued identity
  and runtime evidence, invokes the no-argument `firth_finalize` handoff, and
  stops before legacy Land/Cleanup and terminal-token handling.
- Invalid, stale, or inconsistent prepared evidence fails closed. It never
  authorises a branch, ref, worktree, publication, recovery effect, merge, or
  completion result.

## Authority boundaries

The selector and preflight classifier are read-only and deterministic. Recovery
is validation-only: it may report a closed verdict and sanctioned next step but
cannot mutate Git, worktrees, containers, leases, credentials, or forge state.
Landing admits only the installed policy projection, exact prepared identity,
external review attestations, finaliser receipt, and the sanctioned selected-
todo status transition. Completion remains exclusively the coverage gate's
machine-checked result; no loop helper, skill, receipt, merge, or UI state may
emit or infer `LOOP EXHAUSTED`.

Changes to this contract, the command/skill procedures, or the deterministic
checker interfaces require the normal Cairn decision and interface-baseline
workflow before they are accepted.
