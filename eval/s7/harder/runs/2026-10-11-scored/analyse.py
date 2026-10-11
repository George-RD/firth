#!/usr/bin/env python3
"""The scored run's analysis, as `preregistration.md` "Analysis (fixed now)"
defines it. It reads only this run directory's kept files:

- `<results>/NAME/results-N.json`: tasks passed per round, each failure's
  cause, the per-author means, the S7 difference and its tests, the ceiling
  and floor rules, and the guarantees. `<results>` is `rescore-pin`, the
  answers scored again from a checkout of the pin (coordinator's
  instruction), or `.` for the live scores;
- `NAME/answer-N.md`: answer lengths;
- `NAME/outcome.json`, `response-N.json`, `request-N.json` (DeepSeek):
  verdicts, void status, `prompt_eval_count`, `done_reason`, characters
  sent;
- `NAME/transcript.json` (sub-agents): audit flags; a sub-agent with no
  transcript ended without handing back, a crash;
- `NAME/context-seen.json` and `scan-output.txt`: context voids.

Voids are derived from those files, then checked against `voids.txt`, the
list kept by hand during the run; the analysis stops if they differ.

    python3 analyse.py [--results rescore-pin] > analysis-output.md
    python3 analyse.py --self-test

Standard library only. The self-test checks the permutation test and the
bootstrap against hand-worked examples, the permutation test against
enumeration, and rejects planted bugs in each, in the void rules and in the
error sorting.
"""

from __future__ import annotations

import itertools
import json
import random
import re
import sys
import tempfile
from math import comb
from pathlib import Path

HERE = Path(__file__).resolve().parent
TASKS = ["sokoban", "checkers", "regex", "swiss", "warehouse", "cache-sim"]
SUBJECTS = {"sonnet": 8, "deepseek": 8, "haiku": 5}  # planned kept samples per arm
CAP = 3  # voids and crashes per cell that stop replacement
BOOT, SEED = 10_000, 0

# Context items every sub-agent author is shown (preregistration.md "Known
# injected items"; run-notes.md "Context"). `other` of 183 characters is the
# harness's "Output token limit hit. Resume directly ..." continuation.
KNOWN_KINDS = {
    "attachment:auto_mode", "attachment:credential_org", "attachment:date",
    "attachment:deferred_tools_delta", "attachment:environment",
    "attachment:hook_non_blocking_error", "attachment:instructions",
    "attachment:mcp_instructions_delta", "attachment:model", "attachment:nested_memory",
    "attachment:prompt_snapshot", "attachment:remote_session_change",
    "attachment:session_context", "attachment:skill_listing",
    "attachment:total_tokens_reminder", "system-reminder"}
KNOWN_OTHER_CHARS = {183}
SCAN_COUNTS = ("others", "task_status", "notification", "compact", "queued_command",
               "project message")

STACK = {"firth.type.stack-underflow", "firth.type.stack-mismatch",
         "firth.type.branch-mismatch", "firth.type.declared-effect-mismatch"}
ROWS = ["stack effects", "checked types", "linear ownership", "other refusal"]


# ---------------------------------------------------------------- statistics

def perm_p(a: list[int], b: list[int]) -> float:
    """Exact two-sided permutation p for the difference in means, over every
    split of the pooled scores into groups of len(a) and len(b). Counts the
    splits by the first group's sum (scores are small integers)."""
    pooled, n, m = a + b, len(a), len(b)
    total = sum(pooled)
    ways = [[0] * (total + 1) for _ in range(n + 1)]
    ways[0][0] = 1
    for x in pooled:
        for k in range(n, 0, -1):
            for s in range(total, x - 1, -1):
                ways[k][s] += ways[k - 1][s - x]
    obs = abs(sum(a) / n - sum(b) / m)
    hits = sum(ways[n][s] for s in range(total + 1)
               if abs(s / n - (total - s) / m) >= obs - 1e-12)
    return hits / comb(n + m, n)


def perm_p_brute(a: list[int], b: list[int]) -> float:
    pooled, n, m = a + b, len(a), len(b)
    total = sum(pooled)
    obs = abs(sum(a) / n - sum(b) / m)
    splits = list(itertools.combinations(range(n + m), n))
    hits = sum(1 for c in splits
               if abs((s := sum(pooled[i] for i in c)) / n - (total - s) / m) >= obs - 1e-12)
    return hits / len(splits)


def boot_interval(a: list[int], b: list[int], boot: int = BOOT, seed: int = SEED) -> tuple[float, float]:
    """95% percentile bootstrap interval for mean(a) - mean(b), resampling
    within each arm."""
    rng = random.Random(seed)
    diffs = sorted(sum(rng.choices(a, k=len(a))) / len(a) - sum(rng.choices(b, k=len(b))) / len(b)
                   for _ in range(boot))
    return diffs[int(0.025 * boot)], diffs[int(0.975 * boot) - 1]


