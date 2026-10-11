# Harder tier, scored run of 11 October 2026: results

The pre-registered comparison of Firth with Python on the six scored tasks
(`preregistration.md` and `run-plan.md` in this directory, pinned in #244).
Every number below comes from `analysis-output.md`, which `analyse.py`
computes from this directory's kept files and the pin rescore in
`rescore-pin/`. Nothing here is proved: the results are measured on these
samples, and no task has a Lean cost contract, so no proved bound applies to
any run.

## The answer

S7 asks for a materially higher pass rate in Firth. This run does not show
one for any subject. Python is materially higher for DeepSeek on both
measures, and for Sonnet on the first attempt. Sonnet within two rounds is
parity at the ceiling. Haiku's comparison is incomplete.

| Subject | Kept (Python, Firth) | Within two rounds, mean of 6 (Python, Firth) | Difference, p, 95% interval | Rule | Round 1 (Python, Firth) | Difference, p, 95% interval | Rule |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Sonnet 5.5 (primary) | 8, 8 | 6.00, 5.50 | -0.50, 0.20, [-1.00, -0.13] | parity at the ceiling | 5.75, 4.38 | -1.38, 0.008, [-2.00, -0.75] | materially higher in Python |
| DeepSeek v4.1 Flash | 8, 8 | 6.00, 0.00 | -6.00, 0.0002, [-6.00, -6.00] | materially higher in Python | 5.38, 0.00 | -5.38, 0.0002, [-5.88, -4.75] | materially higher in Python |
| Haiku 5.5 (secondary) | 5, 2 | 6.00, 0.00 | -6.00, 0.048, [-6.00, -6.00] | incomplete, not a result | 6.00, 0.00 | -6.00, 0.048, [-6.00, -6.00] | incomplete, not a result |

Differences are Firth minus Python. p is the exact two-sided permutation
test over the authors' labels; the interval is the 95% percentile bootstrap,
10,000 resamples within each arm, seed 0 (`preregistration.md`, "Analysis").

- **Sonnet.** Within two rounds both arms average 5.5 or more (Firth 44 of
  48 tasks, Python 48 of 48), so the pre-registered rule makes the row parity
  at the ceiling, never a pass, whatever the interval says. On the first
  attempt Firth passed 35 of 48 and Python 46 of 48: a difference of more
  than one task per author, the interval excluding 0 and p below 0.05,
  which the pre-registration counts as materially higher in Python. Most
  Firth first-attempt losses were checker refusals that round 2 fixed
  (below).
- **DeepSeek.** Firth passed 0 of 48 tasks in both rounds; Python passed 43
  of 48 in round 1 and 48 of 48 within two. The deviation in how its
  requests were sent is stated next to this result, below.
- **Haiku.** Firth passed 0 of 12 tasks (2 authors), Python 30 of 30. The
  Firth cell reached the cap of 3 voids, so it has 2 of its 5 planned
  samples, and the comparison is reported, not a result. Its arms' voids
  differ by 2 (below). The roadmap names Haiku 4.5; the Agent tool runs
  Haiku 5.5, so this row does not meet the line "Haiku 4.5 stays as a
  secondary check", which stays open (`preregistration.md`).

- **Underscores in the task's output names.** Checkers, warehouse and
  cache-sim name their outputs with `_` (`white_took`, `ev_day`,
  `l1_hits`). Firth refuses `_` in a name, and authors who copied the names
  into their stack effects had the whole task refused: Sonnet 3 tasks in
  round 1 and 0 in round 2 (all sonnet-firth-5), DeepSeek 21 in round 1 and
  0 in round 2 (seven authors), Haiku 3 in round 1 (haiku-firth-4) and 3 in
  round 2 (haiku-firth-1). Python accepts these names, so it does not pay
  this cost. Nothing is adjusted or rescored for it: it is a confound in
  the task inputs, to be fixed in the next tier (coordinator's ruling, 11
  October 11:34Z), and the diagnostic is `todo.underscore-name-diagnostic`.

The harder tier's own criterion, that the primary subject does not sit at
the ceiling in Python or in Firth (`todo.s7-harder-task-tier`), is not met
by this set: Sonnet's Python arm passed every task within two rounds. As
that todo requires, the set is kept and reported as it stands.

## DeepSeek: the transport deviation

DeepSeek counts as pre-registered, with this deviation (coordinator's ruling
(a), 11 October 08:26Z, `run-notes.md`; the independent reviewer checks it
and may overrule it, in which case this report gives both readings):

- The pinned driver sent non-streamed requests. It completed 0 of 3 sample
  requests: deepseek-python-1, deepseek-firth-1 and deepseek-firth-2 each
  got HTTP 502 "upstream request failed" after about 30 seconds of the model
  thinking, before any reply byte (31.1 s, 31.1 s, 30.7 s; `probes.log`).
  A non-sample request with the real round-1 Firth prompt failed the same
  way (502 at 30.5 s, reply discarded unread).
- #246 (merged as 8ce2c8f) streams the reply, which is the API's default,
  and changes nothing else: model, prompts, parameters and scorer are as
  pinned. Every kept DeepSeek sample, both arms, ran streamed at 8ce2c8f
  and was scored at the pin. No kept sample used the old transport.
- The three voids count as written, against their cells: DeepSeek Python 1,
  DeepSeek Firth 2. Their cause: HTTP 502 after about 30 seconds of
  thinking, on a non-streamed request, before #246.
- Transport by sample: deepseek-python-1, deepseek-firth-1 and
  deepseek-firth-2 non-streamed (void); deepseek-python-2 to -9 and
  deepseek-firth-3 to -10 streamed (kept).
- The DeepSeek block paused at 05:05Z while the fix was reviewed, and ran
  after sample 14 in its own plan order (06:22Z to 06:58Z), while Sonnet and
  Haiku continued in plan order. So DeepSeek's samples ran in a different
  part of the run from the other subjects'; DeepSeek is compared only with
  itself.
- A health probe (`probe.py`, logged in `probes.log`) ran before each
  DeepSeek sample. It is one short non-streamed request, so it shows the API
  answered, not that a long request would get through; no kept sample
  failed after a passing probe.
- Every round's `done_reason` was `stop` (no length cut-off). Round-1
  `prompt_eval_count` was 4,634 for every Python prompt and 16,670 for every
  Firth prompt, above the one-token-per-eight-characters void line in each
  case (1,996 and 8,145).

**What DeepSeek's Firth answers did.** Seven of the eight kept DeepSeek
Firth authors (all but deepseek-firth-9) answered every task they did not
leave refused with a word that drops all of its inputs and pushes the
visible example's expected output. In round 1 that passed the visible
example for sokoban, regex and swiss and failed every hidden test; the other
three tasks were refused by the checker. In round 2 they answered the three
refused tasks the same way. Their answers are 1,687 to 2,174 characters for
six tasks, against 18,502 to 20,709 for DeepSeek's Python answers.
deepseek-firth-9 wrote one sokoban answer the checker refused, and answered
no other task in either round. So DeepSeek's Firth result is 0 because its
authors did not write programs for the tasks, and the hidden tests caught
the constant answers. The checker cannot catch them: a constant of the
right type is a well-typed program.

## Ruling out a harness fault in the Firth zeros

DeepSeek Firth at 0 of 48 and Haiku Firth at 0 were checked for a harness or
extraction fault before being read as results (coordinator's request, 11
October 11:24Z). No such fault was found.

Each task's outcome per author and round, from the pin's rescore
(`rescore-pin/`). "carried" is a task round 1's feedback did not list, scored
again from the same code; "wrong, visible passed" passed the visible example
and failed every hidden test; refusals give the diagnostic code and its row
of the code table. No task had a length cut-off, ran out of steps, trapped
or timed out.

DeepSeek Firth:

| Author | Round | sokoban | checkers | regex | swiss | warehouse | cache-sim |
| --- | --- | --- | --- | --- | --- | --- | --- |
| deepseek-firth-3 | 1 | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | wrong, visible passed | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | refused, `syntax.unexpected-token` (other refusal) |
| deepseek-firth-3 | 2 | carried | wrong, visible passed | carried | carried | wrong, visible passed | wrong, visible passed |
| deepseek-firth-4 | 1 | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | wrong, visible passed | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | refused, `syntax.unexpected-token` (other refusal) |
| deepseek-firth-4 | 2 | carried | wrong, visible passed | carried | carried | wrong, visible passed | wrong, visible passed |
| deepseek-firth-5 | 1 | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | wrong, visible passed | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | refused, `syntax.unexpected-token` (other refusal) |
| deepseek-firth-5 | 2 | carried | wrong, visible passed | carried | carried | wrong, visible passed | wrong, visible passed |
| deepseek-firth-6 | 1 | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | wrong, visible passed | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | refused, `syntax.unexpected-token` (other refusal) |
| deepseek-firth-6 | 2 | carried | wrong, visible passed | carried | carried | wrong, visible passed | wrong, visible passed |
| deepseek-firth-7 | 1 | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | wrong, visible passed | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | refused, `syntax.unexpected-token` (other refusal) |
| deepseek-firth-7 | 2 | carried | wrong, visible passed | carried | carried | wrong, visible passed | wrong, visible passed |
| deepseek-firth-8 | 1 | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | wrong, visible passed | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | refused, `syntax.unexpected-token` (other refusal) |
| deepseek-firth-8 | 2 | carried | wrong, visible passed | carried | carried | wrong, visible passed | wrong, visible passed |
| deepseek-firth-9 | 1 | refused, `syntax.unexpected-eof` (other refusal) | no answer | no answer | no answer | no answer | no answer |
| deepseek-firth-9 | 2 | refused, `syntax.unexpected-eof` (other refusal) | no answer | no answer | no answer | no answer | no answer |
| deepseek-firth-10 | 1 | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | wrong, visible passed | wrong, visible passed | refused, `syntax.unexpected-token` (other refusal) | refused, `syntax.unexpected-token` (other refusal) |
| deepseek-firth-10 | 2 | carried | wrong, visible passed | carried | carried | wrong, visible passed | wrong, visible passed |

Haiku Firth:

| Author | Round | sokoban | checkers | regex | swiss | warehouse | cache-sim |
| --- | --- | --- | --- | --- | --- | --- | --- |
| haiku-firth-1 | 1 | no answer | no answer | no answer | no answer | no answer | no answer |
| haiku-firth-1 | 2 | refused, `name.unresolved` (other refusal) | refused, `syntax.unexpected-token` (other refusal) | wrong | refused, `type.declared-effect-mismatch` (stack effects) | refused, `syntax.unexpected-token` (other refusal) | refused, `syntax.unexpected-token` (other refusal) |
| haiku-firth-4 | 1 | refused, entry type, no code (other refusal) | refused, `syntax.unexpected-token` (other refusal) | refused, `type.declared-effect-mismatch` (stack effects) | refused, `type.declared-effect-mismatch` (stack effects) | refused, `syntax.unexpected-token` (other refusal) | refused, `syntax.unexpected-token` (other refusal) |
| haiku-firth-4 | 2 | wrong | wrong | wrong | wrong | wrong | wrong |

What was checked against what the scorer saw:

- **DeepSeek's content, not its thinking.** For all 16 kept DeepSeek Firth
  rounds (and the 11 DeepSeek Python rounds) the answer file equals the
  streamed reply's `message.content` byte for byte, holds none of its
  `message.thinking`, and every `done_reason` is `stop`. deepseek-firth-3's
  thinking ends with the decision "So the hardcoded outputs are correct ...
  Let's write the final answer", and its content is those constants.
- **The prompts sent.** Every DeepSeek round-1 request holds the whole
  `prompt-firth.md` or `prompt-python.md`; deepseek-firth-3's round-2
  request holds its round-1 answer and the whole of `repair-1.md`.
- **Haiku's answer files.** For haiku-firth-1 and haiku-firth-4, each answer
  file's sha256 equals the content hash of the author's one `Write` call in
  `transcript.json`. haiku-firth-1's round-1 file is one unclosed sokoban
  block (its hand-back: "Not complete ... wrote an incomplete stub"), so no
  task was taken.
- **Extraction.** Splitting every answer file above into its
  `### task:` blocks with a separate regular expression gives exactly the
  solutions `tier.py take` scored, for every round.

Three of the refusals are reported worse than they should be. They are
checker and runner defects, not scoring faults, filed as todos:

- deepseek-firth-9's `unexpected-eof` is at the last line of a 250-line
  answer; the real error is an unnamed output (`-- Bool )`) on line 1
  (`todo.unnamed-output-diagnostic`). The author got the same report in
  both rounds and its round-2 answer kept the same error.
- haiku-firth-4's sokoban declared `cells:Seq^many`. The checker accepts
  any name as a type (`Seq` alone, or `Foo`), and the runner then refuses
  the entry with no code (`todo.unknown-base-type`).
- The `unexpected-token` refusals are all `_` in a name: checkers, warehouse
  and cache-sim name outputs such as `white_took`, which authors of every
  subject copied into their stack effects (30 task refusals, sonnet-firth-5
  included). The report says `expected ':'` without saying `_` is not
  allowed in a name (`todo.underscore-name-diagnostic`). Every author with a
  later round fixed it there.

## Voids and crashes

Counted per arm and by cause, from the files (`analyse.py` re-derives them
and checks them against `voids.txt`):

| Cell | Kept | Voids and crashes | Causes |
| --- | --- | --- | --- |
| Sonnet Python | 8 | 0 | |
| Sonnet Firth | 8 | 1 | context: sonnet-firth-8 (sample 39) |
| DeepSeek Python | 8 | 1 | transport: deepseek-python-1 (sample 3) |
| DeepSeek Firth | 8 | 2 | transport: deepseek-firth-1 (4), deepseek-firth-2 (9) |
| Haiku Python | 5 | 1 | audit flag: haiku-python-3 (17), a `send_message` call |
| Haiku Firth | 2 | 3 (cap) | audit flag: haiku-firth-2 (11), a `send_message` call; audit flag: haiku-firth-3 (18), its answer file written twice with different content; context: haiku-firth-5 (30) |

No sample crashed. Haiku's arms differ by 2 voids (Firth 3, Python 1), so the
samples that survived may differ between its arms. The cap stopped Haiku
Firth's replacements, so haiku-firth-6 and -7 never ran.

**An injected item the pre-registration did not list.** Two authors,
haiku-firth-5 and sonnet-firth-8, were shown a 141-character harness line,
"[handback-send-enforce] Your report has not been delivered. Call
SubagentHandback(...) now; the call ends your run.", after writing their
answer file and before handing back. It is not on the pre-registration's
list of known injected items, and "any other injected item ... voids the
sample", so both are void (coordinator's ruling, the same literal reading
as the DeepSeek voids). haiku-firth-5 was first kept on a timing argument
and then voided when that was found not to be in the pre-registration
(`run-notes.md`).

