#!/usr/bin/env python3
"""What run 11's failing Haiku answers failed on, by rule.

Usage, from eval/s7: python3 runs/2026-09-29-locals-guide/causes/causes.py [--self-test]

Reads the 20 counted samples of each arm (analyse.py's rule)
and writes `units.json`, one row per answer an author wrote for a task:
arm, sample, round (1 is the first answer, 2 and 3 the answers after each
feedback round), task, whether it passed, the first diagnostic in the kept
results (what the author was shown first), and every diagnostic the
pinned `5d09e25` checker reports for the same source (`rechecked.json`, from
`recheck.py`). Then prints the tables the write-up uses.

A task is "written" in round 1 for every task, and in rounds 2 and 3 only
when the author's answer file has a block for it (`harness.extract`).
Final state is `solutions-3.json`, which carries unrewritten tasks forward.

Families group diagnostic codes; nothing here reads an answer's meaning.
A diagnostic whose `assumes` names another word is a report the checker made
assuming a broken callee keeps its declared effect, so it is counted as
dependent, not as an independent error.
"""
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
RUN = HERE.parent
sys.path.insert(0, str(RUN.parents[1]))
from harness import extract  # noqa: E402

sys.path.insert(0, str(RUN))
from analyse import ARMS, counted as counted_in  # noqa: E402
FAMILIES = [
    ("syntax", lambda c: c.startswith("firth.syntax.")),
    ("unknown-name", lambda c: c in ("firth.name.unresolved", "firth.name.unresolved-effect")),
    ("locals", lambda c: c in ("firth.name.locals-order", "firth.elaboration.untracked-local")),
    ("branch-mismatch", lambda c: c == "firth.type.branch-mismatch"),
    ("declared-effect", lambda c: c == "firth.type.declared-effect-mismatch"),
    ("input-mismatch", lambda c: c.startswith("firth.type.")),
]


def family(code):
    if code is None:
        return None
    for name, test in FAMILIES:
        if test(code):
            return name
    return "other:" + code


def seen(task):
    """The family and code of the first thing the author was shown for a failing task."""
    case = next((c for c in task.get("cases") or [] if not c["pass"]), None)
    if case is None:
        return "not-scored", None
    err = case.get("error") or ""
    m = re.search(r"code: (\S+)", err)
    if m:
        return family(m[1]), m[1]
    if "trap" in err:
        return "runtime-trap", None
    if case.get("ok"):
        return "wrong-result", None
    return "other", None


def counted():
    for arm, path in ARMS.items():
        for d in counted_in(path):
            yield arm, d


def passed(task):
    cs = task.get("cases") or []
    return bool(cs) and all(c["pass"] for c in cs)


def build():
    rechecked = json.loads((HERE / "rechecked.json").read_text())["answers"]
    rows = []
    for arm, d in counted():
        sample = f"{arm}{d.name.rsplit('-', 1)[1]}"
        for n in (1, 2, 3):
            sols = json.loads((d / f"solutions-{n}.json").read_text())
            res = json.loads((d / f"results-{n}.json").read_text())["tasks"]
            written = set(sols) if n == 1 else set(extract((d / f"answer-{n}.md").read_text()))
            for task, src in sols.items():
                if task not in res:
                    continue  # a block for a task the set does not have; never scored
                t = res[task]
                ok = passed(t)
                fam, code = (None, None) if ok else seen(t)
                diags = rechecked[hashlib.sha256(src.encode()).hexdigest()]
                rows.append({
                    "arm": arm, "sample": sample, "round": n, "task": task,
                    "written": task in written, "passed": ok,
                    "seen_family": fam, "seen_code": code,
                    "errors": [{"code": x["code"], "family": family(x["code"]), "word": x["word"],
                                "line": x["line"], "dependent": bool(x.get("assumes"))}
                               for x in diags],
                    "chars": len(src),
                })
    return rows


def table(title, counter, total=None):
    print(f"\n{title}")
    for k, v in counter.most_common():
        print(f"  {v:4d}  {k}" + (f"  ({100 * v / total:.0f}%)" if total else ""))


def feedback(rows):
    """For a task that failed in round n and was rewritten in n + 1: what happened."""
    by = {(r["sample"], r["round"], r["task"]): r for r in rows}
    out = Counter()
    skipped = 0
    for r in rows:
        if r["round"] == 3 or r["passed"]:
            continue
        nxt = by[(r["sample"], r["round"] + 1, r["task"])]
        if not nxt["written"]:
            skipped += 1
            continue
        if nxt["passed"]:
            out["passed"] += 1
        elif nxt["seen_code"] == r["seen_code"] and nxt["seen_family"] == r["seen_family"]:
            words_before = {e["word"] for e in r["errors"] if e["code"] == r["seen_code"]}
            words_after = {e["word"] for e in nxt["errors"] if e["code"] == nxt["seen_code"]}
            out["same first error, same word" if words_before & words_after
                else "same first error, other word"] += 1
        else:
            out["first error changed"] += 1
    return out, skipped


