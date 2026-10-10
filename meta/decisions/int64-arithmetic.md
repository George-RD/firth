---
id: dec.int64-arithmetic
nodes: [firth.language.kernel, firth.toolchain.interpreter, firth.runtime.vm]
status: proposed
related: [dec.comparison-primitives, dec.agent-development-rules]
date: 2026-10-10
---
# Signed 64-bit integers, overflow and `MIN div -1`

## Context

`todo.language-11-arithmetic-comparison` asks for numeric ranges, underflow
and overflow to be stated exactly, and for the `Int` name and its execution to
agree. Integers became signed in #122 (Gamma 0.4), and `div` and `mod` became
Euclidean later, but no decision records the semantics or says why the two
hosts differ on overflow. This record states what ships today and recommends
one change. The change is not made here.

## Semantics as shipped (Gamma 0.8)

- **The type.** `Int` is a signed integer. The VM holds it as an i64, in
  `-9223372036854775808..9223372036854775807`. Source literals may be
  negative. A literal outside that range is refused by the compiler
  (`firth.compile.unsupported-literal`, "int literal exceeds the target
  integer"), so no program that runs on the VM starts from an out-of-range
  value. Host inputs are checked against the same range
  (`src/compiler/Firth/TargetRun.lean`, "integer outside the signed 64-bit
  range").
- **Overflow.** `+`, `-`, `*` and `div` trap on the VM with a primitive fault
  when their exact result leaves the range. Nothing wraps. `mod` cannot
  overflow: its result lies in `0..|b|-1`.
- **Division.** `div` and `mod` are Euclidean: `a = b*q + r` with
  `0 <= r < |b|`. A zero divisor is a primitive fault on both hosts. The one
  quotient outside the range, `-2^63 div -1`, is the `div` overflow above.
- **Sequence length.** `seq-int.len` and `seq-bool.len` return the length as
  an `Int`. For a sequence of 2^63 or more elements the reference returns
  the length and the target faults; that is the `LenOverflowAt` exception
  in `compileWords_correct` (`src/compiler/Firth/LoweringSimulation.lean`). No
  such sequence can be built in practice (inferred, not proved).
- **The reference interpreter.** The runner's registry, `adapterGamma`
  (`src/interpreter/FirthReferenceRun.lean`), computes on Lean's unbounded `Int`.
  So `MAX 1 prim +` and `-2^63 -1 prim div` succeed there with results
  outside the range, where the VM traps, and so does the length of a
  sequence of 2^63 or more elements. Only the zero divisor and the sequence
  index faults are shared.
- **The checked registry.** `int64Gamma` (`src/interpreter/Firth/ProgramLogic.lean`)
  is `adapterGamma` with `+`, `-`, `*` and `div` faulting outside the range,
  as the VM's do. Every proof record's contract is stated under it (all six in `src/proofs/contracts.json`), so a
  proved run under it has no checked `+`, `-`, `*` or `div` result outside
  the range. It does not range-check literals or the starting stack, so a
  value from the input stays in range only where the contract's
  precondition says so (the allocator's program checks its own inputs and its contract states the result; a contract that
  admits an out-of-range input can return it unchanged). The
  kernel's progress theorem is not yet proved for this registry.
- **How the gap is tested.** The differential harness classifies a run where
  the reference succeeds and the VM faults at the first primitive that leaves
  the range as `expected-portable-overflow` (`src/diffharness/README.md`). It
  is a pass, but the README says it is the documented difference between the
  hosts, not an agreement. `FirthLogicTest.lean` pins both registries'
  behaviour at `-2^63 div -1`. `docs/getting-started.md` tells authors that
  the reference's integers are unbounded and the VM's refusal is not
  evidence of agreement.

## The question

AGENTS.md rule 12 says the reference interpreter defines behaviour, so a
divergence is a VM or compiler bug unless the reference disagrees with the
kernel specification. The kernel is parameterised by its primitive signature
`Γ` and says nothing about integer width. So today the reference "defines"
an unbounded result that no VM run can produce. Integer overflow and the
length of a sequence of 2^63 or more elements are the two places where the
defining semantics is not the one programs run under, and where the two
hosts may disagree.

## Options

1. **Keep the split** (status quo). The reference stays unbounded, and
   overflow stays a documented, tested divergence. This costs nothing now.
   But every tool that compares the hosts has to carry a second notion of
   passing for overflow, with its own prefix rule, and the gate cannot expect
   a trap on both hosts there as it can for a zero divisor. An author reading
   the reference result also learns a value the VM will never return.
2. **Run the reference under `int64Gamma`, with `len` checked too.** Add
   `seq-int.len` and `seq-bool.len` to `int64Gamma`'s checked set
   (`Int64Checked` covers only `+`, `-`, `*` and `div` today), faulting on a
   length outside the range. The reference then faults wherever the VM
   traps, so overflow becomes an `expected-trap` with matching stacks, costs
   and traces up to the fault, the same as a zero divisor. The reference, the
   proofs and the VM share one registry, and the `LenOverflowAt` exception
   leaves `compileWords_correct` and `TargetHolds`, which then have only the
   call-depth bound as an exception. This needs:
   - progress for `int64Gamma` (`PrimitivesWellFormed`: its checked
     primitives are declared `faults := true`, so totality exempts them; preservation
     should follow from `adapterGamma`'s, since a checked delta either refuses
     or returns the same `Int` (inferred, not yet proved);
   - the runner switched to it, with a Gamma version bump so an old request
     is refused rather than run differently;
   - the reference runner refusing integer literals and starting-stack
     values outside the range, as the target boundary does
     (`TargetRun.lean`, the compiler's literal check). `int64Gamma` inherits
     `adapterGamma`'s literal typing, so without this a request starting
     from 2^63 still succeeds on the reference and is refused by the target;
   - the harness's `expected-portable-overflow` category retired or folded
     into `expected-trap`, with its planted-bug tests kept;
   - the S7-input wording in `docs/getting-started.md` changed (an S7 input,
     so outside an authoring window);
   - `adapterGamma` kept in `ProofRecords.allowedGammas` or retired, so
     existing records under either registry stay sound.
3. **Make the VM unbounded.** This was rejected: it gives up the fixed-width
   target the cost model and the compiler proof assume, for no program that
   needs it.

## Recommendation

Option 2. It is the harder change now and removes a category every
comparison tool would otherwise carry forever (rule 4). With `len` in the
checked set it also makes rule 12 true for integers without an exception:
the reference would define the arithmetic programs actually have. The
256-frame call-depth bound stays a VM resource limit the reference does not
model, as it is today; this decision does not change it. The easier option, keeping the split, would cost a permanent
second notion of agreement and a reference that answers questions about
values no program can hold.

Option 2 changes the reference registry, which is part of `Γ`.
`dec.comparison-primitives` treated a `Γ` change as needing the maintainer,
so this should be approved the same way before any code changes. The change
would land in its own PR, after progress for `int64Gamma` is proved and
outside an S7 authoring window.

## Approval

Not yet approved. The semantics section records what ships; the change in
option 2 waits for the maintainer's decision.
