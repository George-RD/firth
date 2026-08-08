#!/usr/bin/env python3
"""Reconcile the PRD obligations matrix against the todo tracker and blueprint."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
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


def node_status(
    node: str,
    active: dict[str, dict[str, object]],
    obligations: dict[str, dict[str, object]],
    classification: dict[str, str],
) -> str:
    """Gate on the active profile's rows. A node whose matrix rows are all
    outside the active profile is gate-neutral (complete): the inactive
    horizon must not deadlock active dependants. A node with no matrix rows
    at all stays ungenerated, as before."""
    rows = [oid for oid in active if active[oid].get("node") == node]
    if not rows:
        if any(row.get("node") == node for row in obligations.values()):
            return "complete"
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
    parser.add_argument(
        "--run-gates",
        action="store_true",
        help="execute pinned acceptance gates; a failure holds exhaustion false",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    obligations_path = root / "tools" / "loop" / "obligations.toml"
    if not obligations_path.is_file():
        return report([f"missing obligations file: {obligations_path}"])
    with obligations_path.open("rb") as handle:
        data = tomllib.load(handle)
    obligations: dict[str, dict[str, object]] = data.get("obligation", {})
    profile = (data.get("completion") or {}).get("profile", "full")

    nodes, edges = load_blueprint(root)
    statuses, errors = load_todo_statuses(root)

    if profile not in ("mvp", "full"):
        errors.append(f"completion.profile must be 'mvp' or 'full', not {profile!r}")
    for oid, row in sorted(obligations.items()):
        node = row.get("node")
        if node not in nodes:
            errors.append(f"{oid}: unknown node {node!r}")
        if row.get("milestone", "mvp") not in ("mvp", "post-mvp"):
            errors.append(f"{oid}: milestone must be 'mvp' or 'post-mvp'")
        gate = row.get("gate")
        if gate is not None and (not isinstance(gate, str) or not gate or gate.startswith("/")):
            errors.append(f"{oid}: gate must be a repo-relative path")
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
    active = {
        oid: row
        for oid, row in obligations.items()
        if profile == "full" or row.get("milestone", "mvp") == "mvp"
    }

    def deps_ready(node: str) -> bool:
        return all(
            node_status(dep, active, obligations, classification) in ("complete", "in-flight")
            for dep in edges.get(node, ())
        )

    complete = sorted(oid for oid in active if classification[oid] == "complete")
    in_flight = sorted(oid for oid in active if classification[oid] == "in-flight")
    blocked = sorted(oid for oid in active if classification[oid] == "blocked")
    ungenerated = sorted(oid for oid in active if classification[oid] == "ungenerated")
    first_incomplete = next(
        (oid for oid in sorted(active) if classification[oid] != "complete"),
        None,
    )
    next_obligation = next(
        (oid for oid in ungenerated if deps_ready(active[oid]["node"])),  # type: ignore[arg-type]
        None,
    )
    # The todo gate honours the profile: a todo whose every matrix reference
    # is outside the active profile is roadmap, not outstanding work. Unmapped
    # todos still gate, conservatively: the loop finishes what it opened.
    refs: dict[str, list[bool]] = {}
    for oid, row in obligations.items():
        for slug in row.get("satisfied_by", []):  # type: ignore[union-attr]
            refs.setdefault(slug, []).append(oid in active)
    gated = {
        slug: status
        for slug, status in statuses.items()
        if slug not in refs or any(refs[slug])
    }
    all_todos_done = bool(gated) and all(status == "done" for status in gated.values())
    # A row may pin an executable acceptance gate (dec.mvp-completion
    # clause 4). Presence is always machine-checked; --run-gates also
    # executes each present gate, and a non-zero exit holds exhaustion
    # false. The exhaustion decision point and the dry-run preflight run
    # with --run-gates, so neither prose nor a broken gate script can
    # stand in for the executable criterion.
    missing_gates = sorted(
        str(row["gate"])
        for row in active.values()
        if isinstance(row.get("gate"), str) and not (root / str(row["gate"])).is_file()
    )
    failing_gates: list[str] = []
    if args.run_gates:
        # Bounded and silent: gate output is discarded (nothing here reads
        # it, so it cannot grow memory) and a hung gate is a failed gate,
        # never a wedged completion check. COVERAGE_GATE_TIMEOUT seconds,
        # default 1800.
        try:
            gate_timeout = int(os.environ.get("COVERAGE_GATE_TIMEOUT", "1800"))
        except ValueError:
            gate_timeout = 1800
        for gate in sorted(
            {
                str(row["gate"])
                for row in active.values()
                if isinstance(row.get("gate"), str) and (root / str(row["gate"])).is_file()
            }
        ):
            try:
                done = subprocess.run(
                    [sys.executable, str(root / gate)],
                    cwd=root,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=gate_timeout,
                )
                failed = done.returncode != 0
            except (subprocess.TimeoutExpired, OSError):
                failed = True
            if failed:
                failing_gates.append(gate)
    loop_exhausted_valid = (
        not ungenerated and all_todos_done and not missing_gates and not failing_gates
    )
    print(
        json.dumps(
            {
                "schema": 1,
                "profile": profile,
                "complete": complete,
                "in_flight": in_flight,
                "blocked": blocked,
                "ungenerated": ungenerated,
                "outside_profile": sorted(oid for oid in obligations if oid not in active),
                "first_incomplete": first_incomplete,
                "next_obligation": next_obligation,
                "missing_gates": missing_gates,
                "failing_gates": failing_gates,
                "loop_exhausted_valid": loop_exhausted_valid,
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
