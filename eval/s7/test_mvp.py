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

import json
import os
import re
import subprocess
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


def rounds_prompt() -> None:
    # A sub-agent author has no `try`: its prompt must not offer one, and it
    # still gets the MVP documents and every MVP task.
    for lang in ("firth", "python"):
        text = harness.prompt(list(MVP), lang, rounds=2)
        check("try --lang" not in text and "at most 2 such rounds" in text
              and all(f"## {t.id}\n" in text for t in MVP), f"the {lang} --rounds prompt offers feedback, not try")
    firth = harness.prompt(list(MVP), "firth", rounds=2)
    check(all(f'<document path="{d}">' in firth for d in harness.MVP_DOCS),
          "the --rounds prompt carries the MVP documents")
    check("try --lang" in harness.prompt(list(MVP), "firth", mvp=True), "the mvp prompt still offers try")
    try:
        harness.prompt([BY_ID["fib"]], "firth", rounds=2)
        outside = False
    except ValueError:
        outside = True
    check(outside, "feedback rounds are refused outside the MVP tier, whose step budget they promise")


def feedback_keeps_hints() -> None:
    # The runner's error ends in the repr of the diagnostics, and Python puts a
    # string holding an apostrophe in double quotes. The authors' feedback must
    # still carry that hint (in run 5 it was dropped, so none saw it).
    diag = [{"body": {"code": "firth.name.unresolved",
                      "message_params": {"hint": "`xs` is a name in the word's stack effect.",
                                         "message": "`xs` is not a defined word, primitive or local."},
                      "cause": {"kind": "validation", "data": {"actual": "xs"}}}}]
    raw = json.dumps({"error": f"application elaborate: status 'failure', expected 'success': {diag!r}",
                      "status": "error"})
    got = harness.compact(raw)
    check("hint: `xs` is a name in the word's stack effect." in got
          and "message: `xs` is not a defined word" in got and "actual: xs" in got,
          "feedback keeps a hint that holds an apostrophe")


def feedback_shows_location() -> None:
    # The checker says where in the program it failed; the feedback must show
    # that line and column, or an author cannot tell which `if` a branch
    # mismatch means (run 7's `sort` edited the wrong word). The `if` below is
    # on line 5, from column 21.
    source = (": main\n"
              "  (forall ρ; ρ xs:Seq Int^many -- ρ out:Seq Int^many)\n"
              "  locals { xs } {\n"
              "    xs prim seq-int.len 0 prim <\n"
              "    [ xs 1 ] [ xs ] if\n"
              "  };\n")
    real = harness.compact
    harness.compact = lambda text: text  # keep the runner's raw output
    try:
        raw = harness.run_firth(source, ([1, 2],), harness.MVP_FUEL).get("error", "")
    finally:
        harness.compact = real
    got = harness.compact(raw)
    check("code: firth.type.branch-mismatch\nword: main\nat: line 5, column 21\n" in got,
          f"feedback names the line and column of the mismatched `if`: {got[:200]!r}")
    # Planted: the same checker output without its location shows none, so the
    # check above depends on the location reaching the text.
    stripped = re.sub(r"'location': \{'path': '[^']*', 'range': \{'start': \{[^}]*\}, "
                      r"'end': \{[^}]*\}\}\}, ", "", raw)
    check(stripped != raw and "at: line" not in harness.compact(stripped),
          "without the location the feedback shows none (the planted case)")


