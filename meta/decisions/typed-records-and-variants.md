---
id: dec.typed-records-and-variants
nodes: [firth.language.surface, firth.language.types, firth.toolchain.elaborator, firth.toolchain.compiler, firth.ecosystem.stdlib]
status: accepted
related: [dec.multi-file-imports, dec.source-type-names, dec.locals-input-order, dec.kernel-spec-freeze, dec.agent-development-rules]
date: 2026-10-13
---
# Typed records and results: surface types that erase to the stack

## Context

`todo.language-12` asks for "the minimum typed records/results/bounded
sequence representation needed for the consumer, through existing kernel
facilities where possible". Imports are done (`dec.multi-file-imports`); this
is the other half, and `todo.language-13` (the M1 inventory component)
depends on it.

Today a Firth value is an `Int`, a `Bool`, a `Seq Int`, a `Seq Bool`, or one
of the world types. Everything structured is a convention on the stack:
`allocator.firth` takes each request as four unrelated `Int`s in a flat
sequence, a result is a code (`0 ok, 1 invalid-range, 2 duplicate-id`) next
to values that mean something only for some codes.
Records give a group of values one name and named fields, so a word that
passes a request on says `r:Request` once, and a result type makes "failed,
with this code" and "worked, with this answer" different cases the checker
makes the caller handle.

The question this record has to answer first is whether that needs a kernel
change, since the kernel is frozen (`AGENTS.md` rule 7).

## Answer: no kernel change

Records and results are **surface types that erase to flat stack values**.
The kernel gets no new atom, type, typing rule or semantic rule, and `Γ`
gets no new base type or primitive:

- A record value is its fields on the stack, in declaration order. Packing,
  unpacking and field access emit existing atoms (`dup`, `drop`, `swap`,
  `pick n`, `roll n`, `dip`, `quote`) and literals.
- A result (a variant, below) is a fixed number of stack values, `Bool` tags
  and payload slots, with the slots of cases not taken holding default
  values.
- A sequence of records is a record of sequences (one `Seq Int` or `Seq Bool`
  per scalar field), kept equal in length by the operations that build it.

