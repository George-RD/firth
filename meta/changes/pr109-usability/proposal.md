# PR #109: executable language workflow and trustworthy verification

## Problem

The compiler infers an entry from source order, the MVP gate supplies an empty reference dictionary, and cost comparison includes VM-only administration. The gate checks a manifest's transcript claim without reading the transcript. There is no copy-and-run user workflow or repository CI evidence for this branch.

## Proposed change

Require explicit entry selection for multiword compilation, preserve checked dictionary entries, compare kernel costs, verify transcript contents, add source-level regression cases and a documented runner. Add GitHub Actions for the existing Lean, Rust and Python gates. Review the bounded solver process separately without weakening proof admission.

## Scope

Existing compiler, agent interface, SMT and governance modules. No changes to the language's kernel semantics, no removal of proof checks, no claim of production readiness, and no changes to post-MVP requirements.

## Verification

Exercise original failures as negative regression tests. Run the locally available Python tests and use the published CI jobs for Lean/Rust execution. Record unavailable or failing gates explicitly; a completed tracker is not a substitute for these results.
