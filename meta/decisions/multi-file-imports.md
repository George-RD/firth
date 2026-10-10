---
id: dec.multi-file-imports
nodes: [firth.language.surface, firth.toolchain.elaborator, firth.toolchain.compiler, firth.ecosystem.stdlib]
status: accepted
related: [dec.surface-visibility-model, dec.core-stdlib-vocabulary, dec.agent-development-rules]
date: 2026-10-10
---
# Multi-file programs: `import` and `export`

## Context

A Firth program was one file. `examples/inventory/policy_change.py` worked
around that by concatenating `allocator.firth` in front of each client's
source, which rule 6 forbids, and a standard library word could not be used
by another file at all. `todo.language-12` asks for "reusable multi-file
vocabularies with deterministic imports, explicit exports and stable errors",
and `todo.language-13` (the M1 inventory milestone) depends on it. The other
half of language-12, typed records and results, is a separate change.

`dec.surface-visibility-model` already gives one file a canonical dictionary:
the file is an implicit vocabulary with an empty prefix, `vocab v { ... }`
gives its words keys `v.w`, and `use v [as a];` makes them visible
unqualified. Names erase before kernel construction. This decision extends
that model across files. It does not change the kernel, the kernel
specification or any acceptance criterion; it extends section 2 of
`spec/surface/syntax.md`.

## Decision

### Syntax

    file              = { import-declaration } ,
                        { vocabulary | use-declaration | export-declaration | word-definition } ;
    import-declaration = "import" , string , ";" ;
    export-declaration = "export" , name , { name } , ";" ;

`import "../allocator.firth";` names another source file by a path relative
to the importing file's directory. Every import comes before the file's other
declarations, and neither `import` nor `export` may appear inside a
vocabulary (`firth.syntax.misplaced-import`, `firth.syntax.misplaced-export`).
`import` becomes a reserved word, as `export` already was.

`export allocate-batch core.identity;` lists words this file offers to the
files that import it, by canonical key. A file may have several `export`
declarations. Each name must be a word this file defines
(`firth.name.unresolved` otherwise) and may be listed once
(`firth.name.duplicate-export`). Exports matter only to importers: inside its
own file every word stays visible exactly as before, so a file with no
`export` is still a complete program, and one imported for nothing is not an
error.

### Paths

An import path is `/`-separated segments of ASCII letters, digits, `.`, `_`
and `-`, ending in `.firth`. `.` segments are dropped and `..` goes up one
directory. The path is resolved against the importing file's path to a
normalised path relative to the source root, the directory of the root file
unless the caller names another. A path that is absolute, has an empty
segment, contains any other character, does not end in `.firth`, or climbs
above the source root is refused (`firth.name.import-path`). Two imports of
one normalised path in one file are refused (`firth.name.duplicate-import`).

### Load order and cycles

The program is the root file and every file it imports, transitively. Each
file is loaded once, whatever the number of paths to it (a diamond is one
file). The load order is the post-order of a depth-first walk from the root
that follows each file's imports in the order they are written: a file comes
after everything it imports, and the root comes last. Nothing depends on
directory listing, hashing or the order files are supplied in.

An import that reaches a file still being loaded is a cycle, refused at that
import as `firth.name.import-cycle`, whose message lists the files around the
cycle. Allowing cycles later is a relaxation that no accepted program can
notice, so refusing them now costs nothing later.

### Names and collisions

A word's canonical key is the key it has in its own file. Importing does not
prefix it: `allocate-batch` in `allocator.firth` is `allocate-batch` in every
program that imports it, and `core.identity` stays `core.identity`. The whole
program is one dictionary, so two files that define the same key cannot be in
one program, even when neither exports it: `firth.name.duplicate-canonical`
names both files. When one of them is the importing file the error is at its
word; when both are imported, it is at the second import that brings the key
in. A library avoids collisions by putting its words in a vocabulary, as
`stdlib/core.firth` does.

