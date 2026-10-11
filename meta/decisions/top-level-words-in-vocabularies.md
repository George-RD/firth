---
id: dec.top-level-words-in-vocabularies
nodes: [firth.language.surface, firth.toolchain.elaborator]
status: accepted
related: [dec.surface-visibility-model, dec.multi-file-imports]
date: 2026-10-10
---
# Top-level words are visible inside vocabularies

## Context

A word declared outside any vocabulary has a canonical key with no dot
(`top`). An unqualified reference inside `vocab v { ... }` considered only
`v.top` and the words of active `use` declarations, and a qualified
reference must name a key with a vocabulary prefix. So no spelling inside a
vocabulary reached `top`, from the same file or from an import that exports
it, and programs moved such words into a vocabulary to call them
(`todo.top-level-word-from-vocabulary`, found by Codex on PR #225).

## Decision

Inside a vocabulary, an unqualified reference also considers the top-level
key of the same name. It is one more candidate under the existing rule, not
a fallback: the reference must still match exactly one candidate, so when the
current vocabulary or an active `use` also defines the name, the reference is
`firth.name.ambiguous-use` and the author writes the qualified name
(`v.top`). Nothing shadows anything. A top-level word of an imported file is
a candidate only when that file exports it, as everywhere else; an unexported
one is still `firth.name.not-exported`. Words of other vocabularies are
unchanged: they still need a qualified name or a `use`.

This widens what resolves. Every program accepted before still resolves to
the same keys, except one that defines or imports a top-level `top` and refers to `top`
unqualified inside a vocabulary `v` where it already resolved to another
word: to `v.top`, or to `u.top` through an active `use u`. That reference is
now ambiguous. That is the same trade `use` already makes when a used vocabulary
gains a word.

## Rejected options

- A root qualifier, such as `.top` or `root.top`: explicit and never
  ambiguous, but it adds syntax and a reserved token for models to learn, for
  a reference the existing candidate rule already handles.
- Keeping the restriction: every program that shares a helper between
  vocabularies has to move it into a vocabulary of its own, and the guide has
  to teach an exception to the visibility rule.
- Letting the vocabulary's own word shadow the top-level one: no new
  ambiguity, but the same text would silently mean a different word once a
  vocabulary gains a name, which the canonical-key model avoids everywhere
  else.

## Status

Accepted on 2026-10-10 by the project coordinator under the maintainer's
delegation ("you decide; hard now, easy later"). It widens what resolves and
changes no acceptance criterion and no kernel rule; it amends section 2 of
`spec/surface/syntax.md`.
