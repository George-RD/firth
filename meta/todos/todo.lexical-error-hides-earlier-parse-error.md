---
node: firth.toolchain.elaborator
status: open
created: 2026-10-11
---

# Report a parse error that comes before a lexical error

The lexer runs over the whole file before the parser, so a lexical error
anywhere is reported ahead of a parse error earlier in the file.

```
: f ( -- Bool ) @ ;
```

is refused with `firth.syntax.invalid-token` at `@` (line 1, column 17),
not with `firth.syntax.unnamed-stack-item` at `Bool` (column 10). Main gives
the same report (`firthElaborate` built at ff6e72a; main at 60b3ad4 changes
nothing under `src/` since), and so does #250 at 3ab6015. #250 orders a name with `_` against parse
errors, but on this path a `_` name before the lexical error is reported in
its place, so `: f ( -- Bool ) a_b @ ;` reports `a_b` and still hides `Bool`
(CodeRabbit on #250).

Parsing the tokens read before the lexical error and comparing positions is
not enough by itself: the stack-effect sub-parser looks ahead for its `)`, so
a truncated token stream may produce a spurious error of its own (not checked).

## Acceptance criteria

- The first error in source order is reported, whether it is lexical or a
  parse error, checked on the program above and on the `a_b` variant.
- A truncated stack effect before the lexical error does not produce a
  report of its own (planted case).
