#!/usr/bin/env python3
"""Reconcile the PRD obligations matrix against the todo tracker and blueprint."""

from __future__ import annotations

import argparse
import json
import re
import sys
import tomllib
from pathlib import Path

from select_unit import frontmatter_and_requires

NODE_ID = re.compile(r'id\s+"([A-Za-z0-9_.]+)"')
EDGE = re.compile(r'^([A-Za-z0-9_.]+)\s*->\s*([A-Za-z0-9_.]+)', re.MULTILINE)


def report(errors: list[str]) -> int:
    print(json.dumps({"schema": 1, "errors": sorted(errors)}, sort_keys=True))
    return 2


def load_blueprint(root: Path) -> tuple[set[str], dict[str, set[str]]]:
    text = (root / "cairn.blueprint").read_text(encoding="utf-8")
    nodes = set(NODE_ID.findall(text))
    edges: dict[str, set[str]] = {node: set() for node in nodes}
    for src, dst in EDGE.findall(text):
        edges.setdefault(src, set()).add(dst)
    return nodes, edges


def load_todo_statuses(root: Path) -> tuple[dict[str, str | None], list[str]]:
    todo_dir = root / "meta" / "todos"
    statuses: dict[str, str | None] = {}
    errors: list[str] = []
    if not todo_dir.is_dir():
        return statuses, [f"missing todo directory: {todo_dir}"]
    for path in sorted(todo_dir.glob("todo.*.md")):
        slug = path.name[len("todo.") : -len(".md")]
        fields, _requires, parse_errors = frontmatter_and_requires(path)
        errors.extend(parse_errors)
        statuses[slug] = fields.get("status")
    return statuses, errors


def classify(slugs: list[str], statuses: dict[str, str | None]) -> str:
    """complete: non-empty, all done. in-flight: any open/in_progress.
    blocked: non-empty, none open/in_progress, not all done (e.g. done+blocked).
    ungenerated: empty satisfied_by."""
    if not slugs:
        return "ungenerated"
    states = [statuses.get(slug) for slug in slugs]
    if any(state in ("open", "in_progress") for state in states):
        return "in-flight"
    if all(state == "done" for state in states):
        return "complete"
    return "blocked"


def node_status(node: str, obligations: dict[str, dict[str, object]], classification: dict[str, str]) -> str:
    rows = [oid for oid, row in obligations.items() if row.get("node") == node]
    if not rows:
        return "ungenerated"
    states = {classification[oid] for oid in rows}
    if "ungenerated" in states:
        return "ungenerated"
    if "blocked" in states:
        return "blocked"
    if "in-flight" in states:
        return "in-flight"
    return "complete"


def main() -> int:
    parser = argparse.ArgumentParser(description="reconcile PRD obligations against todos")
    parser.add_argument("--validate", action="store_true", help="validate only")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    obligations_path = root / "tools" / "loop" / "obligations.toml"
    if not obligations_path.is_file():
        return report([f"missing obligations file: {obligations_path}"])
    with obligations_path.open("rb") as handle:
        data = tomllib.load(handle)
    obligations: dict[str, dict[str, object]] = data.get("obligation", {})

    nodes, edges = load_blueprint(root)
    statuses, errors = load_todo_statuses(root)

    for oid, row in sorted(obligations.items()):
        node = row.get("node")
        if node not in nodes:
            errors.append(f"{oid}: unknown node {node!r}")
        for slug in row.get("satisfied_by", []):  # type: ignore[union-attr]
            if slug not in statuses:
                errors.append(f"{oid}: unknown satisfied_by slug {slug!r}")

    if errors:
        return report(errors)
    if args.validate:
        print(json.dumps({"schema": 1, "valid": True}, sort_keys=True))
        return 0

    classification = {
        oid: classify(row.get("satisfied_by", []), statuses)  # type: ignore[arg-type]
        for oid, row in obligations.items()
    }

    def deps_ready(node: str) -> bool:
        return all(
            node_status(dep, obligations, classification) in ("complete", "in-flight")
            for dep in edges.get(node, ())
        )

    complete = sorted(oid for oid, state in classification.items() if state == "complete")
    in_flight = sorted(oid for oid, state in classification.items() if state == "in-flight")
    blocked = sorted(oid for oid, state in classification.items() if state == "blocked")
    ungenerated = sorted(oid for oid, state in classification.items() if state == "ungenerated")
    first_incomplete = next(
        (oid for oid in sorted(classification) if classification[oid] != "complete"),
        None,
    )
    next_obligation = next(
        (oid for oid in ungenerated if deps_ready(obligations[oid]["node"])),  # type: ignore[arg-type]
        None,
    )
    all_todos_done = bool(statuses) and all(status == "done" for status in statuses.values())
    loop_exhausted_valid = not ungenerated and all_todos_done
    print(
        json.dumps(
            {
                "schema": 1,
                "complete": complete,
                "in_flight": in_flight,
                "blocked": blocked,
                "ungenerated": ungenerated,
                "first_incomplete": first_incomplete,
                "next_obligation": next_obligation,
                "loop_exhausted_valid": loop_exhausted_valid,
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
