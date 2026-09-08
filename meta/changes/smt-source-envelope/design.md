# Design: smt-source-envelope

Use a domain-separated SHA-256 over sorted relative paths and byte contents for
all `.lean` files below `src/`, plus `lean-toolchain`, `lakefile.toml` and
`lake-manifest.json`. Each region's new hash binds the envelope digest, region
kind, name and body with length-delimited byte framing. Region counts and the
record wire format do not change; old records intentionally become stale.

The supported package has no third-party Lake dependencies and every target's
`srcDir` is within `src/`. Refuse unsupported source roots, dependencies,
symlinked inputs and missing inputs rather than silently hash a partial tree.
This deliberately includes tests and comments: unrelated Lean edits also
invalidate records. A narrower dependency closure requires a separately
verified Lean dependency extractor, not an approximate import regex.

Avoid self-reference by masking only the two literal lists in the unique,
strictly parsed `defaultSmtProofBindings` initializer. No executable definition
or arbitrary text between declarations is exempt from hashing. Compile-time
`.olean` hashes remain a separate gate and must be regenerated from the actual
pinned build, not from source hashes.

The source envelope is an integrity binding, not proof of semantic correctness
or solver provenance. It assumes the standard declared Lake build and does not
attest a hostile host, altered toolchain or undeclared search-path overrides.
