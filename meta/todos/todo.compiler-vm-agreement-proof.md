---
node: firth.toolchain.compiler
status: open
created: 2026-09-28
---

Requires: language-06b-program-property-proofs language-06c-proved-cost-bound

## Goal

Close the first gap stated with S5 (met 28 September 2026). The allocator's
properties and cost bound are proved over the kernel program run by the Lean
reference interpreter (#137, recorded in #141). Two further links are only
tested: the compiler's lowering of that kernel program to the Forth-class
target, and the Rust VM's execution of it, including the VM's own cost
accounting. Today the differential harness (`src/diffharness`) and the
VM-versus-reference checks in `examples/inventory/run_cases.py` compare them on
chosen inputs. Neither shows agreement on every input, and neither can catch a
bug the two sides share.

## Acceptance criteria

- A Lean theorem states that for every well-typed kernel program the compiler
  accepts, the lowered target program run under the target semantics
  (`src/runtime/vm/target-spec.md`) gives the reference interpreter's result,
  faults and cost, or the exceptions are stated precisely.
- The VM's side is either proved against the target semantics or its trusted
  part is named and kept small; the claim says which.
- The allocator's proof record can then name the VM result, not only the
  reference result. Until then every S5 claim keeps stating this gap.
- A planted miscompile (for example a swapped operand order in one lowering
  rule) breaks the theorem's build.
