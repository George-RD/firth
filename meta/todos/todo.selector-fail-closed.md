---
node: firth.governance.loop
status: done
created: 2026-07-17
---

# Selector Fail Closed

Requires:

Harden `tools/loop/select_unit.py` so unsupported Markdown dependency forms fail
closed during validation and selection. Add synthetic regression coverage for
heading/list `Requires` forms and inline dependency blocking.
