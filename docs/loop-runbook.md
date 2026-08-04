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
- [ ] Cairn is installed in the required series: `cairn --version` must report
  `cairn 0.3.x`.
- [ ] Python 3.11 or newer with TOML support is available:
  `python3 -c 'import sys, tomllib; assert sys.version_info >= (3, 11)'`.
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
N=10
AGENT=${AGENT:?set AGENT to a non-interactive harness invocation}
MISSION='' # for example: MISSION='MISSION: toolchain only'
for i in $(seq 1 "$N"); do
  log="/tmp/firth-loop-${i}.log"
  prompt=$(cat .claude/commands/firth-loop.md)
  if [ -n "$MISSION" ]; then
    prompt="$prompt
$MISSION"
  fi
  $AGENT "$prompt" 2>&1 | tee "$log"
  token=$(awk 'NF { last=$0 } END { print last }' "$log")
  case "$token" in
    "LOOP HALTED"|"LOOP EXHAUSTED")
      printf 'stopping after iteration %s: %s\n' "$i" "$token"
      break
      ;;
    "ITERATION COMPLETE")
      continue
      ;;
    *)
      printf 'stopping: missing or unknown terminal token in %s\n' "$log" >&2
      break
      ;;
  esac
done
```

One iteration is one session. A harness that carries context between
iterations, or that cannot re-inject the prompt unchanged, breaks the
one-unit contract in the command file and must not drive this loop.

## Terminal tokens and health

The final non-empty output line is the loop control token.

| Token | Meaning | Action |
| --- | --- | --- |
| `ITERATION COMPLETE` | One unit landed, or was safely deferred with a blocked todo. | Continue to the next iteration. |
| `LOOP EXHAUSTED` | The backlog is empty, or the immutable mission cannot progress. | Stop. Review the reported reason before choosing a new mission. |
| `LOOP HALTED` | A fail-closed state needs maintainer investigation. | Stop and investigate. Repeating halts are the durable signal, not noise. |

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
git remote -v
gh auth status
```

Expected results for the current spec-phase repository:

- Selector validation exits 0 and prints `{"schema": 1, "valid": true}`.
- Selector selection exits 0 and reports `next` as `diagnostic-schema`.
  `host-language-decision` is blocked and absent from `eligible`.
- Coverage validation exits 0. Coverage reports `first_incomplete`, obligation
  classifications, and a dependency-gated `next_obligation`; ungenerated
  obligations remain visible rather than being mistaken for exhaustion.
- `cairn scan` exits 0 with zero Errors. The expected baseline includes
  `CAIRN_RECONCILE_LANGUAGE_UNKNOWN` for declared empty language paths,
  unresolved-gap warnings, and the existing governance/path warnings.
- `cairn hook all` exits 0 and reports `Decision: pass`.
- `git remote -v` shows the canonical SSH origin above.
- `gh auth status` reports an active account with `repo` scope.

After changing tracker or architecture state, repeat the selector and Cairn
checks. A scan Error, malformed selector JSON, or hook failure is a halt.
