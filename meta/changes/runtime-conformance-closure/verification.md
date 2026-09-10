# Verification: runtime-conformance-closure

Date: 10 September 2026. Parent: `todo.language-03-runtime-conformance`.
Scope: branch verification of the conformance comparison closure and the
execution and transport bounds, not baseline acceptance on `main`.

## Candidate identity

- Base: `80a9d41f3895b25793c7c4c37f1ec60bb29f10ef` (head of PR #109).
- Toolchains: Rust 1.93 per `rust-toolchain.toml`, Lean 4.30.0 via `lake`,
  Python 3.11, Cairn 0.9.0. All runs below were made in this worktree on a
  four-CPU host shared with other agents, in unoptimised (`dev`) builds.
- The frozen inputs are unchanged: `src/runtime/vm/fixtures/kernel.tsv`,
  `examples/**`, the four pinned MVP applications and their transcripts, the
  differential generator recipe and seeds, `docs/firth-agent-guide.md` (its
  SHA-256 is pinned by `tools/loop/mvp_agent_manifest.toml`, so the guide was
  not edited even where the plan named lines in it) and every Lean source.

## Failing-before reproductions on the unchanged head

Every reproduction ran against the base commit before any product line was
changed: the Rust probes as a temporary integration test using only the
unchanged public API (source archived with the evidence, not committed), the
CLI probes against the base `target/debug/firth-vm` through a Python driver
recording elapsed time and exit status, and the Python probes against
`git show 80a9d41:tools/loop/mvp_agent_gate.py` and `firth_run.py`.

| Gap | Reproduction on `80a9d41` | Observed |
| --- | --- | --- |
| G1 | `observe_image` of `1 quote` and `2 quote`, compared | both stacks `quotation-many`; verdict `Agree` |
| G2 | `4 [drop] dip` against `5 [drop] dip` (stack-fault inside the dip) | both frames `main@2;main@0`; verdict `Agree` |
| G3 | `vm-run` of `42 quote` | stack `[{"kind":"quotation","usage":"many"}]`, no body or capture |
| G4 | `execute_diagnostic` of three literals | trace costs `[1, 2, 3]` |
| G6 | `vm-run` self-recursive `main`, fuel 4096, 2 MiB stack (`RLIMIT_STACK`) | `thread 'main' has overflowed its stack`, SIGABRT (status -6) after 0.16 s |
| G6 | same request, fuel 1024, default 8 MiB stack | SIGABRT after 36.76 s |
| G6 | same request, fuel 64 (control) | `fuel-exhausted` observation, exit 0, 0.03 s |
| G7 | `vm-run` of a 4096-literal word at fuel 4096 | killed at the 120 s deadline, no answer (the plan's idle-host measurement was 10.6 s; three probes shared the host here) |
| G9 | `vm_run` at fuel 100000; Python `compare(fuel=100000)` | both accepted |
| G10 | `vm-run` of an 80,000-member object of 880,001 bytes | 65.33 s before the refusal `request: unknown member`, above the gate's 60 s adapter timeout |
| G11 | `parse_json("\"\\ud83d\\ude00\"")` | `Err(Malformed)` while the raw UTF-8 spelling parses; `vm-run` refuses the request as `malformed-json` |
| G12 | nested `push-quote` with a literal innermost | depth 8 accepted, depth 9 refused `depth-limit` |
| G13 | `firth-vm run /dev/zero` under a 1.2 GB address-space cap | buffered until allocation failed: `cannot read image` after 3.27 s |
| G13 | `vm-run` fed from a writer until the pipe broke, same cap | 1,073,807,360 bytes (1024.1 MiB) accepted before the child died |
| G14 | `push-quote` operand without `kind` and with an extra member | accepted and executed |
| G15 | `push-quote` with `captures:[1]`, `consumed:[true]` | accepted and executed |
| G17 | `render_json` of backspace and form feed | rendered as `\u0008\u000c` rather than the minimal `\b\f` |
| G5 | Python `compare` on `1 drop 2` (reference) against `2 1 drop` (target) with cumulative VM event costs | returned without error: a false agreement |
| (c) | `firth_run.main(... --stack "[[[...")` with 100,000 levels | `RecursionError` escaped `main()` instead of a JSON error |

Evidence: `probe-before.log`, `probe-before-2.log`, the `before-*.json` driver
records, `python-before.log` and the request files, kept under the session
scratch directory `agent-scratch/impl-language-03/before/` (SHA-256 of the
driver records: recursion 2 MiB `61d02cb5…`, recursion fuel 1024
`2306b05d…`, flat word `f519750c…`, object `5b1e8d3a…`, `/dev/zero`
`e63c3ec4…`, surrogate `720a0182…`; Python probe log `2fb31075…`).

## Native frame measurement and the depth cap

Fuel `F` drives exactly `F` administrative frames for `: main main ;`, so a
binary search on the largest fuel that exits normally under `RLIMIT_STACK`
measures the frames a native stack holds. With the bounded checkpoint alone,
127 fuel (128 frames) was the exact capacity of a 2 MiB stack, about 16.5 KiB
per frame, so pinning 128 against a 2 MiB thread would have had no margin.
After splitting the executor into per-opcode step functions, so only the
active path's temporaries occupy the stack, a 2 MiB stack holds 434 frames on
the `CALL_WORD` path (about 4.8 KiB per frame), about 440 on `CALL`, about
403 on `IF`, and about 389 on `DIP` (about 5.4 KiB, the worst path). The plan
allowed raising the constant if the refactor made 256 fit: `MAX_CALL_DEPTH`
is 256, the worst path needs about 1.4 MiB of a 2 MiB thread, and
`tests/bounds.rs` pins exactly that depth on both the `CALL_WORD` and the
`DIP` path inside a 2 MiB thread.

## Candidate results

Rust, from `src/runtime/vm`:

- `cargo fmt --check`: passed.
- `cargo clippy --locked --all-targets -- -D warnings`: passed.
- `cargo clippy --locked --no-default-features -- -D warnings`: passed.
- `cargo test --locked`: all suites passed (unit, binary, bounds, cli,
  ingress, lifecycle, observations, projections; counts in the final run
  section below).
- `cargo test --locked --no-default-features --lib --test bounds --test
  observations --test projections --test ingress --test cli`: passed. The
  whole-crate `cargo test --no-default-features` does not compile on the
  unchanged head either: `tests/lifecycle.rs`, untouched here, imports
  std-only items unconditionally, which is why CI runs the no_std library
  Clippy and the ingress gate rather than the full suite in that configuration.

Python and gates, from the repository root (`lake build` completed first):

| Check | Result |
| --- | --- |
| `tools/loop/test_*.py` (18 suites) | all passed, including the new `test_s5_envelope.py` (11), the extended `test_portable_observations.py` (29), `test_mvp_agent_gate.py` (33) and `test_diffharness.py` (39) |
| `check_mvp_agent_inputs.py` | ok, with `extensions = ["frames","trap_subcode","verification"]` on `[entry_point.vm_run.response]` |
| `mvp_agent_gate.py` | ok: `literal-int` and `add-one` `trace_comparison: agreed`; `quotation-call` and `conditional` `unsupported-quotation-values` |
| `check_language_examples.py` | ok: 10 successful cases (7 `agreed`, 3 `unsupported-quotation-values`), 7 refused cases, 2 documented commands |
| `check_trust_boundaries.py` | ok, 24/24 (no case relied on a consumed bit being accepted) |
| `check_compiler_admission.py --no-build` | ok, 45/45 |
| `check_s5_envelope.py` | ok: result 4, kernel cost 25, target cost 31, envelope 40; both branches proved from both traces (`handlers: handle-ping, handle-pong`, conditions `false, true`); the one-branch negative control refused; `trace_comparison: unsupported-quotation-values` |
| `harness.py run --seed 0 --seed 1 --seed 20260909 --cases 24` | ok: 72/72 agreement, `trace_comparisons: {"unsupported-quotation-values": 72}` (every generated case begins with `[ ] [ dup drop ] if`) |
| `check_failure_roundtrip.py` | ok: `bounded-fuel-inconclusive` reproduced, shrinking accepted 9 of 9 attempts |
| `check_runtime_ingress.py` (std and `--no-default-features`) | ok, 20/20 each |
| `check_runtime_bounds.py` (std and `--no-default-features`) | ok, 3/3 each: recursion `passed` within 60 s, flat word and maximal object `passed` within 30 s |
| `check_runtime_bounds.py --expect-vulnerable` on the unchanged head | see the final run section |
| `check_kernel_fixtures.sh` | ok (`lake exe firthVmFixtures` output byte-identical to the frozen corpus) |
| `coverage.py --validate` | ok |
| `cairn scan`, `cairn hook all` | zero errors, exit 0; the pre-existing warnings are retained (see deviations for the oversized-file note) |
| `git diff --check` | clean |

Empirical validation of the trace projection: the per-event rule (reference
events with positive cost against VM events with positive kernel charge,
equal lengths, equal per-index charges, then exact scalar stacks) disagreed
on no real program across the four MVP applications, the ten documented
examples, the 72-case campaign, the S5 witness and its negative control, and
the 24 trust-boundary cases. The `quoted-value`, `quotation-call`,
`conditional`, `choose-increment` (via `main`) and S5 programs are labelled
unsupported because their intermediate stacks hold quotations; the label is
recorded, never counted as agreement.

## Deviations from the plan

1. `MAX_CALL_DEPTH` is 256, not 128, under the plan's own clause, on the
   measurement above; the executor was split into per-opcode step functions
   (`execute_steps.rs`) because without it no depth fitted a 2 MiB thread
   with margin.
2. The adapter no longer counts nesting itself. The plan said to pass
   `depth` rather than `depth + 1` and let the decoder be the authority at
   33; an adapter counter at `MAX_NESTING` would still have refused depth 33
   before the decoder, so the transport bound (`3 * MAX_NESTING + 8`) is the
   only bound on the adapter's recursion and the decoder alone refuses depth
   33 (`invalid-image`, `malformed-instruction`), as the test asserts.
3. `tests/bounds.rs` names the bounds by value and traps by their stable
   codes so the gate's `--expect-vulnerable` mode compiles against the
   unchanged head; `tests/projections.rs` ties the values to the constants.
4. Gate deadlines are 30 s (flat word, maximal object) and 60 s (recursion)
   rather than 3 s: the fixed cases finish in a few seconds in an unoptimised
   build on this shared host, while the unchanged head exceeded 120 s and
   took 65 s respectively, so the deadlines still separate the two.
5. `trap_subcode` is the empty string on a trap whose class has no subcode
   and `null` on success, mirroring `trap`.
6. The `[comparison]` table was kept and bound rather than deleted:
   `verify_contract` refuses a manifest whose table differs from
   `COMPARISON_CONTRACT`, and `compare` refuses any contract argument other
   than that table, so no flag can weaken the comparison; unit tests mutate
   every key.
7. The S5 branch witness follows the coordinator's later instruction (mangled
   handler names matched positionally and required as VM trace words) and
   additionally requires both hosts to have selected on `true` and `false`.
8. Five VM files crossed the 500-line guideline and were split along the
   crate's `include!` seams (`adapter_response.rs`, `conformance_render.rs`,
   `conformance_observe.rs`, `execute_steps.rs`, `tests_adapter_payloads.rs`,
   `tests/projections.rs`); the moves changed no line.
