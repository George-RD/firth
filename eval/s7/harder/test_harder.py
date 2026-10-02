#!/usr/bin/env python3
"""Checks for the harder S7 tier, run before any model sees a task.

1. Each task's Python `ref` agrees with values worked out by hand from the
   description, written here without running the refs.
2. Each task's Python reference solution (`reference/<set>/python/<id>.py`, written
   separately from the ref) passes its example and hidden tests.
3. Each task's Firth reference solution (`reference/<set>/firth/<id>.firth`)
   passes its example and hidden tests on both hosts, using at most a
   quarter of the step budget on every case, so an author's slower but
   reasonable program still fits.
4. The hidden tests catch the mistakes a careful author is likely to make:
   for every task, a planted Python mutant with one such mistake fails, and a
   planted mutant of a Firth reference fails.
5. The prompt carries no hidden input and repair shows only the example.
6. The audit refuses options that widen an author's tools, and scoring
   refuses a link named as the answer directory.

    python3 eval/s7/harder/test_harder.py            # everything (needs the toolchain)
    python3 eval/s7/harder/test_harder.py --no-firth # 1, 2, the Python part of 4, and 5
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import tier  # noqa: E402
from tier import BY_ID, SETS, harness  # noqa: E402

FAILED = []


def check(ok: bool, what: str) -> None:
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        FAILED.append(what)


# (task id, inputs, outputs), worked out by hand from the descriptions.
HAND = [
    # X=20, 7/3+9=39, 9-0=48, X+0+8=66, 0-8=74, 8/2+0=84, 0-6=90, X+X+X=120, X+X+8=148, X81=167.
    ("bowling", ([10, 7, 3, 9, 0, 10, 0, 8, 8, 2, 0, 6, 10, 10, 10, 8, 1],),
     ([20, 39, 48, 66, 74, 84, 90, 120, 148, 167],)),
    ("bowling", ([10] * 12,), ([30, 60, 90, 120, 150, 180, 210, 240, 270, 300],)),
    # Tenth frame 7/3 then 10: 63 + 20.
    ("bowling", ([3, 4] * 9 + [7, 3, 10],), ([7, 14, 21, 28, 35, 42, 49, 56, 63, 83],)),
    # Strike then two gutters: 10, then 0, then 2 a frame.
    ("bowling", ([10, 0, 0] + [1, 1] * 8,), ([10, 10, 12, 14, 16, 18, 20, 22, 24, 26],)),
    # 1 2 miss, 1 hit, 3 miss evicts 2, 2 miss evicts 1.
    ("lru", (2, [1, 2, 1, 3, 2]), (4, [3, 2])),
    ("lru", (1, [5, 5, 5]), (1, [5])),
    ("lru", (1, []), (0, [])),
    ("rpn", ([0, 0, 0, 3, 1], [2, 3, 4, 0, 0]), (14, 0)),
    ("rpn", ([0, 0, 4], [-7, 2, 0]), (-3, 0)),
    ("rpn", ([0, 0, 4], [-1, 5, 0]), (0, 0)),
    ("rpn", ([0, 0, 4, 0, 1], [5, 0, 0, 1, 0]), (0, 2)),
    ("rpn", ([5, 0], [0, 1]), (0, 1)),
    ("rpn", ([], []), (0, 3)),
    ("rpn", ([0, 0, 0, 1], [1, 2, 3, 0]), (0, 3)),
    # 3*3=9, 9*9=81, 81-80=1.
    ("rpn", ([0, 5, 3, 5, 3, 0, 2], [3, 0, 0, 0, 0, 80, 0]), (1, 0)),
    # Delete 2, insert 4.
    ("edit-cost", ([1, 2, 3], [1, 3, 4], 1, 1, 1), (2,)),
    ("edit-cost", ([], [1, 2, 3], 2, 7, 1), (6,)),
    ("edit-cost", ([4, 4], [], 2, 7, 1), (14,)),
    # Replacing costs 5, deleting and inserting 2.
    ("edit-cost", ([1, 2, 3], [1, 9, 3], 1, 1, 5), (2,)),
    ("edit-cost", ([1, 2, 3], [1, 9, 3], 3, 3, 5), (5,)),
    # 0->1->3 costs 2 with 2 hops; 0->2 costs 4.
    ("shortest-hops", (4, [0, 0, 1, 2], [1, 2, 3, 3], [1, 4, 1, 1], 0), ([0, 1, 4, 2], [0, 1, 1, 2])),
    # Zero weights: 2 is reached at 0 by the direct edge, 1 hop.
    ("shortest-hops", (3, [0, 1, 0], [1, 2, 2], [0, 0, 0], 0), ([0, 0, 0], [0, 1, 1])),
    # 0->3 directly costs 3, the same as 0->1->2->3, so 1 hop.
    ("shortest-hops", (4, [0, 1, 2, 0], [1, 2, 3, 3], [1, 1, 1, 3], 0), ([0, 1, 2, 3], [0, 1, 2, 1])),
    ("shortest-hops", (3, [], [], [], 1), ([-1, 0, -1], [-1, 0, -1])),
    ("merge-ranges", ([8, 1, 4, 15], [10, 3, 6, 15]), ([1, 8, 15], [6, 10, 15], 10)),
    ("merge-ranges", ([1, 4], [2, 5]), ([1, 4], [2, 5], 4)),
    ("merge-ranges", ([1, 3], [2, 4]), ([1], [4], 4)),
    ("merge-ranges", ([1, 1], [10, 3]), ([1], [10], 10)),
    ("merge-ranges", ([], []), ([], [], 0)),
    # r0=5, r1=1, r2=1; loop r1*=r0, r0-=r2 five times; halt: 3 + 15 + 1.
    ("tiny-vm", ([1, 0, 5, 1, 1, 1, 1, 2, 1, 4, 1, 0, 3, 0, 2, 6, 0, 3, 0, 0, 0], [0, 0, 0, 0], 100),
     ([0, 120, 1, 0], 19, 0)),
    ("tiny-vm", ([], [1, 2, 3, 4], 10), ([1, 2, 3, 4], 0, 1)),
    ("tiny-vm", ([0, 0, 0], [1, 2, 3, 4], 1), ([1, 2, 3, 4], 1, 0)),
    ("tiny-vm", ([0, 0, 0], [1, 2, 3, 4], 0), ([1, 2, 3, 4], 0, 2)),
    # r1=1, then r0+=r1 and a jump back, forever: 7 executed, r0 = 3.
    ("tiny-vm", ([1, 1, 1, 2, 0, 1, 6, 0, 1], [0, 0, 0, 0], 7), ([3, 1, 0, 0], 7, 2)),
    # Jump to -1 is out of range after one instruction.
    ("tiny-vm", ([6, 0, -1, 0, 0, 0], [1, 0, 0, 0], 10), ([1, 0, 0, 0], 1, 1)),
    # r0 = 6 counts down by 2 until negative: 2 + 3*4 + 2 + 2.
    ("tiny-vm", ([1, 0, 6, 1, 1, 2, 3, 0, 1, 7, 0, 6, 2, 2, 1, 6, 1, 2, 1, 3, 77, 0, 0, 0],
                 [5, 5, 5, 5], 300), ([-2, 2, 11, 77], 18, 0)),
    ("lis-smallest", ([5, 1, 6, 2, 7, 3],), ([1, 2, 3],)),
    ("lis-smallest", ([],), ([],)),
    ("lis-smallest", ([3, 3, 3],), ([3],)),
    ("lis-smallest", ([5, 4, 3, 2, 1],), ([1],)),
    # 1 2 5 6 and 1 2 4 6 are both longest; 4 < 5.
    ("lis-smallest", ([3, 1, 2, 0, 5, 4, 6],), ([1, 2, 4, 6],)),
    ("lis-smallest", ([2, 9, 3, 8, 4],), ([2, 3, 4],)),
]


def hand_values() -> None:
    for tid, args, want in HAND:
        check(tuple(BY_ID[tid].ref(*args)) == want, f"hand value: {tid}{args} = {want}")
    covered = {tid for tid, _, _ in HAND}
    check(covered == set(BY_ID), f"every task has hand values (missing: {sorted(set(BY_ID) - covered)})")


def cases(t):
    return (t.example, *t.hidden)


def python_references() -> None:
    """In-process: these are our own files, not an author's answer."""
    for name, tasks in SETS.items():
        for t in tasks:
            ns: dict = {}
            exec(compile((HERE / "reference" / name / "python" / f"{t.id}.py").read_text(), f"{t.id}.py", "exec"), ns)
            bad = [args for args in cases(t)
                   if not harness.same(json.loads(json.dumps(as_list(ns["main"](*args), t))), t.expected(args))]
            check(not bad, f"Python reference {name}/{t.id} passes {len(cases(t))} cases (failing: {bad[:1]})")


