---
id: dec.gap-firth-language-kernel-open-3-validate-quotation-usage-meet-inference
nodes: [firth.language.kernel]
status: accepted
date: 2026-07-16
gap: true
informed_by: [res.quotation-typing-prior-art]
---

# Decision: OPEN-3 quotation usage meet and linearity

## Question

OPEN-3: validate quotation usage meet inference at compose and quote boundaries

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "OPEN-3: validate quotation usage meet inference at compose and quote boundaries"`.

## Resolution

The v0.1 quotation usage rule is accepted. A quotation's usage is the meet of
all usages embedded by `quote` and `lit`, computed recursively through nested
quotation bodies. The empty meet is `many`; any embedded `linear` value makes
the quotation `linear`, including `[lit h]` when `h` has a linear base type.
`compose` takes the meet of its operands, while `call` and `dip` consume one
quotation value in their transition and accept either usage. `if` requires
both branch quotations to be `many` and to have identical stack effects, so
the unchosen branch may be discarded. `dup` and `drop` remain restricted to
`many`, with no implicit coercion.

The supporting prior-art note is evidence, not a mechanised proof. Lean must
prove preservation and at-most-once linearity safety over finite traces. An
exact-once theorem additionally requires a termination premise and a terminal
configuration with empty linear residue. The decision resolves OPEN-3 for the
frozen rule while recording its proof obligations.
