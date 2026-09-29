---
node: firth.toolchain.elaborator
status: open
created: 2026-09-29
---

# Firth has no non-strict integer comparison

Found by the run 11 failure analysis (`eval/s7/README.md`, "Run 11 failure
analysis"; scripts and outputs in
`eval/s7/runs/2026-09-29-locals-guide/causes/`). Gamma offers only `prim <`
and `prim =` for comparing integers, so `a <= b` must be written
`swap prim < prim not` (or `b a prim < prim not`) and `a > b` as
`swap prim <`.

Measured in run 11's counted final answers (`rank.txt`):

- 29 answers check and run but give wrong results with the equality-boundary
  outcome: a strict `<` where `<=` was meant (15 in arm A, 14 in arm B).
  No diagnostic can catch these.
- 9 answers invented `<=` or `>` (2 in A, 7 in B), which the parser refuses.

Inferred, not measured: that the cause is composing `<=` from `<`, `not` and
argument order.

To close: decide between a Gamma primitive (`prim <=`, perhaps `prim >`) and
a clearer idiom in the agent guide. The guide is an S7 eval input, and a
new primitive changes what authors can write, so either needs its own
pre-registered run to show it reduces these errors.
