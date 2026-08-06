# Proposal: loop-driver-hardening

## Motivation

Retroactive provenance for the adversarial hardening chain that landed as
PRs #39 through #46 after dec.loop-autonomy: the launch driver became the
loop's supervisor (uncapped progress window, typed exit statuses,
driver-owned watchdog, guarded observations) and the omp launch guidance
gained the memory-off overlay. The individual PRs were each smoke-tested
and gated, but no single `meta/changes/` record covered the series.

## Scope

- Record the accumulated driver contract as `dec.loop-driver-contract`
  (accepted, node `firth.governance.loop`).
- Acknowledge the merged PRs this record covers: #39 (progress window
  replaces the fuse), #40 and #41 (`W` validation), #42 (save-and-sh
  launch, AGENT inline), #43 (landing gate `testDriver` detection and VM
  crate gates), #44 and #45 (single guarded preflight fence), #46
  (driver-owned watchdog, failure classification, memory-off overlay).

## Out of scope

- No behaviour changes in this record; the referenced PRs already landed
  with their own smokes and gates.
- No tools/loop code changes.
