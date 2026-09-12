---
id: dec.gap-firth-language-kernel-open-5-decide-required-bool-base-type
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: OPEN-5 Bool is a required base type

## Question

OPEN-5: decide required Bool base type versus Church encoding

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "OPEN-5: decide required Bool base type versus Church encoding"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

Resolved as a required base type. Section 3 of the kernel specification
requires `Γ` to contain `Bool^many`, and the `(IF)` rule in section 4 and
the `S-IF-T`/`S-IF-F` transitions in section 5 dispatch on a `Bool^many`
literal; section 11 lists a Church encoding as a question that does not
alter the frozen rules. The mechanisation has `BaseType.bool`,
`Literal.bool`, `defaultGamma` typing Boolean literals, and
`AtomTyping.ifThenElse` requiring `.base .bool .many` under the two `many`
branch quotations, preserved by `KernelMetatheory.preservation_if`. No Church
encoding is offered by the kernel; a library may define one as ordinary
words without any change to the freeze.
