# Design: mvp-agent-gate

## Approach

Provenance is verified before anything is executed, and that ordering is
itself tested. Every fail-closed case in the suite is observable without a
toolchain precisely because no subprocess runs until the manifest, the guide,
the three pinned interface files, every application source and every
transcript have been checked. A path that leaves the repository root, an
absolute path, a malformed hash, a duplicate application, a lowered
`applications.minimum`, and a transcript recording an output that is not the
checked-in application are each a refusal.

Isolation is enforced rather than asserted. Each application is copied alone
into a scratch directory, and the gate then checks that the directory holds
exactly that one file before it runs anything. The adapters are invoked as
built binaries with the scratch directory as their working directory, so an
application cannot reach the repository even by accident.

The pipeline joins adapters rather than reconstructing records: the elaborate
response's `checked_words` and `erased_word_types` become the compile
request's members verbatim, the compile response's `target_program` becomes
the VM request's, and the elaborate response's `kernel_programs` becomes the
reference run's `checked_kernel.program`. A gate that built those by hand
would be a fifth encoder of the same records.

The comparison covers every field `[comparison]` names. Two need a stated
reading. A dual fuel exhaustion is `bounded-fuel-inconclusive`, so the gate
refuses it rather than passing it: inconclusive is not agreement. And the two
hosts observe the world differently, the reference interpreter reporting live
`World` identifiers and the VM reporting registry observation bytes, so the
gate compares the one fact both express: whether the effect thread was touched
at all.

A fourth application was added because the first three reach only literals,
`call` and `if`. Nothing executable exercised the `Gamma` primitive profile
that the comparison contract names, so the gate would have been green while
proving nothing about primitives. `add-one` applies `+`.

## Changes

ADDED:
- `tools/loop/mvp_agent_gate.py`.
- `tools/loop/test_mvp_agent_gate.py`.
- `examples/mvp/add-one.firth` and
  `meta/sources/mvp-agent-example-add-one.md`.

MODIFIED:
- `tools/loop/mvp_agent_manifest.toml`: the fourth application entry.
- `AGENTS.md`: the gate and its suite in the command list and the QA section.
