# Run 10 pre-registration: is run 9's gain the toolchain or variance?

Written and committed before the first author starts. Nothing here changes
after the first answer is scored; any departure is reported as one.

## Question

Run 9 (`8ea4a1d`, counted samples 3, 12, 17 and 0 of 20) did far better
than run 8 (`4c379e0`, 0 each). Is that difference caused by the
toolchain and prompt changes between the two commits (#174 to #176), or
is it sample-to-sample variance?

## Design

- Two arms, 10 counted samples each, run fresh. Runs 8 and 9 are
  reported pilots and are not pooled.
  - Arm A: `4c379e0` (run 8's build and prompt), worktree
    `/home/user/firth-r8`, run dir `runs/2026-09-29-control/4c379e0/`.
  - Arm B: `8ea4a1d` (run 9's build and prompt), worktree
    `/home/user/firth-v9`, run dir `runs/2026-09-29-control/8ea4a1d/`.
  - Each worktree is detached at its commit and never fetched or checked
    out during the run. The prompt each arm reads is byte-identical to its
    pilot run's `prompt-firth.md` (checked with `cmp`).
- Author: `claude-haiku-4-5-20251001`, as an Agent-tool sub-agent with no
  API key, given run 8's and run 9's author, round 1 and round 2
  instructions word for word, with only the paths changed. Three answers
  per sample (first answer and two feedback rounds).
- Interleaving: samples start in the order A1, B1, A2, B2, ..., with at
  most four authors running at a time, two per arm. A void sample's
  replacement starts in the next slot of its own arm.
- Scoring: each arm is scored by its own worktree's harness and checker
  (`harness.py score --lang firth --tier mvp`), with the build warmed
  first. `4c379e0`'s harness predates #173 and does not stop on a
  toolchain failure, so after every score the results are searched for
  toolchain text (`toolchain:`, `lake: exit`, `cargo: exit`, "is not
  available"); a round with any is rescored before its feedback is sent.

## Validity of a sample

A sample is void, and replaced, if any of these holds:

- `audit_subagent.py --rounds 2 --lang firth` flags any call (exit 1).
  Both arms are audited with the same `audit_subagent.py`, main's at
  `74679f8` (blob `d36ebbb`, the same as at `8ea4a1d`), so the older
  audit at `4c379e0` is not used. `plant_audit.py` here shows it flags a
  read of the eval session's own tool results or task outputs, another
  sample's feedback, `Glob`, `LS`, `Grep` and `Bash`, and does not flag
  the allowed reads.
  The allowed calls are a `Read` of the arm's `prompt-firth.md` and of
  the sample's own `repair-1.md` and `repair-2.md`, a `Write` of the
  sample's own `answer-1.md` to `answer-3.md`, and the hand-back.
- Any `AGENTS.md` or `CLAUDE.md` the author was shown is not blob
  `7c89481` (`AGENTS.md`) or `43c994c` (`CLAUDE.md`), after the HTML
  comment lines Claude Code strips before showing them
  (`seen_agents.py` in this directory on the raw log, exit 0 and no `UNMATCHED`).
  Both arms must see run 8's `AGENTS.md`, so this holds even after a
  newer `AGENTS.md` merges to main. The blobs each author saw are kept
  per sample in `agents-seen.json`. The check reports `UNMATCHED` when
  given an older `AGENTS.md` blob as the expected one (`861808e`), so it
  can fail.
- The author did not write all three answers.

Void samples are reported with their scores and not counted. Samples
are numbered `haiku-firth-1` to `haiku-firth-10` in each arm in start
order; a replacement takes the next number (11, 12, ...).

## Outcomes

- **Primary:** the number of counted samples in each arm that pass at
  least one of the 20 tasks after round 2 (all cases of the task,
  `results-3.json`). Test: one-sided Fisher exact test, arm B greater
  than arm A, at alpha 0.05.
- **Secondary 1:** total tasks passed after round 2 per sample,
  one-sided Mann-Whitney U, arm B greater than arm A.
- **Secondary 2:** tasks passed in the first answer per sample
  (`results-1.json`), the same test. First answers see no feedback, so
  this separates the prompt's new paragraph from the new feedback.

## Reading the result

- Primary significant: the gain is attributed to the change between the
  commits, not to variance.
- Primary not significant: the result is reported as inconclusive, with
  both arms' counts and the p value. It is not reported as "no effect".
- Whatever the result, both arms' tables, the per-sample scores and every
  void sample are reported.

## Power

With true rates of 0.75 (arm B) and 0.15 (arm A) for passing at least
one task, the chance of p < 0.05 is 0.17 at 4 samples per arm, 0.62 at 8
and 0.81 at 10 (20,000 simulated draws, one-sided Fisher). The rates are
guesses from the pilots (run 9: 3 of 4; run 8: 1 of 6 including a void
sample), so the real power may be lower.
