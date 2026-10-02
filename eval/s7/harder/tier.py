#!/usr/bin/env python3
"""Prompt, score and repair for the harder S7 tier (`todo.s7-harder-task-tier`).

    tier.py prompt --set calibration --lang firth|python [--rounds 1] > prompt.md
    tier.py extract answer.md > solutions.json
    tier.py score  --set calibration --lang firth solutions.json > results.json
    tier.py repair --set calibration --lang firth solutions.json results.json > repair.md
    tier.py report results-*.json

The protocol is the MVP tier's sub-agent protocol (`eval/s7/harness.py`,
`prompt --rounds`): the author answers without tools, then is shown how each
answer did on its task's visible example and may fix it, up to `--rounds`
times. "Correct on the first attempt" is round 1; "correct within two
attempts" is round 2. The Firth author gets the MVP documents and the MVP
step budget. Hidden tests are never shown.

This tier lives apart from `harness.py` and its task sets, so it changes
nothing a pinned S7 run scores with. It reuses the harness's runners,
comparison and diagnostics, and adds its own sets, step budget and hashes.

A task passes only when every hidden test returns exactly the expected stack.
Firth runs go through `tools/loop/firth_run.py`, so a pass also means the VM
and the Lean reference interpreter agreed. Python answers run in the
harness's sandbox, which needs root; scoring Python refuses without it.
"""
from __future__ import annotations

import argparse
import functools
import hashlib
import json
import os
import stat
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
S7 = HERE.parent
sys.path.insert(0, str(S7))
sys.path.insert(0, str(HERE))
# What scoring reads, hashed before any of it is imported, so a result names
# the task definitions and scorer it was produced with.
HASHED = {f"harder/{n}": HERE / n for n in ("calibration.py", "tier.py")} | {
    n: S7 / n for n in ("task.py", "harness.py", "isolate.py")}
IMPORT_HASHES = {n: hashlib.sha256(p.read_bytes()).hexdigest() for n, p in HASHED.items()}
import harness  # noqa: E402
import isolate  # noqa: E402
from calibration import CALIBRATION  # noqa: E402
from task import Task  # noqa: E402

SETS: dict[str, tuple[Task, ...]] = {"calibration": CALIBRATION}
BY_ID = {t.id: t for ts in SETS.values() for t in ts}
assert len(BY_ID) == sum(len(ts) for ts in SETS.values()), "task ids must be unique across sets"
assert not set(BY_ID) & {t.id for t in harness.TASKS + harness.HARD + harness.MVP}, \
    "a harder-tier id must not reuse an earlier tier's"
FUEL = harness.MVP_FUEL


def prompt(tasks: list[Task], lang: str, rounds: int = 1) -> str:
    """The author's prompt: the MVP tier's sub-agent prompt (`harness.prompt`
    with `rounds`), for these tasks."""
    if rounds < 1:
        raise ValueError("this tier is answered with at least one feedback round")
    parts = []
    loop = ("Do not use any tool except reading this prompt file and writing your answer "
            "file, and do not use the internet. After you answer, you will be shown how each "
            "answer did on its task's example: the result, or the diagnostics if it failed. "
            f"You may then fix your answers; there {'is' if rounds == 1 else 'are'} at most "
            f"{rounds} such round{'' if rounds == 1 else 's'}.\n")
    if lang == "firth":
        parts.append(
            "You are writing programs in Firth, a new stack language. You have never seen "
            "it before; everything you know about it is in the documentation below. Programs "
            "are run with the portable runner described in 'Getting started', so only what "
            "that runner supports will execute.\n\n"
            "For each task, write a complete Firth source file whose entry word is named "
            f"`main`. Helper words are allowed. Each run may take up to {FUEL:,} steps.\n\n"
            + loop)
        for doc in harness.MVP_DOCS:
            parts.append(f"<document path=\"{doc}\">\n{(harness.ROOT / doc).read_text()}\n</document>\n")
        fence = "firth"
    else:
        parts.append("For each task, write a Python 3 function named `main`. Use only the "
                     "standard library.\n\n" + loop)
        fence = "python"
    parts.append(
        f"Answer every task in this exact format, one block per task, and nothing that "
        f"could be mistaken for one:\n\n### task: <task id>\n```{fence}\n<source>\n```\n\n"
        "If you believe a task cannot be written with what is available, still give "
        "your best attempt, and add one line after the block starting `NOTE:`.\n\n# Tasks\n")
    for t in tasks:
        parts.append(f"## {t.id}\n{t.description}\n{harness.shape(t, lang)}\n")
    return "\n".join(parts)


