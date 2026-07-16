# Firth (working name)
## Product Requirements Document, v0.1

### 1. Vision

Firth is a concatenative programming language in the Forth tradition whose programs carry machine-checked guarantees. It pairs the smallest viable runtime model in computing with the strongest available correctness tooling: source is elaborated through Lean 4, where types and proof obligations are checked, then compiled to a minimal Forth-class target for execution. The result is a language in which a running system can be modified one word at a time, with every change re-verified before it is swapped in.

The long-range thesis is that such a language is the natural substrate for large-scale machine-generated software. Concatenative programs compose by concatenation, word-level granularity keeps changes small and independent, and a mechanical checker rather than human review is the arbiter of correctness. These properties make contributions from many independent authors, human or machine, safe to combine.

The trajectory is deliberate: Firth starts where its guarantees are most valuable (embedded, safety-critical, and machine-generated code) and is designed from the outset to grow outward toward general software development. Nothing in the kernel forecloses breadth; generality is reached by expanding the library, targets, and tooling around an unchanged verified core, in the pattern of languages that generalised from a strong niche rather than launching broad and shallow.

Machine authorship is a first-class design constraint, not a hoped-for side effect. Concatenative languages are theoretically well suited to models but empirically difficult for them, because stack state is implicit and must be simulated. Firth resolves this by making machine state explicit and reasoning local everywhere: signatures state the stack, meaning never depends on distant context, and the toolchain speaks structured feedback designed to be consumed by an agent loop.

### 2. Goals

**G1. A provable core.** A kernel calculus of approximately a dozen combinators with fully specified typing rules and small-step operational semantics. Everything in the language desugars to this kernel. The kernel is small enough that its metatheory (type safety, determinism) can be mechanised in Lean.

**G2. Stack effects as mandatory, inferred types.** Every word has a machine-checked stack effect. Row polymorphism handles "the rest of the stack" so generic words typecheck naturally. Stack imbalance, the classic Forth failure mode, is a compile-time error.

**G3. Linear resource discipline.** Duplication and destruction of values are explicit operations. Resources such as handles, buffers, and hardware registers cannot be silently leaked or aliased. The stack is the ownership model; no separate borrow checker is required.

**G4. Optional refinement proofs.** Stack effects may carry refinements (for example, a word requiring a positive integer and guaranteeing a larger one), discharged automatically via SMT where possible and escalated to interactive Lean proof where not. Verification effort is progressive: untyped-feeling code at the low end, full functional correctness at the high end.

**G5. A tiny, live-patchable runtime.** Compiled output targets a minimal Forth-class VM. Individual words can be redefined in a running image. The defining workflow of the language is the verified live patch: redefine a word, re-check only its obligations, hot-swap it with the proof attached.

**G6. Semantics preservation.** The compiler from kernel calculus to target carries a mechanised proof, or a clearly stated path to one, that compiled programs preserve the semantics of their source. Until proven, the same property is enforced empirically through differential testing against a reference interpreter.

**G7. A verifiable cost model.** The kernel semantics admit a cost annotation so that bounds on execution time and memory can be stated and checked. Forth-class primitives make costs near-transparent, which is what makes real-time claims honest rather than aspirational.

**G8. Machine-native authorship.** The language is designed so that a model can write it correctly from local context alone. Four properties carry this goal. First, mandatory stack-effect signatures act as explicit machine state at every word boundary, so no author, human or model, ever infers the stack across distance. Second, local reasoning is a guarantee: a word's meaning is fully determined by its body and the signatures of the words it calls. Third, the norm is short words, with named locals as the sanctioned escape once stack manipulation exceeds a small depth; deep juggling is a lint, not a badge. Fourth, the toolchain is an agent interface: diagnostics are structured and machine-parseable, carry proposed fixes, and typed holes report the exact stack state at the hole. The checker's output is treated as a feedback signal for generation loops, and the language's regularity makes it strong training data for small specialised models.

**G9. A staged path to generality.** The verified kernel is the permanent centre; breadth arrives around it. Successive expansion targets are: embedded and control systems, protocol and systems components, general server-side development, and eventually mainstream application work as the library and target surface mature. Each stage is served by the same kernel, type system, and patch model; no stage requires semantic additions that would compromise the guarantees of the previous one.

### 3. Non-Goals

