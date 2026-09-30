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


def check_tool_prompt() -> None:
    # Run 12: arm B's prompt differs from arm A's only in the tool paragraph,
    # which names the check command by this checkout's absolute path.
    a = harness.prompt(list(MVP), "firth", rounds=2)
    b = harness.prompt(list(MVP), "firth", rounds=2, check_tool=True)
    check(harness.CHECK not in a and harness.CHECK in b and str(Path(harness.__file__).resolve()) in b,
          "only the check-tool prompt offers the checker, by absolute path")
    head_a, tail_a = a.split("Do not use any tool", 1)
    head_b, tail_b = b.split("Do not use any tool", 1)
    rest = "After you answer, you will be shown"
    check(head_a == head_b and tail_a[tail_a.index(rest):] == tail_b[tail_b.index(rest):],
          "the check-tool prompt changes the tool paragraph and nothing else")
    for lang, rounds in (("python", 2), ("firth", 0)):
        try:
            harness.prompt(list(MVP), lang, rounds=rounds, check_tool=True)
            refused = False
        except ValueError:
            refused = True
        check(refused, f"the check tool is refused for {lang} with {rounds} rounds")


def check_tool_checks_only() -> None:
    # `check` must show the checker's verdict for each block and run nothing.
    # Planted: a program that checks but traps when run (an index past the end)
    # must read `ok`; if `check` ran programs it would show the trap.
    traps = ("### task: sum-list\n```firth\n: main ( forall ρ; ρ xs:Seq Int -- ρ r:Int ) "
             "locals { xs } { xs 99 prim seq-int.at } ;\n```\n")
    bad = "### task: reverse\n```firth\n: main ( forall ρ; ρ x:Int -- ρ r:Int ) a ;\n```\n"
    got = harness.check_answer(traps + "\n" + bad)
    check(got.startswith("## sum-list\nok\n\n## reverse\n") and "firth.name.unresolved" in got
          and "trap" not in got, f"check shows ok and diagnostics, in file order, and runs nothing: {got[:300]!r}")
    check(harness.check_answer("no blocks here").startswith("No task blocks found"),
          "check says when it finds no task block")
    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        link = Path(tmp) / "answer-1.md"
        link.symlink_to(HERE / "mvp_tasks.py")
        cli = subprocess.run([sys.executable, str(HERE / "harness.py"), "check", "--lang", "firth", str(link)],
                             capture_output=True, text=True)
        check(cli.returncode != 0 and "not a plain file" in cli.stderr,
              "check refuses an answer file that is a link (the planted case)")


