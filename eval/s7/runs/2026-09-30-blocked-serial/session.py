#!/usr/bin/env python3
"""The per-session runner of S7 run 14 (preregistration.md, "Runbook for each session").

A runner session follows the runbook by running these commands, in the
pinned worktree, and doing exactly what each one prints. Every choice is
made here, so the runner makes none; anything that needs one prints a line
starting `STOP:`, and the runner then tells the driver and does nothing
else.

  python3 session.py setup SESSION --pin SHA   once, before anything else
  python3 session.py hookcheck SESSION [AGENT_ID]
                                               once after setup: without an id
                                               it prints the hook-check author
                                               to start; with it, checks its log
  python3 session.py next SESSION              start the next sample
  python3 session.py started SESSION AGENT_ID  record the author just started
  python3 session.py round SESSION             after each hand-back: score,
                                               audit, scan, print what to send
  python3 session.py --self-test

SESSION is s1 to s5. Samples are numbered across sessions in start order:
block k (1 to 8) of session j is sample (k - 1) * 5 + j in each arm, so an
arm's samples 1 to 40 are its start order (block, then session). Blocks
beyond 8 are started only when the driver lists them in
`extra-blocks.txt` in the shared folder, one line `SESSION BLOCK ORDER N`.

A sample's files stay in `arm-<a>/haiku-firth-<N>/` of this directory and
are copied, with the session's state and hook log, to the shared folder
after the sample's `final.md`. Validity is decided here by exit codes
only (`void_causes`): every check's exit status goes in `checks.json`, and
a nonzero one writes `void.md` in the form `analyse.py` reads (`write_void`:
one header `rule: <causes>: ...`, the causes merged over rounds, then a
line per round and the audit's flagged lines). A toolchain failure writes
`void.md` and `final.md` (`write_toolchain`), and stops the session.
Any exit code but 0 or 1 from a check stops the session for the driver.
"""
import json
import os
import random
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

RUN = Path(__file__).resolve().parent
S7 = RUN.parents[1]
W = RUN.parents[3]
WORKTREE = Path("/home/user/firth-r14")  # the path the prompts name
MAIN = Path("/home/user/firth")  # the session's own checkout, whose AGENTS.md authors see
HOOK = Path("/home/user/r14-hook")  # STATE's path is fixed by the skill's hook command
AGENT_FILE = Path(".claude/agents/s7-author.md")
SKILL = Path(".claude/skills/s7-author-hook/SKILL.md")  # registers the hook (author_hook.py)
SEEN = HOOK / "seen.jsonl"  # every call the hook passed as not an author's
RUN14_SHARED = Path("/mnt/project-files/s7-eval/run14")


def shared() -> Path:
    """The shared folder this session publishes to: the run's own, unless
    `R14_SHARED` names another. The smoke test sets it to `run14-smoke`, so
    nothing it writes (samples, STOP) can reach the run's folder."""
    return Path(os.environ.get("R14_SHARED") or RUN14_SHARED)
SESSIONS = ("s1", "s2", "s3", "s4", "s5")
ARMS = {"A": "arm-a", "B": "arm-b"}
# preregistration.md, "Order": four AB and four BA per session, one
# random.Random(14).shuffle per session, s1 to s5 in turn.
ORDER = {"s1": "AB AB AB BA BA BA BA AB", "s2": "BA BA AB AB AB AB BA BA",
         "s3": "BA BA AB AB AB AB BA BA", "s4": "BA AB AB AB BA BA AB BA",
         "s5": "AB AB BA BA BA BA AB AB"}
AUTHORS_PATH = ("/root/.local/bin:/root/.cargo/bin:/usr/local/go/bin:/opt/node22/bin:/opt/maven/bin:"
                "/opt/gradle/bin:/opt/rbenv/bin:/root/.bun/bin:/usr/local/sbin:/usr/local/bin:"
                "/usr/sbin:/usr/bin:/sbin:/bin")  # run 13's pinned.txt
SCRATCH = RUN / "scratch-answer.md"
# Run 13's toolchain (its pinned.txt), as `lake --version` and `lean --version` print it.
TOOLCHAIN = ("Lake version 5.0.0-src+d024af0", "commit d024af099ca4bf2c86f649261ebf59565dc8c622", "cargo ")
HOOK_TEST_DIR = HOOK / "hook-test"
TOOLCHAIN_TEXT = re.compile(r"toolchain:|lake: exit|cargo: exit|is not available|the toolchain did not build"
                            r"|is not on PATH")


class Stop(Exception):
    """Something the runner must not decide: it tells the driver and stops."""


class Toolchain(Stop):
    """The toolchain failed: the sample is a toolchain void, and the session stops."""


CAUSES = ("audit", "agent-files", "context")  # the names analyse.py's CAUSES uses


