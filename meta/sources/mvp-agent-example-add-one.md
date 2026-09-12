---
id: src.mvp-agent-example-add-one
file: examples/mvp/add-one.firth
verification: unverified
type: model-authorship-transcript
date: 2026-09-03
output_sha256: 960d894edfca48657229f6aa21921da7002acad4c27abcb2d9d4275b44aca401
---
# Model authoring transcript: add-one

## Context

The model received only these inputs:

- `docs/firth-agent-guide.md`
- `src/agent/Firth/Agent/DiagnosticEnvelope.lean`
- `src/agent/Firth/Agent/Validation.lean`
- `src/agent/Firth/Agent/ElaboratorDiagnostics.lean`
- Task: provide a basic Firth application that exercises the Gamma primitive
  profile, for the MVP agent corpus.

The three applications already in the corpus use only literals, `call` and
`if`, so nothing executable reached the primitive registry. Section 3 of the
guide gives the closed stack effect form, section 4 gives `prim <name>`, and
section 8's first worked application uses `prim +` with the declared effect
`Int^many Int^many -- Int^many`. Composing those, a closed application that
applies the primitive is two literals followed by the primitive.

## Model output

```firth
: add-one
  ( -- result:Int^many )
  41 1 prim +;
```

## Note on provenance

`dec.mvp-gate-provenance` clause 4 records that no gate can prove a transcript
was not fabricated, because the loop is itself a code model. This transcript
records byte-level provenance for drift detection; it is not evidence of
authorship independence.
