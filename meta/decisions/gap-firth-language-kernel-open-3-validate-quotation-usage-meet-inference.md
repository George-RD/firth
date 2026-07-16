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

Not resolved. Research `res.quotation-typing-prior-art` supplies supporting
prior art for a Firth-derived meet proposal, but it does not validate the rule.
Mirth has no reviewed mechanised proof, Kitten has no linear-capture soundness
result, and Cat has no affine usage dimension. Lean must still prove
preservation and at-most-once linearity safety.

The proposal must account for literal ownership as well as dynamic captures.
For `[p]`, recursively meet the usages of every base literal `lit c` embedded
in `p`; the empty meet is `many`. Thus `[lit h]` is `linear` when `h` has a
linear base type. For `quote` and `compose`, every meet involving `linear`
remains the conservative candidate result `linear`.

The research also finds that the draft `if` rule is not linearity-safe. It
accepts branch quotations of arbitrary usage, while execution discards the
unchosen branch. The v1 recommendation is that both branches be `many`, but
that recommendation remains subject to the unresolved proof obligation.

This gap remains `proposed` and explicitly unresolved until the normative
kernel rules include literal ownership and the Lean mechanisation discharges
the required proofs. Unrestricted recursion limits the general theorem to
at-most-once safety over finite traces; exact-once consumption additionally
requires termination and an empty-linear-residue terminal condition.
