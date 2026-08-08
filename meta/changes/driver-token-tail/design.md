# Design: driver-token-tail

Authority and rationale live in `meta/decisions/driver-token-tail.md`.

The token read is one awk pass keeping a 15-slot ring of non-empty,
CR-stripped lines. Acceptance:

- collect exact whole-line token matches within the ring;
- two distinct tokens -> print `AMBIGUOUS TOKENS` (not a token, so the
  driver's unknown-token arm stops rc 3);
- `LOOP EXHAUSTED` prints only when it is also the ring's newest line;
- otherwise print the single seen token; print nothing when none seen.

The clean-exit gate is unchanged and evaluated before the token: any
nonzero harness exit ignores whatever the tail says. Wedge accounting is
unchanged: only an observed `origin/main` tip move resets the window, so
a tolerated token cannot fake progress.

`test_driver_tokens.py` extracts the block exactly as the launch contract
does, stubs `git` (fetch/show/ls-remote with an advancing fake tip) and
the harness (canned per-iteration outputs and exit codes) on PATH, and
asserts the driver's typed exits across nine paths.
