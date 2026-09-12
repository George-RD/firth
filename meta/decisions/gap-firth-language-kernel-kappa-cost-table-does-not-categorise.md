---
id: dec.gap-firth-language-kernel-kappa-cost-table-does-not-categorise
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-17
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: kappa does not categorise the administrative push

## Question

kappa cost table does not categorise the administrative S-PUSH transition; interpreter currently treats it as zero-cost

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "kappa cost table does not categorise the administrative S-PUSH transition; interpreter currently treats it as zero-cost"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

The administrative atom `push v` exists only in the semantics (frozen spec
section 5) and is not a kernel atom of section 2, so the total table `κ` of
section 8, which is defined over kernel atoms, primitives and `unfold`, has
no entry for it by construction. The `S-PUSH` transition therefore carries
no kernel cost. The mechanisation encodes exactly that: the `S-PUSH` case of
`step` in `Interpreter.lean` charges `0`,
`CostInvariance.step_cost_matches_kappa` and `traceStep_cost_matches_kappa`
prove every charged step cost equals `chargedCost costs atom`, and
`seq_cost_composes` proves compositionality under that charging. The VM
target instantiates `kappa_vm` accordingly (`src/runtime/vm/target-spec.md`
section 5: `DIP`, `QUOTE` and `PUSH_CAPTURE` carry no hidden additional
semantic cost), and the S5 envelope gate compares kernel and VM costs under
this reading.

Charging `push` would enlarge the domain of `κ` and is a frozen-specification
amendment (dec.loop-autonomy clause 2b), requiring a superseding decision and
a green re-run of the cost-invariance and S5 gates. Until then the zero-cost
administrative push is the accepted, mechanised reading.
