# Run 11 pre-registration: does steering authors to `locals` help?

Written and committed before the first author starts. Nothing here changes
after the first answer is scored; any departure is reported as one.

## Question

In run 10's counted samples, final answers with no shuffle words passed 94
of 228 times (41%), and answers with them 17 of 172 times (10%); the gap
held within all 17 tasks and 10 of 11 samples where it could vary
(`runs/2026-09-29-control/causes/behaviour.txt`). That is an association:
authors who avoid shuffles may simply be the stronger ones. Run 11 asks
whether telling authors to bind values with `locals` and not to shuffle the
stack raises how many MVP tasks Haiku passes.

## Design

- Two arms that differ only in one paragraph of the prompt.
  - Arm A: the prompt `harness.py prompt --lang firth --tier mvp --rounds 2`
    builds at the pinned commit, unchanged (`arm-a/prompt-firth.md`).
  - Arm B: the same prompt with `arm-b-paragraph.md` inserted as a new
    paragraph in `docs/getting-started.md`, straight after the paragraph
    that introduces `locals` and its input order (`arm-b/prompt-firth.md`).
  - `make_prompts.py --check` shows arm A is the harness's prompt and arm
    B differs from it by exactly that insertion; its self-test plants an
    extra word, a stale arm A and misplaced anchors, and each is caught.
  - Every claim in the paragraph was checked on the runner at `c5fa7f4`:
    `over` and `rot` are unresolved names; a nested block
    (`a a prim * locals { s } { s b prim + s prim + }` on 3 4 5 gives 22),
    an unused local and locals inside `if` branches all check and run.
  - All 20 MVP reference solutions (`eval/s7/reference/mvp/`) use `locals`
    and no shuffle word, so every task can be solved as arm B advises.
- Build: both arms use one worktree, `/home/user/firth-r11`, detached at
  main's head when authoring starts (the pinned commit), never fetched or
  checked out during the run. The run directory is copied into it from
  this PR's head. Both arms are scored by that worktree's harness and
  checker, so any `src/` change that merges during the run reaches
  neither arm.
- The committed prompts were built at `c5fa7f4`, and arm A's is
  byte-identical to run 10 arm B's `prompt-firth.md` (checked with `cmp`).
  At the pinned commit, `make_prompts.py` is run again; if either prompt
  differs from the committed one, authoring does not start and this file is
  amended and reviewed again.
- Author: `claude-haiku-4-5-20251001`, as an Agent-tool sub-agent (model
  `haiku`) with no API key, given run 10's author, round 1 and round 2
  instructions word for word with only the paths changed, and started
  with the description `Run 11 author <arm><n>` (such as `Run 11 author
  B7`). Three answers per sample: the first answer and two feedback rounds.
- Sample size: 20 counted samples per arm, not run 10's 10, because the
  power below is too low at 10. Authoring stops when both arms have 20
  counted samples; no test is run before then.
- Interleaving: samples start in the order A1, B1, A2, B2, ..., with at
  most six authors running at a time, three per arm. A void sample's
  replacement starts in the next slot of its own arm. Samples are numbered
  `haiku-firth-1`, `haiku-firth-2`, ... in each arm in start order; a
  replacement takes the next number.
- Scoring: `harness.py score --lang firth --tier mvp --jobs 4` in the
  worktree, with the build warmed first. The harness stops on a toolchain
  failure (#173); results are also searched for toolchain text
  (`toolchain:`, `lake: exit`, `cargo: exit`, "is not available"), and a
  round with any is rescored before its feedback is sent.

## Validity of a sample

A sample is void, and replaced, if any of these holds:

- `audit_subagent.py --rounds 2 --lang firth` flags any call (exit 1).
  The allowed calls are a `Read` of the arm's `prompt-firth.md` and of the
  sample's own `repair-1.md` and `repair-2.md`, a `Write` of the sample's
  own `answer-1.md` to `answer-3.md`, and the hand-back.
- Any `AGENTS.md` or `CLAUDE.md` the author was shown is not the pinned
  commit's blob (`runs/2026-09-29-control/seen_agents.py` on the raw log,
  exit 0 and no `UNMATCHED`). Authors are started from the main checkout
  `/home/user/firth`, which stays on this PR's branch; that branch does not
  touch either file, and before authoring both blobs are checked equal to
  the pinned commit's.
