#!/usr/bin/env python3
"""Pure, fail-closed classification of observed Firth loop state.

The privileged observer owns command execution and forge authentication. This
module accepts its bounded observations, validates that forge pagination is
complete, reuses the selector's todo parser, and returns one closed schema-1
verdict without mutating the repository.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections.abc import Callable, Mapping, Sequence
from pathlib import Path
from typing import Any

from select_unit import FILENAME, SLUG, frontmatter_and_requires

NORMAL_BRANCH = re.compile(r"^loop/resolver\.([0-9a-f]{32})$")
INCIDENT = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
)
SCHEMA = 1
VERDICTS = {
    "fresh",
    "dirty-known-unit",
    "dirty-unsafe",
    "open-pr",
    "multiple-open-prs",
    "merged-tip-cleanup",
    "recover-todo",
    "surviving-adoptable",
    "surviving-orphan",
    "stale-park",
    "unsafe-committed-park",
    "observation-failed",
}


def collect_forge_pages(
    fetch_page: Callable[[str | None], Mapping[str, Any]], *, max_pages: int = 100
) -> dict[str, Any]:
    """Collect every forge page or return an explicit failed observation.

    ``fetch_page`` receives the opaque cursor from the previous page. An empty
    complete first page is success. Exceptions, malformed pages, cursor loops,
    and a page bound are failures, never an empty result.
    """

    cursor: str | None = None
    seen: set[str] = set()
    items: list[dict[str, Any]] = []
    try:
        for _ in range(max_pages):
            page = fetch_page(cursor)
            if not isinstance(page, Mapping):
                raise ValueError("forge page is not an object")
            raw_items = page.get("items")
            if not isinstance(raw_items, list) or not all(isinstance(item, dict) for item in raw_items):
                raise ValueError("forge page items must be an array of objects")
            items.extend(raw_items)
            next_cursor = page.get("next_cursor")
            if next_cursor is None:
                return {"complete": True, "items": items, "error": None}
            if not isinstance(next_cursor, str) or not next_cursor:
                raise ValueError("forge next_cursor must be a non-empty string or null")
            if next_cursor in seen:
                raise ValueError("forge pagination cursor repeated")
            seen.add(next_cursor)
            cursor = next_cursor
        raise ValueError(f"forge pagination exceeded {max_pages} pages")
    except Exception as error:  # Observer failures are data, not empty evidence.
        return {"complete": False, "items": [], "error": str(error)}


def load_todos(root: Path) -> tuple[dict[str, dict[str, Any]], list[str]]:
    """Parse todo identity/status with the selector's authoritative parser."""

    todo_dir = root / "meta" / "todos"
    errors: list[str] = []
    records: dict[str, dict[str, Any]] = {}
    if not todo_dir.is_dir():
        return {}, [f"missing todo directory: {todo_dir}"]
    for path in sorted(todo_dir.glob("todo.*.md")):
        match = FILENAME.fullmatch(path.name)
        if match is None:
            errors.append(f"{path}: filename must match todo.<slug>.md")
            continue
        slug = match.group(1)
        if SLUG.fullmatch(slug) is None:
            errors.append(f"{path}: invalid slug {slug!r}")
        try:
            fields, requires, parse_errors = frontmatter_and_requires(path)
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as error:
            errors.append(f"{path}: unreadable todo: {error}")
            continue
        errors.extend(parse_errors)
        status = fields.get("status")
        if status not in {"open", "in_progress", "done", "blocked"}:
            errors.append(f"{path}: missing or invalid status")
        records[slug] = {
            "node": fields.get("node"),
            "requires": requires,
            "status": status,
            "text": text,
        }
    return records, errors


def _failed(reason: str, *, errors: Sequence[str] = ()) -> dict[str, Any]:
    return {
        "schema": SCHEMA,
        "verdict": "observation-failed",
        "reason": reason,
        "errors": sorted(str(error) for error in errors),
    }


def _loop_slug(branch: str | None) -> str | None:
    if not isinstance(branch, str) or not branch.startswith("loop/"):
        return None
    slug = branch.removeprefix("loop/")
    return slug if SLUG.fullmatch(slug) else None

