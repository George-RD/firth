"""Kernel steps of the dropped chess-moves Firth references on the recorded
positions (README, "The candidate set"). Each row: reference, position,
kernel steps, and whether the result equals the expected one recorded in
positions.json from the task's meaning when the task was dropped.

    python3 eval/s7/harder/runs/2026-10-11-chess-moves-dropped/measure.py > output.tsv
"""
import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]


def run(ref: str, pos: dict) -> str:
    p = subprocess.run([sys.executable, "tools/loop/firth_run.py", "run", str(HERE / ref), "--entry", "main",
                        "--stack", json.dumps(pos["input"]), "--fuel", "1000000"],
                       cwd=ROOT, capture_output=True, text=True)
    out = json.loads(p.stdout)
    return f"{ref}\t{pos['name']}\t{out.get('kernel_cost')}\t{out.get('stack') == pos['expected']}"


def main() -> int:
    positions = json.loads((HERE / "positions.json").read_text())
    jobs = [(ref, pos) for ref in ("chess-moves-first.firth", "chess-moves.firth") for pos in positions]
    with ThreadPoolExecutor(4) as ex:
        for line in ex.map(lambda j: run(*j), jobs):
            print(line, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
