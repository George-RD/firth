#!/usr/bin/env python3
"""Checks for the frozen MVP-authoring task set, run before any model sees it.

1. Each task's Python `ref` agrees with expected values worked out by hand,
   written here without running the refs.
2. Every Firth reference solution in `reference/mvp/` passes its task's example
   and hidden tests on both hosts under the MVP step budget.
3. The scorer rejects wrong answers: a planted mutant of a Firth reference, a
   Python answer that returns a nested Bool where an Int is due, and a bare list
   spread into several outputs.

    python3 eval/s7/test_mvp.py            # everything (needs `lake build`)
    python3 eval/s7/test_mvp.py --no-firth # 1 and the Python parts of 3 only
"""
from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import harness  # noqa: E402
from mvp_tasks import MVP  # noqa: E402
from tasks import BY_ID  # noqa: E402

T, F = True, False

# (task id, inputs, outputs), all worked out by hand from the task descriptions.
HAND = [
    ("seq-sum", ([4, 5, 6],), (15,)),
    ("seq-sum", ([],), (0,)),
    ("seq-max", ([3, 9, 2],), (9,)),
    ("seq-max", ([-4, -2, -9],), (-2,)),
    ("count-below", ([1, 5, 2, 8], 4), (2,)),
    ("count-below", ([4, 4], 4), (0,)),
    ("index-of", ([7, 3, 9, 3], 3), (1,)),
    ("index-of", ([1, 2, 3], 4), (-1,)),
    ("reverse", ([1, 2, 3],), ([3, 2, 1],)),
    ("reverse", ([],), ([],)),
    ("prefix-sums", ([1, 2, 3],), ([1, 3, 6],)),
    ("prefix-sums", ([3, -3, 3, -3],), ([3, 0, 3, 0],)),
    ("keep-positive", ([3, -1, 0, 4],), ([3, 4],)),
    ("keep-positive", ([0, 0, 5, 0],), ([5],)),
    ("is-sorted", ([1, 2, 2, 5],), (T,)),
    ("is-sorted", ([1, 3, 2],), (F,)),
    ("is-sorted", ([],), (T,)),
    ("dot", ([1, 2, 3], [4, 5, 6]), (32,)),
    ("dot", ([1, 0, -1], [5, 5, 5]), (0,)),
    ("all-true", ([T, T, F],), (F,)),
    ("all-true", ([],), (T,)),
    ("longest-run", ([1, 1, 2, 2, 2, 1],), (3,)),
    ("longest-run", ([1, 2, 2, 1, 1, 1, 1, 3],), (4,)),
    ("longest-run", ([],), (0,)),
    ("has-pair-sum", ([1, 4, 6, 2], 8), (T,)),
    ("has-pair-sum", ([4], 8), (F,)),
    ("has-pair-sum", ([3, 1, 3], 2), (F,)),
    ("count-distinct", ([3, 1, 3, 2, 1],), (3,)),
    ("count-distinct", ([],), (0,)),
    ("merge-sorted", ([1, 4, 9], [2, 3, 10]), ([1, 2, 3, 4, 9, 10],)),
    ("merge-sorted", ([1, 1], [1]), ([1, 1, 1],)),
    ("digits", (305,), ([3, 0, 5],)),
    ("digits", (0,), ([0],)),
    ("digits", (10,), ([1, 0],)),
    ("digits", (1005,), ([1, 0, 0, 5],)),
    ("digits", (40213,), ([4, 0, 2, 1, 3],)),
    ("primes-up-to", (10,), ([2, 3, 5, 7],)),
    ("primes-up-to", (1,), ([],)),
    ("histogram", ([0, 2, 2, 1, 2], 3), ([1, 1, 3],)),
    ("histogram", ([], 2), ([0, 0],)),
    # The largest value is below k - 1, so the result is longer than max + 1.
    ("histogram", ([1, 0, 1], 4), ([1, 2, 0, 0],)),
    ("sort", ([3, 1, 2],), ([1, 2, 3],)),
    ("sort", ([9, -1, 4, -1, 0, 7, 3],), ([-1, -1, 0, 3, 4, 7, 9],)),
    # 10+5=15; 15-20<0 rejected; 15-15=0; 0+4=4.
    ("ledger", (10, [5, -20, -15, 4]), (4, 1)),
    ("ledger", (3, [-1, -1, -1, -1, -1]), (0, 2)),
    # stock [10,3]: order 0 item 0 wants 4 -> 4 (0), stock [6,3]; order 1 item 1
    # wants 5, whole, only 3 -> 0 (3); order 2 item 0 wants 7, partial, 6 left
    # -> 6 (1), stock [0,3]; order 3 item 1 wants 1 -> 1 (0), stock [0,2].
    ("allocate-batch", ([10, 3], [0, 1, 0, 1], [4, 5, 7, 1], [F, T, F, F]),
     ([0, 2], [4, 0, 6, 1], [0, 3, 1, 0])),
    # item 0 has none -> 0 (2).
    ("allocate-batch", ([0], [0], [3], [F]), ([0], [0], [2])),
]

failures: list[str] = []


def check(ok: bool, what: str) -> None:
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        failures.append(what)


def hand_values() -> None:
    covered = {tid for tid, _, _ in HAND}
    check(covered == {t.id for t in MVP}, "every MVP task has hand-worked values")
    for tid, args, want in HAND:
        got = BY_ID[tid].expected(args)
        check(harness.same(list(got), list(want)), f"{tid}{args} ref gives {want}")


