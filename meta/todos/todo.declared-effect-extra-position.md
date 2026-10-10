---
node: firth.toolchain.agent
status: done
created: 2026-10-02
---

# Say where the extra value is when a body leaves too many

Found by the second harder-tier calibration pool (`eval/s7/harder/README.md`,
"Second pool results"). Firth 3's round-1 elevator `main` pushed `tm` twice,
so its body left `ρ Seq Int Seq Int Int Int` against a declared
`ρ Seq Int Int Int`
(`eval/s7/harder/runs/2026-10-02-calibration2/sonnet-firth-3/results-1.json`).
The extra value is the first `Seq Int`, under all three results. The hint
says

```
hint: The body leaves 1 extra value on top (Int). Consume or `drop` it before the end of the word, ...
```

which names the wrong value and the wrong place: the top three values
are the declared `Seq Int Int Int`. `explain` in
`src/agent/Firth/Agent/ElaboratorDiagnostics.lean` assumes the declared
values are the bottom of what the body leaves and the surplus is on top.
Reproduce with

```
: main
  (forall ρ; ρ a:Seq Int^many -- ρ r:Seq Int^many n:Int^many m:Int^many)
  locals { a } { a a 1 2 };
```

which `tools/loop/firth_run.py check` refuses with the same hint.

A wrong shipped hint outranks a new one: it sends the author to drop the
wrong value.

## Acceptance criteria

- When the declared values match the top of what the body leaves, the hint
  says the extra values are under them and names their types and depth.
- When the extra value's position cannot be told from the types, the hint
  does not claim one.
- A test holds the case above and the existing extra-on-top case, and a
  planted mutant restoring the old wording fails it.

## Resolution

`extraValuesHint` in `src/agent/Firth/Agent/ElaboratorDiagnostics.lean`
places the declared values among what the body leaves, in order and by type,
counting values of one type in a row as interchangeable. It says "on top"
only when that placement puts every extra value above the declared ones and
no other placement puts them below; "under" only the other way round, with
their types and depth; "among" with each group's depth when the extra values
are between declared ones; and no place when the types allow either, or more
than one placement. The case above now reads "The top 3 values match the
declared output, and under them the body leaves 1 extra value (Seq Int),
value 4 from the top."

`firthAgentDiagnosticTest` holds that case, the existing on-top cases and the
others above. Each of these fails a test: the old wording restored (always
"on top"); "on top" given where both placements fit; the kept-value check
for "on top" taken from the wrong placement; a unique placement treated as
several; and adjacent wholly extra runs not merged.