def write_void(d: Path, causes: list[str], r: int, when: str, flagged: list[str]) -> None:
    """Record a round's rule-void causes in `void.md`: one header line
    `rule: <causes>: ...` with every round's causes merged, as `analyse.py`
    reads the first line, then the rounds' own lines."""
    v = d / "void.md"
    old = v.read_text().splitlines() if v.is_file() else []
    before = [c.strip() for c in old[0].split(":", 2)[1].split(",")] if old else []
    merged = [c for c in CAUSES if c in before or c in causes]
    body = old[1:] + [f"  round {r} at {when}: {', '.join(causes)}"] + [f"    {x}" for x in flagged]
    v.write_text(f"rule: {', '.join(merged)}: exit codes of the checks, by round below (session.py)\n"
                 + "".join(line + "\n" for line in body))


def write_toolchain(d: Path, why: str, when: str) -> str:
    stamp = f"toolchain: stopped {when}"
    (d / "void.md").write_text(f"{stamp}\n{why}\n")
    (d / "final.md").write_text(stamp + "\n")
    return stamp


def write_final(d: Path, when: str) -> None:
    (d / "final.md").write_text(f"final {when}: audit and scans run on the complete log after answer 3 "
                                "was scored\n")


def void_causes(res: dict) -> list[str]:
    """A round's rule-void causes, from exit codes alone: the audit (a call off
    the list that ran, an unmatched hook record, an answer not rebuilt from
    the author's calls), the agent-files check and the context scan each exit
    1 when they find one. Any other code is not a verdict and stops."""
    codes = {"audit": res["audit_exit"], "agent-files": res["agents_exit"], "context": res["context_exit"]}
    odd = {k: v for k, v in codes.items() if v not in (0, 1)}
    if odd:
        raise Stop(f"a check exited with a code that is not 0 or 1: {odd}")
    return [k for k, v in codes.items() if v == 1]


def now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sh(*cmd, cwd=None, env=None, timeout=3600) -> subprocess.CompletedProcess:
    return subprocess.run([str(c) for c in cmd], cwd=cwd, env=env, capture_output=True, text=True,
                          timeout=timeout)


# Order and numbering ------------------------------------------------------

def draw_orders() -> dict:
    r = random.Random(14)
    out = {}
    for s in SESSIONS:
        b = ["AB"] * 4 + ["BA"] * 4
        r.shuffle(b)
        out[s] = " ".join(b)
    return out


def extra_blocks(session: str, text: str) -> list[tuple[int, str, int]]:
    """The driver's extra blocks for SESSION: (block, order, N), in file order."""
    out = []
    for line in text.splitlines():
        f = line.split()
        if not f or f[0].startswith("#"):
            continue
        if len(f) != 4 or f[0] not in SESSIONS or f[2] not in ("AB", "BA") or not f[1].isdigit() \
                or not f[3].isdigit() or int(f[1]) <= 8 or int(f[3]) <= 40:
            raise Stop(f"extra-blocks.txt has a line this script cannot read: {line!r}")
        if f[0] == session:
            out.append((int(f[1]), f[2], int(f[3])))
    return out


def queue(session: str, extra_text: str = "") -> list[tuple[int, str, int]]:
    """The session's samples in start order: (block, arm, N)."""
    j = SESSIONS.index(session) + 1
    blocks = [(k, o, (k - 1) * 5 + j) for k, o in enumerate(ORDER[session].split(), 1)]
    blocks += extra_blocks(session, extra_text)
    return [(k, arm, n) for k, o, n in blocks for arm in o]


def sample_dir(arm: str, n: int, run: Path = RUN) -> Path:
    return run / ARMS[arm] / f"haiku-firth-{n}"


def label(session: str, arm: str, n: int) -> str:
    return f"{session}-{arm}{n}"


# Session state --------------------------------------------------------------

def sdir(session: str) -> Path:
    return RUN / "sessions" / session


def load(session: str) -> dict:
    p = sdir(session) / "state.json"
    return json.loads(p.read_text()) if p.is_file() else {"current": None, "done": []}


def save(session: str, st: dict, note: str) -> None:
    d = sdir(session)
    d.mkdir(parents=True, exist_ok=True)
    (d / "state.json").write_text(json.dumps(st, indent=1) + "\n")
    with open(d / "state.md", "a") as f:
        f.write(f"{now()} {note}\n")


def templates() -> dict:
    return json.loads((RUN / "instructions-templates.json").read_text())


def instruction(arm: str, n: int, r: int) -> str:
    """What the runner sends: the start prompt (r = 0) or feedback round r,
    without the wrapper the harness adds around a message to a running agent."""
    t = templates()[arm][r].replace("{ARM}", ARMS[arm]).replace("{N}", str(n))
    pre, post = "The coordinator sent a message while you were working:\n", \
        "\n\nAddress this before completing your current task."
    if r:
        if not (t.startswith(pre) and t.endswith(post)) or "{" in t:
            raise Stop(f"the arm {arm} template for round {r} does not fit")
        t = t[len(pre):-len(post)]
    elif "{" in t:
        raise Stop(f"the arm {arm} start template does not fit")
    return t


