---
id: res.host-language-tradeoffs
nodes: [firth.runtime.vm, firth.toolchain.compiler, firth.toolchain.diffharness]
sources: [src.firth-prd]
date: 2026-07-16
---

# Host-language trade-offs

This note compares candidate implementation hosts against the PRD's embedded target, permissive licensing, Lean verification boundary, fuzzing needs, and third-party reimplementation goal (PRD S6). Claims about toolchain integration are design research and remain unverified until a prototype validates them.

## VM candidates

- **Lean 4:** Excellent definitional alignment with the interpreter and proof reuse. Extraction and FFI are possible, but the generated runtime and dependency footprint are less obviously embeddable than a small C VM. Licence compatibility and portability require checking the exact generated artefacts. Third-party reimplementation from the VM specification would not require Lean, but a Lean implementation may make the reference implementation less portable. **Recommendation: not preferred for the production VM; validate extraction before rejecting.**
- **C99/C11:** Portable, small, embeddable, and compatible with permissive distribution. Mature sanitiser, fuzzing, cross-compilation, and bare-metal integration are strong fits for the embedded target. The cost is a foreign implementation requiring a conformance suite rather than direct Lean proof reuse. **Recommended VM default, pending maintainer ratification.**
- **Rust:** Strong memory-safety story and excellent fuzzing ecosystem, with good embedded support. The compiler/runtime and dependency policy can increase portability and build complexity for third-party reimplementers. Licence fit is generally permissive, but every dependency must be audited. **Credible alternative.**
- **Zig:** Simple cross-compilation and C interoperability suit embedded deployment, but its ecosystem and long-term toolchain stability are less established than C or Rust. **Exploratory alternative; claims require prototype validation.**

## Compiler and differential harness

Lean 4 maximises reuse of the typed kernel, reference semantics, and proof artefacts, and keeps compiler correctness work near the Lean TCB (PRD R8). An external host such as Rust or C may improve integration with native fuzzers and target binaries, but introduces a larger translation boundary and duplicate data models. **Recommended default: Lean 4 for compiler and diffharness, with external fuzzing tools allowed at the process boundary.** This recommendation is proposed, not ratified.

## Open validation work

A prototype must measure Lean extraction/FFI, C/Rust/Zig cross-compilation and embedding, licence manifests, fuzz-driver integration, and conformance-test ergonomics before the host decision is accepted.

## Sources and verification status

Accessed 2026-07-16.

- Lean 4 official FFI reference: https://lean-lang.org/doc/reference/latest/Run-Time-Code/Foreign-Function-Interface/ . Verified claim: Lean documents C FFI declarations and runtime interoperation. Exact extraction size, embedded suitability, and ABI performance remain prototype-dependent.
- Lean 4 official development FFI guide: https://github.com/leanprover/lean4/blob/master/doc/dev/ffi.md . Verified claim: native foreign symbols and linking are part of the supported development model; version-specific Lake wiring remains to validate against the selected release.
- Rust Embedded Book: https://docs.rust-embedded.org/book/ . Verified claim: Rust supports `no_std` embedded development; suitability for Firth's minimal VM still depends on chosen target and dependency policy.
- cargo-fuzz documentation: https://rust-fuzz.github.io/book/cargo-fuzz.html . Verified claim: Rust has an established libFuzzer-integrated workflow; comparative throughput and process-boundary integration remain unmeasured here.
- Zig official documentation: https://ziglang.org/documentation/0.16.0/ and Learn page https://ziglang.org/learn/ . Verified claim: Zig documents cross-platform tooling and C interoperability; long-term stability and ecosystem maturity are judgement calls requiring project validation.
- C language standard overview: https://www.iso.org/standard/74528.html . Verified claim: ISO C17 is standardised; the recommendation here targets the portable C99/C11 subset and must validate compiler/library assumptions per supported embedded target.

Licence statements and third-party reimplementation implications must be checked against the exact dependency manifests and VM specification conformance suite before acceptance.
