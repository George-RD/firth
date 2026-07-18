---
node: firth.runtime.vm
---

# Firth v0.1 VM target specification

Status: target contract for v0.1. This document is normative for the target
machine and is written so that an independent implementation can produce the
same observable results. The Lean kernel specification remains normative for
kernel behaviour; this VM is trusted but unverified, so a mismatch is a VM
defect, not a new language meaning.

## 1. Scope and invariants

The VM executes compiled kernel terms from the frozen
`files/firth-kernel-spec-draft.md`. Its only dynamic data structure is one
value stack. It has no observable return stack, environment, mutable variables,
garbage collector, scheduler, or implicit effect channel. Quotations are
values, and dictionary words are the sole source of recursion. Concurrency,
foreign calls, and effectful patch compatibility are outside v0.1.

An implementation may use private call frames or an instruction pointer stack
to implement bounded execution, but those are administrative state. They must
not be inspectable, serialised as language values, or alter the result of a
well-typed program. The observable state is the value stack, the active word
image, the terminal outcome, and the cost report.

## 2. Value and instruction representation

The target value algebra is:

```text
Value ::= Int(i64) | Bool(bool) | Bytes(bytes) | Quotation(Code[], Captures)
        | PrimitiveValue(tag, bytes)
```

`PrimitiveValue` is reserved for values declared by the shared primitive
registry `Gamma`; it is not a licence for host-specific values. The initial
registry must provide canonical serialisation and deterministic transitions.
Linear values other than `World` are represented by the registry's tagged
value form and are moved, never implicitly copied or dropped. Literal encoding
can produce only `many` base values. `World` is absent from the observable
`Value` algebra: the frozen kernel says that its token compiles to nothing. The
administrative stack nevertheless keeps one non-observable `WorldMarker` slot
wherever the erased kernel stack has a `World`, so generic `swap`, `dip`, and
`quote` remain total without pretending that the token has no stack position.
The VM also owns one opaque ordered `WorldState`; each effectful `PRIM`
receives and returns it through the primitive ABI. Neither marker nor state is
serialised as a language value.

A quotation is immutable `Code[]` plus an ordered vector of owned capture
slots. `PUSH_CAPTURE i` moves slot `i` onto the value stack exactly once. A
linear capture therefore makes the quotation linear and a second execution
traps with `resource-fault`; a many capture may be copied according to its
declared usage. This is the target representation of the kernel's quotation
ownership footprint.

The canonical encoding is the versioned, length-delimited wire format frozen
in §7. Quotation code uses the instruction encoding below recursively. Canonical encoding is for
images, traces, and differential comparison; pointer identity is never
observable. Unknown tags, truncated lengths, and trailing bytes are malformed
input traps.

The v0.1 instruction set is deliberately small:

```text
PUSH_LITERAL  literal
PUSH_QUOTE    QuotationCode
PUSH_CAPTURE  capture-index
DUP
DROP
SWAP
CALL
DIP
COMPOSE
QUOTE
IF
CALL_WORD    Name
PRIM         PrimitiveId
```

`PUSH_LITERAL` and `PUSH_QUOTE` are the target forms of kernel literal and
quotation construction. `PUSH_CAPTURE` is the one additional instruction
needed to make `quote` executable without cloning linear values. `CALL_WORD` resolves a dictionary name at execution
time. `PRIM` dispatches through the versioned deterministic `Gamma` registry.
There are no arithmetic, branch, load/store, return, or host-I/O instructions:
those are primitives or higher-level words, which keeps the trusted decoding
and dispatch surface auditable.

## 3. Total kernel lowering

Compilation is structural and deterministic. For a kernel atom `a`, `lower(a)`
is exactly one of the following instruction sequences. Concatenation lowers by
concatenating sequences in source order; an empty program lowers to an empty
sequence.

