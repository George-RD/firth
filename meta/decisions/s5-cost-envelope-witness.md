---
id: dec.s5-cost-envelope-witness
nodes: [firth.runtime.vm]
status: accepted
related: [dec.mvp-completion, dec.mvp-gate-provenance]
informed_by: [src.firth-prd]
date: 2026-09-03
---

# The S5 witness, its home, and what it can honestly claim at v0.1

## Context

`sc-s5` was the last ungenerated obligation inside the active profile with no
plausible existing todo. PRD S5 reads:

> A non-trivial program (for example, a protocol handler or control loop)
> written, verified to a stated specification, and executed on the VM within a
> bounded cost envelope.

Discharging it needed three decisions: what a non-trivial program can be in
the v0.1 vocabulary, what "verified to a stated specification" means before
the SMT slice lands, and where the witness lives.

## Decision

### The witness is a protocol handler, not a control loop

S5 offers two examples. A terminating control loop is not expressible at v0.1
and would be dishonest to fake. Recursion comes from the dictionary, so a
self-calling word is easy to write, but terminating it needs a decreasing
measure, and the v0.1 vocabulary has neither subtraction nor a comparison
returning `Bool`: the frozen kernel `Literal` is `nat | bool | unit` with no
negative literal, and the manifest's `Gamma` declares exactly `+` and `send`.
The predicates `positive`, `nonzero` and `is-open` belong to the refinement
surface, not to the stack vocabulary. A loop written anyway would either run
to fuel exhaustion, which is not termination, or be an unrolled sequence
dressed up as a loop.

The witness is therefore S5's other example. `examples/s5/protocol-handler.firth`
dispatches a session of three tagged messages to two handlers through a
quotation chosen by `if`, with every handler reached by a dictionary call. It
is four words, higher order, takes both branches, and makes six dictionary
calls at run time from five static call sites.

Making a real control loop expressible needs `Gamma` to gain a comparison and
a subtraction, which is a registry version change and a maintainer decision,
not something this unit takes on its own. That is the honest boundary and it
is recorded here rather than left implicit in a passing gate.

### "Verified to a stated specification" is the checked word type, for now

The specification a Firth word states is its stack effect plus its
refinements. Refinements do not yet reach the obligation pipeline from the
surface, so what is machine-checked today is the declared word type: types,
ownership, and row polymorphism, checked body against declaration by the
elaborator. `examples/s5/protocol-handler.spec.toml` states each declared type
and the gate compares it with the type the toolchain actually checked and
rendered, so a drift between the stated specification and the verified one
fails rather than passing quietly.

The specification also states the program's shape, its result, and its cost.
That is deliberate: without the shape clauses, a later refactor that inlined
the handlers into a straight-line sequence would still satisfy the result and
the envelope while destroying what makes the witness non-trivial.

### The cost envelope is stated as a bound, not as the measurement

`target_cost_envelope` is above the measured `target_cost`, so the witness
states a bound that the execution stays inside rather than restating what it
happened to charge. The gate additionally requires the kernel-comparable
charge to equal the reference interpreter's exactly, which is the real
agreement claim; the envelope is the boundedness claim.

Reporting a kernel-comparable charge needed one small change to
`firth.vm-run.v1`: its `cost` object gained a `kernel` field alongside
`total`. The VM charges one administrative entry per dictionary call and the
reference interpreter does not, so the two totals differ for any program that
calls a word. The MVP corpus never called one, which is why the difference had
not surfaced. `kernel` is `total` less those entries, which is exactly the
quantity the frozen fixture corpus already records as its `lean_cost` column.

### The witness lives under the VM module

`examples/s5` is added to `firth.runtime.vm`'s paths. The obligation is the
VM's, and the artefact exists to demonstrate the VM executing a verified
program inside a cost envelope; the alternative homes, the agent corpus under
`examples/mvp` and the standard library under `stdlib`, would both misdescribe
it. The gate itself is loop machinery and lives under `tools/loop`.

## Consequences

- `sc-s5` is discharged by a pinned gate, so the claim is re-checked at every
  exhaustion decision point rather than asserted once.
- S5's stronger reading, a verified terminating control loop, stays open as
  future work gated on a `Gamma` extension.
- `firth.vm-run.v1` responses now carry `cost.kernel`. The field list of
  `firth.observation.v1` is unchanged; only the inner shape of `cost` grew.