- **Breadth before depth.** Firth does not chase ergonomics parity with mainstream languages in its early life. Generality is an explicit destination (G9) but is reached by expanding around the verified core, never by weakening it. Any feature that would trade away kernel guarantees for surface convenience is out, permanently.
- **A new proof assistant.** Lean 4 is the verification layer and the permanent trusted base. Firth never reimplements or self-verifies its own checker.
- **Preserving legacy Forth compatibility.** The target is Forth-class in execution model, not ANS Forth conformance. Existing Forth code is prior art, not an input.
- **Whole-program object systems, garbage collection, or heavyweight runtimes.** The runtime stays small enough to audit and to embed.
- **Mandatory proofs everywhere.** Refinements and functional correctness proofs are opt-in per word. A program with only stack-effect checking is a legitimate program.

### 4. Scope

#### 4.1 Language

- Kernel calculus: combinator set, typing rules, small-step semantics, cost semantics.
- Surface syntax: Forth-flavoured, point-free by default, with named locals as pure sugar that desugars to the kernel.
- Type system: stack effects with row polymorphism, linearity, refinements.
- Quotations: first-class anonymous words enabling higher-order combinators (conditionals, iteration, mapping), with a sound typing treatment.
- Vocabulary layering: the language grows upward as dictionaries of words, from core through domain vocabularies to application-level words; every layer is words only, never new semantics, so all strata reduce to the same kernel. Users grow their own dictionaries; contracts make them portable; standard layers are curated from proven vocabularies rather than designed up front.
- Specification predicates as words: refinements are expressed using predicates that are themselves defined in the language (or the Lean layer beneath) and desugar to kernel terms, so specifications and programs share one source of truth and no informal meta-language exists.
- Naming grammar: a closed set of English morphemes with deterministic composition rules and a small fixed symbol set as affixes, so that correct names are derivable rather than memorised; conformance is lintable.
- Module and word visibility model suited to word-granularity change.

#### 4.2 Toolchain

- Elaborator: surface syntax to kernel terms, embedded in Lean 4; the point where types, linearity, and proof obligations are checked.
- Reference interpreter: a deliberately simple executable semantics in Lean, serving as the behavioural oracle.
- Compiler: kernel calculus to the Forth-class target.
- Differential test harness: fuzzed program generation with compiler-versus-interpreter agreement checking.
- SMT integration for refinement discharge.
- Agent interface: structured machine-parseable diagnostics with proposed fixes, typed holes reporting stack state, and queryable signatures, so that generation loops receive precise feedback rather than prose errors.
- Signature search: the dictionary is queryable by stack effect and refinement (in the manner of type-directed search), so words are retrievable by the shape of the transformation needed rather than by name; names function as retrieval keys and carry no semantics.

#### 4.3 Runtime

- Minimal permissively-licensed VM implementing the target semantics.
- Image model with word-level hot redefinition.
- Verified-patch protocol: the mechanism by which a re-checked word replaces its predecessor in a live image.

#### 4.4 Ecosystem surface

- Standard library written in Firth itself, specified and progressively verified.
- Language server and editor support sufficient for practical authoring.
- Specification documents for the kernel calculus and target VM, written to be reimplementable by third parties.

### 5. Requirements

**R1.** The kernel shall consist of a minimal combinator set such that removal of any element loses expressive power.
**R2.** Every surface construct shall have a defined desugaring to kernel terms; no surface feature may carry semantics of its own.
**R3.** Type checking shall be decidable and require no annotations beyond word-level stack effects; inference shall handle all intra-word typing.
**R4.** Linearity violations (implicit duplication or discard of restricted values) shall be compile-time errors.
**R5.** The reference interpreter shall be the definition of program behaviour; any divergence in the compiler is a compiler bug by definition.
**R6.** Compiled words shall be individually replaceable in a running image without restarting the system.
**R7.** A word replacement shall be accepted only if its stack effect and stated refinements are compatible with the word it replaces.
**R8.** The trusted computing base shall be limited to the Lean kernel, the SMT solver where used, and the VM; everything else shall be checked artefacts.
**R9.** Proof obligations shall be decomposable and independently checkable per word, so that verification is incremental with respect to change.
**R10.** All timing or memory claims shall be derivable from the stated cost semantics, not from measurement alone.
**R11.** A word's semantics shall be fully determined by its body and the signatures of the words it references; no construct may introduce untracked non-local effects.
**R12.** All diagnostics shall be emitted in a structured, machine-parseable form carrying location, cause, expected-versus-actual stack state, and where determinable a proposed fix; human-readable rendering is a view over this structure, not the primary output.
**R13.** The toolchain shall support typed holes that report the inferred stack state and obligations at the hole.
**R14.** Stack manipulation depth per word shall be lintable against a configurable threshold, with named locals as the sanctioned refactoring target.
**R15.** Every predicate used in a refinement shall itself be a defined word (or Lean definition) reducing to kernel terms; no specification construct may appeal to meaning outside the kernel semantics.
**R16.** The dictionary shall support search by signature: given a stack effect (and optionally refinements), return the words whose contracts match or subsume it.
**R17.** Word names shall be checkable against the naming grammar; violations are lints, not errors.

