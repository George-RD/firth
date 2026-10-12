---
node: firth.toolchain.agent
status: open
created: 2026-10-11
---

# Write the reordering edit so it can be applied when it crosses a line

Found in review of #254. The reordering hint (`withCallAccount` in
`src/elaborator/Firth/Pipeline.lean`, worded in `callExplanation` in
`src/agent/Firth/Agent/ElaboratorDiagnostics.lean`) says "write `X` in
place of `Y` on line N", with `Y` written with its whitespace collapsed.
When the values it reorders are written over more than one line, `Y` is not
on line N as written. For `undo4 ( m:Seq Int e:Int d:Int -- ... )` and

```
locals { m e } { e
  m e undo4 } ;
```

the hint says "write `m e e` in place of `e m e` on line 4", but line 4 has
only `e`, and `m e` is on line 5. The removal hint added in #254 avoids
this by naming the value alone when its text crosses a line.

The same collapsing misquotes text on one line with wider space, between
the values or inside a literal. For `g ( m:Seq Int i:Int -- v:Int )` and
`0 { 1  2 } g`, main 35c73c1 says "write `{ 1 2 } 0` in place of
`0 { 1 2 }` on line 2", and `0 { 1 2 }` is not in the source. The removal
hint names the value alone unless its text is the items with one space
between them.

## Acceptance criteria

- A reordering whose text crosses a line gets a hint that, applied
  literally to the source as written, makes the word check: either each
  line's text is named, or the edit is described without quoting the
  collapsed text.
- The same for text with wider space between the values or inside a
  literal: `Y` is quoted as written.
- A Lean case for each example above, with a plant of the current wording.
