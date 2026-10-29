#!/usr/bin/env python3
"""The calibration's selection, as `calibration.md` "Selection rule (fixed
now)" and "Stop rule after calibration (fixed now)" define it. It reads only
the kept authors' score files in a calibration run directory:

- `<run>/NAME/results-1.json` (round 1) and, when a second round ran,
  `<run>/NAME/results-2.json`, as `tier.py score` writes them. Round 2 scores
  every answer again (earlier answers carry over), so an author's final
  answer to a task is `results-2.json`'s when that file exists, else
  `results-1.json`'s. A task passes when its `pass` is true.

    python3 calibration_selection.py RUN --authors cal-python-1,cal-firth-1,... > selection.md
    python3 calibration_selection.py --self-test

`--authors` names the kept authors (the six, replacements for voids included,
voids left out): three per arm, `cal-python-N` and `cal-firth-N`. The script
stops on any other count, on a missing score file, and on a task the file
lacks. Candidate order is `candidates.py`'s (`tier.SETS["candidates"]`).

For each candidate, `pass(t)` counts the authors whose final answer passed
and `first(t)` those whose round 1 passed, summed over both arms. A candidate
with `pass(t)` = 0 is dropped; the rest rank by `pass(t)`, then `first(t)`,
lowest first, then candidate order; the first six, in candidate order, are the
selected set. Fewer than six remaining: no scored run. The scored run is also
not started when the Python authors' mean of selected tasks passed is 5.5 or
more of 6.

Standard library only. The self-test checks a hand-worked example and rejects
planted bugs in each rule (a rank by Python alone, no floor, no tie-breaks,
the round-1 count used as final, a stop rule at 5.5 exclusive).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

CEILING = 5.5
PICK = 6
PER_ARM = 3


def arm(name: str) -> str:
    for lang in ("python", "firth"):
        if name.startswith(f"cal-{lang}-"):
            return lang
    raise SystemExit(f"{name}: not a cal-python-N or cal-firth-N author")


def final(first: dict[str, bool], second: dict[str, bool] | None) -> dict[str, bool]:
    return first if second is None else second


def counts(authors: dict[str, tuple[dict[str, bool], dict[str, bool]]], order: list[str]) -> dict:
    """`authors` maps a name to (round-1 pass per task, final pass per task)."""
    out = {t: {"pass": 0, "first": 0, "python": 0, "firth": 0, "python_first": 0, "firth_first": 0}
           for t in order}
    for name, (r1, fin) in authors.items():
        lang = arm(name)
        for t in order:
            out[t]["pass"] += fin[t]
            out[t]["first"] += r1[t]
            out[t][lang] += fin[t]
            out[t][f"{lang}_first"] += r1[t]
    return out


def rank(c: dict, order: list[str]) -> list[str]:
    """Drop the floor, then lowest `pass`, lowest `first`, candidate order."""
    kept = [t for t in order if c[t]["pass"] > 0]
    return sorted(kept, key=lambda t: (c[t]["pass"], c[t]["first"], order.index(t)))


def select(c: dict, order: list[str]) -> list[str]:
    top = rank(c, order)[:PICK]
    return [t for t in order if t in top] if len(top) == PICK else []


def python_mean(authors: dict, picked: list[str]) -> float:
    py = [fin for name, (_, fin) in authors.items() if arm(name) == "python"]
    return sum(sum(fin[t] for t in picked) for fin in py) / len(py)


def verdict(authors: dict, order: list[str]) -> dict:
    c = counts(authors, order)
    ranked = rank(c, order)
    picked = select(c, order)
    res = {"counts": c, "dropped": [t for t in order if c[t]["pass"] == 0],
           "ranking": ranked, "selected": picked, "python_mean": None, "run": False}
    if not picked:
        res["outcome"] = (f"stop: {len(ranked)} candidates remain after the floor, fewer than {PICK}; "
                          "there is no scored run from this pool")
        return res
    res["python_mean"] = python_mean(authors, picked)
    if res["python_mean"] >= CEILING:
        res["outcome"] = (f"stop: the Python authors pass a mean of {res['python_mean']:.2f} of {PICK} "
                          f"selected tasks, {CEILING} or more; these candidates do not take Sonnet's "
                          "Python arm off the ceiling")
    else:
        res["run"] = True
        res["outcome"] = (f"go: the Python authors pass a mean of {res['python_mean']:.2f} of {PICK} "
                          f"selected tasks, below {CEILING}")
    return res


def render(authors: dict, order: list[str], res: dict) -> str:
    c = res["counts"]
    names = sorted(authors)
    out = ["# Calibration selection", "",
           "Computed by `calibration_selection.py` from the kept authors' score files: "
           + ", ".join(f"`{n}`" for n in names) + ".", "",
           "| candidate | pass python | pass firth | pass (sum) | first (sum) | dropped | selected |",
           "|---|---|---|---|---|---|---|"]
    for t in order:
        out.append(f"| {t} | {c[t]['python']}/{PER_ARM} | {c[t]['firth']}/{PER_ARM} | {c[t]['pass']} | "
                   f"{c[t]['first']} | {'yes' if c[t]['pass'] == 0 else ''} | "
                   f"{'yes' if t in res['selected'] else ''} |")
    out += ["", "Ranking after the floor (lowest first): " + ", ".join(res["ranking"]) + ".",
            "", "Selected, in `candidates.py` order: " + (", ".join(res["selected"]) or "none") + ".", ""]
    if res["python_mean"] is not None:
        out.append(f"Python authors' selected tasks passed within two rounds: {res['python_mean']:.2f} of {PICK} (mean).")
    out += ["", f"Outcome: {res['outcome']}.", ""]
    return "\n".join(out)


def load(run: Path, names: list[str], order: list[str]) -> dict:
    langs = [arm(n) for n in names]
    for lang in ("python", "firth"):
        if langs.count(lang) != PER_ARM:
            raise SystemExit(f"{lang}: {langs.count(lang)} kept authors, need {PER_ARM}")
    if len(set(names)) != len(names):
        raise SystemExit("an author is named twice")
    authors = {}
    for n in names:
        rounds = []
        for k in (1, 2):
            p = run / n / f"results-{k}.json"
            if p.exists():
                res = json.loads(p.read_text())
                if set(res["tasks"]) != set(order):
                    raise SystemExit(f"{p}: tasks differ from the candidate set")
                rounds.append({t: bool(res["tasks"][t]["pass"]) for t in order})
            elif k == 1:
                raise SystemExit(f"{p}: missing")
        authors[n] = (rounds[0], final(rounds[0], rounds[1] if len(rounds) > 1 else None))
    return authors


def self_test() -> None:
    order = [f"t{i}" for i in range(1, 10)]

    def author(name, r1, fin=None):
        f1 = {t: t in r1 for t in order}
        ff = f1 if fin is None else {t: t in fin for t in order}
        return name, (f1, ff)

    # Hand-worked. Python authors pass (final): t1..t9 minus the lists below; Firth likewise.
    authors = dict([
        author("cal-python-1", ["t1", "t2", "t3", "t4", "t5", "t6"], ["t1", "t2", "t3", "t4", "t5", "t6", "t7"]),
        author("cal-python-2", ["t1", "t2", "t3", "t4"], ["t1", "t2", "t3", "t4", "t5"]),
        author("cal-python-3", ["t1", "t2", "t3"], ["t1", "t2", "t3", "t5"]),
        author("cal-firth-1", ["t1", "t2"], ["t1", "t2", "t3"]),
        author("cal-firth-2", ["t1"], ["t1", "t2"]),
        author("cal-firth-3", ["t1", "t2"], ["t1", "t2", "t4"]),
    ])
    c = counts(authors, order)
    # Final passes: t1 6, t2 6, t3 4 (python 1-3, firth-1), t4 3 (python 1, 2, firth-3),
    # t5 3 (python 1-3), t6 1, t7 1, t8 0, t9 0. Round-1 passes ("first") are below.
    want_pass = dict(t1=6, t2=6, t3=4, t4=3, t5=3, t6=1, t7=1, t8=0, t9=0)
    assert {t: c[t]["pass"] for t in order} == want_pass, {t: c[t]["pass"] for t in order}
    assert {t: c[t]["first"] for t in order} == dict(t1=6, t2=5, t3=3, t4=2, t5=1, t6=1, t7=0, t8=0, t9=0)
    # t8 and t9 dropped. Rank: t7 (1,0), t6 (1,1), t5 (3,1), t4 (3,2), t3 (4,3), t2 (6,5), t1 (6,6).
    assert rank(c, order) == ["t7", "t6", "t5", "t4", "t3", "t2", "t1"]
    assert select(c, order) == ["t2", "t3", "t4", "t5", "t6", "t7"]
    v = verdict(authors, order)
    # Python authors' final passes on t2..t7: python-1 6 (t2..t7), python-2 4 (t2 t3 t4 t5), python-3 3 (t2 t3 t5).
    assert abs(v["python_mean"] - (6 + 4 + 3) / 3) < 1e-9 and v["run"] and v["outcome"].startswith("go")
    assert v["dropped"] == ["t8", "t9"]
    text = render(authors, order, v)
    assert "Selected, in `candidates.py` order: t2, t3, t4, t5, t6, t7." in text and "go:" in text

    # Fewer than six remain after the floor: no scored run.
    few = dict([author(f"cal-{l}-{i}", ["t1", "t2"]) for l in ("python", "firth") for i in (1, 2, 3)])
    fv = verdict(few, order)
    assert fv["selected"] == [] and not fv["run"] and fv["outcome"].startswith("stop: 2 candidates remain")

    # Stop rule. Firth passes only t1; Python authors pass the first n tasks. With three
    # authors a mean is a multiple of 1/3, so 5.5 itself is out of reach: 5 2/3 stops, 5 1/3 goes.
    def three(py_each):
        a = dict([author(f"cal-python-{i}", order[:n]) for i, n in enumerate(py_each, 1)])
        a.update([author(f"cal-firth-{i}", ["t1"]) for i in (1, 2, 3)])
        return a
    stop = verdict(three([6, 6, 5]), order)
    assert stop["selected"] == ["t1", "t2", "t3", "t4", "t5", "t6"]
    assert stop["python_mean"] == 17 / 3 and not stop["run"] and stop["outcome"].startswith("stop: the Python")
    go = verdict(three([6, 5, 5]), order)
    assert go["python_mean"] == 16 / 3 and go["run"]

    # Round 2 supersedes round 1, and its absence leaves round 1.
    assert final({"a": False}, {"a": True}) == {"a": True} and final({"a": False}, None) == {"a": False}

    # Planted bugs: each must change the verdict on the example.
    def rank_python_only(c, order):
        kept = [t for t in order if c[t]["python"] > 0]
        return sorted(kept, key=lambda t: (c[t]["python"], c[t]["python_first"], order.index(t)))
    assert rank_python_only(c, order)[:6] != rank(c, order)[:6]
    def rank_no_floor(c, order):
        return sorted(order, key=lambda t: (c[t]["pass"], c[t]["first"], order.index(t)))
    assert rank_no_floor(c, order)[:6] != rank(c, order)[:6]
    def rank_no_ties(c, order):
        kept = [t for t in order if c[t]["pass"] > 0]
        return sorted(kept, key=lambda t: (c[t]["pass"], order.index(t)))
    assert rank_no_ties(c, order)[:6] != rank(c, order)[:6]
    def rank_no_order(c, order):
        kept = [t for t in order if c[t]["pass"] > 0]
        return sorted(kept, key=lambda t: (c[t]["pass"], c[t]["first"], -order.index(t)))
    tie = dict([author(f"cal-{l}-{i}", ["t1", "t2", "t3", "t4", "t5", "t6", "t7"]) for l in ("python", "firth") for i in (1, 2, 3)])
    assert rank_no_order(counts(tie, order), order) != rank(counts(tie, order), order)
    c_first = counts({n: (f1, f1) for n, (f1, ff) in authors.items()}, order)  # round 1 used as final
    assert {t: c_first[t]["pass"] for t in order} != {t: c[t]["pass"] for t in order}
    # A loader that skips the six-author count, or reads a task set that differs, stops.
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        run = Path(d)
        for n, (r1, fin) in authors.items():
            (run / n).mkdir()
            (run / n / "results-1.json").write_text(json.dumps({"tasks": {t: {"pass": r1[t]} for t in order}}))
            if fin != r1:
                (run / n / "results-2.json").write_text(json.dumps({"tasks": {t: {"pass": fin[t]} for t in order}}))
        assert load(run, sorted(authors), order) == authors
        for bad in (sorted(authors)[:5], sorted(authors) + ["cal-firth-4"], ["cal-python-1"] * 6):
            try:
                load(run, bad, order)
            except SystemExit:
                continue
            raise AssertionError(f"load accepted {bad}")
        (run / "cal-firth-1" / "results-1.json").write_text(json.dumps({"tasks": {"t1": {"pass": True}}}))
        try:
            load(run, sorted(authors), order)
        except SystemExit:
            pass
        else:
            raise AssertionError("load accepted a different task set")
    print("calibration_selection.py self-test: ok")


def main(argv: list[str]) -> int:
    if argv == ["--self-test"]:
        self_test()
        return 0
    if len(argv) != 3 or argv[1] != "--authors":
        print(__doc__)
        return 2
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import tier
    order = [t.id for t in tier.SETS["candidates"]]
    authors = load(Path(argv[0]), argv[2].split(","), order)
    print(render(authors, order, verdict(authors, order)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
