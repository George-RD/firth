# Proposal: kernel-non-local-effect-isolation

## Motivation

R11 requires each word's meaning to be determined by its body and the
signatures of referenced words, with no untracked non-local effects. The
kernel currently typechecks dictionary and primitive references, but it does
not expose the resolved dependency boundary as an executable artefact.

## Scope

- Define a kernel dependency boundary that records resolved word and primitive
  signatures, including references nested in quotations.
- Prove from `ProgramTyping` that every external reference in a well-typed
  body resolves through the dictionary or primitive environment.
- Add executable Lean checks for direct, nested, recursive, and rejected
  effectful references.

## Out of scope

- Changes to the frozen kernel specification or its cost table.
- New runtime effects, primitive implementations, or compiler behaviour.
- Transitive dependency closure beyond the references appearing in a word body.