def report(rows):
    first = [r for r in rows if r["round"] == 1]
    final = [r for r in rows if r["round"] == 3]
    for label, rs in (("First answers", first), ("Final answers", final)):
        fails = [r for r in rs if not r["passed"]]
        print(f"\n== {label}: {len(rs)} tasks, {len(rs) - len(fails)} passed, {len(fails)} failed")
        table("First diagnostic shown, by family", Counter(r["seen_family"] for r in fails), len(fails))
        table("First diagnostic shown, by code (checker failures)",
              Counter(r["seen_code"] for r in fails if r["seen_code"]))
        indep = Counter(sum(not e["dependent"] for e in r["errors"]) for r in fails)
        table("Independent errors per failing answer (5d09e25 checker, one per word)", indep)
        only = Counter()
        for r in fails:
            fams = {e["family"] for e in r["errors"] if not e["dependent"]}
            if len(fams) == 1:
                only[next(iter(fams))] += 1
            elif not fams:
                only[f"no checker error ({r['seen_family']})"] += 1
            else:
                only["two or more families"] += 1
        table("Failing answers whose independent errors are all in one family", only)
        involved = Counter(f for r in fails for f in {e["family"] for e in r["errors"]
                                                     if not e["dependent"]})
        table("Failing answers with at least one independent error in each family", involved)
        per_task = defaultdict(Counter)
        for r in fails:
            per_task[r["task"]][r["seen_family"]] += 1
        print("\nPer task: failing answers, and the commonest first family")
        for task in sorted(per_task, key=lambda t: -sum(per_task[t].values())):
            c = per_task[task]
            print(f"  {task:18s} {sum(c.values()):3d}  " +
                  ", ".join(f"{k} {v}" for k, v in c.most_common(3)))
        per_sample = defaultdict(Counter)
        for r in rs:
            per_sample[r["sample"]]["passed" if r["passed"] else r["seen_family"]] += 1
        print("\nPer sample: passed, and the commonest first families")
        for s in sorted(per_sample, key=lambda s: (s[0], int(s[1:]))):
            c = per_sample[s]
            fails_c = Counter({k: v for k, v in c.items() if k != "passed"})
            print(f"  {s:4s} passed {c['passed']:2d}  " +
                  ", ".join(f"{k} {v}" for k, v in fails_c.most_common(3)))
    out, skipped = feedback(rows)
    total = sum(out.values())
    table(f"Feedback rounds: a failing task rewritten in the next round ({total}; "
          f"{skipped} failing tasks were not rewritten)", out, total)


def self_test():
    assert family("firth.syntax.invalid-item") == "syntax"
    assert family("firth.type.branch-mismatch") == "branch-mismatch"
    assert family("firth.type.word-input-mismatch") == "input-mismatch"
    assert family("firth.name.locals-order") == "locals"
    assert family("firth.name.unresolved") == "unknown-name"
    assert family("firth.new.code") == "other:firth.new.code"
    fail = {"cases": [{"pass": False, "ok": True, "error": None}]}
    assert seen(fail) == ("wrong-result", None)
    fail = {"cases": [{"pass": True}, {"pass": False, "ok": False,
                                       "error": "code: firth.type.expected-bool\nat: line 1"}]}
    assert seen(fail) == ("input-mismatch", "firth.type.expected-bool")
    assert not passed({"cases": []}) and passed({"cases": [{"pass": True}]})
    # Planted: a task that failed, was rewritten with the same error on the same word.
    rows = [
        {"sample": "A1", "round": 1, "task": "t", "passed": False, "written": True,
         "seen_family": "branch-mismatch", "seen_code": "c",
         "errors": [{"code": "c", "word": "w", "family": "branch-mismatch", "dependent": False}]},
        {"sample": "A1", "round": 2, "task": "t", "passed": False, "written": True,
         "seen_family": "branch-mismatch", "seen_code": "c",
         "errors": [{"code": "c", "word": "w", "family": "branch-mismatch", "dependent": False}]},
        {"sample": "A1", "round": 3, "task": "t", "passed": True, "written": True,
         "seen_family": None, "seen_code": None, "errors": []},
    ]
    out, skipped = feedback(rows)
    assert out == Counter({"same first error, same word": 1, "passed": 1}) and skipped == 0, out
    rows[2]["written"] = False
    rows[2]["passed"] = False
    out, skipped = feedback(rows)
    assert skipped == 1, (out, skipped)
    print("self-test ok")


def main():
    if "--self-test" in sys.argv:
        return self_test()
    rows = build()
    (HERE / "units.json").write_text(json.dumps(rows, indent=0) + "\n")
    report(rows)


if __name__ == "__main__":
    main()
