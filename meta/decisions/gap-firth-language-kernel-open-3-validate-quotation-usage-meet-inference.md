---
id: dec.gap-firth-language-kernel-open-3-validate-quotation-usage-meet-inference
nodes: [firth.language.kernel]
status: proposed
date: 2026-07-16
gap: true
informed_by: [res.quotation-typing-prior-art]
---

# Gap: OPEN-3: validate quotation usage meet inference at compose and quote boundaries

## Question

OPEN-3: validate quotation usage meet inference at compose and quote boundaries

## Context

Node: `firth.language.kernel` (state: Ghost)

Opened by `cairn gap firth.language.kernel --question "OPEN-3: validate quotation usage meet inference at compose and quote boundaries"`.

## Resolution

Research `res.quotation-typing-prior-art` validates the meet rule for `quote`
and `compose` when construction transfers capture ownership: `many meet many`
is `many`, and every meet involving `linear` is `linear`.

The research also finds that the draft `if` rule is not linearity-safe. It
accepts branch quotations of arbitrary usage, while execution discards the
unchosen branch. The recommended v1 rule requires both branches to be `many`.

This gap remains proposed pending CTO ratification of that conservative `if`
restriction. The alternative is a larger ownership-aware conditional that
returns or otherwise accounts for the unselected linear capture.
