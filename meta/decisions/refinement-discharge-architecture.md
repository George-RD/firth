---
id: dec.refinement-discharge-architecture
nodes:
  - firth.toolchain.smt
  - firth.toolchain.elaborator
  - firth.toolchain.agent
  - firth.language.kernel
status: accepted
date: 2026-07-17
---

# Refinement discharge architecture

Adopt the architecture boundary in
`spec/smt/refinement-discharge-architecture.md`. Refinements remain outside
the frozen kernel, and the elaborator contract is `(WordType, Spec)`. SMT is a
closed-world backend for a typed, normalised decidable fragment once the type
system fixes the concrete predicate and stack-refinement representation. The
decision fixes the backend boundary, not that upstream syntax. Unsupported,
unknown, timed-out, malformed, or unsoundly translated obligations are not
accepted and escalate to Lean when possible.

For v0.1, the pinned SMT solver is within the PRD's trusted computing base for
successful `unsat` results. Discharge records bind the obligation, word and
specification hashes, translation, profile, solver version, and body. Unsat
cores are explanatory evidence, not independently checked certificates.
Lean checks translation soundness before a predicate or VC generator is
eligible, so the translator remains a checked artefact rather than an
additional trusted component. Proof-certificate checking remains an explicit
future fork. Diagnostics use
the accepted versioned envelope and report the obligation at the word boundary
with expected and actual refined stack states.
