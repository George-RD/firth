---
id: dec.closed-effect-under-locals
nodes: [firth.toolchain.elaborator]
status: accepted
related: [dec.locals-input-order, dec.agent-development-rules]
date: 2026-10-10
---
# A call to a word with a closed effect runs above the block's unused locals

## Context

A word whose stack effect has no row, such as
`: add2 ( a:Int b:Int -- r:Int ) prim + ;`, takes the whole stack: the type
checker accepts a call only when the stack holds exactly its inputs. Inside a
`locals` block, erasure keeps each local that is still to be used on the
stack, under the values the body pushes. So in

```
: g ( x:Int n:Int -- r:Int s:Int ) locals { x n } { x 1 add2 n } ;
```

`add2` saw `n` below its two inputs and the word was refused with
`firth.type.word-input-mismatch`, "the stack before it is Int Int Int". The
author sees two values: the guide and the diagnostics say a local is a name,
not a value on the stack. Whether a program was accepted depended on where
erasure put the locals, not on the program as written
(`todo.closed-effect-under-locals`).

## Decision

When a word or primitive whose input has no row is called inside a `locals`
block, erasure moves every local still to be used that lies below the call's
inputs to the top, and runs the call under `dip` beneath them. This uses the
moves erasure already makes for an unused local among an item's inputs
(`raise`, then `beneath` in `ErasureRel`); a closed call's reach is the whole
stack instead of its inputs (`signatureReach` in
`src/elaborator/Firth/Erasure.lean`). The type checker then sees the call on
exactly its inputs.

Values the body pushed, and the rest of the stack a word with a row was given,
are still on the stack under the call's inputs, so such a call is refused as
before: only locals, which the body cannot see, are moved.

The kernel and its typing rules are unchanged. Erasure's output is still
related to its input by `ErasureRel`, with no new constructor. More programs
are accepted; no program that was accepted changes meaning, since a call with
no unused local below its inputs is erased as before.

Accepted by the project coordinator under the maintainer's standing
delegation ("you decide; hard now, easy later"), 2026-10-10, together with the
independent reviewer's approval of the PR that carries it.

## Alternatives rejected

- Refusing the call with a message that says the callee's effect is closed
  and a live local is below its inputs. Cheaper, and it changes nothing that
  is accepted, but it keeps the rule that a local is not on the stack false
  for one kind of call, so authors would have to know how erasure places
  locals to write a correct program.
- Treating a closed effect as if it had a row. It would accept the call on any
  stack, changing what a declared effect means everywhere, not only under
  `locals`.
