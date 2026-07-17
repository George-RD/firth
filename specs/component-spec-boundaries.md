# Firth v0.1 component specification boundaries

Status: accepted boundary map for the component specifications listed in the
PRD artefact chain. This document is subordinate to the frozen kernel
specification and the VM target contract.

## 1. Boundary rule

The frozen kernel specification, `files/firth-kernel-spec-draft.md`, is the
semantic source of truth for v0.1. It owns the atom grammar, typing judgement,
linearity and quotation-usage rules, small-step transitions, dictionary
meaning, effects, and parameterised cost semantics. No downstream component
may add a language meaning by interpreting an implementation detail.

The component specifications describe checked artefacts and projections of
that kernel. A component is trustworthy when its required evidence exists and
its boundary conformance tests pass. It is not thereby added to the trusted
computing base. The v0.1 TCB remains the Lean kernel, the pinned SMT solver
where an accepted `unsat` result is used, and the VM. The reference
interpreter is the executable witness of the kernel semantics; the
differential harness detects disagreement rather than becoming a second
semantic authority.

## 2. Ownership map

| Component | Normative surface it owns | Inputs | Checked artefacts | Boundary conformance |
| --- | --- | --- | --- | --- |
| Kernel specification | Kernel syntax, types, ownership, transitions, dictionary layering, effects, and abstract cost `κ` | PRD requirements and accepted kernel decisions | Lean definitions, interpreter semantics, and zero-admit metatheory | Lean mechanisation agrees with every frozen clause; determinism, preservation, progress, linearity, and cost obligations pass |
| Elaborator | Surface-to-kernel elaboration and the public word contract `(WordType, Spec)`; typing, linearity, and proof-obligation generation | Surface syntax, type rules, frozen kernel, dictionary contracts, refinement architecture | Checked kernel term, erased `WordType`, normalised `Spec`, discharge records, and structured diagnostics | Accepted source elaborates only to well-typed kernel terms; each word's evidence is independently recheckable; no refinement is inserted into kernel meaning |
| Compiler | Implementation of the VM-owned deterministic lowering table, plus compiler rejection, metadata, and lowering evidence | Checked kernel terms, frozen kernel, VM target contract, `Γ`, and target `κ` | Target code, canonical operands, debug/source mapping, and lowering evidence | Every kernel atom is implemented according to the VM table; unknown inputs are rejected before execution; differential and VM conformance tests pass, with a future Lean lowering-preservation proof required for the G6 proof path |
| VM target | Concrete instruction set, values, encoding, execution outcomes, image and target cost contract | Kernel terms, `Γ`, `κ`, image and patch inputs | Deterministic lowering, canonical image/trace encoding, VM conformance witnesses | Third-party implementation passes the lowering, encoding, outcome, cost, resource, and patch-atomicity suite; a mismatch is a VM defect |
| Patch protocol | Admission and atomic publication of a word replacement in a live image | Elaborator `(WordType, Spec)` plus evidence, VM image/version and code digests | Exact erased-type evidence, refinement-subsumption evidence, VM validation result, immutable image transition | Replacement preserves exact erased `WordType`, dictionary well-formedness, and accepted `Spec` subsumption; publication changes one binding atomically |
| Diagnostic envelope | Versioned agent-interface wire format for diagnostics, typed holes, and signature search | Elaborator outcomes and refinement obligations | JSON envelope validation, stable codes and IDs, locations, opaque stack states, obligations and fixes | Payloads validate against `dec.agent-diagnostic-envelope`; ordering is deterministic; renderers consume the envelope and do not define semantics |
| Differential harness | Agreement oracle and reproducible failure classification | Checked kernel cases, interpreter, compiler, VM, shared `Γ`, `D`, initial stack, `κ`, and semantic fuel | Seeds, coverage data, canonical observations, traces, shrink results, and failure artefacts | Terminals, residuals, stacks, hidden `WorldState` observations, traps, and bounded outcomes agree under `dec.diffharness-fuzz-strategy`; dual fuel exhaustion is inconclusive |

The compiler is deliberately a producer of target code, not the owner of
kernel or target meaning. The VM target owns the lowering table; the compiler
implements it and owns compiler-side rejection, metadata, and evidence. It is
checked by VM conformance plus differential testing. The Lean reference
interpreter owns no independent component contract: it is the executable
kernel semantics used by the harness and by metatheory validation.

## 3. Cross-references and evidence

The dependency order is a partial order aligned with the implementation edges
in `cairn.blueprint`. Arrows below use Cairn's direction: `A -> B` means
component A requires prerequisite B.

```text
surface/type rules -> frozen kernel specification
reference interpreter -> frozen kernel specification
SMT boundary -> frozen kernel specification
elaborator -> surface/type rules, SMT boundary, frozen kernel specification
VM target -> reference interpreter
compiler -> frozen kernel specification, VM target
differential harness -> compiler, reference interpreter
agent interface -> elaborator
image model -> VM target
patch protocol -> elaborator, VM target, image model
```

These levels may proceed in parallel where the arrows permit it. In
particular, compiler work does not require elaborator implementation, the
differential harness requires only compiler and interpreter outputs, and the
patch protocol does not gate either compiler or harness work. The order
prevents a component from declaring conformance against an unfrozen upstream
contract; it does not add edges to the architecture graph. The relevant
binding references are:

1. The PRD artefact chain and requirements R5, R7, R8, R9, R10, R11, R12,
   R13, R15, and R16 define why these boundaries exist.
2. The kernel freeze decision makes the kernel prose normative and requires a
   governed decision for an erratum. The VM target specification consumes
   that freeze and states that a mismatch is a VM defect.
