# S7 authoring experiment

The PRD's goal S7 exists to test Firth's core bet: that explicit stack
signatures make a language models can write well. This directory is a cheap,
repeatable measurement of that bet. A model that has only read the language
docs solves small tasks in Firth and in Python, and hidden tests score both.

## How it works

- `tasks.py` holds 22 tasks. Each has a description, its input and output
  shape, one visible example, 2 to 6 hidden test inputs and a Python reference
  that computes the expected stack. Values are non-negative integers and
  Booleans, the only values the portable runner can pass in or read back.
  Each task records the capabilities it `needs`. Eleven need only `prim +`,
  stack words, quotations and `if`; the other eleven need subtraction,
  comparison, multiplication or loops, which the runner does not have yet.
- `harness.py prompt` builds the author prompt. For Firth it contains
  `docs/getting-started.md` and `docs/firth-agent-guide.md` verbatim, then the
  tasks. Nothing from `src/`, `tools/` or `examples/` is included, so the
  prompt follows whatever the docs say at the time of the run.
- `harness.py score` runs every answer against the visible example and the
  hidden tests. Firth goes through `tools/loop/firth_run.py run`, so a pass
  also means the VM and the Lean reference interpreter agreed. A task passes
  only when every hidden test returns exactly the expected stack, with no
  Boolean/integer coercion. The toolchain is built once, serially, with the
  runner's own build time limit, before any answer runs. If it cannot build,
  or the build times out, scoring stops with `ToolchainError` rather than
  failing the answer and showing the build error to the author as feedback
  (`test_mvp.py`).
- `harness.py repair` builds a second-round prompt showing each failing
  answer's result on the visible example only. Hidden tests are never shown.
- `classify.py` labels why each failed task failed. Tasks that need a
  capability the runner lacks are labelled `missing_primitive` by rule.
  `--available` names the capabilities the build provides and defaults to all
  of them; runs scored on the plus-only build passed `--available add`. The
  rest are sent to TypeSafe's Jev classifier (`jev-1.13.0`), which is cheap and
  fast but can only pick from fixed labels. Pass/fail never comes from Jev.
- `reference/firth-today.json` has hand-written Firth solutions for the eleven
  tasks that need only `prim +`, and `reference/firth-all.json` covers all 22
  for the build with the new primitives. They pass 11/11 and 22/22 and check
  the harness itself.
- `prompt --extra-doc FILE` appends a document after the repo docs. Run 2
  used `docs/primitives-pr113.md` because the repo docs had not yet been
  updated for the new primitives.
- `classify.py` also labels a failure `resource_limit` by rule when the run
  hit the step budget, a VM resource fault or overflow, so runtime limits are
  counted apart from authoring mistakes.

```sh
python3 eval/s7/harness.py prompt --lang firth > prompt.md
# give prompt.md to the author model; save its reply as answer.md
python3 eval/s7/harness.py extract answer.md > solutions.json
python3 eval/s7/harness.py score --lang firth solutions.json --label "firth sonnet" > results.json
python3 eval/s7/harness.py report results.json
python3 eval/s7/classify.py solutions.json results.json > modes.json
```

The author model is run separately, as a sub-agent told to read only the
prompt file and to use no other tool. Each run directory keeps a trimmed
transcript (`transcript.json`): the model name, start and finish times, and
every tool call the author made, with written content reduced to a hash of
the `answer-*.md` next to it. In all 18 author sessions the only files read
were the prompt and repair files, and the only files written were the
answers. This is an instruction plus an audit, not a sandbox.