def find_log(agent: str) -> Path:
    hits = sorted(Path("/root/.claude/projects").glob(f"*/*/subagents/agent-{agent}.jsonl"))
    hits += sorted(Path("/tmp").glob(f"claude-*/*/*/tasks/{agent}.output"))
    if not hits:
        raise Stop(f"no log found for author {agent}")
    return hits[0]


# Checks ---------------------------------------------------------------------

def scratch_check() -> str:
    """The check of the scratch answer in the authors' own shell environment."""
    env = {"HOME": "/root", "PATH": AUTHORS_PATH}
    p = sh("python3", S7 / "harness.py", "check", "--lang", "firth", SCRATCH, env=env, timeout=3600)
    return (p.stdout + p.stderr).strip()


def write_state(prompt: Path, d: Path, check_cmd) -> None:
    HOOK.mkdir(parents=True, exist_ok=True)
    (HOOK / "state.json").write_text(json.dumps({
        "prompt": str(prompt), "dir": str(d), "rounds": 2,
        "check_cmd": str(check_cmd) if check_cmd else None, "log": str(HOOK / "hook-log.jsonl")}))


def hook_dry_run() -> list[str]:
    """Feed the hook a planted off-list call and the allowed check, with STATE
    pointed at a scratch arm B sample. Returns the problems."""
    d = HOOK_TEST_DIR / "arm-b" / "haiku-firth-1"
    d.mkdir(parents=True, exist_ok=True)
    shutil.copy(SCRATCH, d / "answer-1.md")
    write_state(RUN / "arm-b" / "prompt-firth.md", d, S7 / "harness.py")
    check = f"python3 {S7 / 'harness.py'} check --lang firth {d}/answer-1.md"
    problems = []
    for tool, inp, want in (("Glob", {"pattern": "*"}, 2), ("Bash", {"command": check}, 0)):
        p = subprocess.run([sys.executable, str(S7 / "author_hook.py"), "--state", str(HOOK / "state.json"),
                            "--only", "s7-author"],
                           input=json.dumps({"tool_name": tool, "tool_input": inp, "agent_type": "s7-author",
                                             "tool_use_id": f"preflight-{tool}"}),
                           capture_output=True, text=True, timeout=60)
        if p.returncode != want or (want == 2 and "[s7-author-hook]" not in p.stderr):
            problems.append(f"hook on {tool}: exit {p.returncode}, stderr {p.stderr.strip()[:200]!r}")
    return problems


def hook_registered(seen: Path, cmd: str, session: str, within: int = 300) -> bool:
    """True when the hook recorded, as a call that is not an author's, the
    runner's Bash call of `session.py CMD SESSION` in the last `within`
    seconds: the hook fires before a call runs, so the command running now
    is there if and only if the hook is registered in this session."""
    if not seen.is_file():
        return False
    now_t = datetime.now(timezone.utc)
    for line in seen.read_text().splitlines():
        try:
            e = json.loads(line)
            at = datetime.fromisoformat(e["at"])
        except (ValueError, KeyError, TypeError):
            continue
        if (e.get("tool_name") == "Bash" and e.get("agent_type") is None
                and f"session.py {cmd} {session}" in (e.get("command") or "")
                and 0 <= (now_t - at).total_seconds() <= within):
            return True
    return False


def require_hook(cmd: str, session: str) -> None:
    if not hook_registered(SEEN, cmd, session):
        raise Stop(f"the author hook is not registered in this session: {SEEN} has no record of this "
                   f"`session.py {cmd} {session}` call (runbook step 2 invokes the s7-author-hook skill)")


def preflight() -> None:
    out = scratch_check()
    if out != "## sum-list\nok":
        raise Stop(f"preflight: the scratch check printed {out[:300]!r}, not '## sum-list' and 'ok'")
    problems = hook_dry_run()
    if problems:
        raise Stop("preflight: " + "; ".join(problems))


def write_stop(line: str) -> None:
    shared().mkdir(parents=True, exist_ok=True)
    with open(shared() / "STOP", "a") as f:
        f.write(line + "\n")


def stop_file() -> str | None:
    p = shared() / "STOP"
    return p.read_text().strip() or "STOP" if p.is_file() else None


# Commands -------------------------------------------------------------------

