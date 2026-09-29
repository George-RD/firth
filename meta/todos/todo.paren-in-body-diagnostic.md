---
node: firth.toolchain.agent
status: open
created: 2026-09-29
---

# Say what is wrong when a body uses parentheses

Found by S7 run 8 (`eval/s7/README.md`, "Run 8"). Sample 4's first answers
grouped arguments in parentheses, as in `xs (idx 1 prim +) sum-loop`, in 19
of 20 tasks (`eval/s7/runs/2026-09-29-haiku-4c379e0/haiku-firth-4/answer-1.md`).
The parser reports each one as

```
code: firth.syntax.invalid-item
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
```

at the `(`. The input does not end there, and neither the message nor the
hint says that parentheses only delimit a stack effect. Reproduce with

```
: main (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  locals { n } { (n 1 prim +) };
```

which `tools/loop/firth_run.py check` refuses the same way at line 2,
column 18.

## Acceptance criteria

- A `(` inside a word body gets a diagnostic that names the parenthesis
  and says what to write instead (push the arguments in order; a
  quotation is `[ ... ]`), checked on the program above and on the 19
  run 8 answers.
- The message no longer says the input ended where it did not.
