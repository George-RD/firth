---
id: dec.gap-firth-language-kernel-open-1-choose-usage-formalisation-as-kinds
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.firth-kernel-spec.summary]
---

# Decision: OPEN-1 usage is a per-type annotation, not a kind

## Question

OPEN-1: choose usage formalisation as kinds or capability flags

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "OPEN-1: choose usage formalisation as kinds or capability flags"`.

Resolved by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`. The answer is
read from the frozen `files/firth-kernel-spec-draft.md` and its zero-admit
mechanisation under `src/interpreter/Firth/`; no frozen rule is amended.

## Resolution

Resolved as a per-type annotation. Section 3 of the kernel specification
attaches `u ::= many | linear` to every value type (`ι^u` and
`[Σ₁ → Σ₂]^u`) and defines the meet on those annotations; section 11 lists
the kinds-versus-flags question as a mechanisation question that does not
alter the frozen rules. The mechanisation chose the flag form: `Usage` is a
two-constructor inductive carried as a field of both `ValueType`
constructors, `ValueType.usage` reads it, and the `(DUP)`, `(DROP)`,
`(COMPOSE)` and `(QUOTE)` rules are stated over that field
(`AtomTyping.dup`, `AtomTyping.drop`, `AtomTyping.compose`,
`AtomTyping.quote`). No kind judgement exists or is needed for the frozen
rules; introducing one would be a mechanisation refactor, not a semantic
change, and would have to preserve the same theorems.
