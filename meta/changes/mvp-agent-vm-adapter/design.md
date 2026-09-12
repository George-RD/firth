# Design: mvp-agent-vm-adapter

## Approach

The adapter is built to have no semantic authority. It decodes the request
into a word vector, seals it with `seal_image`, encodes it with
`encode_image`, and hands the bytes to `decode`. Everything the target
contract requires of an image is then checked by the trusted decoder on the
same path a real image takes: word ordering, duplicate names, canonical
identifiers, the canonical erased word-type grammar, nesting and size bounds,
the dictionary and image digests, and each word's `body_digest` against the
canonical encoding of its own code.

That last check is the point. A compiler that computed a body digest from a
different encoding is refused here with `invalid-image` rather than silently
executed, which makes the Lean encoder's agreement with the Rust one a
mechanical precondition of every gate run rather than an assumption.

JSON is parsed by a bounded reader in the crate rather than by a dependency.
`target-spec.md` §7 asks the trusted implementation to stay dependency-minimal
and reviewable, and the parser is deliberately narrower than RFC 8259:
integers only, no leading zeros, no duplicate members, bounded depth and size.
A number that parses has exactly one textual form, so a request cannot smuggle
a rounding difference past the adapter.

The response uses the reference-run adapter's value encoding, so the same
`initial_stack` can be sent to both hosts and the two `stack` arrays compare
directly. Where the two hosts genuinely observe different things the adapter
does not pretend otherwise: the hidden world observation is reported as the
VM's own `{"bytes": [...]}`, because the Lean `{"ids": [...]}` counts World
tokens in a configuration and the VM records registry observation bytes. The
gate compares those through one documented projection.

Two kernel values have no v0.1 target representation: the `unit` literal, and
a kernel-shaped quotation, which the compiler must lower first. Both are
refused with `unsupported-value` rather than approximated.

Named-entry execution matters for cost agreement. Wrapping a compiled word in
a synthetic `main` that calls it would charge an administrative word entry the
reference interpreter never charges, so the entry word is named in the request
and executed as the top frame instead.

## Changes

ADDED:
- `src/runtime/vm/src/json.rs`: the bounded JSON grammar, parser, and writer.
- `src/runtime/vm/src/adapter.rs`: request decoding, sealing through the
  trusted decoder, execution, and `firth.observation.v1` rendering.
- `src/runtime/vm/src/tests_adapter.rs`: grammar refusals, round-tripping,
  success, classified traps, fuel exhaustion, a wrong body digest, schema
  refusals, unrepresentable initial values, and determinism.
- `execute_diagnostic_entry`, `execute_report_entry`, `observe_image_entry`
  for named-entry execution.

MODIFIED:
- `src/runtime/vm/src/main.rs`: the `vm-run` subcommand.
- `src/runtime/vm/tests/cli.rs`: stdin/stdout contract and the refusal path.
