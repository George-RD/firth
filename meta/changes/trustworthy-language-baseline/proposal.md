# Trustworthy language baseline

## Motivation

The maintainer asked to update the roadmap and start making Firth a useful,
credible language. PR #109 has passing examples but unresolved guarantee and
input-boundary defects. Empty tracked work is not application acceptance.

## Scope

First reproduce and close three bounded defects: source annotations silently
ignored by the default refinement builder; linear quotation usage erased by
lowering; and malformed capture-state lengths reaching canonical VM encoding.
Reject empty source as a structured error. Add real-process regressions and
retain red/green results. Do not claim that these fixes authenticate evidence
or implement source-level refinement proofs.

A separate roadmap change will add executable acceptance milestones and
selector-visible work for remaining trust defects, differential testing, a
real inventory-allocation component, and documentation-only agent changes.

## Verification

Run the real adapter regression gate, all Lean/Rust/Python checks and governed
proof bindings. No expected output or proof pin may be changed to hide a bug.
Record unrun gates and unresolved findings explicitly; do not merge while they
remain. Local GitHub DNS and Lean/Rust/Cairn tools are unavailable in this
session, so language execution is verified by pinned GitHub Actions.