| Kernel atom | Target sequence | Required precondition and result |
| --- | --- | --- |
| `lit c` | `PUSH_LITERAL c` | Pushes `c`; `c` is a canonical many literal. |
| `[p]` | `PUSH_QUOTE lower(p)` | Pushes an immutable quotation. |
| `dup` | `DUP` | Duplicates the top many value; linear values trap. |
| `drop` | `DROP` | Removes the top many value; linear values trap. |
| `swap` | `SWAP` | Exchanges the top two values, preserving ownership. |
| `dip` | `DIP` | Consumes `v, quotation`; runs quotation below `v`, then restores `v`. |
| `call` | `CALL` | Consumes a quotation and runs it on the current stack. |
| `compose` | `COMPOSE` | Consumes two quotations and pushes their concatenation. |
| `quote` | `QUOTE` | Quotes the top value as a one-slot capture and `PUSH_CAPTURE 0`; moves ownership as specified by the kernel. |
| `if` | `IF` | Consumes `Bool` and two equal-effect quotations, running the selected one. |
| `w` | `CALL_WORD name(w)` | Resolves and runs the current definition of `w`. |
| `prim π` | `PRIM id(π)` | Applies deterministic `delta_pi` from `Gamma`, threading hidden `WorldState` linearly. |

The table is total over the frozen atom grammar. A compiler must reject an
unknown atom, unresolved word, or primitive outside `Gamma` before execution;
such rejection is distinct from a VM trap. `CALL_WORD` must not inline a word
in a way that changes hot-redefinition behaviour. `QUOTE` stores the value in
the resulting quotation's immutable capture slot and must not clone a linear
resource.

`COMPOSE` creates code `code1 ; code2` and capture vector `captures1 ++
captures2`. Every `PUSH_CAPTURE i` originating in `code2` is rebased to
`i + len(captures1)`; code1 indices are unchanged. Capture slots are consumed
according to their usage. Duplicating a many quotation deep-copies its many
capture values; duplicating a linear quotation traps with `resource-fault`.
These rules make quotation composition and copying independent of pointers.

Instruction decoding and dispatch are deterministic. For a given image,
instruction stream, stack, primitive registry, and fuel, there is at most one
next state. A VM may use threaded dispatch internally, but the instruction
semantics above are the conformance boundary.

## 4. Execution and outcomes

The abstract machine state is:

```text
Machine = (ActiveImageHandle, CallFrames, ValueStack, WorldState,
           Fuel, Cost, Trace)
CallFrame = (code, instruction_pointer, captures, continuation, word_entry)
continuation ::= Halt | Return(frame) | RestoreDip(saved-slot, frame)
```

`ActiveImageHandle` is an atomic pointer to an immutable image snapshot. At
each step the VM fetches from the current `CallFrame`, checks operands and
stack shape, charges its target cost, then performs its transition. A terminal
result has no remaining frames or code and reports the final stack in
bottom-to-top order. A word call resolves the current active image once and
pushes a frame retaining that immutable `WordEntry`; subsequent word calls
resolve the then-current active handle. Frames are administrative continuation
state, not a language return stack: they cannot be pushed, popped, inspected,
serialised as values, or affect a well-typed result except by implementing the
kernel rewrite. `DIP` uses `RestoreDip` to retain the protected value or
`WorldMarker` while its quotation runs, then restores it in the specified
position. `CALL_WORD` enters with `Return` to its caller; `CALL` and `IF` use
`Return`; the entry program uses `Halt`. All continuation tags and transitions
are fixed by this paragraph.

At terminal state, hidden `WorldMarker` positions are removed from the
reported stack. Any other linear resource left in the administrative stack is
a `resource-fault`, matching the kernel's conditional exact-once termination
obligation; a non-terminating or fuel-exhausted state may retain it.

For bounded observations, the VM serialises the complete residual frame stack
(word name, code digest, instruction pointers, capture states) in the trace.
Thus fuel exhaustion is replayable and corresponds to a definite residual
configuration, including the saved value for `DIP`.

Fuel is an explicit finite execution budget. The VM checks fuel before a step;
when none remains it returns `fuel-exhausted` with the current stack, cursor,
image version, and trace. Fuel exhaustion is not termination and is not proof
of divergence. The differential harness classifies dual equivalent-budget
exhaustion as `bounded-fuel-inconclusive`, never as agreement.