3. The elaborator consumes the frozen stack and usage rules. Its public
   contract is `(WordType, Spec)`, while the kernel dictionary stores only the
   erased `(WordType, Program)` pair. The refinement service follows
   `spec/smt/refinement-discharge-architecture.md` and
   `dec.refinement-discharge-architecture`.
4. The diagnostic envelope carries elaborator and discharge results without
   exposing kernel constructors, solver traces, or internal ASTs. Its wire
   compatibility rules are fixed by `dec.agent-diagnostic-envelope`.
5. The compiler lowers kernel atoms according to section 3 of the VM target
   specification. `CALL_WORD` must preserve hot-redefinition behaviour and
   must not inline across that boundary.
6. The patch protocol combines the elaborator's two proofs, exact erased
   type equality and refinement subsumption, with VM validation and atomic
   image publication. Pure and refinement-typed patches are covered by
   `dec.patch-compatible-word-replacement`; effectful observational
   compatibility remains outside v0.1.
7. The differential harness uses the Lean interpreter as the behavioural
   oracle and compares it with compiler plus VM. Its seeded generator and
   negative corpus follow `dec.diffharness-fuzz-strategy`. A differential
   failure is evidence of a compiler or VM defect, not permission to revise
   kernel semantics.

## 4. Conformance gates by boundary

### Kernel to Lean mechanisation

The definitions must match the frozen atom set, `Γ` versus `Σ` distinction,
quotation usage meet, `if` premises, administrative `push`, deterministic
primitive deltas, erased dictionary, World threading, finite-trace linearity,
conditional exact-once termination, and parameterised cost table. The Lean
gate is zero admitted proofs. A prose/mechanisation mismatch is recorded as a
governed kernel erratum before either side changes.

### Kernel to elaborator

For every accepted word, elaboration produces a kernel program whose inferred
`WordType` is the declared erased effect. Linearity and quotation ownership
are checked using kernel rules. Refinements and predicates remain outside the
kernel and are attached as `Spec`; each obligation is discharged by the
approved SMT fragment or Lean, with a content-addressed record. Unsupported,
unknown, timed-out, malformed, or unsoundly translated SMT work cannot count
as success.

### Kernel to VM and compiler

Lowering is structural and deterministic for every kernel atom. The VM and an
independent implementation must agree on canonical values, quotations and
captures, hidden World handling, traps, fuel, cost reports, image versions,
and trace encoding. The conformance suite includes one witness per lowering
row and the interactions named in the VM target specification. Well-typed
programs must not produce target faults reserved for compiler or VM defects.

### Elaborator to diagnostic envelope

Every payload first validates as a version `1.0` common envelope with stable
identity fields, supported `payload_kind`, and a body. Kind-specific checks
then apply: diagnostics require their location, cause, stack-state fields,
obligations, and proposed fixes when determinable; typed holes require their hole location, inferred
stack state, and obligations; signature-search requests and responses require
their query, paging, matches, and ranking fields instead. Sorting and
pagination are deterministic. A human-readable renderer is a view over this
payload and cannot change its meaning. Additive fields and enum values must
obey the decision's forward-compatibility rules.

### Elaborator and VM to patch protocol

Prepare binds the replacement body, contract, evidence, and expected image
version. Verify checks exact erased `WordType` equality, dictionary
well-formedness, and replacement-spec subsumption. Validate checks target
encoding, referenced names and primitives, digests, and image version without
running the body. Commit publishes exactly one new immutable binding or leaves
the old image untouched. In-flight calls retain their resolved entry.

### Interpreter, compiler, and VM to differential harness

For a checked case, terminal status, residual program, canonical stack,
deterministic World observation, and classified traps must agree. Costs are
checked against their respective `κ` views, not by requiring equal raw step
counts. One-sided fuel exhaustion, unexpected traps, and terminal mismatches
fail. Dual equivalent-budget exhaustion is retained as a reproducible
`bounded-fuel-inconclusive` result, not agreement.

## 5. Change control

The following are constitutional changes and require re-freezing the affected
boundary through a new accepted Cairn decision, with downstream evidence
re-run:

- changing kernel atoms, typing premises, usage or linearity, quotation
  ownership, operational transitions, dictionary meaning, World semantics,
  or abstract cost composition;
- changing the observable VM value/instruction model, canonical encoding,
  trap taxonomy, target cost contract, image publication atomicity, or the
  interpretation of a kernel-to-target lowering row;
- changing the meaning of `(WordType, Spec)`, patch compatibility, refinement
  subsumption, solver trust, or what constitutes discharge evidence;
- changing diagnostic required fields, the meaning of an existing code or
  enum, or the major version of the envelope; and
- changing differential equality, fuel classification, canonical observation,
  or the interpreter's authority.

The following are additive evolution within v0.1 when they preserve existing
meanings and are covered by conformance tests:

- new words, surface syntax that erases to existing kernel terms, and new
  well-formed dictionaries;
- new many-valued primitives or registry entries with deterministic deltas,
  canonical encodings, explicit costs, and both-host harness support;
- optional diagnostic fields, documented diagnostic codes, and documented
  additive enum values under envelope major version 1;
- new VM witnesses, seeds, shrinkers, and diagnostic renderings that do not
  alter existing classifications; and
- additional refinement predicates or supported SMT definitions whose
  translation soundness and hashes are recorded.

An additive change that cannot be shown to preserve an existing conformance
obligation is treated as a constitutional change. No component may silently
repair a discrepancy by weakening a test or by updating a downstream
specification first. The dependency order requires the upstream decision and
its evidence to land before dependent specifications or implementations are
changed.
