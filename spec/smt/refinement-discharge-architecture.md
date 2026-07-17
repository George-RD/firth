# Refinement discharge architecture

Status: accepted architecture boundary; concrete predicate syntax and stack
representation remain subject to the type-system specification.

This document specifies the elaborator's refinement-discharge service. It
does not add refinements to the frozen kernel. The kernel still checks only
the erased `WordType` and executes kernel programs; the elaborator owns the
contract `(WordType, Spec)` and invokes this service for obligations generated
at word boundaries.

## 1. Obligation boundary

For a word with erased effect `W : Σin -> Σout`, the elaborator produces a
normalised specification `Spec = (Pre, Post, Totality?)`. A body check is a
Hoare-style obligation:

```
  Pre_body(stack_in) ∧ Sem(body, stack_in)  =>  Post_body(stack_out)
```

The implementation must also satisfy the public contract. For a replacement,
the elaborator separately requires exact equality of erased `WordType`, then
checks `Spec_new <=spec Spec_old` by implication. For pure words, the
subsumption obligations are at least:

```
Pre_old(x) => Pre_new(x)
Pre_old(x) ∧ Post_new(x,y) => Post_old(x,y)
Pre_old(x) ∧ Total_old(x) => Total_new(x)
```

where `Total(x)` means that the new implementation preserves the old
termination/totality promise. Any alternate convention requires a new
decision, not an implicit reversal.
The body obligation remains `Pre_new(x) ∧ Sem(body,x,y) => Post_new(x,y)`.
The SMT service receives only these refinement-level formulae and never
changes kernel typing. The tuple shape and syntax of `Spec` are provisional
until `firth.language.types` fixes the normative representation; this document
fixes the discharge boundary and invariants, not that upstream syntax.

SMT is the default backend for a decidable, quantifier-free fragment after
normalisation:

- booleans and equality/disequality;
- mathematical integers and linear integer arithmetic, with non-linear
  arithmetic admitted only when the selected solver reliably supports it;
- fixed-width bit-vectors when the word's declared semantics is bit-vector
  semantics;
- finite tuples and arrays only through the explicitly supported theory
  encodings; and
- applications of declared pure predicate/function words whose translations
  are total and have a registered SMT definition.

The fragment is closed-world. Quantifiers, recursion, higher-order values,
uninterpreted effects, floating-point semantics, opaque primitives, and
predicate words without a translation are outside it. An outside-fragment
obligation is not sent to SMT as an approximation. It is escalated to Lean.
Lean is also the backend for totality, semantic properties of predicate words,
non-linear or quantified reasoning not covered by the pinned SMT profile, and
any obligation whose translation would lose meaning.

Representative outcomes, using an effect `Int -> Int`, are:

| word body and contract | obligation | result |
| --- | --- | --- |
| `inc : x:Int -> y:Int` with `x > 0`, `y = x + 1` | `x > 0 ∧ y = x + 1 => y > 0` | SMT `unsat` after negation, discharged |
| `half : x:Int -> y:Int` with `y = x div 2`, requires `x > 0` | `x > 0 ∧ y = x div 2 => y > x` | SMT `sat`, for example `x=1,y=0`, counterexample is a failed diagnostic |
| `f : x:Int -> y:Int` with `P x`, where `P` is recursive or untranslated | implication containing `P` | deferred to Lean, never guessed by SMT |

`unknown`, timeout, resource exhaustion, malformed output, translation
failure, and a solver crash are all non-success. They produce a `deferred`
obligation, whether or not Lean escalation is available, and block word
acceptance until Lean succeeds or the source changes. Only a validated `sat`
countermodel produces a `failed` obligation. None of these outcomes becomes
proof evidence.

## 2. Predicate-word translation

Specification predicates remain ordinary Firth/Lean definitions and are
identified by a stable qualified word name plus a semantic version. The
translator consumes the elaborator's typed, normalised predicate IR, not source
text and not arbitrary kernel syntax. A predicate word may be translated only
if its declaration has a trusted registry entry containing:

1. its input/output sorts, once fixed by the type-system specification;
2. a total, pure SMT-LIB definition or a primitive theory operator;
3. the semantics profile and solver features it requires; and
4. the hash of the predicate definition and translation rule.

The initial sort mapping is `Bool -> Bool`, mathematical `Int -> Int`, and
declared finite enumerations to SMT datatypes or integer tags with generated
distinctness constraints. A Firth tuple becomes a fixed SMT tuple/datatype;
stack rows are not solver values, but named symbolic variables for the
individual refined stack slots. Linear `World` and other resources are not
translated as data. An obligation mentioning them is Lean-only unless a later
decision gives it a semantics-preserving model.

Pure predicate words inline or emit `define-fun` declarations in dependency
order. Recursive definitions are rejected by the SMT translator. Names are
quoted/generated from stable IDs, never copied from source identifiers. Every
SMT assertion carries an obligation label and the source-level word boundary
is retained in the manifest.

Theory selection is explicit in the query profile, for example `QF_LIA` for
integer arithmetic or `QF_BV` for bit-vectors. The translator must reject a
formula that requires a theory absent from the profile. It must not silently
coerce integers to bit-vectors or use an unsound abstraction.

## 3. Evidence and rechecking

Each discharge creates a content-addressed `DischargeRecord` containing:

