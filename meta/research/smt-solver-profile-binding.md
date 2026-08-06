---
id: res.smt-solver-profile-binding
nodes: [firth.toolchain.smt]
sources: [src.z3-5.0.0-release, src.z3-licence]
date: 2026-08-06
---

Z3 `5.0.0` is the selected initial solver. Its official release metadata
provides a reproducible Linux arm64 glibc 2.38 archive and a published archive
digest. The extracted `bin/z3` executable digest was independently computed
from that archive as
`sha256:6457d93236741071c91bfa2927744372e15fdb236d0116bf487aa9930a38972e`.

The official release licence is MIT, satisfying the permissive licensing
constraint. The initial profile is intentionally narrow: QF_LIA only, with
stdin SMT-LIB2 input, a five-second wall-time bound, and a 256 MiB memory
bound. The profile records the exact invocation options and limits as typed
values. Solver invocation, translation, and adapter implementation remain out
of scope for this unit.
