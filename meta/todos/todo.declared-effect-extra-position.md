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
counting values of one type in a row as interchangeable. When there is one
such placement and every run of one type holding an extra value is wholly
extra, the types fix where each extra value is: the hint says "on top" when
they are all above the declared ones, "under" with their types and depth
when they are all below, and "among" with each group's depth otherwise.
When a run is only partly extra, the types do not tell which of its values
is the extra one, so the hint names the run, its type and its depths, says
the types do not tell which value it is, and names no edit that relies on a
place. If the values above every such run are all declared ones, it also
says those match the top of the declared output and the extra values are
under them, which the types do fix. The hint names no place when all the
values are of one type, or when more than one placement fits. The case above
now reads "The top 2 values match the top of the declared output, and under
them the body leaves 1 extra value: 1 of the 2 Seq Int values, values 3 to 4
from the top." Which of the two `Seq Int` values is extra cannot be told from
the types, so the first criterion is met as far as the second allows: the
extra value is named as under the declared `Int Int`, with its type and the
two depths it can be at.

`firthAgentDiagnosticTest` holds that case, the existing on-top cases, an
extra Int among two on top (`( -- b:Bool n:Int ) true 1 2`) and among two
under the top (`( -- n:Int b:Bool ) 1 2 true`), and the others above. Each
of these fails a test: the old wording restored (always "on top"); a run
only partly extra treated as placed, which restores the first version's
"on top" and "the third value from the top" for those two; the "under"
lead-in for a partly extra run dropped, or given when a declared run sits
below the extra ones; the one-type
stack listed as a run; "under" missed when the kept values are counted from
runs with extra values in them; a unique placement treated as several; and
adjacent wholly extra runs not merged.
