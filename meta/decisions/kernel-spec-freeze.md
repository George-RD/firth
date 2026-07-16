---
id: dec.kernel-spec-freeze
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-17
informed_by:
  - res.quotation-typing-prior-art
  - res.patch-compat-prior-art
---

# Firth v0.1 kernel specification freeze

The v0.1 kernel calculus in `files/firth-kernel-spec-draft.md` is frozen and
normative. Its quotation usage, finite-trace linearity obligations, erased
dictionary boundary, and elaborator patch obligations are the v0.1 contract.
Lean mechanisation targets zero admitted proofs and must agree with the prose.
Any correction requires a new governed decision.

Effectful-word observational refinement remains outside the v0.1 freeze. It is
the proposed gap
`dec.gap-firth-runtime-patch-should-effectful-verified-patch-compatibility-use-an`.
