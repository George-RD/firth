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

```sh
W=${W:-10} # max consecutive completions landing nothing; wedge guard, not a cap
case "$W" in ''|0|*[!0-9]*) W= ;; esac
: "${W:?W must be a positive integer}"
AGENT=${AGENT:?set AGENT to a non-interactive harness invocation}
MISSION='' # for example: MISSION='MISSION: toolchain only'
rc=4 # 0 exhausted, 2 halted, 3 unknown token/harness/observation failure, 4 wedged; pre-start config aborts exit 1
i=0
window=0
mark=$(git ls-remote origin refs/heads/main | awk '{print $1}')
: "${mark:?cannot observe origin/main; fix connectivity before launching}"
while :; do
  i=$((i + 1))
  log="/tmp/firth-loop-${i}.log"
  prompt=$(cat .claude/commands/firth-loop.md)
  if [ -n "$MISSION" ]; then
    prompt="$prompt
$MISSION"
  fi
  $AGENT "$prompt" > "$log" 2>&1
  agent_rc=$?
  cat "$log"
  token=$(awk '{ sub(/\r$/, "") } NF { last=$0 } END { print last }' "$log")
  if [ "$agent_rc" -ne 0 ]; then
    printf 'stopping: harness exited %s on iteration %s (any token line ignored) in %s\n' "$agent_rc" "$i" "$log" >&2
    rc=3; break
  fi
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

Verified against omp 17.2.9:

```sh
AGENT='omp -p --approval-mode yolo --no-skills --max-time 2h'
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
- `--max-time 2h` bounds a wedged iteration. A session killed mid-iteration
  leaves exactly the states the preflight recovery rows classify; the next
  iteration recovers, so the bound is safe.
- Each `omp -p` invocation is a fresh session, satisfying the
  fresh-context-per-iteration requirement.

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

## Terminal tokens and health

The final non-empty output line is the loop control token.

| Token | Meaning | Action |
| --- | --- | --- |
| `ITERATION COMPLETE` | One unit landed, or was safely deferred with a blocked todo. | Continue to the next iteration. |
| `LOOP EXHAUSTED` | Project completion: `coverage.py` reports `loop_exhausted_valid` true (dec.loop-autonomy). With a MISSION, it can also mean the immutable mission cannot progress. | Stop. Confirm with the dry-run preflight and the session report. |
| `LOOP HALTED` | A fail-closed state needs attention. A report opening `implementation complete; external success criteria outstanding` means everything machine-reachable is done and only the listed external evidence (e.g. PRD S6) remains; any other report is an incident or defect. | Stop and investigate. Repeating halts are the durable signal, not noise. |

Review loop health in several places: merged and open PR history, todo
statuses under `meta/todos/`, `cairn status`, and the JSON emitted by
`python3 tools/loop/select_unit.py`. The selector's `next`, `eligible`,
`ineligible_open`, `blocked`, and `in_progress` fields explain selection.

## Dry-run preflight

Run this once before launch, from the repository root:

```sh
python3 tools/loop/select_unit.py --validate && python3 tools/loop/select_unit.py
python3 tools/loop/coverage.py --validate && python3 tools/loop/coverage.py
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
  `loop_exhausted_valid` (false until every obligation is generated,
  unblocked, and discharged); ungenerated obligations remain visible rather
  than being mistaken for exhaustion.
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
