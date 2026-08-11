# Design: rust-vm-lifecycle-integration

Use the public lifecycle APIs already assembled by the VM. Build the existing
dictionary fixture, serialise and decode it to exercise the canonical image
boundary, then create an `ImageStore`. Capture an old `WordHandle`, execute
the active image, apply the existing evidence-backed replacement, and assert
the new active execution result. Roll back using the prior image version and
assert the restored result and fresh monotonic version. A second scenario
attempts stale and rejected evidence patches and checks both the snapshot and
active execution remain unchanged.

## Changes

ADDED:
- Integration tests in `src/runtime/vm/src/tests_image.rs`.

MODIFIED:
- None.

REMOVED:
- None.

RENAMED:
- None.
