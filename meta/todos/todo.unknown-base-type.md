---
node: firth.toolchain.elaborator
status: done
created: 2026-10-11
---

# Refuse a type name that is not a type

The checker accepts any name as a base type in a stack effect: `Seq` with no
element type, and a made-up name such as `Foo`.

```
: main
  (forall ρ; ρ s:Foo^many -- ρ n:Int^many)
  drop 0 ;
```

checks with `"status": "success"` (`tools/loop/firth_run.py check`, at
627a0eb; main at 8ce2c8f changes nothing under `src/` or `tools/`). The error
shows up only later: a primitive given the value says it gets `Seq` where it
takes `Seq Int`, and running the word refuses its input with no diagnostic
code and a raw record:

```
entry main: initial stack type mismatch; expected {'kind': 'base', 'name': 'Seq', 'usage': 'many'}, got Seq Int
```

Found in the harder tier's scored run of 11 October 2026: haiku-firth-4's
round-1 sokoban declared `cells:Seq^many` and got that runner message on
every case (`eval/s7/harder/runs/2026-10-11-scored/rescore-pin/haiku-firth-4/results-1.json`).

## Acceptance criteria

- A stack effect naming a type that does not exist is refused by the checker
  with a code and a hint listing the types (`Int`, `Bool`, `Seq Int`,
  `Seq Bool`), and `Seq` alone says to give the element type. Planted cases:
  `Foo`, `Seq`, `Seq Foo`.
- The runner's entry-type refusal names the expected type in Firth syntax.

## Done

`dec.source-type-names`: the checker refuses any type outside `Int`, `Bool`,
`Seq Int`, `Seq Bool` and the effect types with `firth.type.unknown-type`,
at the type, with a hint listing them; `Seq` alone says to write `Seq Int`
or `Seq Bool`. `runSourceTypeTests` covers `Foo`, `Seq`, `Seq Foo` and
`SeqInt`, with a planted acceptance (the old outcome) that fails the check.
The runner's entry-type refusal now reads "the input is declared as `Seq`,
but the case gives `Seq Int`" (`test_mvp_agent_gate.py`).
