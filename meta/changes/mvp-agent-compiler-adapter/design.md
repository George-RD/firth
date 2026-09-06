# Design: mvp-agent-compiler-adapter

## Approach

The compiler is four small layers, each independently checkable.

`Digest` is SHA-256 (FIPS 180-4) in pure Lean. The gate rebuilds applications
in an isolated workspace, so a compiler that shelled out to `sha256sum` would
make its output depend on the machine it ran on. It is checked against the
FIPS vectors.

`Target` is the frozen value and instruction algebra of `target-spec.md` §2
and the canonical encoding of §7: unsigned LEB128, zig-zag signed integers,
length-prefixed strings and vectors, opcodes and tags numbered in declaration
order from zero. This is the second implementation of a format the Rust VM
already implements, which is the point: the VM recomputes every `body_digest`
when it decodes an image, so a divergence between the two encoders is refused
at load time rather than executed. Test vectors taken from the Rust encoder
pin the agreement in the other direction, so a change to either side fails
fast.

`WordType` renders a checked scheme into the canonical erased word-type
string. The reasoning behind positional item labels, positional row renaming,
the always-emitted usage annotation, and the refusal to default an unresolved
inference variable is recorded in `dec.compiler-target-lowering`.

`Lowering` applies the §3 table, which is total over the frozen atom grammar,
and mangles source names into the target `Name` grammar. Three kernel forms
have no v0.1 target representation, and each is a structured compile failure
rather than an approximation: the `unit` literal, a `World` value pushed as
data, and the declared `send` primitive.

`Compile` is the adapter. It decodes kernel programs with
`Firth.ReferenceRun.decodeProgram`, the reference interpreter's own decoder,
so the two hosts cannot disagree about which programs are well formed while
claiming to be compared, and it rejects duplicate JSON members through
`Firth.Agent.rejectDuplicateMembers` so a malformed record fails closed the
same way at every adapter.

The optional `entry` request field selects a source word by name. It is required
for multiword requests and validated before lowering. A single-word request may
omit it because its entry is unambiguous. Source order does not determine
reachability: words can refer forward, backward, or recursively.

`debug_locations` is an index correspondence rather than an assertion: the §3
table emits exactly one instruction per atom, and `compileRequest` checks that
invariant per word before it will emit a response.

## Changes

ADDED:
- `src/compiler/Firth/Digest.lean`, `Target.lean`, `WordType.lean`,
  `Lowering.lean`, `Compile.lean`.
- `src/compiler/FirthCompileCli.lean` (`firthCompile`) and
  `src/compiler/FirthCompilerTest.lean` (`firthCompilerTest`).
- `meta/decisions/compiler-target-lowering.md`.
- Blueprint edges `firth.toolchain.compiler -> firth.toolchain.interpreter`
  and `firth.toolchain.compiler -> firth.toolchain.agent`.

MODIFIED:
- `lakefile.toml`: the `FirthCompiler` library, both executables, and
  `firthCompilerTest` in `defaultTargets`.
- `src/agent/FirthAllTest.lean`: run the compiler suite under `lake test`.
- `src/interpreter/FirthReferenceRun.lean`: `decodeProgram` is public so the
  compile adapter can share it. No behaviour changes.
- `specs/tcb-boundary.toml`: the compiler and its translator are implemented.
