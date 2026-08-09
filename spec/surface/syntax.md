# Firth Surface Syntax

## Status and scope

This is the normative v0.1 surface syntax specification. It defines the concrete
source language and its elaboration to the frozen kernel in
`files/firth-kernel-spec-draft.md`. Surface syntax has no independent runtime
semantics. After name resolution, macro expansion, and checking, every body is
a kernel `Program` made only from `lit c`, quotation literals, the atoms
`dup`, `drop`, `swap`, `dip`, `call`, `compose`, `quote`, `if`, a
dictionary word `w`, or `prim π`.

The specification covers source files, vocabularies, words, literals,
quotations, stack-effect contracts, comments, and named-local sugar intended
for machine authorship.

## 1. Lexical conventions

Source is Unicode text, but canonical v0.1 identifiers are ASCII. Whitespace is
spaces, tabs, or newlines and separates tokens where needed. Identifiers are
case-sensitive.

    letter       = "a" … "z" | "A" … "Z" ;
    digit        = "0" … "9" ;
    word-name    = letter , { letter | digit | "-" | "?" | "!" } ;
    name         = word-name , { "." , word-name } ;
    row-name     = "ρ" , { letter | digit | "-" } ;
    type-name    = name ;
    integer      = [ "-" ] , digit , { digit } ;
    character    = "'" , printable-character , "'" ;
    string       = '"' , { string-character | escape } , '"' ;
    escape       = "\\" , ( "\\" | '"' | "n" | "r" | "t" ) ;

Implementations may accept Unicode aliases in tooling, but canonical source uses
the grammar above. `true` and `false` are reserved Boolean literals;
`many`, `linear`, `forall`, `vocab`, `use`, `export`, `locals`,
`prim`, and kernel atom names are reserved in their syntactic positions. A
word name may not be a keyword or kernel atom.

An integer, character, string, or Boolean token elaborates to `lit c`, with
its type looked up in Γ. Literals must have a `many` base type. A declaration
or primitive that would give a literal a linear type is rejected; nested
literals inside quotations are checked recursively. A linear resource can enter
a program only from an input, dictionary word, or primitive result, never from
a replayable literal.

