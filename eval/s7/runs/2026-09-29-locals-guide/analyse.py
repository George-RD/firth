#!/usr/bin/env python3
"""Run 11's pre-registered tests (preregistration.md, "Outcomes").

Usage, from eval/s7: python3 runs/2026-09-29-locals-guide/analyse.py [--self-test]

A sample counts when its directory has results-1.json and results-3.json and
no void.md. A task passes when every case passes. Every test is exact and
one-sided, and written out here because the container has no scipy. The
Mann-Whitney p is the exact permutation p of the rank sum with mid-ranks for
ties, counted by dynamic programming rather than by listing the 1.4 x 10^11
ways to split 40 samples.
"""
import itertools
import json
import re
import sys
from math import comb
from pathlib import Path

HERE = Path(__file__).resolve().parent
ARMS = {"A": HERE / "arm-a", "B": HERE / "arm-b"}
N_PER_ARM = 20  # preregistration.md: no test before both arms have exactly this many
# The shuffle words, and how comments and stack effects are removed before
# counting them, are run 10's (runs/2026-09-29-control/causes/behaviour.py).
SHUFFLES = re.compile(r"(?<![\w-])(dup|drop|swap|dip|over|rot|nip|tuck|pick|roll)(?![\w-])")


def shuffle_count(src):
    code = re.sub(r"\(\*.*?\*\)|\\[^\n]*", "", src, flags=re.S)  # comments
    code = re.sub(r"\(forall[^)]*\)", "", code)  # stack effects
    return len(SHUFFLES.findall(code))


def passed(results):
    tasks = json.loads(results.read_text())["tasks"].values()
    return sum(bool(t.get("cases")) and all(c["pass"] for c in t["cases"]) for t in tasks)


def shuffle_share(solutions):
    """Share of the answered tasks whose source uses a shuffle word."""
    sols = json.loads(solutions.read_text())
    return sum(shuffle_count(s) > 0 for s in sols.values()) / len(sols) if sols else 0.0


def fisher_greater(b_yes, b_n, a_yes, a_n):
    """P(arm B has >= b_yes successes) given the margins (hypergeometric)."""
    k, n = b_yes + a_yes, b_n + a_n
    return sum(comb(k, x) * comb(n - k, b_n - x)
               for x in range(b_yes, min(k, b_n) + 1)) / comb(n, b_n)


def ranks(values):
    order = sorted(range(len(values)), key=values.__getitem__)
    r = [0.0] * len(values)
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and values[order[j + 1]] == values[order[i]]:
            j += 1
        for k in range(i, j + 1):
            r[order[k]] = (i + j) / 2 + 1
        i = j + 1
    return r


def mann_whitney_greater(b, a):
    """U for B and the exact permutation p of U_B >= observed (mid-ranks).

    Mid-ranks are multiples of 1/2, so twice each rank is an integer; ways[k][s]
    counts the k-subsets of the pooled samples whose doubled ranks sum to s."""
    pooled = b + a
    r2 = [round(2 * x) for x in ranks(pooled)]
    obs2 = sum(r2[:len(b)])
    ways = [[0] * (sum(r2) + 1) for _ in range(len(b) + 1)]
    ways[0][0] = 1
    for x in r2:
        for k in range(len(b), 0, -1):
            row, prev = ways[k], ways[k - 1]
            for s in range(len(row) - 1, x - 1, -1):
                row[s] += prev[s - x]
    hits = sum(ways[len(b)][obs2:])
    u = obs2 / 2 - len(b) * (len(b) + 1) / 2
    return u, hits / comb(len(pooled), len(b))


def mann_whitney_brute(b, a):
    """The same p by listing every split; for the self-test only."""
    pooled = b + a
    r = ranks(pooled)
    obs = sum(r[:len(b)])
    splits = list(itertools.combinations(range(len(pooled)), len(b)))
    return sum(sum(r[i] for i in idx) >= obs - 1e-9 for idx in splits) / len(splits)


def samples(arm_dir):
    """An arm's sample directories in start order (the number is the start order)."""
    return sorted(arm_dir.glob("haiku-firth-*"), key=lambda p: int(p.name.rsplit("-", 1)[1]))


def counted(arm_dir, n=N_PER_ARM):
    """The first n non-void samples by start order (preregistration.md). A sample
    started later is reported, not counted, whatever it scored."""
    return [d for d in samples(arm_dir) if not (d / "void.md").is_file()][:n]


def extra(arm_dir, n=N_PER_ARM):
    return [d for d in samples(arm_dir) if not (d / "void.md").is_file()][n:]


def voided(arm_dir):
    """Void samples, with whichever rounds were scored, for the report only."""
    for d in samples(arm_dir):
        if (d / "void.md").is_file():
            yield d.name, [passed(d / f"results-{n}.json") if (d / f"results-{n}.json").is_file()
                           else None for n in (1, 2, 3)]


def ready(dirs, n=N_PER_ARM):
    """None when every arm has n counted samples, each scored in rounds 1 and 3,
    else why not. `dirs` maps arm to its counted() directories."""
    why = [f"arm {arm} has {len(ds)}" for arm, ds in sorted(dirs.items()) if len(ds) != n]
    why += [f"arm {arm} {d.name} is not scored" for arm, ds in sorted(dirs.items()) for d in ds
            if not ((d / "results-1.json").is_file() and (d / "results-3.json").is_file())]
    return None if not why else (
        f"not analysed: want {n} counted, scored samples per arm; " + "; ".join(why))


