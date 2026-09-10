---
id: dec.gap-firth-language-kernel-open-4-decide-whether-swap-generalises-to
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: OPEN-4 swap does not generalise to indexed rot atoms in v0.1

## Question

OPEN-4: decide whether swap generalises to indexed rot atoms

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "OPEN-4: decide whether swap generalises to indexed rot atoms"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

Resolved as no for v0.1. Section 2 of the kernel specification fixes the
atom set with `swap` as the only exchange rule and states that the atoms are
minimal for v0.1; section 10 has named locals desugar to `dip`, `swap` and
`dup` patterns; section 11 lists whether `swap` later gains indexed shuffles
as a question that does not alter the frozen rules. The mechanisation has
`Atom.swap` only, typed by `AtomTyping.swap` and preserved by
`KernelMetatheory.preservation_swap`; the elaborator's named-local erasure
(`elaborator-named-local-erasure`) realises deeper shuffles by `swap` and
`dip` compositions, which `STACK_JUGGLE` lints. Adding indexed atoms would
be a frozen-specification amendment (dec.loop-autonomy clause 2b), and the
expressive-power side of that question is the subject of the open todo
`kernel-minimality-evidence` (PRD R1).