def check_tool_audit() -> None:
    # Arm B's audit allows exactly the check command on the author's own answer
    # files, and its reads, writes and edits of them; any other call is a void.
    import tempfile
    from audit_subagent import audit
    tool = Path("/pinned/eval/s7/harness.py")
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        prompt, ans = d / "prompt-firth.md", d / "answer-1.md"
        prompt.write_text("p")
        final = "### task: sort\n```firth\nfixed\n```\n"
        ans.write_text(final)
        (d / "solutions-1.json").write_text(json.dumps(harness.extract(final)))

        def call(name, **inp):
            return {"type": "assistant", "timestamp": "t",
                    "message": {"model": "m", "content": [{"type": "tool_use", "name": name, "input": inp}]}}
        run = f"python3 {tool} check --lang firth {ans}"
        ok = [call("Read", file_path=str(prompt)),
              call("Write", file_path=str(ans), content=final.replace("fixed", "draft")),
              call("Bash", command=run, description="check my answer"),
              call("Read", file_path=str(ans)),
              call("Edit", file_path=str(ans), old_string="draft", new_string="fixed"),
              call("Bash", command=run)]
        log, bad = audit(ok, prompt, d, d, 2, "firth", tool)
        check(bad == [] and log["check_calls"] == 2,
              f"arm B's audit passes check runs, reads, writes and edits of its own answer: {bad}")
        check(len(audit(ok, prompt, d, d, 2, "firth")[1]) >= 2,
              "without --check-cmd the same log is flagged (arm A)")
        other = d.parent / "haiku-firth-9" / "answer-1.md"
        for what, ev in (
                ("a check of another sample's answer", call("Bash", command=f"python3 {tool} check --lang firth {other}")),
                ("a check through another harness", call("Bash", command=f"python3 /home/user/firth/eval/s7/harness.py check --lang firth {ans}")),
                ("a check with more shell after it", call("Bash", command=run + "; cat " + str(HERE / "mvp_tasks.py"))),
                ("a check piped elsewhere", call("Bash", command=run + " | tee /tmp/x")),
                ("a check of an answer past the round limit", call("Bash", command=run.replace("answer-1", "answer-4"))),
                ("a check run in the background", call("Bash", command=run, run_in_background=True)),
                ("the harness's try", call("Bash", command=f"python3 {tool} try --lang firth --task sort {ans}")),
                ("any other command", call("Bash", command="ls")),
                ("an edit of another file", call("Edit", file_path=str(HERE / "harness.py"), old_string="a", new_string="b"))):
            check(len(audit(ok + [ev], prompt, d, d, 2, "firth", tool)[1]) == 1, f"arm B's audit flags {what}")
        # Run 13 (`--shell-forms`): the check command may carry a closed set of
        # additions that only read the checker's own output. Each allowed form
        # passes with the flag and is flagged without it (run 12's rule).
        root = "cd /pinned && "
        for form in (run + " 2>&1", run + " 2>&1 | head -100", run + " | head -n 50",
                     run + " 2>&1 | tail -50", run + " 2>&1 | tail -n 20",
                     run + ' 2>&1 | grep -E "^## |^ok$"', run + " 2>&1 | grep -A 10 '^## reverse$'",
                     run + ' | grep -n -i -v -c "x"', run + ' 2>&1 | grep -B 2 -C 3 "error"',
                     run + ' 2>&1 | grep -E "^## |^ok$|^code:" | head -50',
                     run + ' 2>&1 | grep -A 20 "^## sort$" | tail -n 25',
                     run + r' 2>&1 | grep -A 10 "^## sort\|^## histogram"',
                     run + ' 2>&1 | grep -E "^## |^ok|^code:" ',
                     run + ' | grep "^ok$"', run + r' | grep -E "^## sort\$"',
                     root + run, root + run + " 2>&1 | tail -60"):
            ev = call("Bash", command=form)
            shown = ("cd prefix, " if form.startswith(root) else "") + repr(form.split(run)[1])
            check(audit(ok + [ev], prompt, d, d, 2, "firth", tool, shell_forms=True)[1] == [],
                  f"run 13's audit allows the check with {shown}")
            check(len(audit(ok + [ev], prompt, d, d, 2, "firth", tool)[1]) == 1,
                  f"run 12's audit still flags the check with {shown}")
        for what, form in (
                ("a grep reading patterns from a file", run + f" 2>&1 | grep -f {HERE / 'mvp_tasks.py'}"),
                ("a grep with a file operand", run + ' | grep "x" /some/file'),
                ("a grep with an unquoted pattern", run + " 2>&1 | grep x"),
                ("a recursive grep", run + ' | grep -r "x"'),
                ("a grep with --include", run + ' | grep --include=*.py "x"'),
                ("an option hidden in a quoted pattern", run + ' | grep "-r"'),
                ("-f hidden in a quoted pattern", run + " | grep '-f/etc/passwd'"),
                ("command substitution in a pattern", run + f' | grep "$(cat {HERE / "mvp_tasks.py"})"'),
                ("a backquote in a pattern", run + ' | grep "`id`"'),
                ("a variable in a pattern", run + ' | grep "$HOME"'),
                ("a second command after a pipe", run + " | head; cat x"),
                ("a second pipe", run + ' | head -5 | grep "x"'),
                ("head with a file operand", run + " | head 5"),
                ("a redirect to a file", run + " > /tmp/out"),
                ("an appended redirect", run + " 2>&1 >> /tmp/out"),
                ("input from a file", run + " < /etc/passwd"),
                ("&& after the check", run + " && cat x"),
                ("|| after the check", run + " || cat x"),
                ("cd somewhere else first", "cd /eval && " + run),
                ("a command between cd and the check", root + "ls && " + run),
                ("2>&1 after the pipe", run + ' | grep "x" 2>&1'),
                ("a third pipe", run + ' | grep "x" | head -5 | tail -1'),
                ("a grep after head", run + ' | head -5 | grep "x"'),
                ("an escaped quote in a pattern", run + r' | grep "a\"; cat x; \""'),
                ("a backslash before a letter", run + r' | grep "\n"'),
                ("a file operand after grep's head", run + ' | grep "x" | head -5 x')):
            check(len(audit(ok + [call("Bash", command=form)], prompt, d, d, 2, "firth", tool,
                            shell_forms=True)[1]) == 1, f"run 13's audit flags {what}")
        # The answer left by the writes and edits must be the one scored.
        stale = ok[:5]
        check(any("left" in b for b in audit(stale[:2] + stale[2:4], prompt, d, d, 2, "firth", tool)[1]),
              "arm B's audit flags a kept answer that is not what the last write left (the planted case)")
        lost = [call("Edit", file_path=str(ans), old_string="absent", new_string="x")]
        check(any("replayed" in b for b in audit(ok + lost, prompt, d, d, 2, "firth", tool)[1]),
              "arm B's audit flags an edit reported as done that it cannot replay (the planted case)")

        # A call the tool reported as an error changed nothing, so it is not
        # replayed (the reviewer, on #190): an author retrying a mismatched
        # old_string, or a write the tool refused, is not a void.
        def failing(name, cid, **inp):
            ev = call(name, **inp)
            ev["message"]["content"][0]["id"] = cid
            return [ev, {"type": "user", "timestamp": "t", "message": {"role": "user", "content": [
                {"type": "tool_result", "tool_use_id": cid, "is_error": True,
                 "content": "String to replace not found in file."}]}}]
        retry = ok[:4] + failing("Edit", "e1", file_path=str(ans), old_string="draft ", new_string="fixed") + ok[4:]
        check(audit(retry, prompt, d, d, 2, "firth", tool)[1] == [],
              "arm B's audit passes a failed edit followed by the corrected one")
        refused = ok + failing("Write", "w1", file_path=str(ans), content="never written")
        check(audit(refused, prompt, d, d, 2, "firth", tool)[1] == [],
              "arm B's audit does not count a write the tool refused")
        check(audit(refused, prompt, d, d, 2, "firth", tool)[0]["tool_calls"][-1].get("tool_error"),
              "the kept log marks the refused write")
        # Planted: the same failed edit without its error result is flagged.
        bare = ok[:4] + [call("Edit", file_path=str(ans), old_string="draft ", new_string="fixed")] + ok[4:]
        check(any("replayed" in b for b in audit(bare, prompt, d, d, 2, "firth", tool)[1]),
              "without its error result, the same edit is flagged (the planted case)")
        arm_a = [call("Read", file_path=str(prompt)), call("Write", file_path=str(ans), content=final)]
        check(audit(arm_a + failing("Write", "w2", file_path=str(ans), content="never written"),
                    prompt, d, d, 2, "firth")[1] == [],
              "arm A's audit does not count a write the tool refused either")
        check(len(audit(arm_a + [call("Write", file_path=str(ans), content="rewritten")],
                        prompt, d, d, 2, "firth")[1]) == 1,
              "arm A's audit still flags a rewrite that succeeded (the planted case)")
        outside = failing("Edit", "e2", file_path=str(HERE / "harness.py"), old_string="a", new_string="b")
        check(len(audit(ok + outside, prompt, d, d, 2, "firth", tool)[1]) == 1,
              "a failed edit of another file is still flagged")
        # Only the harness's own tool result, in a user-type event and carrying
        # the call's id, marks a call as failed (reviewer, on #190). Planted:
        # an error result spoofed in an assistant event, and one with no id
        # matching a call with no id, leave the bad edit flagged.
        spoofed = failing("Edit", "e3", file_path=str(ans), old_string="draft ", new_string="fixed")
        spoofed[1]["type"] = "assistant"
        check(any("replayed" in b for b in audit(ok[:4] + spoofed + ok[4:], prompt, d, d, 2, "firth", tool)[1]),
              "an error result outside a user-type event is not trusted (the planted case)")
        no_id = failing("Edit", "e4", file_path=str(ans), old_string="draft ", new_string="fixed")
        del no_id[0]["message"]["content"][0]["id"]
        del no_id[1]["message"]["content"][0]["tool_use_id"]
        check(any("replayed" in b for b in audit(ok[:4] + no_id + ok[4:], prompt, d, d, 2, "firth", tool)[1]),
              "an error result with no id marks no call as failed (the planted case)")
        # A kept answer must come from a successful write or edit in the log.
        # Planted: no write at all, and only a refused write, in either arm.
        for arm, cmd in (("A", None), ("B", tool)):
            for what, log in (("no write at all", [call("Read", file_path=str(prompt))]),
                              ("only a refused write", [call("Read", file_path=str(prompt))]
                               + failing("Write", "w3", file_path=str(ans), content=final))):
                check(any("no successful write" in b for b in audit(log, prompt, d, d, 2, "firth", cmd)[1]),
                      f"arm {arm}'s audit flags a kept answer with {what} (the planted case)")
        # Run 14's forms: run 13's, with `$` also allowed before `)` in a grep
        # pattern. Planted: run 13's forms still flag it, and `$` before a
        # letter or `(` stays flagged under run 14's.
        dollar = run + ' 2>&1 | grep -E "^(## |ok$)"'
        check(audit(ok + [call("Bash", command=dollar)], prompt, d, d, 2, "firth", tool,
                    shell_forms="run14")[1] == [], "run 14's audit allows `$)` in a grep pattern")
        check(len(audit(ok + [call("Bash", command=dollar)], prompt, d, d, 2, "firth", tool,
                        shell_forms=True)[1]) == 1, "run 13's audit still flags `$)` (the planted case)")
        for form in (run + ' | grep "ok$x"', run + ' | grep "$(id)"', run + ' | grep "$HOME"'):
            check(len(audit(ok + [call("Bash", command=form)], prompt, d, d, 2, "firth", tool,
                            shell_forms="run14")[1]) == 1, f"run 14's audit flags {form.split(run)[1]!r}")
        # Run 14's author hook stops a call before it runs. A call counts as
        # stopped only when the hook's log denied its id and the author's log
        # shows the hook's mark in that call's result; then it is kept, not
        # flagged. Planted: each half alone is flagged, and so is a stopped
        # call that was on the list.
        from audit_subagent import HOOK_MARK

        def stopped(name, cid, mark=True, **inp):
            ev = call(name, **inp)
            ev["message"]["content"][0]["id"] = cid
            text = f"{HOOK_MARK} This call is not allowed" if mark else "ran"
            return [ev, {"type": "user", "timestamp": "t", "message": {"role": "user", "content": [
                {"type": "tool_result", "tool_use_id": cid, "is_error": True, "content": text}]}}]
        hook_log = d / "hook-log.jsonl"
        hook_log.write_text(json.dumps({"tool_use_id": "h1", "decision": "deny"}) + "\n"
                            + json.dumps({"tool_use_id": "h9", "decision": "deny"}) + "\n")
        wc = stopped("Bash", "h1", command=run + " | wc -l")
        log, bad = audit(ok + wc, prompt, d, d, 2, "firth", tool, "run14", hook_log)
        check(bad == [] and log["blocked_calls"] == 1 and log["tool_calls"][-1].get("blocked"),
              f"run 14's audit keeps a call the hook stopped, unflagged: {bad}")
        check(len(audit(ok + wc, prompt, d, d, 2, "firth", tool, "run14")[1]) == 1,
              "without the hook log the same call is flagged (the planted case)")
        unmarked = stopped("Bash", "h1", mark=False, command=run + " | wc -l")
        check(len(audit(ok + unmarked, prompt, d, d, 2, "firth", tool, "run14", hook_log)[1]) == 2,
              "a denial whose result lacks the hook's mark is flagged, and so is the call (the planted case)")
        forged = stopped("Bash", "h2", command=run + " | wc -l")
        check(any("did not deny" in b for b in audit(ok + forged, prompt, d, d, 2, "firth", tool, "run14",
                                                     hook_log)[1]),
              "a result with the hook's mark that the hook log did not deny is flagged (the planted case)")
        on_list = stopped("Bash", "h9", command=run)
        check(any("on the list" in b for b in audit(ok + on_list, prompt, d, d, 2, "firth", tool, "run14",
                                                    hook_log)[1]),
              "a call on the list that the hook stopped is flagged (the planted case)")


