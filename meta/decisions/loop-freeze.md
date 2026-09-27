---
id: dec.loop-freeze
nodes: [firth.governance, firth.governance.loop]
status: accepted
related: [dec.loop-autonomy, dec.mvp-completion, dec.mvp-gate-provenance]
date: 2026-09-27
---
# Freeze the autonomous loop and reopen downgraded goals

## Context

The maintainer asked for the repository to be put back on track to deliver a
working language. On `main` at c6b1a19 about 21,000 lines had gone into loop
and gate tooling against about 2,000 lines of compiler. The only executable
primitive is `prim +`. Two goals were recorded as met on readings weaker than
the PRD: S5 by `examples/s5/protocol-handler.firth`, which adds 1, 2 and 1,
and the "MVP reading of S5/S7" in `dec.mvp-gate-provenance` by four
three-line programs with unverified transcripts and no measured pass rate.

## Decision

1. The loop is frozen. Its selector, coverage matrix, landing and recovery
   tooling, command and skills move to `archive/loop/` and leave CI. The
   Cairn governance job runs on manual dispatch only.
2. This supersedes `dec.loop-autonomy` and `dec.mvp-completion`: the
   obligations matrix and `loop_exhausted_valid` no longer define completion.
   The maintainer and `docs/roadmap.md` ("Goal status") do.
3. This supersedes the S5/S7 reading in `dec.mvp-gate-provenance`. S5 and
   `mvp-agent-authoring` are reopened against the PRD's own wording, with the
   acceptance stated in `docs/roadmap.md`. The MVP gate stays as a regression
   check of the example corpus, not as evidence of S5 or S7.
4. No new governance, evidence or attestation tooling is added unless the
   maintainer asks for it.
