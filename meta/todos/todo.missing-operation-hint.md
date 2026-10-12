---
node: firth.toolchain.agent
status: open
created: 2026-10-11
---

# Say when a call gets a value an operation should have combined

Found in the scored S7 run of 2026-10-11 (sonnet-firth-9's checkers, round
1, `eval/s7/harder/runs/2026-10-11-scored/sonnet-firth-9/solutions-1.json`).
`ac` writes `m 40 cnt 1 prim - gt` where it means `m 40 cnt 1 prim - prim +
gt`: an operation is missing, so `gt ( m:Seq Int i:Int -- v:Int )` gets one
value too many. The report says only that `40` "is not what `gt` takes
there (Seq Int)" and suggests `swap`.

The one-value-too-many edit (`extraValueEdit` in
`src/elaborator/Firth/Pipeline.lean`) names a removal only when exactly one
removal lets the word check. Here three do (`40`, `cnt` or `1`), and none is
what the author meant, so it rightly names none. Searching for the missing
operation is open-ended: any operation from two Ints to one would do.

## Acceptance criteria

- The report for `ac` above says the count is off by one before `gt`, and
  names no single removal as the fix.
- If it suggests an operation, the suggestion applied literally makes `ac`
  check, and a planted case where two operations fit gets no named one.