def cmd_setup(session: str, pin: str) -> None:
    if W != WORKTREE:
        raise Stop(f"this script is in {W}, not {WORKTREE}")
    head = sh("git", "-C", W, "rev-parse", "HEAD").stdout.strip()
    if not pin or not head.startswith(pin):
        raise Stop(f"the worktree is at {head}, not the pin {pin}")
    if sh("git", "-C", W, "status", "--porcelain", "--untracked-files=no").stdout.strip():
        raise Stop("the worktree has changed tracked files")
    blobs = {f: sh("git", "-C", W, "rev-parse", f"HEAD:{f}").stdout.strip() for f in ("AGENTS.md", "CLAUDE.md")}
    for f, b in blobs.items():
        mb = sh("git", "-C", MAIN, "hash-object", MAIN / f).stdout.strip()
        if mb != b:
            raise Stop(f"{MAIN / f} is blob {mb}, not the pinned {b}: authors would see another {f}")
    for f in (AGENT_FILE, SKILL):
        if not (W / f).is_file() or not (MAIN / f).is_file() or (MAIN / f).read_bytes() != (W / f).read_bytes():
            raise Stop(f"{MAIN / f} is missing or differs from the pinned {W / f}")
    held = [d for a in ARMS.values() for d in (shared() / session / a).glob("haiku-firth-*")]
    if held or (shared() / "STOP").exists():
        raise Stop(f"{shared()} already holds a STOP file or {len(held)} sample(s) of {session}; "
                   "the driver empties it first")
    p = sh("python3", RUN / "make_prompts.py", "--check", cwd=S7)
    if p.returncode:
        raise Stop(f"make_prompts.py --check: {p.stdout}{p.stderr}")
    versions = sh("bash", "-c", "lake --version; lean --version; cargo --version",
                  env={"HOME": "/root", "PATH": AUTHORS_PATH}, cwd=W).stdout.strip()
    if not all(v in versions for v in TOOLCHAIN):
        raise Stop(f"the authors' shell has not the pinned toolchain {TOOLCHAIN}: {versions[:300]!r}")
    out = scratch_check()  # builds the toolchain on first use
    if out != "## sum-list\nok":
        raise Stop(f"the scratch check printed {out[:300]!r}")
    sdir(session).mkdir(parents=True, exist_ok=True)
    (sdir(session) / "pinned.txt").write_text(
        f"run 14 session {session}, set up {now()}\nworktree {W} HEAD {head}\n"
        f"make_prompts.py --check: {p.stdout.strip()}\npinned blobs {json.dumps(blobs)}; "
        f"{MAIN} has the same\nagent file {AGENT_FILE} and skill {SKILL} identical in {MAIN} and {W}\n"
        f"toolchain (authors' PATH): {versions}\nscratch check: ok\n")
    save(session, load(session), "setup ok")
    publish(session)
    print(f"SETUP OK for {session}. Next run: python3 {RUN / 'session.py'} hookcheck {session}")


HOOK_CHECK_PROMPT = (
    "This is a test of a tool hook. Make exactly these two tool calls, one after the other, and "
    "nothing else. First, the Glob tool with pattern \"*\". Second, the Bash tool with exactly this "
    "command:\n\n    {check}\n\nThen reply with the text of both results, verbatim.")


def cmd_hookcheck(session: str, agent: str | None) -> None:
    d = HOOK_TEST_DIR / "arm-b" / "haiku-firth-1"
    check = f"python3 {S7 / 'harness.py'} check --lang firth {d}/answer-1.md"
    if not agent:
        require_hook("hookcheck", session)
        if hook_dry_run():
            raise Stop("the hook dry run failed: " + "; ".join(hook_dry_run()))
        print("START THE HOOK-CHECK AUTHOR with the Agent tool: subagent_type \"s7-author\", "
              f"model \"haiku\", description \"Run 14 hook check {session}\", and this prompt, exactly "
              "the text between the lines:\n-----\n" + HOOK_CHECK_PROMPT.format(check=check) +
              f"\n-----\nWhen it hands back, run: python3 {RUN / 'session.py'} hookcheck {session} "
              "<its agent id>")
        return
    events = [json.loads(l) for l in find_log(agent).read_text().splitlines() if l.strip()]
    sys.path.insert(0, str(S7))
    from audit_subagent import hook_denials
    stopped, bad = hook_denials(HOOK / "hook-log.jsonl", events)
    calls = {b["id"]: b["name"] for e in events if e.get("type") == "assistant"
             for b in e["message"]["content"] if isinstance(b, dict) and b.get("type") == "tool_use"}
    globs = [i for i, n in calls.items() if n == "Glob"]
    bashes = [i for i, n in calls.items() if n == "Bash"]
    ran = {b["tool_use_id"] for e in events if e.get("type") == "user"
           for b in (e["message"]["content"] if isinstance(e["message"]["content"], list) else [])
           if isinstance(b, dict) and b.get("type") == "tool_result" and "sum-list" in json.dumps(b.get("content"))}
    problems = list(bad)
    if not globs or any(g not in stopped for g in globs):
        problems.append(f"the Glob call was not stopped by the hook (calls {calls})")
    if not bashes or not any(b in ran and b not in stopped for b in bashes):
        problems.append("the allowed check did not run")
    if problems:
        raise Stop("hook check failed: " + "; ".join(problems))
    save(session, load(session), f"hookcheck ok (author {agent})")
    publish(session)
    print(f"HOOK CHECK OK. Next run: python3 {RUN / 'session.py'} next {session}")


