---
node: firth.toolchain.agent
status: open
created: 2026-10-11
---

# Give S7 Firth authors the standard library

The harder tier's scored run of 11 October 2026 gave its Firth authors no
standard library: `tier.py` scores each answer from a source root that holds
only that answer, so an `import` of `stdlib/` cannot resolve, and the prompt
said not to import (pinned in #244, after Codex's P1 finding there). Every
Firth author had to define each helper word it used, while the Python
authors had Python's builtins (`eval/s7/harder/runs/2026-10-11-scored/results.md`,
"Limits").

## Acceptance criteria

- The next tier stages `stdlib/` into each answer's source root, at the
  commit the authors' prompts were built from, and the prompt says which
  words it offers and how to import them.
- A planted answer that imports a stdlib word scores as a pass, and one that
  imports a word the stdlib does not export is refused.
- The run's notes record which stdlib version the authors saw.

## Progress

The first two criteria are met in `eval/s7/harder/tier.py`:
- `stage` copies `stdlib/` beside every Firth answer.
- The Firth prompt shows the library's files and how to import them.
- `test_harder.py` (`stdlib_staged`, `stdlib_prompt`) shows that an import of
  `stdlib/core.firth` runs and that a word the library does not export is
  refused. Its plants are a runner with nothing staged, a runner that
  accepts everything, and prompts with the note missing or misplaced.

Scored results record each stdlib file's hash in `eval_sha256`. The third
criterion stays open until the next run's notes say which version its
authors saw.

The library holds only `stdlib/core.firth`, whose five exported words are
stack shuffles, so staging it does not yet give a Firth author anything
like Python's builtins.