def as_list(r, t):
    return list(r) if len(t.outputs) > 1 else [r]


def firth_references() -> None:
    for name, tasks in SETS.items():
        sols = {t.id: (HERE / "reference" / name / "firth" / f"{t.id}.firth").read_text() for t in tasks}
        res = tier.score(sols, "firth", list(tasks))
        for t in tasks:
            r = res["tasks"][t.id]
            vis = r["cases"][0]["pass"]
            check(r["pass"] and vis, f"Firth reference {name}/{t.id}: example {'passes' if vis else 'FAILS'}, "
                  f"hidden {r['hidden_passed']}/{r['hidden_total']}")
            most = max((c.get("kernel_cost") or 0) for c in r["cases"])
            check(0 < most <= tier.FUEL // 4,
                  f"Firth reference {name}/{t.id}: most kernel steps on a case {most:,} (budget {tier.FUEL:,})")


# One plausible mistake per task, each a whole Python answer. Every one must
# fail at least one hidden test, which shows the hidden tests can fail an answer
# that passes the visible example.
PY_MUTANTS = {
    # The tenth frame's extra rolls scored as frames of their own: frames 1-10 all
    # take a strike bonus, but the walk is right, so this one double-counts only
    # when frame 10 is a spare scored without its bonus.
    "bowling": ("a spare in the tenth frame scored without its bonus roll",
                (HERE / "reference/calibration/python/bowling.py").read_text().replace(
                    "bonus = rolls[pos + 2] if first + second == 10 else 0",
                    "bonus = rolls[pos + 2] if first + second == 10 and frame < 9 else 0")),
    "lru": ("a hit refreshes the key only when the cache is full",
            (HERE / "reference/calibration/python/lru.py").read_text().replace(
                "cache.move_to_end(k)\n", "if len(cache) >= cap:\n                cache.move_to_end(k)\n")),
    "rpn": ("division floors instead of truncating",
            (HERE / "reference/calibration/python/rpn.py").read_text().replace(
                "if q < 0 and q * b != a:", "if False:")),
    "edit-cost": ("the insert and delete costs swapped",
                  (HERE / "reference/calibration/python/edit-cost.py").read_text()
                  .replace("def main(xs, ys, insert, delete, replace):",
                           "def main(xs, ys, delete, insert, replace):")),
    "shortest-hops": ("hops is the fewest edges overall, not among the shortest paths",
                      (HERE / "reference/calibration/python/shortest-hops.py").read_text().replace(
                          "    return [-1 if b is None else b[0] for b in best], "
                          "[-1 if b is None else b[1] for b in best]\n",
                          "    hops = [-1] * n\n    hops[source] = 0\n    frontier = [source]\n"
                          "    while frontier:\n        nxt = []\n        for v in frontier:\n"
                          "            for b, _ in adj[v]:\n                if hops[b] < 0:\n"
                          "                    hops[b] = hops[v] + 1\n                    nxt.append(b)\n"
                          "        frontier = nxt\n"
                          "    return [-1 if b is None else b[0] for b in best], hops\n")),
    "merge-ranges": ("covered counted from the input ranges, so overlaps count twice",
                     (HERE / "reference/calibration/python/merge-ranges.py").read_text().replace(
                         "sum(b - a + 1 for a, b in zip(ms, me))",
                         "sum(b - a + 1 for a, b in zip(starts, ends))")),
    "tiny-vm": ("a halt runs even when the limit is used up",
                (HERE / "reference/calibration/python/tiny-vm.py").read_text().replace(
                    "if executed >= limit:", "if executed >= limit and code[3 * pc] != 0:")),
    "lis-smallest": ("the smallest tail of each length, which need not be a subsequence",
                     "from bisect import bisect_left\n"
                     "def main(xs):\n"
                     "    tails = []\n"
                     "    for x in xs:\n"
                     "        i = bisect_left(tails, x)\n"
                     "        tails[i:i + 1] = [x]\n"
                     "    return tails\n"),
}