def verdict(firth: list[int], python: list[int], incomplete: bool, perm=perm_p, boot=boot_interval) -> dict:
    mf, mp = sum(firth) / len(firth), sum(python) / len(python)
    diff, p, (lo, hi) = mf - mp, perm(firth, python), boot(firth, python)
    if incomplete:
        rule = "incomplete: reported, not a result"
    elif mf >= 5.5 and mp >= 5.5:
        rule = "parity at the ceiling"
    elif mf <= 0.5 and mp <= 0.5:
        rule = "parity at the floor"
    elif diff >= 1 and lo > 0 and p < 0.05:
        rule = "materially higher in Firth"
    elif diff <= -1 and hi < 0 and p < 0.05:
        rule = "materially higher in Python"
    else:
        rule = "not material"
    return {"firth_mean": mf, "python_mean": mp, "difference": diff, "p": p,
            "interval": [lo, hi], "rule": rule}


# ---------------------------------------------------------------- errors

def codes(error: str) -> list[str]:
    return re.findall(r"^code: (\S+)", error or "", re.M)


def row(code: str) -> str:
    if code in STACK:
        return "stack effects"
    if code.startswith("firth.type."):
        return "checked types"
    if code.startswith("firth.linearity."):
        return "linear ownership"
    return "other refusal"


def case_cause(lang: str, case: dict) -> str:
    """One case's outcome: passed, refusal, out of steps, runtime error,
    timeout or wrong result (preregistration.md "Outcomes")."""
    if case.get("pass"):
        return "passed"
    e = case.get("error")
    if case.get("ok") and not e:
        return "wrong result"
    e = e or ""
    if e == "timeout":
        return "timeout"
    if e.startswith("trap fuel-exhausted"):
        return "out of steps"
    if e.startswith("trap ") or e.startswith("Traceback"):
        return "runtime error"
    if lang == "firth":  # a checker diagnostic, or the runner refusing the entry
        return "refusal"
    return "runtime error"


CAUSE_ORDER = ["refusal", "out of steps", "runtime error", "timeout", "wrong result"]


def task_cause(lang: str, task: dict) -> tuple[str, dict]:
    """A task's cause and the count of each case cause. A failed task with
    cases of several causes is listed under the first of CAUSE_ORDER that
    any case has (the pre-reg gives no order; every case's cause is kept)."""
    if not task.get("submitted"):
        return "no answer", {}
    counts: dict[str, int] = {}
    for c in task.get("cases", []):
        k = case_cause(lang, c)
        counts[k] = counts.get(k, 0) + 1
    if task.get("pass"):
        return "passed", counts
    for k in CAUSE_ORDER:
        if counts.get(k):
            return k, counts
    return "wrong result", counts  # failed with no failing case recorded


# ---------------------------------------------------------------- samples

def scan_counts(scan_text: str) -> dict[str, dict[str, int]]:
    out, name = {}, None
    for line in scan_text.splitlines():
        m = re.match(r"^(\S+-\d+) \(", line)
        if m:
            name = m.group(1)
        elif name and line.strip().startswith("others:"):
            vals = dict((k, int(v)) for k, v in re.findall(r"([a-z_ ]+?): (\d+)", line.strip()))
            out[name] = {k.strip(): v for k, v in vals.items()}
    return out


def void_cause(d: Path, scans: dict) -> str | None:
    """Why sample directory D is void or crashed, from its files; None when kept."""
    name = d.name
    if name.startswith("deepseek-"):
        o = json.loads((d / "outcome.json").read_text())
        if o.get("status") == "crashed":
            return "crash"
        if o.get("status") == "void" or any(r.get("result") == "void" for r in o.get("rounds", [])):
            return "transport"
        resp = json.loads((d / "response-1.json").read_text())
        n = resp.get("prompt_eval_count")
        if not isinstance(n, (int, float)) or isinstance(n, bool):
            return "missing prompt count"
        req = json.loads((d / "request-1.json").read_text())
        sent = sum(len(m.get("content", "")) for m in req["body"]["messages"])
        if n < sent / 8:
            return "transport"
        return None
    t = d / "transcript.json"
    if not t.exists():
        return "crash"
    tr = json.loads(t.read_text())
    if tr.get("flagged"):
        return "audit flag"
    # Ended without handing back: some round's answer has no hand-back after it.
    tools = [c.get("tool") for c in tr.get("tool_calls", [])]
    rounds = sum(1 for n in (1, 2) if (d / f"answer-{n}.md").exists())
    if not tools or tools[-1] != "SubagentHandback" or tools.count("SubagentHandback") < rounds:
        return "crash"
    c = json.loads((d / "context-seen.json").read_text())
    for item in c.get("injected", []):
        k = item.get("kind")
        if k in KNOWN_KINDS or (k == "other" and item.get("chars") in KNOWN_OTHER_CHARS):
            continue
        return "context"
    if c.get("cross_sample") or c.get("compactions") or c.get("other_arm_worktree_named"):
        return "context"
    s = scans.get(name)
    if s is None or any(s.get(k, 1) for k in SCAN_COUNTS):
        return "context"
    return None


