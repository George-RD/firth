# Design: mvp-agent-elaborate-adapter

## Approach

The response is shaped so the gate joins adapters rather than reconstructing
records. `checked_words` carries the evidence markers and the kernel program
in exactly the form `firth.checked-kernel.v1` requires, `erased_word_types`
in exactly the form the compile adapter decodes, and `kernel_programs` in the
form the reference-run request's `checked_kernel.program` takes. A gate that
builds these by hand would be a fourth hand-written encoder of the same
records, and the drift would surface as a differential failure that looks like
a compiler bug.

The erased word type is emitted structurally, not as the canonical target
string. The elaborator has no business knowing the target grammar; the
compiler renders it, and `dec.compiler-target-lowering` records why that
rendering needs positional labels and renamed rows. The wire form is
lossless for a resolved scheme: an unresolved row, type, or usage variable is
refused rather than defaulted, since defaulting one would publish a contract
the checker never established.

The `[gamma]` table is resolved into both environments the pipeline needs: an
erasure `Signature` carrying ownership classes, and a typing `Scheme` carrying
the full row-polymorphic effect. `send` is declared here even though the
compiler refuses to lower it. That is deliberate and honest: the language has
`send`, the v0.1 target does not implement it, and the two facts belong to
different components.

Failure goes through `Firth.Agent.elaboratePipeline`, which already sorts
diagnostics into versioned envelopes. That path existed and was reachable from
no executable.

## Changes

ADDED:
- `src/agent/Firth/Agent/ElaborateAdapter.lean`: request decoding, the Gamma
  environments, the structured scheme and kernel encoders, and the response.
- `src/agent/FirthElaborateCli.lean` (`firthElaborate`).
- `src/agent/FirthElaborateTest.lean` (`firthElaborateTest`).
- `meta/todos/todo.mvp-agent-elaborate-adapter.md`.

MODIFIED:
- `lakefile.toml`: the adapter root, both executables, and the test in
  `defaultTargets`.
- `src/agent/FirthAllTest.lean`: run the suite under `lake test`.
- `meta/todos/todo.mvp-agent-gate.md`: `Requires` gains this slug.