def feedback_shows_every_error() -> None:
    # The checker reports the first error in each word it refuses. The feedback
    # must show each of them with its word and place, so an author can fix both
    # words at once: `main` uses its input name without `locals` (line 3), and
    # `twice` adds a Bool (line 6).
    source = (": main\n"
              "  (forall ρ; ρ n:Int^many -- ρ out:Int^many)\n"
              "  n twice;\n"
              ": twice\n"
              "  (forall ρ; ρ n:Int^many -- ρ out:Int^many)\n"
              "  true prim +;\n")
    real = harness.compact
    harness.compact = lambda text: text  # keep the runner's raw output
    try:
        raw = harness.run_firth(source, (2,), harness.MVP_FUEL).get("error", "")
    finally:
        harness.compact = real
    got = harness.compact(raw)
    first = got.find("error 1 of 2\ncode: firth.name.unresolved\nword: main\nat: line 3, column 3\n")
    second = got.find("error 2 of 2\ncode: firth.type.primitive-input-mismatch\nword: twice\nat: line 6, column 8\n")
    check(got.startswith("The checker found 2 errors") and 0 < first < second,
          f"feedback shows both words' errors, in source order: {got[:300]!r}")
    # Planted: feedback that reads only the first diagnostic, as before, loses
    # the second word's error.
    real_list = harness._diagnostics
    harness._diagnostics = lambda error: real_list(error)[:1]
    try:
        planted = harness.compact(raw)
    finally:
        harness._diagnostics = real_list
    check("twice" not in planted and "error 2 of 2" not in planted,
          "feedback that reads only the first diagnostic misses `twice` (the planted case)")