def models(d: Path) -> list[str]:
    """The model id each author's record names: `transcript.json`'s `models`
    for a sub-agent, each response's `model` for DeepSeek."""
    if d.name.startswith("deepseek-"):
        out = []
        for f in sorted(d.glob("response-[12].json")):
            try:
                m = json.loads(f.read_text()).get("model")
            except ValueError:  # a void round's raw reply
                continue
            if m and m not in out:
                out.append(m)
        return out
    t = d / "transcript.json"
    return json.loads(t.read_text()).get("models", []) if t.exists() else []


def started(d: Path) -> str:
    if d.name.startswith("deepseek-"):
        try:  # a void round's response is the raw reply, not JSON
            return json.loads((d / "response-1.json").read_text()).get("created_at", "")
        except ValueError:
            return ""
    t = d / "transcript.json"
    return json.loads(t.read_text()).get("started", "") if t.exists() else ""


def load(run: Path, results: Path) -> dict:
    scans = scan_counts((run / "scan-output.txt").read_text()) if (run / "scan-output.txt").exists() else {}
    samples = {}
    for d in sorted(p for p in run.iterdir() if p.is_dir() and re.match(r"^[a-z]+-(python|firth)-\d+$", p.name)):
        subj, lang, num = d.name.split("-")
        s = {"name": d.name, "subject": subj, "lang": lang, "number": int(num),
             "void": void_cause(d, scans), "started": started(d), "models": models(d)}
        if s["void"] is None:
            r = [json.loads(f.read_text()) for f in sorted((results / d.name).glob("results-[12].json"))]
            if not r:
                raise SystemExit(f"{d.name}: kept, but no results in {results / d.name}")
            s["results"] = r
            s["round1"] = sum(r[0]["tasks"][t]["pass"] for t in TASKS)
            s["within_two"] = sum(r[-1]["tasks"][t]["pass"] for t in TASKS)
            s["lengths"] = [len((d / f"answer-{n}.md").read_text()) for n in (1, 2)
                            if (d / f"answer-{n}.md").exists()]
        if subj == "deepseek":
            s["rounds"] = []
            for n in (1, 2):
                f = d / f"response-{n}.json"
                if f.exists():
                    try:
                        resp = json.loads(f.read_text())
                    except ValueError:  # a void round's raw reply
                        resp = {"prompt_eval_count": None, "done_reason": "not a chat reply"}
                    s["rounds"].append({"round": n, "prompt_eval_count": resp.get("prompt_eval_count"),
                                        "done_reason": resp.get("done_reason")})
        samples[d.name] = s
    return samples


def check_voids(samples: dict, listed: str) -> list[str]:
    """Differences between the derived voids and voids.txt."""
    want = {l.split()[0] for l in listed.splitlines() if l.strip() and not l.startswith("#")}
    got = {n for n, s in samples.items() if s["void"]}
    return [f"void in the files, not in voids.txt: {n}" for n in sorted(got - want)] + \
           [f"in voids.txt, not void in the files: {n}" for n in sorted(want - got)]


# ---------------------------------------------------------------- report

def listed(r1: dict, task: str) -> bool:
    """Whether round 1's feedback listed TASK: no answer, or its visible
    example failed. Only listed tasks are taken in round 2; the rest are
    scored again from the same round-1 code, so round 2 adds no new run."""
    t = r1["tasks"][task]
    vis = [c for c in t.get("cases", []) if c.get("visible")]
    return not t.get("submitted") or not vis or not all(c.get("pass") for c in vis)


def runs(s: dict):
    """(round, task, task record) for every run of an author's answer: every
    task in round 1, and in round 2 only the tasks round 1's feedback listed."""
    for n, r in enumerate(s["results"], 1):
        for t in TASKS:
            if n == 1 or listed(s["results"][0], t):
                yield n, t, r["tasks"][t]