def scorer_rejects_wrong_python() -> None:
    check(not harness.same([[1, 0]], [[True, False]]), "a nested Bool never equals an Int")
    check(not harness.same([[1, 2]], [[1, 2, 3]]), "nested lengths are compared")
    # `reverse` has one output, a list: returning it must not spread into several values.
    rev = harness.run_python("def main(xs):\n    return xs[::-1]\n", ([1, 2],), None, ("Seq Int",))
    check(rev == {"ok": True, "stack": [[2, 1]]}, "a single list output stays one value")
    # CodeRabbit's finding: an answer that prints while it works used to break
    # the result (stdout carried both), and with it the whole scoring run.
    loud = harness.run_python("def main(xs):\n    print('debug', xs)\n    return xs[::-1]\n",
                              ([1, 2],), None, ("Seq Int",))
    check(loud == {"ok": True, "stack": [[2, 1]]}, "an answer that prints still gives its result")
    fake = harness.run_python("import os\ndef main(xs):\n    os._exit(0)\n", ([1, 2],), None, ("Seq Int",))
    check(not fake["ok"], "an answer that exits before returning gives no result, not a crash")
    two = harness.run_python("def main(s, t):\n    return (s, 0)\n", (1, []), None, ("Int", "Int"))
    check(two == {"ok": True, "stack": [1, 0]}, "a tuple of two outputs gives two values")
    # A tuple where a list is due, or a Bool where an Int is due, fails even
    # though JSON would make it look right.
    # Several outputs come as a tuple, as the prompt asks; a list of the same
    # length is a different return type and fails (Codex's finding).
    pair = harness.run_python("def main(s, t):\n    return [s, 0]\n", (1, []), None, ("Int", "Int"))
    check(not pair["ok"], "a list returned for several outputs fails")
    tup = harness.run_python("def main(xs):\n    return tuple(xs[::-1])\n", ([1, 2],), None,
                             ("Seq Int",))
    check(not tup["ok"], "a tuple returned for a Seq Int output fails")
    flag = harness.run_python("def main(xs):\n    return [x > 0 for x in xs]\n", ([1, 2],), None,
                              ("Seq Int",))
    check(not flag["ok"], "Bools returned inside a Seq Int output fail")
    # A reviewer's wrong answer that the first hidden set let through: it sizes
    # the histogram by the largest value instead of by k.
    hist = harness.score({"histogram": "def main(xs, k):\n    return [xs.count(v) for v in "
                          "range(max(xs) + 1)] if xs else [0] * k\n"}, "python",
                         [BY_ID["histogram"]], 1)
    check(not hist["tasks"]["histogram"]["pass"], "the scorer fails a histogram sized by max(xs)")
    # Another that got through: it keeps at most three digits.
    three = harness.score({"digits": "def main(n):\n    return [int(c) for c in str(n)[:3]]\n"},
                          "python", [BY_ID["digits"]], 1)
    check(not three["tasks"]["digits"]["pass"], "the scorer fails digits truncated to three")
    res = harness.score({"reverse": "def main(xs):\n    return list(xs)\n"}, "python",
                        [BY_ID["reverse"]], 1)
    check(not res["tasks"]["reverse"]["pass"], "the scorer fails a wrong Python answer")


def firth_references() -> None:
    sols = harness.load_solutions(HERE / "reference/mvp", HERE)
    check(set(sols) == {t.id for t in MVP}, "there is one Firth reference per MVP task")
    res = harness.score(sols, "firth", list(MVP), 8)
    for tid, r in res["tasks"].items():
        bad = [c for c in r["cases"] if not c["pass"]]
        check(r["pass"] and not bad,
              f"{tid} reference passes {r['hidden_passed']}/{r['hidden_total']} hidden"
              + (f" (first failure {bad[0]})" if bad else ""))
    # Planted mutant: flip insertion sort's comparison, so each element goes
    # before the first smaller one and the result comes out descending.
    src = sols["sort"].replace("[ x s i prim seq-int.at prim <", "[ s i prim seq-int.at x prim <")
    check(src != sols["sort"], "the sort mutant changes the source")
    res = harness.score({"sort": src}, "firth", [BY_ID["sort"]], 4)
    check(not res["tasks"]["sort"]["pass"], "the scorer fails a mutated Firth sort")
    # The step budget is really raised: this loop needs more than the default.
    loop = (": count-down (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n"
            "  locals { n } { n 0 prim = [ 0 ] [ n 1 prim - count-down ] if };\n"
            ": main (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many) drop 20000 count-down;\n")
    small = harness.run_firth(loop, ([],))
    big = harness.run_firth(loop, ([],), harness.MVP_FUEL)
    check(not small["ok"] and big == {"ok": True, "stack": [0]},
          "MVP tasks run past the default step budget")


def unsandboxed_python_refused() -> None:
    real = harness.os.geteuid
    try:
        harness.os.geteuid = lambda: 1000
        try:
            harness.require_sandbox("python", [BY_ID["sort"]])
            refused = False
        except SystemExit:
            refused = True
        check(refused, "a non-root Python score of MVP tasks is refused")
        harness.require_sandbox("firth", [BY_ID["sort"]])
        harness.require_sandbox("python", [BY_ID["fib"]])
        check(True, "Firth, and Python outside the MVP tier, are not refused")
    finally:
        harness.os.geteuid = real


def hashes_recorded() -> None:
    h = harness.eval_hashes()
    check(set(h) == {"task.py", "tasks.py", "mvp_tasks.py", "harness.py", "isolate.py"}
          and all(len(v) == 64 for v in h.values()), "results can record the eval sources' SHA-256")


def main() -> int:
    hand_values()
    scorer_rejects_wrong_python()
    hashes_recorded()
    unsandboxed_python_refused()
    if "--no-firth" not in sys.argv:
        firth_references()
    print(f"\n{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
