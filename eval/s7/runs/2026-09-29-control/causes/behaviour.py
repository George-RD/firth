#!/usr/bin/env python3
"""Does anything an author did predict passing? Exploratory, run 10's 20 counted samples.

Usage, from eval/s7: python3 runs/2026-09-29-control/causes/behaviour.py [--self-test]

Per sample, from `transcript.json` and the first answers (`solutions-1.json`),
so the measures come before any feedback:

- reread: the author read the prompt again after its first whole Read;
- minutes: time from the first tool call to the first answer's Write;
- chars: the first answer's size;
- locals: share of the first answer's words whose body opens a `locals` block;
- shuffles: kernel shuffle words (dup, drop, swap, dip, over, rot, nip, tuck,
  pick, roll) per task in the first answer;
- words: definitions per task in the first answer.

Each is set against the sample's final passes (`results-3.json`) with a
Spearman rank correlation and a two-sided permutation p (20,000 fixed-seed
shuffles). With 20 samples and six measures, nothing here is more than a
lead; no correction for multiple tests is applied.

Then, per answer: the final pass rate of answers with and without shuffle
words, for final answers and for first answers (whose use of shuffle words
comes before any feedback), pooled and within each task and each sample (a
task or sample where every answer passed, every answer failed, or every
answer used the same style says nothing and is left out).

Reading feedback does not vary: every author read each `repair-N.md` whole
(all are under the Read tool's 2,000 line default) before writing again.
"""
import json
import random
import re
import sys
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from causes import counted, passed  # noqa: E402

SHUFFLES = re.compile(r"(?<![\w-])(dup|drop|swap|dip|over|rot|nip|tuck|pick|roll)(?![\w-])")
DEF = re.compile(r"^:\s+\S+", re.M)


def ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def words(src):
    """The bodies of a source's definitions."""
    starts = [m.start() for m in DEF.finditer(src)]
    return [src[a:b] for a, b in zip(starts, starts[1:] + [len(src)])]


def uses_locals(body):
    return bool(re.search(r"(?<![\w-])locals\s*\{", body))


def shuffle_count(src):
    code = re.sub(r"\(\*.*?\*\)|\\[^\n]*", "", src, flags=re.S)  # comments
    code = re.sub(r"\(forall[^)]*\)", "", code)  # stack effects
    return len(SHUFFLES.findall(code))


def features(d):
    t = json.loads((d / "transcript.json").read_text())["tool_calls"]
    first_write = next(c for c in t if c["tool"] == "Write")
    before = [c for c in t[:t.index(first_write)] if c["tool"] == "Read"]
    sols = json.loads((d / "solutions-1.json").read_text())
    bodies = [w for src in sols.values() for w in words(src)]
    return {
        "reread": int(len(before) > 1),
        "minutes": (ts(first_write["at"]) - ts(t[0]["at"])).total_seconds() / 60,
        "chars": first_write["content_chars"],
        "locals": sum(map(uses_locals, bodies)) / len(bodies),
        "shuffles": sum(shuffle_count(s) for s in sols.values()) / len(sols),
        "words": len(bodies) / len(sols),
    }


def ranks(xs):
    order = sorted(range(len(xs)), key=lambda i: xs[i])
    r = [0.0] * len(xs)
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and xs[order[j + 1]] == xs[order[i]]:
            j += 1
        for k in range(i, j + 1):
            r[order[k]] = (i + j) / 2 + 1
        i = j + 1
    return r


def pearson(a, b):
    n = len(a)
    ma, mb = sum(a) / n, sum(b) / n
    cov = sum((x - ma) * (y - mb) for x, y in zip(a, b))
    va = sum((x - ma) ** 2 for x in a) ** 0.5
    vb = sum((y - mb) ** 2 for y in b) ** 0.5
    return cov / (va * vb) if va and vb else 0.0


