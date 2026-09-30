---
id: dec.comparison-primitives
nodes: [firth.language.kernel, firth.toolchain.interpreter, firth.runtime.vm]
status: accepted
related: [dec.agent-development-rules]
date: 2026-09-30
---
# `<=`, `>` and `>=` are Gamma primitives

## Context

Until Gamma 0.7 integers compared only with `prim <` and `prim =`. In the S7
authoring eval's run 11 (`eval/s7/runs/2026-09-29-locals-guide`), the most
common cause of failure was the comparison at equal values: 29 answers that
checked gave wrong results at the boundary (cause inferred, #188), and 9 more
wrote `prim <=` or `prim >`, which did not exist. #192 answered the second
group with a diagnostic that rewrote each comparison with `prim <`, `swap` and
`prim not`. That kept the language as it was, but every author still had to
build `<=` out of `<` and `not`, which is where the boundary mistakes come
from, and a library word could not stand in: `<=` is not a legal word name,
and there are no cross-file imports.

The kernel calculus is parameterised by its primitive signature `Γ`
(`files/firth-kernel-spec-draft.md`), so this adds entries to `Γ`; it changes
no typing or reduction rule and no metatheorem statement.

## Decision

Gamma 0.8 (target Gamma version 8) adds three pure, total primitives, each
`Int Int -- Bool` on signed integers:

- `a b prim <=` (`leInt`): whether `a` is at most `b`;
- `a b prim >` (`gtInt`): whether `a` is greater than `b`;
- `a b prim >=` (`geInt`): whether `a` is at least `b`.

The reference interpreter, the linearity contract, preservation
(`defaultGamma_primitivesWellFormed`), the program-logic rules (`runs_le`,
`runs_gt`, `runs_ge`) and the VM registry carry them. #192's rewrite hint is
removed, since the words it said did not exist now do.

## Approval

George chose "Add them" on the project-chat decision card "Add <=, > and >=
comparison primitives to Firth's kernel?" at 02:54 on 2026-09-30 (the other
option was "Checker hint only"), relayed to the Language core thread by the
project's coordinator.

## Consequences

- Every host bumps its Gamma version, so an image or request built for 0.7
  is refused rather than run under a different registry.
- The S7 eval inputs (`docs/getting-started.md`,
  `examples/programs/README.md`) list the new primitives, so the next S7 run
  measures a different language from runs 10 to 12.
