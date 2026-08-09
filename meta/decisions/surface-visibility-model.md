---
id: dec.surface-visibility-model
nodes: [firth.language.surface]
status: accepted
date: 2026-08-09
informed_by:
  - res.firth-prd.summary
  - res.firth-kernel-spec.summary
---

# Surface visibility and vocabulary resolution

Autonomous author: loop/todo.scope-language-visibility-model

Firth v0.1 uses lexical vocabulary scopes over a canonical dictionary. The
outermost file has an empty canonical prefix. Vocabulary and word declarations
therefore produce stable qualified keys, while `use` declarations expose
exported words as unqualified candidates and `as` declarations expose a
qualified alias. All words are exported by default in v0.1, with no private
visibility modifier.

Resolution is syntax-directed and deterministic. Qualified references first
expand a leading alias to its canonical vocabulary prefix, then match canonical
keys exactly. Unqualified references combine current-vocabulary words
with the exported words made visible by active uses. Nested vocabularies inherit
the active uses at their declaration and add their own uses lexically. A `use`
target must resolve to exactly one vocabulary before imported candidates exist.
Candidate identity is the canonical key; equal-key ties use source ranges and
stable payload IDs. Alias bindings cannot collide with another alias or a
visible canonical vocabulary prefix. Candidate and diagnostic ordering is
therefore lexical rather than discovery-order dependent. Duplicate canonical
names, duplicate aliases, ambiguous unqualified references, and unresolved
references have stable `firth.name.*` diagnostics with related source spans
where applicable.

Implementations collect vocabulary declarations and word signatures before
checking bodies. Definitions are therefore visible throughout their vocabulary,
including forward references and mutually recursive dictionary words. Names,
uses, aliases, and export metadata erase before kernel construction. Runtime
behaviour remains solely the canonical dictionary key and the erased word
contract and body.