def guarantees(kept: list[dict]) -> dict:
    """Firth guarantees: round-1 visible refusals sorted by row, out of steps,
    runtime refusals on hidden inputs, and measured kernel cost."""
    g = {"diagnostics": {r: 0 for r in ROWS}, "refusals": {r: 0 for r in ROWS},
         "catches": {r: 0 for r in ROWS}, "catches_run": {r: 0 for r in ROWS},
         "no_code": [], "refusal_list": [], "out_of_steps": [], "hidden_runtime": [],
         "cost": {n: {t: {"passed": [], "wrong": []} for t in TASKS} for n in (1, 2)}, "no_cost": {}}
    for s in kept:
        r1 = s["results"][0]
        for t in TASKS:
            task = r1["tasks"][t]
            vis = next((c for c in task.get("cases", []) if c.get("visible")), None)
            if vis and case_cause("firth", vis) == "refusal":
                cs = codes(vis["error"])
                rows = sorted({row(c) for c in cs}) or ["other refusal"]
                if not cs:
                    g["no_code"].append(f"{s['name']} {t}: {vis['error'][:120]}")
                for c in cs:
                    g["diagnostics"][row(c)] += 1
                # Behaves differently on some hidden test: a hidden case's outcome
                # in round 2 differs from round 1's (round 1's were all refused).
                differs = ran = False
                if len(s["results"]) == 2:
                    h1 = [c for c in task["cases"] if not c.get("visible")]
                    h2 = [c for c in s["results"][1]["tasks"][t]["cases"] if not c.get("visible")]
                    key = lambda c: (c.get("pass"), c.get("stack"), c.get("error"))
                    differs = [key(c) for c in h1] != [key(c) for c in h2]
                    ran = any(case_cause("firth", c) != "refusal" for c in h2)
                for rw in rows:
                    g["refusals"][rw] += 1
                    if rw != "other refusal":  # never counted as a guarantee catch
                        g["catches"][rw] += bool(differs)
                        g["catches_run"][rw] += bool(differs and ran)
                g["refusal_list"].append({"sample": s["name"], "task": t, "codes": cs, "rows": rows,
                                          "round2_differs": differs, "round2_runs": ran})
        for n, t, task in runs(s):
            for c in task.get("cases", []):
                k = case_cause("firth", c)
                if k == "out of steps":
                    g["out_of_steps"].append(f"{s['name']} r{n} {t} {'visible' if c.get('visible') else 'hidden'}")
                if k == "runtime error" and not c.get("visible"):
                    g["hidden_runtime"].append(f"{s['name']} r{n} {t} {c['error'].splitlines()[0]}")
                if k in ("passed", "wrong result") and c.get("kernel_cost") is not None:
                    g["cost"][n][t]["passed" if k == "passed" else "wrong"].append(c["kernel_cost"])
                elif k not in ("passed", "wrong result"):
                    g["no_cost"][k] = g["no_cost"].get(k, 0) + 1
    return g


def hidden_failures(kept: list[dict]) -> set[tuple[str, int, str, int]]:
    """(sample, round, task, case index) of every hidden test an answer ran
    and failed, in each round (round 2: the tasks it took): a wrong result,
    runtime error, out of steps or timeout. These are what "A reading nobody
    listed" traces; a refusal or no answer turns on no sentence of the task."""
    out = set()
    for s in kept:
        for n, t, task in runs(s):
            for i, c in enumerate(task.get("cases", [])):
                if not c.get("visible") and case_cause(s["lang"], c) in (
                        "wrong result", "runtime error", "out of steps", "timeout"):
                    out.add((s["name"], n, t, i))
    return out


def readings_check(kept: list[dict], readings: dict | None) -> tuple[list[str], dict[str, set[str]], list[dict]]:
    """Problems with the traces in `readings.json`, per subject the tasks the
    reviewer ruled admit another reading, and the traces that follow another
    reading (the report lists each).

    readings.json: {"traces": [{"sample", "round", "task", "cases": [i, ...],
    "rule", "other_reading": bool, "note"}], "rulings": [{"subject", "task",
    "rule", "sentence", "admits": bool, "by"}]}. Every hidden failure must be
    traced; every trace with another reading needs the ruling on that same
    rule, for its subject and task."""
    want = hidden_failures(kept)
    if readings is None:
        return [f"readings.json is missing: {len(want)} failed hidden tests are not traced"], {}, []
    names = {s["name"] for s in kept}
    got, problems, admitted, other = set(), [], {}, []
    rulings = {(r["subject"], r["task"], r["rule"]): r for r in readings.get("rulings", [])}
    for tr in readings.get("traces", []):
        if tr["sample"] not in names:
            continue
        keys = {(tr["sample"], tr["round"], tr["task"], i) for i in tr["cases"]}
        if not keys or keys - want:
            problems.append(f"trace {tr['sample']} r{tr['round']} {tr['task']} {tr['cases']} names no case "
                            "or a case that is not a failed hidden test; its ruling is not applied")
            continue
        got |= keys
        if tr.get("other_reading"):
            other.append(tr)
            r = rulings.get((tr["sample"].split("-")[0], tr["task"], tr["rule"]))
            if r is None:
                problems.append(f"no ruling on rule {tr['rule']!r} for {tr['sample']} r{tr['round']} {tr['task']}, "
                                "traced to another reading")
            elif not r.get("sentence") or not r.get("by"):
                problems.append(f"ruling on rule {tr['rule']!r} for {tr['task']} names no sentence or no reviewer")
            elif r.get("admits"):
                admitted.setdefault(tr["sample"].split("-")[0], set()).add(tr["task"])
    if want - got:
        problems.append(f"{len(want - got)} failed hidden tests not traced, e.g. {sorted(want - got)[:3]}")
    return problems, admitted, other