def _branch_unit(
    name: str, branch: Mapping[str, Any]
) -> tuple[str | None, str | None]:
    match = NORMAL_BRANCH.fullmatch(name)
    if match is None:
        return _loop_slug(name), None
    unit = branch.get("unit")
    incident_id = branch.get("incident_id")
    if (
        not isinstance(unit, str)
        or SLUG.fullmatch(unit) is None
        or not isinstance(incident_id, str)
        or INCIDENT.fullmatch(incident_id) is None
        or incident_id.replace("-", "") != match.group(1)
    ):
        return None, None
    return unit, incident_id


def _recover_target(slug: str) -> str | None:
    prefix = "recover-"
    return slug[len(prefix) :] if slug.startswith(prefix) else None


def _discard_authorised(text: str) -> bool:
    return any(
        line.strip().lower().startswith("maintainer-discard:")
        and line.split(":", 1)[1].strip().lower() in {"yes", "true", "authorised", "authorized"}
        for line in text.splitlines()
    )


def _normalise_prs(forge: Mapping[str, Any]) -> tuple[list[dict[str, Any]], list[str]]:
    errors: list[str] = []
    if forge.get("complete") is not True:
        errors.append(str(forge.get("error") or "forge observation incomplete"))
        return [], errors
    raw_items = forge.get("items")
    if not isinstance(raw_items, list):
        return [], ["forge items must be an array"]
    prs: list[dict[str, Any]] = []
    for index, item in enumerate(raw_items):
        if not isinstance(item, dict):
            errors.append(f"forge item {index} is not an object")
            continue
        branch = item.get("head_ref")
        state = item.get("state")
        head = item.get("head_sha")
        if not isinstance(branch, str) or _loop_slug(branch) is None:
            continue
        unit, incident_id = _branch_unit(branch, item)
        if (
            unit is None
            or state not in {"OPEN", "MERGED", "CLOSED"}
            or not isinstance(head, str)
            or not head
        ):
            errors.append(f"forge item {index} has invalid state, head, or binding")
            continue
        prs.append(
            {
                "head_ref": branch,
                "head_sha": head,
                "number": item.get("number"),
                "state": state,
                "unit": unit,
                "incident_id": incident_id,
            }
        )
    return prs, errors


