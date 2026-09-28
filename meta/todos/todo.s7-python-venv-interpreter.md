---
node: firth.toolchain.agent
status: done
created: 2026-09-28
---

# Sandboxed Python under a virtual-environment interpreter

CodeRabbit on #134: `run_python` ran `sys.executable` inside the sandbox,
so an interpreter reached through a virtual environment's link (whose
`bin/` is not shown) could not start. Scoring refused (fail closed), and
each sandboxed `try` reported a failure the author would read as its own.

Done in the S7 rerun PR: the sandbox runs `realpath(sys.executable)` and
shows that directory when the system directories lack it. `test_isolation.py`
plants a venv link: unresolved, it fails to start; resolved, it scores.
