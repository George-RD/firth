# Proposal: differential-execution

Implement `todo.language-04-differential-execution` (PRD G6/R5/S2) using the
existing checked source, compiler, Lean reference and Rust VM adapters.
The current strategy document is not executable evidence.

Scope: deterministic typed source generation, bounded real adapter execution,
strict portable observation comparison, retained failure records, replay,
bounded type-preserving shrinking and a small CI seed matrix.

This does not authenticate SMT results or compiler evidence, prove compiler
correctness, establish effectful equivalence or complete the sustained S2
campaign. PR #109's other acceptance blockers remain open.
