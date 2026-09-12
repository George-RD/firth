---
node: firth.runtime.patch
status: open
created: 2026-09-09
---

Requires: language-02-compiler-evidence language-03-runtime-conformance language-06-source-refinement-execution

## Goal

Bind verified-patch admission to real elaborator-owned kernel and refinement
evidence. At `80a9d41` `compileWords` in `src/compiler/Firth/Lowering.lean`
fills `kernelEvidenceDigest` with a hash of the canonical code and
`refinementEvidenceDigest` with a hash of the erased type, and the VM in
`src/runtime/vm/src/image_patch.rs` only checks that each digest has the
right length and is non-zero. Content hashes of code are not proof, and the
VM-side shape check is not evidence binding.

## Acceptance criteria

- Reproduce through the public compile and patch boundaries that two words
  with equal lowered code and erased type but different refinement evidence
  receive identical `refinement_evidence_digest` values today (PR #109 review
  threads on `Lowering.lean`: "compileWords emits generated-code and
  erased-type hashes as kernel/refinement evidence" and "Bind evidence
  digests to the actual proof artefacts"). Retain the failing-before record.
- Carry elaborator-owned digests through the compile request; the VM
  verifier rejects a patch whose digests are not bound to a rechecked
  discharge record for the replacing word. Content hashes of code alone are
  never labelled proof.
- Check refinement subsumption on the Lean side; its record is what the VM
  digest names. Erased stack-effect equality stays exact.
- Negative tests: forged, stale, swapped and missing evidence each leave the
  live image unchanged.
- Update `src/runtime/vm/target-spec.md`, `specs/tcb-boundary.toml` and the
  documentation together with the code.

## Traceability

PRD R7, R6 and 4.3; obligations `req-r7` and `scope-runtime-patch`. Opened by
the baseline obligation audit (`meta/changes/baseline-obligation-audit/`) at
`80a9d41`.