Each `results-*.json` records `firth_commit` (the build it was scored on;
if files outside `eval/` had uncommitted changes, it ends in `-dirty+` and
a digest of those changes, so two different patches never share a value) and
`prompt_docs` (the documents the author's prompt was built from). Failure
messages are kept in compact form: the VM trap class, and the checker's code,
message, expected and actual stacks and hint.

## The MVP task set

`mvp_tasks.py` is the fixed task set for the roadmap's "MVP agent authoring"
row, frozen in its own reviewed change before any model attempted it. It has
20 tasks that need real loops over `Seq Int` and `Seq Bool`, locals and
several cooperating words. Five are at allocator weight (`merge-sorted`,
`histogram`, `sort`, `ledger` and `allocate-batch`, the last a whole batch of
the inventory allocator's rules), and two (`digits`, `primes-up-to`) need
division. When the set was frozen Firth had no division, so an author built
it from subtraction; `prim div` and `prim mod` landed in #139 and
`seq-int.set` in #149, and the tasks are unchanged. Inputs include negative
numbers and empty sequences.

- Each task's Python `ref` defines the answer. `test_mvp.py` checks every ref
  against values worked out by hand from the description.
- `reference/mvp/` has a Firth solution for each task. All 20 pass their
  example and hidden tests on both hosts. `test_mvp.py` checks that, and that
  the scorer fails a planted mutant and Python answers of the wrong type (a
  tuple where a list is due, Bools inside a `list[int]`). A Python answer must
  return exactly its declared types, checked before JSON conversion. CI runs it.
- MVP tasks run with a budget of 1,000,000 steps (`--fuel`), the runner's
  largest. The references use far less.
- `prompt --tier mvp` gives the author `docs/getting-started.md`,
  `docs/firth-agent-guide.md` and `examples/programs/README.md` (the
  getting-started guide points there for sequences), plus one diagnostics
  loop, `./try` (`harness.py try` underneath). It checks and runs a program on the task's visible
  example, or on inputs the author passes with `--stack`, and shows the
  result or the checker's diagnostics. It never runs hidden tests. The author
  may use it as often as it likes and nothing else.
- **An author cannot read the hidden tests or the references.** This is
  enforced, not just asked. `isolate.py workspace` makes a workspace holding
  only the prompt and a `./try` client. `isolate.py run` runs the author
  inside a sandbox (a mount and PID namespace with every capability dropped)
  whose root is built from an allowlist: `/usr` (with `/usr/local` and
  `/usr/src`, where local installs and source trees live, covered by empty
  directories), `/etc` and the other system directories, the author CLI's install (`--tool DIR`), read-only copies of
  its credentials (`--keep`), a fresh `/tmp`, `/dev` and `/proc`, and the
  workspace at `/tmp/work`. The host's root is dropped with `pivot_root`, so
  the repository, `/home`, `/root`, `/opt`, `/var`, `/mnt`, `/sys` and
  anything else not on the list do not exist inside. An earlier version hid a
  list of paths instead, and a plain `cat` read the main checkout of a
  worktree it did not know about. `./try` talks to a server
  the harness runs outside, over a socket in the workspace, so `mvp_tasks.py`,
  `reference/mvp/` and the git history stay out of reach.
  Python programs run the author's code, so `./try` runs them inside the
  sandbox as well, and scoring runs Python answers there too; the result
  records `python_sandboxed`. `harness.py score` refuses to score Python
  answers to MVP tasks when it cannot sandbox them (not root). Firth programs cannot read files.
  `test_isolation.py` (CI, as root) runs a probe that finds them without the
  sandbox and finds nothing inside it, by direct path, `/proc/<pid>/root`,
  `git show` or a filesystem search. That probe also runs once on the host as
  root, so it never mounts or unmounts anything; unmounting is tried only
  inside, on the workspace mount, and fails for lack of capabilities.
- The sandbox refuses to start if anything it would show (a system
  directory, a `--tool`, a `--keep` credential or the workspace) is, holds or
  lies inside a path of the repository: the checkout, its git directory,
  common directory and object alternates, its main checkout and other
  worktrees, remotes that are local paths, and any enclosing checkout
  (`repository_paths`). It also refuses when git cannot tell it that layout.
  `test_isolation.py` plants a worktree of a `--shared` clone of a local
  origin, inside an enclosing checkout, with a copy of the clone beside it,
  all under `/opt`. Outside the sandbox `cat` reads the main checkout's,
  parent's and sibling's secrets and git gives back the stored one; inside,
  none of them exists, and a `--tool` naming any of those paths is refused.
  A repository placed under `/usr/local` is refused too, since `/usr` is
  shown. Copies that no git metadata leads to are refused too: the shown
  directories are scanned once per process for git storage (a `.git`
  entry, or HEAD, `objects` and `refs` as in a bare mirror) that holds the
  hidden files: a blob of any revision this repository knows, or any tree
  object, reachable or not, holding `mvp_tasks.py` or an `eval/s7/reference`
  directory. The scan also looks for a file named
  `mvp_tasks.py` or a directory ending in `eval/s7/reference` (older
  revisions), and for a file with the content of a hidden file (hashing only
  files of a hidden file's size). `test_isolation.py` plants each under
  `/usr/share`, including repositories with a revision of the task file
  that matches no known blob, in a reachable commit and in an unreachable
  one. It plants an older revision and a bare mirror
  under `/usr/local`, which are unreachable. An unrelated repository, such
  as the CI runner's `/etc/skel/.nvm`, is shown.
- **Threat model.** The sandbox guarantees that an author, and every
  program it submits, cannot reach this repository's checkouts or git
  storage, nor any shown file that is named like the hidden tests or the
  references, holds their exact content, or is git storage holding them. It trusts the
  operator's environment: what `--tool` and `--keep` name, the contents of
  kept credentials, and the host itself. A copy of the hidden tests that
  someone renamed and edited and placed on the host on purpose is outside
  the model; so is anything reached through the author's network, which the
  transcript audit covers instead. A finding outside this model goes to a
  todo, not to this sandbox.
- Submitted Python programs, run by `./try`, by `harness.py try` or at
  scoring, also get an empty
  network namespace, so an answer cannot fetch anything. `test_isolation.py`
  plants one that reads from a local listener.
- The author process's network stays open, because the author model needs its API. So every
  run limits the author's tools to `./try` and workspace files, and
  `isolate.py audit` checks each retained transcript for any other tool call.
  A run with a flagged call is void. The audit is tested against planted
  calls. The transcript is kept outside the workspace, the one host
  directory the author can write, so the author cannot replace it with a
  clean one after a forbidden call: `audit` takes `--workspace` and refuses
  a transcript inside it. `test_isolation.py` plants a rewritten transcript
  in the workspace, which audits clean without that check.
- Since `./try` is the one command allowed, the author must not be able to
  change what it runs. In the sandbox the client is mounted read-only, it
  runs as `python3 -I` so a `json.py` the author writes is not imported, and
  the audit flags any write to `try`, its socket or `workspace.json`.
  The client reads only a plain file inside the workspace, reached without
  links, so `./try` cannot be pointed at a host file (for example
  `/etc/shadow`, which the author process could otherwise read) to echo it
  back in a diagnostic. `test_isolation.py` plants each of these.
  Run directly, `harness.py try` is operator tooling that authors never
  see: whoever passes its `--workspace` already has the host, so its own
  workspace check guards against operator mistakes, not against authors.
- The host reads what an author wrote (answer files, transcripts) only as
  plain files with one link. It opens each path one component at a time from
  the workspace (`--workspace DIR` on `score` and `extract`) with
  `O_NOFOLLOW`, so no link is followed, in a directory component or the file
  itself. Without `--workspace`, a path with any link in its directories is
  refused. Otherwise a link made in the sandbox to a reference path, dangling
  there, would read the reference on the host. Such a workspace is refused.
- The author and each program it submits run as a fresh uid, drawn at random
  from 2^30 to 2^31 for each run, not as a shared `nobody`: the kernel keeps
  a user keyring per uid outside every namespace here, so one uid shared
  across runs could leave a note there for the next (`test_isolation.py`
  plants it). They get a fresh `/dev`
  holding only `null`, `zero`, `full`, `random`, `urandom` and `tty`, so no
  disk device or root-only file is readable below the path mounts. The
  workspace is handed to that uid, except `try` and `workspace.json`.
- Nothing from the host environment reaches the sandbox except `PATH`, and
  what `isolate.py run --pass-env NAME` names (the model API key). `HOME` is
  the workspace. Credentials passed with `--keep` come in as read-only copies
  the author's uid can read. A `--keep` path inside the workspace, through a
  link, or under a directory an author uid or everyone can write is refused, and so is a
  kept path holding anything but directories and plain files with one link
  (a symbolic or hard link could lead to the repository), with a mount point
  at or below it (read from `/proc/self/mountinfo`, since a same-filesystem
  bind looks like a plain directory), or with a file whose SHA-256 equals a
  hidden file's (a copy or reflink). The copy never follows links. A kept
  file holding part of a hidden file, or an encoding of it, is not caught:
  kept contents are trusted to be credentials.
- Inside the sandbox the root and everything shown are read-only except the
  workspace, a fresh `/tmp` and `/dev/shm`, and there is no `/run` (it holds
  host sockets). So one attempt cannot leave notes for a later one.
  `test_isolation.py` runs `find / -writable` as the author and allows nothing
  else. There is no `/sys`, and `/proc/sys` is read-only, so even a root
  author (a test-only case) cannot write a kernel knob; the test plants the
  sandbox without its read-only `/proc/sys`, which does write one.
- Scoring Python first checks that the sandbox starts, and refuses to score if
  it does not, so a broken sandbox cannot pass for a set of wrong answers.
- The sandbox has its own IPC namespace, so shared memory and message queues
  die with it. It shares the host's network (the author needs its API), so
  two attempts running at once could talk over loopback or an abstract
  socket. `isolate.py run` therefore holds an exclusive lock for the whole
  run and refuses to start while another run holds it.
- When a submitted program times out, the harness kills the sandbox's first
  process, which ends every process in its PID namespace, however it forked.
- An author can delete `try.sock`. That only breaks its own `./try`, and the
  audit flags the command.
- Each results file records `eval_sha256`, a SHA-256 of `task.py`,
  `tasks.py`, `mvp_tasks.py`, `harness.py` and `isolate.py` as scored. `firth_commit`
  ignores `eval/`, so this is what shows an edit to the frozen set or the
  scorer, committed or not.
- Writing the references hit two gaps: no division or remainder, and no way
  to replace one element of a sequence. They are recorded in
  `meta/todos/todo.language-14-authoring-gaps.md`, and both are now closed:
  `prim div` and `prim mod` in #139, `seq-int.set` and `seq-bool.set` in
  #149. The references still use the words built from older primitives, and
  pass on main (`test_mvp.py`). Boolean `and`, `or` and `not` landed in #131 and
  are in the author's docs.

A run gives each task to a fresh author several times, in Firth and in Python,
keeps every transcript, and reports the pass rate per task and overall.

```sh
python3 eval/s7/harness.py prompt --lang firth --tier mvp > prompt.md
sudo python3 eval/s7/isolate.py workspace --lang firth /var/tmp/ws   # outside the repository
sudo python3 eval/s7/isolate.py run /var/tmp/ws --tool <author CLI install> -- <author command> > /var/tmp/transcript.jsonl
sudo python3 eval/s7/isolate.py audit /var/tmp/transcript.jsonl --workspace /var/tmp/ws
python3 eval/s7/harness.py score --lang firth --tier mvp solutions.json > results.json
python3 eval/s7/test_mvp.py
sudo python3 eval/s7/test_isolation.py
```

## Run 1: 27 September 2026, `prim +` only

Main at `c6b1a19`. Authors: Claude Sonnet 5 and Claude Haiku 4.5, one answer
per task, all 22 tasks in one prompt. Results and answers are in
`runs/2026-09-27-plus-only/`.

| | Firth, 11 runnable tasks | Firth, 11 tasks needing new primitives | Python, all 22 |
|---|---|---|---|
| Sonnet 5 | 11/11 | 0/11, and flagged all 11 as impossible | 22/22 |
| Haiku 4.5 | 7/11 | 0/11, and flagged all 11 as impossible | 22/22 |

Haiku got one repair round showing its four failing answers' errors on the
visible example. It then passed 10/11. The last failure, `count-true`, was a
real stack-reasoning mistake: it ran `if` three times in a row as though each
Boolean were still on top, and the checker rejected it with
`firth.type.expected-bool` before anything ran. Sonnet needed no repair.
`runs/2026-09-27-plus-only/report.md` has the per-task table.

What this does and does not show:

- The runnable tasks are easy. Python is at ceiling for both models, so the
  Python column only shows the tasks are fair, not that Firth is close to it.
- Sonnet wrote correct Firth first time using only the docs, and stayed
  within the documented profile. It avoided `locals` and used `dip`, `swap`
  and helper words. When it had to guess, it named the missing primitives
  `prim -`, `prim =`, `prim <`, `prim >`, `prim *`, `prim /` and `prim mod`.
- All four Haiku failures came from `locals`, not from stack reasoning. Three
  referenced a local inside a quotation, which the checker rejects with
  `firth.elaboration.unsupported-capture`; the docs do not mention that limit.
  One used `if` inside a `locals` body, which fails with
  `firth.type.quotation-input-mismatch` even when correct. A third gap came up
  while writing the references: selecting the topmost local twice fails with
  `firth.name.unbound-local`, although the guide says repeated `many`
  selections are copied. These are implementation bugs or undocumented limits
  in `src/`, reported to the Language core thread.
- Jev's labels were not reliable enough to use unreviewed. Before the rule for
  missing capabilities was added, it labelled the placeholder answers
  `stack_effect` with confidence up to 0.99, because the checker diagnostic
  dominated the input. On the four real Haiku failures it said `toolchain`
  three times at 0.29 to 0.53 confidence and `stack_effect` once at 0.70; a
  person reading them would say `toolchain` for all four. Use its labels to
  sort failures for review, not as findings.
- It says nothing yet about the bet on programs with arithmetic, comparison
  or loops. That needs the rerun below.

## Run 2: 27 September 2026, with `-`, `*`, `<`, `=` and tail calls

Run against draft PR #113 (`42f00a7`), which adds `prim -`, `prim *`,
`prim <`, `prim =` and tail calls. That branch had not yet updated the two
docs, so the prompt also carried `docs/primitives-pr113.md`: a primitive
table, the tail-call rule and the 4096-step budget, with no example programs.
New author sessions, all 22 tasks, then one repair round. Python results are
reused from run 1. Everything is in `runs/2026-09-27-pr113/`.

| | Firth, first try | Firth, after one repair | Python |
|---|---|---|---|
| Sonnet 5 | 20/22 | 21/22 | 22/22 |
| Haiku 4.5 | 5/22 | 11/22 | 22/22 |

- **Sonnet is close to Python.** Neither first-try miss was an authoring
  mistake. `majority` reused the topmost local, which is the checker's
  `unbound-local` bug. `collatz-steps` is correct but runs out of the 4096-step
  budget on n = 7, because halving has to be a loop without division. After
  the repair, the step budget is its only failure.
- **Haiku is far from Python.** Its first try failed in ways the docs warn
  against. It declared no inputs in four signatures, used the signature's
  value names as variables in five bodies, and put locals inside quotations in
  five more, which hits the checker's capture limit. It gave up on
  `is-even` and gave no answer for `collatz-steps`. After the repair its 11
  remaining failures were real stack mistakes. The checker rejected 6 of them
  before running (`expected-bool`, `branch-mismatch`, `occurs-check`). Four
  ran and returned wrong answers (`max`, `min3`, `gcd`, `collatz-steps`), and
  it still gave up on `is-even`.
- **What this says about the bet.** For a strong model, explicit stack effects
  plus a checker are enough to write small loops and arithmetic from the docs
  alone at nearly the Python rate. For a weaker model they are not. The
  checker catches most of its stack mistakes, but one round of diagnostics
  did not get it to fix them, while the same model wrote all 22 correctly in
  Python.
- **Jev.** On Haiku's post-repair failures its labels were plausible
  (`stack_effect` 7, `logic` 3, `stack_order` 1). It again called a known
  checker bug `invented_syntax` (Sonnet's `majority`, 0.45). It is useful for
  sorting failures, not as the record.

## Run 3: 27 September 2026, harder tasks, three attempts each

Nine harder tasks (`HARD` in `tasks.py`): sort3, median3, triangle-kind,
divmod, isqrt, is-prime, digit-sum, lcm, and one step of the inventory
allocator from `specs/inventory-allocation.md`. They need several cooperating
words and more stack juggling. Loop inputs are small because the step budget
is 4096. A loop over three locals cost about 120 steps per iteration in this
build, so a count-divisors task was dropped: no plain solution fitted.
`reference/firth-hard.json` passes 9/9.

Each model got three fresh author sessions per language. Firth attempts that
failed the visible example got one repair round. The repair showed the
checker's new plain-language `message`, `expected`, `actual` and `hint`
fields rather than the raw envelope. The prompt was built at PR #113
`a8c3337` with the primitives supplement; everything was finally scored at
`ecd724d`, which fixes the nested-`if`-in-`locals` bug the first scoring hit.
Results are in `runs/2026-09-27-hard/`.

| Passed out of 9 | Firth, first try | Firth, after one repair | Python |
|---|---|---|---|
| Sonnet 5, three attempts | 9, 9, 8 | 9, 9, 8 | 9, 9, 9 |
| Haiku 4.5, three attempts | 1, 0, 4 | 1, 2, 3 | 9, 9, 9 |

- **Sonnet matched Python except for one step-budget failure.** Its one miss in 27 was a correct `lcm` that ran
  out of steps on an input Python handles instantly (`resource_limit`). One
  attempt first scored 7/9 on `a8c3337` because correct nested `if`s inside
  `locals` hit a checker bug; after the Language core fix both passed
  unchanged. Sonnet took far longer to write Firth than Python: about 7 to 29
  minutes per attempt, against under 30 seconds.
- **Haiku failed badly in Firth and not at all in Python.** Across its three
  attempts after repair, 21 tasks failed:
  - 9 used syntax that does not exist. Five used primed names such as `q'`,
    which the lexer reports only as `firth.syntax.overlong-character`. Four
    called words they never defined.
  - 5 were stack-shape mistakes that the checker rejected before running
    (`branch-mismatch`, `occurs-check`, `quotation-compose-mismatch`).
  - 6 ran but gave wrong answers. Two attempts got `allocate` wrong when
    requested equals remaining, and there were off-by-one errors in `isqrt`
    and `is-prime`.
  - 1 nested a `locals` block inside a quotation, which is still unsupported.
- **The repair round barely helped Haiku** (5 to 6 of 27), even with the new
  error messages. One attempt got worse. Its first `sort3` error came from the
  since-fixed checker bug, and that bug's hint ("a `locals` block needs more
  values") sent it to strip out locals and break two other tasks. A misleading
  hint costs more than no hint.

## Rescores on later builds

Stored answers are rescored when the language changes, with no new model
calls. The tables above keep the original scores; the rescore files list
every attempt's passes then and now.

**PR #113 without the locals rework (`b958353`).** The locals fixes run 3
was scored on were taken out of #113 after review found silent miscompiles
in them. Run 2 was unchanged. Run 3 fell to 3 of Sonnet's 27 tasks and none
of Haiku's, all rejected by the checker for their use of locals and none
giving a wrong answer, so they were counted as blocked, not as model
failures. See `runs/rescore-pr113-b958353.json`.

**Main with the locals rework, a larger step budget and signed Int
(`9ac3bc8`: PRs #118, #119 and #122).** All 42 reference solutions pass. No
stored answer that passed before now fails except one `abs-diff`, explained
below, so the earlier locals miscompile had not let any wrong answer through.
See `runs/rescore-main-9ac3bc8.json`.

| Firth, passed | First try, originally | First try, now | After repair, originally | After repair, now |
|---|---|---|---|---|
| Run 2, Sonnet 5, 22 tasks | 20 | 21 | 21 | 21 |
| Run 2, Haiku 4.5, 22 tasks | 5 | 11 | 11 | 11 |
| Run 3, Sonnet 5, 27 tasks | 26 | 27 | 26 | 27 |
| Run 3, Haiku 4.5, 27 tasks | 5 | 5 | 6 | 6 |

- Sonnet's run 2 `abs-diff` computed (a − b) + (b − a). That was correct
  when the run 2 prompt said subtraction stops at zero, and it returns 0 now
  that `Int` is signed. This is a language change, not a model error; the
  reference used the same trick and was rewritten in #122.
- Sonnet's run 2 `collatz-steps` and run 3 `lcm` now fit in the step budget,
  which went from 4096 to 100,000 steps. Its run 2 `majority` no longer hits
  the top-local bug. Apart from run 2's `abs-diff`, Sonnet now passes every task.
- Haiku's run 2 first try gains six tasks that used locals inside quotations.
  Its repaired answers still pass 11, but a different 11: the repair round
  had steered it away from locals and it broke other tasks doing so. Its
  run 3 failures are unchanged, because they were not locals problems.
- Run 1 was scored with only `prim +`. On main, four of the answers Sonnet
  flagged as impossible now pass (`factorial`, `min3`, `power`, `sum-to`),
  because the primitives it guessed (`prim -`, `prim *`, `prim <`,
  `prim =`) are the ones that were added. The Haiku `count-true` answer the
  checker rejected in run 1 also passes now.

## Run 4: 28 September 2026, the MVP task set

Scored on `eb2208f` (the #134 branch: the frozen MVP set and the sandbox).
Authors: `claude-sonnet-5` and `claude-haiku-4-5-20251001`, one sample each
per language. Everything is in `runs/2026-09-28-mvp/`.

**How the authors ran.** The maintainer ruled out an API key for these runs,
so the authors are sub-agents of the session running the eval, as in runs 1
to 3, not sandboxed `isolate.py run` processes. A sub-agent cannot use
`./try` without a shell that could also read the hidden tests, so it got
`prompt --tier mvp --rounds 2` instead: the MVP documents and tasks, no
tools except reading the prompt and writing its answer, then up to two rounds
of `repair` feedback. Each round shows only the visible example's result or
diagnostics, which is what `./try` shows. Unlike `./try`, it cannot run the
author's own inputs, and the rounds are limited to two.

**What is and is not isolated.** Submitted Python ran in the sandbox at
scoring (`python_sandboxed`). The authors themselves were *not*
process-isolated: a sub-agent has the same shell and files as the session,
so it could have read `mvp_tasks.py` or the references. What covers that gap
is the transcript audit, `audit_subagent.py`. It writes each
`transcript.json` from the sub-agent's log: every tool call the author made,
and anything it flags. All 21 calls across the four authors were Reads of their own
prompt or feedback file, Writes of their own answer file (each matching the
kept answer by SHA-256), or the hand-back, and nothing else. The audit also
rebuilds each round's `solutions-<n>.json`, the file `score` read, from the
previous round's and the tasks in `answer-<n>.md`, and flags any difference;
every kept round matches (`test_mvp.py`). `test_mvp.py`
plants a read of `mvp_tasks.py`, a shell call, a stray write, another
directory's feedback and a changed answer, and the audit flags each one.
It is given the rounds the prompt allowed (`--rounds`) and flags any
feedback read, answer written or file kept from a later round, so a run
cannot score more feedback than it reports; `test_mvp.py` plants a third
repair under `--rounds 2`. It also rebuilds each kept `repair-<n>.md` from
that round's solutions and results and flags any difference, so feedback
cannot show more than the visible example; a planted repair that shows a
hidden case is flagged, and every kept one matches. A sub-agent also sees the repository's `AGENTS.md` in its context, which
describes Firth but gives no syntax.

| Passed (of 20) | First answer | After feedback |
|---|---|---|
| Sonnet 5, Firth | 19 | 20 (round 2) |
| Haiku 4.5, Firth | 0 | 0 (round 3) |
| Sonnet 5, Python | 20 | |
| Haiku 4.5, Python | 20 | |

- **Sonnet wrote all 20 in Firth**, including `allocate-batch`, `sort`,
  `merge-sorted`, and `digits` and `primes-up-to` with division built from
  subtraction. Its only first-answer miss was `ledger`, where the call
  passed `start` into the loop's index slot (a stack-order slip; Jev said
  `logic` at 0.56, and the hand label is `stack_order`). It fixed that from
  the example's feedback. From reading the prompt to writing the first
  answer, the Firth answer took 5 minutes 56 seconds and the Python answer
  11 seconds (the tool-call times in `transcript.json`; the `started` field
  of every committed transcript, runs 1 to 5, is the first event of the log,
  which is context inherited from the session, so it is not the author's
  start).
- **Haiku failed every Firth task, in all three answers, for one reason.**
  It used the names from a word's stack effect (`xs`, `n`, `k`, `start`) as
  if they were bound, outside any `locals` block, so every program stopped
  at `firth.name.unresolved`. The rule-based pass labelled nothing (no
  resource limits, no missing capabilities); Jev put 39 of the 40 failures in
  `invented_syntax` and one in `missing_primitive` (a guessed `prim %` in
  round 3). A look at that slice found the cause is shared by the docs and
  the diagnostic:
  - `docs/getting-started.md` says once that "names such as `n` label the
    type boundary; they are not ordinary mutable variables". That reads as
    if they were variables of some other kind. No document says that they
    are out of scope in the body and that `locals` is what binds them.
  - The diagnostic says "`xs` is not a defined word, primitive or local" and
    its hint is about spelling and `prim`. It never says that `xs` is the
    word's own stack-effect name or that `locals { xs } { ... }` binds it.
    Haiku read the feedback as a local-ordering problem, then as a problem
    with quotations, and never found the fix.
  - Both `firth.name.unresolved` and `firth.name.unresolved-effect` hints
    list only `prim +`, `-`, `*`, `<` and `=`. That list is out of date: it
    leaves out `and`, `or`, `not` and the `seq-int` and `seq-bool`
    primitives. In round 3, Haiku guessed `prim %` and got that stale list back.
  These are recorded in `meta/todos/todo.s7-name-diagnostics.md`.
- One sample per cell. The roadmap row asks for several attempts per task,
  so this run does not discharge it. With the results this one-sided (Sonnet
  20, Haiku 0), more samples would narrow the Haiku figure but not change it
  from "fails".

## Run 5: 28 September 2026, Haiku after the hint fix

Main at `cec3707` (#142: the unresolved-name hint names `locals`, the
getting-started guide explains stack-effect names, and every hint lists all
primitives). The eval code is run 4's with the feedback fix below. Author:
`claude-haiku-4-5-20251001` only, Firth only, set up as in run 4. Sonnet was
left out because it was already at 20 of 20. Everything is in
`runs/2026-09-28-haiku-cec3707/`.
`cec3707` also has `prim div` and `prim mod` (#139), so `digits` and
`primes-up-to` no longer need division built from subtraction. Run 4 and
run 5 differ in more than the hints.

**The feedback had been dropping hints.** `readable` picked the checker's
fields out of the runner's error by matching single-quoted text. Python
quotes a string that holds an apostrophe with double quotes, so the new hint
("`xs` is a name in the word's stack effect ...") was silently left out.
The same happened to the whole `untracked-local` message ("can't"). Sample 1's
feedback rounds therefore never showed Haiku the new hints. `readable` now
decodes the diagnostic, and `test_mvp.py` checks that a hint with an
apostrophe survives. That check fails with the old parser. Sample 2 ran with
the fix. Runs 3 and 4 were not affected: none of their feedback hints held an
apostrophe. Runs 1 and 2 were. In their repair files, 21 answers got a raw
envelope cut to 300 characters in place of the checker's message.

| Haiku 4.5, Firth, passed (of 20) | First answer | Round 1 | Round 2 |
|---|---|---|---|
| Sample 1 (feedback without the new hints) | 2 | 2 | 2 |
| Sample 2 (feedback fixed) | 6 | 7 | 8 |
| Run 4, for comparison | 0 | 0 | 0 |

- **The locals failure is gone from first answers.** In run 4, all 20 first
  answers stopped at `firth.name.unresolved`. Here it was 1 of 20 in sample 1
  and 0 in sample 2. Sample 1 fell back to it in its last round, in 15
  tasks, after two rounds of feedback that had lost the hint. Sample 2, which
  saw the hint, never did. Its one later `unresolved` (round 1, `allocate-batch`) was a local used out of its block.
- **The next cause is stack shape.** Jev puts sample 2's first-answer failures
  at 8 `stack_effect`, 5 `stack_order` and 1 `logic`, and its last round at 6,
  3 and 2, plus one run out of steps (`has-pair-sum`, by rule). By
  diagnostic, the largest group in the last round is
  `firth.elaboration.untracked-local` (4 of 12). Then come word-input
  mismatches (3), wrong answers (2: `is-sorted`, `primes-up-to`), and one
  each of branch and compose mismatches.
- **The untracked-local slice is a misleading diagnostic.** Looking closer,
  the two failures checked by hand (`keep-positive`, `ledger`) hold an `if`
  whose branches leave different stacks, inside a `locals` block. The checker reports
  that as "the local is used after `if` ran a quotation whose stack effect is
  not known", and its hint says inline quotations are fine. The actual
  mistake is a branch mismatch, which the same `if` outside `locals`
  reports as `firth.type.branch-mismatch`. With the one branch fixed
  (`[ drop result ]` to `[ result ]`), `keep-positive` passes its example.
  Recorded in `meta/todos/todo.s7-untracked-local-misreport.md` and fixed
  in #145; the re-run that measures it is `todo.s7-mvp-rerun`.
- Two samples, three answers each. The transcripts are clean (`audit_subagent.py`): every call was
  a read of the prompt or feedback or a write of the answer, and each
  recorded write matches the answer that was scored. Sample 1 wrote to a
  directory named `haiku-firth/`, renamed `haiku-firth-1/` afterwards; the
  audit was given both (`--dir`, `--kept`).

## Run 6: 28 September 2026, Haiku after the branch-mismatch fixes

Main at `470c6d0`, which has #145 and #148 (a mismatched `if` is reported at
the `if` as `firth.type.branch-mismatch`, at any depth, instead of as
`firth.elaboration.untracked-local`) and #149 (`seq-int.set`,
`seq-bool.set`). The prompt is `prompt --lang firth --tier mvp --rounds 2`
at `470c6d0`, byte-identical on main after #152. The answers were scored at
`7fa99fc`, the #152 branch, whose only changes against `470c6d0` are in
`eval/` and `meta/`. Every round was rescored with `harness.py score --lang
firth --tier mvp` on each round's `solutions-N.json`, on main at `f947c03`
(the reviewer) and at #155's head `7788ea6`, and every task entry is
identical to the kept `results-N.json`. Author: `claude-haiku-4-5-20251001`,
Firth only, two samples, set up as in run 5. Everything is in
`runs/2026-09-28-haiku-470c6d0/`. This measures `todo.s7-mvp-rerun`.

| Haiku 4.5, Firth, passed (of 20) | First answer | Round 1 | Round 2 |
|---|---|---|---|
| Sample 1 | 3 | 3 | 5 |
| Sample 2 | 0 | 2 | 6 |
| Run 5 sample 2, for comparison | 6 | 7 | 8 |

Failures by the checker's first diagnostic (`results-N.json`):

| | S1 first | S1 last | S2 first | S2 last |
|---|---|---|---|---|
| `firth.name.unresolved` | 7 | 0 | 19 | 0 |
| `firth.type.branch-mismatch` | 8 | 6 | 0 | 10 |
| `firth.type.word-input-mismatch` | 1 | 5 | 0 | 1 |
| other type errors | 0 | 0 | 1 | 2 |
| wrong answer or runtime fault | 1 | 4 | 0 | 1 |

- **No failure is `firth.elaboration.untracked-local` in any round of
  either sample.** In run 5 it was the largest last-round group (4 of 12),
  and hand checks showed it hid branch mismatches. Those now surface as
  `firth.type.branch-mismatch`.
- **Branch mismatches are reported but rarely repaired.** Sample 1 had 8
  at its first answer; 6 of them moved on to a word-input mismatch, which
  is progress to the next error, not a fix. Of its 5 in round 1, 4 were
  still branch mismatches in round 2. Sample 2 had 10 in round 1 and 9 of
  them were still branch mismatches in round 2; one passed. Branch
  mismatch is the largest last-round group in both samples (6 of 15, 10
  of 14). The diagnostic says where the branches disagree but Haiku does
  not act on it.
- **The rise in first-answer `firth.name.unresolved`** (7 and 19, against 1
  and 0 in run 5) is unexplained. The #148 diagnostic changes cannot cause
  it, because first answers are written before any checker message. The
  guidance on binding stack-effect names with `locals` is byte-identical
  between `cec3707` and `470c6d0`. The prompt did change, though: its diff
  makes four changes, all additive (the `set` primitives, a note on `if`
  branch diagnostics, `sieve.firth` and `sort.firth`); `git diff` shows 3
  hunks, 17 lines added and 8 removed, where the removed lines are only
  rewrapped or extended. With two samples
  per run, this data cannot separate sample variance from an effect of
  those additions. A controlled rerun (several first answers on each
  prompt) would. Every such failure is the known mistake of using a
  stack-effect name without `locals`, and the hint fixed all of them by
  round 1 in both samples.
- **Jev** (`modes-1.json`, `modes-3.json`, with every capability
  available) puts the first answers at mostly `stack_effect` and
  `invented_syntax` (the unresolved names), and the last rounds at 6
  `stack_effect`, 5 `stack_order`, 3 `logic` and 1 `toolchain` (sample 1)
  and 11 `stack_effect`, 2 `stack_order` and 1 `logic` (sample 2). The one
  `toolchain` label (0.12 confidence) is a `count-distinct` answer that
  indexed past the end of its sequence, an author error.
- **Fixtures for the branch-mismatch diagnostic.** The last-round answers
  that failed on `firth.type.branch-mismatch` are, in sample 1's
  `answer-3.md`: `reverse`, `merge-sorted`, `digits`, `histogram`,
  `ledger`, `allocate-batch`; and in sample 2's `answer-3.md`:
  `prefix-sums`, `keep-positive`, `longest-run`, `has-pair-sum`,
  `merge-sorted`, `digits`, `primes-up-to`, `histogram`, `ledger`,
  `allocate-batch`.
- The transcripts are clean (`audit_subagent.py --rounds 2 --lang firth`):
  every call was a read of the prompt or its own feedback or a write of an
  answer, within the round limit, and each kept `solutions-N.json` and
  `repair-N.md` is what its answer and results give.
- Two samples, three answers each, so the comparison with run 5 is weak.
  Sample 2 of run 5 reached 8; here the best is 6. The next rerun should
  follow the next change to the branch-mismatch diagnostic.

## Run 7: 28 September 2026, Haiku after the locals-aware branch-mismatch diagnostic

Main at `c6a964a`, which has #153 (the branch-mismatch message says what
each branch takes and leaves, which branch leaves more, and a concrete fix,
and names locals when a branch reaches for one on the stack) and #156 (the
stacks compared are kept in the diagnostic envelope). The feedback shows
`expected:` and `actual:` lines for 3 of the 18 branch mismatches, the
ones where a branch cannot run on the stack it is given; the others carry
both branch effects in the message. The prompt, `prompt --lang firth
--tier mvp --rounds 2` at `c6a964a`, is byte-identical to run 6's, so the
diagnostics are the only change. Answers were scored at `c6a964a`. Author:
`claude-haiku-4-5-20251001`, Firth only, two samples of three answers, set
up as in run 6, plus two extra first answers to the run 5 prompt
(`prompt-cec3707.md`, copied from `runs/2026-09-28-haiku-cec3707/`) for the
first-answer comparison `todo.s7-branch-mismatch-repair` asks for.
Everything is in `runs/2026-09-28-haiku-c6a964a/`.

| Haiku 4.5, Firth, passed (of 20) | First answer | Round 1 | Round 2 |
|---|---|---|---|
| Sample 1 | 0 | 0 | 0 |
| Sample 2 | 0 | 0 | 0 |
| Run 6, for comparison | 3 and 0 | 3 and 2 | 5 and 6 |

Failures by the checker's first diagnostic (`results-N.json`):

| | S1 first | S1 r1 | S1 r2 | S2 first | S2 r1 | S2 r2 |
|---|---|---|---|---|---|---|
| `firth.type.branch-mismatch` | 2 | 1 | 0 | 7 | 8 | 10 |
| `firth.type.stack-underflow` | 12 | 0 | 0 | 0 | 1 | 0 |
| `firth.type.primitive-input-mismatch` | 3 | 8 | 0 | 2 | 4 | 6 |
| `firth.type.word-input-mismatch` | 1 | 7 | 0 | 4 | 4 | 0 |
| `firth.name.unresolved` | 0 | 0 | 20 | 2 | 2 | 0 |
| other checker errors | 2 | 2 | 0 | 4 | 0 | 2 |
| wrong answer or runtime fault | 0 | 2 | 0 | 1 | 1 | 2 |

- **Branch-mismatch repair did not improve.** Of the answers that failed
  on `firth.type.branch-mismatch` and were resubmitted, 12 of 18 failed on
  it again in the next round and none passed. In run 6 it was 15 of 23,
  with one pass. Sample 2, which did not reverse its locals (below),
  passed 0 in both feedback rounds against run 6 sample 2's 2 and 6 on
  the same prompt, from the same first-answer score of 0. Only the
  diagnostics changed, and two samples cannot tell sample variance from a
  regression caused by the new messages.
- **Why sample 1 collapsed: it bound its locals in reverse from the
  first answer.** In sample 1's `answer-1.md`, 29 of the 34 `locals`
  blocks that open a word body list the word's inputs in reverse (for
  inputs `acc idx xs` it writes `locals { xs idx acc }`), and `locals`
  binds its last name to the top of the stack, so every name holds
  another input's value. That was before any feedback, so the new
  messages did not cause it. None of the other first answers kept here
  (run 5, run 6, sample 2, and the two extra) does it. The feedback on
  the resulting type errors pointed at argument order ("`swap` exchanges
  the top two values"), and by the last round Haiku had dropped `locals`
  from `main` altogether (next point). Language core is adding a check
  that refuses a `locals` block which does not bind each declared input
  name to that input.
- **What the unrepaired branch mismatches have in common.** In 9 of the
  10 last-round branch mismatches in sample 2, the message says a branch
  takes values from below the `if` that the code there does not have (3
  "cannot run on the stack it is given", 6 "takes N values from the
  stack below the `if`"); the tenth (`sort`) is a plain count mismatch.
  Language core's reading of those programs is that in each one a single
  operation inside the branch (a helper call missing arguments, a stray
  `swap`) reaches below it, and the message never names that operation.
  A message that does is Language core's next change, and run 8 follows
  both changes.
- **Sample 1 dropped `locals` from `main` in its last round.** Round 2
  had no unresolved names; in round 3 every `main` used its stack-effect
  names without binding them (for example `0 0 xs helper-sum` in
  `seq-sum`), the run 4 mistake, while the helpers kept their `locals`.
  All 20 failed on `firth.name.unresolved`. The checker's hint names the
  fix; there was no round left to use it.
- **The first-answer `firth.name.unresolved` rise in run 6 is
  consistent with sample variance.** First answers that failed on it, by
  prompt:

  | Prompt | Answers |
  |---|---|
  | `cec3707` (run 5) | 1 and 0 (run 5), 20 and 13 (this run) |
  | `470c6d0` (runs 6 and 7) | 7 and 19 (run 6), 0 and 2 (this run) |

  Both prompts produce anything from none to all 20, so sample variance
  alone can account for the run 5 to run 6 change. Four answers per
  prompt are too few to rule out a smaller effect of the prompt's
  additions.
- **Jev** (`modes-1.json`, `modes-3.json`, every capability available):
  sample 1's first answers are 17 `stack_effect` and 3 `stack_order`, its
  last all 20 `invented_syntax` (the unresolved names); sample 2's first
  answers are 9 `stack_effect`, 6 `invented_syntax`, 4 `stack_order` and 1
  `logic`, its last 12 `stack_effect`, 6 `stack_order` and 2 `logic`. The
  run 5 prompt's extra first answers are 18 and 13 `invented_syntax`.
- **Fixtures.** The last-round answers that failed on
  `firth.type.branch-mismatch` are all in sample 2's `answer-3.md`.
- The transcripts are clean (`audit_subagent.py --rounds 2 --lang firth`,
  exit 0 for all four authors): every call was a read of the prompt or its
  own feedback or a write of an answer, within the round limit, and each
  kept `solutions-N.json` and `repair-N.md` is what its answer and results
  give. Scoring on `c6a964a` still passes run 6's passing answers
  (sample 2 round 2 rescored: 6 of 20, the same tasks).

**The feedback in runs 1 to 7 showed no location.** The checker gives each
diagnostic the line and column in the submitted program where it failed, and
`readable` left it out, so an author saw the word a message named but not
which `if` or line it meant. Language core's reading of run 7 is that in
`sort` (sample 2, round 2) Haiku edited `insert-at` when the mismatched `if`
was in `insertion-sort`. The feedback now puts `at: line L, column C` after
the code, as a real author would see it; the line and column count from the
start of the answer as written. `test_mvp.py` checks it on a real branch
mismatch, and the check fails with the location removed from the checker's
output. Kept runs are unchanged, since their results hold the feedback as it
was shown. Run 8 is the first with it.

## Run 8: 29 September 2026, Haiku after the locals-order rule and the branch account

Main at `4c379e0`. Since run 7 (`c6a964a`) it has:

- #161: a `locals` block that opens a word body must bind the stack
  effect's input names in their order, or it is refused with
  `firth.name.locals-order`.
- #162: each error in the feedback carries an `at: line L, column C` line.
  The error text kept in `results-N.json` includes it, so this run's
  results strings differ from earlier runs' by that line as well as by
  the messages below.
- #164 and #166: a branch mismatch names the operation in the branch that
  takes values the branch did not push, and each value by its source. For
  a short branch the hint names a side only when exactly one typed
  placement fits.
- #165 and #167: the `locals` hints are checked before they are stated,
  and suggested renames avoid clashes.

The prompt, `prompt --lang firth --tier mvp --rounds 2` at `4c379e0`, is
not run 7's: it gains two paragraphs on the `locals` order rule and one on
what a branch-mismatch report says (`diff` of the two `prompt-firth.md`
files: 13 lines in, 1 out). So the prompt and the diagnostics both
changed. Answers were scored at `4c379e0`. Author:
`claude-haiku-4-5-20251001`, Firth only, three answers per sample, set up
as in run 7 with the same author and feedback instructions. Everything is
in `runs/2026-09-29-haiku-4c379e0/`.

**Samples 1 and 3 are void, and samples 5 and 6 replace them.** A run
with a flagged call is void (above), and `audit_subagent.py --rounds 2
--lang firth` flags two of the first four authors. Sample 1, in round 1,
read its own `answer-2.md` back and changed it with `Edit`, a tool it had
been told not to use; the edit appended two whole tasks, `primes-up-to`
and `allocate-batch`, that its `Write` of that answer had left out. Sample 3 wrote `answer-1.md` twice, and the audit
flags the first write because the kept file is the second. Neither read
anything but the prompt, its own feedback and its own answers, but the
rule does not depend on what a flagged call could have seen, so neither
is counted. Samples 5 and 6 were then run the same way, and the audit
passes for samples 2, 4, 5 and 6 (exit 0). The void samples' files stay
in the directory; they are described at the end of this section and
nowhere else.

| Haiku 4.5, Firth, passed (of 20) | First answer | Round 1 | Round 2 |
|---|---|---|---|
| Samples 2, 4, 5 and 6 | 0 each | 0 each | 0 each |
| Run 7 (two samples) | 0 and 0 | 0 and 0 | 0 and 0 |
| Run 6 (two samples) | 3 and 0 | 3 and 2 | 5 and 6 |

Failures by the checker's first diagnostic, summed over the counted
samples (`results-N.json`; run 7 has two samples, 40 answers a round,
run 8 four, 80):

| | Run 7 first | r1 | r2 | Run 8 first | r1 | r2 |
|---|---|---|---|---|---|---|
| `firth.type.branch-mismatch` | 9 | 9 | 10 | 12 | 15 | 30 |
| `firth.name.locals-order` | (no rule) | | | 27 | 5 | 0 |
| `firth.name.unresolved` | 2 | 2 | 20 | 1 | 15 | 26 |
| `firth.type.stack-underflow` | 12 | 1 | 0 | 0 | 24 | 11 |
| `firth.type.word-input-mismatch` | 5 | 11 | 0 | 0 | 0 | 4 |
| `firth.type.primitive-input-mismatch` | 5 | 12 | 6 | 1 | 1 | 1 |
| `firth.syntax.*` | 4 | 0 | 0 | 32 | 20 | 7 |
| other checker errors | 2 | 2 | 2 | 7 | 0 | 1 |
| wrong answer or runtime fault | 1 | 3 | 2 | 0 | 0 | 0 |

By sample (first answer, round 1, round 2):

| | S2 | S4 | S5 | S6 |
|---|---|---|---|---|
| `firth.type.branch-mismatch` | 0, 5, 5 | 0, 0, 1 | 12, 0, 8 | 0, 10, 16 |
| `firth.name.locals-order` | 8, 0, 0 | 0, 5, 0 | 0, 0, 0 | 19, 0, 0 |
| `firth.name.unresolved` | 0, 0, 0 | 1, 15, 15 | 0, 0, 10 | 0, 0, 1 |
| `firth.type.stack-underflow` | 0, 15, 9 | 0, 0, 0 | 0, 0, 0 | 0, 9, 2 |
| `firth.syntax.*` | 12, 0, 6 | 19, 0, 0 | 0, 20, 1 | 1, 0, 0 |
| other checker errors | 0, 0, 0 | 0, 0, 4 | 8, 0, 1 | 0, 1, 1 |

- **No counted sample passed any task in any round**, as in run 7. Run 6,
  on the prompt before the `locals` paragraphs, reached 5 and 6 after
  feedback.
- **Between 2 and 8 of 27 branch mismatches were repaired.** Of the 27
  answers that failed on `firth.type.branch-mismatch` in the first answers
  or round 1, all were resubmitted and none then got past the checker. 12
  failed on a branch mismatch again. The other 15 failed first on an
  earlier error: 14 no longer parsed (sample 5's 12 round-1 answers,
  below, and 2 of sample 2's) and 1 was sample 2's empty `main` effect.
  With that error removed by hand (`] if;` to `] if` and `main`'s inputs
  bound for sample 5; `main`'s effect filled in and the `prim` before a
  literal dropped for sample 2), 7 fail on a branch mismatch again, 2 pass
  every case (sample 5's `index-of` and `all-true`), 5 fail on another
  type error and 1 still does not parse
  (`counterfactual/branch-blocked.json`, hand-edited, not scored). So 19
  recurred and 2 were repaired; the last 6 are still stopped before the
  checker reaches the branch, so their repair is unknown. Run
  7's counts were 0, 10 and 6 of 16 resubmitted. Sample 6 repeated all 10
  of its round-1 branch mismatches in round 2 with the new message, which
  names the operation and says which values to push
  (`haiku-firth-6/repair-2.md`).
- **The `locals` order rule refused 32 answers, and each was fixed in the
  next round.** It refused 27 first answers (sample 2: 8; sample 6: 19)
  and 5 of sample 4's round-1 answers. Sample 2 wrote 28 of its 29
  word-opening `locals` blocks that name the inputs in reverse, and
  sample 4 22 of 23 (behind a syntax error in its first answers). All 32
  were resubmitted and none was refused again. None went on to pass: the
  next error was `firth.type.stack-underflow` in 16 (sample 2's 8, sample
  6's 8), a branch mismatch in 11, a word-input mismatch in 3, and one
  each of `firth.type.primitive-input-mismatch` and
  `firth.name.unresolved-effect`.
- **"Unexpected the end of the input." misled two samples.** The parser
  reports it at a token that is not the end of the input. Sample 4's
  first answers grouped arguments in parentheses, as in
  `xs (idx 1 prim +) sum-loop`, 19 times, and got it at the `(`. Sample
  5's round-1 answers ended a block with `] if;` inside `{ ... }` (27
  times in 20 tasks), and got it at that `;`. Sample 5 then wrote every
  round-2 answer as a single `main` with no helper words, "to avoid
  multi-definition parsing issues" in its words, which left it no way to
  loop
  (`todo.paren-in-body-diagnostic`). Sample 2 wrote literals after `prim`
  (`i prim 0 prim <`), 12 times, reported as ``Unexpected `0`, expected
  `primitive name`.``
- **Sample 2 declared `main` with no inputs, and the feedback did not say
  so.** In rounds 1 and 2 every stack underflow (15, then 9) is a `main`
  whose stack effect is `( -- result:Int^many)` followed by
  `locals { xs } { ... }`. The error points at `xs` and says "A `locals`
  block or an operation here needs more values than the stack holds",
  with no mention of the empty stack effect; 8 of the 15 failed the same
  way again (`todo.underflow-names-declared-inputs`). Firth already
  accepts `( -- result:Int^many)` as a stack effect with no inputs, so it
  is not a parse error.
- **Sample 4 never bound `main`'s inputs.** In both its round-1 and
  round-2 answers, 15 tasks used `xs` in `main` without a `locals` block
  and failed on `firth.name.unresolved`. The hint says to bind it first;
  between the two rounds Haiku changed all 15 answers, but not that.
- **Type variables still reach the author** in 5 counted errors, such as
  `?t67 ?t66` in `actual:`, on the word-input and quotation paths
  (`todo.internal-operation-diagnostics`).
- **Jev** (`modes-1.json`, `modes-3.json`, every capability available),
  counted samples: first answers 34 `invented_syntax`, 28 `stack_order`,
  15 `stack_effect` and 3 `missing_primitive`; last answers 46
  `stack_effect`, 29 `invented_syntax`, 4 `stack_order` and 1
  `missing_primitive`.
- **Fixtures.** The last-round branch mismatches are in each counted
  sample's `answer-3.md`, or its latest answer for tasks it did not
  resubmit: sample 2 (5), sample 4 (1), sample 5 (8), sample 6 (16).
- **Set-up slips, caught before any answer was scored.** The first four
  authors were first started with an instruction worded differently from
  run 7's; they were stopped and restarted with run 7's wording, and only
  the restarted authors' answers are kept. Their raw logs are not kept in
  the repository; `raw-log-extract.json` lists every tool call they made,
  one `Read` of the prompt each and no `Write`. Sample 4's first feedback
  message was also worded differently; it read `repair-1.md`, was stopped
  before writing `answer-2.md`, and was sent run 7's wording, then wrote
  its answer. The kept transcript records its tool calls but not the
  messages it was sent, so the first message's wording is recorded only
  here.
- Scoring at `4c379e0` still passes run 6's passing answers (sample 2
  round 2 rescored: 6 of 20, the same tasks).

### Why the counted samples passed nothing

**It was not the harness or the prompt.** All six authors read the same
`prompt-firth.md`, got feedback from the same `repair` step and were
scored by the same `score` call at `4c379e0`. The kept transcripts record
each `Read` by path only, without its offset and limit. The raw sub-agent
logs, which are not kept in the repository, show that each author's first
`Read` of the prompt had no offset or limit and returned lines 1 to the
end; `raw-log-extract.json` lists every prompt `Read` with the lines it
returned, extracted from those logs. From the next run on,
`audit_subagent.py` keeps the offset and limit of each allowed `Read` in
the transcript (the partial-read plant in `test_mvp.py`). No task failed on a harness error: every counted
failure is a checker diagnostic.

**Each sample repeated a few mistakes across nearly every task, and the
feedback showed only the first.** The checker stops at the first error in
a program, so each round of feedback uncovered the next mistake in the
same answers, and two feedback rounds did not get through them:

| First answers | S2 | S4 | S5 | S6 |
|---|---|---|---|---|
| `main` declares the task's inputs | 0 (`( -- result)`) | 20 | 20 | 20 |
| `main` binds them with `locals` | 20 | 0 | 20 | 20 |
| helper `locals` in effect order | no (28 of 29 reversed) | no (22 of 23 reversed) | yes | no (19 refused) |
| parse errors | 12 (`prim 0`) | 19 (parentheses) | 0 | 1 |
| first-answer type errors | none reached | none reached | 12 branch, 7 other | none reached |

- Sample 2's round-2 answers still fail on the empty `main` effect (9) and
  on `prim` literals (4). Checked by hand: `seq-sum`'s helper is correct
  and only `main ( -- result:Int^many)` is wrong. With `main`'s stack
  effect filled in from the task and nothing else changed
  (`counterfactual/sample-2-main-effect*.json`), 2 of the 9 underflow
  tasks pass; 5 are then refused by the `locals` order rule in `main`, 1
  traps and 1 fails on a word-input mismatch.
- Sample 4's round-2 answers still use `main`'s inputs unbound (15). With
  `main`'s body wrapped in `locals { <the task's inputs> } { ... }`
  (`counterfactual/sample-4-main-locals*.json`), none of the 15 passes;
  they fail on word-input (5), branch (4), unresolved-effect (3) and 3
  other type errors. These are hand edits, not Haiku's answers, and are
  not counted in any score.
- Sample 5 had the basics right from the start, as the table shows, and
  its first answers failed on type errors (12 branch mismatches, and
  `prim >`, which is not a primitive, 4 times). Its round-1 answers then
  all failed to parse on `] if;`, the misleading message sent it to
  single-word answers, and its last round fails on unbound names (10) and
  branch mismatches (8).
- Sample 6's first answers were refused by the `locals` order rule (19);
  its round-1 answers fail on branch mismatches (10) and underflows (9),
  and in round 2 all 10 branch mismatches recur.

No single class explains the zero: the first answers' largest blockers are
parse errors (samples 2 and 4), the `locals` order (sample 6) and branch
mismatches (sample 5), and in the last round they are the empty `main`
effect (sample 2), unbound `main` inputs (sample 4) and branch mismatches
(samples 5 and 6).

### The void samples

Samples 1 and 3 are kept for the record and counted nowhere above.
Sample 1 passed 0, 7 and 8, and its round-1 branch mismatches are the only
ones in this run that got past the checker (6 of 12 resubmitted: 2 passed,
4 gave wrong answers). Its first answers had all the basics in the table
right. Sample 3 passed nothing; it wrote `i xs prim seq-int.at` against
the documented `xs i` in 34 places in every round (counted by the
`seq-int.at` edit in `fixes/measure.py`). Sample 1 suggests that
an author who gets the basics right can repair branch mismatches from the
new message, but a void sample is not evidence, and sample 5, which also
had the basics right, did not.

### Which fix would help most

No new eval was run for this. The stored first and round-1 answers
(`solutions-1.json`, `solutions-2.json`) of the four counted samples, 160
failing answers in all, were edited mechanically to model each candidate
fix. Each edited answer was then checked and scored at `4c379e0`
(`fixes/measure.py`, output `fixes/measure.json`). **These are
counterfactual, hand-modelled edits, not Haiku's answers, and not
scores.** Each edit models an author who follows the fix perfectly, so a
count is an upper bound on what that fix could do for these answers. It is
not a prediction of run 9.

**The checker reports only the first error in a program.** Two errors in
two different words give one diagnostic, so each feedback round shows one
mistake. To count independent errors, each word was checked on its own
with every other word's body replaced by a call to itself. That found at
least this many words with an error of their own in each failing answer:

| Words with their own error | 1 | 2 | 3 | 4 |
|---|---|---|---|---|
| Failing answers (of 140) | 38 | 79 | 22 | 1 |

So 102 of these 140 answers had at least two independent errors, and the
author was shown one. The count is a lower bound, because a word is
counted once however many errors it holds. Sample 5's 20 round-1 answers
are left out: their `] if;` ends a word early for the word split, so their
words cannot be checked apart. Reporting every independent error is a
checker change, so it goes to Language core. Editing answers cannot
measure it.

Each candidate edit was applied to every failing answer it matches. An
answer an edit does not match is left out of that row.

| Candidate (models) | Edited | Pass | Checks, wrong answer | Next error | Same error |
|---|---|---|---|---|---|
| Prompt: a real `main` signature (`main` gets the task's stack effect) | 40 | 4 | 2 | 12 | 22 |
| Prompt: bind `main`'s inputs with `locals` | 49 | 0 | 0 | 16 | 33 |
| Prompt: `locals` in stack-effect order | 80 | 0 | 0 | 32 | 48 |
| Prompt: `seq-int.at` argument order | 2 | 0 | 0 | 0 | 2 |
| Prompt: `( )` is not grouping or a comment | 19 | 0 | 0 | 19 | 0 |
| All five prompt edits together | 119 | 15 | 3 | 64 | 37 |
| Other: no `prim` before a literal | 12 | 0 | 0 | 12 | 0 |
| All five, and no `prim` before a literal | 119 | 16 | 6 | 72 | 25 |
| Parse message: no `;` inside a block | 20 | 0 | 0 | 20 | 0 |
| Parse message: no `( )` and no `;` inside a block | 39 | 0 | 0 | 39 | 0 |
| Every edit above | 120 | 18 | 7 | 89 | 6 |

"Next error" means the edited answer fails first on a different error, or
in a different word. In the `main` signature row, 8 of those 12 are the
`locals` order rule refusing `main` itself. "Same error" means the first
error did not move, usually because an earlier error still hides the edit.
The parse-message rows model an author who fixes the parentheses or the
`;` once the message names them (`todo.paren-in-body-diagnostic`). The
message itself changes no code.

- **Fixing the parse message alone passes nothing.** All 39 answers it
  touches move to the next error. Sample 4's 19 first answers move to an
  unbound `main` input (13), the `locals` order rule (5) or another syntax
  error (1). Sample 5's 20 round-1 answers move to an unbound `main` input
  (18), another syntax error (1) or a branch mismatch (1). With every
  edit, 2 of sample 5's 20 pass (`index-of` and `all-true`, the same two
  that pass with only the `;` removed and `main`'s inputs bound in
  `counterfactual/branch-blocked.json`) and 10 fail on a branch mismatch.
- **16 of the 18 passes are sample 2's.** With every edit, 8 of its 20
  first answers and 8 of its 20 round-1 answers pass. Its answers were
  close: an empty `main` stack effect, reversed `locals` and `prim 0` were
  most of what stood between them and passing. The other 2 are sample 5's.
- **Samples 4 and 6 pass nothing under any edit.** With every edit,
  sample 4's 40 answers move to word-input mismatches (15), branch
  mismatches (12) and unresolved effects (7). Sample 6's 20 edited
  answers move to branch mismatches (10) and underflows (8). What stops
  them is type errors in their loops, which no prompt line models.
- **`seq-int.at` order barely matters in the counted samples.** Only 2
  answers were edited. The reversed calls were in void sample 3, where the
  same edit changes 34 calls in each round.
- **Forth `( a b -- c )` comments in bodies (count only): none.** Of the
  1,103 kept Firth answers in every run (all 60 Firth `solutions-*.json`
  files under `runs/`), none writes one in a word body
  (`fixes/count_comments.py`, output `fixes/comments.json`). The
  Forth-style `( -- result)` headers are signatures, which Firth already
  parses: run 8's sample 2 has 60 (20 in each round), run 7's sample 1
  has 12, and #113's run has 4. Parentheses appear in 22 word bodies, 21
  of them in sample 4's first answers, where they group arguments; a
  comment rule would not accept those either. Accepting stack comments
  would change none of these answers.
- **Sample 4 saw two feedback wordings.** Its round-1 and round-2 answers
  were written in a session that received both feedback instructions (see
  "Set-up slips"). Without sample 4, the `locals` order rule refused 27
  answers, and each was fixed. The next error was an underflow in 16, a
  branch mismatch in 10 and a primitive-input mismatch in 1. Sample 4 had
  no branch mismatch in its first or round-1 answers, so the branch
  counts are the same without it. In this section it adds no passes under
  any edit.

Taken together, all the edits could at most move sample 2 from 0 to 8 of
20 and sample 5 to 2. The rest, and most of what is left after the edits,
are type errors in loop bodies, branch mismatches first among them, which
the checker shows one at a time. Showing every independent error is
necessary for an author to fix several at once, and it matters for 102 of
the 140 answers that could be counted. It is not sufficient: after every
edit, 61 of the 135 answers that still fail the checker have two or more independent
errors (sample 6: 36 of 40; sample 4: 20 of 40), mostly branch mismatches
(57 words) and word-input mismatches (39) (`fixes/after_edits.py`, output
`fixes/after_edits.json`). Run 8's branch
mismatches, shown one at a time, recurred at least 19 times in 27, and
only run 9 can show whether seeing every error helps Haiku repair them.

## Run 9: 29 September 2026, Haiku with one diagnostic per refused word

Main at `8ea4a1d`. Since run 8 (`4c379e0`) it has:

- #174: a refused program gets one diagnostic for each word the checker
  refuses, that word's first error, found against the declared effects of
  the words it calls. A caller of a word whose declared effect is not a
  valid signature is reported as `firth.type.unchecked-word`. The harness
  feedback shows every diagnostic ("The checker found N errors, one for
  each word it did not accept. Fix them all before you run it again."),
  each as an `error i of N` block with its code, word, position, message
  and hint.
- #175: the words before a bad `use` are still reported.
- #176: a report that depends on the declared effect of a called word that
  is itself reported says so, and so does a hint whose edit was checked
  assuming that effect.

The prompt, `prompt --lang firth --tier mvp --rounds 2` at `8ea4a1d`, is
run 8's plus one paragraph on how refused words are reported, and step 5
of the agent loop now reads "Fix every reported word" (`diff` of the two
`prompt-firth.md` files: 31 lines in, 2 out). Answers were scored at
`8ea4a1d` (`firth_commit` in every `results-N.json`). The authors ran
against a detached worktree at that commit, so merges to main during the
run could not reach the checker, the prompt or the `AGENTS.md` they saw
(blob `7c89481`, the same as in run 8). Author:
`claude-haiku-4-5-20251001`, Firth only, three answers per sample, with
run 8's author and feedback instructions word for word. Everything is in
`runs/2026-09-29-haiku-8ea4a1d/`.

**Sample 4 is void, and sample 5 replaces it.** After writing its last
answer, sample 4 made 16 calls outside its allowlist, and
`audit_subagent.py --rounds 2 --lang firth` flags all 16. It made 2
`Read` calls and 4 `Bash` commands (`head`, `grep`, `jq`, `cat`) on
sample 3's sub-agent output file under `/tmp` (task
`a7884e1827d752497`, which the run's id list maps to `haiku-firth-3`). It
read part of a file of the eval session's own saved tool output
(`tool-results/bulg7e94h.txt` under `/root/.claude/projects/`). And it
ran `ls` and `find` over its own directory and over the whole run
directory, which lists every sample's answer and feedback files. Its
answers were all written before the first of these calls, but
the rule does not depend on that, so it is not counted. Its files stay in
the directory (it passed 0, 0 and 1). The audit passes for samples 1, 2,
3 and 5 (exit 0, nothing flagged). Each of them made exactly nine calls:
a `Read` of `prompt-firth.md`, its own `repair-1.md` and `repair-2.md`, a
`Write` of each of its own three answers (each matching the kept file by
SHA-256) and three hand-backs. So no counted author read another sample's
files, the tasks, the references or anything else. That this was only
detected, not prevented, is `todo.s7-author-enforced-allowlist`.

| Haiku 4.5, Firth, passed (of 20) | First answer | Round 1 | Round 2 |
|---|---|---|---|
| Sample 1 | 0 | 1 | 3 |
| Sample 2 | 3 | 8 | 12 |
| Sample 3 | 9 | 13 | 17 |
| Sample 5 | 0 | 0 | 0 |
| Run 8 (samples 2, 4, 5, 6) | 0 each | 0 each | 0 each |
| Run 6 (two samples) | 3 and 0 | 3 and 2 | 5 and 6 |

Failures by the first diagnostic of the visible example, summed over the
counted samples (80 answers a round; `fixes/tabulate.py`):

| | First | r1 | r2 |
|---|---|---|---|
| `firth.type.branch-mismatch` | 23 | 26 | 10 |
| `firth.name.unresolved` | 10 | 1 | 18 |
| `firth.syntax.*` | 5 | 6 | 3 |
| `firth.type.word-input-mismatch` | 2 | 4 | 5 |
| `firth.type.primitive-input-mismatch` | 6 | 2 | 1 |
| `firth.type.stack-underflow` | 4 | 4 | 1 |
| other checker errors | 13 | 8 | 0 |
| wrong answer or runtime fault | 5 | 7 | 10 |
| **failing** | 68 | 58 | 48 |

- **Three of four counted samples passed tasks, and 12 first answers
  passed.** In run 8 no counted sample passed anything. Sample 3 reached
  17 of 20, Haiku's best Firth result so far on the MVP task set (run 5's
  best was 8). Sample
  5 passed nothing in any round, and no task that passed in one round
  failed in the next.
- **The new feedback explains little of the gain.** Seeing every error
  mattered little here, because these answers seldom had more than one:
  of the 126 failing answers whose feedback the counted authors read
  (`repair-1.md`, `repair-2.md`), 10 showed two or more errors. Run 8's
  counted first and round-1 answers, the ones whose feedback an author
  would read, rechecked at `8ea4a1d`, show two or more for 71 of 160
  (`fixes/feedback_check.py`, output
  `fixes/run8-feedback-at-8ea4a1d.json`; 109 of 240 with round 2).
  Of the 20 tasks repaired
  between rounds, 3 followed feedback with two or more errors. And the 12
  first answers that passed saw no feedback at all; the only prompt
  change they read is the paragraph on how errors are reported. So the
  difference from run 8 is mostly in what Haiku wrote, not in what it was
  told, and with four samples a run it is not yet separable from
  sample-to-sample variance (run 6's two samples, on one build and
  prompt, passed 3 and 0 first answers). Run 9's 12 of 80 first answers
  also match runs 5 and 6 (11 of 80), which makes runs 7 and 8 (0 of 120)
  the outliers. A control, run 8's build with run 9's protocol, would
  separate them (run 10).
- **More branch mismatches got past the checker.** Of the 49 answers that
  failed on `firth.type.branch-mismatch` in the first answers or round 1,
  6 passed in the next round, 8 got past the checker to a wrong answer,
  14 stopped at another checker error and 21 failed on a branch mismatch
  again (run 8: 2 to 8 of 27 repaired, at least 19 recurred). Sample 1
  accounts for 14 of the 21.
- **Sample 5's round-2 answers used an undefined `i` in 17 tasks.** Its
  loop words name `i` in the stack effect and use it in the body without
  a `locals` block. The hint names the fix
  (`locals { xs k i len count } { ... }`), but the feedback it read before
  that round showed this error once, and there was no round after it. Its round-1 answers had failed on
  branch mismatches (7) and `firth.type.quotation-compose-mismatch` (4).
- **Jev** (`modes-1.json`, `modes-3.json`), counted samples: first
  answers 40 `stack_effect`, 16 `invented_syntax`, 7 `stack_order`, 4
  `logic` and 1 `toolchain` (sample 5's `seq-sum`, a duplicate `main`,
  mislabelled); last answers 20 `invented_syntax`, 13 `stack_effect`, 9
  `logic` and 6 `stack_order`.
- **Set-up.** Samples 1 to 4 ran at the same time in one container, as
  sub-agents of the session running the eval, so each could have reached
  the others' files; the audit above is what shows the counted ones did
  not. Sample 5 started after sample 4 was voided.

## Run 10: 29 September 2026, a control for run 9's gain

Run 9 (`8ea4a1d`) passed 3, 12, 17 and 0 of 20 where run 8 (`4c379e0`)
passed nothing, and four samples a run could not say whether that was the
change between the two commits or sample-to-sample variance. Run 10 ran
both again, fresh, 10 counted samples each, under a design, validity
rules and tests committed before the first author started
(`runs/2026-09-29-control/preregistration.md`, commit `6e7f963`).

- **Arm A** is run 8's build and prompt: a detached worktree at
  `4c379e0`. **Arm B** is run 9's: a detached worktree at `8ea4a1d`. Each
  arm's prompt is byte-identical to its pilot's `prompt-firth.md`, and
  each arm's answers were scored by its own harness and checker. Neither
  worktree was fetched or checked out during the run.
- Author: `claude-haiku-4-5-20251001` as an Agent-tool sub-agent, with
  runs 8 and 9's instructions word for word (only the paths changed),
  three answers per sample. `runs/2026-09-29-control/instructions.json`
  keeps every message each of the 26 authors received, taken from its raw
  log; `instructions.py --check` reduces the eval session's three
  messages to templates (worktree, commit and sample number replaced) and
  finds one sequence shared by both arms, and its `--self-test` shows an
  added arm-specific word or a missing round fails. The other 113 messages
  came from the harness (hand-back reminders and nudges, and one context
  compaction in B8).
- The audit checks what an author called; `context_seen.py` checks what it
  was shown. It lists every item put into an author's context that is
  neither its own turn, nor a result of its own call, nor one of the eval
  session's three messages, and flags any that names another sample or
  another task's files. It also scans the text of the author's own tool
  results, where the harness can add a `<system-reminder>`, and names a
  sample by arm and number, so the other arm's sample with the same
  number, its commit, or a path into its worktree's `eval/` tree counts
  as crossing. Each sample keeps its `context-seen.json`. It exits 1 on
  one sample of the 26, B8, at line 81 of its log: the `task_status`
  attachment that named B10. No tool result carried an added reminder.
  Its `--self-test` plants each kind of crossing (that attachment, a
  label alone, a nudge naming another sample's answer file, the other
  arm's sample with the same number, a path into the other arm's `eval/`,
  and a reminder inside a Read result) and each is flagged.
- The scan also lists, without counting it as crossing, where the other
  arm's worktree was named with no path into it. Every author but B2 was
  shown a skill listing naming both worktrees (the repository's cairn
  skills, scoped to `firth-r8/` and `firth-v9/`), and B1's and B2's first
  environment notice gave `/home/user/firth-r8` as the working directory,
  which was the eval session's own at the time. None of these carries a
  sample's content, and the `CLAUDE.md` and `AGENTS.md` each author was
  given came from its own arm's worktree and the main checkout, never the
  other arm's (`agents-seen.json`; all have the same blobs). An enforced allowlist
  should hide the other worktree too
  (`todo.s7-author-enforced-allowlist`).
- Both arms were audited with main's `audit_subagent.py` (`74679f8`),
  with the hand-back kept whole (reviewer, on #181).
  `plant_audit.py` shows it flags a read of the eval session's own tool
  results or task outputs, another sample's feedback, `Glob`, `LS`,
  `Grep` and `Bash`, and allows the permitted reads.
- Every author saw `AGENTS.md` blob `7c89481` and `CLAUDE.md` blob
  `43c994c`, run 8's (`seen_agents.py` on each raw log, exit 0 for every
  sample, void ones included; the blobs are in each of the 26
  `agents-seen.json` files). A5 and B5 read only their prompt before the
  restart (their `transcript.json`).
- Arm A's harness predates #173, so every one of its results was searched
  for toolchain text before its feedback was sent. None had any.

Everything is in `runs/2026-09-29-control/`: one directory per arm, the
scripts that drove the rounds (`driver/`), the sample-to-author map
(`driver/ids.txt`) and the running log (`driver/state.md`).
`python3 runs/2026-09-29-control/analyse.py` prints the tables and tests
below (`analysis.txt`); `--self-test` checks both tests against known
values.

| Passed (of 20): first answer, round 1, round 2 | Arm A (`4c379e0`) | Arm B (`8ea4a1d`) |
|---|---|---|
| Counted samples | 1: 0, 2, 3 | 1: 1, 7, 8 |
| | 2: 0, 5, 9 | 2: 0, 0, 0 |
| | 3: 0, 0, 10 | 3: 6, 8, 9 |
| | 6: 1, 1, 1 | 4: 0, 0, 0 |
| | 7: 5, 9, 10 | 6: 1, 10, 13 |
| | 8: 0, 0, 3 | 7: 0, 0, 7 |
| | 9: 0, 7, 12 | 11: 2, 2, 2 |
| | 10: 0, 1, 6 | 12: 0, 1, 2 |
| | 11: 0, 0, 0 | 13: 1, 6, 8 |
| | 12: 0, 8, 8 | 14: 0, 0, 0 |
| Passing at least one task after round 2 | 9 of 10 | 7 of 10 |
| Tasks passed after round 2 | 62 | 49 |
| First answers passed | 6 | 11 |

**The result is inconclusive, as pre-registered: arm B did not do better
than arm A.**

- **Primary:** samples passing at least one task after round 2, A 9 of
  10 and B 7 of 10, one-sided Fisher exact test (B greater than A)
  p = 0.957.
- **Secondary:** tasks passed after round 2, A 62 and B 49, one-sided
  Mann-Whitney U (B greater) U = 38, p = 0.820. First answers, A 6 and
  B 11, U = 64.5, p = 0.126.
- The pre-registration says a non-significant primary is reported as
  inconclusive, not as "no effect", and so it is here. What the data do
  show: run 8's build and prompt passed tasks in 9 of 10 fresh samples,
  so run 8's four samples passing nothing was not a property of that
  build, and run 9's gain over run 8 did not reproduce. It is consistent
  with the sample-to-sample variance runs 5 to 9 already suggested.
- **Arm B's feedback did show many errors at once this time.** Of arm
  B's 355 failing first and round-1 answers, 118 had feedback showing two
  or more errors (arm A: 0 of 361, one diagnostic per program). So the
  per-word feedback of #174 was exercised far more than in run 9 (10 of
  126), and still arm B repaired no more than arm A. The arms differ by
  every change from #168 to #176, including #171's checked reorder edits,
  so this is a result for that whole build delta, not for #174 alone.
- **Failure modes** (Jev, counted samples, failing tasks):

  | | Arm A first | Arm A round 2 | Arm B first | Arm B round 2 |
  |---|---|---|---|---|
  | `stack_effect` | 60 | 71 | 88 | 72 |
  | `invented_syntax` | 113 | 24 | 55 | 27 |
  | `stack_order` | 20 | 21 | 43 | 32 |
  | `logic` | 1 | 20 | 3 | 20 |
  | other | 0 | 2 | 0 | 0 |

  Arm A's first answers fail more on invented syntax; arm B's prompt adds
  a paragraph on how refused words are reported, and its first answers
  pass slightly more (11 against 6, not significant). After two rounds
  both arms fail mostly on stack effects.

**Void samples.** Six samples are void under the pre-registered rules
and are not counted. Each directory has a `void.md` saying why.

| Sample | Passed so far | Why void |
|---|---|---|
| A4 | 0, 0 | Container restart during round 2; no third answer |
| A5 | none | Container restart before its first answer |
| B5 | none | Container restart before its first answer |
| B8 | 0, 0, 0 | Ran `ls` twice on its own directory after its last answer (`Bash`, flagged) |
| B9 | 7, 11 | Used `Edit` five times on its own `answer-2.md` (flagged); no round 2 sent |
| B10 | 0, 5 | Wrote `answer-2.md` three times; the audit flags the two writes that are not the kept file; no round 2 sent |

- B10's rewrites used only the allowed tool on its own answer file, but
  the rule voids any flagged sample, and it was applied as written. The
  audit's rule is stricter than the allowlist the pre-registration states
  (a `Write` of the sample's own answers); that is recorded in
  `todo.s7-author-enforced-allowlist`.
- Counterfactual, hand-counted, not scored: if B9 and B10 had been
  counted on their last scored round, arm B would have 9 of 12 samples
  passing a task against arm A's 9 of 10, so the primary would still not
  favour arm B.
- B8's final hand-back named another author ("Control author B10").
  Its raw log shows where the name came from: at 18:52:15 the harness
  injected a `task_status` attachment into B8's context describing B10's
  task, with the path of B10's output log. B8 made no call on that path.
  The excerpt is `8ea4a1d/haiku-firth-8/handback.txt`, and the hand-back
  itself is in that sample's `transcript.json`. It arrived at 18:52:15,
  after B8's last answer was written, and B8 was already void on its
  `Bash` calls and never counted. `context_seen.py` over all 26 logs
  finds this one item and nothing else naming another sample, but the
  channel exists, one more reason for
  `todo.s7-author-enforced-allowlist`.

**Departures from the pre-registration.**

- The pre-registration says the builds differ by #174 to #176. They
  differ by every change from #168 to #176 (`git log --first-parent
  4c379e0..8ea4a1d`), so the comparison is between the two builds, not
  of #174 to #176 alone. The design, rules and tests are unaffected.
- The container restarted at about 18:34 UTC. The files and raw author
  logs survived. A3's final scoring and B4's round-1 scoring had
  finished; A4, A5 and B5 were
  killed mid-turn and, not having written all three answers, are void
  (above). They were not resumed, so no counted transcript spans the
  restart.
- From 18:40:22 to 18:44:48 UTC three arm A authors ran at once (A6, A7,
  A8), and until 18:42:29 five in total, where the design allows two per
  arm and four in all. The slip was in starting A8 early; it changed
  nothing an author could see.
- Samples did not start in strict alternation. Each new author started
  when a slot in its own arm came free, so the start order (first call
  in each `transcript.json`) was A1, B1, A2, B2 (18:02), A3, A4 (18:17),
  B3, B4 (18:27), A5, B5 (about 18:32, void), A11, B11, A12 (18:35), B6,
  A6, A7, A8, B7 (18:37 to 18:42), B8, A9, B9, A10 (18:45 to 18:46), then
  B10, B12, B13, B14 (18:51 to 18:58). Arm B had three audit voids and
  arm A none, so arm B's last four samples ran after arm A had finished
  (18:50) and were not interleaved with it. The whole run took under an
  hour on one model version, but anything that changed over that hour
  (service load, for example) would weigh only on arm B's late samples.
  The three of them that count passed 2, 8 and 0 of 20 (B12, B13, B14).
  The result is reported with that caveat.

## Run 10 failure analysis: what separates passing from failing answers

This reads run 10's 20 counted samples again (no new authoring) to find
what the failing answers failed on. Scripts and outputs are in
`runs/2026-09-29-control/causes/`; each table below is printed by the named
script from the committed files.

**Method.** `recheck.py` ran `8ea4a1d`'s checker over all 1,064 distinct
sources the counted authors submitted, keeping every diagnostic
(`rechecked.json`). `causes.py` groups the first diagnostic each author was
shown into families by code (`units.json`, `causes.txt`). `jev_causes.py`
asked Jev (`jev-1.13.0`) for a finer cause of each failing first and final
answer (`jev.json`). I labelled a fixed-seed sample of 30 of those by hand
without seeing Jev's labels (`handcheck.md`): 22 of 30 agree: 15 of 17 on
syntax, unknown-name and input-mismatch failures, 6 of 9 on branch
mismatches and 1 of 4 on wrong results. So Jev's label only splits checker
failures, and wrong results stay one group. Among the stack-juggling,
stale-local-state and argument-order labels the splits below use, Jev
matched the hand label on 9 of 13, and every miss was a swap among those
three, so each of those sub-rows is approximate and could be off by a lot
either way. Condition-after-the-quotations agreed 4 of 4. `rank.py` ranks the causes (`rank.txt`) and
`behaviour.py` looks for author behaviour that predicts passing
(`behaviour.txt`).

**First answers** (400 tasks, 17 passed). The first thing shown was a
syntax error for 125 (33%), a branch mismatch for 109 (28%), another input
mismatch for 85 (22%) and an unknown name for 47 (12%). Most samples made
one mistake across nearly every task: A1 and A3 wrote `locals { ... }`
without a braced body (20 tasks each), B4 put parentheses around
conditions (19), A9 used its stack-effect names without binding them (20),
and A11 and B2 had a branch mismatch in 18 tasks each. 323 of 383 failing
answers had one independent error (one word refused), 48 had two.

**Feedback** (`rank.txt`). Of failing tasks rewritten in the next round,
the next answer's first error was in the same family for 50% of branch
mismatches, 54% of input mismatches and 48% of syntax errors, but only 16%
of unknown names and 12% of locals errors; 13% or fewer of the first three
passed next time. Every author read each feedback file whole (all are under
the Read tool's 2,000 line default), so whether feedback was read does not
vary; 33% of rewrites kept the same first error on the same word
(`causes.txt`).

**Final answers** (400 tasks, 111 passed, 289 failed), ranked by an
inferred count of answers a fix could recover. "Single" is a final answer
whose independent errors are all in that family, so fixing that family
alone would leave a program that checks. Of written answers that checked,
59% passed (111 of 187), so "recoverable" is single x 0.59. That assumes
fixed answers pass at the same rate and that a fix reveals no other error;
it is an estimate, not a measurement.

| Rank | Cause (first shown; Jev's split) | Final | Single | Recoverable (inferred) | Where |
|---|---|---|---|---|---|
| 1 | Branch mismatch | 107 | 94 | 56 | 18 of 20 samples |
| | of which stack-juggling (approx.) | 71 | 60 | 36 | |
| | of which stale local state (approx.) | 35 | 33 | 20 | |
| 2 | Input mismatch | 85 | 78 | 46 | |
| | of which argument order (approx.) | 39 | 36 | 21 | B2 9, A6 6 |
| | of which condition after the quotations (approx.) | 17 | 15 | 9 | B11 12, B14 5 |
| | of which stale local state or stack-juggling (approx.) | 29 | 27 | 16 | |
| 3 | Syntax | 39 | 39 | 23, but see below | B4 20 (parentheses) |
| 4 | Wrong result (checks, runs, wrong) | 40 | - | - | 4 are reversed loop guards, all B2 |
| 5 | Unknown name | 16 | 7 | 4 | A11 8 (stack-effect names unbound) |

"Stale local state" is the pattern where a loop computes a new value (a
pushed sequence, an incremented index) and then gives the recursive call
the old local's name, or gives it only the changed arguments, so a computed
value is left over or the call is short. "Condition after the quotations"
is Joy/Factor's `[ .. ] [ .. ] condition if`.

Syntax's "single" is true by construction: a syntax error ends the parse,
so the checker reports nothing else for that answer (all 211 answers with a
syntax error have only syntax errors), and what lies behind it is unseen.
For B4, `b4_parens.py` measured it: with every parenthesised condition
unwrapped (a hand-made counterfactual, not scored), none of B4's 20 final
answers checks. Eleven then fail on locals, eight on input mismatches, three
on branch mismatches and two on unknown names (some on more than one;
`b4_parens.txt`). So fixing B4's parentheses alone would recover none of
its answers, and syntax's 23 overstates what a syntax fix recovers.

**Behaviour** (`behaviour.txt`; exploratory, 20 samples, six measures, no
correction for multiple tests). Re-reading the prompt, time to the first
answer, locals share and definitions per task showed nothing (Spearman
|rho| at most 0.24 with final passes, p at least 0.30), and shuffle words
per task little (rho -0.34, p 0.15). The first answer's
length did: rho +0.60, p 0.006, which is a lead to test, not a finding.
Answers without kernel shuffle words (`dup`, `drop`, `swap`, `dip`, and
Forth's `over`, `rot` and the like) passed far more often: 41% of final
answers without them against 10% with them. It holds within each task (17
of 17 tasks where both kinds occur and outcomes differ) and within samples
(10 of 11), and already in first answers, before any feedback (38%
against 16% final passes; 16 of 17 tasks, 8 of 10 samples). This is an
association: an author who avoids shuffles may simply be the stronger
author on that task. Whether telling authors to bind everything with
`locals` and avoid shuffles helps would need a pre-registered run, since
the guide is an eval input.

**Voids.** Six samples were void. Three were container restarts, unrelated
to how the author wrote. The three audit voids, all in arm B, had passed
0, 5 and 11 of 20 before voiding, across the range of the counted samples.
Their last kept answers (`rank.txt`) add 21 branch mismatches, 12 input
mismatches, 5 syntax errors and 4 wrong results; restart A4, the one with
kept answers, adds 7, 12, 1 and 0. Adding them leaves the ranking of the
families unchanged, so the voids do not distort it.

**What this suggests for the language and diagnostics** (inferred from the
ranking; each needs its own measured check):

1. Branch mismatches from stale local state: when a branch leaves a value
   computed from a local and then calls a word with that local's old name
   (or with too few arguments), say so and name the computed value.
2. Condition after the quotations: when `if` finds a Bool on top of two
   quotations, say the condition goes before the first `[`. The current
   message states the rule but B11 repeated the mistake in 12 final answers.
3. Argument order on primitives: name the operand order of
   `seq-int.set` (sequence, index, value) and `seq-int.at` when their
   inputs arrive in another order.
4. Parentheses in bodies: #180's diagnostic, which targets B4's 20 answers;
   those answers also have locals and stack errors behind the parse.
5. The guide could steer authors to `locals` over shuffle words; test it
   with a pre-registered run.

Wrong results (40) are outside what the checker can see; the four read by
hand were two reversed comparisons, an off-by-one start and `<` for `<=`.

## Run 11: 29 September 2026, steering authors to `locals`

In run 10's counted samples, final answers without shuffle words passed
41% of the time and answers with them 10%. That is an association, not a
cause. Run 11 asked whether telling Haiku to bind values with `locals` and
not to shuffle the stack raises how many MVP tasks it passes. The design,
validity rules and tests were committed and reviewed before the first
author started (`runs/2026-09-29-locals-guide/preregistration.md`, #184,
merged as `5d09e25`).

- **Arm A** gets the harness's prompt unchanged. **Arm B** gets the same
  prompt with one paragraph ("Prefer names to stack shuffling",
  `arm-b-paragraph.md`) inserted in `docs/getting-started.md` after the
  paragraph that introduces `locals`. `make_prompts.py --check` passes at
  the pinned commit, and its self-test catches a planted extra word, a
  stale arm A and three misplaced anchors.
- **Build.** Both arms were built and scored in one detached worktree at
  `5d09e25`. It was never fetched or checked out during the run
  (`pinned.txt`: its HEAD, the prompts' SHA-256 and the `AGENTS.md` and
  `CLAUDE.md` blobs, written before the first author started).
- **Authors.** `claude-haiku-4-5-20251001`, run as Agent-tool sub-agents
  and given run 10's instructions word for word, with only the paths
  changed. Each sample has three answers.
  - `instructions.py --check` reduces the eval session's three messages
    to templates and finds one sequence, shared by both arms, across all
    49 authors (`instructions.json`). Its self-test plants an
    arm-specific word and a missing round, and both fail.
  - The other 131 messages came from the harness: hand-back and system
    reminders, and three context compactions.
- **Concurrency.** At most three authors per arm ran at once, and six in
  all (first and last log times of each author). Every round's results
  were searched for toolchain text before feedback was sent, and none had
  any.
- **Validity checks.** Every sample was checked on its complete log with
  the pre-registered checks: `audit_subagent.py`, `seen_agents.py` and
  `context_seen.py --arm-set run11`. The two arms saw the same
  `AGENTS.md` and `CLAUDE.md` blobs.
- **Where everything is.** The run is in `runs/2026-09-29-locals-guide/`.
  It holds one directory per arm and `driver/`, which has the scripts
  that drove the rounds, the sample-to-author map (`ids.txt`) and the
  running log (`state.md`).
  - `python3 runs/2026-09-29-locals-guide/analyse.py` prints the tables
    and tests below (`analysis.txt`).
  - Its `--self-test` checks the exact Mann-Whitney p against brute force,
    plants swapped arms and a 21st sample, and reproduces run 10's
    p = 0.8196.

| Passed (of 20): first answer, round 1, round 2 | Arm A (guide as is) | Arm B (plus the paragraph) |
|---|---|---|
| Counted samples | 2: 0, 5, 12 | 1: 0, 7, 9 |
|  | 3: 0, 0, 0 | 2: 0, 9, 10 |
|  | 4: 0, 0, 8 | 3: 5, 10, 13 |
|  | 5: 0, 5, 7 | 4: 0, 0, 7 |
|  | 6: 6, 13, 15 | 5: 4, 14, 17 |
|  | 7: 0, 0, 7 | 6: 0, 8, 11 |
|  | 8: 6, 9, 9 | 7: 7, 10, 13 |
|  | 9: 0, 6, 9 | 9: 0, 7, 9 |
|  | 10: 5, 6, 11 | 10: 6, 11, 14 |
|  | 11: 0, 6, 12 | 13: 0, 0, 10 |
|  | 12: 0, 5, 9 | 14: 11, 12, 14 |
|  | 13: 0, 0, 1 | 15: 0, 0, 4 |
|  | 16: 3, 9, 13 | 16: 4, 12, 15 |
|  | 17: 7, 9, 11 | 17: 0, 0, 6 |
|  | 18: 7, 12, 15 | 18: 0, 0, 7 |
|  | 19: 0, 0, 4 | 19: 0, 0, 0 |
|  | 20: 5, 8, 10 | 21: 0, 0, 0 |
|  | 21: 0, 0, 0 | 22: 0, 0, 1 |
|  | 23: 0, 0, 1 | 24: 11, 14, 17 |
|  | 24: 0, 0, 0 | 25: 0, 0, 0 |
| Passing at least one task after round 2 | 17 of 20 | 17 of 20 |
| Tasks passed after round 2 | 154 | 177 |
| First answers passed | 39 | 48 |
| Share of first answers using a shuffle word (mean) | 0.37 | 0.06 |

**The result is inconclusive, as pre-registered.** Arm B's paragraph
changed how authors wrote, but no gain in passes large enough to detect
with 20 samples an arm.

- **Primary:** tasks passed after round 2. A 154, B 177, a one-sided exact
  Mann-Whitney U test (B greater) gives U = 224 and p = 0.26.
- **Secondary 1:** samples passing at least one task after round 2. A 17
  of 20, B 17 of 20, one-sided Fisher p = 0.67.
- **Secondary 2:** tasks passed in the first answer. A 39, B 48, U = 203.5,
  p = 0.46.
- **Manipulation check:** the share of first answers using a shuffle word
  (`dup drop swap dip over rot nip tuck pick roll`, with comments and
  stack effects removed). Mean A 0.37, B 0.06, U_A = 338, one-sided exact
  p < 0.0001. Final answers, reported only: A 0.26, B 0.01.
  - Arm B's authors did what the paragraph asked. 17 of its 20 counted
    samples used no shuffle word in any first answer, and B17 and B25 used
    one in 10% of them.
  - B19 is the exception: 0.90 in its first answers, 0.10 in its final
    ones.
- **Reading.** Following the pre-registration: the primary is not
  significant and the manipulation check is. So fewer shuffle words
  produced no gain in passes large enough to detect at 20 an arm. The
  pre-registered power for a gain of 2 tasks a sample was 0.47, and the
  observed difference is 1.15 tasks a sample.
  - This does not show that the paragraph has no effect.
  - It also does not support run 10's association as a cause. Authors who
    avoided shuffles when told to did not pass clearly more.
  - The paragraph is not proposed for `docs/getting-started.md` on this
    evidence.
- **Two sensitivity checks** (counterfactual, computed from the committed
  results, not scored and not pre-registered). Neither makes the primary
  significant.
  - Counting every void sample at its last scored round gives A 170 over
    24 samples and B 229 over 25, p = 0.088.
  - Dropping the samples started last (A21, A23, A24 and B25; see
    departures) gives p = 0.40. That drop is uneven, three from arm A and
    one from arm B. Dropping B24 as well, so each arm loses every sample
    started after 22:28, gives A 153 over 17 and B 160 over 18, p = 0.50.

**Closed-effect refusals** (`todo.closed-effect-under-locals`,
`closed_effect.py`, `closed-effect.txt`). A word whose effect has no row
variable is refused when called inside `locals` while a later-used local is
live, even when the author pushed exactly its inputs.

- **Method.** `closed_effect.py` finds each answer refused with
  `firth.type.word-input-mismatch` at a call of a closed-effect word from
  a word that uses `locals`. It then opens the callee's effect
  (`(a -- b)` becomes `(forall ρ; ρ a -- ρ b)`) and checks the program
  again.
  - Its self-test counts the todo's two refused programs.
  - It does not count a planted program with a genuine extra value, a
    call outside `locals`, or an open-effect callee.
- **Result.** Across all three answers of the 20 counted samples in each
  arm, the refusal occurs only in arm B, in one sample (B1), in two tasks.
  - B1's `primes-up-to` (`is-prime` called inside `locals`) type-checks
    once the callee is opened, so this refusal was its only type error.
    That holds for both its round 1 and round 2 answers. Whether it would
    then pass the tests was not run.
  - B1's `count-distinct` (`contains`) also had an unrelated error.
  - So the refusal cost arm B one final task at most, and arm A none.
  - The harness shows the first error in each refused word, so a closed
    call behind an earlier error in the same word would not be seen.
    These counts are a lower bound.

**`pick` and `roll`.** No counted answer in either arm used `pick` or
`roll`, in any round. Arm B's answers used no `over` or `rot` either (the
paragraph says those are not Firth words). In arm A, 18 answers used
`over`, all of them first answers and 16 of them A24's. 15 distinct
answers used `rot`: 11 from A24, 3 from A3 and 1 from A13 (A3's round 3
rewrote one of them unchanged, so a count of answer blocks gives 16). Both names are unresolved in
Firth.

**Void samples.** Nine samples are void under the pre-registered rules and
are not counted: four in arm A and five in arm B. Each directory has a
`void.md` quoting the flagged audit lines with their log times.

| Sample | Passed so far | Why void |
|---|---|---|
| A1 | 4 | Wrote `answer-1.md` twice |
| A14 | 0, 4, 4 | After its last answer, read another author's raw log and ran `tail` on it (`Read` and `Bash`, flagged) |
| A15 | 1, 8 | Wrote `answer-2.md` twice |
| A22 | 0 | Wrote `answer-1.md` three times, then read it back |
| B8 | 2, 13 | Used `Edit` four times on its own `answer-2.md` |
| B11 | 0, 12, 15 | Read `answer-3.md` back twice, then wrote it again |
| B12 | 0 | Wrote `answer-1.md` twice |
| B20 | 0, 11, 16 | Wrote `answer-3.md` twice |
| B23 | 8 | Wrote `answer-1.md` three times |

- **Void rates are about equal:** 4 of 24 started samples in arm A and 5
  of 25 in arm B.
- **Arm B lost higher-scoring samples.**
  - Its voids that reached round 2 ended at 13, 15 and 16. Arm A's ended
    at 4 and 8.
  - Validity was judged on the rules alone, never on scores.
  - This asymmetry is why the first sensitivity check above comes closer
    to significance.
- **Most voids were rewrites.** Eight of the nine were an author
  rewriting, editing or re-reading its own answer file with the allowed
  tools. The audit flags this, which is stricter than the allowlist the
  pre-registration states. That gap is recorded in
  `todo.s7-author-enforced-allowlist`, as it was after run 10.

**What authors were shown.** `context_seen.py` flagged items naming
another sample in three logs, all `task_status` attachments that the
harness injected during a context compaction. Each named five other
running or finished authors and the paths of their output logs.

- In A13 and B4 the items arrived after the author's last answer (36
  seconds and 41 seconds after its last `Write`). Under the
  pre-registration they are reported (`late-context.md`), not voiding.
  Neither author made a call after them except its hand-back.
- **A14 is the first author seen to act on one.**
  - Forty seconds after writing `answer-3.md`, it was shown `task_status`
    items naming A15, A16, B16, B17 and B18.
  - It then read A15's raw output log and ran `tail` on it (log lines 95
    and 101).
  - Its answers were all written before that, but the audit rule has no
    timing exception, so A14 is void.
  - Run 10's B8 was shown the same kind of attachment and made no call.
    A14 shows the channel can be used, and an author compacted before its
    last answer could read another sample's work.
  - This is added to `todo.s7-author-enforced-allowlist`.
- Everything else injected was the harness's own housekeeping: token and
  hook notices, the skill and tool listings, the environment, and the
  nested `CLAUDE.md`. None of it named another sample.

**Departures from the pre-registration.**

- **Samples did not start in strict alternation.** Each new author
  started when a slot in its own arm came free. The start order is in
  `driver/ids.txt` and each `transcript.json`.
- **Arm A's last three regular starts came late.** At 22:23, after A20
  started, the eval session counted 20 non-void starts in arm A. In fact
  there were 17, because A1, A14 and A15 were void.
  - The miscount was found at 22:31. A21, A22 and A23 then started, after
    arm B's last regular starts (B23 and B24 at 22:28). A22 was void and
    was replaced by A24 at 22:34.
  - So arm A's last three counted samples (A21, A23 and A24) and arm B's
    last (B25) ran in the final ten minutes, not interleaved as designed.
    They passed 0, 1, 0 and 0 of 20.
  - The whole run took one hour (21:38 to 22:38 UTC) on one model
    version. The second sensitivity check above drops those four samples,
    and the result is the same.
  - No sample was started, stopped or counted on the basis of a score,
    and the counted set is the first 20 non-void samples by start order
    in each arm, as `analyse.py` computes it.

## Run 11 failure analysis: what stops answers passing, by arm

This reads run 11's 40 counted samples again, with no new authoring. It
asks what the failing final answers failed on in each arm, and above all
what stops arm B's locals-style answers. The scripts extend #182's and live
in `runs/2026-09-29-locals-guide/causes/`. Each table below is printed by
the named script from the committed files.

**Method.**

- `recheck.py` runs the pinned checker (`5d09e25`, the one both arms were
  scored with) over all 2,036 distinct sources the counted authors
  submitted, and keeps every diagnostic (`rechecked.json`).
- `causes.py` groups the first diagnostic each author was shown into
  families by code (`units.json`, `causes.txt`).
- `rank.py` splits each family by the checker's own diagnosis, which is
  read from the shape of its hint, and ranks the families by arm
  (`rank.txt`).
  - This replaces #182's Jev labels. The checker's hint is exact about
    which of its cases fired, whereas Jev agreed with hand labels on only
    9 of 13 sub-splits.
  - So the sub-rows below are measured, not approximate. They say what
    the checker saw, not what the author meant.
- "Recoverable (inferred)" is the number of single-family answers
  multiplied by the rate at which written answers that checked also
  passed, as in #182. That rate is 58% for arm A and 59% for arm B.
- Four counterfactuals are measured on the answers themselves. They are
  not scored as part of the run.
  - `recover.py` applies, word for word, every edit the checker's hints
    spell out ("write `A` in place of `B`"). It re-checks until no edit
    applies, then scores what checks. It was run with the pinned checker
    and with main's (`a3fb621`, which adds #185's branch-mismatch edits).
  - `locals_body.py` braces unbraced `locals` bodies.
  - `shown.py` reads the feedback files for which edits the authors saw,
    and whether they applied them.
  - `closed_effect.py` opens closed effects (run 11's write-up).

**Final answers.** Arm A has 246 failing final answers and arm B 223.

| Rank | Cause (first error shown) | Arm A | Arm B | Recoverable, A / B (inferred) | Measured |
|---|---|---|---|---|---|
| 1 | Branch mismatch | 93 | 44 | 53 / 24 | Main's edits: 6 pass, all in arm A |
| | of which one branch leaves extra values | 38 | 25 | | No edit offered |
| | of which a call in a branch gets the wrong values | 29 (A24 14) | 15 | | #185's target |
| 2 | Input mismatch | 68 | 70 | 35 / 36 | Checker's edits: 8 / 7 pass |
| | of which argument order, the hint gives the edit | 27 (A23 15) | 19 | | Following the edits: 15 pass |
| | of which argument order, left to the author | 10 | 5 | | No edit offered |
| | of which a value of the wrong type at a position | 13 | 23 (B22 13) | | |
| | of which too few values or underflow | 16 (A3 15) | 17 | | |
| 3 | Wrong result or trap (checks, runs, wrong) | 51 | 61 | not checker-visible | see below |
| 4 | Syntax | 22 | 37 | 13 / 22, overstated | Bracing: 0 pass |
| | of which `locals { .. }` with no braced body | 20 (A21) | 20 (B21) | | 4 check, 0 pass |
| | of which an operator that does not exist (`<=`, `>`) | 2 | 7 | | |
| | of which a code fence left open in the first answer | 0 | 9 (B15) | | |
| 5 | Unknown name, declared effect, locals | 12 | 11 | 6 / 3 | |
| - | Closed effect under `locals` | 0 | 1 (B1) | | Opening the effect: checks |

**What stops arm B.**

- Arm B failed on branch mismatches half as often as arm A (44 against
  93). That is the one family its paragraph plainly changed.
- It failed on input mismatches as often as arm A (70 against 68), and
  somewhat more often on wrong results and traps (61 against 51).
- In arm B the largest groups are:
  - wrong results (61);
  - input mismatches, of which 24 are argument order (19 with the edit
    spelled out by the checker) and 23 are an extra value pushed before an
    operation (13 of those are B22 writing `xs i prim seq-int.len`);
  - one sample (B21) writing every `locals` body without braces.
- So steering authors to `locals` moved failures out of branch mismatches
  without moving them into passes. That fits the run's inconclusive
  primary result.

**Wrong results and traps** (`rank.py` section 3). These are classified by
fixed rules on the failing case's outcome, not by reading programs. The
causes named here are inferred from the outcome.

| Outcome | Arm A | Arm B |
|---|---|---|
| Equality boundary: `is-sorted` false on equal neighbours, `primes-up-to` keeping squares (4, 9), `keep-positive` keeping 0 | 15 | 14 |
| Empty or zero result (the loop body never ran) | 16 | 3 |
| Digits in reverse order | 2 | 5 |
| Trap (index out of range, fuel, resource) | 6 | 11 |
| Other wrong value | 12 | 28 |

- Inferred, not measured: the equality-boundary answers are strict `<`
  where `<=` was meant, in both arms. The rule measures only the outcome.
  By hand, 7 of the 8 `keep-positive` answers skip on `x 0 prim <`.
  - Firth has only `prim <` and `prim =` for comparing integers. So
    `a <= b` has to be written `b a prim < prim not`, and `a > b` has to
    be written `b a prim <`.
  - Nine further final answers invented `<=` or `>`, which the parser
    refuses (syntax, above).
  - Six of the 19 empty results, read by hand, are a backwards loop
    guarded by `i 0 prim <` where `i >= 0` was meant (A7, A16, B22).
- Of the 12 primes answers that keep 4 and 9, 10 use a
  `d d prim * n prim <` bound where `<=` was meant (read by hand; B4's
  and B22's have no squared bound).
- These 29 answers check and run, so no diagnostic can catch them.
  - The language gap is the missing non-strict comparison. It is
    recorded in `todo.comparison-primitives`.
  - Whether adding `prim <=` would cut these errors needs its own
    measured run.

**Syntax (overstated, as in #182).**

- A21 and B21 wrote every word as `locals { a b } body ;` in all three
  rounds. Each time the checker said only "Unexpected `a`, expected `{`",
  with the generic hint "A definition looks like ...".
- Bracing their 40 final answers mechanically gives 4 that check and 0
  that pass. Behind the braces are branch and input mismatches the authors
  never saw.
- So a specific diagnostic here would recover nothing directly. It would
  unblock feedback that these two samples never received in three rounds.
- B15's nine are one code fence left open in its first answer, which
  pulled the next task's heading into the program. It never rewrote those
  tasks.

**Measured edit recoveries** (`recover.py`, `rank.py` section 2).

- **Pinned checker.** Of the 357 refused final answers (195 in A, 162 in
  B), 52 had an edit offered. Applying the edits word for word makes 37
  check and 15 pass, all of them input mismatches.
- **Main's checker** (with #185) offers edits for 73 answers. 50 then
  check and 21 pass. The six extra passes are arm A branch mismatches.
- Most of these edits were never shown to the authors (`shown.py`).
  - A final answer's own errors get no feedback, since the third answer
    is the last.
  - For 38 of the 52 answers, neither feedback round on that task showed
    an edit: the error shown had none, or the example passed. Those 38
    include 13 of the 15 passes.
- When feedback did show an edit, the next answer applied it 55 of 68
  times in arm A and 86 of 102 in arm B (141 of 170).
  - "Applied" means that, against the answer the feedback was about, the
    old text occurs fewer times and the new text more times. A short old
    text can correctly remain elsewhere in the task.
  - This is a mechanical reading: a word rewritten some other way counts
    as not applied.
  - The reading is close but not exact. The reviewer applied each shown
    edit at the occurrence nearest the error's line and column, and
    checked the next answer there. The count rule credits 3 edits made
    elsewhere and misses 10 made at that spot (all B9, round 1), so the
    stricter figure is about 148 of 170.
  - Only the first edit in a task's feedback section is judged. A section
    with an error in two words, each with an edit, is judged on the
    first.
  - A failing input mismatch was rewritten into the same family 28 to
    29% of the time (`rank.py` section 5).

**Tasks failing in both arms** (`rank.py` section 4).

- `sort` and `allocate-batch` failed in all 40 counted samples.
  `primes-up-to` failed in 39, mostly with wrong results (20).
  `longest-run`, `histogram`, `digits` and `is-sorted` failed in 30 or
  more.
- The four tasks with the most wrong results (`primes-up-to`,
  `is-sorted`, `digits`, `keep-positive`) are the equality-boundary and
  ordering tasks above.

**Voids** (`rank.py` section 6). The nine void samples' last kept answers
fail in the same families, input and branch mismatches first. Two of them
(A22, B12) failed all 20 tasks with a syntax error in their only kept
answer. Adding the voids leaves the ranking unchanged.

**Ranked for Language core.** Each item names what is measured and what is
inferred.

1. **Non-strict comparison.**
   - Measured: 29 wrong results with the equality-boundary outcome, and 9
     answers that invented `<=` or `>`.
   - Inferred: that the cause is composing `<=` from `<`, `not` and
     argument order.
   - The fix is a Gamma primitive (`prim <=`), or a clearer idiom in the
     guide. The guide is an eval input, so either needs its own run.
     Recorded as `todo.comparison-primitives`.
2. **Argument order the checker already solves.**
   - Measured: 61 final answers, 46 of them with an edit. Following the
     edits makes 15 of those 46 pass. The other 15 answers got the hint
     that only the author can tell which value is which, with no edit.
   - Measured: the authors never saw most of those edits. 13 of the 15
     passes come from answers whose feedback showed no edit in either
     round. The edit was in the final answer, which gets no feedback.
   - When an edit was shown, the next answer applied it 141 times out of
     170 (A 55 of 68, B 86 of 102). So authors mostly do apply a shown
     edit. The larger loss is that a final answer's new errors are never
     shown.
3. **A branch leaving extra values** (63 final answers).
   - No edit is offered. #185 covers the other branch case (44 answers):
     measured on main, its edits make 6 of them pass.
4. **`locals` without a braced body** (40 final answers, two samples,
   unchanged over three rounds).
   - A specific diagnostic would unblock feedback that the generic hint
     hid.
   - Measured: bracing alone makes none pass.
5. **Closed effect under `locals`.** One answer (B1). Low priority.

## Run 12: 30 September 2026, letting authors run the checker (stopped early)

Run 12 asked whether letting Haiku run the checker on its own answer file,
as often as it likes before each hand-in, raises how many MVP tasks it
passes. The design was committed and reviewed before the first author
started (`runs/2026-09-30-check-tool/preregistration.md`, #190, merged as
`e381708`). Arm A got run 11's arm A prompt unchanged. Arm B got the same
prompt with one paragraph that allows Read, Write and Edit of its own answer
file and exactly one Bash command:
`python3 /home/user/firth-r12/eval/s7/harness.py check --lang firth <its answer file>`.

**Run 12 has no result.** It was stopped early for feasibility, a departure
from the pre-registration (`departures.md`). Nearly every arm B author ran
the check command with shell syntax the pre-registration refuses, so arm B
could not reach 40 counted samples. `analyse.py` refuses to run on fewer
than 40 counted samples an arm, and no test was computed. Everything below
is descriptive.

- **Build.** Both arms were built and scored in one detached worktree at
  `e381708`, never fetched or checked out during the run (`pinned.txt`).
  The two arms saw the same `AGENTS.md` and `CLAUDE.md` blobs.
- **Authors.** 19 authors, `claude-haiku-4-5-20251001`, run as Agent-tool
  sub-agents: arm A 1 to 11 and arm B 1 to 8. `instructions.py --check`
  finds that every author received exactly its own arm's templates
  (`instructions.json`; 46 other messages came from the harness).
- **Start order.** Starts alternated A1, B1, A2, B2 and so on up to B7. Then
  A7 to A11 started before B8. Arm B authors ran longer (B5 took 14
  minutes, B6 17), and at most three authors per arm ran at once, so arm A
  ran ahead. The pre-registered start-order analysis (secondary 4) was meant
  to cover this. It is reported below both ways, as agreed before the stop.
- **Where everything is.** The run is in `runs/2026-09-30-check-tool/`,
  with `driver/` holding the scripts that drove the rounds, the
  sample-to-author map (`ids.txt`) and the running log (`state.md`).
  - `python3 runs/2026-09-30-check-tool/describe.py` prints the scores
    below. It computes no p-value.
  - `python3 runs/2026-09-30-check-tool/driver/bash_calls.py` counts arm B's
    Bash calls from `bash-calls.json` in each arm B sample. That file holds
    every Bash command from the author's raw log, verbatim. Its
    `--self-test` plants an allowed call, another sample's answer, and each
    added form.

### What stopped the run

Arm B started 8 samples, and all 8 are void.

- **Toolchain voids: B1, B2 and B3.** After a container restart, `lake` was
  not on the authors' default PATH, so every check they ran printed "lake is
  not on PATH". Three symlinks in `/usr/local/bin` fixed it before the next
  start (`pinned.txt` records the toolchain versions in both
  environments). From 03:31Z, `driver/preflight.sh` ran the check in the
  authors' own shell before an arm B start.
- **Rule voids: B4 to B8.** The audit flagged Bash calls that were not
  exactly the allowed command. `driver/bash_calls.py` counts 83 such calls
  across arm B's 91 Bash calls, and only 8 calls were the allowed command.
  One call can add several forms:

| Added to or instead of the check | Calls |
|---|---|
| `2>&1` | 69 |
| piped to `grep` | 49 |
| piped to `head` | 25 |
| `cd /home/user/firth-r12 &&` prefix | 10 |
| piped to `tail` | 8 |
| redirected to a file in `/tmp` | 2 |
| not a check at all | 9 |

  - The 9 non-checks were: B1's four toolchain probes (`which lake`,
    `lake --version`, `ls -la ~/.elan/`, `cat ~/.elan/env`), B3's `grep -c`
    and `tail -20` of its own answer, B5's `grep -A 15` of its own answer,
    and B7's heredoc writing `/tmp/fix_firth.py` and its `ls -lh` of its
    answer.
  - Typical calls, verbatim:
    `python3 /home/user/firth-r12/eval/s7/harness.py check --lang firth /home/user/firth-r12/eval/s7/runs/2026-09-30-check-tool/arm-b/haiku-firth-6/answer-1.md 2>&1 | head -100`,
    and, from B8, the same command followed by
    `2>&1 | grep -A 10 "^## reverse$"`.
  - None of these calls reached another sample's files or the hidden tests.
    The pre-registration voids them anyway, because the audit cannot tell a
    harmless filter from a harmful one without allowing shell syntax.
- **The stop.** At 03:39Z the coordinator set a rule: start no new samples,
  and stop the run if at least two of B5, B6 and B8 turned out to be rule
  voids. The rule was applied at 03:42Z on void status only. B5 and B6 were
  both flagged on their logs so far, and no score of theirs had been read.
  - At the rate observed, with arm B's 5 samples that had a working
    toolchain all rule voids, 40 counted arm B samples would take far more
    starts than the pre-registered feasibility stop at 40 voids allows. The
    early stop anticipates that stop; it does not replace it.
  - Samples already running finished. Arm A samples got their feedback
    rounds, and arm B voids got none.

### Scores (descriptive only)

| Passed (of 20) by answer | Arm A (as run 11) | Arm B (may run the checker) |
|---|---|---|
| 1 | 0, 10, 13 | 11 (toolchain void) |
| 2 | 0, 2, 2 | 9 (toolchain void) |
| 3 | 1, 7, 10 | 0 (toolchain void) |
| 4 | 0, 5, 5 | 0 (rule void) |
| 5 | 0, 2, 2 | 11 (rule void) |
| 6 | 0, 0, 0 | 10 (rule void) |
| 7 | 0, 0, 0 | 0 (rule void) |
| 8 | 0, 1, 8 | 9 (rule void) |
| 9 | 0, 1, 11 | |
| 10 | 0, 5, 8 | |
| 11 | 0, 0, 6 | |
| Final answers, sum | 65 over 11 samples | none counted |

- Arm A's 11 samples are counted under the pre-registered rules. They
  passed 65 tasks after round 2 (median 6). They passed 1 task in the first
  answer, against run 11 arm A's 39 over 20 samples with the same prompt.
  That difference is reported, not explained.
- Every arm B sample is void, and none got feedback. Only the first answer
  of each was scored. That answer was written after the author ran the
  checker (except B1 to B3, whose checks never ran), so it is not
  comparable with arm A's first answer.
- **Secondary 4**, the start-order analysis, keeps rule voids at their
  latest scored answer. It is shown here without a test, because arm A's
  latest answer is its third and arm B's is its first.
  - Without the toolchain voids: arm A 11 samples, sum 65; arm B 5 samples
    (B4 to B8), sum 30 (0, 11, 10, 0, 9).
  - With the toolchain voids: arm A 11 samples, sum 65; arm B 8 samples, sum
    50 (11, 9, 0, 0, 11, 10, 0, 9).
- B1 and B2 passed 11 and 9 tasks in their first answers without seeing a
  single diagnostic. Arm A's first answers passed 1 task over 11 samples.
  That contrast is striking, but it comes from 8 void samples that were not
  randomised against arm A's timing. It suggests, and does not show, that
  the arm B prompt changes how authors write before they check. Run 13 can
  test it.

### Validity findings

- **A memory hook in the account's settings fired in every author.** 380
  `hook_non_blocking_error` attachments across the 19 logs came from one
  hook, `omega-memory`'s `fast_hook.py`, run on PostToolUse (Read, Write,
  Edit, Bash) and on SessionStart after a compaction. Every one exited 127
  because the hook's Python interpreter is not in the container, and every
  one had empty stdout. It put nothing into any author's context beyond its
  own error line.
- **Status lines about other authors reached three authors.** The context
  scan (`context_seen.py`) flagged `task_status` attachments. Each names
  another author's label ("Run 12 author B7"), its state and its output log
  path.
  - B5 got 5 at 03:37:50Z and B6 got 6 at 03:37:31Z, both before their last
    write of `answer-1.md`. The pre-registered context rule voids them for
    that too, on top of their Bash calls.
  - A10 got 1 at 03:45:45Z, after its last answer was written at 03:44:56Z.
    Under the pre-registration it is reported, not voiding.
  - No tool call of any author names another author's log or directory.
  - Nothing in this session asked for these lines. They are the harness's
    own, and they arrived in a burst when several authors changed state at
    once. They can void a counted sample in either arm, so run 13 reports
    them per arm.
- **Toolchain.** No scored result contains toolchain text, and no check
  run by B4 to B8 printed any (their raw logs have no "is not on PATH" or
  "the toolchain did not build"). The preflight was logged before B7's
  start. B4 to B6 started at 03:27Z, after the fix and before the preflight
  existed.

### What run 13 changes

Run 13's pre-registration is a separate PR. It rewords arm B's tool
sentence to say that the command already prints everything and needs no
redirection or filter. It allows a closed set of exact forms of the check
command: with or without ` 2>&1`, optionally one pipe to `head -n N`,
`tail -n N` or a `grep` with a closed set of options and one quoted
pattern, and optionally the prefix `cd /home/user/firth-r12 && `. It
refuses everything else, and it makes the start-order analysis co-primary.

## What the eleven runs say about the bet

Explicit stack effects did not stop a strong model writing correct Firth from
the docs alone. On main, Sonnet matches Python on every task set except
for one run 2 `abs-diff` answer that the signed-Int change invalidated; its
other failures when first scored were checker bugs and a step budget that
have since been fixed. On the MVP set (run 4) it wrote all 20 tasks, 19 on
the first answer and the last from the example's feedback.

A weaker model is not there yet, but the gap moved with the diagnostics.
Haiku wrote correct Python every time. In Firth it failed all 20 MVP tasks
in run 4, all for one naming mistake that the checker caught and Haiku
could not repair. Once the checker's hint named the fix (#142) and that
hint reached it, Haiku passed 6 of 20 first answers and 8 after two rounds
of feedback (run 5, sample 2). Its remaining failures are mostly stack
shape, and the largest slice of those was a misleading diagnostic, since
fixed (#145). Run 6 confirmed that fix: no failure is misreported that
way any more, and branch mismatches are the largest group left, which
Haiku rarely repairs from the current message. Run 7 made that message
say how the branches differ and how to fix them, and Haiku still did not
repair them. It passed nothing in run 7. One sample bound its locals in
reverse from the start; the other, which did not, also passed nothing
after feedback where run 6's sample reached 6, and that is unexplained
(variance or a regression from the new messages). In most unrepaired
mismatches one operation reaches below the branch without the message
naming it. Run 8 added a rule against reversed locals and a message
that names that operation. The rule refused 32 answers and each was
fixed in the next round, but no counted sample passed any task and at
least 19 of 27 branch mismatches recurred (7 of them behind an earlier
error) and between 2 and 8 were repaired. Each sample repeated a
few mistakes across nearly every task, and with one diagnostic per
program two feedback rounds did not get past them. Run 9, with one
diagnostic for each refused word, passed 3, 12, 17 and 0 of 20 after two
rounds, but its answers seldom had more than one error, so the new
feedback explains little of that. Run 10 then ran both builds fresh, 10
samples each: run 8's build passed a task in 9 of 10 samples and run 9's
in 7 of 10, so run 9's gain did not reproduce and run 8's zeros were not a
property of its build. Differences between single runs of four samples
can be explained by variance alone. The checker found
most stack-shape errors before execution.
Wrong answers at runtime were logic slips that a signature cannot catch.

So the bet holds for strong models and not yet for weak ones. The
checker's diagnostics are still the lever most likely to move the weak
model (the #142 hint removed a failure that every task shared), but the
diagnostic changes from #168 to #176 taken together (among them #171's
checked reorder edits and #174's one diagnostic per refused word) did not
show a gain in a controlled comparison of the two builds (run 10,
inconclusive: 7 of 10 samples against the older build's 9 of 10). Run 10
cannot say what any one of those changes did on its own.
Run 11 tried a guide change instead: one paragraph telling authors to bind
values with `locals` and not to shuffle the stack. Authors followed it
(first answers using a shuffle word fell from 37% to 6% of answers), but
tasks passed did not rise detectably (154 against 177 over 20 samples an
arm, p = 0.26), so run 10's link between avoiding shuffles and passing is
not shown to be causal.
The costs are real. From reading the prompt to writing the first answer,
Sonnet took about 50 to 250 times longer in Firth than in Python in runs 1
and 3 (6 to 28 minutes against 7 to 8 seconds; run 2 kept no Sonnet Python
transcript), and about 31 times longer in run 4 (5 minutes 56 seconds
against 11 seconds).

## Limits and next steps

- Python is still at ceiling for both models on every task set, so these
  tasks measure Firth's cost relative to an easy baseline, not a hard one.
- Runs 1 and 2 used one sample per task, which is noisy: Haiku passed 7 of
  the easy tasks in run 1 and only 5 in run 2. Run 3 used three.
- Haiku's results vary widely between samples of one build (arm A of run
  10: 0 to 12 of 20). Four samples an arm is usually underpowered: only a
  large separation (4 of 4 against 0 of 4 gives one-sided Fisher p =
  1/70) would show a change helped, and under the rates the
  pre-registration guessed, such a run has power 0.17. Judge a change by a pre-registered control
  like run 10, with about 10 samples an arm.
- The step budget is now 100,000 steps (#119), so tasks with real loops
  (count-divisors, larger inputs) can come back.
- The repo docs now cover the new primitives (PR #113 `54387bd`), so the
  next run should drop the supplement and use the docs as they are.
