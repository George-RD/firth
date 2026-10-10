---
node: firth.toolchain.agent
status: open
created: 2026-10-10
---

# Name the file of each warning in a program of several files

## Goal

`successJson` (`src/agent/Firth/Agent/ElaborateAdapter.lean`) flattens every
file's warnings (`LOCAL_DEPTH`, `STACK_JUGGLE`) into one `warnings` array of
word, code and range. The range is relative to the word's own file, but the
warning does not name that file. The elaborate response's `sources` maps each
word to its file, so a caller can join them, but `firth_run.py check` returns
the warnings without `sources`, so an author cannot tell which file a line
refers to. Diagnostics already carry their file's path
(`dec.multi-file-imports`); warnings should too.

## Acceptance criteria

- Each warning names its file's `source_path`, in the adapter or in
  `firth_run.py check`, and any schema listing the warning's members says so.
- A test with a warning in an imported file checks the path, and fails if the
  path is dropped.

## Traceability

Codex on PR #225 (`src/agent/Firth/Agent/ElaborateAdapter.lean`), found after
the PR was approved; filed under rule 15 to ride a later PR.