def report(samples: dict, results_dir: str, readings: dict | None = None) -> str:
    out = [f"# Scored run analysis\n\nResults read from `{results_dir}`. Produced by `analyse.py`.\n"]
    voids = [s for s in samples.values() if s["void"]]
    out.append("## Voids and crashes\n")
    for s in sorted(voids, key=lambda s: s["started"] or s["name"]):
        out.append(f"- {s['name']}: {s['void']}")
    for subj, planned in SUBJECTS.items():
        for lang in ("python", "firth"):
            cell = [s for s in samples.values() if s["subject"] == subj and s["lang"] == lang]
            by = {}
            for s in cell:
                if s["void"]:
                    by[s["void"]] = by.get(s["void"], 0) + 1
            kept = sum(1 for s in cell if not s["void"])
            out.append(f"- {subj} {lang}: kept {kept} of {planned} planned; voids and crashes {sum(by.values())} {by}")
    out.append("")
    verdicts = {}
    for subj, planned in SUBJECTS.items():
        arms = {lang: sorted((s for s in samples.values() if s["subject"] == subj and s["lang"] == lang
                              and not s["void"]), key=lambda s: s["started"]) for lang in ("python", "firth")}
        nv = {lang: sum(1 for s in samples.values() if s["subject"] == subj and s["lang"] == lang and s["void"])
              for lang in ("python", "firth")}
        incomplete = any(len(a) < planned for a in arms.values())
        out.append(f"## {subj}\n")
        for lang, a in arms.items():
            out.append(f"### {lang} ({len(a)} kept), in run order\n")
            out.append("| sample | model | started | round 1 | within two | lengths | "
                       "per task, round 1 | per task, round 2 |")
            out.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
            for s in a:
                per_round = []
                for r in s["results"]:
                    causes = []
                    for t in TASKS:
                        k, counts = task_cause(lang, r["tasks"][t])
                        causes.append(t + ": " + (k if k in ("passed", "no answer") else
                                                  k + " " + json.dumps({x: y for x, y in counts.items() if x != "passed"})))
                    per_round.append("; ".join(causes))
                if len(per_round) == 1:
                    per_round.append("no round 2 (every example passed)")
                out.append(f"| {s['name']} | {', '.join(s['models'])} | {s['started'][:19]} | {s['round1']} | "
                           f"{s['within_two']} | {s['lengths']} | {per_round[0]} | {per_round[1]} |")
            out.append(f"\nTotal: round 1 {sum(s['round1'] for s in a)}, within two {sum(s['within_two'] for s in a)}.\n")
            if subj == "deepseek":
                out.append("DeepSeek rounds (prompt_eval_count, done_reason): " + "; ".join(
                    f"{s['name']} " + ", ".join(f"r{r['round']} {r['prompt_eval_count']} {r['done_reason']}"
                                                for r in s["rounds"]) for s in a) + "\n")
        if arms["firth"] and arms["python"]:
            for measure in ("within_two", "round1"):
                v = verdict([s[measure] for s in arms["firth"]], [s[measure] for s in arms["python"]], incomplete)
                verdicts[(subj, measure)] = v
                out.append(f"**{'Primary, within two rounds' if measure == 'within_two' else 'Secondary, round 1'}:** "
                           f"Firth {v['firth_mean']:.3f}, Python {v['python_mean']:.3f}, difference "
                           f"{v['difference']:+.3f}, exact two-sided p {v['p']:.4f}, 95% bootstrap interval "
                           f"[{v['interval'][0]:+.3f}, {v['interval'][1]:+.3f}]: {v['rule']}.\n")
        problems, admitted, other = readings_check(arms["firth"] + arms["python"], readings)
        for tr in other:
            out.append(f"- Another reading: {tr['sample']} round {tr['round']} {tr['task']}, hidden cases "
                       f"{tr['cases']}, rule {tr['rule']!r}: {tr.get('note', '')}")
        if other:
            out.append("")
        if problems:
            out.append("**Readings (preregistration.md, \"A reading nobody listed\") not complete:** "
                       + "; ".join(problems) + ". The result above is not final until they are.\n")
        elif admitted.get(subj) and arms["firth"] and arms["python"]:
            keep = [t for t in TASKS if t not in admitted[subj]]
            for label, idx in (("within two rounds", -1), ("round 1", 0)):
                per = lambda a: [sum(s["results"][idx]["tasks"][t]["pass"] for t in keep) for s in a]
                v = verdict(per(arms["firth"]), per(arms["python"]), incomplete)
                out.append(f"**Sensitivity check, never the headline:** leaving out {sorted(admitted[subj])} "
                           f"(ruled to admit another reading), {label}: Firth {v['firth_mean']:.3f}, "
                           f"Python {v['python_mean']:.3f}, difference {v['difference']:+.3f}, p {v['p']:.4f}, "
                           f"interval [{v['interval'][0]:+.3f}, {v['interval'][1]:+.3f}].\n")
        else:
            out.append("Readings: every failed hidden test is traced; no sentence was ruled to admit another reading.\n")
        if abs(nv["firth"] - nv["python"]) >= 2:
            out.append(f"Voids and crashes differ between arms by {abs(nv['firth'] - nv['python'])} "
                       f"(Firth {nv['firth']}, Python {nv['python']}): the surviving samples may differ between arms.\n")
        if incomplete:
            out.append("A cell has fewer than its planned samples: this comparison is incomplete, not a result.\n")
        g = guarantees(arms["firth"])
        out.append(f"### {subj} Firth guarantees\n")
        out.append("| row | diagnostics | refusals (round 1, visible) | round 2 differs on a hidden test | of those, round 2 ran |")
        out.append("| --- | --- | --- | --- | --- |")
        for rw in ROWS:
            if rw == "other refusal":
                out.append(f"| {rw} | {g['diagnostics'][rw]} | {g['refusals'][rw]} | never a catch | never a catch |")
            else:
                out.append(f"| {rw} | {g['diagnostics'][rw]} | {g['refusals'][rw]} | {g['catches'][rw]} | {g['catches_run'][rw]} |")
        out.append("| declared effects | not exercised | | | |\n")
        if g["no_code"]:
            out.append("Refusals with no `code:` line (other refusal): " + "; ".join(g["no_code"]) + "\n")
        out.append(f"Out of steps (1,000,000-step budget used up): {len(g['out_of_steps'])} {g['out_of_steps']}\n")
        out.append(f"Runtime refusals on hidden inputs: {len(g['hidden_runtime'])} {g['hidden_runtime']}\n")
        out.append("Measured kernel steps (reference interpreter), every case that ran to completion, per "
                   "round (round 2: the tasks it took). Measured, not a bound; no task has a Lean cost "
                   "contract, so no proved bound applies.\n")
        out.append("| round | task | passed cases | passed steps | wrong cases | wrong steps | total steps |")
        out.append("| --- | --- | --- | --- | --- | --- | --- |")
        for n in (1, 2):
            for t in TASKS:
                c = g["cost"][n][t]
                out.append(f"| {n} | {t} | {len(c['passed'])} | {sum(c['passed'])} | {len(c['wrong'])} | "
                           f"{sum(c['wrong'])} | {sum(c['passed']) + sum(c['wrong'])} |")
        out.append(f"\nCases with no measured cost, by cause: {g['no_cost']}\n")
    return "\n".join(out), verdicts


