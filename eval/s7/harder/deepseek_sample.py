#!/usr/bin/env python3
"""Run one DeepSeek sample of the harder tier through both rounds and score it
(`todo.s7-harder-task-tier`).

    python3 deepseek_sample.py --set scored --lang firth|python PROMPT DIR

A Sonnet sample is run by hand with `tier.py`'s steps; a DeepSeek author has
no hands, so this runs the same steps around `deepseek.py`:

1. Round 1: `deepseek.py` asks once. Its answer is extracted
   (`solutions-1.json`) and scored (`results-1.json`).
2. The feedback (`repair-1.md`) is `tier.py repair`'s: each answer that
   failed its visible example, never a hidden test. When every answer passed
   its example there is no feedback and no round 2.
3. Round 2 answers only the tasks the feedback listed. Those answers replace
   round 1's (`solutions-2.json`) and the whole set is scored again
   (`results-2.json`). An answer in round 2 to a task the feedback did not
   list is not taken, and is named in `outcome.json`. Both rounds' solutions
   are built by `tier.take`, the step a Sonnet sample's are built with.

A reply cut off at the length limit (`deepseek.py` exit 2) is a failed answer:
nothing in it is scored, whatever it holds, and a round-2 cut-off keeps round
1's results as they were scored, without scoring again. After a round-1 cut-off the
feedback says so and lists every task, and round 2 resends the cut text as
the model's turn (`cut-1.md`). A void round (exit 3: the request failed or the
reply was not a complete answer from the model) voids the whole sample, which
is replaced as the pre-registration says; nothing is scored and `outcome.json`
records the round and why. A run that stops part way (an error, or a guard in
`deepseek.py` or `tier.py` refusing) leaves `outcome.json` with status
`crashed` and the error, so a half-finished directory is never read as a
finished sample; the directory is not reused.

`outcome.json` records each round's verdict, which tasks passed in round 1
and within two rounds, and the totals. Exit 0 for a scored sample, 3 for a
void one. `test_harder.py` runs this against planted replies, with no network.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import deepseek  # noqa: E402
import tier  # noqa: E402

CUT_OFF = ("Your reply was cut off at the length limit before it was complete, so none "
           "of it was scored. Every task counts as unanswered; answer each one again, "
           "more briefly if you can.\n\n")


def sample(prompt: Path, d: Path, set_name: str, lang: str, send=deepseek.post, score=None) -> dict:
    tasks = list(tier.SETS[set_name])
    score = score or (lambda sols: tier.scored(sols, lang, tasks, jobs=4))
    out: dict = {"set": set_name, "lang": lang, "model": deepseek.MODEL, "rounds": []}
    with open(d / "outcome.json", "x") as f:  # one sample per directory
        f.write(json.dumps({**out, "status": "running"}, indent=1) + "\n")

    def finish(status: str) -> dict:
        out["status"] = status
        deepseek.write(d / "outcome.json", json.dumps(out, indent=1) + "\n")
        return out

    try:
        return rounds(prompt, d, tasks, lang, send, score, out, finish)
    except BaseException as e:  # a run that stops part way is recorded as such, never as finished
        out["error"] = repr(e)
        finish("crashed")
        raise


def rounds(prompt, d, tasks, lang, send, score, out, finish) -> dict:
    solutions: dict[str, str] = {}
    res: dict = {}
    for rnd in (1, 2):
        code = deepseek.run(prompt, d, rnd, send)
        verdict = json.loads(deepseek.text(d / f"request-{rnd}.json"))["outcome"]
        entry = {"round": rnd, "result": verdict["result"], "why": verdict["why"]}
        out["rounds"].append(entry)
        if code == 3:
            out["void"] = {"round": rnd, "why": verdict["why"]}
            return finish("void")
        entry["not_taken"] = []
        if code == 0:  # the same step a Sonnet sample's solutions are built with (`tier.py take`)
            solutions, entry["not_taken"] = tier.take(deepseek.text(d / f"answer-{rnd}.md"), tasks,
                                                      None if rnd == 1 else (solutions, res))
        deepseek.write(d / f"solutions-{rnd}.json", json.dumps(solutions, indent=2) + "\n")
        if rnd == 2 and code == 2:
            res = json.loads(deepseek.text(d / "results-1.json"))  # nothing new: round 1's results stand
        else:
            res = score(solutions)
        deepseek.write(d / f"results-{rnd}.json", json.dumps(res, indent=2) + "\n")
        passed = {tid: r["pass"] for tid, r in res["tasks"].items()}
        out["round1" if rnd == 1 else "within_two"] = passed
        if rnd == 2:
            break
        feedback = tier.repair(solutions, res, lang, tasks)
        if code == 2:
            feedback = CUT_OFF + feedback
        if not feedback:
            out["within_two"] = passed  # nothing could be shown, so no round 2
            break
        deepseek.write(d / "repair-1.md", feedback)
    out["passed"] = {k: sum(out[k].values()) for k in ("round1", "within_two")}
    out["tasks"] = len(tasks)
    return finish("scored")


def main(argv: list[str]) -> int:
    cli = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    # DeepSeek is a subject on the scored set only; tests call `sample` with calibration fixtures.
    cli.add_argument("--set", required=True, choices=["scored"])
    cli.add_argument("--lang", required=True, choices=["firth", "python"])
    cli.add_argument("prompt", type=Path)
    cli.add_argument("dir", type=Path)
    a = cli.parse_args(argv)
    out = sample(a.prompt, a.dir, a.set, a.lang)
    print(json.dumps({k: out.get(k) for k in ("status", "passed", "tasks", "void")}))
    return 0 if out["status"] == "scored" else 3


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