def subagent_audit() -> None:
    # The audit is what stands in for a sandbox around a sub-agent author, so
    # it must flag a planted read of the hidden tests, a shell call and an
    # answer file changed after the author wrote it.
    import tempfile
    from audit_subagent import audit
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        prompt, ans = d / "prompt-firth.md", d / "answer-1.md"
        prompt.write_text("p")
        ans.write_text("### task: sort\n")
        (d / "solutions-1.json").write_text(json.dumps(harness.extract(ans.read_text())))

        def call(name, **inp):
            return {"type": "assistant", "timestamp": "t",
                    "message": {"model": "m", "content": [{"type": "tool_use", "name": name, "input": inp}]}}
        ok = [call("Read", file_path=str(prompt)), call("Write", file_path=str(ans), content=ans.read_text()),
              call("Read", file_path=str(d / "repair-1.md"))]
        check(audit(ok, prompt, d, d, 2, "firth")[1] == [], "the audit passes a prompt read, an answer write and feedback")
        # A read in chunks is allowed, and the kept log must say which part
        # of the file each read asked for (reviewer, on #169). Planted: a
        # partial read of the prompt, whose offset and limit must survive.
        part = audit(ok + [call("Read", file_path=str(prompt), offset=200, limit=100)], prompt, d, d, 2, "firth")
        check(part[1] == [] and part[0]["tool_calls"][-1] == {"at": "t", "tool": "Read", "path": prompt.name,
                                                              "offset": 200, "limit": 100},
              f"the audit keeps a partial read's offset and limit: {part[0]['tool_calls'][-1]}")
        check("offset" not in audit(ok, prompt, d, d, 2, "firth")[0]["tool_calls"][0],
              "the audit adds no offset to a whole-file read")
        inherited = {"type": "user", "timestamp": "2026-01-01T00:00:00Z", "message": {"content": "context"}}
        timed = [dict(e, timestamp=f"2026-01-01T01:00:0{i}Z") for i, e in enumerate(ok)]
        log = audit([inherited, *timed], prompt, d, d, 2, "firth")[0]
        check((log["started"], log["finished"]) == ("2026-01-01T01:00:00Z", "2026-01-01T01:00:02Z"),
              f"the audit times the author's own turns, not inherited context: {log['started']} {log['finished']}")
        for what, ev in (("a read of the hidden tests", call("Read", file_path=str(HERE / "mvp_tasks.py"))),
                         ("a shell call", call("Bash", command="cat eval/s7/reference/mvp/sort.firth")),
                         ("a write outside the author's files", call("Write", file_path=str(HERE / "x.py"), content="")),
                         ("a read of another directory's feedback", call("Read", file_path="/elsewhere/repair-1.md"))):
            check(len(audit(ok + [ev], prompt, d, d, 2, "firth")[1]) == 1, f"the audit flags {what}")
        sol = d / "solutions-1.json"
        sol.write_text(json.dumps(harness.extract(ans.read_text())))
        check(audit(ok, prompt, d, d, 2, "firth")[1] == [], "the audit passes solutions that are the answer as written")
        sol.write_text(json.dumps({**harness.extract(ans.read_text()), "sort": "changed after the answer"}))
        check(len(audit(ok, prompt, d, d, 2, "firth")[1]) == 1, "the audit flags scored solutions that differ from the answer")
        sol.unlink()
        check(len(audit(ok, prompt, d, d, 2, "firth")[1]) == 1, "the audit flags an answer round with no scored solutions kept")
        sol.write_text(json.dumps(harness.extract(ans.read_text())))
        ans.write_text("### task: sort\nchanged\n")
        sol.write_text(json.dumps(harness.extract(ans.read_text())))
        check(len(audit(ok, prompt, d, d, 2, "firth")[1]) == 1, "the audit flags an answer changed after it was written")
        ans.write_text("### task: sort\n")
        sol.write_text(json.dumps(harness.extract(ans.read_text())))
        # Codex's case: a third repair under --rounds 2 would score more
        # feedback than the prompt allowed. Planted: the reads, the write and
        # the kept files of that round.
        extra = [call("Read", file_path=str(d / "repair-3.md")), call("Write", file_path=str(d / "answer-4.md"), content="x")]
        check(audit(ok + [call("Read", file_path=str(d / "repair-2.md"))], prompt, d, d, 2, "firth")[1] == [],
              "the audit passes feedback up to the round limit")
        check(len(audit(ok + extra, prompt, d, d, 2, "firth")[1]) == 2, "the audit flags a read and a write past the round limit")
        (d / "repair-3.md").write_text("r")
        (d / "repair-3.md").unlink()
        # Codex's case: feedback is allowed by its name only if it is what the
        # round's results give. Planted: a repair file edited to show more.
        (d / "results-1.json").write_text(json.dumps({"tasks": {"sort": {"submitted": True, "cases": [
            {"visible": True, "pass": False, "ok": True, "stack": [[2, 1]], "expected": [[1, 2]]}]}}}))
        (d / "repair-1.md").write_text(harness.repair(harness.extract(ans.read_text()),
                                                      json.loads((d / "results-1.json").read_text()),
                                                      "firth", harness.select("mvp")))
        check(audit(ok, prompt, d, d, 2, "firth")[1] == [], "the audit passes feedback that its round's results give")
        (d / "repair-1.md").write_text((d / "repair-1.md").read_text() + "\nhidden case: [[3, 1, 2]] -> [[1, 2, 3]]\n")
        check(len(audit(ok, prompt, d, d, 2, "firth")[1]) == 1, "the audit flags feedback edited to show more than its results")
        (d / "repair-3.md").write_text("r")
        check(any("past" in b or "beyond" in b for b in audit(ok, prompt, d, d, 2, "firth")[1]),
              "the audit flags a kept feedback file past the round limit")
        (d / "repair-3.md").unlink()
        # Codex's case (#152): a numbering gap ended the walk, so round 2's
        # files went unchecked when round 1's were not kept. Planted: answer-2
        # with differing solutions-2, and a made-up repair-2, with no round 1.
        from audit_subagent import repair_mismatch as repairs, solutions_mismatch as solutions
        gap = d / "gap"
        gap.mkdir()
        (gap / "answer-2.md").write_text("### task: sort\n")
        (gap / "solutions-2.json").write_text(json.dumps({"sort": "not what was written"}))
        check(any("answer-1.md" in b for b in solutions(gap)),
              "the audit flags answers kept after a missing round")
        check(any("solutions-2.json" in b for b in solutions(gap)),
              "after a missing round, the next round's mismatch is still listed")
        # A later round that is the kept round's solutions plus its own answer
        # is not a mismatch (Codex, on #154). Planted: without carrying the
        # kept solutions over the gap, round 2 is flagged.
        carry = d / "carry"
        carry.mkdir()
        (carry / "solutions-1.json").write_text(json.dumps({"reverse": "kept"}))
        (carry / "answer-2.md").write_text("### task: sort\n")
        (carry / "solutions-2.json").write_text(json.dumps({"reverse": "kept", **harness.extract("### task: sort\n")}))
        check(solutions(carry) == [f"{carry / 'answer-1.md'}: missing (Codex, on #152)"],
              "across a missing answer, the kept solutions carry to the next round")
        (gap / "repair-2.md").write_text("hidden case: [[3, 1, 2]] -> [[1, 2, 3]]\n")
        check(any("repair-2.md" in b for b in repairs(gap, "firth")),
              "the audit checks feedback kept after a missing round")
        # Codex's case (#152): the CLI defaulted to Firth, so a Python author's
        # real feedback was rebuilt as Firth feedback and flagged. --lang is now
        # required. Planted: the same Python feedback checked as Firth.
        py = d / "python"
        py.mkdir()
        (py / "answer-1.md").write_text("### task: sort\n```python\ndef main(xs):\n    return xs\n```\n")
        (py / "solutions-1.json").write_text(json.dumps(harness.extract((py / "answer-1.md").read_text())))
        (py / "results-1.json").write_text(json.dumps({"tasks": {"sort": {"submitted": True, "cases": [
            {"visible": True, "pass": False, "ok": True, "stack": [[2, 1]], "expected": [[1, 2]]}]}}}))
        (py / "repair-1.md").write_text(harness.repair(json.loads((py / "solutions-1.json").read_text()),
                                                       json.loads((py / "results-1.json").read_text()),
                                                       "python", harness.select("mvp")))
        check(repairs(py, "python") == [], "the audit passes a Python author's own feedback")
        check(repairs(py, "firth") != [], "checked as Firth, the same feedback is flagged (the planted case)")
        cli = subprocess.run([sys.executable, str(HERE / "audit_subagent.py"), str(d / "none.jsonl"),
                              "--prompt", str(prompt), "--dir", str(py), "--rounds", "2"],
                             capture_output=True, text=True)
        check(cli.returncode == 2 and "--lang" in cli.stderr, "the audit CLI refuses to guess the language")
    from audit_subagent import solutions_mismatch
    kept = sorted(p for p in (HERE / "runs").glob("2026-09-28-*/*") if (p / "answer-1.md").is_file())
    check(kept and all(solutions_mismatch(p) == [] for p in kept),
          f"every kept round's scored solutions are its answers as written ({len(kept)} authors)")
    from audit_subagent import repair_mismatch
    check(all(repair_mismatch(p, "python" if "python" in p.name else "firth") == [] for p in kept),
          "every kept feedback file is what its round's results give")