def classify(
    observation: Mapping[str, Any] | Any, todos: Mapping[str, Mapping[str, Any]] | Any
) -> dict[str, Any]:
    """Return exactly one closed verdict for an immutable observation."""

    if not isinstance(observation, Mapping):
        return _failed("repository observation is not an object")
    if not isinstance(todos, Mapping) or not all(
        isinstance(slug, str) and isinstance(record, Mapping)
        for slug, record in todos.items()
    ):
        return _failed("todo observation is malformed")
    failures = observation.get("failures", [])
    if not isinstance(failures, list):
        return _failed("invalid observation failures", errors=["failures must be an array"])
    if failures:
        return _failed("one or more repository observations failed", errors=[str(value) for value in failures])

    forge = observation.get("forge")
    if not isinstance(forge, Mapping):
        return _failed("missing forge observation")
    prs, forge_errors = _normalise_prs(forge)
    if forge_errors:
        return _failed("forge observation failed", errors=forge_errors)

    main_head = observation.get("main_head")
    head = observation.get("head")
    current_branch = observation.get("current_branch")
    dirty = observation.get("dirty")
    raw_branches = observation.get("loop_branches")
    if (
        not isinstance(main_head, str)
        or not main_head
        or not isinstance(head, str)
        or not head
        or current_branch is not None
        and not isinstance(current_branch, str)
        or not isinstance(dirty, bool)
        or not isinstance(raw_branches, list)
    ):
        return _failed("repository observation is malformed")

    branches: list[dict[str, Any]] = []
    for index, branch in enumerate(raw_branches):
        if not isinstance(branch, Mapping):
            return _failed("repository observation is malformed", errors=[f"loop branch {index} is not an object"])
        name = branch.get("name")
        branch_head = branch.get("head")
        if not isinstance(name, str) or _loop_slug(name) is None or not isinstance(branch_head, str) or not branch_head:
            return _failed("repository observation is malformed", errors=[f"loop branch {index} is invalid"])
        unit, incident_id = _branch_unit(name, branch)
        if unit is None:
            return _failed("repository observation is malformed", errors=[f"loop branch {index} has invalid binding"])
        branches.append({"name": name, "head": branch_head, "unit": unit, "incident_id": incident_id})

    open_prs = sorted((pr for pr in prs if pr["state"] == "OPEN"), key=lambda pr: pr["head_ref"])
    if len(open_prs) > 1:
        return {
            "schema": SCHEMA,
            "verdict": "multiple-open-prs",
            "reason": "more than one open loop pull request",
            "branches": [pr["head_ref"] for pr in open_prs],
        }

    live_findings = observation.get("live_findings", [])
    backlog_modules = observation.get("backlog_modules", [])
    if not isinstance(live_findings, list) or not isinstance(backlog_modules, list):
        return _failed(
            "repository observation is malformed",
            errors=["live_findings and backlog_modules must be arrays"],
        )
    known_units = {
        slug for slug, record in todos.items() if record.get("status") in {"open", "in_progress"}
    }
    for value in live_findings:
        if isinstance(value, str) and SLUG.fullmatch(value):
            known_units.add(value)
    for value in backlog_modules:
        if isinstance(value, str) and value:
            known_units.add(f"backlog.{value}")

    branch_by_name = {branch["name"]: branch for branch in branches}
    current_record = branch_by_name.get(str(current_branch))
    current_unit = current_record.get("unit") if current_record else None
    if dirty:
        conflicts = [pr for pr in open_prs if pr["head_ref"] != current_branch]
        if (
            current_unit in known_units
            and current_record
            and current_record["incident_id"] is not None
            and current_record["head"] == head
            and not conflicts
        ):
            return {
                "schema": SCHEMA,
                "verdict": "dirty-known-unit",
                "reason": "dirty bytes are bound to the current known unit",
                "branch": current_branch,
                "slug": current_unit,
                "unit": current_unit,
                "incident_id": current_record["incident_id"],
                "head": head,
            }
        return {
            "schema": SCHEMA,
            "verdict": "dirty-unsafe",
            "reason": "dirty bytes are not uniquely bound to a credentialled incident",
            "branch": current_branch,
            "head": head,
        }

    recover_by_target: dict[str, Mapping[str, Any]] = {}
    for todo_slug, record in todos.items():
        target = _recover_target(todo_slug)
        if target is None:
            continue
        status = record.get("status")
        text = str(record.get("text", ""))
        if status != "done" or not _discard_authorised(text):
            recover_by_target[target] = record
    recovered = sorted(
        branch["name"]
        for branch in branches
        if branch["unit"] in recover_by_target
    )
    if recovered:
        return {
            "schema": SCHEMA,
            "verdict": "recover-todo",
            "reason": "a surviving branch is governed by a non-discharged recovery todo",
            "branch": recovered[0],
            "unit": branch_by_name[recovered[0]]["unit"],
            "incident_id": branch_by_name[recovered[0]].get("incident_id"),
        }

    if open_prs:
        pr = open_prs[0]
        branch = branch_by_name.get(pr["head_ref"])
        if pr["incident_id"] is None:
            return _failed("legacy open pull request requires resolver migration")
        if (
            branch is None
            or branch["head"] != pr["head_sha"]
            or branch["unit"] != pr["unit"]
            or branch["incident_id"] != pr["incident_id"]
        ):
            return _failed("open pull request head or binding does not match the observed local branch")
        return {
            "schema": SCHEMA,
            "verdict": "open-pr",
            "reason": "exactly one open loop pull request matches its local tip",
            "branch": pr["head_ref"],
            "head": pr["head_sha"],
            "pr": pr["number"],
            "unit": branch["unit"],
            "incident_id": branch.get("incident_id"),
        }

    merged = {
        (pr["head_ref"], pr["head_sha"], pr["unit"], pr["incident_id"])
        for pr in prs
        if pr["state"] == "MERGED"
    }
    cleanup = sorted(
        branch["name"]
        for branch in branches
        if (branch["name"], branch["head"], branch["unit"], branch["incident_id"]) in merged
    )
    if cleanup:
        return {
            "schema": SCHEMA,
            "verdict": "merged-tip-cleanup",
            "reason": "surviving branch tip exactly matches a merged pull request",
            "branch": cleanup[0],
            "head": branch_by_name[cleanup[0]]["head"],
            "unit": branch_by_name[cleanup[0]]["unit"],
            "incident_id": branch_by_name[cleanup[0]].get("incident_id"),
        }

    park = observation.get("park")
    if park is not None:
        if not isinstance(park, Mapping):
            return _failed("park observation is malformed")
        park_branch = park.get("branch")
        park_head = park.get("head")
        writer_present = park.get("writer_present")
        park_status_hash = park.get("status_hash")
        status_hash = observation.get("status_hash")
        park_unit, park_incident = _branch_unit(str(park_branch), park)
        if (
            not isinstance(park_branch, str)
            or _loop_slug(park_branch) is None
            or park_unit is None
            or not isinstance(park_head, str)
            or not park_head
            or not isinstance(writer_present, bool)
            or not isinstance(park_status_hash, str)
            or not isinstance(status_hash, str)
        ):
            return _failed("park observation is malformed")
        observed = branch_by_name.get(park_branch)
        if (
            writer_present
            or observed is None
            or observed["incident_id"] is None
            or observed["head"] != park_head
            or observed["unit"] != park_unit
            or observed["incident_id"] != park_incident
            or park_status_hash != status_hash
        ):
            return {
                "schema": SCHEMA,
                "verdict": "unsafe-committed-park",
                "reason": "park identity, bytes, or writer state does not match the observed branch",
                "branch": park_branch,
                "head": park_head,
            }
        return {
            "schema": SCHEMA,
            "verdict": "stale-park",
            "reason": "clean parked branch and status identities are stable with no writer",
            "branch": park_branch,
            "head": park_head,
            "unit": observed["unit"],
            "incident_id": observed.get("incident_id"),
        }

    if branches:
        branch = sorted(branches, key=lambda value: value["name"])[0]
        unit = branch["unit"]
        if unit in known_units and branch["incident_id"] is not None:
            return {
                "schema": SCHEMA,
                "verdict": "surviving-adoptable",
                "reason": "surviving incident branch maps to an open unit",
                "branch": branch["name"],
                "slug": unit,
                "unit": unit,
                "incident_id": branch["incident_id"],
                "head": branch["head"],
            }
        return {
            "schema": SCHEMA,
            "verdict": "surviving-orphan",
            "reason": "surviving branch has no credentialled incident and open unit binding",
            "branch": branch["name"],
            "head": branch["head"],
            "unit": branch["unit"],
            "incident_id": branch.get("incident_id"),
        }

    if head != main_head or current_branch not in {None, "main"}:
        return _failed("clean checkout is not current main and has no classified loop branch")
    return {
        "schema": SCHEMA,
        "verdict": "fresh",
        "reason": "clean current main has no surviving loop state",
        "head": head,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="classify observed Firth loop state")
    parser.add_argument("observation", nargs="?", help="JSON observation file; stdin when omitted")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    try:
        if args.observation:
            observation = json.loads(Path(args.observation).read_text(encoding="utf-8"))
        else:
            observation = json.load(sys.stdin)
    except (OSError, json.JSONDecodeError) as error:
        print(json.dumps(_failed("observation input failed", errors=[str(error)]), sort_keys=True))
        return 2
    todos, errors = load_todos(args.root)
    result = _failed("todo observation failed", errors=errors) if errors else classify(observation, todos)
    print(json.dumps(result, sort_keys=True))
    return 2 if result["verdict"] == "observation-failed" else 0


if __name__ == "__main__":
    sys.exit(main())
