---
node: firth.toolchain.agent
status: open
created: 2026-10-10
---

# A `locals` block names a word's row as if it were a value

Erasure counts the entry that stands for a word's row (the caller's values
below its declared inputs) as a value a `locals` block can name
(`bindable` in `src/elaborator/Firth/Erasure.lean`). So in

```
: main (forall ρ; ρ -- ρ r:Int^many ) locals { xs } { xs } ;
```

`xs` names the row, and the report is the typing one: "`main` declares that
it leaves ρ Int but its body leaves ρ", with the hint "Something consumes a
value it should keep". Nothing consumes a value: the block names a value the
word was never given. Found while building `todo.underflow-names-declared-inputs`,
which leaves words whose effect has a row out for this reason.

## Acceptance criteria

- A `locals` block that would name the row of the word's effect is refused
  as a stack underflow, and the report says the block names more values than
  the word's declared inputs and the values pushed before it.
- A block that names only declared inputs or pushed values is unchanged.