def run_firth(source: str, args: tuple) -> dict:
    """`harness.run_firth`, keeping the runner's measured cost of the run: the
    kernel steps the reference interpreter counted and the VM's own count.
    The runner measures them; the checker proves nothing about them.

    A copy, not a call, because changing `harness.py` would change files a
    pinned S7 run scores with; keep it in step with `harness.run_firth`
    (`todo.s7-harder-tier-harness-merge`)."""
    with tempfile.NamedTemporaryFile("w", suffix=".firth", delete=False) as f:
        f.write(source)
        path = f.name
    try:
        p = subprocess.run(
            [sys.executable, str(harness.RUNNER), "run", path, "--entry", "main",
             "--stack", json.dumps(list(args)), "--fuel", str(FUEL)],
            cwd=harness.ROOT, capture_output=True, text=True, timeout=harness.TIMEOUT)
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "timeout"}
    finally:
        Path(path).unlink()
    if p.returncode == 0:
        out = json.loads(p.stdout)
        return {"ok": True, "stack": out["stack"], "kernel_cost": out.get("kernel_cost"),
                "vm_cost": out.get("vm_cost")}
    harness.toolchain_failure(p.stderr)
    return {"ok": False, "error": harness.compact(p.stderr.strip() or p.stdout.strip())}


def run(source: str, lang: str, task: Task, args: tuple) -> dict:
    if lang == "firth":
        return run_firth(source, args)
    return harness.run_python(source, args, FUEL, harness.types(task), sandboxed=True)


def load(path: Path, lang: str) -> dict[str, str]:
    """A solutions JSON file, or a directory of answers in LANG: only its
    `<id>.firth` (or `<id>.py`) files, read as `harness.load_solutions` reads
    them, so an answer in the other language never stands in for one."""
    if not path.is_dir():
        return harness.load_solutions(path, harness.plain_parent(path))
    ext = ".firth" if lang == "firth" else ".py"
    # Opened as harness.load_solutions opens it: no link on the way, so a link
    # named as the answer directory cannot point the scorer at the references.
    dfd = harness.open_under(path, harness.plain_parent(path), directory=True)
    try:
        return {Path(n).stem: harness._read_plain(os.open(n, harness.READ, dir_fd=dfd), path / n)
                for n in sorted(os.listdir(dfd)) if Path(n).suffix == ext}
    finally:
        os.close(dfd)


# This tier's hidden tests and references, as paths in the repository. The
# sandbox's own scan (isolate.hidden_copies) knows only the MVP tier's, and
# isolate.py is pinned by earlier runs, so this tier scans for its own.
HIDDEN_PATHS = tuple(f"eval/s7/harder/{n}" for n in (*(f"{s}.py" for s in SETS), "reference"))


def hidden_files() -> list[Path]:
    root = S7.parent.parent
    out = []
    for rel in HIDDEN_PATHS:
        p = root / rel
        out += sorted(f for f in p.rglob("*") if f.is_file()) if p.is_dir() else [p]
    return out


@functools.lru_cache(maxsize=None)
def hidden_blobs() -> tuple[str, ...]:
    """The git blob id of every version of this tier's hidden files: as they
    are now, and each revision in the repository's history."""
    root = S7.parent.parent
    blobs = set(isolate.git_lines(root, "hash-object", "--", *map(str, hidden_files())))
    for line in isolate.git_lines(root, "log", "--all", "--format=", "--raw", "--no-abbrev",
                                  "--", *HIDDEN_PATHS):
        blobs.update(b for b in line.split()[2:4] if b.strip("0"))
    return tuple(sorted(blobs))


def tier_storage(top: str, bare: bool) -> str | None:
    """Why the git storage at TOP could hand an author this tier's hidden files,
    or None: it has one of their blobs, or any tree, reachable or not, with an
    `eval/s7/harder` directory. Storage git cannot read is refused."""
    git = ["git", "-c", "safe.directory=*", *(["--git-dir", top] if bare else ["-C", top])]
    try:
        have = subprocess.run(git + ["cat-file", "--batch-check"], input="".join(b + "\n" for b in hidden_blobs()),
                              capture_output=True, text=True, timeout=60)
        if have.returncode:
            return f"git cannot read ({have.stderr.strip()[:200]})"
        if any(not line.endswith(" missing") for line in have.stdout.splitlines()):
            return "holds a hidden file's content"
        listed = subprocess.run(git + ["cat-file", "--batch-all-objects", "--unordered",
                                       "--batch-check=%(objecttype) %(objectname)"],
                                capture_output=True, text=True, timeout=300)
        if listed.returncode:
            return f"git cannot read ({listed.stderr.strip()[:200]})"
        trees = [line.split()[1] for line in listed.stdout.splitlines() if line.startswith("tree ")]
        read = subprocess.run(git + ["cat-file", "--batch"], input="".join(t + "\n" for t in trees).encode(),
                              capture_output=True, timeout=300)
        if read.returncode:
            return f"git cannot read ({read.stderr.decode(errors='replace').strip()[:200]})"
        entries = isolate.tree_entries(read.stdout)
    except (OSError, subprocess.SubprocessError, ValueError) as e:
        return f"git cannot read ({e})"
    child = {(tree, name): oid for tree, items in entries.items() for name, oid, is_tree in items if is_tree}
    for (tree, name), oid in child.items():
        if name == b"eval" and (oid, b"s7") in child and (child[oid, b"s7"], b"harder") in child:
            return "has a revision of this tier"
    return None


