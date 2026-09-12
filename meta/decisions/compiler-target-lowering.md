---
id: dec.compiler-target-lowering
nodes: [firth.toolchain.compiler]
status: accepted
related: [dec.mvp-gate-provenance]
informed_by: [src.firth-kernel-spec-draft]
date: 2026-09-03
---

# Compiler target lowering and its two new architecture edges

## Context

`todo.mvp-agent-compiler-adapter` asks for the `firth.compile.v1` adapter that
lowers checked kernel programs to the target image format. Implementing it
made two facts about the compiler's position explicit that the blueprint did
not yet record, and forced three representation choices that the frozen
contracts constrain but do not decide.

## Decision

### Two blueprint edges

`firth.toolchain.compiler -> firth.toolchain.interpreter`. The frozen kernel
term types (`Atom`, `Program`, `Value`, `Literal`) are defined in
`src/interpreter/Firth/Interpreter.lean`, which the blueprint assigns to the
interpreter module. A compiler that consumes kernel terms therefore depends on
the interpreter module, not only on the kernel module that specifies them.
The compile adapter also decodes checked-kernel records with
`Firth.ReferenceRun.decodeProgram`, the reference interpreter's own decoder,
so that the two hosts cannot disagree about which programs are well formed
while claiming to be compared.

`firth.toolchain.compiler -> firth.toolchain.agent`. The compile adapter is
one of the four entry points pinned by `tools/loop/mvp_agent_manifest.toml`,
and it speaks that manifest's structured JSON transport. It rejects duplicate
JSON members with `Firth.Agent.rejectDuplicateMembers` rather than carrying a
second copy of that scan, so a malformed record fails closed identically at
every adapter.

### Target word names are mangled, injectively

The frozen target `Name` grammar is `[A-Za-z_][A-Za-z0-9_]*` (target-spec §7)
and it gates the dictionary key, every `CALL_WORD` operand, every item name
and every base type name. Firth surface word names admit `-`, `?`, `!` and
`.`, so `literal-int` and `quotation-call` cannot be target names as written.

The compiler therefore mangles: `_` becomes `_u`, `-` becomes `_h`, every
other byte becomes `_x` followed by two lowercase hex digits, and a result
that would start with a digit is prefixed with `_d`. An underscore in a
mangled name is always a tag prefix, so the mapping is injective and two
source words can never claim one target name. The compiler checks that
anyway, and refuses a collision rather than publishing the second word.

The alternative, relaxing the target identifier grammar, was rejected: §7 is
frozen and the VM validates the same predicate in four places.

### Erased word types are rendered with positional labels and renamed rows

The canonical grammar requires a `Name ":" ValueType` label on every value
item, and the elaborator's checked scheme carries none: `stackFromItems`
discards the surface label. Labels are therefore synthesised positionally as
`v0`, `v1`, ... from the bottom of each stack. This is sound because the VM
only ever compares an erased word type for equality when admitting a patch,
so all that is required is that one checked word always renders to one string.
Recovering surface labels was rejected: a legal surface item name such as
`my-val` is not a legal target `Name`.

Row binders are likewise renamed positionally onto single Unicode scalars
(`ρ`, `σ`, `τ`, ...), because surface row names may be several characters
(`ρ2`) while a target `RowName` is exactly one scalar. The usage annotation is
always emitted even though the grammar makes it optional, because
`dictionary_digest` hashes these bytes and two spellings of one type would be
two different images.

An unresolved inference variable is refused rather than defaulted. Defaulting
an unsolved usage variable to `^many` would silently widen the published
contract.

### Three kernel forms have no v0.1 target representation

The `unit` literal, a `World` value pushed as data, and the declared `send`
primitive are each refused with a structured compile error rather than
approximated. The target value algebra (§2) has no unit; the frozen kernel
says the `World` token compiles to nothing; and the target registry has no
`send` implementation at `gamma_version` 1. Emitting something that would run
in place of any of them would put a claim into an image that the checked
program never made.

### SHA-256 is implemented in Lean rather than shelled out

`body_digest` is SHA-256 over a word body's canonical encoding, and the MVP
gate rebuilds applications in an isolated workspace. A compiler that called
`sha256sum` would make its output depend on the machine it ran on. The Lean
implementation is checked against the FIPS 180-4 vectors and, more usefully,
against the Rust encoder: the VM recomputes every `body_digest` when it
decodes an image, so a divergence between the two encoders is refused at load
time rather than executed.

## Consequences

- A compiled dictionary key is a mangled name, so a debugger or a patch
  producer must map back through `word_digests`, which is keyed by the source
  name.
- An application using `send` cannot be compiled until the target registry
  gains an implementation and a `gamma_version` that includes it.
- The Lean and Rust canonical encoders are now two implementations of one
  frozen format. They are pinned against each other by the byte vectors in
  `src/compiler/FirthCompilerTest.lean` and, at run time, by the VM's own
  digest check.
