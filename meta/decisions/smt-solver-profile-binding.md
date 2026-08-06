---
id: dec.smt-solver-profile-binding
nodes:
  - firth.toolchain.smt
  - firth.toolchain.elaborator
status: accepted
date: 2026-08-06
informed_by:
  - res.smt-solver-profile-binding
  - src.z3-5.0.0-release
  - src.z3-licence
---

Autonomous author: loop/todo.smt-solver-profile-binding.

Select Z3 `5.0.0` as the first Firth SMT solver profile. The selected release
is MIT licensed and is acquired from the official Linux arm64 glibc 2.38 asset.
The typed profile records solver id, version, licence, platform, executable
digest, acquisition URL, QF_LIA theory support, immutable invocation options,
and explicit five-second and 256 MiB resource bounds.

The SMT queue entry is the typed request binding and carries the exact pinned
profile. Adapter results use a typed result wrapper carrying the same profile;
profile mismatches are deferred rather than accepted. This unit records the
profile only. It does not invoke Z3, translate formulas, or implement the
adapter. Other platforms and solver upgrades require a new profile decision.