@functools.lru_cache(maxsize=None)
def tier_copies(sources: tuple[str, ...]) -> list[str]:
    """What under SOURCES could hand an author this tier's hidden tests or
    references, as `isolate.hidden_copies` finds the MVP tier's: a file with a
    hidden file's content, a directory named like this tier's
    (`eval/s7/harder`, catching older revisions), and git storage that holds
    any revision of them. The directories the sandbox never shows are skipped.
    A renamed and edited copy is not caught, as there."""
    hidden: dict[int, set[str]] = {}
    for f in hidden_files():
        hidden.setdefault(f.stat().st_size, set()).add(hashlib.sha256(f.read_bytes()).hexdigest())
    found = []

    def check_file(path: str) -> None:
        try:
            st = os.lstat(path)
            if (stat.S_ISREG(st.st_mode) and st.st_size in hidden and
                    hashlib.sha256(Path(path).read_bytes()).hexdigest() in hidden[st.st_size]):
                found.append(f"{path} (the content of a hidden file)")
        except OSError:
            pass
    for src in sources:
        if not os.path.isdir(src):
            check_file(src)
            continue
        for top, dirs, files in os.walk(src, followlinks=False):
            dirs[:] = [d for d in dirs if os.path.join(top, d) not in isolate.UNSHOWN]
            if ".git" in dirs + files or {"objects", "refs"} <= set(dirs) and "HEAD" in files:
                why = tier_storage(top, bare=".git" not in dirs + files)
                if why:
                    found.append(f"{top} (git storage that {why})")
            if top.endswith("/eval/s7/harder"):
                found.append(f"{top} (named like this tier)")
            for n in files:
                check_file(os.path.join(top, n))
    return found


def check_sandbox_sources() -> None:
    """Refuse to score Python when what the sandbox shows (its system
    directories and the interpreter's install) holds a copy of this tier's
    hidden files. The repository itself is kept out by the sandbox."""
    exe = harness.sandbox_python()
    sources = tuple(s for s, _ in isolate.allowed_sources(harness.python_install(exe)))
    found = tier_copies(sources)
    if found:
        raise SystemExit(f"the sandbox would show {found[0]}; move it or leave it out")


def score(solutions: dict[str, str], lang: str, tasks: list[Task], jobs: int = 4) -> dict:
    if lang == "python":
        if os.geteuid() != 0:
            raise SystemExit("scoring Python answers needs the sandbox; run as root")
        harness.sandbox_preflight()
        check_sandbox_sources()
    work = [(t, args, i == 0) for t in tasks if t.id in solutions
            for i, args in enumerate((t.example, *t.hidden))]
    if lang == "firth" and work:
        harness.warm_toolchain(solutions[work[0][0].id])
    with ThreadPoolExecutor(jobs) as pool:
        outs = list(pool.map(lambda w: run(solutions[w[0].id], lang, w[0], w[1]), work))
    per = {t.id: {"needs": sorted(t.needs), "submitted": t.id in solutions, "cases": []} for t in tasks}
    for (t, args, visible), out in zip(work, outs):
        want = t.expected(args)
        case = {"input": list(args), "expected": want, "visible": visible, **out}
        case["pass"] = out["ok"] and harness.same(out["stack"], want)
        per[t.id]["cases"].append(case)
    for r in per.values():
        hidden = [c for c in r["cases"] if not c["visible"]]
        r["pass"] = bool(hidden) and all(c["pass"] for c in hidden)
        r["hidden_passed"] = sum(c["pass"] for c in hidden)
        r["hidden_total"] = len(hidden)
    return {"lang": lang, "tasks": per}


def hashes() -> dict[str, str]:
    return {n: hashlib.sha256(p.read_bytes()).hexdigest() for n, p in HASHED.items()}