### 6. Success Criteria

- **S1.** Kernel metatheory (type safety, determinism) mechanised in Lean with zero admitted lemmas.
- **S2.** Zero behavioural divergence between compiler and reference interpreter across sustained large-scale fuzzing.
- **S3.** The verified live patch demonstrated end to end: a running image, a word redefined, obligations re-checked, hot swap completed, system state preserved.
- **S4.** The standard library self-hosted: written in Firth, checked by the toolchain, with a verified subset.
- **S5.** A non-trivial program (for example, a protocol handler or control loop) written, verified to a stated specification, and executed on the VM within a bounded cost envelope.
- **S6.** A third party able to reimplement the VM from the specification alone and pass the conformance suite.
- **S7.** Machine authorship demonstrated at a measured pass rate: a code model, given only local context (task, relevant signatures, diagnostics loop), produces words that pass all gates at a rate materially higher than it achieves on equivalent tasks in a mainstream language.

### 7. Risks and Open Questions

- **Quotation typing.** Sound and ergonomic typing of higher-order words is the hardest known design problem in typed concatenative languages; prior art (Mirth, Kitten, Cat) is instructive but not settled.
- **Proof search stalls.** Semantics-preservation proofs can wedge on mis-stated invariants far upstream. Mitigation is architectural: the smallest possible kernel, provable-shaped semantics, and proofs decomposed into an independently checkable lemma graph.
- **Readability at scale.** Point-free code degrades under heavy stack manipulation. Named locals as sugar are the escape hatch; whether they suffice for large programs is open.
- **Model fluency is engineered, not assumed.** Current models handle stack languages poorly out of the box. The design bets that explicit signatures, local reasoning, and structured feedback close the gap, with fine-tuning as reinforcement; S7 exists to test this bet rather than presume it.
- **Generality without dilution.** Each expansion stage (G9) will generate pressure for conveniences that erode guarantees. The non-goal on breadth-before-depth is the standing defence, but it requires governance to hold.
- **Patch compatibility semantics.** What exactly "compatible replacement" means for a word under refinement types (behavioural subtyping at the word level) needs careful definition.
- **Cost model fidelity.** The gap between the abstract cost semantics and real hardware (caches, pipelines) bounds the strength of real-time claims; the model must be conservative and say so.

### 8. Licensing Posture

Apache-2.0 for the toolchain and specifications; MIT/Apache-2.0 dual for the standard library, runtime, and any code emitted into user programs, so that compiled artefacts inherit no obligations. Development-time use of GPL Forth systems is acceptable for testing only; nothing GPL is bundled or linked.

### 9. Artefact Chain

This PRD is the top of a chain of increasingly binding documents. Each artefact is drafted, validated by the layer below it, and only then frozen.

1. **PRD (this document).** Goals, scope, requirements. Evolves by revision.
2. **Kernel specification.** The combinator set, typing rules, operational and cost semantics. Drafted from the PRD, validated by mechanisation, then frozen; changes thereafter are constitutional events, not edits.
3. **Lean mechanisation.** The kernel spec as executable mathematics: definitions, reference interpreter, metatheory (S1). This is the validation step for the spec; where mechanisation and prose disagree, the disagreement is resolved before freezing and the mechanisation becomes normative.
4. **Component specifications.** Elaborator, compiler, VM, patch protocol, agent interface; each written against the frozen kernel and verified or differentially tested per the requirements.

The kernel specification is the single point where care concentrates; every downstream artefact inherits its correctness or its mistakes.
