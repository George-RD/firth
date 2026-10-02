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

## Progress

- 2 October 2026, step 1 of 4 (plan agreed with the coordinator: lowering,
  target semantics, simulation theorem, allocator record with a planted
  miscompile). `lowerProgram`, `lowerValue`, `lowerAtom`, `nameMapOf` and
  the target bound and well-formedness checks are now total functions that
  proofs can unfold. `src/compiler/Firth/LoweringFacts.lean` proves
  `compileWords_ok`: every emitted entry is, in order, its source word lowered
  by `lowerProgram` under the dictionary's name map, published under the
  mangled name that map gives it, and the mangled names are distinct
  (`nameMapOf_ok`). Nothing about target execution is proved yet.
- 2 October 2026, step 2 of 4. `src/compiler/Firth/TargetSemantics.lean`
  states the target machine of `target-spec.md` §4 and §5 as a Lean step
  function (frames, tail transfers, the 256-frame bound, fuel, total and
  kernel cost, traps), with examples worked out by hand in
  `TargetSemanticsExamples.lean`. `lake exe firthTargetRun` runs it on a
  `firth.vm-run.v1` request, and `mvp_agent_gate.rebuild` now requires the
  Rust VM to agree with it on status, stack, cost and trap for every compiled
  program it runs (146/146 programs and the inventory cases agree). That is
  tested agreement, not a proof about the VM. The semantics leaves out image
  admission, `PUSH_QUOTE` of a quotation owning a linear capture and the
  `World` primitives, and reports `unsupported` for them; the compiler emits
  none of them. The VM's response has no primitive count, so that field is
  not compared. Still to do: the simulation theorem (step 3) and the
  allocator record, planted miscompile and named trusted list (step 4), which
  must also name the JSON emitter, the Rust decoder and `canonicalCode`.