9. The probe's maximal object is 880,001 bytes, not the plan's 960,018;
   both are under the 1 MiB bound and the effect is the same.
10. A `vm-run` response at the depth cap carries every event's frames and
    is several megabytes, larger than the bounded request parser admits, so
    the CLI regression locates its members textually. The size is bounded by
    `MAX_FUEL` events of at most `MAX_CALL_DEPTH` frames.

## Remaining limitations

There is no cross-host quotation normal form: quotation-valued stacks and
traces are labelled unsupported, not compared. Residual programs, frames,
words, instruction pointers and step counts are not compared across hosts.
The depth cap is a hosted-VM bound the reference lacks; the iterative
executor that would lift it is future work. Evidence digests remain
unauthenticated content identifiers and patch admission remains delegated to
the caller's verifier; every observation surface now says so, and
authenticated admission is tracked by `patch-refinement-evidence-admission`.
Deadline results are bounded regressions on one host, not timing guarantees.
Product-head CI and merged-main acceptance are separate claims.

## Final run

After the file splits, from `src/runtime/vm`: `cargo fmt --check` passed;
`cargo clippy --locked --all-targets -- -D warnings` passed; `cargo clippy
--locked --no-default-features -- -D warnings` passed; `cargo test --locked`
passed 162 tests (87 unit, 8 binary, 3 bounds, 14 cli, 20 ingress,
6 lifecycle, 15 observations, 9 projections); the no_std selection (`--lib`,
`bounds`, `observations`, `projections`, `ingress`, `cli`) passed 129 tests.
`cairn scan` reported zero errors and no oversized-module warning; `cairn hook
all` exited 0; `git diff --check` was clean.

`check_runtime_bounds.py --expect-vulnerable` was run against a `git archive`
of the unchanged head under scratch with the new `tests/bounds.rs` and a copy
of the gate (its `git rev-parse` replaced by a literal, since the archive is
not a repository): status `ok` in baseline mode, that is, on `80a9d41` the
flat-word case and the maximal-object case exceeded their 30 s deadlines and
the recursion case aborted with SIGABRT (`thread '<unknown>' has overflowed
its stack`), while the same three cases pass on the candidate in both VM
configurations.