An importing file sees the exported words of the files it imports directly,
and nothing else from them. They join its own words as resolution candidates,
under the existing rules: a qualified reference names a key exactly, and an
unqualified reference considers the current vocabulary and active `use`
declarations. A `use` may name a vocabulary of a directly imported file that
exports at least one word. A reference to a word an imported file defines but
does not export is `firth.name.not-exported`, which names the file. Imports are
not transitive: to use a word of a file that an imported file imports, import
that file too.

### Checking

Each file is checked once, alone, by the existing pipeline, in load order. A
file is checked against the declared stack effects of the words it imports,
exactly as a word is checked against the declared effects of the words it
calls; those words were themselves checked against those effects when their
own file was. Diagnostics for a file carry that file's path, and its spans
are positions in that file. When a file is refused, each file that imports it
is not checked and gets `firth.name.import-failed` at the import, so a failure
is reported once, in the file that has it, and no importer is taken for a
checked file. Files that do not depend on the refused one are still checked
and reported.

The elaborator never reads the file system. The elaborate request carries the
root file as before (`source_path`, `source_text`) and every imported file in
an optional `files` array of `{source_path, source_text}`, with paths
normalised relative to the source root. An import whose path is not in
`files` is `firth.name.import-not-found`. Files the program does not import
are ignored. A small loader, `lake exe firthSources`, reads the root file and
its imports from disk under a source root, refusing any path that leaves it,
including through a symbolic link, and returns exactly that request part. The
Python tools (`firth_run.py`, `mvp_agent_gate.py`) call it before
elaborating.

### Reference interpreter, compiler and VM

The checked program is every file's checked words in load order, so the
elaborate response's `checked_words` is the whole dictionary. A new
`sources` member lists, in load order, each file's path, the SHA-256 of its
text, and the words it defines. The reference interpreter receives that
dictionary as before and needs no change.

The compile request's `source` envelope takes the same optional `files`
array, and source binding re-elaborates the whole set, so every word of every
file is bound to bytes that were checked. `verification.source_sha256` stays
the digest of the root file's text, and a new
`verification.imported_sha256` lists each imported file's path and digest in
load order. Each debug location names the file its word came from.

Target names are still the compiler's mangling of canonical keys, so imports
add nothing to image naming, and the image is one flat dictionary: the VM
sees no difference between a word written in the root file and one imported.
Because neither the key nor the body of an imported word depends on who
imports it, its body digest is the same in every program that contains it.
A Lean proof record bound to that digest (`src/proofs/records.json`) therefore
covers the word in an importing program's image unchanged; a record covers
words by digest, never by file. `firthExportLean` exports a source with
imports as the whole dictionary the reference runner builds for it, loading
imports with the same loader; `sourceDigest` stays the root text's digest and
an export with imports also lists each imported file's digest.

## Rejected alternatives

- **Textual inclusion** (what `policy_change.py` did): diagnostics lose the
  file they belong to, nothing is private, and a file cannot be checked once
  and reused. It is the workaround rule 6 names.
- **File-qualified keys** (prefixing every imported word with its file or
  module): it would remove collisions between private helpers, but a word's
  key, and with it every caller's body digest, would depend on how the word
  was reached and on the file's name. A proof record about `allocator.firth`
  would not carry to a program importing it, and renaming a file would change
  every digest. Keeping keys file-independent costs a collision error when two
  files reuse a top-level name, which a vocabulary avoids.
- **An elaborator that reads files itself:** the adapters would stop being
  functions of their request, and the compiler's source binding needs the
  exact bytes in the request anyway.
- **Transitive visibility:** what a file can name would change when an
  imported file changed its own imports.

## Consequences

`policy_change.py` builds each client from its own file, which imports
`allocator.firth`, and checks that every allocator word keeps the digest it
has when `allocator.firth` is compiled alone. `stdlib/core.firth` lists its
exports. The agent guide, `getting-started.md` and the surface specification
describe imports. A package registry, versioned dependencies and import
search paths stay out of scope (`todo.language-12`).
