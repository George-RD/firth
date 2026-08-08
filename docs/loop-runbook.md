# Firth autonomous loop runbook

This is the launch contract for one-unit Firth loop sessions, for any agent
harness that can re-inject one fixed prompt per iteration. The normative
prompt is the full contents of `.claude/commands/firth-loop.md`. This runbook
is descriptive and does not replace that prompt or either named skill.

## Maintainer prerequisites

Complete these checks before launching the loop:

- [ ] The remote is the canonical repository and `main` tracks it:
  `git remote -v` must show `origin git@github.com:George-RD/firth.git` for fetch
  and push; `git branch -vv` must show `main` tracking `origin/main`.
- [ ] Current commits are published first. From the repository root, run
  `git push -u origin main`. The loop worktree is created from `origin/main`,
  so a local-only commit is not visible to it.
- [ ] GitHub SSH works: `ssh -T -o BatchMode=yes -o ConnectTimeout=5 git@github.com`.
  A successful authentication normally says that GitHub does not provide shell
  access.
- [ ] GitHub CLI is authenticated with repository scope:
  `gh auth status`. It must report an active account and the `repo` scope.
- [ ] Cairn is installed and its gates hold on a clean checkout:
  `cairn --version` succeeds (0.9.x verified), `cairn scan` reports zero
  Errors, and `cairn hook all` exits 0 from a clean tree. The installed
  series' `change accept` battery is known-unreachable in this repository;
  changes are accepted per dec.loop-autonomy clause 5 (tasks complete plus
  repository gates) and archived with `cairn change apply`.
- [ ] Python 3.11 or newer with TOML support is available:
  `python3 -c 'import sys, tomllib; assert sys.version_info >= (3, 11)'`.
- [ ] The Lean toolchain resolves: `command -v lake` succeeds and
  `lake --version` runs from the repository root (elan downloads the
  pinned `leanprover/lean4:v4.30.0` on first use; elan 4.2.3 verified).
- [ ] Rust tooling for VM units: `command -v cargo` succeeds
  (rustup-managed; cargo 1.93.0 verified). VM gates run from
  `src/runtime/vm`, never the repository root, which has no Cargo
  manifest.
- [ ] A process-level watchdog exists: `command -v timeout || command -v
  gtimeout` (GNU coreutils; stock on Linux, `brew install coreutils` on
  macOS; coreutils 9.10 verified). The driver bounds every iteration with
  it; harness-internal deadline flags are not relied on.
- [ ] The chosen harness meets the loop's capability requirements: it runs a
  session non-interactively, re-injects one fixed prompt per iteration, starts
  each iteration with a fresh context, may write the workspace, and may reach
  the network for the loop's required `git push` and `gh` operations.

Do not push from this runbook until the maintainer has reviewed the local
commits. The required first publication is specifically `git push -u origin
main`, before the first loop iteration.

## Launch

Run from the repository root. The prompt passed to the harness is the complete
command file, optionally followed by one immutable `MISSION` line. Do not
summarise or reconstruct the command file.

Set `AGENT` to the harness invocation that runs one non-interactive session
with the prompt as its final argument. It is left unquoted below so that
`AGENT` may carry the harness flags that select non-interactive approval and
workspace-write sandboxing; confirm those flags against the harness's own help
output rather than assuming a spelling, and re-confirm them after upgrading it.

Run the driver as a saved script under non-interactive `sh`; never paste
it into an interactive shell. The pre-start guards are parameter-expansion
aborts (`${...:?}`), which stop a non-interactive script outright with
exit 1 but, pasted interactively, abort only their own line and let the
loop run with the invalid value. Extract and launch the block verbatim:

```text
awk '/^```sh$/{f=1;next} f&&/^```$/{exit} f' docs/loop-runbook.md > /tmp/firth-driver.sh
AGENT='<non-interactive harness invocation>' sh /tmp/firth-driver.sh
```

(That extracts the FIRST fenced sh block in this file, which is the driver
below; run it from the repository root.)