**Haiku authors calling `send_message`.** Both calls failed and reached no
session. They are filed as `todo.s7-author-tool-set`.

## Failure causes

Per author, per task and per round in `analysis-output.md`. In short:

- **Sonnet Firth**, round 1: 13 tasks failed. 10 were checker refusals on
  the visible example (checkers 3, regex 3, warehouse 2, sokoban 1,
  cache-sim 1); round 2 fixed 9 of them and left sonnet-firth-6's regex a
  wrong result on 16 of 25 hidden tests. The other 3 never got a round 2,
  because their visible examples passed: sonnet-firth-1's regex ran out of
  steps on 1 hidden input, and swiss trapped (`primitive-fault`) on 1 hidden
  input for sonnet-firth-1 and sonnet-firth-2.
- **Sonnet Python**, round 1: 2 wrong results (sonnet-python-6 sokoban,
  sonnet-python-7 checkers), both fixed in round 2.
- **DeepSeek Firth**: constant answers and refusals, per task in "Ruling out
  a harness fault".
- **DeepSeek Python**, round 1: 5 failures (checkers 2 wrong results, regex
  2 runtime errors and 1 wrong result counted per task as runtime error,
  cache-sim 1 no answer), all fixed in round 2.
- **Haiku Firth**: haiku-firth-1 answered nothing in round 1; haiku-firth-4
  was refused on all six (per task in "Ruling out a harness fault"). In
  round 2 both left placeholder answers (zeros
  and empty sequences) or refusals, and passed nothing.
