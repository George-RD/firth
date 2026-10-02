---
node: firth.toolchain.agent
status: open
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
