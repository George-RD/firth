---
node: firth.toolchain.compiler
status: done
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
- 2 October 2026, step 3 of 4. `src/compiler/Firth/LoweringSimulation.lean`
  proves that the target semantics simulates the reference interpreter on
  lowered code. `compileWords_correct`: for each word `compileWords` compiles,
  a target run that halts matches an interpreter run of the word's body from
  the related stack to a related stack, with the target's kernel cost equal
  to the interpreter's cost; and an interpreter run that ends in `N` steps
  makes the target, given `N` fuel, halt with a related stack and the same
  kernel cost. The stated exceptions are the target's 256-frame call-depth
  bound and `seq-int.len`/`seq-bool.len` of a sequence of 2^63 or more
  elements (the interpreter returns the length, the target faults).
  `execute_of_stuck`: when the interpreter gets stuck after `n` steps, the
  target given more than `n` fuel traps, and not for want of fuel;
  `execute_trapped` gives the converse. The kernel cost spent before a fault
  is not related.
  Hypotheses: the interpreter's dictionary gives each word its checked body,
  and no body holds the runtime-only `push` atom. Typing is not assumed.
  `LoweringPrimitives.lean` proves the 23 surface primitives agree.
  `LoweringSimulationMutants.lean` plants two miscompiled images of `1 +`
  (`1 -` and `2 +`) and proves each fails `ImageRel` because of the theorem;
  changing a lowering rule in `Lowering.lean` (tried locally: `swap` lowered
  to three `SWAP`s) breaks `lowerProgram_rel`'s build. Not covered: the
  target's word-entry charge (only kernel cost is related), the VM itself
  (tested against the semantics in step 2, not proved), and the JSON image
  `Compile.lean` emits. Still to do (step 4): the allocator's record naming
  the VM result, a planted miscompile through the gate, and the trusted list.
- 2 October 2026, between steps 3 and 4. The compiler now refuses a
  source-level `push` atom (`todo.compiler-source-push-atoms`), so the
  `noPushProgram` hypothesis is gone and `compileWords_correct` covers every
  program `compileWords` accepts.
- 2 October 2026, step 4 of 4. `src/compiler/Firth/ContractTarget.lean`
  proves `targetHolds_of_holds`: a word contract proved of an exported body
  under `int64Gamma` holds of the target semantics running any image that
  publishes each exported word, under the name `nameMapOf` gives it, as the
  code `lowerProgram` lowers its body to. From a stack that stands for the
  contract's input, with at least the contract's step bound as fuel, the
  target halts with a stack that stands for its output at a kernel cost within
  its cost bound, with the two exceptions above (depth bound, length overflow).
  `src/proofs/Inventory/Target.lean` applies it to both allocator contracts.
  The proof-record audit accepts a contract's `target_theorem` only when its
  statement is definitionally that `TargetHolds` (fixtures: one accepted, three
  refused), and the record lists the image it is about: each word, its target
  name and its body digest, recomputed by lowering the exported program.
  `examples/inventory/run_cases.py` requires the image the VM runs on every
  case to be exactly that one (`check_image`); `test_inventory_target_image.py`
  plants miscompiled images (one word's code changed, two swapped, a word
  missing or added, another entry) and the call site.
  `specs/tcb-boundary.toml` names the parts between the theorem and a VM run,
  all trusted and tested, not proved: the JSON emitter, the Lean and Rust
  canonical encodings with SHA-256, the Rust decoder, VM image admission, the
  Rust VM (with the Lean decoder `firthTargetRun` uses to test it), and the
  image match itself.

## Resolution

Done on 2 October 2026, by the second branch of the second criterion: the VM
is not proved; its trusted part is named in `specs/tcb-boundary.toml`, and the
claim says it is tested against the proved target semantics. The first
criterion is met with stated exceptions (`compileWords_correct`): the target's
256-frame call-depth bound, the length of a sequence of 2^63 or more elements,
the kernel cost spent before a fault, and the word-entry charges, since only
kernel cost is related. The allocator's records name the target result
(`allocate_batch_target`, `allocate_batch_host_target`) and the image the VM
runs is checked to be the one they are about. The planted miscompiles are in
`LoweringSimulationMutants.lean` (images the theorem rejects) and
`tools/loop/test_inventory_target_image.py` (images the gate refuses); a
changed lowering rule breaks the build of `lowerProgram_rel` and so of every
target theorem.