- `context_seen.py --arm-set run11` reports a `cross_sample` item (another
  sample's number or files, the other arm's run directory, another
  author's label, or another task's output) put into the author's context
  before its last answer was written. One that arrives after the last
  answer cannot change a scored answer; it is reported, not voiding.
- The author did not write all three answers.

Void samples are reported with their scores and not counted.

## Outcomes

`analyse.py` computes all of these; its self-test checks the exact
Mann-Whitney p against brute-force enumeration on 200 random small cases,
plants swapped arms, and reproduces run 10's p of 0.8196 from run 10's
committed results.

- **Primary:** tasks passed after round 2 per counted sample (all cases of
  the task, `results-3.json`). Test: one-sided exact Mann-Whitney U, arm B
  greater than arm A, at alpha 0.05.
- **Secondary 1:** the number of counted samples in each arm that pass at
  least one task after round 2. One-sided Fisher exact test, B greater.
- **Secondary 2:** tasks passed in the first answer per sample
  (`results-1.json`), one-sided exact Mann-Whitney U, B greater. First
  answers see no feedback, so this is the paragraph's effect alone.
- **Manipulation check:** per sample, the share of first answers
  (`solutions-1.json`) whose source uses a shuffle word, with run 10's
  definition (`dup drop swap dip over rot nip tuck pick roll`, comments
  and stack effects removed). One-sided exact Mann-Whitney U, arm A
  greater than arm B. The same share for final answers is reported
  without a test.

## Reading the result

- Primary significant and the manipulation check significant: arm B's
  paragraph raised Haiku's MVP passes at the pinned build. A follow-up PR
  then proposes the paragraph for `docs/getting-started.md`; that change
  alters eval inputs and is reviewed as such. It is not evidence that
  `locals` causes passing in general, or for any other model.
- Primary significant, manipulation check not: the gain is reported, but
  not attributed to fewer shuffle words.
- Primary not significant: reported as inconclusive, with both arms'
  counts and the p value, never as "no effect". If the manipulation check
  is significant, the write-up says that fewer shuffle words produced no
  gain large enough to detect at 20 per arm.
- Whatever the result, both arms' tables, the per-sample scores and every
  void sample are reported. Runs 10 and 11 are not pooled: the prompts
  match but the builds differ (#180 and #183 changed diagnostics).

## Changes from the brief, and why

The brief (the coordinator's note starting this run) proposed 10 samples
per arm with "passes at least one task" as the primary outcome.

- Primary outcome: in run 10, 16 of 20 counted samples passed at least one
  task, so that outcome has almost no room to rise. Simulated below, the
  Fisher test on it reaches at most 0.12 power at 10 per arm and 0.36 at
  20, even for large effects. Total passes has no such ceiling. The brief's
  outcome is kept as secondary 1.
- Sample size: at 10 per arm the primary has power 0.29 for a gain of 2
  tasks per sample, the gain run 10's association predicts if it were
  causal. At 20 per arm it is 0.47. More than 20 was rejected as too long
  a run for one comparison; 20 is still underpowered for gains of 2 or
  less, and a null result is read that way.
- Concurrency: six authors (three per arm) rather than four, so 40
  counted samples finish in about the time run 10 took for 20.

## Power

`power.py` (fixed seed, 2,000 simulated runs per cell, about 8 minutes).
Final passes are drawn from run 10's 20 counted samples; an arm B sample
then passes each task it failed with probability q. q = 0.14 is about +2
tasks: run 10's 41% and 10% rates with arm B's share of answers using
shuffle words cut from 43% to 10%.

| q | mean gain | MWU, 10/arm | MWU, 20/arm | Fisher (at least one), 10/arm | 20/arm |
| --- | --- | --- | --- | --- | --- |
| 0.00 | 0.0 | 0.05 | 0.04 | 0.02 | 0.02 |
| 0.07 | +1.0 | 0.16 | 0.21 | 0.07 | 0.23 |
| 0.14 | +2.0 | 0.29 | 0.47 | 0.12 | 0.34 |
| 0.21 | +3.0 | 0.46 | 0.71 | 0.11 | 0.36 |
| 0.28 | +4.1 | 0.65 | 0.89 | 0.11 | 0.36 |

The model of the effect is a guess; the real power may be lower.

## Enforcement

Authors run with the after-the-fact audit only, as in run 10. A PreToolUse
hook limiting authors to their own files waits on the maintainer's
approval and is not used in this run.
