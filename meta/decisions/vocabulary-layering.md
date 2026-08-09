---
id: dec.vocabulary-layering
nodes:
  - firth.language.surface
status: accepted
date: 2026-08-09
informed_by:
  - res.firth-prd.summary
  - res.firth-kernel-spec.summary
---
# Vocabulary Layering

## Context
Autonomous author: loop/todo.scope-language-vocabulary-layering

The PRD requires core, domain, and application vocabulary layers, while the
surface specification currently defines lexical vocabularies without defining
the layer contract or promotion boundary. The frozen kernel already fixes
dictionary entries to erased `(WordType, Program)` pairs, and the elaborator
owns refinements and public specifications. Layering must therefore organise
words without creating a second semantic system.

## Decision

Define a vocabulary layer as a finite named dictionary `D_L` of words with a
public contract map `C_L`, where each `C_L(w)` contains the erased `WordType`
and any checked specification for `w`. Core vocabularies may depend only on
core vocabularies, the frozen kernel, and declared portable primitives. Domain
vocabularies may depend only on core and lower domain layers. Application
vocabularies may depend only on core and domain layers. Every dependency is
explicit and acyclic.

## Rationale

The dictionary and contract pair matches the kernel and elaborator boundary,
so each word remains independently checkable and replaceable. Explicit,
acyclic dependencies make portability and curation machine-checkable.
Treating layers as semantic extensions would contradict the kernel freeze;
using labels without contracts would not support portable user dictionaries.

## Consequences

The surface and elaborator tooling must preserve layer metadata, validate every
word against its declared contract, and reject undeclared or cyclic
dependencies. Users may publish new dictionaries by supplying their words,
contracts, and dependency closure. A standard layer may be curated only when
all its words and dependencies pass the same checks and use no undeclared
target-specific primitive. Portable curation records content-addressed
primitive and Γ profile identifiers; changing a provider contract, target
profile, or dependency invalidates the curation and requires rechecking. All
layers erase to the same frozen kernel dictionary and operational semantics.