def python_mutants() -> None:
    check(set(PY_MUTANTS) == set(BY_ID), "every task has a Python mutant")
    for tid, (what, src) in PY_MUTANTS.items():
        t = BY_ID[tid]
        ns: dict = {}
        exec(compile(src, f"{tid}-mutant.py", "exec"), ns)
        caught = [args for args in t.hidden
                  if not harness.same(json.loads(json.dumps(as_list(ns["main"](*args), t))), t.expected(args))]
        example = harness.same(json.loads(json.dumps(as_list(ns["main"](*t.example), t))),
                               t.expected(t.example))
        check(example and bool(caught), f"Python mutant of {tid} ({what}) passes the example and fails "
              f"{len(caught)} hidden test(s)")


def firth_mutant() -> None:
    """A planted bug in a Firth reference: the scorer must fail it."""
    src = (HERE / "reference/calibration/firth/lru.firth").read_text()
    t = BY_ID["lru"]
    mutant = src.replace("c prim seq-int.len cap prim <", "c prim seq-int.len cap 1 prim + prim <", 1)
    check(mutant != src, "the lru mutant changes the reference")
    res = tier.score({"lru": mutant}, "firth", [t])["tasks"]["lru"]
    check(all(c["ok"] for c in res["cases"]), "the lru mutant checks and runs on every case")
    check(not res["pass"], "a Firth lru reference that holds cap + 1 keys fails the hidden tests "
          f"({res['hidden_passed']}/{res['hidden_total']})")


