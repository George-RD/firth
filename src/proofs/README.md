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
- `int64Gamma`, the registry with `+`, `-`, `*` and `div` faulting outside i64
  as the VM's do. The literal lemmas and the comparison, `mod` and sequence
  primitive lemmas hold under either registry (`[ReferenceRegistry gamma]`);
  for the arithmetic, use `runs_add_int64` and friends, and `runs_div_int64`,
  which also needs a nonzero divisor. `Runs.of_int64` gives the same
  fact under the reference registry, now with no overflow on the way;
- tactics: `runs_chain` proves a straight-line body one atom at a time,
  `runs_unfold` does the same through one word call, and `runs_arith` closes
  the step and cost arithmetic under `defaultCosts`. Word calls inside a
  body are discharged only from `Runs` hypotheses in context, so recursion
  stays explicit. Under `int64Gamma` the chain leaves an `InInt64` side goal
  per `+`, `-`, `*` and `div`, and a nonzero-divisor goal per `div` and `mod`,
  closed when it is an assumption or follows from the
  assumptions by linear arithmetic. `runs_arith` clears Boolean equations
  such as an `if` condition `decide (x < y) = true` before calling `omega`,
  which can time out with one in context, so state any fact the arithmetic
  needs over `Int` or `Nat`. The side goals match assumptions up to
  reducible unfolding only, so a hypothesis that wraps `InInt64` in a
  definition of your own (`h : MyRange x`) must be unfolded first, or used
  with `exact h`. `src/interpreter/FirthLogicTest.lean` holds the
  regression cases.

`Programs/Signed.lean` proves `abs`, whose local compiles to `pick` and
`roll`, under `int64Gamma` with `runs_chain` alone.

`Programs/Division.lean` proves `divmod` with `runs_chain`, and that `gcd`
leaves `Int.gcd a b` for any `a` and `b` in i64 other than -2^63, by strong
induction on `|b|`. Its step and cost bounds are linear in `|b|`: sound, but
not the logarithmic bound Euclid's algorithm meets. Both are recorded as
contracts (`divmodContract`, `gcdContract`); `gcd`'s record also covers the
`abs` it calls, and `digit-sum-from` has no contract yet.

`Programs/SumTo.lean` is the worked example: under `int64Gamma`, for every
`n ≥ 0` whose sum is in i64 range, `sum-to` returns `1 + ... + n` at a cost of
exactly `13·n + 10`, the figure `firth_run.py` reports as `kernel_cost`.

Proofs here are built by `lake build`, which has the Lean kernel check every
declaration.

## Contracts and proof records

A contract is a `WordContract` (in `ProgramLogic.lean`): a type of arguments,
a precondition `pre`, the input and output stacks and the step and cost bounds
as functions of the arguments, and a `witness` that some arguments satisfy
`pre`. The witness is a field, so a contract whose precondition nothing
satisfies cannot be declared at all. `contract.Holds gamma dictionary costs
program` is the statement

```lean
∀ args tail, contract.pre args →
  RunsWithin gamma dictionary costs program
    (contract.input args ++ tail) (contract.output args ++ tail)
    (contract.steps args) (contract.cost args)
```

`contracts.json` lists each claimed contract: the theorem, its module, the
export and word it is about, the `WordContract`, the registry and the cost
table, and a one-line claim for readers. What is checked is the theorem.
`python3 tools/loop/update_proof_records.py` audits each entry with
`firthProofRecords` and writes `records.json`. The audit builds the expected
statement itself,

```lean
contract.Holds gamma <export>.dictionary costs <export>.«word».body
```

and refuses the whole run if the theorem's type is not definitionally equal to
it. So a theorem with an extra hypothesis, a weaker conclusion (`∨ True`), a
different dictionary or a hand-written precondition is refused, however it
names the word. It also refuses an entry when:

- the theorem is not a `theorem` in the named module;
- the theorem, its statement or any definition they use reaches an axiom
  other than `propext`, `Classical.choice` and `Quot.sound`. This refuses
  `sorryAx` and the auxiliary axioms `native_decide` declares;
- the registry is not `adapterGamma` or `int64Gamma` itself (a definition
  equal to one of them is refused too);
- the module's source file is gone, since its `.olean` may be stale.

Coverage comes from the declared word alone: the record covers that word and
every word its body calls, closed under calls, never the rest of the export.
Each record carries the contract's fields pretty-printed (`pre`, `input`,
`output`, `steps`, `cost`) so a reader sees what was proved. It also carries a
digest of the statement: its text and the declaration (type, value, and an
inductive type's constructors) of every constant it names, followed through
every declaration this repository declares, in any namespace, so editing a
helper such as `triangle`, or an inductive type such as `Trace`, changes it. Only Lean's own
`Init`, `Std`, `Lean` and `Lake` are not followed, since `lean-toolchain` pins
them. Then come the axioms used, a digest of the registry and of the cost
table (each over its definition and every repository definition it uses), the
Lean version, and each covered word's body digest and erased type. Its
evidence id is the SHA-256 of the record's text. `records.json` reports every
exported word as
`contract_verified`, naming the theorems that cover it, or `type_checked`.

What the audit cannot judge is whether a precondition is the right one. The
witness shows it can be met, not that it is broad enough: a precondition of
`x = 0` has a witness too. So review each record's printed `pre` against its
`claim` in the `records.json` diff; a claim broader than the printed
precondition is wrong even though the audit accepts it.

`firthProofRecords --status records.json` audits every record in a written
report again and counts it only when the audit reproduces it exactly. A record
whose registry, cost table, word body, erased type, statement, Lean version
or any definition the statement rests on changed, or
whose covers list was edited, stops making its words `contract_verified`.

CI runs the script with `--check`. It fails if any contract is refused, if
the checked-in report differs, or if the audit's behaviour on the fixtures in
`src/prooftests/` changes: every entry in `refused.json` must be refused for
its expected reason, and every entry in `accepted.json` accepted with exactly
its expected coverage and cost table. It also reads the new report back with
`--status`, then plants a changed cost table digest, registry digest, body
digest, erased type, statement digest, Lean version, precondition and a
forged cover, one at a time, and fails
unless each withdraws `contract_verified` from the words that record covers
and verifies nothing new. Last, it narrows the helpers behind the preconditions
of the `abs` fixtures in `src/prooftests/Helper.lean`, declared outside the
`Firth` namespace: a definition, `Allowed`, and an inductive type, `Ok`. For
each it rebuilds that module (the proofs still hold and the printed
preconditions are unchanged) and fails unless `--status` stops counting that
record written before the edit. The file is restored and rebuilt afterwards.

Adding a contract: define its `WordContract` and prove `Holds` here, add it to
`contracts.json`, then run `lake build` and
`python3 tools/loop/update_proof_records.py`.
