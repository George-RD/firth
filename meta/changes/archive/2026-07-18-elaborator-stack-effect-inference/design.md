# Design: elaborator-stack-effect-inference

## Approach

Represent algorithmic stack rows as a row tail plus bottom-to-top value types.
Fresh row metavariables are allocated from a monotonically increasing counter,
and substitutions are solved by structural unification with an explicit occurs
check. Dictionary and primitive schemes are instantiated at each reference;
quotation literals are inferred monomorphically and retain their inferred input
and output rows as required by the frozen kernel.

Check each located atom left to right, preserving its originating span. Report
the state immediately before the failing atom, plus expected and actual states
where applicable. A typed-hole API runs the same prefix checker and returns the
exact normalised stack state. Word bodies are checked against all declared
signatures at once, permitting self and mutual recursion.

## Changes

ADDED:
- `src/elaborator/Firth/StackEffect.lean`
- `src/elaborator/FirthStackEffectTest.lean`

MODIFIED:
- `src/elaborator/Firth/Erasure.lean`
- `src/elaborator/FirthErasureTest.lean`
- `src/elaborator/FirthElaborator.lean`
- `src/interpreter/FirthTest.lean`
- `lakefile.toml`
- `meta/todos/todo.elaborator-stack-effect-inference.md`

REMOVED:
- None.

RENAMED:
- None.
