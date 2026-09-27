# Proofs about Firth programs

Each file here proves properties of one exported source (`src/exports/`)
with the program logic in `src/interpreter/Firth/ProgramLogic.lean`.

A proof states a `Runs` fact about an exported word or body:

```lean
Runs adapterGamma dictionary defaultCosts program before after steps cost
```

says that `program`, started on `before` and followed by anything, finishes on
`after` in exactly `steps` transitions charging `cost`. The logic has one rule
per kernel atom, sequencing (`runs_cons`, `runs_append`), `runs_if`,
`runs_dip`, `runs_call`, `runs_word`, one lemma per primitive under the
reference runner's registry, and `induction_on_measure` for recursion.
`run_of_runs` turns a `Runs` fact into the value the reference interpreter's
`run` returns.

`Programs/SumTo.lean` is the worked example: for every `n`, `sum-to` returns
`1 + ... + n` at a cost of exactly `13·n + 10`, the figure `firth_run.py`
reports as `kernel_cost`.

Proofs here are built by `lake build` and must be free of `sorry`, `admit`
and new axioms. They are not yet recorded as evidence bound to body digests,
and the toolchain does not yet report `contract_verified`; that is the next
step.
