---
node: firth.toolchain.elaborator
status: done
created: 2026-07-18
---

Requires: surface-syntax-spec pin-lean-toolchain

# Elaborator parser

## Objective

Implement the Lean 4 surface parser that converts the defined Forth-flavoured grammar into a located AST with deterministic source spans and explicit syntax errors. Refinement clauses are captured as located predicate token sequences until their concrete predicate representation is governed by the refinement/type work.

## Acceptance criteria

- Parse literals, quotations, word definitions, vocabulary visibility, stack-effect declarations, point-free sequencing, named-local syntax, and balanced refinement clauses from the landed surface specification.
- Preserve one-based half-open locations for every AST node and report malformed or unexpected input through stable parser error data.
- Add executable parser tests for representative valid programs, nesting, comments, locations, and malformed input; the implementation contains no `sorry`, `admit`, TODO placeholder, or unimplemented branch.

## Verification

- `lake build`
- `lake test`
- `! rg -n '\b(sorry|admit)\b|TODO|unimplemented|placeholder' src/elaborator`
- `git diff --check`

## Non-goals

- Do not erase named locals, infer stack effects, validate predicate meaning, discharge refinements, emit diagnostics envelopes, or construct kernel terms.
- Do not add an alternate grammar, implicit recovery semantics, or speculative source roots.