def author_hook_decides() -> None:
    # Run 14's hook asks the audit's own `allowed`; its self-test plants
    # allowed and refused calls in both arms and a missing state file.
    cli = subprocess.run([sys.executable, str(HERE / "author_hook.py"), "--self-test"],
                         capture_output=True, text=True)
    check(cli.returncode == 0 and "self-test: ok" in cli.stdout,
          f"the author hook's self-test passes: {cli.stdout[-300:]}{cli.stderr[-300:]}")


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
    except harness.ToolchainError as e:
        check(False, f"feedback_shows_location needs a built toolchain: {e}")
        return
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
    """The checker reports the first error in each word it refuses. The feedback
    must show each of them with its word and place, so an author can fix both
    words at once: `main` uses its input name without `locals` (line 3), and
    `twice` adds a Bool (line 6)."""
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


def run10_causes() -> None:
    """The run 10 failure analysis scripts' own checks, and the hand labels still
    match the sample they were written for."""
    causes = HERE / "runs/2026-09-29-control/causes"
    for script, arg in (("causes.py", "--self-test"), ("recheck.py", "--self-test"),
                        ("rank.py", "--self-test"), ("behaviour.py", "--self-test"),
                        ("handcheck_sample.py", "--self-test"),
                        ("b4_parens.py", "--self-test"),
                        ("handcheck_sample.py", "--compare")):
        r = subprocess.run([sys.executable, str(causes / script), arg], cwd=HERE,
                           capture_output=True, text=True)
        check(r.returncode == 0, f"run 10 {script} {arg} passes"
              + ("" if r.returncode == 0 else ": " + r.stderr[-300:]))


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


