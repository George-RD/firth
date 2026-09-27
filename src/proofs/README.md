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
`runs_dip`, `runs_call`, `runs_word`, `runs_pick`, `runs_roll`, one lemma per primitive under the
reference runner's registry, and `induction_on_measure` for recursion.
`run_of_runs` turns a `Runs` fact into the value the reference interpreter's
`run` returns. Each export states `«w».entry`, the dictionary entry a call to
`w` unfolds through.

Also in the library:

- `RunsWithin … maxSteps maxCost`, the upper-bound form for words whose exact
  cost depends on the data, with the same rules and `run_of_runsWithin`;
- `runs_if_of_true` and `runs_if_of_false`, which take the condition as an
  equation;
- `runs_intSeq_at_int` and `runs_boolSeq_at_int`, for an index computed as an
  `Int`;
- `int64Gamma`, the registry with `+`, `-` and `*` faulting outside i64 as the
  VM's do. The literal lemmas and the comparison and sequence primitive
  lemmas hold under either registry (`[ReferenceRegistry gamma]`); for the
  arithmetic, use `runs_add_int64` and friends. `Runs.of_int64` gives the same
  fact under the reference registry, now with no overflow on the way;
- tactics: `runs_chain` proves a straight-line body one atom at a time,
  `runs_unfold` does the same through one word call, and `runs_arith` closes
  the step and cost arithmetic under `defaultCosts`. Word calls inside a
  body are discharged only from `Runs` hypotheses in context, so recursion
  stays explicit. Under `int64Gamma` the chain leaves an `InInt64` side goal
  per `+`, `-` and `*`, closed when it is an assumption or follows from the
  assumptions by linear arithmetic. `runs_arith` clears Boolean equations
  such as an `if` condition `decide (x < y) = true` before calling `omega`,
  which can time out with one in context, so state any fact the arithmetic
  needs over `Int` or `Nat`. The side goals match assumptions up to
  reducible unfolding only. `src/interpreter/FirthLogicTest.lean` holds the
  regression cases.

`Programs/Signed.lean` proves `abs`, whose local compiles to `pick` and
`roll`, under `int64Gamma` with `runs_chain` alone.

`Programs/SumTo.lean` is the worked example: under `int64Gamma`, for every
`n ≥ 0` whose sum is in i64 range, `sum-to` returns `1 + ... + n` at a cost of
exactly `13·n + 10`, the figure `firth_run.py` reports as `kernel_cost`.

Proofs here are built by `lake build`, which has the Lean kernel check every
declaration.

## Contracts and proof records

`contracts.json` lists the theorems claimed as contracts, each with its module
and a one-line claim. The claim is a label for readers; what is checked is the
theorem's statement. `python3 tools/loop/update_proof_records.py` audits them
with `firthProofRecords` and writes `records.json`. The audit refuses the whole
run if any contract:

- is not a `theorem` in the named module under `proofs.`;
- reaches, through its statement, its proof or any definition they use, an
  axiom other than `propext`, `Classical.choice` and `Quot.sound`. This refuses
  `sorryAx` and the auxiliary axioms `native_decide` declares;
- reaches no exported word body.

Each record lists the exported words the theorem reaches, with their current
body digests, and an evidence id: the SHA-256 of the record's text, which
includes a digest of the theorem's statement. `records.json` also reports
every exported word as `contract_verified`, naming the theorems that cover it,
or `type_checked`.

CI runs the script with `--check`. It fails if any contract is refused, if a
covered word's body digest changed since the record was written, or if the
audit no longer refuses the fixtures in `src/prooftests/Refused.lean`.

Adding a contract: prove it here, add it to `contracts.json`, then run
`lake build` and `python3 tools/loop/update_proof_records.py`.
