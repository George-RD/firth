# Compiler admission and evidence

The compiler checks the complete kernel dictionary before returning a target
program. It uses the same Lean stack-effect and ownership checker and primitive
signatures as the source elaborator. This includes unused helpers, callee
signatures, row variables, nested quotations and linear values. A caller cannot
skip this by setting `checking_state: "checked"` or `proof_state: "available"`.
Those fields are historical compatibility assertions, not proof objects.

## Source-backed execution

The source runner, MVP gate and differential driver include an optional
`source` object in their existing compile request:

```json
{
  "source_path": "example.firth",
  "source_text": ": main ( -- n:Int^many ) 42 ;",
  "language_version": "0.1"
}
```

The object is the value of the top-level `source` member, alongside the
existing request ID, selected entry, checked words, erased types and versions.
The compiler re-elaborates these exact bytes and compares every word body and
type with the supplied dictionary. Missing/extra words, changed helpers,
changed bodies and changed types are refused without a target program. Source
paths are diagnostic labels and are never opened by this check. Word order is
not an identity requirement; all names, bodies and types must match.

A coherent new source and its matching kernel can compile. This establishes
correspondence to the submitted source, not an immutable history of earlier
source versions or authorship. There is no hidden cache or reusable proof token.

## Direct kernel execution

Direct structured-kernel requests remain supported and are fully rechecked for
types and ownership, but have no source-origin claim. This supports quotation
boundary types not yet expressible in the source syntax. Omitting the `source`
member selects that narrower mode; a malformed or mismatched source member
never falls back to it.

Successful responses include `verification` with schema
`firth.compiler-verification.v1`, method `kernel-type-and-linearity-recheck`,
`source_bound`, the exact source SHA-256 or null, and current Gamma/target
versions. Both modes state `refinements: "not-checked"` and identify image
evidence as unauthenticated legacy content identifiers.

## Target admission bounds

The VM refuses any image whose code or capture vector holds more than 4096
elements or whose quotations nest deeper than 32 levels
(`src/runtime/vm/src/lib.rs`, `target-spec.md` "Direct runtime ingress
bounds"). The compiler applies the same limits after lowering and reports
`firth.compile.target-bound-exceeded` instead of returning a target program
the VM would refuse to load; a program exactly at either bound compiles.
Separately, the `vm-run` JSON transport bounds request nesting at `3 * 32 + 8`
levels, chosen so that it admits every structure the decoder admits. A
quotation nested beyond the decoder's 32 levels is therefore refused by
whichever of the two sees it first, with `depth-limit` from the transport or
`nesting-limit` from the decoder depending on the operands it carries. That
transport limit belongs to the runtime adapter and is not enforced by the
compiler.

## What is not proved

Type checking does not discharge application contracts, prove termination,
prove compiler correctness, authenticate an arbitrary target image, or bind
runtime input values to their declared types. Source refinements remain
explicitly unsupported and are refused by source elaboration.

The target v1 fields `kernel_evidence_digest` and
`refinement_evidence_digest` retain their wire names for compatibility. In this
compiler they hash canonical code and erased type respectively. They are
content identifiers, not Lean proofs, solver evidence or authorisation tokens.
The VM bootstrap loader cannot authenticate the compiler invocation from those
bytes, and it now says so on every observation surface: `firth.vm-run.v1`
responses carry a `verification` member with schema
`firth.vm-verification.v1` stating `admission: structural-digest-recheck`,
`image_evidence: legacy-content-identifiers-not-authenticated-proofs`,
`refinements: not-checked` and
`patch_admission: external-verifier-unauthenticated`, the same vocabulary as
this compiler's `verification` member, and `firth-vm run` prints the same
label. Do not accept an untrusted image merely because its hashes are nonzero
or self-consistent. Authenticated image and verified-patch admission remain
separately tracked (`patch-refinement-evidence-admission`) and are not part
of baseline acceptance.

The trusted checking path here includes the Lean runtime, source elaborator,
algorithmic stack/ownership checker, compiler and their shared encoders. The
kernel metatheory is separate evidence: it is not a compiler-correctness proof
or a theorem that these executable implementations contain no defects.

## Verification

`python3 tools/loop/check_compiler_admission.py` builds the real adapters and
runs the public-input corpus. The suite includes forged marker attacks and
same-type source/body substitution, which a type-only check cannot detect.
`--baseline` is an explicit reproduction mode for recording the old bug; it is
never used by the acceptance gate. Full CI also retains the unchanged seeded
source campaign, the original fixed MVP applications and proof-binding checks.
