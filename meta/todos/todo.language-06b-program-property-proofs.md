---
node: firth.toolchain.interpreter
status: done
created: 2026-09-27
---

Requires: language-02-compiler-evidence

## Goal

Prove properties of a real Firth program, for every valid input, over the
kernel program the elaborator produces, and admit those proofs as toolchain
evidence. The first consumer is the inventory allocator's required properties
(`specs/inventory-allocation.md`, "Required properties"), which S5 needs.

## Why this is separate from language-06

`language-06-source-refinement-execution` translates arithmetic source
contracts into obligations for the pinned QF_LIA solver. The allocator's
properties are outside that fragment: they need invariants for recursive
words, sums over sequences (conservation) and quantification over sequence
indices (order, no over-allocation, priority, policy). This task takes the
route PRD G4 names for what SMT cannot do: Lean proofs.

## What counts as toolchain-checked

- The property is stated once, as a Lean statement bound to the words it
  covers. A body digest hashes only that word's own code, so the binding is
  the body digest and erased type of every covered word and of every word it
  calls, directly or transitively, with that call set determined
  mechanically from the compiled program's `call-word` edges.
- It is proved for every input the host can hand the program (for the
  allocator: stock and quantities in the spec's ranges, at most 64 requests,
  well-formed ID encodings). A finite set of inputs, `decide` or
  `native_decide` on concrete stacks, a Python model, runtime assertions or a
  proof about a hand re-implementation of the algorithm do not count.
- The proof is about the kernel program the elaborator emits for those words,
  run by the Lean reference interpreter.
- The Lean kernel checks it. The result is a content-addressed record that CI
  rechecks and that becomes invalid when any bound word's body or type
  changes, including a callee of a covered word (the per-word obligation
  shape of `req-r9`).
- The toolchain reports the property as `contract_verified`, distinct from
  `type_checked` and `unsupported`.

The VM's integers are i64 and trap on overflow; Lean's are unbounded. So
the proofs must also show, not assume, that every intermediate value stays in
i64 for every input within the host's bounds, and the result states that
bound.

Two gaps remain and must be stated wherever the result is claimed:

- The proofs are about the reference interpreter. That the compiler's
  lowering and the VM compute the same result rests on differential testing
  (S2), not on a proof.
- The host is Python and is tested, not proved: JSON decoding and encoding,
  and the four-Int ID encoding the spec requires to give distinct IDs
  distinct encodings. The properties about IDs (order preserved, repeated IDs
  rejected) rely on it.

## Acceptance criteria

- The toolchain exports a word's elaborated kernel program as a Lean
  definition bound to its body digest, and CI fails when the two differ.
- A kernel program-logic library over the reference interpreter covers
  atoms, composition, `if`, `dip`, quotation calls, word unfolding, recursion
  by a measure, and the sequence primitives. No `sorry`, `admit` or `axiom`.
- User-written Lean proofs are admitted as evidence records carrying that
  binding (covered words and their transitive callees, digests and types)
  and rechecked by the Lean kernel; the pipeline reports
  `contract_verified` for them instead of treating the Lean queue as an
  internal failure.
- The allocator's required properties are proved this way: non-negative
  remaining stock and allocations, no request over its quantity,
  conservation, IDs and order preserved, earlier eligible requests first, and
  each allocation following the chosen policy, together with termination and
  the i64 range of every intermediate value.
- A deliberately wrong property is rejected, and so is a proof after a
  covered word changes, after a covered word's type changes, and after only a
  callee of a covered word changes (for the allocator: editing
  `allocate-one` invalidates the proofs about `allocate-batch`).

## Non-goals

Extending the SMT profile with sequences, sums or quantifiers is not part of
this task and is not planned (decided 28 September 2026 by the coordinator, on
George's delegation); it can be revisited. Proving the VM equal to the reference interpreter is not part of
it either.

## Progress

28 September 2026: `src/proofs/Inventory/Allocate.lean` proves that
`allocate-batch`'s exported kernel program, run by the reference interpreter,
returns `Spec.allocateAll`'s result on every valid input (codes 1 and 2 for
out-of-bounds input and repeated IDs), so the properties proved in
`src/proofs/Inventory/Spec.lean` hold of the program, with every intermediate
value in i64 (`int64Gamma`).

`allocate_batch_contract` is recorded in `src/proofs/records.json`, bound to
the body digests and erased types of `allocate-batch` and the nine words it
calls, and all ten are reported `contract_verified`. A planted change to
`allocate-one` (reason 3 to 4) breaks the proof, and
`update_proof_records.py --check` refuses; the record mechanism's own
staleness checks are in its fixtures (#138).

## Completion, 28 September 2026

Each acceptance criterion and its evidence on `main`:

- Export bound to the body digest: `lake exe firthExportLean` writes
  `src/exports/`, and `update_kernel_exports.py --check` in CI fails on drift
  (#133).
- Program logic: `src/interpreter/Firth/ProgramLogic.lean` has `Runs` and
  `RunsWithin` with rules for atoms, composition, `if` (`runs_if`), `dip`
  (`runs_dip`), quotation calls (`runs_call`), word unfolding (`runs_word`),
  recursion by a measure (`induction_on_measure`) and the sequence
  primitives (`runs_intSeq_*`), with no `sorry`, `admit` or `axiom`
  (`check_zero_admit.py`; the record audit refuses non-standard axioms)
  (#135, #136).
- Evidence records: `firthProofRecords` admits a `WordContract` theorem as a
  record bound to the covered words, their transitive callees, digests and
  types, rechecked by `--status`, and reports `contract_verified` (#138).
- The allocator's properties: `src/proofs/Inventory/Spec.lean` proves them of
  `allocateAll` (lengths and order, no request over its quantity,
  non-negative stock, conservation, the policy rule, the reason table,
  priority), and `allocate_batch` in `src/proofs/Inventory/Allocate.lean`
  proves the program returns that result, with termination and every value
  in i64 (#137). Repeated IDs are rejected (code 2). It is recorded as
  `allocate_batch_contract` (#141).
- Rejections: the refused fixtures in `src/prooftests/` include false and
  vacuous contracts (#138). `update_proof_records.py` plants a stale body
  digest on each covered word of every record, callees included, and a stale
  erased type, and each must withdraw the record (#141). Editing
  `allocate-one` breaks the proof of `allocate-batch`.

The two stated gaps are open as their own todos:
`todo.compiler-vm-agreement-proof` and `todo.inventory-host-proof`.

## Traceability

PRD G4, R9, R15, S5. Split from `language-06-source-refinement-execution` on
27 September 2026 (proposal: Inventory allocator thread).
