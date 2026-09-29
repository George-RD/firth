---
node: firth.toolchain.agent
status: done
created: 2026-09-29
---

# Say what is wrong when a body uses parentheses or ends early

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

The same message misled sample 5: its round-1 answers closed a branch
with `] if;` inside a `locals { ... } { ... }` block (27 times in 20
tasks, `haiku-firth-5/answer-2.md`), each reported as `Unexpected the end
of the input.` at the `;`. The `;` ends the definition early, but the
message does not say so, and Haiku's next answers dropped every helper
word, which left them no way to loop.

## Acceptance criteria

- A `(` inside a word body gets a diagnostic that names the parenthesis
  and says what to write instead (push the arguments in order; a
  quotation is `[ ... ]`), checked on the program above and on the 19
  run 8 answers.
- A `;` that ends a definition inside an open `{` or `[` gets a
  diagnostic that says the definition ended there, checked on sample 5's
  round-1 answers.
- The message no longer says the input ended where it did not.

## Resolution

The parser reports `firth.syntax.parenthesis-in-body` at a `(` or `)` in a
body, with a hint that says to push arguments in order, to quote code with
`[ ... ]`, and that a comment is `(* ... *)` or `\` (run 8 sample 2 used
`(copy of sum at top)` as a comment). Of sample 4's 20 first answers, 19
now get it first.

A `;` inside an open `[` or `locals` body reports
`firth.syntax.definition-ended-early`. Which hint it gets depends on the
text after the `;`:

- When the brackets after it close everything still open, in order,
  before any other `;`, the hint says to delete this `;` and names the
  line of the bracket that closes the outermost one. This is how 21 of the
  22 answers across `eval/s7/runs/` that get this error wrote it: `] if;`
  with `};` on the next line. Deleting the `;` takes all 21 past it: 16
  reach a type or name error, 4 reach another early `;` further down, and
  1 reaches `prim <=` (`firth.syntax.invalid-item`).
- When those brackets close everything but no `;` ends the word before
  the next declaration or the end of the input, the hint says to move this
  `;` to just after the closing bracket instead. No answer in the corpus
  has this shape; it is tested.
- Otherwise the hint says to close the open brackets first and names the
  next one to close. Only run 4's `is-sorted`
  (`2026-09-28-mvp/haiku-firth/answer-3.md`) gets this reading; closing the
  `]` there reaches a name error.

No syntax message says the input ended unless it did: over every answer in
`eval/s7/runs/`, messages saying so drop from 54 to 0. A `'` that touches
the name before it, as in `q'`, reports `firth.syntax.quote-in-name`
instead of the character-literal error, so a real overlong literal such as
`'ab'` keeps a hint about literals.
