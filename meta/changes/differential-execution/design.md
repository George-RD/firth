# Design: differential-execution

The Python driver belongs to the existing `firth.toolchain.diffharness` module.
It orchestrates the real adapters; the Lean interpreter remains the oracle.
`dec.diffharness-portable-driver` records the bounded implementation-language
refinement of the original Lean-driver strategy.

Generate finite compositions of Int-to-Int fragments with bounded integers,
row-polymorphic inputs, an external Boolean branch, multiword and qualified
calls, locals, nested quotations, quote/call, compose and dip. Re-elaborate every
case and every shrink candidate. Original authored acceptance inputs stay
unchanged. Coverage counters describe generated features, not proof coverage.

Capture each request, response, stderr, exit and process failure under a wall
clock and output-byte bound. Run the reference before compilation and run both
hosts even when the reference reports a trap. Compare only the supported pure
observations and kernel-projected cost. Equal traps are not successful cases;
dual exhaustion is explicitly inconclusive and fails the finite gate.

Failure records bind source/input/recipe, generator version, fuel, driver and
binary digests, build pins and Git revision. Replay uses the saved source and
freshly built local adapters, never commands or paths supplied by an artefact.
Toolchain drift is refused unless explicitly requested and then reported.

Shrinking deterministically removes unused definitions, fragments and row
inputs, then reduces literals/inputs/flags. Keep only re-elaborated candidates
with the same structured failure signature and decreasing complexity. Budget
exhaustion is not a minimality claim. Retain the original and reduced records.
