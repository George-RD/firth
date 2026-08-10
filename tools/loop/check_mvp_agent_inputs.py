#!/usr/bin/env python3
"""Validate the model-facing MVP guide and interface inputs."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

import tomllib

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "tools" / "loop" / "mvp_agent_manifest.toml"
HASH = re.compile(r"^[0-9a-f]{64}$")
REQUIRED_ENTRY_POINTS = ("compile", "elaborate", "reference_run", "vm_run")
REQUIRED_GUIDE_HEADINGS = (
    "## 1. The programming model",
    "## 2. Lexical rules and source files",
    "## 3. Stack effects",
    "## 4. Body operations and quotations",
    "## 5. Refinements and proof obligations",
    "## 6. Deterministic diagnostics",
    "## 7. Elaboration, compilation, and execution workflow",
    "## 8. Worked applications",
)


class InputError(Exception):
    """A deterministic manifest or input violation."""


def fail(message: str) -> None:
    raise InputError(message)


def path_from_manifest(value: Any, field: str) -> tuple[str, Path]:
    if not isinstance(value, str) or not value or Path(value).is_absolute():
        fail(f"{field}: expected a non-empty relative path")
    path = (ROOT / value).resolve()
    try:
        path.relative_to(ROOT)
    except ValueError:
        fail(f"{field}: path escapes repository root")
    if not path.is_file():
        fail(f"{field}: missing file {value}")
    return value, path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def string_list(value: Any, field: str, *, nonempty: bool = True) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) and item for item in value):
        fail(f"{field}: expected a list of non-empty strings")
    if nonempty and not value:
        fail(f"{field}: expected at least one item")
    return value


def main() -> int:
    try:
        try:
            data = tomllib.loads(MANIFEST.read_text(encoding="utf-8"))
        except FileNotFoundError:
            fail("manifest: missing tools/loop/mvp_agent_manifest.toml")
        except (OSError, tomllib.TOMLDecodeError) as error:
            fail(f"manifest: invalid TOML ({error})")

        if type(data.get("manifest_version")) is not int or data["manifest_version"] != 1:
            fail("manifest_version: expected integer 1")
        if data.get("protocol_version") != "1.0":
            fail("protocol_version: expected 1.0")
        if data.get("language_version") != "0.1":
            fail("language_version: expected 0.1")
        if data.get("role") != "mvp-agent-input-and-provenance":
            fail("role: unexpected manifest role")
        if data.get("guide_path") != "docs/firth-agent-guide.md":
            fail("guide_path: unexpected guide location")
        if data.get("interface_root") != "src/agent/Firth/Agent":
            fail("interface_root: unexpected interface location")
        if data.get("gate_path") != "tools/loop/mvp_agent_gate.py":
            fail("gate_path: unexpected pinned gate")
        guide_value, guide_path = path_from_manifest(data.get("guide_path"), "guide_path")
        interface_root = (ROOT / "src/agent/Firth/Agent").resolve()
        if not interface_root.is_dir():
            fail("interface_root: missing directory")
        inputs = data.get("inputs")
        if not isinstance(inputs, dict):
            fail("inputs: expected a table")
        if inputs.get("model_only") is not True:
            fail("inputs.model_only: expected true")
        if inputs.get("guide_path") != guide_value:
            fail("inputs.guide_path: must equal guide_path")
        guide_hash = inputs.get("guide_sha256")
        if not isinstance(guide_hash, str) or not HASH.fullmatch(guide_hash):
            fail("inputs.guide_sha256: expected a lowercase SHA-256")
        actual_guide_hash = digest(guide_path)
        if guide_hash != actual_guide_hash:
            fail("inputs.guide_sha256: hash mismatch")

        interface_paths = string_list(inputs.get("interface_paths"), "inputs.interface_paths")
        interfaces = inputs.get("interface")
        if not isinstance(interfaces, list) or not interfaces:
            fail("inputs.interface: expected at least one table")
        if sorted(interface_paths) != sorted(
            item.get("path") for item in interfaces if isinstance(item, dict)
        ):
            fail("inputs.interface: paths must equal inputs.interface_paths")

        interface_hashes: dict[str, str] = {}
        for index, item in enumerate(interfaces):
            field = f"inputs.interface[{index}]"
            if not isinstance(item, dict):
                fail(f"{field}: expected a table")
            value, path = path_from_manifest(item.get("path"), f"{field}.path")
            try:
                path.relative_to(interface_root)
            except ValueError:
                fail(f"{field}.path: outside interface_root")
            if value not in interface_paths:
                fail(f"{field}.path: not listed in inputs.interface_paths")
            expected = item.get("sha256")
            if not isinstance(expected, str) or not HASH.fullmatch(expected):
                fail(f"{field}.sha256: expected a lowercase SHA-256")
            if not isinstance(item.get("role"), str) or not item["role"]:
                fail(f"{field}.role: expected a non-empty role")
            actual = digest(path)
            if expected != actual:
                fail(f"{field}.sha256: hash mismatch")
            interface_hashes[value] = actual
        if len(interface_hashes) != len(interface_paths):
            fail("inputs.interface: duplicate path")

        guide_text = guide_path.read_text(encoding="utf-8")
        for heading in REQUIRED_GUIDE_HEADINGS:
            if heading not in guide_text:
                fail(f"guide: missing required section {heading}")

        protocol = data.get("agent_protocol")
        if not isinstance(protocol, dict):
            fail("agent_protocol: expected a table")
        if protocol.get("schema_version") != "1.0":
            fail("agent_protocol.schema_version: expected 1.0")
        payload_kinds = string_list(protocol.get("payload_kinds"), "agent_protocol.payload_kinds")
        if payload_kinds != [
            "diagnostic",
            "typed_hole",
            "signature_search_request",
            "signature_search_response",
        ]:
            fail("agent_protocol.payload_kinds: unexpected order or value")
        if protocol.get("diagnostic_code_namespaces") != [
            "type",
            "linearity",
            "refinement",
            "elaboration",
            "syntax",
            "name",
            "search",
            "protocol",
        ]:
            fail("agent_protocol.diagnostic_code_namespaces: unexpected value")
        gamma = data.get("gamma")
        if not isinstance(gamma, dict):
            fail("gamma: expected a table")
        if gamma.get("version") != "0.1" or gamma.get("portable") is not True:
            fail("gamma: expected portable version 0.1")
        if gamma.get("primitives") != ["+", "send"]:
            fail("gamma.primitives: unexpected profile")
        if gamma.get("values") != ["Int", "Bool", "Handle", "Bytes", "World"]:
            fail("gamma.values: unexpected profile")
        if gamma.get("predicates") != ["positive", "nonzero", "is-open"]:
            fail("gamma.predicates: unexpected profile")
        if gamma.get("primitive") != {
            "+": {
                "effect": "Int^many Int^many -- Int^many",
                "transition": "deterministic-integer-addition",
                "observation": "pure",
            },
            "send": {
                "effect": "World^linear Handle^linear Bytes^linear -- World^linear",
                "transition": "deterministic-world-send",
                "observation": "world-threaded",
            },
        }:
            fail("gamma.primitive: incomplete primitive contract")
        if gamma.get("predicate") != {
            "positive": {
                "effect": "Int^many -- Bool^many",
                "purity": "pure",
                "totality": "required",
            },
            "nonzero": {
                "effect": "Int^many -- Bool^many",
                "purity": "pure",
                "totality": "required",
            },
            "is-open": {
                "effect": "Handle^many -- Bool^many",
                "purity": "pure",
                "totality": "required",
            },
        }:
            fail("gamma.predicate: incomplete predicate contract")

        comparison = data.get("comparison")
        expected_comparison = {
            "terminal_status": True,
            "bottom_to_top_stack": True,
            "trap_classification": True,
            "bounded_trace": True,
            "cost_report": True,
            "world_observation": True,
            "fuel_exhaustion": "bounded-fuel-inconclusive",
        }
        if comparison != expected_comparison:
            fail("comparison: agreement contract is incomplete or weakened")
        expected_schemas = {
            "firth.source.v1": {
                "version": "1.0",
                "encoding": "utf-8",
                "fields": [
                    "request_id:string",
                    "source_path:string",
                    "source_text:string",
                    "language_version:string",
                    "gamma_version:string",
                ],
            },
            "firth.elaboration.v1": {
                "version": "1.0",
                "encoding": "json",
                "fields": [
                    "request_id:string",
                    "status:success|failure",
                    "checked_words:array",
                    "erased_word_types:array",
                    "kernel_programs:array",
                    "warnings:array",
                    "diagnostics:array",
                ],
            },
            "firth.checked-kernel.v1": {
                "version": "1.0",
                "encoding": "json",
                "fields": [
                    "request_id:string",
                    "checked_words:array",
                    "erased_word_types:array",
                    "gamma_version:string",
                    "target_version:string",
                ],
            },
            "firth.target-program.v1": {
                "version": "1.0",
                "encoding": "json",
                "fields": [
                    "request_id:string",
                    "status:success|failure",
                    "target_program:object",
                    "word_digests:object",
                    "debug_locations:array",
                    "compile_error:object|null",
                ],
            },
            "firth.reference-execution.v1": {
                "version": "1.0",
                "encoding": "json",
                "fields": [
                    "request_id:string",
                    "checked_kernel:object",
                    "initial_stack:array",
                    "dictionary:object",
                    "gamma_version:string",
                    "fuel:nonnegative-integer",
                ],
            },
            "firth.vm-execution.v1": {
                "version": "1.0",
                "encoding": "json",
                "fields": [
                    "request_id:string",
                    "target_program:object",
                    "initial_stack:array",
                    "image:object",
                    "gamma_version:string",
                    "fuel:nonnegative-integer",
                ],
            },
            "firth.observation.v1": {
                "version": "1.0",
                "encoding": "json",
                "fields": [
                    "request_id:string",
                    "status:success|trap",
                    "stack:array",
                    "trace:array",
                    "cost:object",
                    "trap:string|null",
                    "world_observation:object|null",
                ],
            },
        }
        if data.get("schema") != expected_schemas:
            fail("schema: request and response schemas are incomplete or changed")



        entries = data.get("entry_point")
        if not isinstance(entries, dict) or set(entries) != set(REQUIRED_ENTRY_POINTS):
            fail("entry_point: expected exactly the four required entry points")
        required_contracts = {
            "elaborate": {
                "request": ["request_id", "source_path", "source_text", "language_version", "gamma_version"],
                "response": ["request_id", "status"],
            },
            "compile": {
                "request": ["request_id", "checked_words", "erased_word_types", "gamma_version", "target_version"],
                "response": ["request_id", "status"],
            },
            "reference_run": {
                "request": ["request_id", "checked_kernel", "initial_stack", "dictionary", "gamma_version", "fuel"],
                "response": ["request_id", "status", "stack", "trace", "cost", "trap", "world_observation"],
            },
            "vm_run": {
                "request": ["request_id", "target_program", "initial_stack", "image", "gamma_version", "fuel"],
                "response": ["request_id", "status", "stack", "trace", "cost", "trap", "world_observation"],
            },
        }
        for name in REQUIRED_ENTRY_POINTS:
            entry = entries[name]
            field = f"entry_point.{name}"
            if not isinstance(entry, dict):
                fail(f"{field}: expected a table")
            if entry.get("version") != "0.1":
                fail(f"{field}.version: expected 0.1")
            if not isinstance(entry.get("kind"), str) or not entry["kind"]:
                fail(f"{field}.kind: expected a non-empty kind")
            if entry.get("availability") != "gate-required":
                fail(f"{field}.availability: expected gate-required")
            if not isinstance(entry.get("adapter"), str) or not entry["adapter"]:
                fail(f"{field}.adapter: expected a non-empty adapter")
            if entry.get("transport") != "structured-json":
                fail(f"{field}.transport: expected structured-json")
            for direction in ("request", "response"):
                table = entry.get(direction)
                if not isinstance(table, dict):
                    fail(f"{field}.{direction}: expected a table")
                required = string_list(table.get("required"), f"{field}.{direction}.required")
                if required != required_contracts[name][direction]:
                    fail(f"{field}.{direction}.required: unexpected field set")
                schema_key = f"{direction}_schema"
                schema_name = entry.get(schema_key)
                if not isinstance(schema_name, str) or schema_name not in expected_schemas:
                    fail(f"{field}.{schema_key}: unknown schema")
                schema_fields = {
                    item.split(":", 1)[0]
                    for item in expected_schemas[schema_name]["fields"]
                }
                if not set(required).issubset(schema_fields):
                    fail(f"{field}.{direction}.required: field is absent from schema")
                for outcome in ("success", "failure"):
                    if outcome in table:
                        outcome_fields = string_list(
                            table[outcome], f"{field}.{direction}.{outcome}"
                        )
                        if not set(outcome_fields).issubset(schema_fields):
                            fail(f"{field}.{direction}.{outcome}: field is absent from schema")

        applications = data.get("applications")
        if not isinstance(applications, dict) or type(applications.get("minimum")) is not int:
            fail("applications.minimum: expected integer 3")
        if applications["minimum"] != 3:
            fail("applications.minimum: expected 3")
        if not isinstance(applications.get("entries"), list):
            fail("applications.entries: expected a list")

        result = {
            "application_count": len(applications["entries"]),
            "entry_points": list(REQUIRED_ENTRY_POINTS),
            "guide_sha256": actual_guide_hash,
            "interface_sha256": interface_hashes,
            "manifest": "tools/loop/mvp_agent_manifest.toml",
            "status": "ok",
        }
        print(json.dumps(result, sort_keys=True, separators=(",", ":")))
        return 0
    except (InputError, OSError, UnicodeError) as error:
        print(json.dumps({"error": str(error), "status": "error"}, sort_keys=True), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