def cmd_next(session: str) -> None:
    st = load(session)
    if st["current"]:
        raise Stop(f"sample {st['current']['label']} has no final.md yet; run `round` after its hand-back")
    log = sdir(session) / "state.md"
    if not log.is_file() or "hookcheck ok" not in log.read_text():
        raise Stop("the hook check has not passed in this session")
    s = stop_file()
    if s:
        print(f"STOPPED by the driver: {s}\nStart no author. Tell the driver the session is idle.")
        return
    extra = (shared() / "extra-blocks.txt").read_text() if (shared() / "extra-blocks.txt").is_file() else ""
    todo = [(k, a, n) for k, a, n in queue(session, extra) if not (sample_dir(a, n) / "final.md").is_file()]
    if not todo:
        print(f"DONE: session {session} has no sample left. Tell the driver.")
        return
    k, arm, n = todo[0]
    require_hook("next", session)
    preflight()
    d = sample_dir(arm, n)
    if d.exists() and any(d.iterdir()):
        raise Stop(f"{d} already has files but no final.md")
    d.mkdir(parents=True, exist_ok=True)
    write_state(RUN / ARMS[arm] / "prompt-firth.md", d, S7 / "harness.py" if arm == "B" else None)
    lab = label(session, arm, n)
    st["current"] = {"label": lab, "arm": arm, "n": n, "block": k, "agent": None}
    save(session, st, f"PREFLIGHT ok; next {lab} (block {k})")
    print(f"START AUTHOR {lab} with the Agent tool: subagent_type \"s7-author\", model \"haiku\", "
          f"description \"Run 14 author {lab}\", run_in_background true, and this prompt, exactly the "
          f"text between the lines:\n-----\n{instruction(arm, n, 0)}\n-----\n"
          f"Then at once run: python3 {RUN / 'session.py'} started {session} <the agent id the Agent "
          "tool returned>\nThen wait for its hand-back, doing nothing else.")


def cmd_started(session: str, agent: str) -> None:
    st = load(session)
    if not st["current"] or st["current"]["agent"]:
        raise Stop("no sample is waiting for its author's id")
    if not re.fullmatch(r"[0-9a-f]{8,}", agent):
        raise Stop(f"{agent!r} does not look like an agent id")
    st["current"]["agent"] = agent
    save(session, st, f"started {st['current']['label']} as author {agent}")
    print(f"RECORDED. Wait for author {agent} to hand back, doing nothing else. Then run: "
          f"python3 {RUN / 'session.py'} round {session}")


def next_round(d: Path) -> int:
    for r in (1, 2, 3):
        if not (d / f"results-{r}.json").is_file():
            return r
    raise Stop(f"{d} is already scored in all three rounds")


def score(arm: str, n: int, r: int) -> str:
    d = sample_dir(arm, n)
    x = sh("python3", S7 / "harness.py", "extract", d / f"answer-{r}.md", cwd=W)
    if x.returncode:
        raise Stop(f"harness.py extract failed on answer-{r}.md of {d.name}: {x.stderr[-300:]}")
    new = json.loads(x.stdout)
    prev = json.loads((d / f"solutions-{r - 1}.json").read_text()) if r > 1 else {}
    (d / f"solutions-{r}.json").write_text(json.dumps({**prev, **new}, indent=2))
    pin = sh("git", "-C", W, "rev-parse", "--short", "HEAD").stdout.strip()
    p = sh("python3", S7 / "harness.py", "score", "--lang", "firth", "--tier", "mvp", d / f"solutions-{r}.json",
           "--label", f"run 14 {ARMS[arm]} firth {n} round {r}",
           "--prompt-docs", f"prompt --tier mvp --rounds 2 at {pin}, {ARMS[arm]}", "--jobs", "4", cwd=W)
    (d / f"results-{r}.json").write_text(p.stdout)
    if p.returncode or TOOLCHAIN_TEXT.search(p.stdout + p.stderr):
        raise Toolchain(f"toolchain or scoring failure in round {r} of {d.name}: {(p.stderr or p.stdout)[-400:]}")
    total = sh("python3", S7 / "harness.py", "report", d / f"results-{r}.json", cwd=W).stdout.strip().splitlines()
    if r < 3:
        rep = sh("python3", S7 / "harness.py", "repair", d / f"solutions-{r}.json", d / f"results-{r}.json",
                 "--lang", "firth", "--tier", "mvp", cwd=W)
        (d / f"repair-{r}.md").write_text(rep.stdout)
    return total[-1] if total else ""


