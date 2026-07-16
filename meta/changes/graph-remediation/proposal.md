# Proposal: graph-remediation

## Motivation

The initial graph remediation was written before a Cairn change proposal existed. This change retroactively records the graph, provenance, todo, and gap work so the repository contract has a reviewable proposal-before-write artefact.

## Scope

This change covers only the files listed below. It does not include `.claude/`, tools, or Governance blueprint nodes owned by the parallel session.

- `cairn.blueprint`
- `meta/decisions/blueprint-edge-semantics.md`
- `meta/decisions/firth-blueprint.md`
- `meta/decisions/host-languages.md`
- `meta/decisions/gap-firth-language-kernel-open-1-choose-usage-formalisation-as-kinds.md`
- `meta/decisions/gap-firth-language-kernel-open-2-confirm-the-linear-world-token.md`
- `meta/decisions/gap-firth-language-kernel-open-3-validate-quotation-usage-meet-inference.md`
- `meta/decisions/gap-firth-language-kernel-open-4-decide-whether-swap-generalises-to.md`
- `meta/decisions/gap-firth-language-kernel-open-5-decide-required-bool-base-type.md`
- `meta/decisions/gap-firth-language-kernel-kernel-formal-gap-add-administrative-push.md`
- `meta/decisions/gap-firth-language-kernel-kernel-formal-gap-disambiguate-sigma-notation.md`
- `meta/decisions/gap-firth-language-kernel-kernel-formal-gap-define-base-type-usage.md`
- `meta/decisions/gap-firth-language-kernel-kernel-formal-gap-define-linear-consumption.md`
- `meta/decisions/gap-firth-language-kernel-kernel-formal-gap-state-sigma-and.md`
- `meta/decisions/gap-firth-language-kernel-kernel-cost-default-keep-kappa-an.md`
- `meta/research/host-language-tradeoffs.md`
- `meta/todos/todo.component-spec-boundaries.md`
- `meta/todos/todo.diagnostic-schema.md`
- `meta/todos/todo.kernel-metatheory.md`
- `meta/todos/todo.kernel-spec-freeze.md`
- `meta/todos/todo.pin-lean-toolchain.md`
- `meta/todos/todo.quotation-typing-prior-art.md`
- `meta/todos/todo.reference-interpreter.md`
- `meta/todos/todo.refinement-discharge-design.md`
- `meta/todos/todo.surface-syntax-spec.md`
- `meta/todos/todo.vm-target-spec.md`
- `meta/todos/todo.host-language-decision.md`
- `meta/todos/todo.patch-compat-prior-art.md`
- `meta/todos/todo.diffharness-fuzz-strategy.md`
- `meta/changes/graph-remediation/proposal.md`
- `meta/changes/graph-remediation/design.md`
- `meta/changes/graph-remediation/tasks.md`

## Out of scope

The parallel session owns `.claude/`, `meta/changes/autonomous-loop/`, tools, and Governance blueprint nodes. Its later blueprint edit may land after this change.
Ownership: `todo.host-language-decision.md` is owned by this change (graph-remediation), not by autonomous-loop.