def build_failure_stops_scoring() -> None:
    """A runner that cannot build its toolchain never ran the answer. The scorer
    stops rather than fail the case and pass the build error on as feedback, and
    the run 8 measurement scripts stop rather than read it as no error."""
    import importlib.util
    import tempfile
    lake = {"error": "lake: exit 1: error: build failed", "status": "error"}
    answer = {"error": "entry: unknown checked word 'main'", "status": "error"}
    diag = "[{'body': {'code': 'firth.type.stack-underflow', 'location': {'start': {'line': 2, 'column': 3}}}}]"
    with tempfile.TemporaryDirectory() as d:
        stub = Path(d) / "tools/loop/firth_run.py"
        stub.parent.mkdir(parents=True)

        def runner_says(text: str) -> None:
            stub.write_text(f"import sys\nprint({text!r}, file=sys.stderr)\nsys.exit(1)\n")

        old_runner = harness.RUNNER
        harness.RUNNER = stub
        try:
            runner_says(json.dumps(lake))
            try:
                got = harness.run_firth(": main ( -- ) ;", ())
            except harness.ToolchainError as e:
                got = str(e)
            check(got == lake["error"], "a failed build stops scoring instead of failing the answer")
            for error in ("toolchain: lake is not on PATH", "toolchain: /opt/elan/bin/lake did not answer "
                          "within 900s", "cargo: exit 101: error: could not compile", "toolchain: "
                          "firthCompile was not built"):
                runner_says(json.dumps({"error": error, "status": "error"}))
                try:
                    got = harness.run_firth(": main ( -- ) ;", ())
                except harness.ToolchainError as e:
                    got = str(e)
                check(got == error, f"a build failure stops scoring: {error}")
            runner_says(json.dumps(answer))
            got = harness.run_firth(": main ( -- ) ;", ())
            check(got["ok"] is False and "unknown checked word 'main'" in got["error"],
                  "an answer's own runner error is still scored as a failed case")
            # An adapter that times out on an answer is the answer's failure, though
            # the runner words it like a toolchain error (Codex, on #173).
            adapter = {"error": "toolchain: /w/.lake/build/bin/firthElaborate did not answer within 60s",
                       "status": "error"}
            runner_says(json.dumps(adapter))
            try:
                got = harness.run_firth(": main ( -- ) ;", ())
            except harness.ToolchainError as e:
                got = {"raised": str(e)}
            check(got.get("ok") is False and "firthElaborate did not answer" in got.get("error", ""),
                  "an adapter timeout on an answer is still scored as a failed case")
            # A cold build that outlasts the per-answer timeout is the build's,
            # not the answer's (Codex, on #173).
            stub.write_text("import time\ntime.sleep(3)\n")
            timeouts = harness.TIMEOUT, harness.BUILD_TIMEOUT
            harness.TIMEOUT = harness.BUILD_TIMEOUT = 1
            task = MVP[0]
            try:
                got = harness.score({task.id: ": main ( -- ) ;"}, "firth", [task], 1)
            except harness.ToolchainError as e:
                got = str(e)
            finally:
                harness.TIMEOUT, harness.BUILD_TIMEOUT = timeouts
            check(got == "the toolchain did not build within 1s",
                  "a build that times out stops scoring instead of failing the answer")
        finally:
            harness.RUNNER = old_runner

        fixes = HERE / "runs/2026-09-29-haiku-4c379e0/fixes/measure.py"
        spec = importlib.util.spec_from_file_location("run8_measure", fixes)
        measure = importlib.util.module_from_spec(spec)
        argv, sys.argv = sys.argv, sys.argv[:1]
        try:
            spec.loader.exec_module(measure)
        finally:
            sys.argv = argv
        measure.ROOT = Path(d)
        runner_says(json.dumps(lake))
        try:
            got = measure.check(": main ( -- ) ;")
        except RuntimeError as e:
            got = "raised" if "lake: exit 1" in str(e) else str(e)
        check(got == "raised", "the run 8 measurement stops on a failed build instead of counting no error")
        runner_says(diag)
        check(measure.check(": main ( -- ) ;") == ("firth.type.stack-underflow", 2, 3),
              "the run 8 measurement still reads a checker diagnostic")


def main() -> int:
    hand_values()
    scorer_rejects_wrong_python()
    hashes_recorded()
    rounds_prompt()
    check_tool_prompt()
    check_tool_audit()
    author_hook_decides()
    feedback_keeps_hints()
    feedback_shows_location()
    feedback_shows_every_error()
    subagent_audit()
    run_options_parsed()
    unsandboxed_python_refused()
    classify_default()
    run10_causes()
    build_failure_stops_scoring()
    if "--no-firth" not in sys.argv:
        firth_references()
        check_tool_checks_only()
    print(f"\n{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
