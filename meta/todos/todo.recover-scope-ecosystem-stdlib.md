---
node: firth.ecosystem.stdlib
status: done
created: 2026-08-10
---

# Recover Scope Ecosystem Stdlib


## Recovery evidence

- Branch: `loop/todo.scope-ecosystem-stdlib`
- Tip: `3a53bb25096698ab37fddf6598646f271b642555`
- PR state: PR #97 is `CLOSED` and unmerged at this tip; PR #96 is `MERGED` at an earlier tip.

The surviving branch contains one unmerged commit relative to `origin/main`. It changes `stdlib/core.firth` in four lines, replacing duplicate generic result labels with the explicit labels `copy-one`, `copy-two`, `exchanged-second`, and `exchanged-first`.

This recovery todo is blocked because the original `todo.scope-ecosystem-stdlib` is already done and PR #97 closed without merging. A maintainer must decide whether the preserved branch change should be retained or discarded.

Resolution (dec.split-todo-form migration, 2026-08-10): superseded. The four preserved stdlib labels (`copy-one`, `copy-two`, `exchanged-second`, `exchanged-first`) are present in `stdlib/core.firth` on `origin/main`, landed via PR #98.