def spearman(a, b, perms=20000, seed=20260929):
    ra, rb = ranks(a), ranks(b)
    rho = pearson(ra, rb)
    rng = random.Random(seed)
    rb2 = list(rb)
    hits = 0
    for _ in range(perms):
        rng.shuffle(rb2)
        hits += abs(pearson(ra, rb2)) >= abs(rho) - 1e-12
    return rho, (hits + 1) / (perms + 1)


def report():
    samples = []
    for arm, d in counted():
        res = json.loads((d / "results-3.json").read_text())["tasks"]
        res1 = json.loads((d / "results-1.json").read_text())["tasks"]
        samples.append({"sample": f"{arm}{d.name.rsplit('-', 1)[1]}", **features(d),
                        "final": sum(map(passed, res.values())),
                        "first": sum(map(passed, res1.values()))})
    cols = ["reread", "minutes", "chars", "locals", "shuffles", "words"]
    print("== Per sample (first-answer measures; passes of 20)")
    print("  sample " + " ".join(f"{c:>8s}" for c in cols) + "   first  final")
    for s in samples:
        print(f"  {s['sample']:6s} " + " ".join(f"{s[c]:8.2f}" for c in cols)
              + f"   {s['first']:5d}  {s['final']:5d}")
    print("\n== Spearman with final passes (n = 20, permutation p, exploratory)")
    final = [s["final"] for s in samples]
    for c in cols:
        rho, p = spearman([s[c] for s in samples], final)
        print(f"  {c:9s} rho {rho:+.2f}  p {p:.3f}")

    for label, rnd in (("final answers", 3), ("first answers, scored by the task's final result", 1)):
        rows = []
        for arm, d in counted():
            sols = json.loads((d / f"solutions-{rnd}.json").read_text())
            res = json.loads((d / "results-3.json").read_text())["tasks"]
            rows += [(task, d.name + arm, shuffle_count(src) > 0, passed(res[task]))
                     for task, src in sols.items()]
        print(f"\n== {label.capitalize()}: final pass rate with and without shuffle words")
        for flag, name in ((False, "no shuffle words"), (True, "shuffle words")):
            rs = [r for r in rows if r[2] == flag]
            print(f"  {name:17s} {sum(r[3] for r in rs):3d} of {len(rs):3d} pass "
                  f"({100 * sum(r[3] for r in rs) / len(rs):.0f}%)")
        for key, what in ((0, "tasks"), (1, "samples")):
            print(f"  within {what} that vary: no-shuffle rate higher in "
                  "{0}, lower in {1}, equal in {2}".format(*strata(rows, key)))


def strata(rows, key):
    """Within each task (or sample) with both kinds of answer and both outcomes,
    whether answers without shuffle words passed more often."""
    better = worse = same = 0
    for k in sorted({r[key] for r in rows}):
        rs = [r for r in rows if r[key] == k]
        if len({r[3] for r in rs}) < 2 or len({r[2] for r in rs}) < 2:
            continue
        a = [r[3] for r in rs if not r[2]]
        b = [r[3] for r in rs if r[2]]
        ra, rb = sum(a) / len(a), sum(b) / len(b)
        better += ra > rb
        worse += ra < rb
        same += ra == rb
    return better, worse, same


def self_test():
    src = ": a (forall ρ; ρ x:Int -- ρ x:Int x:Int) dup ;\n: b (forall ρ; ρ -- ρ) locals { } { } ;\n"
    assert len(words(src)) == 2 and uses_locals(words(src)[1]) and not uses_locals(words(src)[0])
    assert shuffle_count(src) == 1
    assert shuffle_count("(* dup swap *) \\ drop\n dup-all swap") == 1
    assert ranks([3, 1, 3]) == [2.5, 1.0, 2.5]
    rho, p = spearman(list(range(20)), list(range(20)), perms=2000)
    assert rho == 1.0 and p < 0.01, (rho, p)
    rho, p = spearman(list(range(20)), [1] * 10 + [0] * 10, perms=2000)
    assert rho < -0.8, rho
    print("self-test ok")


if __name__ == "__main__":
    self_test() if "--self-test" in sys.argv else report()
