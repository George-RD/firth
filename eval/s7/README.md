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
  Boolean/integer coercion.
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
- **Branch mismatches were not repaired.** Of the 27 answers that failed
  on `firth.type.branch-mismatch` in round 1 or 2, all were resubmitted;
  none then got past the checker, 12 failed on a branch mismatch again,
  and 15 failed first on another error (12 of those are sample 5's
  round-1 answers, which all failed to parse, below). Run 7's counts were
  0, 10 and 6 of 16 resubmitted. Sample 6 repeated all 10 of its round-1
  branch mismatches in round 2 with the new message, which names the
  operation and says which values to push (`haiku-firth-6/repair-2.md`).
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
returned, extracted from those logs. Keeping offset and limit in the
audit is a follow-up. No task failed on a harness error: every counted
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
the documented `xs i` in 28 places in every round. Sample 1 suggests that
an author who gets the basics right can repair branch mismatches from the
new message, but a void sample is not evidence, and sample 5, which also
had the basics right, did not.

## What the eight runs say about the bet

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
fixed in the next round, but no counted sample passed any task and no
branch mismatch was repaired (12 of 27 recurred). Each sample repeated a
few mistakes across nearly every task, and with one diagnostic per
program two feedback rounds did not get past them. The checker found
most stack-shape errors before execution.
Wrong answers at runtime were logic slips that a signature cannot catch.

So the bet holds for strong models and not yet for weak ones, and the
checker's diagnostics are the lever that has moved the weak model most.
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
- The step budget is now 100,000 steps (#119), so tasks with real loops
  (count-divisors, larger inputs) can come back.
- The repo docs now cover the new primitives (PR #113 `54387bd`), so the
  next run should drop the supplement and use the docs as they are.
