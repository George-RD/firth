---
node: firth.toolchain.elaborator
status: open
created: 2026-10-11
---

# Report `_ρ` and `_π` as a name with `_`

The lexer keeps a name that starts with `_` whole only when a letter follows
the `_`s (`src/elaborator/Firth/Parser.lean`, the leading-underscore branch
of `lex`). The identifier branch also starts a name at `ρ` and `π`, so `_ρ`
and `_π` lex as the symbol `_` followed by a name. Checked with
`firth_run.py check` on #250 at 7c33928: a definition
`: _π ( -- n:Int ) 0 ;` gets `firth.syntax.expected-name` ("Unexpected `_`,
expected `name`.") at the `_`, and a use `: f ( -- n:Int ) _π ;` gets
`firth.syntax.invalid-item` at the `_`, where both should get
`firth.syntax.underscore-in-name` (CodeRabbit on #250).

No source in the corpus comparison of `dec.source-type-names` (every
`eval/s7` answer, the examples and the stdlib) or the docs writes either
name, so the case has not come up.

## Acceptance criteria

- A definition, an input and a use written `_ρ` or `_π` are refused with
  `firth.syntax.underscore-in-name` at the name, with the hint naming
  `ρ` or `π` only if that rename checks.
- The test carries planted cases: the `expected-name` and `invalid-item`
  reports above fail the check.