def prompt_and_repair() -> None:
    for name, tasks in SETS.items():
        for lang in ("firth", "python"):
            text = tier.prompt(list(tasks), lang)
            check(all(f"## {t.id}\n" in text for t in tasks), f"{name} {lang} prompt lists every task")
            leaked = [t.id for t in tasks for h in t.hidden
                      if len(json.dumps(list(h))) > 12 and
                      ", ".join(harness.lit(v, lang) for v in h) in text]
            check(not leaked, f"{name} {lang} prompt shows no hidden input (leaked: {leaked})")
    t = BY_ID["rpn"]
    results = {"tasks": {"rpn": {"submitted": True, "cases": [
        {"visible": True, "ok": True, "stack": [0, 0], "expected": [14, 0], "pass": False},
        {"visible": False, "ok": True, "stack": [9, 9], "expected": [42, 0], "pass": False}]}}}
    text = tier.repair({"rpn": "def main(k, v): return 0, 0\n"}, results, "python", [t])
    check("[14, 0]" in text and "[42, 0]" not in text and "[9, 9]" not in text,
          "repair shows the example's outcome and nothing from a hidden test")
    results["tasks"]["rpn"]["cases"][0].update(stack=[14, 0], ok=True, **{"pass": True})
    check(tier.repair({"rpn": ""}, results, "python", [t]) == "",
          "repair is empty, so no round runs, when every answer passed its example")


def refusals() -> None:
    """The audit refuses any option that could widen what an author may do,
    however it is spelt, and scoring refuses a link named as answer directory."""
    import subprocess, tempfile
    for opt in ("--check-cmd=/x", "--check-c=/x", "--shell-forms", "--hook=/x"):
        p = subprocess.run([sys.executable, str(HERE / "audit.py"), "/dev/null", "--set", "calibration",
                            "--prompt", "p", "--dir", "d", "--rounds", "1", "--lang", "firth", opt],
                           capture_output=True, text=True)
        check(p.returncode != 0 and "takes only" in p.stderr, f"audit refuses {opt}")
    with tempfile.TemporaryDirectory() as d:
        link = Path(d) / "answers"
        link.symlink_to(HERE / "reference/calibration/firth")
        try:
            tier.load(link, "firth")
            refused = False
        except (OSError, ValueError):
            refused = True
        check(refused, "scoring refuses a link named as the answer directory")
        real = Path(d) / "real"
        real.mkdir()
        (real / "lru.firth").write_text("x")
        (real / "lru.py").write_text("y")
        check(tier.load(real, "firth") == {"lru": "x"} and tier.load(real, "python") == {"lru": "y"},
              "a directory's answers are read in the language scored only")
    sandbox_scan()


def sandbox_scan() -> None:
    """The scan run before scoring Python finds a copy of this tier's hidden
    files where the sandbox would show it, and passes a directory without one."""
    import shutil, subprocess, tempfile
    git = ["git", "-c", "user.name=t", "-c", "user.email=t@t", "-c", "init.defaultBranch=main"]
    with tempfile.TemporaryDirectory() as d:
        clean = Path(d) / "clean"
        (clean / "lib").mkdir(parents=True)
        (clean / "lib" / "lru.py").write_text("def main(c, ops):\n    return []\n")
        subprocess.run(git + ["init", "-q", str(clean / "repo")], check=True)
        check(tier.tier_copies((str(clean),)) == [], "the sandbox scan passes a directory with no copy")
        def copy(p: Path) -> None:  # a reference under another name
            (p / "x").mkdir()
            shutil.copy(HERE / "reference/calibration/python/lru.py", p / "x" / "cache.py")

        def named(p: Path) -> None:  # an older revision's directory, content unknown
            (p / "old/eval/s7/harder").mkdir(parents=True)

        def history(p: Path) -> None:  # the tasks in a commit, gone from the checkout
            subprocess.run(git + ["init", "-q", str(p / "r")], check=True)
            shutil.copy(HERE / "calibration.py", p / "r" / "tasks.py")
            subprocess.run(git + ["-C", str(p / "r"), "add", "."], check=True)
            subprocess.run(git + ["-C", str(p / "r"), "commit", "-qm", "x"], check=True)
            (p / "r" / "tasks.py").unlink()
        planted = {"copy": copy, "named": named, "git": history}
        for what, plant in planted.items():
            p = Path(d) / what
            p.mkdir()
            plant(p)
            check(bool(tier.tier_copies((str(p),))), f"the sandbox scan finds a planted copy ({what})")


def main() -> int:
    hand_values()
    refusals()
    python_references()
    python_mutants()
    prompt_and_repair()
    if "--no-firth" not in sys.argv:
        firth_references()
        firth_mutant()
    print(f"\n{len(FAILED)} failed" if FAILED else "\nall passed")
    return 1 if FAILED else 0


if __name__ == "__main__":
    raise SystemExit(main())
