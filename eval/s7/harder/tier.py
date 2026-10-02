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
import hashlib
import json
import os
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
    The runner measures them; the checker proves nothing about them."""
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
    return {Path(n).stem: harness.read_regular(path / n, path)
            for n in sorted(os.listdir(path)) if Path(n).suffix == ext}


def score(solutions: dict[str, str], lang: str, tasks: list[Task], jobs: int = 4) -> dict:
    if lang == "python":
        if os.geteuid() != 0:
            raise SystemExit("scoring Python answers needs the sandbox; run as root")
        harness.sandbox_preflight()
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
    example only (`harness.repair`), never a hidden test."""
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
    return "\n".join(parts)


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
        print(repair(json.loads(a.solutions.read_text()), json.loads(a.results.read_text()),
                     a.lang, list(SETS[a.set])).rstrip("\n"))
    elif a.cmd == "report":
        print(report(a.results))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