```sh
W=${W:-10} # max consecutive completions landing nothing; wedge guard, not a cap
case "$W" in ''|*[!0-9]*|0*) W= ;; esac
: "${W:?W must be a positive integer}"
MAXTIME=${MAXTIME:-7200} # per-iteration watchdog in seconds; driver-owned, process-level
case "$MAXTIME" in ''|*[!0-9]*|0*) MAXTIME= ;; esac
: "${MAXTIME:?MAXTIME must be a positive integer of seconds}"
TMO=$(command -v timeout || command -v gtimeout)
: "${TMO:?need coreutils timeout or gtimeout for the per-iteration watchdog}"
AGENT=${AGENT:?set AGENT to a non-interactive harness invocation}
MISSION='' # for example: MISSION='MISSION: toolchain only'
rc=4 # 0 exhausted, 2 halted, 3 unknown token/harness/observation failure, 4 wedged; pre-start config aborts exit 1
i=0
window=0
tfail=0
mark=$(git ls-remote origin refs/heads/main | awk '{print $1}')
: "${mark:?cannot observe origin/main; fix connectivity before launching}"
while :; do
  i=$((i + 1))
  log="/tmp/firth-loop-${i}.log"
  # Bounded log retention: keep the last 20 iteration logs. A long healthy
  # run otherwise accumulates one file per iteration for its whole life;
  # the launcher-side cleanup runs only between runs.
  if [ "$i" -gt 20 ]; then
    rm -f "/tmp/firth-loop-$((i - 20)).log"
  fi
  if ! git fetch origin main; then
    printf 'stopping: cannot fetch origin/main for prompt refresh on iteration %s\n' "$i" >&2
    rc=3; break
  fi
  if ! prompt=$(git show FETCH_HEAD:.claude/commands/firth-loop.md && printf x); then
    printf 'stopping: cannot read the loop command from origin/main\n' >&2
    rc=3; break
  fi
  prompt=${prompt%x} # printf-x idiom: command substitution strips trailing newlines; this restores the file's exact terminator bytes
  if [ -n "$MISSION" ]; then
    prompt="$prompt
$MISSION"
  fi
  "$TMO" -k 60 "$MAXTIME" $AGENT "$prompt" > "$log" 2>&1
  agent_rc=$?
  cat "$log"
  # Token acceptance (dec.driver-token-tail): exactly one distinct terminal
  # token among the last 15 non-empty lines, matched as a whole line after
  # CR strip. A token followed by its own report is accepted for
  # ITERATION COMPLETE and LOOP HALTED. LOOP EXHAUSTED is the completion
  # claim and stays strict: it counts only as the final non-empty line.
  # Zero tokens, conflicting tokens, a buried token, or a non-final
  # LOOP EXHAUSTED fail closed.
  token=$(awk '
    { sub(/\r$/, "") }
    NF { n += 1; tail[n % 15] = $0 }
    END {
      start = n - 14; if (start < 1) start = 1
      for (i = start; i <= n; i++) {
        line = tail[i % 15]
        if (line == "ITERATION COMPLETE" || line == "LOOP HALTED" || line == "LOOP EXHAUSTED") {
          if (seen != "" && seen != line) { print "AMBIGUOUS TOKENS"; exit }
          seen = line
        }
      }
      if (seen == "") exit
      if (seen == "LOOP EXHAUSTED" && tail[n % 15] != "LOOP EXHAUSTED") exit
      print seen
    }' "$log")
  if [ "$agent_rc" -eq 124 ] || [ "$agent_rc" -eq 137 ]; then
    tfail=$((tfail + 1))
    printf 'watchdog killed iteration %s after %ss (exit %s); consecutive timeouts: %s; the next iteration recovers the partial state\n' "$i" "$MAXTIME" "$agent_rc" "$tfail" >&2
    if [ "$tfail" -ge 2 ]; then
      printf 'stopping: two consecutive watchdog timeouts\n' >&2
      rc=3; break
    fi
    continue
  fi
  if [ "$agent_rc" -ne 0 ]; then
    printf 'stopping: harness exited %s on iteration %s (any token line ignored) in %s\n' "$agent_rc" "$i" "$log" >&2
    rc=3; break
  fi
  tfail=0
  case "$token" in
    "LOOP HALTED")
      printf 'stopping after iteration %s: %s\n' "$i" "$token"
      rc=2; break ;;
    "LOOP EXHAUSTED")
      printf 'stopping after iteration %s: %s\n' "$i" "$token"
      rc=0; break ;;
    "ITERATION COMPLETE")
      tip=$(git ls-remote origin refs/heads/main | awk '{print $1}')
      if [ -z "$tip" ]; then
        sleep 10
        tip=$(git ls-remote origin refs/heads/main | awk '{print $1}')
      fi
      if [ -z "$tip" ]; then
        printf 'stopping: cannot observe origin/main after iteration %s (retried once); observation failure, not a wedge\n' "$i" >&2
        rc=3; break
      fi
      if [ "$tip" != "$mark" ]; then
        mark=$tip; window=0
      else
        window=$((window + 1))
        if [ "$window" -ge "$W" ]; then
          printf 'wedged: %s consecutive ITERATION COMPLETE without a landed commit on origin/main\n' "$window" >&2
          rc=4; break
        fi
      fi
      continue ;;
    *)
      printf 'stopping: missing or unknown terminal token (harness exit %s) in %s\n' "$agent_rc" "$log" >&2
      rc=3; break ;;
  esac
done
printf 'driver result: rc=%s (0 only for LOOP EXHAUSTED)\n' "$rc"
( exit "$rc" )
```