Traps are distinguishable terminal outcomes and include:

```text
malformed-instruction | unknown-word | unknown-primitive |
stack-fault | type-fault | resource-fault | primitive-fault |
fuel-exhausted | patch-fault
```

Malformed target data and invalid instructions are target faults. A well-typed
compiled kernel program must not produce the first three, `stack-fault`,
`type-fault`, `resource-fault`, or `primitive-fault` for a total registry
operation; if it does, the compiler or VM has failed. `resource-fault` is the
target classification for a moved linear capture or value being reused or
discarded. The differential harness may retain a more specific internal
subcode, but its cross-host class is `resource-fault`.
Allocation failure while creating a frame, quotation, capture copy, image, or
trace is also `resource-fault` with subcode `allocation-failure`; the VM must
leave the prior machine or image state unchanged at the failed allocation.
The VM must not turn a trap into a normal value or silently continue. Trap
payloads contain a stable code, instruction/word location, and relevant image
version, but never host addresses or secrets.

## 5. Cost accounting

The target supplies a concrete total table `kappa_vm` for every instruction,
primitive, and administrative word entry. Costs are non-negative integers.
The required v0.1 default is one unit for each listed instruction, one unit
for `CALL_WORD` entry, and the registry-defined `kappa_vm(prim)` for `PRIM`.
`DIP`, `CALL`, `COMPOSE`, `QUOTE`, `PUSH_CAPTURE`, and `IF` have no hidden additional semantic
cost beyond their dispatched instruction and the instructions they run.

The VM charges before transition and emits a breakdown by instruction, word
entry, primitive, and image version. A failed instruction still reports the
charged cost only if it passed decoding and validation; malformed bytes cost
zero. Implementations may expose wall-clock or allocation counters as
diagnostics, but those are not semantic cost.

The compiler records the kernel atom and source location in debug metadata, or
an equivalent sidecar, so the harness can aggregate target instructions back
to kernel atoms. Raw instruction counts need not equal interpreter steps. The
Lean interpreter remains the oracle for compositional `kappa`; target reports
are checked against this concrete table as required by `dec.diffharness-fuzz-strategy`.

## 6. Image format and word replacement

An image is a versioned immutable snapshot containing:

```text
Image {
  format_version: u16,
  image_version: u64,
  gamma_version: u64,
  words: Name -> WordEntry,
}
WordEntry {
  name: Name,
  erased_word_type: WordType,
  code: Code[],
  body_digest: Digest,
  kernel_evidence_digest: Digest,
  refinement_evidence_digest: Digest,
  generation: u64,
}
```

Names are canonical UTF-8 strings. `erased_word_type` is the kernel's
`WordType`, including usage annotations, and contains no refinements. The
elaborator's public contract `(WordType, Spec)` and its kernel-equality and
refinement evidence are carried in separate evidence digests, not interpreted
by the VM. Code is
immutable after publication; an image is therefore safe to retain for
rollback.

The verified-patch protocol has these hooks, in order:

1. **Prepare:** receive a replacement name, code, exact old/new erased
   `WordType`, replacement `Spec`, and evidence bound to the body digest and
   expected image version.
2. **Verify:** outside the VM, Lean/elaborator checks exact erased
   `WordType` equality, dictionary well-formedness, and behavioural
   subsumption of the replacement `Spec` by the old contract.
3. **Validate:** the VM checks encoding, referenced words/primitives, digest
   binding, and expected image version without executing the new body.
4. **Commit:** atomically publish a new image snapshot in which exactly one
   `Name -> WordEntry` binding changes. New `CALL_WORD` operations resolve the
   new entry; an in-flight call retains the entry it resolved on entry.
5. **Quiesce/reclaim:** old snapshots and code remain alive until no active
   call or retained quotation refers to them, then may be reclaimed.

