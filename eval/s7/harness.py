#!/usr/bin/env python3
"""S7 authoring harness: build prompts, score solutions, compare languages.

The author model sees only the language docs, each task's description, its
input/output shape and one visible example. Hidden tests stay here.

    harness.py prompt  --lang firth --tier today|all|hard [--extra-doc F] > prompt.md
    harness.py extract --lang firth answer.md > solutions.json
    harness.py score   --lang firth solutions.json > results.json
    harness.py repair  --lang firth solutions.json results.json > repair.md
    harness.py report  runs/*/results-*.json

A task passes only when every hidden test returns exactly the expected stack.
Firth runs go through tools/loop/firth_run.py, so a pass also means the VM and
the Lean reference interpreter agreed.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tasks import BY_ID, HARD, TASKS, Task  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / "tools/loop/firth_run.py"
# The docs a newcomer would read. Nothing under src/, tools/ or examples/.
FIRTH_DOCS = ("docs/getting-started.md", "docs/firth-agent-guide.md")
TIMEOUT = 300


def select(tier: str) -> list[Task]:
    if tier == "all":
        return list(TASKS)
    if tier == "hard":
        return list(HARD)
    if tier == "everything":
        return list(TASKS + HARD)
    if tier == "today":
        return [t for t in TASKS if t.needs <= {"add"}]
    if tier == "later":
        return [t for t in TASKS if not t.needs <= {"add"}]
    return [BY_ID[i] for i in tier.split(",")]


def lit(v, lang: str) -> str:
    if isinstance(v, bool):
        return ("true" if v else "false") if lang == "firth" else str(v)
    return str(v)


def shape(task: Task, lang: str) -> str:
    ins = ", ".join(f"{n}: {ty}" for n, ty in task.inputs) or "none"
    outs = ", ".join(f"{n}: {ty}" for n, ty in task.outputs)
    ex_in = ", ".join(lit(v, lang) for v in task.example)
    ex_out = ", ".join(lit(v, lang) for v in task.expected(task.example))
    if lang == "firth":
        return (f"Inputs on the stack, bottom to top: {ins}.\n"
                f"Outputs left on the stack, bottom to top: {outs}.\n"
                f"Example: stack [{ex_in}] becomes [{ex_out}].")
    return (f"Arguments, in order: {ins}.\n"
            f"Return: {outs}" + (" (as a tuple, in this order)" if len(task.outputs) > 1 else "") + ".\n"
            f"Example: main({ex_in}) returns {ex_out if len(task.outputs) == 1 else '(' + ex_out + ')'}.")


def prompt(tasks: list[Task], lang: str, extra_docs: tuple[str, ...] = ()) -> str:
    parts = []
    if lang == "firth":
        parts.append(
            "You are writing programs in Firth, a new stack language. You have never seen "
            "it before; everything you know about it is in the documentation below. Programs "
            "are run with the portable runner described in 'Getting started', so only what "
            "that runner supports will execute.\n\n"
            "For each task, write a complete Firth source file whose entry word is named "
            "`main`. Helper words are allowed. Do not use tools, files or the internet; "
            "answer from the documentation alone.\n")
        for doc in FIRTH_DOCS:
            parts.append(f"<document path=\"{doc}\">\n{(ROOT / doc).read_text()}\n</document>\n")
        for doc in extra_docs:
            parts.append(f"<document path=\"{Path(doc).name}\">\n{Path(doc).read_text()}\n</document>\n")
        fence = "firth"
    else:
        parts.append(
            "For each task, write a Python 3 function named `main`. Use only the standard "
            "library. Do not use tools; answer directly.\n")
        fence = "python"
    parts.append(
        f"Answer every task in this exact format, one block per task, and nothing that "
        f"could be mistaken for one:\n\n### task: <task id>\n```{fence}\n<source>\n```\n\n"
        "If you believe a task cannot be written with what is available, still give "
        "your best attempt, and add one line after the block starting `NOTE:`.\n\n# Tasks\n")
    for t in tasks:
        parts.append(f"## {t.id}\n{t.description}\n{shape(t, lang)}\n")
    return "\n".join(parts)


BLOCK = re.compile(r"^### task:\s*(\S+)\s*\n```[a-zA-Z]*\n(.*?)^```", re.M | re.S)


def extract(text: str) -> dict[str, str]:
    return {m.group(1): m.group(2) for m in BLOCK.finditer(text)}


def run_firth(source: str, args: tuple) -> dict:
    with tempfile.NamedTemporaryFile("w", suffix=".firth", delete=False) as f:
        f.write(source)
        path = f.name
    try:
        p = subprocess.run(
            [sys.executable, str(RUNNER), "run", path, "--entry", "main",
             "--stack", json.dumps(list(args))],
            cwd=ROOT, capture_output=True, text=True, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "timeout"}
    finally:
        Path(path).unlink()
    if p.returncode == 0:
        return {"ok": True, "stack": json.loads(p.stdout)["stack"]}
    return {"ok": False, "error": compact(p.stderr.strip() or p.stdout.strip())}


def compact(text: str) -> str:
    """Keep what a reader needs from a runner failure: the VM trap class, which sits
    deep in a long payload, and the checker's code, message and hint. The raw
    envelope can run to tens of kilobytes."""
    if text.startswith("trap ") or text.startswith("code: "):
        return text  # already compacted
    trap = re.search(r"'trap': '([^']+)'", text)
    head = f"trap {trap.group(1)}\n" if trap else ""
    body = readable(text)
    if body is text:
        code = re.search(r"'code': '([^']+)'", text)
        body = (f"code: {code.group(1)}\n" if code else "") + text[:300]
    return head + body


PY_DRIVER = """
import json, sys
ns = {}
exec(compile(sys.stdin.read(), "solution.py", "exec"), ns)
r = ns["main"](*json.loads(sys.argv[1]))
print(json.dumps(list(r) if isinstance(r, (tuple, list)) else [r]))
"""


def run_python(source: str, args: tuple) -> dict:
    try:
        p = subprocess.run([sys.executable, "-c", PY_DRIVER, json.dumps(list(args))],
                           input=source, capture_output=True, text=True, timeout=30)
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "timeout"}
    if p.returncode == 0:
        return {"ok": True, "stack": json.loads(p.stdout)}
    return {"ok": False, "error": p.stderr.strip()[-2000:]}


def same(got: list, want: list) -> bool:
    # Booleans and integers must not coerce into each other (True == 1 in Python).
    return len(got) == len(want) and all(
        type(g) is type(w) and g == w for g, w in zip(got, want))


def firth_commit() -> str:
    p = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True)
    return p.stdout.strip() or "unknown"


def score(solutions: dict[str, str], lang: str, tasks: list[Task], jobs: int) -> dict:
    runner = run_firth if lang == "firth" else run_python
    work = [(t, args, i == 0) for t in tasks if t.id in solutions
            for i, args in enumerate((t.example, *t.hidden))]
    if lang == "firth" and work:
        runner(solutions[work[0][0].id], work[0][1])  # build the toolchain once, serially
    with ThreadPoolExecutor(jobs) as pool:
        outs = list(pool.map(lambda w: runner(solutions[w[0].id], w[1]), work))
    per: dict[str, dict] = {t.id: {"needs": sorted(t.needs), "submitted": t.id in solutions,
                                    "cases": []} for t in tasks}
    for (t, args, visible), out in zip(work, outs):
        want = t.expected(args)
        case = {"input": list(args), "expected": want, "visible": visible, **out}
        case["pass"] = out["ok"] and same(out["stack"], want)
        per[t.id]["cases"].append(case)
    for r in per.values():
        hidden = [c for c in r["cases"] if not c["visible"]]
        r["pass"] = bool(hidden) and all(c["pass"] for c in hidden)
        r["hidden_passed"] = sum(c["pass"] for c in hidden)
        r["hidden_total"] = len(hidden)
    return {"lang": lang, "tasks": per}


def readable(error: str) -> str:
    """Prefer the checker's plain-language fields over the raw JSON envelope."""
    fields = {k: m.group(1) for k in ("code", "message", "expected", "actual", "hint")
              if (m := re.search(rf"'{k}': '((?:[^'\\]|\\.)*)'", error))}
    if "message" not in fields:
        return error
    return "\n".join(f"{k}: {v}" for k, v in fields.items())