This is the route `spec/surface/syntax.md` section 7 already requires of any
convenience syntax: "a total erasure to this same atom set", and the one the
kernel specification names in section 10 ("Namespaces, naming grammar,
vocabularies, and visibility are surface concerns that erase to dictionary
entries"). Named locals took it. They did need `pick` and `roll`
(`dec.kernel-indexed-shuffles`), but only for cost; this change needs no new
atom, and its code is as long as stack code written by hand (see Costs).

Consequences that make the claim checkable:

- The reference interpreter, the compiler and the Rust VM see only erased
  words. They need no change and no new test of their own to agree on
  records. The dictionary entry of a word over `Request` has the erased
  `WordType` over `Int`s.
- The kernel metatheory (preservation, progress, linearity) is unchanged: it
  already covers every well-typed erased program.
- Surface syntax has no independent runtime semantics (syntax.md, status):
  the meaning of a record program is the meaning of its erasure. There is no
  gap between "record semantics" and "kernel semantics" to prove.

**What would need George.** If a later requirement cannot be met by erasure,
the smallest kernel-side change is a `Γ` extension (new base types and
primitives, no new rule), so that a tuple or sum is one stack value. The
cases are: a sequence whose elements are sequences or non-scalar records
(erasure cannot express `Seq (Seq Int)`), or a value that must be passed
through generic code without being flattened. That is a `Γ` version bump
touching the reference interpreter, linearity contract, compiler lowering,
VM registry and target semantics proofs, i.e. the shape of
`dec.comparison-primitives` plus a typing-relevant base type, and George
approved the last Γ change on a card. Nothing in the first consumer needs it,
and erasure can be replaced by a `Γ` representation later without changing
any source program, because source programs name fields and cases, never
slots. So the easier option of adding `Γ` types now is rejected for cost, not
for expressiveness (see Rejected alternatives).

## Decision

### Declarations

    record-declaration  = "record" , type-name , "{" , field , { field } , "}" ;
    field               = word-name , ":" , member-type ;
    variant-declaration = "variant" , type-name , "{" , case , case , { case } , "}" ;
    case                = word-name , [ ":" , member-type ] ;
    member-type         = type-expression without its refinement part ;
    type-name           = word-name ;  (* local and unqualified; must start upper-case *)

A member type carries no refinement: a `{ predicate }` after it is refused
(`firth.syntax.refinement-in-type`), as refinements stay at word boundaries
(syntax.md section 3). Refinements on a stack item of a declared type
(`r:Request{...}`) are not defined here; the checker refuses them
(`firth.syntax.refinement-in-type`) until a decision gives them a meaning.

    record Request { id:Int qty:Int }
    variant Outcome { filled:Int short:Int empty }

`record`, `variant` and `match` are contextual keywords, not reserved words:
`record` and `variant` are keywords only at the start of an item when the
next two tokens are a type name and `{`, and `match` only when it is followed by `{`, a
name and `[`, a shape a sequence literal never has (it holds only integer and
boolean literals, `syntax.md`), so `match { 1 }` still calls a word `match`. Anywhere else they are ordinary names, so retained programs that define
and call words named `record` or `match` (`eval/s7/harder/reference/scored/firth/sokoban.firth`,
`eval/s7/harder/reference/calibration2/firth/order-book.firth`) keep checking
and running unchanged; the implementation PR runs both as regression cases.
A declaration sits at the top
level of a file or inside a `vocab`, in the same place a word definition may,
and its canonical key is built the same way (`Request`, `inv.Request`). Type
names and word names are different kinds: a type and a word may not share a
canonical key (`firth.name.duplicate-canonical`), and neither may a type and
a vocabulary. Every operation a declaration generates has a canonical key
too (`R.pack`, `R.unpack`, `R.f`, `R.set-f`, the `R.seq.*` operations of a
scalar-flat `R`, and `V.c`), reserved in the same table: a word, vocabulary
or type, in this file or an imported one, whose canonical key equals a
generated key is `firth.name.duplicate-canonical`, naming both
declarations, so no spelling has two meanings. A `use ... as` alias may not equal a type
name or a vocabulary prefix of a generated key either
(`firth.name.duplicate-alias`, the existing code, now also against declared
types), since resolution expands a leading alias first. A type name starts with an
upper-case letter, which `word-name` allows already; `firth.type.type-name-case`
refuses a record or variant name that does not, so a type name never reads as
a word. A declared name may not be a built-in type name: `Int`, `Bool`, `Seq`,
`World`, `Handle` or `Bytes`, or any other name `sourceTypes` lists
(`firth.type.reserved-type-name`), so `x:Int` has one meaning.

Generated operation names must not collide: a field or case may not be named
`pack`, `unpack` or `seq`, and a field may not begin with `set-`
(`firth.type.reserved-field-name`, which covers case names too for `seq`), so
`R.pack`, `R.unpack`, `R.f` and `R.set-f` are distinct for every field, and a
case constructor `V.c` never meets the `V.seq.*` namespace. A case may be
named `match`: constructors are always written `V.match`, so the contextual
keyword cannot meet it.

A record has at least one field. A variant has at least two cases, which is
what makes it a choice; a case has zero or one payload type. A result is a
two-case variant:

    variant AllocResult { ok:Seq Int err:Int }

There is no built-in `Result`: see Rejected alternatives for generics.
Field and case names are unique within their declaration
(`firth.type.duplicate-field`, `firth.type.duplicate-case`). A field or
payload type is any type a stack effect may name (`dec.source-type-names`)
plus declared records and variants, `Seq` of a scalar-flat type (below), and
may carry `^linear` only on a record field of a base type (`Int`, `Bool`,
`Seq` of those, or a world type), never on a field of a declared record or
variant type (`firth.type.linear-composite-field`): a composite field is
linear exactly when some slot of its own flat form is, as each of its slots
keeps the usage its own declaration gave it, so `Pair.pack` and `Pair.unpack`
have the same effect wherever the pair sits. A type may not contain itself,
directly or through other declarations (`firth.type.recursive-type`): an
erased value has a fixed width, and a recursive type has none.

`type-expression` gains the declared names: `r:Request`, `rs:Seq Request`.
`sourceTypes` stays the list of base types and now also accepts the names
of the declarations visible in the file, so an unknown name is still
`firth.type.unknown-type`.
A usage suffix is refused on a declared name (`r:Request^linear`,
`firth.type.composite-usage`): the usage of a composite value is always the
one derived from its slots, as above, so there is one meaning for `dup` and
for `pack` and `unpack` whatever the use site writes. The suffix keeps its
meaning on base types.

Imports and exports carry types: `export Request Outcome;` lists a type and
its generated operations, and every declared type that appears in its member
types, directly or through other declarations, must be declared in the same
file and exported by it too (`firth.name.export-incomplete`, naming the
missing type). A file may use an imported type in its own declarations, but a
type with an imported type among its members cannot be exported
(`firth.name.export-imported-member`, naming the imported type): exports list
only what the file owns and imports are not transitive
(`spec/surface/syntax.md`), and this decision adds no re-export. A library
that needs such a composition declares the member types in the one file. This
is a deliberate limit, recorded as a gap in `todo.language-12-data-and-modules`
(type re-export). The same closure covers exported words: every declared
type in the input or output of an exported word's signature, with its member
closure, must be declared in the exporting file and exported by it
(`firth.name.export-incomplete`, naming the word and the type), and a
signature naming an imported type cannot be exported
(`firth.name.export-imported-member`). An importer therefore always has the layout and the
operations of every type it can reach; `import` brings them in under the visibility rules
of `dec.multi-file-imports`; `firth.name.not-exported` applies to types. A
type's canonical key, like a word's, does not depend on who imports it.

### Erasure

Widths. The **flat form** of a type is a list of kernel types:

| Type | Flat form |
| --- | --- |
| `Int`, `Bool`, `Seq Int`, `Seq Bool`, `World`, `Handle`, `Bytes` | itself |
| `record R {f1:T1 ... fk:Tk}` | flat(T1) followed by ... flat(Tk) |
| `variant V {c1:P1 ... cn:Pn}` | flat(P1) ... flat(Pn) (a case with no payload adds nothing), then `Bool`s `u2 ... un` |
| `Seq T`, T scalar-flat with m scalars | m sequences, `Seq Int` for an `Int` scalar and `Seq Bool` for a `Bool`, in flat order |

A type is **scalar-flat** when its flat form is only `Int` and `Bool`, all
`many` (a record with an `Int^linear` field is not: the `seq-int` and
`seq-bool` primitives take and give `many` values only, so a `Seq` of it would
either fail to check or lose the field's ownership).
`World`, `Handle` and `Bytes` are never scalar-flat, so a `Seq` of them is
refused (`firth.type.seq-element`), and a `Seq Int` field makes its record
not scalar-flat. A usage `^linear` on a record field makes the record
linear, by the kernel's meet; `dup` and `drop` of the record are refused as
for any linear value. A variant payload must have a default for
every flat slot, so its flat form may contain only `Int`, `Bool`, `Seq Int`
and `Seq Bool` (`firth.type.variant-payload-no-default`, whatever usage is
written): the cases not taken need a default, a replayable literal cannot be
linear (kernel spec section 3), and `World`, `Handle` and `Bytes` have no
literal at all. A record containing any of them is refused as a payload for
the same reason. Records themselves may hold them.

A word's stack effect is flattened when the dictionary entry is built:
`(forall ρ; ρ r:Request ok:Bool -- ρ s:Outcome)` becomes the kernel type
over `r.id:Int r.qty:Int ok:Bool -- Int Int ... Bool`, and its names for
diagnostics are the field paths. A call to the word needs no code beyond
what the flat stack already holds.

Structural atoms on composite values. `pick n` and `roll n` are not source
syntax (syntax.md section 4: named locals erase to them, and a word may not
be named for them), so they need no composite semantics: a program reaches
them only through `locals`, which works slot by slot. The surface layer tracks the width of
every value, and the kernel atoms written in source act on whole surface
values, not on the top flat slot. For a top value of width `w` (a record,
variant, or the columns of a `Seq T`): `dup` emits `pick (w-1)` `w` times;
`drop` emits `drop` `w` times; `swap` of a value of width `a` below one of
width `b` emits `roll (a+b-1)` `a` times; `dip` of any quotation, written or built at run time, emits `quote [dip]
compose` `w-1` times and then `dip` (`[q]` becomes `[[q] dip]`, then
`[[[q] dip] dip]`), so `q` runs beneath all `w` slots without needing the
body at elaboration; `quote` of
a composite emits `quote` then `swap quote swap compose` `w-1` times, which
builds one quotation that pushes all `w` slots in flat order (for `a b`:
`a [b]`, then `[a] [b]`, then `[a b]`). Each slot is consumed once, so linear
slots are legal, and the result is a kernel quotation whose recorded surface
effect is `[ -> R ]`; `call` on it puts the composite back, with its type. The
easier option, refusing composite `quote` and sending authors to `locals`,
was rejected: it would leave a hole in the erasure for a case that has a
total lowering, at the cost of `4w-3` kernel atoms per quote. `call`, `compose`
and `if` act on quotations and `Bool`s, which have width 1, and are unchanged.
Quotation bodies are erased on their own, before the stack they will run on
is known (syntax.md section 5.1), so a structural atom there acts on the width
of the value it touches in the body's own typing: a value the body did not
build is taken to have width 1, and the quotation's recorded surface effect
says so. Applying such a quotation (`call`, `dip`, `if`, or through a word)
where that stack position holds a composite value is refused
(`firth.type.composite-in-quotation`), naming the atom and the type; the
author moves the composite handling into a word with a typed signature, which
is erased with its types known, or uses `locals`. This is a limit of erasing a quotation body before its stack is known, and it is tracked as `todo.composite-quotations`.
A linear slot in `w` still makes `dup` and `drop` refuse, by the kernel's
usage rule. Width 1 reduces each rule to the kernel atom itself.

Operations. Each is a macro in the elaborator that emits only kernel atoms;
none is a dictionary word, so no word digest, key or call graph changes. The
generated operations still have meaning that the erased words do not carry
(renaming or reordering two `Int` fields leaves every erased word the same
while `Pair.left` changes meaning), so the declarations themselves join the
layer identity: the implementation PR adds each exported type declaration
(canonical type key, ordered member names and their declared types, case
order), and each exported word's resolved nominal input and output signature
(an `A.pack` and a `B.pack` erase to the same program), to the layer's `content_profile` of `syntax.md`, so a provider whose
exported types change gets a new content and dependency identity and cached
consumers and proof evidence stop matching. That PR plants the three cases
that must fail without it: renaming a field, reordering two fields of one
flat type, and changing an exported word's result from one same-layout type
to another each change the profile:

- `R.pack` : `ρ f1 ... fk -- ρ r:R`. Emits nothing; it changes the surface
  type of the top `width(R)` values to `R`. `R.unpack` is its inverse and
  emits nothing.
- `R.f` (a field read) : `ρ r:R -- ρ v:Tf`. Consumes the record. Let the field
  occupy `w` flat slots with `s` slots before it and `a` after. It emits
  `drop` `a` times (the slots after the field are on top), then `roll w`
  followed by `drop` `s` times, each pair removing the topmost slot below the
  field. All dropped slots are `many` (`firth.type.record-drop-linear`
  otherwise), and a field of width `w > 1` (a nested record) moves whole.
  A word that reads two fields of one record uses `locals`.
- `R.set-f` : `ρ r:R v:Tf -- ρ r:R`. Replaces the field, dropping the old
  value (`many`; `firth.type.record-drop-linear` otherwise). With `s`, `w`,
  `a` as above it emits `roll (a + w - 1)` `a` times, which moves the slots
  after the field above the new value, then the pair `roll (a + w)`, `drop` repeated `w` times, one
  pair per old slot (each pair removes the topmost remaining old slot, which
  stays at depth `a + w`), which removes the old field's slots.
- In a `locals { r }` block a record local `r` is bound as its fields
  `r.f1 ... r.fk`, one local per flat slot, in order; a field that is itself
  a record or a `Seq` of scalars expands recursively to leaf names (`b.p.x`,
  `b.p.y`, `b.z` for `Box { p:Pair z:Int }`), one per flat slot. `r.f` selects one
  field (all the leaf slots of a composite field, in order, so `b.p` rebuilds a
  `Pair`), and `r` alone selects all of them in order, i.e. `r` rebuilds the
  record. This reuses section 5.1's erasure unchanged: the algorithm's slots
  are flat slots, its usage counting is per slot (so reading `r.id` twice and
  `r.qty` once copies `id` once and moves everything else), and unused fields
  are dropped at the end of the block as unused locals are today. A record
  local with a linear field must have each linear field selected exactly once,
  as any linear local. A variant-valued local `v`, a variant-typed field
  such as `b.result`, and a direct sequence-of-record local `xs:Seq Pair`
  (whose erasure is one column slot per scalar of `Pair`) bind its flat slots under opaque names the program
  cannot write; the bare name selects all of them in order and so rebuilds
  the variant or the sequence, and no case, payload or column selector exists on it (`match` is the
  only way into a variant; `v.c` is `firth.type.variant-local-selector`, and
  `xs.f` on a sequence of records is `firth.type.seq-local-selector`). The usage rules
  of its slots are those of its declaration, as for a record. A record local whose name is also the leading segment
  of a visible qualified name (a vocabulary, or an alias from `use`) is
  refused at the binder (`firth.name.local-shadows-prefix`, naming the local
  and the prefix), so `r.f` never has two readings and qualified lookup in
  `syntax.md` keeps its meaning.
- `V.c` (a case constructor) : `ρ p:Pc -- ρ v:V` (no `p` for a case without a
  payload). With payload width `w` and `b` the total width of the defaults
  of the cases before c, it emits those defaults above the payload, then
  `roll (b + w - 1)` `w` times, which moves the whole payload back to the top
  in order and leaves the earlier defaults beneath it (`dip` protects only one
  slot, so it is not used), then the defaults of the cases after c, then the
  tags, all `false` except the one for case c (case 1 has no tag). With `b`
  zero no `roll` is emitted. Defaults: `0` for `Int`, `false` for `Bool`, one
  `prim seq-int.empty` or `prim seq-bool.empty` per column for a `Seq` (a
  `Seq Pair` with an `Int` and a `Bool` field gets both), the defaults of
  its fields for a record, and for a variant the defaults of every payload
  and `false` for every tag.
- `match`, in a body: `V match { c1 [ body1 ] ... cn [ bodyn ] }`, or with
  the cases of `V` written in any order. An arm for a case with a payload
  runs with the payload on top of the stack; an arm for a case without one
  with nothing added. The arms are compared after their payloads are supplied: an arm
  for case c is checked as a body from `ρ Pc` (or `ρ`), and all arms must
  leave the same stack `Σ'` above the stack `ρ` below the scrutinee, so the
  match as a whole has the effect `ρ V -- Σ'` and arms of different payload
  widths may differ in their own effects (`some [ drop 1 ]` and `none [ 1 ]`
  agree). This is the kernel's `if` rule applied to the erasure, a chain of
  `if`s on the tags,
  the top tag first (case n), down to case 2, with case 1 as the last `else`.
  In each branch the other cases' payload slots and the remaining tags are
  dropped before the arm's body. The match must name every case exactly once
  (`firth.type.match-non-exhaustive`, `firth.type.match-duplicate-case`,
  `firth.type.match-unknown-case`) and the scrutinee on the stack must be a
  `V` (`firth.type.match-not-variant`).

Sequences of records. For a scalar-flat `T` the generated operations are
`T.seq.empty`, `T.seq.len`, `T.seq.at`, `T.seq.push` and `T.seq.set`, with the
effects of `seq-int.*` over a `Seq T` and a `T`, each an erased sequence of
the `seq-int` and `seq-bool` primitives on the columns. They keep the columns
the same length by construction. `T.seq.len` reads one column and drops the
rest. `T.seq.at` and `T.seq.set` of an index beyond the length trap as the
primitives do, on the first column that is read.

### Checking and reports

The kernel checker runs on the erased program as it does today, and it is
the soundness basis: a program the surface layer wrongly accepts is still a
well-typed kernel program, so it cannot violate stack, usage or linearity
safety. The surface layer adds what the kernel cannot see:

- **Nominal types.** `Request` and an `Item` with the same fields are
  different types. The kernel would accept one for the other; the surface
  layer refuses (`firth.type.mismatch`, naming both types, and the first field
  or case whose declared type differs when one exists; two types with the
  same structure and different names are reported by name alone).
- **Field and case names**: unknown field or case (`firth.type.unknown-field`,
  `firth.type.unknown-case`), with the declared names in the report.
- **Reports in record terms.** A stack mismatch involving flat slots of a
  record names the record and field (`r.qty`), not slot positions. A word
  whose only fault is a field read from the wrong record gets a hint naming
  the fields of the record on the stack, quoted from the declaration, under
  the same hint discipline as `dec.locals-input-order` (name a fix only when
  unique and checked).

How the surface layer tracks nominal types over the flat stack is an
implementation matter; the requirement is that it is a function of the
parsed source and the declarations, with no heuristic, and that every code
above has a planted-bug test showing the check can fail (`AGENTS.md` rule 9).

### Host boundary

The host and the VM see the erased stack. A word over `Request` takes two
`Int`s, a word over `Seq Request` takes one `Seq Int` per field. A variant
is its payload slots then its tags. The input and output stacks of
`firth_run.py run` are flat, unchanged; nothing in the compiler envelope or
the VM changes.

One thing the host must keep, stated in each contract that mentions the
type and not proved by Firth: **equal column lengths** of a `Seq T` it
supplies. Nothing else is required. A `Bool` tag cannot be out of range,
which is why tags are `Bool`s (see Rejected alternatives), and the slots of
the cases not taken may hold anything: `match` drops them without reading
them, so a contract speaks only of the selected payload and no canonical form
of the inactive slots is required or checked.

Ownership, bounds and termination as the todo asks: a record has the
ownership of its fields (a linear field makes it linear); every type has a
fixed finite width, so there is no unbounded structure except the `Seq`
columns whose bounds are the programs' own, as today; erasure terminates by
structural recursion on the type (recursive types are refused). A JSON
object form of record arguments at the host is a host convenience that
changes nothing in the language: `todo.host-record-values` records it.

### Costs

Erasure emits straight-line code of length linear in the width of the
types involved: a constructor or field read costs `O(width)` steps, a
`match` `O(cases + total payload width)` executed steps, a `T.seq.at`
`O(columns)` with a handful of atoms per column. Static code size is a
separate figure: each of the `n` arms of a `match` drops the other payloads
and the remaining tags, so the emitted program is `O(n^2)` in the number of
cases for one-slot payloads even though one path runs. The implementation PR
measures the size on the examples and does not claim the linear bound for it;
a shared-tail strategy is a later optimisation, not a requirement here. These are measured per run, and proved only
where a Lean contract exists, as for any word (`AGENTS.md` rule 8); they are
not a claim of this record. Erased code is the code one would write by hand
for the flat stack; the implementation PRs measure it on the examples.

### Proofs

Contracts and proofs are stated over the erased words and the flat stack
(`WordContract`, `.Holds`), as for locals. Nothing in `src/proofs/` needs to
change for this decision. A contract about a word over a record states its
fields as flat values; a word over a variant states its result in terms of the selected case and
its payload only. Words built by the constructors and `match` never read the
inactive slots (the `if` chain drops them), and a word that only passes a
variant on returns whatever slots it was given, so no contract may speak of
them. The imports lemma
`WordContract.Holds.extend` carries over because erased words keep
file-independent keys and digests.

The erasure is trusted in one sense only: the checker's and the
compiler's claim that an erased word has the types its declaration says. That
is checked by the kernel checker on the erasure, as for locals; there is no
separate Lean theorem about record erasure in this milestone, and none is
claimed. If one is wanted it would extend `erase_sound`
(`Firth/Erasure.lean`).

### Work, in order

Each is its own PR, from `main`, with tests, docs and the planted-bug cases
(rule 9), and every one that touches `src/` or `stdlib/` waits for the S7
calibration pin PR to merge.

1. This record, plus the todo updates.
2. Records: `record`, `pack`/`unpack`, field read and set, record locals,
   imports and exports of types, flat word types, nominal and field
   diagnostics, `examples/` programs, expected outputs written
   independently, VM and reference agreement.
3. Variants and `match`.
4. Sequences of records.
5. Docs for the S7 inputs (`docs/getting-started.md`,
   `docs/firth-agent-guide.md`, `examples/programs/README.md`), with the
   note that this changes what the next S7 run measures. `todo.language-13`
   then uses the types in the allocator; that is its change, not this one's.

`todo.language-12` stays open until all five are merged (rule 1, rule 2).

## Rejected alternatives

- **New `Γ` base types or a tuple/sum in the kernel** (a record is one stack
  value, projections and case analysis are primitives or atoms). Cleaner
  runtime values and a place for `Seq` of anything, but it touches the
  interpreter, linearity contract, compiler, VM and target semantics, needs a
  decision that George approves, and buys nothing the first consumer uses.
  Erasure leaves the way open: source names fields, never slots.
- **`Int` tags for variants.** One slot and a short `match`, but a value
  from the host can be out of range, and then `match` either needs a trap
  case or silently takes the last arm. With `Bool` tags every bit pattern
  is a valid value and the host contract has no tag precondition. It costs
  `n - 1` slots for `n` cases.
- **A fixed `Result T E` with type parameters.** Familiar to authors, but
  generic types need type application in stack effects (`Result Int Int`),
  instantiation naming in erased types, and checks for linear parameters.
  A monomorphic `variant` declaration is the same erasure, and a generic
  form can be added later as sugar for declaring one per instantiation.
  Filed as `todo.generic-types`.
- **Stride encoding for sequences of records** (what `allocator.firth` does
  with four `Int`s per ID): no names, no checking, and an off-by-stride
  error is a wrong answer, not a refusal.
- **A `Seq` of records that hold sequences.** Out of scope: erasure cannot
  express `Seq (Seq Int)`, so it needs the `Γ` change above and George. Filed as
  `todo.seq-of-seq-records`.

## Consequences

- The kernel specification, the interpreter, the compiler, the VM and the
  proofs are unchanged by the type syntax. The elaborator and the surface
  specification change, in PRs 2 to 4.
- `todo.language-12` records the plan; `todo.generic-types` and
  `todo.host-record-values` are filed here. The text-values gap
  (`todo.language-text-values`) is unchanged: records do not give the
  allocator ID strings.
- The agent guide and S7 inputs change in PR 5, so the S7 run after it
  measures a larger language than the scored run of 11 October 2026.
