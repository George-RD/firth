---
node: firth.toolchain.agent
status: open
created: 2026-09-30
---

# The checker's command line prints only the raw diagnostic envelope

Found while designing S7 run 12 (`eval/s7/runs/2026-09-30-check-tool/`),
where authors may run the checker on their own answers. When
`tools/loop/firth_run.py check` refuses a program, it prints one line of JSON.
That line holds the Python repr of every diagnostic envelope, including each
stack's `lean_repr`: a few hundred characters of message, hint and location
inside several kilobytes of internal terms.

The readable view that authors see is `compact` and `readable` in
`eval/s7/harness.py`. It shows code, word, `at: line L, column C`, message,
expected, actual and hint, for each word. It lives in the eval, not in the
toolchain. So run 12's arm B reaches the checker through
`harness.py check`, and a model using Firth outside the eval gets the raw
line.

To close: the toolchain gives a text form of its diagnostics, for example
`firth_run.py check --format text`, carrying at least the fields `readable`
shows. `harness.py` then uses that form instead of rebuilding it. Until then,
S7 results about authors running the checker describe the eval's view of its
output, not the command line's.