# ---------------------------------------------------------------- self-test

def planted_one_sided(a, b):
    pooled, n, m = a + b, len(a), len(b)
    total = sum(pooled)
    obs = sum(a) / n - sum(b) / m
    splits = list(itertools.combinations(range(n + m), n))
    return sum(1 for c in splits if (s := sum(pooled[i] for i in c)) / n - (total - s) / m >= obs - 1e-12) / len(splits)


def planted_pooled_boot(a, b, boot=BOOT, seed=SEED):
    rng, pooled = random.Random(seed), a + b
    d = sorted(sum(rng.choices(pooled, k=len(a))) / len(a) - sum(rng.choices(pooled, k=len(b))) / len(b)
               for _ in range(boot))
    return d[int(0.025 * boot)], d[int(0.975 * boot) - 1]


def stat_problems(perm=perm_p, boot=boot_interval) -> list[str]:
    p = []
    # Hand-worked: pooled [3,1,0,0], 6 splits; the first group's sums are
    # 4,3,3,1,1,0, so mean differences s-2 are 2,1,1,-1,-1,-2; |d| >= 2 in 2.
    if abs(perm([3, 1], [0, 0]) - 2 / 6) > 1e-12:
        p.append("perm: hand-worked [3,1] v [0,0] is not 1/3")
    if abs(perm([6] * 5, [0] * 5) - 2 / 252) > 1e-12:
        p.append("perm: smallest p for 5 v 5 is not 2/252")
    rng = random.Random(1)
    for n in (3, 5):
        for _ in range(30):
            a, b = [rng.randint(0, 6) for _ in range(n)], [rng.randint(0, 6) for _ in range(n)]
            if abs(perm(a, b) - perm_p_brute(a, b)) > 1e-12:
                p.append(f"perm: differs from enumeration on {a} {b}")
                break
    # Hand-worked: constant arms leave every resample at 4 - 1 = 3.
    if boot([4, 4, 4], [1, 1, 1]) != (3.0, 3.0):
        p.append("boot: constant arms do not give [3, 3]")
    # Hand-worked: [0, 6] resampled in pairs has mean 0 (1/4), 3 (1/2), 6 (1/4),
    # so the 2.5th and 97.5th percentiles of 10,000 resamples are 0 and 6.
    if boot([0, 6], [0]) != (0.0, 6.0):
        p.append("boot: [0,6] v [0] does not give [0, 6]")
    return p