- **Haiku Python**: every task passed in round 1.

No run was out of steps except sonnet-firth-1's regex (one hidden input), and
no case timed out.

## The guarantees

For each guarantee the roadmap names, whether this run showed it catching a
real error (a refusal on the visible example in round 1 whose author's
round-2 answer behaves differently on some hidden test). Rows are sorted by
diagnostic code, as `preregistration.md` "Sorting a case's error" sets out.

| Guarantee | Sonnet | DeepSeek | Haiku |
| --- | --- | --- | --- |
| Stack effects | 2 refusals, 2 caught | 0 | 2 refusals, 2 caught |
| Checked types | 4 refusals (5 diagnostics), 4 caught | 0 | 0 |
| Linear ownership | 0 | 0 | 0 |
| Declared effects | not exercised (no task uses an effectful primitive) | not exercised | not exercised |
| Other refusals (never a catch) | 4 | 22 | 4 (one with no `code:` line: the runner refused haiku-firth-4's sokoban entry type, `Seq` with no element type) |
| Out of steps (1,000,000 steps) | 1 (sonnet-firth-1 regex, hidden) | 0 | 0 |
| Runtime refusals on hidden inputs | 2 (swiss `primitive-fault`, sonnet-firth-1 and -2) | 0 | 0 |
| Proved cost bound | none applies | none applies | none applies |

"Caught" here is the pre-registered test read literally: the corrected
answer's outcome on some hidden test differs from the refused answer's,
which was a refusal on every case. Every Sonnet and Haiku catch counted
above also ran in round 2 (the last column of `analysis-output.md`'s
guarantee tables), so none counts a refusal that was only replaced by
another refusal. Of Sonnet's 6 catches (all `branch-mismatch` or
`word-input-mismatch`), 5 passed every hidden test in round 2;
sonnet-firth-6's regex was refused for a checked type and gave wrong results
in round 2. Haiku's two stack-effect catches (haiku-firth-4's regex and
swiss, `declared-effect-mismatch`) led to placeholder answers
that still failed every hidden test: the refusal was real, and the fix was
not a solution.