One iteration is one session. A harness that carries context between
iterations, or that cannot re-inject the prompt unchanged, breaks the
one-unit contract in the command file and must not drive this loop.

### Launch with omp

Verified against omp 17.2.9; the complete launch, from the repository
root:

```text
awk '/^```sh$/{f=1;next} f&&/^```$/{exit} f' docs/loop-runbook.md > /tmp/firth-driver.sh
AGENT='omp -p --profile <profile> --approval-mode yolo --no-skills --' sh /tmp/firth-driver.sh
```

- `-p` runs one non-interactive session and prints the final message to
  stdout, so the terminal token lands as the last non-empty line (verified
  with a print-mode session whose stdout ended with its final line
  verbatim).
- `--approval-mode yolo` removes interactive tool approval, which
  unattended operation requires.
- `--no-skills` is required, not cosmetic: it keeps the generic cairn
  pack's skills, and their different ratification contract, out of the
  session. The loop reads its normative files by exact path and needs no
  skill mechanism.
- The trailing `--` ends option parsing before the prompt argument. The
  command file opens with YAML frontmatter, so without the terminator the
  harness parses the prompt's leading dashes as a flag (`unknown flag:
  ---`) and exits 2 on iteration 1 (observed on the first containerised
  launch, 2026-08-06; reproduced and fix verified in the runtime image).
- The per-iteration bound is the driver's watchdog (`MAXTIME`, default
  7200 seconds), not a harness flag: `timeout` kills a wedged session with
  a known exit (124 or 137), the driver tolerates one such kill and stops
  on two in a row, and the killed iteration's partial state is exactly
  what the next iteration's preflight recovery rows classify. omp's own
  `--max-time` is an in-process deadline with unreliable exit semantics
  and is deliberately not used.
- Each `omp -p` invocation is a fresh session, satisfying the
  fresh-context-per-iteration requirement.
- For unattended runs, a memory-off overlay is recommended so that
  long-term memory recall cannot leak prior-session context into an
  iteration; the tracker and graph must stay the only cross-iteration
  channel, and a bank can hold stale workflow facts that contradict the
  loop's procedure. Keep every other profile setting as configured:

  ```text
  printf 'memory:\n  backend: off\n' > ~/.omp/firth-loop-overlay.yml
  AGENT='omp -p --profile <profile> --config ~/.omp/firth-loop-overlay.yml --approval-mode yolo --no-skills --' sh /tmp/firth-driver.sh
  ```

  Verified against omp 17.2.9: with the overlay a print-mode session
  reports no injected memory block; without it, injection occurs.

Do not drive this repository with the generic `/cairn-loop` pack command
installed under `.omp/`: it resolves to cairn's generic loop mode and
ratification contract (subject-hash receipt protocol), not this
repository's selector, obligations matrix, and decision authority
(dec.loop-autonomy). `.claude/commands/firth-loop.md` is the only normative
loop here.

For a run to project completion, leave `MISSION` empty: default selection
plus backlog generation walk the obligations matrix, and the driver keeps
going for as long as work lands. There is no iteration cap: every honest
`ITERATION COMPLETE` lands exactly one commit on `origin/main` (the
command's artefact rule), so the driver instead stops `rc=4` after `W`
(default 10) consecutive completions that land nothing, which is the wedge
signature, never a checkpoint to relaunch. A failed read of `origin/main`
is retried once, then stops `rc=3` as a labelled observation failure
within the same iteration; it is never absorbed into the window or
mislabelled as a wedge. The run
ends itself with `LOOP EXHAUSTED` at project completion, or with
`LOOP HALTED` whose report opens `implementation complete; external
success criteria outstanding` when everything machine-reachable is done
and only external evidence (PRD S6) remains, or earlier on any other halt.

A launcher MAY automate one operator action: relaunching after `rc=3`
when a machine-checked provider-quota report (the harness's own usage
endpoint, never output text) positively identified exhaustion at the
stop and confirms recovery after the reported reset time. Attempts are
bounded, an unreadable or still-exhausted report stays down, and every
other exit code remains a human's decision: this automates the
documented relaunch, not recovery (dec.loop-autonomy clause 7).

## Terminal tokens and health

The loop reports its control token as the final non-empty output line
(that authoring contract in the command file is unchanged). The driver
accepts `ITERATION COMPLETE` or `LOOP HALTED` when exactly one distinct
token appears as a whole line among the last 15 non-empty lines, so a
token followed by its own report still counts. `LOOP EXHAUSTED` is the
completion claim and stays strict: it counts only as the final non-empty
line. Zero tokens, conflicting tokens, a buried token, or a non-final
`LOOP EXHAUSTED` stop the run rc 3, fail closed (dec.driver-token-tail;
twice a landed or safely-deferred iteration was discarded by
last-line-only reading: 2026-08-06, and 2026-08-08 after PR #60 landed).

| Token | Meaning | Action |
| --- | --- | --- |
| `ITERATION COMPLETE` | One unit landed, or was safely deferred with a blocked todo. | Continue to the next iteration. |
| `LOOP EXHAUSTED` | Completion of the active profile: `coverage.py` reports `loop_exhausted_valid` true (dec.loop-autonomy as amended by dec.mvp-completion). With a MISSION, it can also mean the immutable mission cannot progress. | Stop. Confirm with the dry-run preflight and the session report. |
| `LOOP HALTED` | A fail-closed state needs attention. A report opening `implementation complete; external success criteria outstanding` means everything machine-reachable is done and only the listed external evidence remains (e.g. PRD S6 under the `full` profile; no external-evidence row is inside the current `mvp` profile); any other report is an incident or defect. | Stop and investigate. Repeating halts are the durable signal, not noise. |

Review loop health in several places: merged and open PR history, todo
statuses under `meta/todos/`, `cairn status`, and the JSON emitted by
`python3 tools/loop/select_unit.py`. The selector's `next`, `eligible`,
`ineligible_open`, `blocked`, and `in_progress` fields explain selection.

## Dry-run preflight

Run this once before launch, from the repository root:

```sh
python3 tools/loop/select_unit.py --validate && python3 tools/loop/select_unit.py
python3 tools/loop/coverage.py --validate && python3 tools/loop/coverage.py
python3 tools/loop/test_driver_tokens.py
cairn scan
cairn hook all
lake build && lake test
( cd src/runtime/vm && cargo fmt --check && cargo clippy && cargo test --locked )
git remote -v
gh auth status
```

Expected results for the current spec-phase repository:

- Selector validation exits 0 and prints `{"schema": 1, "valid": true}`.
- Selector selection exits 0 with well-formed JSON: `next` is the first
  eligible open slug (at this revision `elaborator-implementation`, with
  `smt-adapter-integration` also eligible and nothing blocked). Treat the
  concrete slugs as a snapshot; the JSON contract is the requirement.
- Coverage validation exits 0. Coverage reports `first_incomplete`,
  obligation classifications, a dependency-gated `next_obligation`, and
  `loop_exhausted_valid`, all evaluated over the active completion profile
  named in `tools/loop/obligations.toml` `[completion]` (dec.mvp-completion;
  currently `mvp`). Rows outside the profile appear as `outside_profile`:
  visible roadmap that never drives generation and never blocks exhaustion.
  `loop_exhausted_valid` stays false until every profile obligation is
  generated, unblocked, and discharged; ungenerated profile obligations
  remain visible rather than being mistaken for exhaustion.
- `lake build` and `lake test` exit 0; the root lakefile's `testDriver` is
  `firthAllTest`.
- The VM crate gates exit 0 from `src/runtime/vm`.
- `cairn scan` exits 0 with zero Errors. The expected baseline includes
  `CAIRN_RECONCILE_LANGUAGE_UNKNOWN` for declared empty language paths,
  unresolved-gap warnings, and the existing governance/path warnings.
- `cairn hook all` exits 0 and reports `Decision: pass`.
- `git remote -v` shows the canonical SSH origin above.
- `gh auth status` reports an active account with `repo` scope.

After changing tracker or architecture state, repeat the selector and Cairn
checks. A scan Error, malformed selector JSON, or hook failure is a halt.