```
obligation_id, word_id, body_hash, erased_word_type_hash, spec_hash,
callee_contract_hashes, predicate_definition_hashes, translation_rule_hashes,
translation_soundness_proof_hashes, vc_generator_version, normaliser_version,
normalised_formula_hash, smt2_hash, solver_id,
solver_version, solver_executable_digest, invocation_options, profile, result,
evidence_hash, toolchain_revision, and source location
```

The record is bound to the elaborated word and its body hash. A cache hit is
usable only when all inputs and the solver profile match exactly. Rechecking
recreates the formula from the typed IR, verifies the hashes and profile, and
reruns the selected checker. A stale, missing, or mismatched record is an open
obligation, not a cached success.

The v0.1 recommendation is to trust the pinned solver's `unsat` result within
the PRD's explicit TCB allowance, while recording optional unsat cores for
explanation and minimisation. Translation soundness is not silently trusted:
Lean must check a semantics-preservation theorem for the typed-IR normaliser,
VC generator, sort/theory encoder, each registered predicate translation, and
the final SMT-LIB serialiser before that pipeline is eligible for SMT. Their
translation-rule and soundness-proof hashes are included in the discharge
record. This keeps the translation pipeline and registry outside the TCB. An
alternative is to count them as trusted, but that conflicts with the
checked-artefact boundary and is rejected. An unsat core is not treated as a
certificate: it explains
which labelled assumptions participated, but independently checking it does
not establish unsatisfiability. A future certificate-producing solver or
independently checked proof certificate can reduce solver trust, but needs a
new decision defining the certificate format and checker. `sat` models are
evidence for failure and are never proof artefacts.

Lean escalation produces a separate `LeanProofRecord` containing the theorem
statement hash, imported predicate-definition hashes, proof term/module hash,
and Lean toolchain hash. The Lean kernel checks the proof term during
rechecking. Thus the TCB is Lean kernel + pinned SMT solver + VM for SMT
successes, and Lean kernel + VM for Lean successes, with the elaborator,
translator, cache, and diagnostic renderer outside the TCB because their
outputs are rechecked, including the Lean-checked translation soundness
bridges required above.

## 4. Diagnostics and user experience

Every obligation has a stable `obligation_id` and is surfaced through the
versioned diagnostic envelope from `dec.agent-diagnostic-envelope`. The
primary location is the word boundary that introduced the obligation. The
diagnostic includes `cause.kind = refinement`, `expected_stack` as the
contractual refined output, `actual_stack` as the body's inferred refined
output, and an obligation entry whose status is `failed` or `deferred`.

The opaque obligation `data` should carry, when available, the backend,
formula hash, solver result, timeout, model or unsat-core labels, and a stable
Lean-escalation state. It must not require clients to understand solver traces.
For `sat`, the model is rendered as a counterexample in `message_params` or
opaque data. For timeout/unknown/outside-fragment, the message distinguishes
"not decided" from "disproved" and proposes a Lean proof or a predicate
rewrite. Expected and actual stack states remain available even when the
failure is reported at a called word boundary. Multiple obligations are
grouped deterministically by `group_id` and sorted by their stable IDs.

## 5. Incrementality and operations

Discharge is per word and per obligation. The elaborator can reuse unchanged
word contracts and records, while a changed body, predicate definition,
transitive translation dependency, solver profile, or Lean revision invalidates
only affected records. A word-level SMT context may share immutable
declarations, but assertions and `push`/`pop` scopes are isolated per
obligation. No solver state is allowed to make one word's proof depend on
discovery order or on a prior word's asserted assumptions.

The service runs with bounded wall time and memory. A timeout returns a stable
non-success status and leaves the word unaccepted until Lean proves the
obligation or the source is changed. Parallel discharge is permitted when
records remain independently keyed and diagnostics are deterministically
sorted.

## 6. Solver posture

The initial implementation should use a permissively licensed, reproducible
SMT solver with a documented release pin, platform-independent SMT-LIB input,
and a declared feature/profile matrix. The solver binary, version, licence,
and invocation options are part of the toolchain lockfile and discharge
record. A solver upgrade invalidates records unless a compatibility decision
establishes identical semantics and evidence handling. The architecture does
not mandate a particular solver before benchmarking and licence review; the
profile and pin are mandatory. GPL-only components are not bundled, consistent
with the PRD licensing posture.

## Open forks

1. **Evidence model:** trust solver `unsat` results (recommended for v0.1,
   because R8 explicitly permits SMT in the TCB and keeps the implementation
   small) versus require independently checked certificates (stronger audit
   story, but adds a certificate format, checker, and another governed
   component). This design records unsat cores but deliberately does not call
   them certificates.
2. **Solver selection:** choose the first permissively licensed solver after
   the profile benchmark and licence audit. Pinning and exact-profile
   reproducibility are decided now; the concrete binary is intentionally open.
3. **Effectful refinements:** model `World` in SMT versus keep it Lean-only.
   Keep it Lean-only for v0.1 because the frozen kernel excludes refinement
   semantics for effects and the patch decision leaves effectful observational
   compatibility open.
4. **Upstream representation timing:** freeze the concrete `Spec` and stack
   refinement syntax now versus wait for `firth.language.types`. Wait is the
   recommendation: this design fixes the backend contract, evidence rules,
   and failure semantics while leaving the syntax and sort inventory open.
