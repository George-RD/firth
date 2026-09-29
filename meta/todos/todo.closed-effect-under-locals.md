---
node: firth.toolchain.elaborator
status: open
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
