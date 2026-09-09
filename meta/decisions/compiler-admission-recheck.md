---
id: dec.compiler-admission-recheck
nodes:
  - firth.toolchain.compiler
status: accepted
date: 2026-09-09
---
# Compiler admission by rechecking

Use the existing Lean elaborator/type checker rather than treating public JSON
flags or hashes as portable proof. Recheck the complete submitted kernel
against its declared dictionary on every compiler invocation. Source-backed
callers additionally submit source bytes and the compiler checks exact
source/kernel/type correspondence by fresh elaboration.

Preserve direct kernel compilation as an explicit, independently typechecked
mode without a source-origin claim. This mode is useful for the structured
quotation tests whose boundary types cannot yet be written in source syntax.
The distinction is explicit in the successful response, not inferred from a
missing field. Public input markers remain compatibility assertions only.

Preserve the target v1 image contract. Its historical evidence slots currently
carry code/type content identifiers; do not call them authenticated proofs or
refinement evidence. Fresh compiler checking is a property of this invocation,
not an authorisation capability that can be safely accepted from arbitrary
image bytes. Authenticated image/patch admission remains a separate gate.

This is an M0 trust-boundary repair under the existing milestone decision,
not a new language feature, a weakened requirement, or a claim of source
contract execution. No kernel typing rule or metatheory theorem changes.
