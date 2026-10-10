---
node: firth.toolchain.elaborator
status: done
created: 2026-09-29
---

# A word with a closed effect cannot be called while a local is still live

Found while checking the edits of the branch-mismatch hints (the PR that adds
`staleEdit` and `missingEdit`). A word whose effect has no row variable, such
as `: h ( a:Int b:Int -- r:Int ) prim + ;`, takes the whole stack. Inside a
`locals` block, erasure keeps the locals that are used later on the stack, so
the call sees them too:

```
: g ( x:Int n:Int -- r:Int ) locals { x n } { x n h } ;              \ accepted
: g ( x:Int n:Int -- r:Int s:Int ) locals { x n } { x 1 h n } ;      \ refused
: g ( x:Int n:Int -- r:Int ) locals { x n } { x locals { y } { y n h } } ; \ refused
```

The second and third are refused with `firth.type.word-input-mismatch`:
"`h` in `g` needs Int Int on top of the stack, but the stack before it is Int
Int Int". The author sees two values before `h`; the third is `n`, which a
local is said not to be ("a local is not a value on the stack"). The same
calls with `h` declared `(forall ρ; ρ a:Int b:Int -- ρ r:Int)` are accepted.

Whether a program is accepted here depends on how erasure places locals, not
on the program as written.

## To do

- Decide between erasing such a call so the live locals are out of its way
  (for example under `dip`, which keeps the kernel unchanged) and refusing it
  with a message that says the callee's effect is closed and a live local is
  below its inputs. The first changes what is accepted, so it needs its own
  decision record.
- Either way, add the three programs above as tests, with a planted failure.

## Resolution

Decided in `dec.closed-effect-under-locals`: a call whose effect has no row
reaches the whole stack, so erasure lifts every local still to be used from
below its inputs and runs it under `dip` (`signatureReach` in
`src/elaborator/Firth/Erasure.lean`; `Signature.closed`, set from the effect
in `signatureOfEffect`). The second program above is now accepted; the first
already was. The third was also already accepted on main: `n`'s last use is a
move since #213, so nothing is left below the call.

`firthErasureTest` checks that a closed call with a later local, at the top
level of the block and in an inner block, runs under `dip`, that the same call
with a row runs where it is written, and that a closed call with nothing below
its inputs, including the third program, is not moved. Restoring the old reach
fails the first of these. `examples/programs/locals.firth` runs two such
calls on the VM and the reference interpreter (`add-then-keep`,
`add-in-block`, with hand-written results), and
`examples/programs/refused/closed-effect-value-below.firth` keeps a value the
body pushed under a closed call refused.

The message for a closed call refused because of what is below its inputs
still does not say the effect is closed (`todo.closed-callee-diagnostic`).