def scans(arm: str, n: int, log: Path, lab: str) -> dict:
    d = sample_dir(arm, n)
    extra = ["--check-cmd", S7 / "harness.py", "--run14-forms"] if arm == "B" else []
    a = sh("python3", S7 / "audit_subagent.py", log, "--prompt", RUN / ARMS[arm] / "prompt-firth.md", "--dir", d,
           "--rounds", "2", "--lang", "firth", "--hook-log", HOOK / "hook-log.jsonl", *extra, cwd=S7)
    (d / "transcript.json").write_text(a.stdout)
    blobs = [sh("git", "-C", W, "rev-parse", f"HEAD:{f}").stdout.strip() for f in ("AGENTS.md", "CLAUDE.md")]
    g = sh("python3", RUN.parent / "2026-09-29-control" / "seen_agents.py", log, W, *blobs, cwd=S7)
    (d / "agents-seen.json").write_text(g.stdout)
    c = sh("python3", S7 / "context_seen.py", log, "--arm-set", "run14", "--arm", ARMS[arm],
           "--sample", d.name, "--label", lab, cwd=S7)
    (d / "context-seen.json").write_text(c.stdout)
    try:
        cross = json.loads(c.stdout).get("cross_sample", [])
    except ValueError:
        cross = ["context_seen.py printed no JSON"]
    toolchain = toolchain_in_checks(log)
    return {"at": now(), "audit_exit": a.returncode, "audit_flagged": a.stderr.strip().splitlines(),
            "agents_exit": g.returncode, "context_exit": c.returncode,
            "cross_sample": len(cross) if isinstance(cross, list) else cross, "toolchain_text_in_log": toolchain}


def cmd_round(session: str) -> None:
    st = load(session)
    cur = st["current"]
    if not cur or not cur["agent"]:
        raise Stop("no author is running in this session")
    arm, n, lab, agent = cur["arm"], cur["n"], cur["label"], cur["agent"]
    d = sample_dir(arm, n)
    r = next_round(d)
    if not (d / f"answer-{r}.md").is_file():
        raise Stop(f"author {lab} handed back without writing answer-{r}.md")
    try:
        total = score(arm, n, r)
    except Toolchain as e:
        stamp = write_toolchain(d, str(e), now())
        st["done"].append(cur)
        st["current"] = None
        save(session, st, f"{lab} r{r} {stamp}")
        publish(session)
        raise
    log = find_log(agent)
    res = scans(arm, n, log, lab)  # the label in its description, e.g. s2-B7
    res["round"] = r
    checks = json.loads((d / "checks.json").read_text()) if (d / "checks.json").is_file() else []
    (d / "checks.json").write_text(json.dumps(checks + [res], indent=1) + "\n")
    note = f"{lab} r{r} {total}; audit exit {res['audit_exit']}, agents exit {res['agents_exit']}, " \
           f"context exit {res['context_exit']}, cross_sample {res['cross_sample']}"
    causes = void_causes(res)
    if causes:
        write_void(d, causes, r, now(), res["audit_flagged"])
        note += f"; VOID rule: {', '.join(causes)} (the sample keeps its slot and gets all its rounds)"
    hook_errors = [e for e in (json.loads(l) for l in (HOOK / "hook-log.jsonl").read_text().splitlines())
                   if e.get("error") and e.get("sample") == str(d)] if (HOOK / "hook-log.jsonl").is_file() else []
    stopping = ""
    if res["cross_sample"]:
        write_stop(f"{now()} stop and review: {lab} has a cross_sample context item (session {session})")
        stopping = ("\nSTOP AND REVIEW is now in force for every session: finish this sample's rounds, "
                    "then start no other. Tell the driver now.")
    if hook_errors:
        save(session, st, note)
        raise Stop(f"the hook reported {len(hook_errors)} error(s) for {lab}: {hook_errors[-1]['error'][:200]}")
    if res["toolchain_text_in_log"]:
        raise Stop(f"{lab}'s log reports a toolchain failure in a check it ran ({note})")
    if r < 3:
        save(session, st, note)
        print(f"{note}{stopping}\nSEND FEEDBACK with SendMessage to \"{agent}\", message exactly the text "
              f"between the lines:\n-----\n{instruction(arm, n, r)}\n-----\nThen wait for its hand-back, "
              f"doing nothing else. Then run: python3 {RUN / 'session.py'} round {session}")
        return
    if arm == "B":
        (d / "bash-calls.json").write_text(json.dumps(bash_calls(log), indent=1) + "\n")
    write_final(d, now())
    st["done"].append(cur)
    st["current"] = None
    save(session, st, note + "; final.md")
    publish(session)
    print(f"{note}\n{lab} DONE and copied to the shared folder.{stopping}\nNext run: "
          f"python3 {RUN / 'session.py'} next {session}")


