---
node: firth.toolchain.elaborator
status: done
created: 2026-10-10
---

# Let a vocabulary refer to a word declared outside any vocabulary

## Goal

A word declared outside any vocabulary has a canonical key with no dot
(`top`), and `resolveWord` (`src/elaborator/Firth/Names.lean`) reads every
undotted reference inside `vocab v` as `v.top` or a `use`d vocabulary's word.
So no spelling inside a vocabulary reaches `top`: the reference is
`firth.name.unresolved`. The same holds for an imported word exported from
outside any vocabulary. Programs work around it by moving the word into a
vocabulary.

## Acceptance criteria

- A decision chooses the spelling (for example a root qualifier) or records
  why the restriction stays, and `spec/surface/syntax.md` section 2 says so.
- If a spelling is added, `FirthNamesTest.lean` covers it inside a vocabulary,
  for a word of the same file and for an imported one, with a known-bad case
  that stays refused.

## Traceability

Codex on PR #225 (`docs/firth-agent-guide.md`), where the guide now states the
restriction. Reproduced on the PR head with
`firth_run.py check` on `: top ( -- ) ; vocab v { : w ( -- ) top ; }`:
`firth.name.unresolved` for `top` in `v.w`.

## Resolution

`dec.top-level-words-in-vocabularies` makes the top-level key one more
unqualified candidate inside a vocabulary, under the existing
exactly-one-candidate rule, and section 2 of `spec/surface/syntax.md` says
so. `FirthNamesTest.lean` covers a same-file reference (declared before and
after the vocabulary), the ambiguity beside the vocabulary's own word and
beside a `use`d word, the qualified spelling that still resolves, and the
known-bad references that stay refused (a sibling vocabulary's word, a name
defined nowhere). `FirthImportsTest.lean` covers an imported top-level word,
an unexported one (`firth.name.not-exported`) and the ambiguity beside a
vocabulary word. Removing the new candidate, or letting the vocabulary's own
word shadow it, fails these tests.
