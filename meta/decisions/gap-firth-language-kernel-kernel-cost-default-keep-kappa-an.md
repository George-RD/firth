---
id: dec.gap-firth-language-kernel-kernel-cost-default-keep-kappa-an
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: kappa stays an uninstantiated total function

## Question

Kernel cost default: keep kappa an uninstantiated total function, with concrete values in vm-target-spec

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "Kernel cost default: keep kappa an uninstantiated total function, with concrete values in vm-target-spec"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

Accepted as frozen. Section 8 of the kernel specification states that each
step carries a cost from the uninstantiated total table `κ` (`κ(a)` for
atoms, `κ(π)` for primitives, `κ(unfold)` for `S-WORD`), that targets
instantiate `κ`, and that concrete values belong to the VM target
specification. The mechanisation keeps `κ` abstract: `CostTable` in
`Interpreter.lean` is a record of total functions, and every theorem
(`step_deterministic`, `preservation`, `progress`, and the
`CostInvariance` results `traceCost_eq_sequenceCost`, `seq_cost_composes`
and `step_cost_matches_kappa`) is quantified over an arbitrary
`costs : CostTable`. `src/runtime/vm/target-spec.md` section 5 supplies the
concrete `kappa_vm`. `kernel-cost-semantics-claims` and the S5 envelope gate
check target claims against that parameterisation rather than against
measurement.
