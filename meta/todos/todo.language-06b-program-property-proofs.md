---
node: firth.toolchain.interpreter
status: open
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

- The property is stated once, as a Lean statement bound to the body digests
  of the words it covers.
- It is proved for every input the host can hand the program (for the
  allocator: stock and quantities in the spec's ranges, at most 64 requests,
  well-formed ID encodings). A finite set of inputs, `decide` or
  `native_decide` on concrete stacks, a Python model, runtime assertions or a
  proof about a hand re-implementation of the algorithm do not count.
- The proof is about the kernel program the elaborator emits for those words,
  run by the Lean reference interpreter.
- The Lean kernel checks it. The result is a content-addressed record that CI
  rechecks and that becomes invalid when a covered word changes (the per-word
  obligation shape of `req-r9`).
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
- User-written Lean proofs are admitted as evidence records bound to the
  digests they cover and rechecked by the Lean kernel; the pipeline reports
  `contract_verified` for them instead of treating the Lean queue as an
  internal failure.
- The allocator's required properties are proved this way: non-negative
  remaining stock and allocations, no request over its quantity,
  conservation, IDs and order preserved, earlier eligible requests first, and
  each allocation following the chosen policy, together with termination and
  the i64 range of every intermediate value.
- A deliberately wrong property, and a proof whose covered word has changed,
  are both rejected.

## Non-goals

Extending the SMT profile with sequences, sums or quantifiers is not part of
this task and is not planned (proposed 27 September 2026, pending George's
decision); it can be revisited. Proving the VM equal to the reference interpreter is not part of
it either.

## Traceability

PRD G4, R9, R15, S5. Split from `language-06-source-refinement-execution` on
27 September 2026 (proposal: Inventory allocator thread).
