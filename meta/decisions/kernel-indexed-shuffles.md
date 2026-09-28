---
id: dec.kernel-indexed-shuffles
nodes: [firth.language.kernel]
status: accepted
supersedes: [dec.gap-firth-language-kernel-open-4-decide-whether-swap-generalises-to]
related: [dec.kernel-spec-freeze]
date: 2026-09-27
---
# Add `pick n` and `roll n` to the kernel for cost

## Context

`dec.gap-firth-language-kernel-open-4-decide-whether-swap-generalises-to`
answered "no indexed shuffles in v0.1" and noted that adding them would amend
the frozen kernel specification. Since then, named locals became the normal
way to write Firth, and their erasure made reaching a value n places down cost
a nested `[ … ] dip swap` chain of about five kernel steps per level. The M1
inventory allocator ran out of its 1,000,000-step fuel with locals in its
pairwise scan and had to hand-write that scan with stack words.

## Decision

The kernel gains two atoms, both costing one step:

- `pick n` copies the `many` value n places below the top to the top;
- `roll n` moves the value n places below the top to the top, keeping the
  others in order.

They are kept for cost, not expressive power: each has the same effect as a
`dip`/`swap`/`dup` chain. This is a dated exception to the minimality claim in
`files/firth-kernel-spec-draft.md` §2 and to PRD R1, recorded there. Named
locals erase to them, so a use of a local costs one step however deep it is.
The target gains `PICK` (13) and `ROLL` (14). The Gamma registry is unchanged.

The mechanisation keeps zero admits: typing, preservation, progress and the
linearity backward-adequacy theorem cover both atoms.

## Status

Accepted on 2026-09-28. Because it amends the frozen specification, it
waited on the maintainer, who delegated the call under the rule "hard now,
easy later": cheap local access in the kernel avoids hand-written stack
juggling in every program and the fragile proofs over it.
