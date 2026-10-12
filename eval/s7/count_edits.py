#!/usr/bin/env python3
"""Every report in the S7 answers, examples and stdlib that names a value to
remove ("Remove the `x` written at line L, column C"), with the removal
applied literally and the answer scored on its task.

The checker names a removal only when the word then checks
(`extraValueEdit` in `src/elaborator/Firth/Pipeline.lean`). This shows what
the removal does to the whole answer: whether the program then checks, and
how many of the task's tests it passes. The answers were all refused before
the removal, so none passed a test.

    python3 eval/s7/count_edits.py > eval/s7/count-edits.txt
"""
from __future__ import annotations

import glob
import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE / "harder"))
import harness  # noqa: E402
import tier  # noqa: E402

REMOVE = re.compile(r"Remove the `([^`]+)` written at line (\d+), column (\d+)")


def sources() -> dict[str, list[tuple[str, str]]]:
    """Each distinct answer or file, with where it was found."""
    found: dict[str, list[tuple[str, str]]] = {}
    for path in sorted(glob.glob(str(ROOT / "eval/s7/**/solutions-*.json"), recursive=True)):
        data = json.loads(Path(path).read_text())
        if isinstance(data, dict):
            for task, source in data.items():
                if isinstance(source, str):
                    found.setdefault(source, []).append((str(Path(path).relative_to(ROOT)), task))
    for path in sorted(glob.glob(str(ROOT / "examples/**/*.firth"), recursive=True)
                       + glob.glob(str(ROOT / "stdlib/**/*.firth"), recursive=True)):
        found.setdefault(Path(path).read_text(), []).append((str(Path(path).relative_to(ROOT)), "file"))
    return found


def removed(source: str, token: str, line: int, column: int) -> str:
    lines = source.split("\n")
    text = lines[line - 1]
    if text[column - 1:column - 1 + len(token)] != token:
        raise SystemExit(f"the hint's `{token}` is not at line {line}, column {column}")
    lines[line - 1] = text[:column - 1] + text[column - 1 + len(token):]
    return "\n".join(lines)


def main() -> int:
    found = sources()
    items = list(found)
    harness.warm_toolchain(items[0])
    with ThreadPoolExecutor(8) as pool:
        reports = list(pool.map(harness.check_one, items))
    rows = []
    for source, report in zip(items, reports):
        for match in REMOVE.finditer(report):
            token, line, column = match.group(1), int(match.group(2)), int(match.group(3))
            edited = removed(source, token, line, column)
            where, task = found[source][0]
            verdict = harness.check_one(edited)
            checks = "checks" if verdict == "ok" else "refused: " + verdict.split("\n")[0].removeprefix("code: ")
            if task in tier.BY_ID:
                result = tier.score({task: edited}, "firth", [tier.BY_ID[task]])["tasks"][task]
            elif task in harness.BY_ID:
                result = harness.score({task: edited}, "firth", [harness.BY_ID[task]], 4)["tasks"][task]
            else:
                result = None
            tests = "no task" if result is None else (
                f"example {'passes' if result['cases'][0]['pass'] else 'fails'}, "
                f"hidden {result['hidden_passed']}/{result['hidden_total']}")
            rows.append(f"{where} {task}: remove `{token}` at {line}:{column}; {checks}; {tests}")
    print(f"{len(items)} sources, {len(rows)} reports name a value to remove")
    print("\n".join(rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