def self_test():
    rng = __import__("random").Random(11)
    for _ in range(200):
        b = [rng.randint(0, 6) for _ in range(rng.randint(1, 6))]
        a = [rng.randint(0, 6) for _ in range(rng.randint(1, 6))]
        assert abs(mann_whitney_greater(b, a)[1] - mann_whitney_brute(b, a)) < 1e-12, (b, a)
    assert mann_whitney_greater([5, 6, 7], [1, 2, 3])[1] == 1 / comb(6, 3)
    # Planted: swapping the arms must not give the same one-sided p.
    b, a = [9, 12, 7, 10, 8], [0, 3, 1, 6, 2]
    assert mann_whitney_greater(b, a)[1] < 0.05 < mann_whitney_greater(a, b)[1]
    assert abs(fisher_greater(7, 10, 2, 10) - 0.0349) < 1e-3
    assert fisher_greater(2, 10, 7, 10) > 0.5
    # Run 10's committed results give run 10's enumerated p values (analysis.txt).
    run10 = HERE.parent / "2026-09-29-control"
    if run10.is_dir():
        res = {arm: [passed(d / "results-3.json") for d in counted(run10 / c, 10)]
               for arm, c in (("A", "4c379e0"), ("B", "8ea4a1d"))}
        assert f"{mann_whitney_greater(res['B'], res['A'])[1]:.4f}" == "0.8196", res
    # Planted: 21 non-void samples and a void one in a scratch arm. The first 20
    # non-void by start order count; the 21st (started last, scored highest) and
    # the void one do not. A short or unscored arm is refused before any statistic.
    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        arm = Path(tmp)
        for i in range(1, 23):
            d = arm / f"haiku-firth-{i}"
            d.mkdir()
            ok = {"tasks": {"t": {"cases": [{"pass": i == 22}]}}}
            for r in (1, 3):
                (d / f"results-{r}.json").write_text(json.dumps(ok))
        (arm / "haiku-firth-5" / "void.md").write_text("planted")
        got = [d.name for d in counted(arm)]
        assert len(got) == 20 and "haiku-firth-5" not in got and "haiku-firth-22" not in got
        assert got[-1] == "haiku-firth-21" and [d.name for d in extra(arm)] == ["haiku-firth-22"]
        assert sum(passed(d / "results-3.json") for d in counted(arm)) == 0
        assert ready({"A": counted(arm), "B": counted(arm)}) is None
        assert ready({"A": counted(arm)[:19], "B": counted(arm)})
        (arm / "haiku-firth-9" / "results-3.json").unlink()
        assert "haiku-firth-9 is not scored" in ready({"A": counted(arm), "B": counted(arm)})
    assert shuffle_count(": f (forall ρ; ρ dup:Int^many -- ρ) \\ swap\n dup drop-all swap") == 2
    print("self-test ok")


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    dirs = {arm: counted(path) for arm, path in ARMS.items()}
    why = ready(dirs)
    if why:
        sys.exit(why)
    rows = {arm: [(d.name, passed(d / "results-1.json"), passed(d / "results-3.json"),
                   shuffle_share(d / "solutions-1.json"), shuffle_share(d / "solutions-3.json"))
                  for d in ds] for arm, ds in dirs.items()}
    for arm, rs in rows.items():
        print(f"arm {arm}: {len(rs)} counted samples")
        for name, first, final, s1, s3 in rs:
            print(f"  {name:15} first {first:2}  final {final:2}  "
                  f"shuffle share first {s1:.2f} final {s3:.2f}")
        for name, scores in voided(ARMS[arm]):
            shown = " / ".join("-" if x is None else str(x) for x in scores)
            print(f"  {name:15} VOID, not counted; passes by round {shown}")
        for d in extra(ARMS[arm]):
            print(f"  {d.name:15} started after the 20th counted sample, not counted")
    a, b = rows["A"], rows["B"]
    col = lambda rs, i: [r[i] for r in rs]  # noqa: E731
    u, p = mann_whitney_greater(col(b, 2), col(a, 2))
    print(f"\nPrimary: tasks passed after round 2, B > A: sums A {sum(col(a, 2))} "
          f"B {sum(col(b, 2))}; U_B = {u}, one-sided exact p = {p:.4f}")
    ay, by = sum(x > 0 for x in col(a, 2)), sum(x > 0 for x in col(b, 2))
    print(f"Secondary 1: samples passing >= 1 task after round 2: A {ay}/{len(a)} "
          f"B {by}/{len(b)}; one-sided Fisher p = {fisher_greater(by, len(b), ay, len(a)):.4f}")
    u, p = mann_whitney_greater(col(b, 1), col(a, 1))
    print(f"Secondary 2: tasks passed in the first answer, B > A: sums A {sum(col(a, 1))} "
          f"B {sum(col(b, 1))}; U_B = {u}, one-sided exact p = {p:.4f}")
    u, p = mann_whitney_greater(col(a, 3), col(b, 3))
    print(f"Manipulation check: share of first answers using shuffle words, A > B: mean A "
          f"{sum(col(a, 3)) / len(a):.2f} B {sum(col(b, 3)) / len(b):.2f}; U_A = {u}, "
          f"one-sided exact p = {p:.4f}")
    print(f"  (final answers, reported only: mean A {sum(col(a, 4)) / len(a):.2f} "
          f"B {sum(col(b, 4)) / len(b):.2f})")


if __name__ == "__main__":
    main()
