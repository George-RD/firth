---
id: res.host-language-tradeoffs
nodes: [firth.language.kernel, firth.toolchain.elaborator, firth.toolchain.interpreter, firth.toolchain.compiler, firth.toolchain.diffharness, firth.runtime.vm, firth.ecosystem.lsp]
sources: [src.firth-prd, src.lean-ffi, src.rust-no-std, src.rust-ownership, src.zig-toolchain, src.zig-interop, src.zig-release, src.iso-c]
date: 2026-07-17
---

# Host-language trade-offs

This note evaluates the ratified candidates against the VM's actual constraints: minimality and auditability, `no_std` and portability, a word-level hot-redefinition image whose code is data, atomic dictionary replacement, verified-patch protocol hosting, and the PRD's permissive licensing posture. It also records the separate host choice for the Lean-side toolchain. The assessment is architectural rather than a benchmark; target-specific costs and concurrency details remain obligations of the VM and image specifications.

## Fixed boundary

Lean 4 owns the elaborator, reference interpreter, and metatheory, with a zero-admit target. The VM is a separate trusted but unverified component: the PRD's TCB is the Lean kernel, the SMT solver where used, and the VM. Rust does not remove the VM from the TCB and does not make it verified. Its value is reducing memory-unsafety risk within that trusted component; semantic correctness, patch safety, and conformance still require specification, review, testing, and eventual verification work.

The image should represent executable words as VM instructions or other VM-defined code data, reached through dictionary entries. This makes a replacement an atomic publication of a new word object or dictionary binding, rather than native self-modifying code. A Rust implementation can provide the ownership and atomic primitives for that design, but the image and patch specifications must define reader quiescence, reclamation, and behaviour of in-flight calls. No candidate makes those protocol decisions disappear.

## VM candidates

### Rust: selected

Rust is a good fit for the small VM if the implementation stays `no_std`-first, uses a deliberately small dependency set, and keeps unsafe code at explicit FFI or target-boundary seams. Official Rust documentation confirms that `no_std` links `core` instead of `std`; allocation is optional through `alloc`, so a fixed arena or caller-supplied storage can avoid a general-purpose runtime. Ownership and borrowing reduce use-after-free and aliasing mistakes in the image, dictionary, and patch paths. This is risk reduction, not proof: safe Rust can still implement the wrong semantics, and any unsafe boundary remains in the trusted VM.

For the live image, Rust's atomics and ownership model are compatible with an indirection-based dictionary swap. The design must avoid treating native function pointers as reloadable code and instead publish immutable word data behind a stable dictionary binding. A fixed-capacity or explicitly supplied allocator can preserve minimality. This is a design constraint, not a material blocker.

Portability is credible across hosted and embedded targets, but a portable VM profile must pin the Rust edition/toolchain, target assumptions, panic strategy, atomics available, and dependency licence set. These are manageable specification and build-policy obligations. Rust's MIT/Apache-2.0 licensing and the primary authors' fluency also fit the PRD, subject to auditing every shipped dependency. Rust has no material blocker against minimality, portability, atomic word replacement, patch hosting, or licensing.

### C: not selected

C remains the strongest minimality and portability baseline. A small C implementation can use a flat instruction representation, explicit image storage, and C11 atomics for dictionary publication, and it has the broadest toolchain availability for third-party reimplementation. It also fits permissive distribution when the project controls its dependencies.

The decisive cost is that pointer lifetime, ownership, bounds, integer behaviour, and atomic publication correctness are manually enforced in a component already inside the TCB. Sanitizers and fuzzing improve confidence but do not change that risk boundary. C therefore satisfies the VM constraints, but carries more memory-unsafety risk and more review burden than the equally plausible Rust design. It is retained as a portable conformance or fallback implementation candidate, not the selected host.

### Zig: not selected

Zig has attractive properties for this VM: explicit allocation, no hidden control flow or allocation as a language goal, C ABI interoperability, and cross-compilation tooling. Those properties map well to a fixed image arena and a small patch protocol. Zig can therefore satisfy the shape of the runtime design.

The project would nevertheless take on a less established compiler, standard-library, package, and release-stability surface than Rust or C. Zig's own guidance distinguishes tagged releases from development builds for stability, which is a meaningful concern for a trusted, portable VM toolchain. Zig also does not provide Rust's ownership-based reduction of aliasing and lifetime mistakes. These are material project risks, but not a technical impossibility; Zig is not selected because its stability and safety trade-offs are weaker for this TCB-bearing component.

### Lean-hosted VM: not selected

Lean would maximise definitional reuse with the reference interpreter and metatheory, but it couples the production runtime to the proof-hosting environment and its runtime/FFI footprint. That works against a tiny, portable, independently reimplementable VM and gives the Lean host an unnecessarily large operational role. Lean remains the correct host for the elaborator, interpreter, and metatheory, not for the production VM.

## Compiler and differential harness

Lean 4 maximises reuse of the typed kernel, reference semantics, and proof artefacts. The elaborator, reference interpreter, and metatheory therefore remain Lean 4 with a zero-admit target. The compiler is Lean 4 code that emits the Rust-hosted VM target representation; the differential harness compares that output with the Lean reference interpreter. External fuzzing tools may drive the harness at a process boundary, but they do not move the trusted proof core.

## Language server

The initial LSP host is Lean 4. This keeps parsing and structured elaborator diagnostics close to the Lean-side toolchain while the LSP remains an ecosystem adapter, not part of the trusted computing base. The choice is deliberately narrower than the VM decision: the LSP may later be split into a Rust service if profiling or deployment needs justify it, provided it consumes checked artefacts and does not become a source of semantics. This satisfies the todo's LSP-host validation without coupling the production VM to Lean.

## Finding and disposition

The comparison found no material blocker for Rust on minimality/auditability, `no_std`/portability, the code-as-data image model, atomic dictionary swap, verified-patch protocol hosting, or licensing. The remaining risks are explicitly deferred to the VM target, image, patch, and build-policy specifications: storage/reclamation semantics, supported atomic targets, panic and allocation policy, unsafe-code budget, dependency audit, and conformance testing. Those risks do not justify keeping the implementation gate blocked.

## References and verification status

Accessed 2026-07-17.

- Lean 4 official FFI reference: https://lean-lang.org/doc/reference/latest/Run-Time-Code/Foreign-Function-Interface/ .
- Rust `no_std` reference: https://doc.rust-lang.org/stable/embedded-book/intro/no-std.html .
- Rust ownership chapter: https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html .
- Zig official home and cross-compilation claims: https://ziglang.org/ .
- Zig C interoperability and compilation model: https://ziglang.org/documentation/master/ .
- Zig release guidance: https://ziglang.org/learn/getting-started/ .
- ISO C revision history: https://www.open-std.org/jtc1/sc22/wg14/www/projects .

These references support language/toolchain capabilities. Exact image layout, atomic memory ordering, code reclamation, dependency manifests, and target support remain Firth design obligations rather than claims established by the references. The accepted architecture is not blocked by those open details; they are implementation and component-acceptance gates for the VM target specification and its conformance evidence.

For VM implementation and component acceptance, licence statements and third-party reimplementation implications must be checked against the exact dependency manifests and VM specification conformance suite.