def run_options_parsed() -> None:
    # Codex's case: the README's `run DIR --tool X -- CMD` must parse --tool as
    # an option, not as the author command. Planted: with the old REMAINDER
    # positional, --tool lands in the command and no tool is shown.
    import isolate
    argv = ["run", "/var/tmp/ws", "--tool", "/opt/cli", "--keep", "/root/.cred", "--", "author", "--flag"]
    a = isolate.parse_args(argv)
    check(a.tool == ["/opt/cli"] and a.keep == ["/root/.cred"] and a.command == ["author", "--flag"],
          f"run parses its options before -- and the command after it: {a.tool} {a.keep} {a.command}")
    old = isolate.parser(remainder=True).parse_args(argv)
    check(old.tool == [] and old.command[:1] == ["--tool"],
          f"with REMAINDER, --tool is taken as the command (the planted case): {old.command[:2]}")


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
    # Hashes are those of the files as first loaded, before the task sets were
    # imported; an edit after that, before or during scoring, is refused.
    # Planted: files edited after loading, and files edited mid-run.
    real, loaded = harness.eval_hashes, harness.IMPORT_HASHES
    check(loaded == real(), "the hashes taken at import match the files on disk")

    ran: list[bool] = []

    def refused(seq: list[str]) -> bool:
        seen = iter({"harness.py": v} for v in seq)
        harness.eval_hashes = lambda: next(seen, {"harness.py": seq[-1]})
        ran.clear()
        try:
            harness.scored_with_hashes(lambda: ran.append(True) or "result")
        except SystemExit:
            return True
        return False
    try:
        harness.IMPORT_HASHES = {"harness.py": "a"}
        check(refused(["b"]) and not ran, "scoring refuses, before running, when the eval files changed after they were loaded")
        check(refused(["a", "b"]), "scoring refuses when the eval files change while it runs")
        harness.eval_hashes = lambda: {"harness.py": "a"}
        real_tree = harness.tree_state
        try:
            harness.tree_state = lambda: ("c0ffee", "d")
            check(harness.scored_with_hashes(lambda: "result") == ("result", {"harness.py": "a"}, "c0ffee"),
                  "unchanged files give the result with the hashes taken at load and the commit taken before")
            trees = iter([("c0ffee", "d"), ("c0ffee", "e")])
            harness.tree_state = lambda: next(trees)
            moved = False
            try:
                harness.scored_with_hashes(lambda: "result")
            except SystemExit:
                moved = True
            check(moved, "scoring refuses when the Firth tree changes while it runs, even dirty to dirty")
            # Codex's case: two different uncommitted patches must not record
            # the same firth_commit. Planted: the same dirty head, two digests.
            got = []
            for digest in ("p1", "p2"):
                harness.tree_state = lambda d=digest: ("c0ffee-dirty", d)
                got.append(harness.scored_with_hashes(lambda: "result")[2])
            check(got == ["c0ffee-dirty+p1", "c0ffee-dirty+p2"],
                  f"a dirty tree's firth_commit names its digest, so two patches differ: {got}")
        finally:
            harness.tree_state = real_tree
    finally:
        harness.eval_hashes, harness.IMPORT_HASHES = real, loaded
    state = harness.tree_state()
    check(state == harness.tree_state() and state[0] == harness.firth_commit(),
          "the tree state is stable and names the commit firth_commit reports")
    probe = harness.ROOT / f"s7-untracked-probe-{os.getpid()}"
    real_digest = harness.untracked_digest
    try:
        probe.write_text("before")
        before = harness.tree_state()
        probe.write_text("after!")
        check(harness.tree_state() != before, "an untracked file edited during a run changes the tree state")
        harness.untracked_digest = lambda: b""
        probe.write_text("before")
        names_only = harness.tree_state()
        probe.write_text("after!")
        check(harness.tree_state() == names_only,
              "without its contents hashed, the same edit goes unseen (the planted case)")
    finally:
        harness.untracked_digest = real_digest
        probe.unlink(missing_ok=True)


