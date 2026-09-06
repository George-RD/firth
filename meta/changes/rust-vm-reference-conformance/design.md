# Design: rust-vm-reference-conformance

## Approach

The comparison is split into a target half and a reference half, so neither
side can quietly borrow the other's answer.

`ConformanceObservation` is what a host observed: status, canonical
bottom-to-top stack rendering, canonical residual frame rendering, the hidden
`WorldState` observation bytes, the classified trap, and the cost report.
Every field is fixed by `target-spec.md` §4, §5 or §7. Quotations render by
usage rather than by body and frames render as `word@pc`, so no pointer,
timing, or allocator detail can reach the record.

`ConformanceReference` is what the reference contract requires. It is
deliberately partial: `world_observation`, `trap` and the cost `breakdown` are
`Option`, because the frozen corpus row format carries no world column, does
not name a trap class, and fixes only the two cost totals. An unstated field
is skipped by the comparison rather than being invented, and a hand-written
witness states it where it matters.

`ConformanceStatus` has three cases, not two. Fuel exhaustion is neither
termination nor a trap (`target-spec.md` §4), so `compare_conformance` returns
`BoundedFuelInconclusive` when both sides exhausted an equivalent budget, and
falls through to an ordinary status disagreement when only one side did.

Cost is compared as `total` plus `kernel`, where `kernel` is `total` less the
administrative word-entry charges, which is the quantity the Lean `kappa`
accounts for. That is exactly the pair the frozen corpus states in its
`lean_cost` and `target_cost` columns.

## Changes

ADDED:
- `src/runtime/vm/src/conformance.rs`: the observation, reference, verdict and
  comparison, plus `observe_image`, `observe_image_bytes` (which classifies a
  decode failure as a zero-cost malformed-input trap) and `fixture_reference`.
- `src/runtime/vm/src/tests_reference_conformance.rs`: deterministic witnesses
  for world threading, malformed bytes, classified traps, primitive faults,
  fuel exhaustion, dual and one-sided exhaustion, cost breakdown, determinism,
  and unstated reference fields.

MODIFIED:
- `src/runtime/vm/src/lib.rs`: include the new module; import `ToString`.
- `src/runtime/vm/src/tests_fixtures.rs`: the frozen corpus now runs through
  `fixture_reference` and `compare_conformance` instead of an inline
  comparison with private renderers, and asserts the corpus row count.
- `src/runtime/vm/src/tests.rs`: include the new witness file; drop the two
  imports the removed renderers used.

REMOVED:
- The private `render_fixture_stack` and `render_fixture_frames` test helpers,
  superseded by the module's canonical renderers.