def self_test() -> None:
    assert not stat_problems(), stat_problems()
    assert stat_problems(perm=planted_one_sided), "planted one-sided p not caught"
    assert stat_problems(boot=planted_pooled_boot), "planted pooled bootstrap not caught"
    # Decision rules.
    assert verdict([6] * 8, [0] * 8, False)["rule"] == "materially higher in Firth"
    assert verdict([0] * 8, [6] * 8, False)["rule"] == "materially higher in Python"
    assert verdict([6] * 8, [6, 6, 6, 6, 6, 6, 6, 5], False)["rule"] == "parity at the ceiling"
    assert verdict([0] * 8, [1, 0, 0, 0, 0, 0, 0, 0], False)["rule"] == "parity at the floor"
    assert verdict([6] * 2, [0] * 5, True)["rule"].startswith("incomplete")
    assert verdict([3, 4, 3, 4], [3, 3, 4, 4], False)["rule"] == "not material"
    # Error sorting.
    assert row("firth.type.branch-mismatch") == "stack effects"
    assert row("firth.type.word-input-mismatch") == "checked types"
    assert row("firth.linearity.dropped") == "linear ownership"
    assert row("firth.syntax.unexpected-eof") == "other refusal" and row("x.y") == "other refusal"
    assert codes("The checker found 2 errors\nerror 1 of 2\ncode: firth.type.a\nerror 2 of 2\ncode: firth.name.b") \
        == ["firth.type.a", "firth.name.b"]
    cc = lambda **k: case_cause(k.pop("lang", "firth"), k)
    assert cc(ok=True, **{"pass": True}) == "passed"
    assert cc(ok=True, **{"pass": False}) == "wrong result"
    assert cc(ok=False, error="trap fuel-exhausted\n{...}") == "out of steps"
    assert cc(ok=False, error="trap primitive-fault") == "runtime error"
    assert cc(ok=False, error="timeout") == "timeout"
    assert cc(ok=False, error="code: firth.type.x\nmessage: m") == "refusal"
    assert cc(ok=False, error='{"error": "entry main: initial stack type mismatch"}') == "refusal"
    assert cc(lang="python", ok=False, error="Traceback (most recent call last):") == "runtime error"
    assert task_cause("firth", {"submitted": False})[0] == "no answer"
    assert task_cause("firth", {"submitted": True, "pass": False, "cases": [
        {"ok": True, "pass": False}, {"ok": False, "error": "trap fuel-exhausted"}]})[0] == "out of steps"
    # Guarantee catches: a refusal whose round-2 answer behaves differently on a
    # hidden test counts under its guarantee row, never under other refusal.
    def refused(code):
        err = f"code: {code}\nmessage: m"
        return {"submitted": True, "pass": False, "cases": [{"visible": True, "ok": False, "error": err},
                                                             {"visible": False, "ok": False, "error": err}]}
    fixed = {"submitted": True, "pass": True, "cases": [{"visible": True, "ok": True, "pass": True, "kernel_cost": 1},
                                                        {"visible": False, "ok": True, "pass": True, "kernel_cost": 1}]}
    r1 = {"tasks": {t: fixed for t in TASKS}}
    r1["tasks"]["sokoban"] = refused("firth.type.stack-mismatch")
    r1["tasks"]["regex"] = refused("firth.syntax.invalid-declaration")
    g = guarantees([{"name": "s", "results": [r1, {"tasks": {t: fixed for t in TASKS}}]}])
    assert g["refusals"]["stack effects"] == 1 and g["catches"]["stack effects"] == 1
    assert g["refusals"]["other refusal"] == 1 and g["catches"]["other refusal"] == 0, g["catches"]
    assert g["catches_run"]["other refusal"] == 0
    # Readings: an untraced hidden failure, and a traced other reading with no
    # ruling, are each reported; an admitted reading gives a sensitivity check.
    wrong = {"submitted": True, "pass": False, "cases": [{"visible": True, "ok": True, "pass": True, "kernel_cost": 1},
                                                        {"visible": False, "ok": True, "pass": False, "kernel_cost": 1}]}
    # Round 1: swiss runs and fails a hidden test; regex has no answer, so it is
    # listed and taken in round 2, where it fails a hidden test too.
    r1 = {"tasks": {**{t: fixed for t in TASKS}, "swiss": wrong, "regex": {"submitted": False}}}
    r2 = {"tasks": {**{t: fixed for t in TASKS}, "swiss": wrong, "regex": wrong}}
    ks = [{"name": "sonnet-firth-1", "lang": "firth", "results": [r1, r2]}]
    assert hidden_failures(ks) == {("sonnet-firth-1", 1, "swiss", 1), ("sonnet-firth-1", 2, "regex", 1)}
    assert readings_check(ks, None)[0]
    t1 = {"sample": "sonnet-firth-1", "round": 1, "task": "swiss", "cases": [1], "rule": "r", "other_reading": True}
    t2 = {"sample": "sonnet-firth-1", "round": 2, "task": "regex", "cases": [1], "rule": "q", "other_reading": False}
    assert readings_check(ks, {"traces": [t1]})[0], "untraced round-2 failure not reported"
    assert readings_check(ks, {"traces": [t1, t2]})[0], "missing ruling not reported"
    wrong_rule = [{"subject": "sonnet", "task": "swiss", "rule": "other", "admits": True}]
    assert readings_check(ks, {"traces": [t1, t2], "rulings": wrong_rule})[0], "ruling on another rule accepted"
    bare = {"traces": [t1, t2], "rulings": [{"subject": "sonnet", "task": "swiss", "rule": "r", "admits": True}]}
    assert readings_check(ks, bare)[0], "ruling with no sentence or reviewer accepted"
    ok = {"traces": [t1, t2], "rulings": [{"subject": "sonnet", "task": "swiss", "rule": "r", "admits": True,
                                           "sentence": "s", "by": "reviewer"}]}
    assert readings_check(ks, ok) == ([], {"sonnet": {"swiss"}}, [t1])
    for bad in ([], [0], [7]):  # no case, a passing visible case, no such case
        bt = {**t1, "task": "swiss", "cases": bad}
        pr, adm, _ = readings_check(ks, {"traces": [t1, t2, {**bt, "rule": "s"}],
                                         "rulings": ok["rulings"] + [{"subject": "sonnet", "task": "swiss",
                                                                      "rule": "s", "admits": True,
                                                                      "sentence": "s", "by": "reviewer"}]})
        assert pr, f"trace naming {bad} accepted"
    # Costs: round 1's runs count, and round 2 counts only the task it took.
    g = guarantees([{"name": "sonnet-firth-1", "lang": "firth", "results": [r1, r2]}])
    assert len(g["cost"][1]["sokoban"]["passed"]) == 2 and not g["cost"][2]["sokoban"]["passed"]
    assert len(g["cost"][2]["regex"]["wrong"]) == 1 and len(g["cost"][1]["swiss"]["wrong"]) == 1
    # Voids from planted sample files, and the voids.txt cross-check.
    with tempfile.TemporaryDirectory() as tmp:
        run = Path(tmp)
        clean_ctx = {"injected": [{"kind": "system-reminder", "chars": 341}, {"kind": "other", "chars": 183}],
                     "cross_sample": [], "compactions": []}
        scan = []

        def sub(name, flagged=(), ctx=clean_ctx, scanline="others: 0  task_status: 0  notification: 0  "
                "compact: 0  queued_command: 0  project message: 0", transcript=True):
            d = run / name
            d.mkdir()
            if transcript:
                calls = [{"tool": "Read"}, {"tool": "Write"}] + ([{"tool": "SubagentHandback"}] if transcript != "no-handback" else [])
                (d / "transcript.json").write_text(json.dumps({"flagged": list(flagged), "started": "t",
                                                               "tool_calls": calls}))
                (d / "answer-1.md").write_text("x")
            (d / "context-seen.json").write_text(json.dumps(ctx))
            scan.append(f"{name} (a0)\n  {scanline}")

        def ds(name, status="scored", count=5000, chars=8000):
            d = run / name
            d.mkdir()
            (d / "outcome.json").write_text(json.dumps({"status": status, "rounds": []}))
            (d / "response-1.json").write_text(json.dumps({"prompt_eval_count": count}))
            (d / "request-1.json").write_text(json.dumps({"body": {"messages": [{"content": "x" * chars}]}}))

        sub("sonnet-firth-1")
        sub("sonnet-firth-2", flagged=["x: not what the author wrote"])
        sub("sonnet-firth-3", ctx={**clean_ctx, "injected": [{"kind": "handback-enforce", "chars": 141}]})
        sub("sonnet-firth-4", ctx={**clean_ctx, "injected": [{"kind": "other", "chars": 141}]})
        sub("sonnet-firth-5", scanline="others: 1  task_status: 0  notification: 0  compact: 0  "
            "queued_command: 0  project message: 0")
        sub("sonnet-firth-6", transcript=False)
        sub("sonnet-firth-7", ctx={**clean_ctx, "cross_sample": [3]})
        sub("sonnet-firth-8", transcript="no-handback")
        ds("deepseek-firth-1")
        ds("deepseek-firth-2", status="void")
        ds("deepseek-firth-3", count=999, chars=8000)
        ds("deepseek-firth-4", count=None)
        (run / "scan-output.txt").write_text("\n".join(scan))
        scans = scan_counts((run / "scan-output.txt").read_text())
        got = {d.name: void_cause(d, scans) for d in run.iterdir() if d.is_dir()}
        want = {"sonnet-firth-1": None, "sonnet-firth-2": "audit flag", "sonnet-firth-3": "context",
                "sonnet-firth-4": "context", "sonnet-firth-5": "context", "sonnet-firth-6": "crash",
                "sonnet-firth-7": "context", "sonnet-firth-8": "crash", "deepseek-firth-1": None, "deepseek-firth-2": "transport",
                "deepseek-firth-3": "transport", "deepseek-firth-4": "missing prompt count"}
        assert got == want, got
        fake = {n: {"void": v} for n, v in got.items()}
        listed = "\n".join(n for n, v in want.items() if v)
        assert not check_voids(fake, listed)
        assert check_voids(fake, listed.replace("sonnet-firth-3\n", "")), "missing void not caught"
        assert check_voids(fake, listed + "\nsonnet-firth-1"), "extra void not caught"
    print("self-test ok")


def main() -> None:
    args = sys.argv[1:]
    if args == ["--self-test"]:
        self_test()
        return
    results = "rescore-pin"
    if args[:1] == ["--results"]:
        results = args[1]
    samples = load(HERE, HERE / results)
    problems = check_voids(samples, (HERE / "voids.txt").read_text())
    if problems:
        raise SystemExit("voids differ from voids.txt:\n" + "\n".join(problems))
    rf = HERE / "readings.json"
    text, _ = report(samples, results, json.loads(rf.read_text()) if rf.exists() else None)
    print(text)


if __name__ == "__main__":
    main()
