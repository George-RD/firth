---
id: dec.rust-vm-integration-split
nodes: [firth.runtime.vm]
status: accepted
date: 2026-08-11
---

# Rust VM integration split

## Context

Autonomous author: loop/split.rust-vm-implementation.

The open `rust-vm-implementation` todo combines composition of already-landed
execution, image, and patch components with reference conformance. It is too
large for one reviewable unit. The split must preserve the parent's acceptance
criteria, keep the parent open, and avoid reopening completed prerequisite
work.

## Decision

Split the parent into exactly two child todos: `rust-vm-lifecycle-integration`
for the end-to-end image and patch lifecycle, and
`rust-vm-reference-conformance` for the deterministic Lean comparison
boundary. Keep crate-wide formatting, build, licence, and no-stub checks as
the parent's final integration gates rather than creating an audit-only child.

## Rationale

The lifecycle child composes the existing public boundaries and proves load,
execution, verified replacement, rejection, rollback, and in-flight image
behaviour without duplicating their unit tests. The conformance child owns the
remaining cross-host comparison and fixture obligations. A separate release
audit would have no independent runtime behaviour and would duplicate the
verification required for every implementation child and for the parent.

## Consequences

The parent remains open with both child slugs in `Requires:`. The lifecycle
child is gated by the four completed VM prerequisite todos, while the
conformance child is gated by the completed execution, interpreter, and
metatheory todos. The parent can be completed only after both children land
and its full acceptance gates pass.