def repair(solutions: dict[str, str], results: dict, lang: str, tasks: list[Task]) -> str:
    """Second attempt: show only the visible example's outcome, never hidden tests."""
    wanted = {t.id for t in tasks}
    parts = [f"Some of your {lang} answers did not work on the visible example. Fix them. "
             "Answer only the tasks listed, in the same format as before.\n"]
    for tid, r in results["tasks"].items():
        if tid not in wanted:
            continue
        vis = next((c for c in r["cases"] if c["visible"]), None)
        if r["submitted"] and vis and vis["pass"]:
            continue
        t = BY_ID[tid]
        what = ("no answer was given" if not vis else
                f"the run failed:\n{readable(vis['error'])}" if not vis["ok"] else
                f"it returned {vis['stack']} instead of {vis['expected']}")
        parts.append(f"## {tid}\n{t.description}\n{shape(t, lang)}\n\nYour answer:\n"
                     f"```\n{solutions.get(tid, '')}\n```\nOn the example, {what}\n")
    return "\n".join(parts)


def report(paths: list[Path]) -> str:
    rows = {}
    for p in paths:
        res = json.loads(p.read_text())
        label = res.get("label") or f"{res['lang']} {p.stem}"
        for tid, r in res["tasks"].items():
            rows.setdefault(tid, {})[label] = r
    labels = sorted({l for r in rows.values() for l in r})
    out = ["| task | needs | " + " | ".join(labels) + " |",
           "|---|---|" + "---|" * len(labels)]
    for t in TASKS + HARD:
        if t.id not in rows:
            continue
        cells = []
        for l in labels:
            r = rows[t.id].get(l)
            cells.append("" if r is None else
                         f"{'PASS' if r['pass'] else 'fail'} {r['hidden_passed']}/{r['hidden_total']}")
        out.append(f"| {t.id} | {','.join(sorted(t.needs))} | " + " | ".join(cells) + " |")
    tot = []
    for l in labels:
        rs = [r[l] for r in rows.values() if l in r]
        tot.append(f"{sum(r['pass'] for r in rs)}/{len(rs)}")
    out.append("| **total** | | " + " | ".join(tot) + " |")
    return "\n".join(out)


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = cli.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("prompt"); p.add_argument("--lang", required=True, choices=["firth", "python"])
    p.add_argument("--tier", default="all")
    p.add_argument("--extra-doc", action="append", default=[],
                   help="extra document appended after the repo docs, e.g. a primitives supplement")
    e = sub.add_parser("extract"); e.add_argument("--lang"); e.add_argument("answer", type=Path)
    s = sub.add_parser("score"); s.add_argument("--lang", required=True, choices=["firth", "python"])
    s.add_argument("solutions", type=Path); s.add_argument("--tier", default="all")
    s.add_argument("--label"); s.add_argument("--jobs", type=int, default=4)
    s.add_argument("--prompt-docs", default="",
                   help="the documents the author's prompt was built from, recorded in the result")
    r = sub.add_parser("repair"); r.add_argument("--lang", required=True)
    r.add_argument("solutions", type=Path); r.add_argument("results", type=Path)
    r.add_argument("--tier", default="all")
    rep = sub.add_parser("report"); rep.add_argument("results", type=Path, nargs="+")
    a = cli.parse_args()
    if a.cmd == "prompt":
        print(prompt(select(a.tier), a.lang, tuple(a.extra_doc)).rstrip("\n"))
    elif a.cmd == "extract":
        print(json.dumps(extract(a.answer.read_text()), indent=2))
    elif a.cmd == "score":
        res = score(json.loads(a.solutions.read_text()), a.lang, select(a.tier), a.jobs)
        res.update(label=a.label, firth_commit=firth_commit(),
                   prompt_docs=[d for d in a.prompt_docs.split(",") if d])
        print(json.dumps(res, indent=2))
    elif a.cmd == "repair":
        print(repair(json.loads(a.solutions.read_text()), json.loads(a.results.read_text()),
                     a.lang, select(a.tier)).rstrip("\n"))
    elif a.cmd == "report":
        print(report(a.results))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