**Measured cost.** Kernel steps counted by the reference interpreter, for
every Firth case that ran to completion, are in `analysis-output.md` per
subject, task and round, with passed and wrong-result cases apart and runs
with no measured cost (refusals, traps, out of steps) counted on their own.
They are measured, never a bound.

## A reading nobody listed

Every failed hidden test is traced to the rule it turns on, refusals
included, in `readings.json`: 1,663 failed hidden tests in 104 traces, and
`analyse.py` checks that each is traced exactly as the pre-registration's
"Detection" step requires. None follows another reading of its rule's
sentence, so no ruling is needed and there is no sensitivity check.

- 47 traces are answers that compute nothing: the seven DeepSeek authors'
  constants (42) and Haiku's fixed-output placeholders (5).
- 44 traces are refusals, each with its diagnostic code. The refused text
  turns on no sentence of a task; the `_` refusals are the confound above.
- 11 traces are bugs in answers that ran: DeepSeek Python 5 (checkers 2;
  regex 3, deepseek-python-9's two bugs traced apart), Sonnet Firth 4
  (sonnet-firth-1 and -2's swiss state sequences too short for 12 players,
  sonnet-firth-6's regex count overwritten, sonnet-firth-1's regex too slow
  for the largest allowed input) and Sonnet Python 2. Nine are confirmed by
  a fix in one place (two for deepseek-python-9's group cases, which need
  both of its fixes) that turns exactly the failing cases into passes;
  `trace-checks/checks.sh` reruns each from the pin checkout, and its
  output is `trace-checks/checks-output.txt`. deepseek-python-5's regex
  crashes on every valid pattern, as the rerun shows. sonnet-firth-1's regex
  is measured instead: one 12-letter string costs 366,324 VM steps, so the
  case's 8 strings need about 2.9 million against the stated limit of
  1,000,000.
- 2 traces are haiku-firth-4's round-2 placeholders, which echo their input
  with every counter 0; its answer says the logic was not written.

The closest call, still traced as the same reading, is deepseek-python-5's
checkers: its answer counts a sequence of no jumps as a capture. Read alone,
"A capture is a sequence of jumps by one piece" might allow that, but then
"If it cannot capture it makes the step" and "if the side to move has no
capture or step, it has lost" could never apply, and the visible example
fails under it. The reviewer may rule on it; until then it counts as
scored.

## Rescoring at the pin

Every kept answer of all 39 kept samples was scored again from a checkout of
the pin, 627a0eb, by `rescore.sh`, which checks the checkout's commit. All
120 solutions and results files are identical to the live ones in tasks,
cases and the `eval_sha256`, `fuel` and `lang` headers
(`rescore-pin/compare.txt`). The results above are the pin's, and they match
the live scores exactly. `rescore.sh --self-test` plants a flipped pass, a
changed cost, a changed header and a changed solution, and the comparison
reports each.

## Limits

- Sample sizes are those pre-registered: 8 per arm for Sonnet and DeepSeek,
  5 per arm planned for Haiku. `power.py` gives about 0.4 power for a true
  difference of 1 task at 8 per arm.
- The Firth authors had no standard library and had to define every word
  they used; the Python authors had Python's builtins
  (`preregistration.md`, "Context"). Staging the standard library for a
  later tier is `todo.s7-stage-stdlib`.
- The Firth prompt is about 3.6 times the Python prompt in tokens (16,670
  against 4,634 for DeepSeek), because it carries the language guide.
- The harness's output-limit continuation fell on the Firth arm only. Its
  text is "Output token limit hit. Resume directly ...", injected after an
  author's turn was cut off at the output limit, and the author then
  carried on. It reached 7 of 8 kept Sonnet Firth authors (all but
  sonnet-firth-4), both kept Haiku Firth authors, and none of the 13 kept
  Python authors. Each affected author got it once, in the turn between
  reading the prompt and writing its round-1 answer. It is a pre-registered known item
  (`preregistration.md`, "Known injected items"), so no sample is void and
  no number changes, but most Firth authors were cut off once and resumed
  and no Python author was, which a reader of the Sonnet round-1 row should
  weigh. `context-seen.json` stores no text and records the item only as
  kind `other`, 183 characters. The identification rests on the raw
  session logs, which are not committed; `continuation.py` read them, and
  its output, `continuation.txt`, gives each author's count, log line,
  time and length, and the item's one text. It cannot be re-run from this
  PR without those logs.
- The S7 inputs were frozen during authoring (`run-notes.md`); every author
  saw the same version of the guide and prompts, built at the pin.
- Each kept transcript's model id is in `analysis-output.md`:
  claude-sonnet-5-5 for every Sonnet author, claude-haiku-5-5 for every Haiku
  author, deepseek-v4.1-flash for every DeepSeek response.
