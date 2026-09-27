# Frozen: the autonomous development loop

Frozen on 27 September 2026 at the maintainer's request. Nothing here runs in
CI or in the default development path. It is kept, not deleted, so the history
stays readable and the loop can be revived deliberately if that is ever wanted.

## Why

An assessment of `main` at c6b1a19 found that effort had drifted from the
language into the machinery that steered the agents: about 21,000 lines of loop
and gate tooling against about 2,000 lines of compiler. Acceptance goals had
also been redefined downward so the loop could report completion. PRD S5 was
"discharged" by a program that adds 1, 2 and 1. The loop's selector, coverage
matrix and completion profile were deciding what counted as done. That job now
belongs to the maintainer and to `docs/roadmap.md`.

## What is here

| Path | What it was |
| --- | --- |
| `tools/select_unit.py`, `coverage.py`, `obligations.toml` | Todo selector, PRD obligations matrix and the `loop_exhausted_valid` completion check |
| `tools/prepare_iteration.py`, `preflight_state.py`, `landing_gate.py`, `authority-policy.projection.json` | Per-iteration coordination, state classification and landing admission |
| `tools/check_s5_envelope.py` | The gate that accepted the trivial S5 program |
| `tools/update_smt_proof_bindings.py`, `check_smt_attestation.py`, `check_tcb_boundary.py`, `audit_branch_axioms.sh` | Hash pinning and provenance lints. The SMT binding hash covers every Lean file under `src/`, so any compiler edit failed CI until the hashes were regenerated |
| `tools/test_*.py` | Tests for the above |
| `claude/` | The `/firth-loop` command and its landing and recovery skills |
| `docs/` | The loop runbook and recovery mandate |

The loop host itself (supervisor, park and ack files, intervention ledger) was
never in this repository. Stopping it is a host action:
`docker compose stop firth-loop`.

## What stayed live

`tools/loop/` still holds the runner (`firth_run.py`), the MVP gate and its
manifest, the proof-module manifest updater (the elaborator reads that file at
run time), and the product checks CI runs: zero-admit, kernel fixtures,
compiler admission, trust boundaries, runtime ingress and bounds, and the
language examples. The directory keeps its name because `src/` refers to paths
in it.

## Reviving it

Don't, without a maintainer decision. If one is made, move the files back with
`git mv`, restore the CI steps removed in the freezing commit, and regenerate
the SMT bindings and coverage matrix against the current tree. Expect drift:
nothing here is kept in step with `src/` any more.
