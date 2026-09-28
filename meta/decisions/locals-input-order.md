---
id: dec.locals-input-order
nodes: [firth.language.surface, firth.toolchain.elaborator]
status: accepted
related: [dec.agent-development-rules]
date: 2026-09-28
---
# A `locals` block that opens a body binds the inputs in stack-effect order

## Context

`locals { a b c } { ... }` takes one value off the stack for each name, the
last name from the top. Nothing tied those names to the names the word's stack
effect gives its inputs, so `locals { b a }` for inputs `a b` was accepted and
gave `b` the value the effect calls `a`.

In the S7 authoring eval, one of the two samples of run 7 (at c6a964a) wrote
29 of the 33 `locals` blocks of its first answer that way, top name first. The
same mode appears in the earlier `2026-09-28-mvp` run, 9 blocks reversed and 16
otherwise permuted. That is 2 of the 14 recorded Haiku first answers. When the inputs
had different types the author got a type error at some later use, whose hint
said to check the argument order with `swap`; the sample never found the real
cause, and by its last round it deleted its `locals` blocks and every task
failed. When the inputs share a type, the program checks and computes the
wrong result, so no diagnostic appears at all.

## Decision

A `locals` block that is the first item of a word's body binds that word's
inputs: its `k` names bind the top `k` declared inputs, in the stack effect's
order. A name the stack effect gives to an input must be bound to that input.
Otherwise the program is refused with `firth.name.locals-order` before erasure,
and the one diagnostic lists every such block in the file with what each of its
names would hold, and the block to write instead.

Names the stack effect does not declare remain the author's to choose. Blocks
that are not the first item of the body, and blocks with more names than
declared inputs, are not constrained by this rule; the checker judges them as
before.

The kernel, the erasure algorithm and the meaning of every accepted program are
unchanged: the rule only refuses programs.

## Alternatives rejected

- A better hint on the type error that follows a reversed block. Cheaper, but
  it cannot help when the inputs share a type: that program checks and returns
  the wrong value, so no hint is ever shown.
- Making stack-effect names bind implicitly in the body. It removes the
  ordering question entirely, but changes what every body means, conflicts with
  point-free bodies that never name their inputs, and interacts with linear
  inputs that must be used exactly once. It would need its own design.

## Evidence

- Over the 640 recorded Firth answers in `eval/s7/runs`, the rule refuses 40
  and none of the 129 that pass their tasks; it refuses none of the 51 `.firth`
  files in the repository.
- Applying the blocks the diagnostic suggests to those 40 answers makes 16 of
  them check, and 8 then pass every case of their task. The rest carry other
  mistakes, such as a `main` whose stack effect drops its inputs.
- `FirthNamesTest` and `ElaboratorDiagnosticsTest` hold the fixtures, including
  count-below from run 7 verbatim; a planted change that disables the rule, and
  one that suggests the names in reverse, each fail them.

## Status

Accepted on 2026-09-28 by the Language core thread, under the maintainer's
standing delegation ("you decide; hard now, easy later"). It changes the
surface language, not the kernel or an acceptance criterion. The maintainer
can reverse it.