def check_results(log: Path) -> list[dict]:
    """The tool results of the author's own Bash calls: where a check it ran
    would report a toolchain failure."""
    ids, out = set(), []
    for raw in log.read_text().splitlines():
        e = json.loads(raw)
        content = (e.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for b in content:
            if not isinstance(b, dict):
                continue
            if e.get("type") == "assistant" and b.get("type") == "tool_use" and b.get("name") == "Bash":
                ids.add(b.get("id"))
            elif e.get("type") == "user" and b.get("type") == "tool_result" and b.get("tool_use_id") in ids:
                out.append(b)
    return out


def toolchain_in_checks(log: Path) -> bool:
    return any(TOOLCHAIN_TEXT.search(json.dumps(b.get("content"))) for b in check_results(log))


def bash_calls(log: Path) -> dict:
    errored, calls = set(), []
    for raw in log.read_text().splitlines():
        e = json.loads(raw)
        content = (e.get("message") or {}).get("content")
        if e.get("type") == "user" and isinstance(content, list):
            errored |= {b["tool_use_id"] for b in content if isinstance(b, dict)
                        and b.get("type") == "tool_result" and b.get("is_error") and b.get("tool_use_id")}
        if e.get("type") == "assistant" and isinstance(content, list):
            calls += [{"at": e.get("timestamp"), "id": b["id"], "command": b["input"].get("command"),
                       "background": bool(b["input"].get("run_in_background"))}
                      for b in content if isinstance(b, dict) and b.get("type") == "tool_use"
                      and b.get("name") == "Bash"]
    for c in calls:
        c["errored"] = c["id"] in errored
    return {"note": "Every Bash call in the author's raw log, command verbatim (session.py).", "calls": calls}


def publish(session: str) -> None:
    """Copy the session's finished samples, state and hook log to the shared folder."""
    out = shared() / session
    (out / "driver").mkdir(parents=True, exist_ok=True)
    for f in sdir(session).iterdir() if sdir(session).is_dir() else []:
        shutil.copy(f, out / "driver" / f.name)
    if (HOOK / "hook-log.jsonl").is_file():
        shutil.copy(HOOK / "hook-log.jsonl", out / "driver" / "hook-log.jsonl")
    for s in load(session)["done"]:
        src = sample_dir(s["arm"], s["n"])
        shutil.copytree(src, out / ARMS[s["arm"]] / src.name, dirs_exist_ok=True)


# Self-test ----------------------------------------------------------------------

def self_test() -> None:
    assert draw_orders() == ORDER, draw_orders()
    for s, o in ORDER.items():
        assert o.split().count("AB") == 4 and o.split().count("BA") == 4, s
    # Numbering: every arm's samples 1 to 40, each once, in block-then-session order.
    for arm in "AB":
        ns = sorted((k, SESSIONS.index(s), n) for s in SESSIONS for k, a, n in queue(s) if a == arm)
        assert [n for *_, n in ns] == list(range(1, 41)), ns
    assert queue("s2")[:4] == [(1, "B", 2), (1, "A", 2), (2, "B", 7), (2, "A", 7)]
    assert queue("s1", "s1 9 BA 41\ns2 9 AB 42\n")[-2:] == [(9, "B", 41), (9, "A", 41)]
    for bad in ("s1 9 XY 41", "s1 3 AB 41", "s1 9 AB 12", "s9 9 AB 41", "s1 9 AB"):
        try:
            extra_blocks("s1", bad)
            raise AssertionError(bad)
        except Stop:
            pass
    # The runner sends run 13's templates with run 14's paths, unwrapped.
    for arm in "AB":
        for r in (0, 1, 2):
            t = instruction(arm, 17, r)
            assert f"{RUN.name}/{ARMS[arm]}/" in t and "check-forms" not in t and "firth-r13" not in t, t
            assert f"haiku-firth-17/{'answer-1.md' if r == 0 else f'repair-{r}.md'}" in t, t
            assert not t.startswith("The coordinator sent") and "Address this" not in t
    assert "/home/user/firth-r14/eval/s7/harness.py check" in instruction("B", 3, 1)
    assert "harness.py" not in instruction("A", 3, 1)
    # Validity from exit codes: 0 clean, 1 a rule void, anything else stops.
    base = {"audit_exit": 0, "agents_exit": 0, "context_exit": 0}
    assert void_causes(base) == []
    assert void_causes({**base, "audit_exit": 1, "context_exit": 1}) == ["audit", "context"]
    for odd in (2, -9, 127):
        try:
            void_causes({**base, "agents_exit": odd})
            raise AssertionError(odd)
        except Stop:
            pass
    import tempfile
    # With R14_SHARED set (the smoke), publish() and the STOP file write
    # there and leave the run's own folder as it was.
    # The run's folder is itself a scratch one here, so even a broken
    # shared() cannot write to the real one during the test.
    global RUN14_SHARED
    real = RUN14_SHARED
    with tempfile.TemporaryDirectory() as tmp:
        old = os.environ.get("R14_SHARED")
        os.environ["R14_SHARED"] = str(Path(tmp) / "run14-smoke")
        RUN14_SHARED = Path(tmp) / "run14"
        try:
            assert shared() == Path(tmp) / "run14-smoke"
            publish("s5")
            write_stop("smoke stop")
            assert (Path(tmp) / "run14-smoke" / "s5" / "driver").is_dir()
            assert stop_file() == "smoke stop"
            assert not RUN14_SHARED.exists(), "the smoke wrote into the run's shared folder"
        finally:
            RUN14_SHARED = real
            if old is None:
                del os.environ["R14_SHARED"]
            else:
                os.environ["R14_SHARED"] = old
    # The pinned toolchain is run 13's, as its pinned.txt recorded it; another fails.
    r13 = (RUN.parent / "2026-09-30-check-forms" / "pinned.txt").read_text()
    line = next(l for l in r13.splitlines() if l.startswith("Toolchain, env -i"))
    assert all(v in line for v in TOOLCHAIN), line
    assert not all(v in line.replace("d024af0", "0000000") for v in TOOLCHAIN)
    # The hook is registered only if it recorded the runner's own call just now.
    with tempfile.TemporaryDirectory() as tmp:
        seen = Path(tmp) / "seen.jsonl"
        assert not hook_registered(seen, "next", "s2"), "no record at all"
        at = datetime.now(timezone.utc)
        rows = [{"at": (at.replace(year=at.year - 1)).isoformat(), "tool_name": "Bash", "agent_type": None,
                 "command": "python3 /x/session.py next s2"},  # stale
                {"at": at.isoformat(), "tool_name": "Bash", "agent_type": None,
                 "command": "python3 /x/session.py next s3"},  # another session
                {"at": at.isoformat(), "tool_name": "Bash", "agent_type": "s7-author",
                 "command": "python3 /x/session.py next s2"},  # an author's call
                {"at": at.isoformat(), "tool_name": "Glob", "agent_type": None, "command": None},
                "not json"]
        seen.write_text("".join((r if isinstance(r, str) else json.dumps(r)) + "\n" for r in rows))
        assert not hook_registered(seen, "next", "s2")
        assert not hook_registered(seen, "hookcheck", "s3")
        assert hook_registered(seen, "next", "s3")
        with open(seen, "a") as f:
            f.write(json.dumps({"at": at.isoformat(), "tool_name": "Bash", "agent_type": None,
                                "command": "R14_SHARED=/y python3 /x/session.py next s2"}) + "\n")
        assert hook_registered(seen, "next", "s2")
        global SEEN
        saved, SEEN = SEEN, Path(tmp) / "none.jsonl"
        try:
            require_hook("next", "s2")
            raise AssertionError("an unregistered hook did not stop `next`")
        except Stop:
            pass
        finally:
            SEEN = saved
    # `next` and `hookcheck` check it before an author can start.
    import inspect
    src = inspect.getsource(cmd_next)
    assert 'require_hook("next", session)' in src and src.index("require_hook") < src.index("preflight()")
    src = inspect.getsource(cmd_hookcheck)
    assert src.index('require_hook("hookcheck", session)') < src.index("START THE HOOK-CHECK AUTHOR")
    # The description names the author as context_seen.py's LABEL reads it.
    sys.path.insert(0, str(S7))
    from context_seen import LABEL
    assert LABEL.findall(f"Run 14 author {label('s2', 'B', 7)}") == ["s2-B7"]
    # The toolchain scan reads only the author's own Bash results.
    import tempfile
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        for e in ({"type": "user", "message": {"content": "the prompt mentions toolchain: lake here"}},
                  {"type": "assistant", "message": {"content": [{"type": "tool_use", "id": "b1", "name": "Bash",
                                                                 "input": {"command": "check"}}]}},
                  {"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": "b1",
                                                            "content": "toolchain: lake exit 1"}]}}):
            f.write(json.dumps(e) + "\n")
    got = check_results(Path(f.name))
    assert [b["tool_use_id"] for b in got] == ["b1"] and toolchain_in_checks(Path(f.name))
    # The same text outside a Bash result (here, only the prompt) is not a failure.
    lines = Path(f.name).read_text().splitlines()
    Path(f.name).write_text(lines[0] + "\n" + lines[1] + "\n")
    assert not toolchain_in_checks(Path(f.name))
    Path(f.name).unlink()
    print("session.py self-test: ok")


def main(argv: list[str]) -> int:
    if argv == ["--self-test"]:
        self_test()
        return 0
    try:
        if len(argv) < 2 or argv[0] not in ("setup", "hookcheck", "next", "started", "round") \
                or argv[1] not in SESSIONS:
            raise Stop(f"usage: see the top of {__file__}")
        cmd, session, rest = argv[0], argv[1], argv[2:]
        if cmd == "setup":
            if rest[:1] != ["--pin"] or len(rest) != 2:
                raise Stop("setup needs --pin SHA")
            cmd_setup(session, rest[1])
        elif cmd == "hookcheck":
            cmd_hookcheck(session, rest[0] if rest else None)
        elif cmd == "next":
            cmd_next(session)
        elif cmd == "started":
            cmd_started(session, rest[0] if rest else "")
        else:
            cmd_round(session)
    except Stop as e:
        print(f"STOP: {e}\nTell the driver exactly this line, then do nothing else until the driver answers.")
        if len(argv) > 1 and argv[1] in SESSIONS and sdir(argv[1]).is_dir():
            save(argv[1], load(argv[1]), f"STOP: {e}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
