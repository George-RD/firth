---
id: dec.s5-proof-standard
nodes: [firth.toolchain.interpreter, firth.toolchain.smt]
status: accepted
related: [dec.loop-freeze, dec.s5-cost-envelope-witness, dec.agent-development-rules]
date: 2026-09-28
---
# S5 is proved in Lean over the reference interpreter; no SMT for sequences

## Context

S5 needs the inventory allocator's properties (conservation, no
over-allocation, the fulfilment policy) "checked by the toolchain, not only by
tests", and a cost bound stated as a function of input size. Those properties
need invariants for recursive words, sums over sequences and quantification
over sequence indices. They are outside the QF_LIA fragment the SMT path
(`language-06`) discharges. #127 splits the work into `language-06`
(arithmetic contracts, SMT), `language-06b` (Lean proofs of program
properties) and `language-06c` (proved cost bounds), and proposes the S5
wording in `docs/roadmap.md`.

The maintainer delegated this choice on 28 September 2026, asking for the
approach that is harder now if the easier one would cause pain later.

## Decision

1. The proof standard for S5 is Lean proofs, for every valid input, over the
   kernel program the elaborator emits, run by the Lean reference
   interpreter, with the cost bound proved the same way. The proofs also show
   every value stays within the VM's i64. The detailed acceptance is in
   `language-06b` and `language-06c`, which #127 adds to `meta/todos/`. None
   of these proofs exist yet; this decision chooses the route, it is not
   evidence that S5 is met.
2. The VM and the compiler's lowering are tied to the reference interpreter by
   differential tests, not by a proof. This gap is stated with every S5
   claim and tracked as open work. It is not closed by more testing, and it
   does not block S5.
3. Extending the SMT path to sequences is a non-goal for now. The Lean route
   can state and prove sequence properties, and a second route would mean a
   second trusted translator to keep honest.

## Consequences

- Proving the compiler and VM equal to the reference interpreter later adds
  one theorem at the interpreter boundary. It does not require redoing any
  program proof, because those are stated against the interpreter.
- The easier route rejected here, SMT over sequences or tests standing in for
  proofs, would have needed a quantifier-heavy solver fragment or left S5 as
  "checked by tests", which is the reading that was reopened.
- #127 changes the S5 row of `docs/roadmap.md` to this standard. Until it
  merges, the row there still says the definition is pending.
