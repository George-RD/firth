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
    field               = word-name , ":" , type-expression ;
    variant-declaration = "variant" , type-name , "{" , case , case , { case } , "}" ;
    case                = word-name , [ ":" , type-expression ] ;

    record Request { id:Int qty:Int }
    variant Outcome { filled:Int short:Int empty }

`record` and `variant` become reserved words. A declaration sits at the top
level of a file or inside a `vocab`, in the same place a word definition may,
and its canonical key is built the same way (`Request`, `inv.Request`). Type
names and word names are different kinds: a type and a word may not share a
canonical key (`firth.name.duplicate-canonical`). A type name starts with an
upper-case letter, which `word-name` allows already; `firth.type.type-name-case`
refuses a record or variant name that does not, so a type name never reads as
a word.

Generated operation names must not collide: a field may not be named
`pack`, `unpack` or `seq`, nor begin with `set-` (`firth.type.reserved-field-name`),
so `R.pack`, `R.unpack`, `R.f` and `R.set-f` are distinct for every field.
(Case constructors are `V.c`; `match` is reserved, so a case cannot take
that name.)

A record has at least one field. A variant has at least two cases, which is
what makes it a choice; a case has zero or one payload type. A result is a
two-case variant:

    variant AllocResult { ok:Seq Int err:Int }

There is no built-in `Result`: see Rejected alternatives for generics.
Field and case names are unique within their declaration
(`firth.type.duplicate-field`, `firth.type.duplicate-case`). A field or
payload type is any type a stack effect may name (`dec.source-type-names`)
plus declared records and variants, `Seq` of a scalar-flat type (below), and
may carry `^linear` only on a record field. A type may not contain itself,
directly or through other declarations (`firth.type.recursive-type`): an
erased value has a fixed width, and a recursive type has none.

`type-expression` gains the declared names: `r:Request`, `rs:Seq Request`.
`sourceTypes` stays the list of base types and now also accepts the names
of the declarations visible in the file, so an unknown name is still
`firth.type.unknown-type`.

Imports and exports carry types: `export Request Outcome;` lists a type and
its generated operations; `import` brings them in under the visibility rules
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

A type is **scalar-flat** when its flat form is only `Int` and `Bool`.
`World`, `Handle` and `Bytes` are never scalar-flat, so a `Seq` of them is
refused (`firth.type.seq-element`), and a `Seq Int` field makes its record
not scalar-flat. A usage `^linear` on a record field makes the record
linear, by the kernel's meet; `dup` and `drop` of the record are refused as
for any linear value. A variant payload may not be linear
(`firth.type.variant-linear-payload`): the cases not taken need a default,
and a replayable literal cannot be linear (kernel spec section 3).

A word's stack effect is flattened when the dictionary entry is built:
`(forall ρ; ρ r:Request ok:Bool -- ρ s:Outcome)` becomes the kernel type
over `r.id:Int r.qty:Int ok:Bool -- Int Int ... Bool`, and its names for
diagnostics are the field paths. A call to the word needs no code beyond
what the flat stack already holds.

Structural atoms on composite values. The surface layer tracks the width of
every value, and the kernel atoms written in source act on whole surface
values, not on the top flat slot. For a top value of width `w` (a record,
variant, or the columns of a `Seq T`): `dup` emits `pick (w-1)` `w` times;
`drop` emits `drop` `w` times; `swap` of a value of width `a` below one of
width `b` emits `roll (a+b-1)` `a` times; `[q] dip` emits `w` nested dips
(`[ [ ... [q] dip ] dip ] dip`), so `q` runs beneath all `w` slots; `quote` of
a composite is refused (`firth.type.composite-quote`), since a quotation holds
one kernel value; use `locals`, which captures slot by slot. `call`, `compose`
and `if` act on quotations and `Bool`s, which have width 1, and are unchanged.
A linear slot in `w` still makes `dup` and `drop` refuse, by the kernel's
usage rule. Width 1 reduces each rule to the kernel atom itself.

Operations. Each is a macro in the elaborator that emits only kernel atoms;
none is a dictionary word, so no digest, key or call graph changes:

- `R.pack` : `ρ f1 ... fk -- ρ r:R`. Emits nothing; it changes the surface
  type of the top `width(R)` values to `R`. `R.unpack` is its inverse and
  emits nothing.
- `R.f` (a field read) : `ρ r:R -- ρ v:Tf`. Consumes the record. Emits a
  `roll` to bring the field to the top and a `drop` for every other flat
  slot, which are all `many` (`firth.type.record-drop-linear` otherwise).
  A word that reads two fields of one record uses `locals`.
- `R.set-f` : `ρ r:R v:Tf -- ρ r:R`. Replaces the field, dropping the old
  value (`many`; `firth.type.record-drop-linear` otherwise).
- In a `locals { r }` block a record local `r` is bound as its fields
  `r.f1 ... r.fk`, one local per flat slot, in order. `r.f` selects one
  field, and `r` alone selects all of them in order, i.e. `r` rebuilds the
  record. This reuses section 5.1's erasure unchanged: the algorithm's slots
  are flat slots, its usage counting is per slot (so reading `r.id` twice and
  `r.qty` once copies `id` once and moves everything else), and unused fields
  are dropped at the end of the block as unused locals are today. A record
  local with a linear field must have each linear field selected exactly once,
  as any linear local.
- `V.c` (a case constructor) : `ρ p:Pc -- ρ v:V` (no `p` for a case without a
  payload). With payload width `w` and `d` the total width of the defaults
  of all other cases, it emits those defaults (cases before c, then cases
  after c) above the payload, then `roll (d + w - 1)` `w` times, which moves
  the whole payload back to the top in order (`dip` protects only one slot,
  so it is not used), then the tags, all `false` except the one for case c (case 1
  has no tag). Defaults: `0` for `Int`, `false` for `Bool`,
  `prim seq-int.empty` or `prim seq-bool.empty` for a sequence, the defaults of
  its fields for a record, and for a variant the defaults of every payload
  and `false` for every tag.
- `match`, in a body: `V match { c1 [ body1 ] ... cn [ bodyn ] }`, or with
  the cases of `V` written in any order. An arm for a case with a payload
  runs with the payload on top of the stack; an arm for a case without one
  with nothing added. All arms must have the same stack effect, as the
  branches of `if` must, because the erasure is a chain of `if`s on the tags,
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
  layer refuses (`firth.type.mismatch`, naming both types and the field
  that differs when they have the same width).
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

Two things the host must keep, stated in each contract that mentions the
type and not proved by Firth:

- **Equal column lengths** of a `Seq T` supplied by the host.
- Nothing else: a `Bool` tag cannot be out of range, which is why tags are
  `Bool`s (see Rejected alternatives).

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
`match` `O(cases + total payload width)`, a `T.seq.at` `O(columns)` with
a handful of atoms per column. These are measured per run, and proved only
where a Lean contract exists, as for any word (`AGENTS.md` rule 8); they are
not a claim of this record. Erased code is the code one would write by hand
for the flat stack; the implementation PRs measure it on the examples.

### Proofs

Contracts and proofs are stated over the erased words and the flat stack
(`WordContract`, `.Holds`), as for locals. Nothing in `src/proofs/` needs to
change for this decision. A contract about a word over a record states its
fields as flat values; a word over a variant states that the unused payload
slots hold defaults and that its behaviour does not depend on them, which is
a property of the word (a theorem about `match`'s erasure is not needed:
after the `if` the other slots are dropped). The imports lemma
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
  express `Seq (Seq Int)`, so it needs the `Γ` change above and George.

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
