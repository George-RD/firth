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
    qualified    = word-name , { "." , word-name } ;
    row-name     = "ρ" , { letter | digit | "-" } ;
    type-name    = qualified ;
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
                      { use-declaration | word-definition } , "}" ;
    use-declaration = "use" , qualified , [ "as" , word-name ] , ";" ;
    word-definition = ":" , word-name , stack-effect , body , ";" ;
    body            = { item } ;
    item            = literal | quotation | kernel-atom | primitive | qualified
                    | word-name | local-block ;
    quotation       = "[" , { item } , "]" ;
    primitive        = "prim" , qualified ;
    local-block     = "locals" , "{" , word-name , { word-name } , "}" ,
                      "{" , { item } , "}" ;

The outermost file is an implicit vocabulary. A vocabulary's canonical name is
its enclosing qualified name. A `use` makes exported words available
unqualified for the rest of the containing scope. `as` adds an alias for
qualified lookup. A word is exported by default from its defining vocabulary;
future visibility modifiers are outside v0.1.

Duplicate canonical names, duplicate aliases, and ambiguous unqualified uses
are errors. Qualified lookup is exact and cannot be shadowed. Vocabulary
declarations, `use`, aliases, and export status erase completely. The
dictionary key is the canonical qualified name, and the dictionary value is the
word's erased prenex stack effect and elaborated kernel body. Vocabularies
organise names but introduce no runtime operations.

Definitions are visible throughout their vocabulary, including before their
textual definition, so mutually recursive dictionary words are possible. A
body is checked against its declared effect while all declared signatures are
in the dictionary. A public contract may retain refinements, but the kernel
dictionary stores only the erased `WordType`.

## 3. Stack effects

The chosen v0.1 annotation is a parenthesised effect at the word boundary:

    stack-effect     = "(" , [ "forall" , row-name , { row-name } , ";" ] ,
                       stack-items , "--" , stack-items , ")" ;
    stack-items      = [ stack-item , { stack-item } ] ;
    stack-item       = row-name | ( word-name , ":" , type-expression ) ;
    type-expression  = type-name , [ "^" , ( "many" | "linear" ) ] ,
                       [ "{" , predicate , { "," , predicate } , "}" ] ;

A row variable is written as a stack item by itself, for example
`(forall ρ; ρ -- ρ x:Int^many)`. The semicolon terminates the prenex binder;
all row variables are bound there and nowhere inside a type. A signature may
omit `forall` only when it has no row variables. Named value entries are
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

The macro uses a deterministic stack-permutation algorithm: produce the
shortest sequence of `swap`, `dip`, and `dup`/`drop` atoms that brings
each demanded value to the top while preserving later live values. A value used
zero times is dropped only if it is `many`; a value used more than once is
duplicated only if it is `many`. A linear value must occur exactly once. Ties
prefer the leftmost live value, then `swap` before `dip`. If no legal
expansion exists, elaboration fails. The expansion is checked normally, so
locals cannot bypass stack, usage, or refinement checking.

The linter reports `LOCAL_DEPTH` when a local block declares more than four
names and `STACK_JUGGLE` when its expansion contains more than four
consecutive structural atoms (`dup`, `drop`, `swap`, `dip`). These are
warnings, not typing rules. Splitting the word is recommended.

## 6. Worked elaborations

Assume Γ contains `Int^many`, `Bool^many`, and `prim +` with effect
`Int^many Int^many → Int^many`:

    : inc ( ρ n:Int^many -- ρ n:Int^many ) 1 prim + ;

Its body is exactly:

    lit 1 ; prim +

A word reference `arith.inc` elaborates to the single atom `arith.inc`, not
to an inline copy. For quotation and conditional syntax:

    : choose-inc ( ρ n:Int^many b:Bool^many -- ρ n:Int^many )
      [ 1 prim + ] [ ] if ;

The body is:

    [ lit 1 ; prim + ] ; [ ] ; if

The branches both have effect ρ n:Int^many → ρ n:Int^many after elaboration.
The frozen `if` rule therefore accepts the example. Unequal branch effects are
always rejected; surface syntax cannot weaken that rule.

For a local permutation:

    : add-top-two ( ρ a:Int^many b:Int^many -- ρ r:Int^many )
      locals { a b } { a b prim + } ;

The canonical expansion is `prim +` because the declared stack already has
`a` below `b`, and both values are consumed in the required order.

Assume linear `Handle^linear`, linear `Bytes^linear`, and `prim send` with
effect `Handle^linear Bytes^linear →`:

    : send-once ( ρ h:Handle^linear b:Bytes^linear -- ρ )
      locals { h b } { h b prim send } ;

Its local expansion is `prim send` when `send` expects `h` below `b`; each
linear value occurs exactly once.
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