Comments are erased before parsing. A line comment begins with `\` and ends
at the newline. A block comment begins with `(*` and ends with the first
`*)`; block comments do not nest. Comment delimiters inside strings and
characters are ordinary characters. Unterminated comments and strings are
errors.

## 2. Source files and vocabularies

    file            = { vocabulary | use-declaration | word-definition } ;
    vocabulary      = "vocab" , word-name , "{" ,
                      { vocabulary | use-declaration | word-definition } , "}" ;
    use-declaration = "use" , name , [ "as" , word-name ] , ";" ;
    word-definition = ":" , word-name , stack-effect , body , ";" ;
    body            = { item } ;
    item            = literal | quotation | kernel-atom | primitive | name
                    | local-block ;
    quotation       = "[" , { item } , "]" ;
    primitive        = "prim" , name ;
    local-block     = "locals" , "{" , word-name , { word-name } , "}" ,
                      "{" , { item } , "}" ;

The outermost file is an implicit vocabulary with an empty canonical prefix.
A top-level word named `w` therefore has canonical dictionary key `w`. A
vocabulary named `v` in a scope with canonical prefix `p` has canonical name
`p.v` (or `v` at the top level), and a word named `w` in it has canonical key
`p.v.w` (or `v.w` at the top level).

Each file and vocabulary body is a lexical scope. A nested vocabulary inherits
the active `use` declarations from enclosing scopes at its declaration, and
its own `use` declarations remain active through the end of its body. A `use`
declaration names a vocabulary and its target must resolve to exactly one
declared vocabulary. A missing, non-vocabulary, or ambiguous target is rejected
at the declaration before any imported candidate is considered. Resolved
exported words become unqualified lookup candidates from the declaration
through the end of its containing scope. `as` binds an alias for that
vocabulary, so `alias.w` is qualified lookup for the canonical word `v.w`. An
alias cannot equal another alias or a visible canonical vocabulary prefix in the
same scope; either collision is a duplicate-alias error. A word is exported by
default from its defining vocabulary; private words and user-selectable export
modifiers are outside v0.1. A word defined in the current vocabulary is
directly available there without a `use`.

Name resolution constructs its candidate set before checking a body. Qualified
lookup first expands a leading alias to its canonical vocabulary prefix, then
the resulting canonical reference must match exactly one canonical dictionary
key and is never shadowed. An unqualified reference considers the current
vocabulary and the exported words made visible by its active `use` declarations.
Candidates are compared by canonical key, not declaration or import order. A
duplicate canonical name, duplicate alias binding, ambiguous unqualified
candidate set, or empty candidate set is rejected with the stable diagnostics
below.

| Code | Condition |
| --- | --- |
| `firth.name.duplicate-canonical` | two declarations produce one canonical key |
| `firth.name.duplicate-alias` | an alias repeats or collides with a visible canonical vocabulary prefix |
| `firth.name.ambiguous-use` | an unqualified reference has multiple candidates |
| `firth.name.unresolved` | a use target or qualified or unqualified reference has no candidate |

Name diagnostics identify the declaration or reference span that caused the
failure and include related spans for every colliding declaration or candidate.
When several diagnostics exist, order them by the established diagnostic
envelope key: source URI or path, primary range start, primary range end, stable
code, then payload ID. Candidate lists and related spans are sorted by canonical
key, then source range start and end, then payload ID. Resolution therefore has
no implementation-defined choice and does not depend on hash-map iteration.

Vocabulary declarations, `use`, aliases, and export status erase completely.
The dictionary key is the canonical qualified name, and the dictionary value is
the word's erased prenex stack effect and elaborated kernel body. Vocabularies
organise names but introduce no runtime operations.

Implementations collect vocabulary declarations and all word signatures before
checking bodies. Definitions are visible throughout their vocabulary, including
before their textual definition, so mutually recursive dictionary words are
possible. A body is checked against its declared effect while all declared
signatures are in the dictionary. A public contract may retain refinements, but
the kernel dictionary stores only the erased `WordType`.

## 2.1 Vocabulary layers

A vocabulary layer is a finite dictionary `D_L` together with a public
contract map `C_L`. For every word `w`, `D_L(w)` is an erased
`(WordType, Program)` entry and `C_L(w) = C(w)`, the established public
contract `(WordType, Spec)`, including checked predicates and any other `Spec`
fields.
A layer manifest
`M_L = (package_id, role, dependencies, primitives, gamma_profile,
primitive_profile, content_profile, dependency_profile)` records the canonical
package identity, role, vocabulary dependencies, exact primitive closure,
target-independent Γ and primitive semantic profiles, a content hash over the
package's words and `C(w)` contracts, and a content hash over the resolved
dependency manifests and contract/profile closure. The closure is derived from
its words and dependencies.
The primitive and Γ closures are graph-wide over every word in the declared
dependency closure, not only references reached from one body; the visited set
deduplicates that finite graph.
`gamma_profile`, `primitive_profile`, `content_profile`, and
`dependency_profile` are content-addressed identifiers for canonical profile
records. A supported target or package provider publishes the records and
identifiers; curation stores all identifiers rather than an unbound claim.
Canonical profile serialization is deterministic and its identifier is the
SHA-256 digest of that serialization; profile equality is identifier equality
after canonicalization.

Primitive profile records include each primitive's deterministic, total `δπ` on
its typed shape, ownership contract, and observable behaviour; effectful
primitives without a shared observation profile are not portable.

The `primitive_profile` keys must equal the derived primitive closure, and the
`gamma_profile` keys must equal the required Γ entries; missing or extra keys
are rejected before portability is assessed.
`gamma_profile` covers non-primitive Γ entries, including base types and
literals; primitive signatures and semantics belong to `primitive_profile`.

Each manifest is attached to exactly one canonical vocabulary package, and `D_L`
contains the words declared by that package. Every nested vocabulary has its
own canonical package identity and manifest, whether or not it is imported.
`D_L` is local to its package. Checking uses the linked union of `D_L` and
dependency dictionaries, while imported entries remain owned by their provider
and are not duplicated into the importing layer.
Linking rejects duplicate canonical keys with
`firth.name.duplicate-canonical` before body checking; a package URI identifies
ownership and does not create a second canonical namespace.

The outer implicit vocabulary uses its source file or package URI as its
canonical package identity in the manifest.
Manifest dependency names use canonical vocabulary names for nested packages
and package URIs for outer file packages; resolution normalises both forms
before matching dependencies.
The package registry binds each outer package URI to a canonical vocabulary
name before source resolution; `use` and `as` therefore expose URI-backed
packages through ordinary `name` and alias syntax.
The loader registers manifest dependencies in the declared-vocabulary
environment before resolving `use`; a registry-backed package therefore counts
as a declared vocabulary for the existing resolution rule.

For an outer package alias `p`, `p.w` resolves to that package's empty-prefix
key `w`; the alias identifies ownership without changing the stored key.
Every inherited `use` declaration contributes a direct dependency to each nested
package in its lexical scope; the nested manifest must list that dependency even
when no body or contract reference is resolved through it.

The manifest is package metadata, not new source syntax in v0.1; `vocab` and
`use` continue to declare words and lexical imports. Manifest direct
dependencies must match each imported vocabulary target and must form an
acyclic graph; their manifests determine the transitive dependency closure.
Resolved cross-vocabulary qualified references also contribute direct
dependencies; a manifest mismatch is rejected even when no `use` declaration is
present.

For an imported word, `C_L(w)` is the provider's `C(w)` and cannot be
overridden by the importing layer. Each imported word is checked and used
through its declared `C_L` contract; refinement obligations cannot be bypassed by crossing
a layer boundary.

The standard roles are:
1. **Core vocabularies** provide foundational reusable words over the frozen
   kernel atoms, literals, and the declared portable primitive set. They may
   depend only on core vocabularies and must not depend on domain or application
   vocabularies.
2. **Domain vocabularies** provide reusable words for a problem area. They may
   depend only on core vocabularies and lower domain layers, and must not depend
   on application vocabularies.
3. **Application vocabularies** provide words for one application or
   deployment. They may depend only on core and domain vocabularies, and must
   not depend on application vocabularies. They are not required to be reusable
   by a standard layer.
“Lower” means a domain dependency that precedes the dependent package in the
acyclic manifest graph; no separate numeric rank is required.

These roles describe dependency and curation boundaries, not new runtime
categories. Every layer introduces dictionary words only. Name resolution,
contract checking, refinement discharge, and erasure produce the same frozen
kernel dictionary entries and `Program` terms as an unlayered vocabulary.
Layer metadata, imports, and curation status erase completely.

Users extend Firth by declaring a vocabulary, supplying each word body and
boundary contract, and supplying its layer manifest. The elaborator derives
the primitive set from every word body and its dependency closure, and rejects
a manifest whose `primitives` entry does not exactly match that derived set.
Primitive derivation traverses canonical word references with a visited set and
uses the finite least closure, so mutually recursive words do not loop or
duplicate dependencies.
Contract predicate references and the required Γ literal and base-type entries
are included in the same dependency closure. A portable package records a
target-independent Γ profile for those entries, and every supported target must
provide that profile.

It then checks the manifest, dependency closure, word contracts, refinements,
and kernel erasure; an extension cannot add atoms, primitives, or runtime
operations.
An accepted contract also retains the existing proof or evidence that its
`Spec` predicates describe the defining elaborated body; unsupported predicate
or primitive fragments cannot be curated as portable contracts.
The elaborator rejects role-invalid edges and any unchecked or failed word
contract, refinement, or kernel-erasure result before a layer is accepted.
For `role=core`, the primitive closure and Γ profile must already satisfy the
portable target profiles; a core layer with any nonportable entry is rejected.

The declared portable primitive set contains only primitives with a checked,
target-independent semantic contract, including stack typing and deterministic
transitions and observable effects, shared by every supported target. The
toolchain declares this portable set and its supported targets as configuration.
A primitive belongs to the set only when every supported target
provides that same semantic contract; standard-layer curation records the
portable-set configuration with the accepted vocabulary contracts. A vocabulary
is portable only when all word contracts, refinements, kernel erasure, and its
dependency closure are accepted, its `gamma_profile` and `primitive_profile`
match every supported target, and its derived primitive set is a subset of that
declared set. The standard library curates
core and domain layers only from accepted, portable vocabulary contracts;
application layers remain user-owned unless separately accepted.
Changing a word body, its `C(w)`, an imported provider body or contract,
dependency manifests, any semantic or content profile, or the supported-target
configuration invalidates the accepted contract and requires rechecking before
curation or publication.

## 3. Stack effects

The chosen v0.1 annotation is a parenthesised effect at the word boundary:

    stack-effect     = "(" , [ "forall" , row-name , { row-name } , ";" ] ,
                       stack-items , "--" , stack-items , ")" ;
    stack-items      = [ stack-item , { stack-item } ] ;
    stack-item       = row-name | ( word-name , ":" , type-expression ) ;
    type-expression  = type-name , [ "^" , ( "many" | "linear" ) ] ,
                       [ "{" , predicate , { "," , predicate } , "}" ] ;

Every row variable must be explicitly bound by the prenex `forall` clause. A
row variable is written as a stack item by itself, for example
`(forall ρ; ρ -- ρ x:Int^many)`. The semicolon terminates the prenex binder;
row variables are bound there and nowhere inside a type. A signature with no
row variables may omit `forall`. Named value entries are
documentation and refinement anchors; their order is bottom to top. `--`
separates input and output rows. `^many` is the default and may be written
explicitly; `^linear` is mandatory for a linear value.

Refinements are predicates in braces, such as `n:Int^many{positive n}`.
They are elaborator obligations and contract metadata, not kernel types or
dictionary fields. Predicate names resolve like words, but a refinement never
adds a runtime stack item. Refinement syntax is restricted to word boundaries in
v0.1, avoiding hidden binders and preserving local reasoning.

An annotation fork was considered. A Forth-style `: name ( in -- out )` form
is preferred over a trailing `name : effect` form because the effect is
adjacent to the definition boundary, easy to scan in a long dictionary, and
matches the frozen Σ₁ → Σ₂ direction. The trailing form is not accepted in
v0.1. The elaborated kernel type is exactly `∀ρ⃗. Σ₁ → Σ₂`, with usage
annotations retained for checking.

## 4. Bodies, sequencing, and quotations

Items execute left to right. Concatenating two bodies concatenates their kernel
programs. There is no implicit application, precedence rule, or hidden stack
manipulation. A bare word name resolves to `w`; `prim p` resolves to
`prim π`; a kernel atom resolves to the atom of the same name.

Quotation brackets are first-class quotation literals. The body between `[` and
`]` is elaborated independently as a program with an inferred effect, then
the whole quotation elaborates to kernel `[p]` and pushes `⟦p⟧`. Its usage
follows the frozen recursive rule: a closed quotation is `many`; capturing a
linear value is `linear`. `call`, `dip`, `compose`, `quote`, and `if`
are ordinary kernel atoms with exactly the frozen typing and stepping rules.
There is no literal syntax for a quotation value other than brackets. `[` is
not a list and does not introduce a new data type.

## 5. Named-local sugar

`locals {a b c} { body }` is an elaborator macro. It takes the top three input
values, naming them in declaration order from bottom to top, and elaborates
each name occurrence in `body` as a demand for that value. It creates no
variable or environment in the kernel.

### 5.1 Complete erasure algorithm

The eraser maintains a symbolic stack `S`, bottom to top. Each entry is a
unique slot identity with its usage and type, for example
`[a:Handle^linear, b:Bytes^linear]`. It also maintains the remaining sequence
of body items and the number of future demands for each slot. A local name is a
slot demand, not a kernel atom.

For a demand of slot `x`, canonical `focus(x,S)` is defined recursively. It is
empty when `x` is top; it is `swap` when `x` is immediately below top; and when
the top is a protected value `v` above `x`, it emits `[focus(x,S_without_v)] dip
swap`. The recursive quotation is constructed first, then pushed above `v`;
`dip` runs the recursive focus below `v`, and the final `swap` moves the focused
slot above `v`. No additional `swap` is emitted before this recursive quotation.
For example, focusing the bottom of `[a,b,c]` emits
`[swap] dip swap`, which is a sequence of valid kernel steps and
leaves `[b,c,a]`. Focus never copies or discards a value.

A local name is a select operation that places its slot on top for the next
ordinary item. If a slot has `d` total selects, the first select emits
`focus(x,S)` followed by exactly `d - 1` `dup` atoms, provided `x` is `many`.
The original and each resulting copy receive distinct identities in production
order. Every select always uses the most recently produced identity that remains
available in `S`, including the first select; consequently, the original
identity is selected last. This agrees with `dup` leaving its newly produced
copy on top. A selected identity is marked used and removed from the available
set immediately, so consecutive demands select distinct identities. A used
identity never becomes available again; an ordinary word or primitive may
consume it or leave it on `S` according to its declared stack effect. For
`d = 1` no `dup` is emitted. A linear slot must have exactly one select and is
never passed to `dup`. Ordinary words and primitives then apply their declared
stack effects to `S`, consuming and producing fresh slot identities as
appropriate. The kernel type checker validates every transition.

At the end of the block, cleanup repeatedly chooses the unused declared-local
slot identity nearest the top of the current stack (breaking any tie by the
stable bottom-to-top slot order), emits `focus(x,S)`, and then emits `drop`.
Fresh identities produced by ordinary items and identities marked used by a
select are not cleanup candidates. The stack state is updated after each
removal. A linear slot with no select, or any slot that would need to be
silently discarded, is an error.

This is a total algorithm: the finite body is scanned once, each focus emits a
finite number of adjacent swaps, each usage count is finite, and the
most-recently-produced remaining copy rule gives exactly one identity to every
demand. It fails with a diagnostic if a name is absent, a required focus is not
represented by the current typed stack, or a linear usage count is not exactly
one. The canonical output is therefore unique and contains only kernel atoms,
dictionary words, primitives, and recursively constructed quotation literals.

The frozen `dip` atom is never emitted bare. Its only legal expansion is
`[q] dip`: first recursively erase `q` to a complete kernel program, construct
the quotation literal `[q]`, push it above the protected top value, then emit
`dip`. Its state transition is:

    (S · v, [q] dip)  ->  (S' · v)  when  q : S -> S'

The quotation is therefore an explicit operand, exactly as required by the
kernel rule. The recursive focus definition and the finite body scan make the
expansion total, with no search or implementation-defined choice.

The expansion is checked normally, so locals cannot bypass stack, usage, or
refinement checking.

The same algorithm is applied recursively to every nested quotation or local
block. Each body is erased against its own typed symbolic stack, and each local
declaration creates a fresh identity family scoped to that body; no local copy
identity is selected across a quotation boundary. The completed unique kernel
expansion of a nested body is then used as the body of its enclosing quotation
or local expansion.

The linter reports `LOCAL_DEPTH` when a local block declares more than four
names and `STACK_JUGGLE` when its expansion contains more than four
consecutive structural atoms (`dup`, `drop`, `swap`, `dip`). These are
warnings, not typing rules. Splitting the word is recommended.

## 6. Worked elaborations

Assume Γ contains `Int^many`, `Bool^many`, and `prim +` with effect
`Int^many Int^many → Int^many`:

    : inc ( forall ρ; ρ n:Int^many -- ρ n:Int^many ) 1 prim + ;

Its body is exactly:

    lit 1 ; prim +

A word reference `arith.inc` elaborates to the single atom `arith.inc`, not
to an inline copy. For quotation and conditional syntax:

    : choose-inc ( forall ρ; ρ n:Int^many b:Bool^many -- ρ n:Int^many )
      [ 1 prim + ] [ ] if ;

The body is:

    [ lit 1 ; prim + ] ; [ ] ; if

The branches both have effect ρ n:Int^many → ρ n:Int^many after elaboration.
The frozen `if` rule therefore accepts the example. Unequal branch effects are
always rejected; surface syntax cannot weaken that rule.

For a local permutation:

    : add-top-two ( forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many )
      locals { a b } { a b prim + } ;

The canonical expansion is `swap swap prim +`: the first select focuses `a`,
the second focuses `b`, and `prim +` then consumes the top two values.

Assume linear `Handle^linear`, linear `Bytes^linear`, and `prim send` with
effect `Handle^linear Bytes^linear →`:

    : send-once ( forall ρ; ρ h:Handle^linear b:Bytes^linear -- ρ )
      locals { h b } { h b prim send } ;

Its local expansion is `swap swap prim send` when `send` expects `h` below `b`;
each linear value occurs exactly once.
Writing `1`, or any literal with a linear type, is rejected before expansion.

## 7. Machine-authorship requirements

The grammar and elaborator shall enforce:

1. **Unambiguous and deterministic.** Tokenisation uses longest match for
   qualified names and escapes. Delimiters are explicit; lookup reports every
   collision; parsing and local expansion have no implementation-defined choices.
2. **Word-level granularity.** Every definition has one name, one boundary
   contract, and one independently checkable body. Replacing a word changes a
   dictionary entry, not hidden global state.
3. **Concatenative composition.** A sequence is meaningful by concatenation.
   Higher-order behaviour is visibly expressed by quotations and kernel atoms.
4. **Greppable and diffable.** Definitions begin with `:`, end with `;`, and
   effects are searchable boundaries. Canonical formatting preserves source
   order and uses qualified names when ambiguity exists.
5. **Local reasoning.** The body plus declared callee signatures determine the
   checked kernel term. Refinements attach at the boundary and diagnostics
   identify the exact word and stack row at failure.

These are conformance and lint requirements, not additional kernel semantics.
Any future convenience syntax must specify a total erasure to this same atom
set before entering v0.1.
