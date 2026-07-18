# Proposal: elaborator-stack-effect-review-fixes

## Motivation

Multi-pop atoms currently report the progressively reduced stack when a later
pop underflows. This violates the elaborator contract that diagnostics carry
the complete stack immediately before the failing atom. Compose usage meet is
implemented but lacks mutation-resistant coverage for every linear case.

## Scope

- Preserve the pre-atom stack snapshot in underflow diagnostics.
- Cover swap, dip, compose, and if underflows with exact state assertions.
- Cover all linear cases of quotation usage meet and an observable linearity
  failure that kills an unconditional-many mutation.

## Out of scope

- Changes to the normative stack-effect rules or diagnostic schema.
- New elaborator atoms or public APIs.
