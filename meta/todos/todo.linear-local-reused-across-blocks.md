---
node: firth.toolchain.agent
status: done
created: 2026-10-02
---

# A linear local used inside an inner block and again after it is reported as never used

The checker refuses the word, as it should, but names the wrong mistake. With
`w` a `World^linear` input:

```firth
: f (forall ρ; ρ w:World^linear -- ρ w:World^linear w2:World^linear)
  locals { w } { 1 locals { k } { w } w } ;
```

reports `firth.linearity.unconsumed-resource`, "The linear local `w` is never
used.", where `w` is used twice. Erasure counts a linear local's uses in the
rest of its own block only (`useCount` in `src/elaborator/Firth/Erasure.lean`),
so the inner block moves `w` and the later `w` no longer finds it. Main before
#213 gives the same report (found by cubic on #213; the tail-call change left
linear locals as they were).

## Acceptance criteria

- The case above is reported as a linear local used twice, naming both uses,
  with the program still refused.
- A test holds that report, and a planted mutant (the current counting) fails
  it.

## Resolution

`useCount` now counts the uses after the inner block for a linear local of
an enclosing block too, so the case above is refused as
`firth.linearity.copy`: "The linear local `w` is used more than once: first
at line 2, column 35, and again here.", at the second use. The report names
the first use for every copy found this way.

Counting further out needs to know which local a name means there: a block
that binds the name again hides the enclosing blocks' later uses of it
(`shadowAfter`), so a linear local of a middle block and an outer local of
the same name are still two locals. `firthErasureTest` holds both cases
(`across`, `rebound`), and `examples/programs/nested-loop.firth` runs the
`many` version of the second (`rebound`).