The active image handle is separate from a machine's retained call frames.
Commit is all-or-nothing. Readers observe either the old or new binding, never
a partially updated entry. If any hook fails, the old image remains active and
the patch returns `patch-fault` with no semantic state change. Rollback
publishes the requested prior snapshot's contents as a new image with a fresh
monotonically increasing `image_version`; it never rewinds the version counter
or mutates an active entry in place. Publication first reserves the new
snapshot and validates allocation and digest work, so allocation failure also
leaves the old handle active. Reclamation is epoch based: an embedding reports
quiescence for calls and retained quotations, and an old snapshot is reclaimed
only after its publication epoch is quiescent. Image and patch APIs expose
image versions so traces identify which definition ran.

This implements the accepted `dec.patch-compatible-word-replacement` boundary.
Effectful replacements are not admitted by v0.1: equal `World` positions prove
linear threading only, and the proposed decision
`dec.gap-firth-runtime-patch-should-effectful-verified-patch-compatibility-use-an`
must be resolved before an effectful observational contract is added.

## 7. Conformance and auditability

The first conformance suite must include one deterministic witness for every
row in the lowering table and interactions covering nested quotations,
`dip`/`call`, `compose` ownership, both `if` branches, recursive word lookup,
linear `World` primitives, primitive faults, malformed instructions, traps,
fuel, costs, patch atomicity, in-flight calls, rollback, and reclamation
quiescence. Each witness states the initial image, `Gamma`, stack, program,
fuel, expected terminal/trap outcome, canonical stack, image version, and cost
breakdown.

The landed differential strategy in `dec.diffharness-fuzz-strategy` is the
agreement gate: deterministic seeded Lean generation produces checked kernel
cases, runs the Lean reference interpreter and the compiled Rust VM, and
compares status, residual program, canonical stack, deterministic hidden
`WorldState` observation, and classified traps. Both hosts use the same case-local `Gamma`,
dictionary, initial stack, `kappa`, and semantic fuel translation. Dual fuel
exhaustion is inconclusive; a one-sided exhaustion, unexpected trap, or
terminal mismatch fails. Rust conformance and differential failures are VM
defects even though the VM remains in the trusted computing base.

The canonical wire encoding is frozen for v0.1: unsigned integers use
little-endian LEB128; signed `i64` uses zig-zag LEB128; byte strings and
vectors are length-prefixed; maps are sorted by canonical UTF-8 key bytes; and
tags and opcodes use the declaration order in this document starting at zero.
`WordType` is encoded as its canonical UTF-8 grammar form with no whitespace,
and digests are SHA-256 over canonical body or evidence bytes.
`format_version` and `gamma_version` are mandatory in every image and trace.
Boolean is tag 1 followed by byte `0` or `1`; integer and byte tags follow the
value declaration order. Every instruction is its opcode followed by its
canonical operands: names and primitive IDs are length-prefixed strings,
capture indices are unsigned integers, and nested quotation code is a vector
of instructions followed by its capture vector. Capture state is a bitmap of
consumed slots plus canonical slot values; a `WorldMarker` has a dedicated
zero-payload tag and `WorldState` is represented only by the registry's
versioned canonical observation bytes. Trace records are vectors of
`(cost, image_version, word_name, code_digest, instruction_pointer,
canonical_stack, canonical_frames, outcome)` records. This fixes
cross-implementation identity while leaving Rust's in-memory layout
unconstrained.

The trusted implementation should therefore remain dependency-minimal and
reviewable: bounded LEB128 decoding, explicit bounds checks, no dynamic code
generation, no implicit host I/O, and no unsafe code unless a separately
reviewed implementation need is recorded. The VM may be built `no_std` with
an injected allocator and host adapters supplied only at the embedding layer;
the core must not require an operating system. Runtime and emitted artefacts
use the project's MIT/Apache-2.0 dual-licensing posture.

### Surfaced forks for v0.2+

- Choose the canonical effectful patch observation: World relation, event
  trace, or both, by resolving the registered proposed gap.
- Specify the process/FFI boundary and whether external effects receive a
  deterministic replay adapter.
