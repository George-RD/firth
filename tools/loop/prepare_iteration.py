#!/usr/bin/env python3
"""Deterministic normal-controller coordination around an OMP iteration.

This module has no Git, forge, host, or ticket-construction implementation. It
submits template requests to the state service, validates independently observed
responses, and emits the prepared envelope consumed by the Firth loop. The
state service derives protected effect fields and is the sole ticket issuer.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import unicodedata
import sys
import uuid
from collections.abc import Mapping
from pathlib import Path
from typing import Any, Protocol

SCHEMA = 1
NAMESPACE = "normal-iteration"
INSTALLED_ENVELOPE = Path("/run/firth/prepared-envelope.json")
INSTALLED_POLICY_PROJECTION = Path("/run/firth/authority-policy.projection.json")
PREPARE_TEMPLATES = (
    "normal.mirror.fetch",
    "normal.branch.create",
    "normal.worktree.create",
    "normal.lease.grant",
)
FINALISE_TEMPLATES = (
    "normal.finalise.seal",
    "normal.finalise.model-stop",
    "normal.finalise.acl-transfer",
    "normal.finalise.lease-acquire",
)
FINALISE_STAGES = {
    "normal.finalise.seal": "seal-requested",
    "normal.finalise.model-stop": "model-stopped",
    "normal.finalise.acl-transfer": "acl-transferred",
    "normal.finalise.lease-acquire": "lease-acquired",
}
SAFE_RECOVERY_VERDICTS = {
    "dirty-known-unit",
    "open-pr",
    "stale-park",
    "surviving-adoptable",
}
REFUSED_VERDICTS = {
    "dirty-unsafe",
    "multiple-open-prs",
    "merged-tip-cleanup",
    "recover-todo",
    "surviving-orphan",
    "unsafe-committed-park",
    "observation-failed",
}
SHA256 = re.compile(r"^[0-9a-f]{64}$")
EXPECTED_NORMAL_TEMPLATE_FIELDS = {
    "normal.mirror.fetch": {"repository_id", "policy_digest", "main_commit", "main_tree", "incident_id", "unit", "observation_generation", "observation_signature"},
    "normal.branch.create": {"repository_id", "policy_digest", "main_commit", "main_tree", "incident_id", "unit", "observation_generation", "observation_signature", "mirror_id", "branch"},
    "normal.worktree.create": {"repository_id", "policy_digest", "main_commit", "main_tree", "incident_id", "unit", "observation_generation", "observation_signature", "mirror_id", "branch", "head"},
    "normal.lease.grant": {"repository_id", "policy_digest", "main_commit", "main_tree", "incident_id", "unit", "observation_generation", "observation_signature", "mirror_id", "branch", "head", "worktree_id"},
    "normal.binding.verify": {"repository_id", "policy_digest", "main_commit", "main_tree", "incident_id", "unit", "observation_generation", "observation_signature", "branch", "head", "verdict"},
    "normal.finalise.seal": {"incident_id", "repository_id", "policy_digest", "unit", "branch", "head", "worktree_id", "container_id", "cgroup_id", "lease_epoch", "observation_generation", "observation_signature"},
    "normal.finalise.model-stop": {"incident_id", "repository_id", "policy_digest", "unit", "branch", "head", "worktree_id", "container_id", "cgroup_id", "lease_epoch", "observation_generation", "observation_signature"},
    "normal.finalise.acl-transfer": {"incident_id", "repository_id", "policy_digest", "unit", "branch", "head", "worktree_id", "container_id", "cgroup_id", "lease_epoch", "observation_generation", "observation_signature"},
    "normal.finalise.lease-acquire": {"incident_id", "repository_id", "policy_digest", "unit", "branch", "head", "worktree_id", "container_id", "cgroup_id", "lease_epoch", "observation_generation", "observation_signature"},
}
OBJECT_ID = re.compile(r"^[0-9a-f]{40,64}$")
UNIT = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


class StateClient(Protocol):
    def request(self, template_id: str, context: Mapping[str, Any]) -> Mapping[str, Any]: ...


class StableSnapshotter(Protocol):
    def snapshot(self, context: Mapping[str, Any]) -> Mapping[str, Any]: ...

class PreparationError(RuntimeError):
    """Closed refusal caused by missing, stale, or contradictory evidence."""


def _require_schema(value: Any, field: str) -> None:
    if not isinstance(value, int) or isinstance(value, bool) or value != SCHEMA:
        raise PreparationError(f"{field} schema mismatch")


def _require_text(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise PreparationError(f"missing or invalid {field}")
    return value


def _require_object_id(value: Any, field: str) -> str:
    text = _require_text(value, field)
    if OBJECT_ID.fullmatch(text) is None:
        raise PreparationError(f"invalid {field}")
    return text


def _require_digest(value: Any, field: str) -> str:
    text = _require_text(value, field)
    if SHA256.fullmatch(text) is None:
        raise PreparationError(f"invalid {field}")
    return text

def _require_incident(value: Any) -> str:
    text = _require_text(value, "incident_id")
    try:
        incident = uuid.UUID(text)
    except ValueError as error:
        raise PreparationError("invalid incident_id") from error
    if incident.version != 7 or str(incident) != text:
        raise PreparationError("incident_id must be a canonical UUIDv7")
    return text


def _normal_branch(incident_id: str) -> str:
    return f"loop/resolver.{incident_id.replace('-', '')}"




def _request(
    client: StateClient,
    template_id: str,
    context: Mapping[str, Any],
    *,
    previous_generation: int,
) -> tuple[dict[str, Any], int]:
    try:
        response = client.request(template_id, dict(context))
    except Exception as error:
        raise PreparationError(f"{template_id}: state request failed: {error}") from error
    if not isinstance(response, Mapping):
        raise PreparationError(f"{template_id}: state response is not an object")
    response_schema = response.get("schema")
    if (
        not isinstance(response_schema, int)
        or isinstance(response_schema, bool)
        or response_schema != SCHEMA
    ):
        raise PreparationError(f"{template_id}: unsupported state schema")
    if response.get("namespace") != NAMESPACE:
        raise PreparationError(f"{template_id}: wrong issuer namespace")
    if response.get("template_id") != template_id:
        raise PreparationError(f"{template_id}: response template mismatch")
    if response.get("status") != "observed":
        raise PreparationError(f"{template_id}: protected effect is not independently observed")
    generation = response.get("generation")
    if not isinstance(generation, int) or isinstance(generation, bool) or generation != previous_generation + 1:
        raise PreparationError(f"{template_id}: observation generation is not the next generation")
    _require_digest(response.get("observation_signature"), f"{template_id} observation_signature")
    if template_id in FINALISE_TEMPLATES:
        _require_digest(response.get("receipt_id"), f"{template_id} attestation receipt_id")
    else:
        _require_text(response.get("receipt_id"), f"{template_id} receipt_id")
    objects = response.get("objects")
    if not isinstance(objects, Mapping):
        raise PreparationError(f"{template_id}: missing observed objects")
    fields = EXPECTED_NORMAL_TEMPLATE_FIELDS.get(template_id)
    if fields is None:
        raise PreparationError(f"{template_id}: unknown transition template")
    for field in fields:
        if field not in context:
            raise PreparationError(f"{template_id}: request omitted bound field {field}")
        if template_id == "normal.finalise.lease-acquire" and field == "lease_epoch":
            continue
        if objects.get(field) != context[field]:
            raise PreparationError(f"{template_id}: observed {field} does not match request identity")
    if template_id == "normal.finalise.lease-acquire":
        lease_epoch = objects.get("lease_epoch")
        expected_epoch = context.get("lease_epoch")
        if (
            not isinstance(lease_epoch, int)
            or isinstance(lease_epoch, bool)
            or not isinstance(expected_epoch, int)
            or isinstance(expected_epoch, bool)
            or lease_epoch != expected_epoch + 1
        ):
            raise PreparationError(f"{template_id}: observed lease epoch is not the next epoch")
    return dict(response), generation


def _base_context(request: Mapping[str, Any], unit: str) -> dict[str, Any]:
    repository_id = _require_text(request.get("repository_id"), "repository_id")
    policy_digest = _require_digest(request.get("policy_digest"), "policy_digest")
    main_commit = _require_object_id(request.get("main_commit"), "main_commit")
    main_tree = _require_object_id(request.get("main_tree"), "main_tree")
    generation = request.get("observation_generation")
    if not isinstance(generation, int) or isinstance(generation, bool) or generation < 0:
        raise PreparationError("invalid observation_generation")
    signature = _require_digest(request.get("observation_signature"), "observation_signature")
    incident_id = _require_incident(request.get("incident_id"))
    return {
        "repository_id": repository_id,
        "policy_digest": policy_digest,
        "main_commit": main_commit,
        "main_tree": main_tree,
        "incident_id": incident_id,
        "unit": unit,
        "observation_generation": generation,
        "observation_signature": signature,
    }


def _selected_unit(selector: Mapping[str, Any]) -> str:
    schema = selector.get("schema")
    if not isinstance(schema, int) or isinstance(schema, bool) or schema != SCHEMA:
        raise PreparationError("selector schema mismatch")
    unit = selector.get("next")
    if not isinstance(unit, str) or UNIT.fullmatch(unit) is None:
        raise PreparationError("selector did not produce one valid unit")
    return unit


def _assert_equal(objects: Mapping[str, Any], expected: Mapping[str, Any], template_id: str) -> None:
    for field, value in expected.items():
        if objects.get(field) != value:
            raise PreparationError(f"{template_id}: observed {field} does not match prepared identity")

def _continued_context(
    context: Mapping[str, Any], response: Mapping[str, Any], generation: int
) -> dict[str, Any]:
    return {
        **context,
        "observation_generation": generation,
        "observation_signature": _require_digest(
            response.get("observation_signature"), "continuation observation_signature"
        ),
    }

def _canonical_projection_bytes(value: Any) -> bytes:
    if isinstance(value, float):
        raise PreparationError("installed policy projection contains a floating-point value")
    if value is None or isinstance(value, (bool, int, str)):
        return json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    if isinstance(value, list):
        return b"[" + b",".join(_canonical_projection_bytes(item) for item in value) + b"]"
    if isinstance(value, Mapping):
        if not all(isinstance(key, str) for key in value):
            raise PreparationError("installed policy projection contains a non-string key")
        return (
            b"{"
            + b",".join(
                _canonical_projection_bytes(key) + b":" + _canonical_projection_bytes(value[key])
                for key in sorted(value)
            )
            + b"}"
        )
    raise PreparationError("installed policy projection contains an unsupported value")

def _domain_digest(kind: str, value: Any) -> str:
    return hashlib.sha256(
        f"firth-resolver/v1/{kind}\0".encode("ascii")
        + _canonical_projection_bytes(value)
    ).hexdigest()

def _projection_pairs(values: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in values:
        if key in result:
            raise PreparationError(f"installed policy projection has duplicate key: {key}")
        result[key] = value
    return result


def _reject_projection_float(_value: str) -> Any:
    raise PreparationError("installed policy projection contains a floating-point value")


def _validate_projection_values(value: Any, path: str = "$") -> None:
    if value is None or isinstance(value, bool):
        return
    if isinstance(value, int):
        if abs(value) > (1 << 53) - 1:
            raise PreparationError(f"installed policy projection integer out of range at {path}")
        return
    if isinstance(value, str):
        if unicodedata.normalize("NFC", value) != value:
            raise PreparationError(f"installed policy projection non-NFC string at {path}")
        return
    if isinstance(value, list):
        for index, item in enumerate(value):
            _validate_projection_values(item, f"{path}[{index}]")
        return
    if isinstance(value, Mapping):
        for key, item in value.items():
            _validate_projection_values(key, f"{path}.<key>")
            _validate_projection_values(item, f"{path}.{key}")
        return
    raise PreparationError(f"installed policy projection unsupported value at {path}")


def _validate_policy_projection(projection: Mapping[str, Any]) -> None:
    allowed = {
        "schema",
        "kind",
        "policy_version",
        "policy_digest",
        "projection_digest",
        "repository_id",
        "operator_repository_id",
        "issuer_namespaces",
        "merge_classes",
        "path_classes",
        "completion_tcb",
        "normal_templates",
    }
    if set(projection) != allowed:
        raise PreparationError("installed policy projection shape is invalid")
    digest = _require_digest(projection.get("projection_digest"), "projection_digest")
    unsigned = dict(projection)
    del unsigned["projection_digest"]
    actual = hashlib.sha256(_canonical_projection_bytes(unsigned)).hexdigest()
    if actual != digest:
        raise PreparationError("installed policy projection digest mismatch")
    policy_version = projection.get("policy_version")
    if not isinstance(policy_version, int) or isinstance(policy_version, bool) or policy_version != 1:
        raise PreparationError("installed policy version is unsupported")
    if projection.get("operator_repository_id") != "George-RD/georges-devops":
        raise PreparationError("installed operator repository identity mismatch")
    if projection.get("issuer_namespaces") != [
        "normal-iteration",
        "halted-recovery",
        "local-operator",
    ]:
        raise PreparationError("installed issuer namespace projection mismatch")
    if projection.get("merge_classes") != [
        "normal-auto",
        "resolver-auto",
        "auto-operator",
        "protected-human",
        "manual-root",
    ]:
        raise PreparationError("installed merge class projection mismatch")
    completion = projection.get("completion_tcb")
    if (
        not isinstance(completion, Mapping)
        or completion.get("exclusive_command") != "python3 tools/loop/coverage.py --run-gates"
        or completion.get("terminal_token") != "LOOP EXHAUSTED"
    ):
        raise PreparationError("installed completion TCB projection mismatch")
    templates = projection.get("normal_templates")
    if not isinstance(templates, Mapping) or set(templates) != set(EXPECTED_NORMAL_TEMPLATE_FIELDS):
        raise PreparationError("installed normal template set mismatch")
    for template_id, expected in EXPECTED_NORMAL_TEMPLATE_FIELDS.items():
        template = templates.get(template_id)
        if (
            not isinstance(template, Mapping)
            or template.get("namespace") != NAMESPACE
            or template.get("max_invocations") != 1
            or template.get("retry") not in {"never", "reconcile-only"}
            or set(template.get("input_fields", [])) != expected
        ):
            raise PreparationError(f"installed template {template_id} mismatch")


def prepare_iteration(
    request: Mapping[str, Any],
    preflight: Mapping[str, Any],
    selector: Mapping[str, Any],
    client: StateClient,
) -> dict[str, Any]:
    """Prepare or verify one iteration and return its immutable launch envelope."""
    if not isinstance(request, Mapping) or not isinstance(preflight, Mapping) or not isinstance(selector, Mapping):
        raise PreparationError("preparation inputs must be objects")
    policy_projection = load_installed_policy_projection()
    if (
        policy_projection.get("schema") != SCHEMA
        or policy_projection.get("kind") != "firth-authority-policy-projection"
    ):
        raise PreparationError("installed policy projection is invalid")
    _validate_policy_projection(policy_projection)
    if request.get("repository_id") != policy_projection.get("repository_id"):
        raise PreparationError("request repository identity does not match installed policy")
    if request.get("policy_digest") != policy_projection.get("policy_digest"):
        raise PreparationError("request policy digest does not match installed policy")
    preflight_schema = preflight.get("schema")
    if (
        not isinstance(preflight_schema, int)
        or isinstance(preflight_schema, bool)
        or preflight_schema != SCHEMA
    ):
        raise PreparationError("preflight schema mismatch")
    verdict = preflight.get("verdict")
    if not isinstance(verdict, str) or verdict not in {
        "fresh", *SAFE_RECOVERY_VERDICTS, *REFUSED_VERDICTS
    }:
        raise PreparationError("unknown preflight verdict")
    if verdict in REFUSED_VERDICTS:
        raise PreparationError(f"preflight verdict {verdict} refuses normal launch")

    unit = _selected_unit(selector)
    base = _base_context(request, unit)
    generation = int(base["observation_generation"])
    receipts: list[str] = []

    if verdict in SAFE_RECOVERY_VERDICTS:
        branch = _require_text(preflight.get("branch"), "preflight branch")
        if preflight.get("unit") != unit:
            raise PreparationError("recovered binding does not match selected unit")
        if preflight.get("incident_id") != base["incident_id"]:
            raise PreparationError("recovered incident does not match prepared incident")
        if branch != _normal_branch(str(base["incident_id"])):
            raise PreparationError("recovered branch does not match prepared incident")
        head = _require_object_id(preflight.get("head"), "preflight head")
        verify_context = {**base, "branch": branch, "head": head, "verdict": verdict}
        response, generation = _request(
            client, "normal.binding.verify", verify_context, previous_generation=generation
        )
        objects = response["objects"]
        assert isinstance(objects, Mapping)
        _assert_equal(
            objects,
            {
                "repository_id": base["repository_id"],
                "policy_digest": base["policy_digest"],
                "unit": unit,
                "branch": branch,
                "head": head,
                "metadata_read_only": True,
                "writer": "model",
            },
            "normal.binding.verify",
        )
        worktree_id = _require_text(objects.get("worktree_id"), "worktree_id")
        lease_epoch = objects.get("lease_epoch")
        if not isinstance(lease_epoch, int) or isinstance(lease_epoch, bool) or lease_epoch < 1:
            raise PreparationError("normal.binding.verify: invalid lease_epoch")
        container_id = _require_text(objects.get("container_id"), "container_id")
        cgroup_id = _require_text(objects.get("cgroup_id"), "cgroup_id")
        receipts.append(str(response["receipt_id"]))
        final_signature = response["observation_signature"]
    elif preflight.get("head") != base["main_commit"]:
        raise PreparationError("fresh preflight head does not match observed main")
    else:
        branch = _normal_branch(str(base["incident_id"]))
        context: dict[str, Any] = dict(base)

        mirror, generation = _request(
            client, PREPARE_TEMPLATES[0], context, previous_generation=generation
        )
        mirror_objects = mirror["objects"]
        assert isinstance(mirror_objects, Mapping)
        _assert_equal(
            mirror_objects,
            {
                "repository_id": base["repository_id"],
                "policy_digest": base["policy_digest"],
                "main_commit": base["main_commit"],
                "main_tree": base["main_tree"],
            },
            PREPARE_TEMPLATES[0],
        )
        mirror_id = _require_text(mirror_objects.get("mirror_id"), "mirror_id")
        receipts.append(str(mirror["receipt_id"]))

        context = _continued_context(
            {**base, "mirror_id": mirror_id, "branch": branch}, mirror, generation
        )
        created, generation = _request(
            client, PREPARE_TEMPLATES[1], context, previous_generation=generation
        )
        created_objects = created["objects"]
        assert isinstance(created_objects, Mapping)
        _assert_equal(
            created_objects,
            {
                "repository_id": base["repository_id"],
                "policy_digest": base["policy_digest"],
                "branch": branch,
                "head": base["main_commit"],
                "base_commit": base["main_commit"],
                "mirror_id": mirror_id,
            },
            PREPARE_TEMPLATES[1],
        )
        head = _require_object_id(created_objects.get("head"), "branch head")
        receipts.append(str(created["receipt_id"]))

        context = _continued_context(
            {**context, "head": head}, created, generation
        )
        linked, generation = _request(
            client, PREPARE_TEMPLATES[2], context, previous_generation=generation
        )
        linked_objects = linked["objects"]
        assert isinstance(linked_objects, Mapping)
        _assert_equal(
            linked_objects,
            {
                "repository_id": base["repository_id"],
                "policy_digest": base["policy_digest"],
                "branch": branch,
                "head": head,
                "metadata_read_only": True,
            },
            PREPARE_TEMPLATES[2],
        )
        worktree_id = _require_text(linked_objects.get("worktree_id"), "worktree_id")
        receipts.append(str(linked["receipt_id"]))

        context = _continued_context(
            {
                **context,
                "worktree_id": worktree_id,
            },
            linked,
            generation,
        )
        leased, generation = _request(
            client, PREPARE_TEMPLATES[3], context, previous_generation=generation
        )
        leased_objects = leased["objects"]
        assert isinstance(leased_objects, Mapping)
        _assert_equal(
            leased_objects,
            {
                "repository_id": base["repository_id"],
                "policy_digest": base["policy_digest"],
                "branch": branch,
                "head": head,
                "worktree_id": worktree_id,
                "metadata_read_only": True,
                "writer": "model",
            },
            PREPARE_TEMPLATES[3],
        )
        lease_epoch = leased_objects.get("lease_epoch")
        if not isinstance(lease_epoch, int) or isinstance(lease_epoch, bool) or lease_epoch < 1:
            raise PreparationError("normal.lease.grant: invalid lease_epoch")
        container_id = _require_text(leased_objects.get("container_id"), "container_id")
        cgroup_id = _require_text(leased_objects.get("cgroup_id"), "cgroup_id")
        receipts.append(str(leased["receipt_id"]))
        final_signature = leased["observation_signature"]

    return {
        "schema": SCHEMA,
        "kind": "firth-prepared-iteration",
        "namespace": NAMESPACE,
        "repository_id": base["repository_id"],
        "policy_digest": base["policy_digest"],
        "incident_id": base["incident_id"],
        "unit": unit,
        "branch": branch,
        "base_commit": base["main_commit"],
        "base_tree": base["main_tree"],
        "head": head,
        "worktree_id": worktree_id,
        "container_id": container_id,
        "cgroup_id": cgroup_id,
        "lease_epoch": lease_epoch,
        "metadata_read_only": True,
        "writer": "model",
        "generation": generation,
        "observation_signature": _require_digest(final_signature, "prepared observation_signature"),
        "receipts": receipts,
        "finalise_tool": "firth_finalize",
        "finalise_arguments": [],
    }



def validate_prepared_envelope(
    envelope: Mapping[str, Any] | Any,
    policy_projection: Mapping[str, Any] | Any,
) -> dict[str, Any]:
    """Validate the issuer-bound launch identity without performing an effect."""
    if not isinstance(envelope, Mapping):
        raise PreparationError("prepared envelope must be an object")
    envelope_schema = envelope.get("schema")
    if (
        not isinstance(envelope_schema, int)
        or isinstance(envelope_schema, bool)
        or envelope_schema != SCHEMA
        or envelope.get("kind") != "firth-prepared-iteration"
    ):
        raise PreparationError("invalid prepared envelope")
    if envelope.get("namespace") != NAMESPACE:
        raise PreparationError("prepared envelope namespace mismatch")
    if envelope.get("finalise_arguments") != [] or envelope.get("finalise_tool") != "firth_finalize":
        raise PreparationError("prepared envelope does not bind the no-argument finaliser")
    unit = _require_text(envelope.get("unit"), "unit")
    if UNIT.fullmatch(unit) is None:
        raise PreparationError("invalid prepared unit")
    incident_id = _require_incident(envelope.get("incident_id"))
    branch = _require_text(envelope.get("branch"), "branch")
    if branch != _normal_branch(incident_id):
        raise PreparationError("prepared incident and branch mismatch")
    lease_epoch = envelope.get("lease_epoch")
    generation = envelope.get("generation")
    if not isinstance(lease_epoch, int) or isinstance(lease_epoch, bool) or lease_epoch < 1:
        raise PreparationError("invalid prepared lease_epoch")
    if not isinstance(generation, int) or isinstance(generation, bool) or generation < 1:
        raise PreparationError("invalid prepared generation")
    receipts = envelope.get("receipts")
    if not isinstance(receipts, list) or not receipts or not all(
        isinstance(receipt, str) and receipt for receipt in receipts
    ):
        raise PreparationError("invalid prepared receipts")
    result = {
        "schema": SCHEMA,
        "kind": "firth-prepared-iteration",
        "namespace": NAMESPACE,
        "repository_id": _require_text(envelope.get("repository_id"), "repository_id"),
        "policy_digest": _require_digest(envelope.get("policy_digest"), "policy_digest"),
        "incident_id": incident_id,
        "unit": unit,
        "branch": branch,
        "base_commit": _require_object_id(envelope.get("base_commit"), "base_commit"),
        "base_tree": _require_object_id(envelope.get("base_tree"), "base_tree"),
        "head": _require_object_id(envelope.get("head"), "head"),
        "worktree_id": _require_text(envelope.get("worktree_id"), "worktree_id"),
        "container_id": _require_text(envelope.get("container_id"), "container_id"),
        "cgroup_id": _require_text(envelope.get("cgroup_id"), "cgroup_id"),
        "lease_epoch": lease_epoch,
        "metadata_read_only": envelope.get("metadata_read_only"),
        "writer": envelope.get("writer"),
        "generation": generation,
        "observation_signature": _require_digest(
            envelope.get("observation_signature"), "observation_signature"
        ),
        "receipts": list(receipts),
        "finalise_tool": "firth_finalize",
        "finalise_arguments": [],
    }
    if result["metadata_read_only"] is not True or result["writer"] != "model":
        raise PreparationError("prepared worktree authority is invalid")
    if not isinstance(policy_projection, Mapping):
        raise PreparationError("installed policy projection must be an object")
    projection_schema = policy_projection.get("schema")
    if (
        not isinstance(projection_schema, int)
        or isinstance(projection_schema, bool)
        or projection_schema != SCHEMA
        or policy_projection.get("kind") != "firth-authority-policy-projection"
    ):
        raise PreparationError("installed policy projection is invalid")
    _validate_policy_projection(policy_projection)
    if policy_projection.get("repository_id") != result["repository_id"]:
        raise PreparationError("installed policy repository identity mismatch")
    if policy_projection.get("policy_digest") != result["policy_digest"]:
        raise PreparationError("installed policy digest mismatch")
    namespaces = policy_projection.get("issuer_namespaces")
    if not isinstance(namespaces, list) or NAMESPACE not in namespaces:
        raise PreparationError("installed policy omits the normal issuer namespace")
    return result



def load_installed_policy_projection() -> Mapping[str, Any]:
    try:
        projection = json.loads(
            INSTALLED_POLICY_PROJECTION.read_text(encoding="utf-8"),
            object_pairs_hook=_projection_pairs,
            parse_float=_reject_projection_float,
        )
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise PreparationError(f"installed policy projection unavailable: {error}") from error
    if not isinstance(projection, Mapping):
        raise PreparationError("installed policy projection must be an object")
    _validate_projection_values(projection)
    return projection


def finalise_iteration(
    envelope: Mapping[str, Any], client: StateClient, snapshotter: StableSnapshotter
) -> dict[str, Any]:
    """Seal one prepared unit, transfer its lease, then snapshot without authority.

    The public tool supplies no arguments. Its issuer-bound session injects the
    complete envelope, state client, and fixed no-authority snapshot helper.
    """
    envelope = validate_prepared_envelope(envelope, load_installed_policy_projection())

    context = {
        "incident_id": _require_incident(envelope.get("incident_id")),
        "repository_id": _require_text(envelope.get("repository_id"), "repository_id"),
        "policy_digest": _require_digest(envelope.get("policy_digest"), "policy_digest"),
        "unit": _require_text(envelope.get("unit"), "unit"),
        "branch": _require_text(envelope.get("branch"), "branch"),
        "base_commit": _require_object_id(envelope.get("base_commit"), "base_commit"),
        "base_tree": _require_object_id(envelope.get("base_tree"), "base_tree"),
        "head": _require_object_id(envelope.get("head"), "head"),
        "worktree_id": _require_text(envelope.get("worktree_id"), "worktree_id"),
        "container_id": _require_text(envelope.get("container_id"), "container_id"),
        "cgroup_id": _require_text(envelope.get("cgroup_id"), "cgroup_id"),
        "lease_epoch": envelope.get("lease_epoch"),
        "observation_generation": envelope.get("generation"),
        "observation_signature": _require_digest(
            envelope.get("observation_signature"), "observation_signature"
        ),
    }
    if context["branch"] != _normal_branch(str(context["incident_id"])):
        raise PreparationError("prepared incident and branch mismatch")
    if not isinstance(context["lease_epoch"], int) or isinstance(context["lease_epoch"], bool):
        raise PreparationError("invalid prepared lease_epoch")
    generation = envelope.get("generation")
    if not isinstance(generation, int) or isinstance(generation, bool) or generation < 1:
        raise PreparationError("invalid prepared generation")

    receipts: list[str] = []
    transition_attestations: list[dict[str, Any]] = []
    last: Mapping[str, Any] | None = None
    state_receipt: Mapping[str, Any] | None = None
    model_response: Mapping[str, Any] | None = None
    model_objects: Mapping[str, Any] | None = None
    worktree_response: Mapping[str, Any] | None = None
    worktree_objects: Mapping[str, Any] | None = None
    for template_id in FINALISE_TEMPLATES:
        response, generation = _request(client, template_id, context, previous_generation=generation)
        objects = response["objects"]
        assert isinstance(objects, Mapping)
        common_identity = {
            "repository_id": context["repository_id"],
            "policy_digest": context["policy_digest"],
            "unit": context["unit"],
            "branch": context["branch"],
            "worktree_id": context["worktree_id"],
        }
        stage_attestation = response.get("stage_attestation")
        if (
            not isinstance(stage_attestation, Mapping)
            or stage_attestation.get("schema")
            != "firth.state-transition-attestation.v1"
            or stage_attestation.get("source") != "installed-state"
        ):
            raise PreparationError(f"{template_id} state stage attestation is missing")
        expected_stage_attestation = {
            "namespace": NAMESPACE,
            "repository_id": context["repository_id"],
            "policy_digest": context["policy_digest"],
            "incident_id": context["incident_id"],
            "unit": context["unit"],
            "branch": context["branch"],
            "worktree_id": context["worktree_id"],
            "template_id": template_id,
            "stage": FINALISE_STAGES[template_id],
            "generation": generation,
            "observation_signature": response["observation_signature"],
            "receipt_id": response["receipt_id"],
        }
        for field, value in expected_stage_attestation.items():
            if stage_attestation.get(field) != value:
                raise PreparationError(
                    f"{template_id} state stage attestation {field} mismatch"
                )
        _require_digest(
            stage_attestation.get("receipt_id"),
            f"{template_id} state stage receipt_id",
        )
        if template_id == "normal.finalise.lease-acquire":
            _assert_equal(objects, common_identity, template_id)
            head = _require_object_id(objects.get("head"), "post-model head")
            head_tree = _require_object_id(objects.get("head_tree"), "post-model head_tree")
            lease_epoch = objects.get("lease_epoch")
            if (
                objects.get("lease_holder") != "broker"
                or objects.get("writer_present") is not False
                or objects.get("model_write_access") is not False
                or objects.get("broker_write_access") is not True
                or not isinstance(lease_epoch, int)
                or isinstance(lease_epoch, bool)
                or lease_epoch != context["lease_epoch"] + 1
            ):
                raise PreparationError("broker lease was not exclusively acquired at the next epoch")
            state_receipt = response.get("finaliser_receipt")
            if not isinstance(state_receipt, Mapping):
                raise PreparationError("state finaliser receipt is missing")
            expected_state_receipt = {
                "schema": "firth.state-finaliser-receipt.v1",
                "namespace": NAMESPACE,
                "repository_id": context["repository_id"],
                "incident_id": context["incident_id"],
                "unit": context["unit"],
                "branch": context["branch"],
                "worktree_id": context["worktree_id"],
                "head_commit": head,
                "head_tree": head_tree,
                "lease_epoch": lease_epoch,
                "observation_generation": generation,
                "observation_signature": response["observation_signature"],
                "stage": "lease-acquired",
                "policy_digest": context["policy_digest"],
            }
            for field, value in expected_state_receipt.items():
                if state_receipt.get(field) != value:
                    raise PreparationError(f"state finaliser receipt {field} mismatch")
            _require_digest(state_receipt.get("receipt_id"), "state finaliser receipt_id")
            prospective_chain = [
                *transition_attestations,
                dict(stage_attestation),
            ]
            transition_chain_digest = hashlib.sha256(
                _canonical_projection_bytes(prospective_chain)
            ).hexdigest()
            if state_receipt.get("transition_chain_digest") != transition_chain_digest:
                raise PreparationError("state finaliser transition chain digest mismatch")
            state_receipt_body = {
                key: value
                for key, value in state_receipt.items()
                if key != "receipt_id"
            }
            if state_receipt["receipt_id"] != _domain_digest(
                "finaliser_receipt", state_receipt_body
            ):
                raise PreparationError("state finaliser receipt digest mismatch")
            worktree_response = response
            worktree_objects = objects
            context = {
                **_continued_context(context, response, generation),
                "head": head,
                "head_tree": head_tree,
                "lease_epoch": lease_epoch,
            }
        else:
            _assert_equal(
                objects,
                {**common_identity, "head": context["head"], "lease_epoch": context["lease_epoch"]},
                template_id,
            )
            if template_id == "normal.finalise.model-stop" and (
                objects.get("container_id") != context["container_id"]
                or objects.get("cgroup_id") != context["cgroup_id"]
                or objects.get("writer_present") is not False
                or objects.get("cgroup_stopped") is not True
                or objects.get("descendant_count") != 0
            ):
                raise PreparationError("model stop and descendant termination were not independently observed")
            if template_id == "normal.finalise.acl-transfer" and (
                objects.get("writer") != "broker"
                or objects.get("model_write_access") is not False
                or objects.get("broker_write_access") is not True
            ):
                raise PreparationError("ACL transfer did not revoke model write access")
            if template_id == "normal.finalise.model-stop":
                model_response = response
                model_objects = objects
            context = _continued_context(context, response, generation)
        receipts.append(str(response["receipt_id"]))
        transition_attestations.append(dict(stage_attestation))
        last = response

    assert last is not None
    try:
        snapshot = snapshotter.snapshot(dict(context))
    except Exception as error:
        raise PreparationError(f"stable snapshot failed: {error}") from error
    if not isinstance(snapshot, Mapping):
        raise PreparationError("stable snapshot result is not an object")
    _require_schema(snapshot.get("schema"), "stable snapshot")
    expected_snapshot = {
        "schema": SCHEMA,
        "kind": "firth-stable-source-snapshot",
        "repository_id": context["repository_id"],
        "policy_digest": context["policy_digest"],
        "unit": context["unit"],
        "incident_id": context["incident_id"],
        "branch": context["branch"],
        "head": context["head"],
        "worktree_id": context["worktree_id"],
        "head_tree": context["head_tree"],
        "lease_epoch": context["lease_epoch"],
        "base_commit": context["base_commit"],
        "base_tree": context["base_tree"],
        "observation_generation": generation,
        "observation_signature": last["observation_signature"],
        "stable": True,
        "snapshot_count": 1,
    }
    for field, value in expected_snapshot.items():
        if snapshot.get(field) != value:
            raise PreparationError(f"stable snapshot {field} mismatch")
    snapshot_digest = _require_digest(snapshot.get("snapshot_digest"), "snapshot_digest")
    snapshot_artifact = _require_text(snapshot.get("artifact_id"), "snapshot artifact_id")
    patch_hash = _require_digest(snapshot.get("patch_hash"), "snapshot patch_hash")
    changed_paths = snapshot.get("changed_paths")
    if (
        not isinstance(changed_paths, list)
        or not all(isinstance(path, str) and path for path in changed_paths)
        or changed_paths != sorted(set(changed_paths))
    ):
        raise PreparationError("stable snapshot changed_paths are invalid")
    manifest = {
        "base_commit": context["base_commit"],
        "head_tree": context["head_tree"],
        "patch_hash": patch_hash,
        "changed_paths": changed_paths,
    }
    changed_paths_digest = hashlib.sha256(
        _canonical_projection_bytes(manifest)
    ).hexdigest()
    if snapshot.get("changed_paths_digest") != changed_paths_digest:
        raise PreparationError("stable snapshot changed path manifest digest mismatch")
    if state_receipt is None or model_response is None or model_objects is None:
        raise PreparationError("finaliser attestations are incomplete")
    if worktree_response is None or worktree_objects is None:
        raise PreparationError("worktree lease attestation is missing")
    model_head = _require_object_id(model_objects.get("head"), "model attestation head")
    model_lease_epoch = model_objects.get("lease_epoch")
    if not isinstance(model_lease_epoch, int) or isinstance(model_lease_epoch, bool) or model_lease_epoch < 1:
        raise PreparationError("model attestation lease_epoch is invalid")
    worktree_head = _require_object_id(worktree_objects.get("head"), "worktree attestation head")
    worktree_tree = _require_object_id(worktree_objects.get("head_tree"), "worktree attestation head_tree")
    worktree_lease_epoch = worktree_objects.get("lease_epoch")
    if (
        not isinstance(worktree_lease_epoch, int)
        or isinstance(worktree_lease_epoch, bool)
        or worktree_lease_epoch < 1
    ):
        raise PreparationError("worktree attestation lease_epoch is invalid")
    state_attestation = dict(state_receipt)
    state_attestation["source"] = "installed-state"
    model_attestation = {
        "schema": "firth.model-stop-attestation.v1",
        "source": "installed-model",
        "repository_id": context["repository_id"],
        "policy_digest": context["policy_digest"],
        "incident_id": context["incident_id"],
        "unit": context["unit"],
        "branch": context["branch"],
        "worktree_id": context["worktree_id"],
        "head": model_head,
        "lease_epoch": model_lease_epoch,
        "container_id": _require_text(model_objects.get("container_id"), "model attestation container_id"),
        "cgroup_id": _require_text(model_objects.get("cgroup_id"), "model attestation cgroup_id"),
        "writer_present": False,
        "cgroup_stopped": True,
        "descendant_count": 0,
        "observation_generation": model_response["generation"],
        "observation_signature": _require_digest(
            model_response.get("observation_signature"), "model attestation observation_signature"
        ),
        "receipt_id": _require_digest(model_response.get("receipt_id"), "model attestation receipt_id"),
    }
    worktree_attestation = {
        "schema": "firth.worktree-lease-attestation.v1",
        "source": "installed-worktree",
        "repository_id": context["repository_id"],
        "policy_digest": context["policy_digest"],
        "incident_id": context["incident_id"],
        "unit": context["unit"],
        "branch": context["branch"],
        "worktree_id": context["worktree_id"],
        "head": worktree_head,
        "head_tree": worktree_tree,
        "lease_epoch": worktree_lease_epoch,
        "lease_holder": "broker",
        "writer_present": False,
        "model_write_access": False,
        "broker_write_access": True,
        "observation_generation": worktree_response["generation"],
        "observation_signature": _require_digest(
            worktree_response.get("observation_signature"), "worktree attestation observation_signature"
        ),
        "receipt_id": _require_digest(worktree_response.get("receipt_id"), "worktree attestation receipt_id"),
    }
    snapshot_attestation = {
        "schema": "firth.stable-snapshot-attestation.v1",
        "source": "installed-state",
        "repository_id": context["repository_id"],
        "policy_digest": context["policy_digest"],
        "incident_id": context["incident_id"],
        "unit": context["unit"],
        "branch": context["branch"],
        "worktree_id": context["worktree_id"],
        "head": context["head"],
        "head_tree": context["head_tree"],
        "lease_epoch": context["lease_epoch"],
        "observation_generation": generation,
        "observation_signature": _require_digest(
            last.get("observation_signature"), "snapshot attestation observation_signature"
        ),
        "snapshot_digest": snapshot_digest,
        "artifact_id": snapshot_artifact,
        "base_commit": context["base_commit"],
        "patch_hash": patch_hash,
        "changed_paths": changed_paths,
        "changed_paths_digest": changed_paths_digest,
    }
    return {
        "prepared_generation": envelope["generation"],
        "prepared_observation_signature": envelope["observation_signature"],
        "schema": SCHEMA,
        "kind": "firth-finaliser-receipt",
        "namespace": NAMESPACE,
        "repository_id": context["repository_id"],
        "policy_digest": context["policy_digest"],
        "incident_id": context["incident_id"],
        "unit": context["unit"],
        "branch": context["branch"],
        "head": context["head"],
        "head_tree": context["head_tree"],
        "worktree_id": context["worktree_id"],
        "changed_paths_digest": changed_paths_digest,
        "lease_epoch": context["lease_epoch"],
        "snapshot_digest": snapshot_digest,
        "snapshot_artifact_id": snapshot_artifact,
        "snapshot_attestation": snapshot_attestation,
        "state_attestation": state_attestation,
        "model_attestation": model_attestation,
        "worktree_attestation": worktree_attestation,
        "generation": generation,
        "observation_signature": last["observation_signature"],
        "state_receipt_id": state_receipt["receipt_id"],
        "receipts": receipts,
        "transition_attestations": transition_attestations,
        "model_terminal": True,
        "iteration_complete": False,
        "loop_exhausted": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="validate a prepared Firth iteration envelope")
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("validate-envelope")
    args = parser.parse_args()
    try:
        envelope = json.loads(
            INSTALLED_ENVELOPE.read_text(encoding="utf-8"),
            object_pairs_hook=_projection_pairs,
            parse_float=_reject_projection_float,
        )
        result = validate_prepared_envelope(envelope, load_installed_policy_projection())
    except (OSError, UnicodeError, json.JSONDecodeError, PreparationError) as error:
        print(json.dumps({"schema": SCHEMA, "valid": False, "error": str(error)}, sort_keys=True))
        return 2
    print(json.dumps({"schema": SCHEMA, "valid": True, "envelope": result}, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
