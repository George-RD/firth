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