def classify_default() -> None:
    import subprocess
    import tempfile
    import classify
    check(all(t.needs <= classify.ALL for t in MVP), "classify's default capabilities cover every MVP task")
    plain = {"cases": [{"visible": True, "pass": False, "ok": False, "error": "code: firth.type.branch-mismatch"}]}
    check(classify.by_rule("sort", plain, set(classify.ALL)) is None,
          "with every capability, an ordinary MVP failure goes to Jev")
    check(classify.by_rule("sort", plain, {"add"}) == "missing_primitive",
          "with only add, the same failure is missing_primitive by rule (the planted case)")
    # Run the CLI with no flags on a failure the fuel rule catches, so Jev is never
    # asked: the old "add" default labelled it missing_primitive instead.
    fuel = {"tasks": {"sort": {"pass": False, "cases": [{"visible": True, "pass": False, "ok": False,
                                                          "error": "fuel exhausted"}]}}}
    with tempfile.TemporaryDirectory() as d:
        (Path(d) / "s.json").write_text("{}")
        (Path(d) / "r.json").write_text(json.dumps(fuel))
        cli = [sys.executable, str(HERE / "classify.py"), f"{d}/s.json", f"{d}/r.json"]
        got = json.loads(subprocess.run(cli, capture_output=True, text=True, check=True).stdout)
        old = json.loads(subprocess.run(cli + ["--available", "add"], capture_output=True, text=True,
                                        check=True).stdout)
    check(got["tasks"]["sort"] == {"mode": "resource_limit", "by": "rule"},
          "classify.py with no flags labels an MVP failure by what went wrong")
    check(old["tasks"]["sort"]["mode"] == "missing_primitive",
          "with the old add default it is missing_primitive (the planted case)")


def main() -> int:
    hand_values()
    scorer_rejects_wrong_python()
    hashes_recorded()
    rounds_prompt()
    feedback_keeps_hints()
    feedback_shows_location()
    feedback_shows_every_error()
    subagent_audit()
    run_options_parsed()
    unsandboxed_python_refused()
    classify_default()
    if "--no-firth" not in sys.argv:
        firth_references()
    print(f"\n{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
