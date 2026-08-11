#!/usr/bin/env python3
"""Validate and select Firth todos without external dependencies."""

from __future__ import annotations

import argparse
import json
import re
import sys
import tomllib
from pathlib import Path

STATUSES = {"open", "in_progress", "done", "blocked"}
FILENAME = re.compile(r"^todo\.(.+)\.md$")
REQUIRES = re.compile(r"^\s*Requires:\s*(.*?)\s*$")
REQUIRES_HEADING = re.compile(r"^\s*#{1,6}\s+Requires\b.*$")
REQUIRES_LABEL = re.compile(r"^\s*Requires\b")
REQUIRES_DECL_BULLET = re.compile(r"^\s*[-*+]\s+Requires\b")
REQUIRES_DEP_BULLET = re.compile(r"^\s*[-*+]\s+`[A-Za-z0-9][A-Za-z0-9._-]*`")
SLUG = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def frontmatter_and_requires(path: Path) -> tuple[dict[str, str], list[str], list[str]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    errors: list[str] = []
    fields: dict[str, str] = {}
    if not lines or lines[0].strip() != "---":
        errors.append(f"{path}: missing YAML frontmatter")
        body_start = 0
    else:
        end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
        if end is None:
            errors.append(f"{path}: unterminated YAML frontmatter")
            body_start = len(lines)
        else:
            body_start = end + 1
            for line in lines[1:end]:
                if not line.strip() or line.lstrip().startswith("#"):
                    continue
                if ":" not in line:
                    # Unknown YAML values may legitimately continue as an
                    # indented list or multiline scalar. Only top-level
                    # malformed lines are violations.
                    if line and not line[0].isspace():
                        errors.append(f"{path}: invalid frontmatter line")
                    continue
                key, value = line.split(":", 1)
                key, value = key.strip(), value.strip()
                if not key:
                    errors.append(f"{path}: empty frontmatter key")
                else:
                    fields[key] = value.strip("\"'")
    requires: list[str] = []
    fenced = False
    requires_heading = False
    inline_requires_seen = False
    requires_continuation = False
    for line in lines[body_start:]:
        if line.strip().startswith(("```", "~~~")):
            fenced = not fenced
            continue
        if not fenced:
            if REQUIRES_HEADING.match(line):
                errors.append(
                    f"{path}: unsupported Requires heading/list format; "
                    "use inline `Requires: slug1 slug2`"
                )
                requires_heading = True
                continue
            if requires_heading and line.lstrip().startswith("#"):
                requires_heading = False
            elif requires_heading and REQUIRES_DEP_BULLET.match(line):
                errors.append(
                    f"{path}: unsupported Requires bullet-list format; "
                    "use inline `Requires: slug1 slug2`"
                )
                continue
            if (requires_heading or requires_continuation) and (
                REQUIRES_DEP_BULLET.match(line) or REQUIRES_DECL_BULLET.match(line)
            ):
                errors.append(
                    f"{path}: unsupported Requires bullet-list format; "
                    "use inline `Requires: slug1 slug2`"
                )
                continue
            if REQUIRES_DECL_BULLET.match(line):
                errors.append(
                    f"{path}: unsupported bullet Requires format; "
                    "use inline `Requires: slug1 slug2`"
                )
                continue
            match = REQUIRES.match(line)
            if match:
                if inline_requires_seen:
                    errors.append(
                        f"{path}: duplicate Requires declaration; "
                        "use one inline `Requires: slug1 slug2`"
                    )
                    continue
                raw = match.group(1).replace(",", " ")
                requires = [slug for slug in raw.split() if slug]
                inline_requires_seen = True
                requires_continuation = True
                continue
            if REQUIRES_LABEL.match(line):
                errors.append(
                    f"{path}: unsupported Requires format; "
                    "use inline `Requires: slug1 slug2`"
                )
            elif line.strip():
                requires_continuation = False
    return fields, requires, errors


def report(errors: list[str]) -> int:
    print(json.dumps({"schema": 1, "errors": sorted(errors)}, sort_keys=True))
    return 2


def outside_profile_slugs(root: Path, errors: list[str]) -> set[str]:
    """Slugs whose every obligations-matrix reference is outside the active
    completion profile (dec.mvp-completion). Such todos are roadmap, never
    selected. A missing matrix means no profile filtering; a malformed one
    is a validation error, fail closed. Unmapped todos are never filtered."""
    path = root / "tools" / "loop" / "obligations.toml"
    if not path.is_file():
        return set()
    try:
        with path.open("rb") as handle:
            data = tomllib.load(handle)
    except (tomllib.TOMLDecodeError, OSError) as error:
        errors.append(f"unreadable obligations matrix: {error}")
        return set()
    profile = (data.get("completion") or {}).get("profile", "full")
    if profile == "full":
        return set()
    refs: dict[str, list[bool]] = {}
    for row in data.get("obligation", {}).values():
        active = row.get("milestone", "mvp") == "mvp"
        for slug in row.get("satisfied_by", []):
            refs.setdefault(slug, []).append(active)
    return {slug for slug, flags in refs.items() if not any(flags)}


def main() -> int:
    parser = argparse.ArgumentParser(description="select eligible Firth todos")
    parser.add_argument("--validate", action="store_true", help="validate only")
    parser.add_argument("--node", help="filter todos by exact frontmatter node id")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    todo_dir = root / "meta" / "todos"
    errors: list[str] = []
    records: dict[str, dict[str, object]] = {}
    declared_slugs: set[str] = set()
    if not todo_dir.is_dir():
        return report([f"missing todo directory: {todo_dir}"])
    for path in sorted(todo_dir.glob("todo.*.md")):
        match = FILENAME.match(path.name)
        if not match:
            errors.append(f"{path}: filename must match todo.<slug>.md")
            continue
        slug = match.group(1)
        if not SLUG.fullmatch(slug):
            errors.append(f"{path}: invalid slug {slug!r}")
        fields, requires, parse_errors = frontmatter_and_requires(path)
        errors.extend(parse_errors)
        declared = fields.get("slug")
        if declared is not None:
            if declared != slug:
                errors.append(f"{path}: frontmatter slug {declared!r} does not match filename")
            if declared in declared_slugs:
                errors.append(f"duplicate slug: {declared}")
            declared_slugs.add(declared)
        if slug in records:
            errors.append(f"duplicate slug: {slug}")
        status = fields.get("status")
        if status not in STATUSES:
            errors.append(f"{path}: missing or invalid status")
        records[slug] = {"path": path, "status": status, "requires": requires, "node": fields.get("node")}
        if status == "blocked":
            # dec.loop-autonomy clause 3: a maintainer-blocked todo must
            # name what is outstanding in machine-findable form. Anything
            # else is a defect of the iteration that parked it, and the
            # split pattern (parent waiting on children) must instead stay
            # open with the children in Requires.
            body = path.read_text(encoding="utf-8")
            if not re.search(r"^\s*(External-evidence|Failing-check):", body, re.MULTILINE):
                errors.append(
                    f"{slug}: blocked without an External-evidence: or Failing-check: line"
                    " (loop-autonomy clause 3; split parents stay open with children in Requires)"
                )
    # Also catch markdown files in the directory that are not todo.<slug>.md.
    for path in sorted(todo_dir.glob("*.md")):
        if not FILENAME.fullmatch(path.name):
            errors.append(f"{path}: filename must match todo.<slug>.md")
    slugs = set(records)
    for slug, record in records.items():
        for required in record["requires"]:  # type: ignore[index]
            if required not in slugs:
                errors.append(f"{slug}: unknown Requires slug {required}")
    outside = outside_profile_slugs(root, errors)
    for slug, record in sorted(records.items()):
        if slug in outside or record["status"] == "done":
            continue
        for required in record["requires"]:  # type: ignore[index]
            if required in outside:
                errors.append(
                    f"{slug}: requires {required}, which is outside the active completion profile"
                )
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(slug: str, trail: list[str]) -> None:
        if slug in visiting:
            cycle = trail[trail.index(slug) :] + [slug]
            errors.append("Requires cycle: " + " -> ".join(cycle))
            return
        if slug in visited or slug not in records:
            return
        visiting.add(slug)
        for required in records[slug]["requires"]:  # type: ignore[index]
            visit(required, trail + [slug])
        visiting.remove(slug)
        visited.add(slug)

    for slug in sorted(records):
        visit(slug, [])
    if errors:
        return report(errors)
    if args.validate:
        print(json.dumps({"schema": 1, "valid": True}, sort_keys=True))
        return 0
    selected = {
        slug for slug, record in records.items()
        if args.node is None
        or record["node"] == args.node
        or (record["node"] or "").startswith(args.node + ".")
    }
    in_progress = sorted(
        slug for slug, r in records.items()
        if slug in selected and slug not in outside and r["status"] == "in_progress"
    )
    eligible: list[str] = []
    ineligible: list[dict[str, object]] = []
    blocked = sorted(
        slug for slug, r in records.items()
        if slug in selected and slug not in outside and r["status"] == "blocked"
    )
    for slug in sorted(records):
        if slug not in selected or slug in outside:
            continue
        record = records[slug]
        if record["status"] != "open":
            continue
        missing = sorted(required for required in record["requires"] if records[required]["status"] != "done")
        if missing:
            ineligible.append({"slug": slug, "missing": missing})
        else:
            eligible.append(slug)
    next_slug = in_progress[0] if in_progress else (eligible[0] if eligible else None)
    print(json.dumps({
        "schema": 1,
        "rule": "in_progress first, then eligible open todos by slug",
        "node": {slug: records[slug]["node"] for slug in sorted(records)},
        "eligible": eligible,
        "next": next_slug,
        "ineligible_open": ineligible,
        "outside_profile": sorted(slug for slug in outside if slug in selected),
        "blocked": blocked,
        "in_progress": in_progress,
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
