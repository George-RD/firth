# Proposal: rust-vm-lifecycle-integration

The VM already exposes independent image decoding, active execution, patch
admission, and rollback APIs, but no integration contract proves that they
compose as one lifecycle. The missing scenario could allow a patch to publish
without changing the active execution result, or let an old resolved word
observe replacement contents.

## Scope

- Add deterministic standard-library integration coverage in the existing
  `src/runtime/vm` test module.
- Load the canonical image through `encode_image` and `decode`, execute the
  active `main`, apply one verified replacement, execute the replacement, and
  roll back with a fresh image version.
- Prove rejected stale and unproven patches leave the active image and
  execution result unchanged, and that a pre-existing word handle retains its
  resolved body.

## Out of scope

- No changes to the decoder, executor, image format, patch validator, or
  rollback implementation.
- No compiler integration, effectful patch support, new target instructions,
  or unsafe code.