def scored(solutions: dict[str, str], lang: str, tasks: list[Task], jobs: int) -> dict:
    """`score`, refused when the task sets or the scorer changed since they were
    imported, or while scoring; the result records those hashes and the commit."""
    if hashes() != IMPORT_HASHES:
        raise SystemExit("the task sets or the scorer changed since they were loaded; nothing is scored")
    tree = harness.tree_state()
    res = score(solutions, lang, tasks, jobs)
    if hashes() != IMPORT_HASHES:
        raise SystemExit("the task sets or the scorer changed while scoring; nothing is recorded")
    if harness.tree_state() != tree:
        raise SystemExit("the Firth tree changed while scoring; nothing is recorded")
    res.update(firth_commit=tree[0] + (f"+{tree[1]}" if tree[0].endswith("-dirty") else ""),
               eval_sha256=dict(IMPORT_HASHES), fuel=FUEL)
    return res


def repair(solutions: dict[str, str], results: dict, lang: str, tasks: list[Task]) -> str:
    """The next round's prompt: each failed answer's outcome on its visible
    example only (`harness.repair`), never a hidden test. Empty when every
    answer passed its example: there is then nothing the author could be
    shown, and no round is run."""
    parts = [f"Some of your {lang} answers did not work on the visible example. Fix them. "
             "Answer only the tasks listed, in the same format as before.\n"]
    for t in tasks:
        r = results["tasks"].get(t.id)
        if r is None:
            continue
        vis = next((c for c in r["cases"] if c["visible"]), None)
        if r["submitted"] and vis and vis["pass"]:
            continue
        what = ("no answer was given" if not vis else
                f"the run failed:\n{harness.readable(vis['error'])}" if not vis["ok"] else
                f"it returned {vis['stack']} instead of {vis['expected']}")
        parts.append(f"## {t.id}\n{t.description}\n{harness.shape(t, lang)}\n\nYour answer:\n"
                     f"```\n{solutions.get(t.id, '')}\n```\nOn the example, {what}\n")
    return "\n".join(parts) if len(parts) > 1 else ""


def report(paths: list[Path]) -> str:
    rows: dict[str, dict] = {}
    for p in paths:
        res = json.loads(p.read_text())
        label = res.get("label") or f"{res['lang']} {p.stem}"
        for tid, r in res["tasks"].items():
            rows.setdefault(tid, {})[label] = r
    labels = sorted({l for r in rows.values() for l in r})
    out = ["| task | " + " | ".join(labels) + " |", "|---|" + "---|" * len(labels)]
    for tid in BY_ID:
        if tid not in rows:
            continue
        cells = ["" if (r := rows[tid].get(l)) is None else
                 f"{'PASS' if r['pass'] else 'fail'} {r['hidden_passed']}/{r['hidden_total']}"
                 for l in labels]
        out.append(f"| {tid} | " + " | ".join(cells) + " |")
    tot = []
    for l in labels:
        rs = [r[l] for r in rows.values() if l in r]
        tot.append(f"{sum(r['pass'] for r in rs)}/{len(rs)}")
    out.append("| **total** | " + " | ".join(tot) + " |")
    return "\n".join(out)


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = cli.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("prompt")
    p.add_argument("--set", required=True, choices=sorted(SETS))
    p.add_argument("--lang", required=True, choices=["firth", "python"])
    p.add_argument("--rounds", type=int, default=1)
    e = sub.add_parser("extract"); e.add_argument("answer", type=Path)
    s = sub.add_parser("score")
    s.add_argument("--set", required=True, choices=sorted(SETS))
    s.add_argument("--lang", required=True, choices=["firth", "python"])
    s.add_argument("solutions", type=Path); s.add_argument("--label"); s.add_argument("--jobs", type=int, default=4)
    r = sub.add_parser("repair")
    r.add_argument("--set", required=True, choices=sorted(SETS))
    r.add_argument("--lang", required=True, choices=["firth", "python"])
    r.add_argument("solutions", type=Path); r.add_argument("results", type=Path)
    rep = sub.add_parser("report"); rep.add_argument("results", type=Path, nargs="+")
    a = cli.parse_args()
    if a.cmd == "prompt":
        print(prompt(list(SETS[a.set]), a.lang, a.rounds).rstrip("\n"))
    elif a.cmd == "extract":
        print(json.dumps(harness.extract(harness.read_regular(a.answer, harness.plain_parent(a.answer))), indent=2))
    elif a.cmd == "score":
        sols = load(a.solutions, a.lang)
        res = scored(sols, a.lang, list(SETS[a.set]), a.jobs)
        res["label"] = a.label
        print(json.dumps(res, indent=2))
    elif a.cmd == "repair":
        # Prints nothing when every answer passed its example (no round).
        print(repair(json.loads(a.solutions.read_text()), json.loads(a.results.read_text()),
                     a.lang, list(SETS[a.set])).rstrip("\n"))
    elif a.cmd == "report":
        print(report(a.results))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
