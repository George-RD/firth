# Design: loop-driver-hardening

## Approach

Consolidated provenance for the post-dec.loop-autonomy driver hardening,
plus one behaviour change landed with this record: the injected command
text is read from `origin/main` (`git fetch` then `git show FETCH_HEAD:`)
at every iteration, never from the launch checkout's working tree, so
normative amendments landed mid-run take effect on the next iteration in
local and containerised runs alike. The driver script itself still only
updates on relaunch, which is acceptable because driver changes are rare
and operator-visible; the command file is the per-iteration normative
input. Everything else in this record documents already-landed, smoked
behaviour as the contract in `dec.loop-driver-contract`.

## Changes

ADDED:
- `meta/decisions/loop-driver-contract.md` (accepted,
  `firth.governance.loop`): typed exit statuses, clean-exit token
  acceptance, driver-owned coreutils watchdog with 124/137 classification,
  progress window, observation retry, harness-flag requirements, and
  per-iteration prompt freshness.
- `meta/changes/loop-driver-hardening/` (this record).

MODIFIED:
- `docs/loop-runbook.md` driver block: prompt sourced from `origin/main`
  per iteration with guarded fetch and show; failures stop rc 3.

REMOVED:
- None.

RENAMED:
- None.
