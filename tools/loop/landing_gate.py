#!/usr/bin/env python3
"""Pure admission checks for broker-owned Firth landing.

The model session cannot call this as an authority boundary. The installed
broker runs the accepted, digest-pinned copy against exact source objects and
external receipts before it requests a publication or merge transition.
"""

from __future__ import annotations

import hashlib
import json
import re
import unicodedata
import uuid
from collections.abc import Mapping, Sequence
from typing import Any

SCHEMA = 1
SHA256 = re.compile(r"^[0-9a-f]{64}$")
OBJECT_ID = re.compile(r"^[0-9a-f]{40,64}$")
EXPECTED_NORMAL_TEMPLATE_FIELDS = {
    "normal.mirror.fetch": {"repository_id", "policy_digest", "main_commit", "main_tree", "incident_id", "unit", "observation_generation", "observation_signature"},
    "normal.branch.create": {"repository_id", "policy_digest", "main_commit", "main_tree", "incident_id", "unit", "observation_generation", "observation_signature", "mirror_id", "branch"},
    "normal.worktree.create": {"repository_id", "policy_digest", "main_commit", "main_tree", "incident_id", "unit", "observation_generation", "observation_signature", "mirror_id", "branch", "head"},
    "normal.lease.grant": {"repository_id", "policy_digest", "main_commit", "main_tree", "incident_id", "unit", "observation_generation", "observation_signature", "mirror_id", "branch", "head", "worktree_id"},
    "normal.binding.verify": {"repository_id", "policy_digest", "main_commit", "main_tree", "incident_id", "unit", "observation_generation", "observation_signature", "branch", "head", "verdict"},
    "normal.finalise.seal": {"incident_id", "repository_id", "policy_digest", "unit", "branch", "head", "worktree_id", "lease_epoch", "container_id", "cgroup_id", "observation_generation", "observation_signature"},
    "normal.finalise.model-stop": {"incident_id", "repository_id", "policy_digest", "unit", "branch", "head", "worktree_id", "lease_epoch", "container_id", "cgroup_id", "observation_generation", "observation_signature"},
    "normal.finalise.acl-transfer": {"incident_id", "repository_id", "policy_digest", "unit", "branch", "head", "worktree_id", "lease_epoch", "container_id", "cgroup_id", "observation_generation", "observation_signature"},
    "normal.finalise.lease-acquire": {"incident_id", "repository_id", "policy_digest", "unit", "branch", "head", "worktree_id", "lease_epoch", "container_id", "cgroup_id", "observation_generation", "observation_signature"},
}
RECEIPT_PATH_PREFIXES = (
    ".firth/reviews/",
    ".resolver/receipts/",
    "meta/reviews/",
    "reviews/",
)


class LandingError(RuntimeError):
    pass
def _schema(value: Any, field: str) -> None:
    if not isinstance(value, int) or isinstance(value, bool) or value != SCHEMA:
        raise LandingError(f"{field} schema is unsupported")



def _text(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise LandingError(f"missing or invalid {field}")
    return value


def _digest(value: Any, field: str) -> str:
    value = _text(value, field)
    if SHA256.fullmatch(value) is None:
        raise LandingError(f"invalid {field}")
    return value


def _object_id(value: Any, field: str) -> str:
    value = _text(value, field)
    if OBJECT_ID.fullmatch(value) is None:
        raise LandingError(f"invalid {field}")
    return value

def _incident(value: Any) -> str:
    text = _text(value, "incident_id")
    try:
        incident = uuid.UUID(text)
    except ValueError as error:
        raise LandingError("invalid incident_id") from error
    if incident.version != 7 or str(incident) != text:
        raise LandingError("incident_id must be a canonical UUIDv7")
    return text


def _normal_branch(incident_id: str) -> str:
    return f"loop/resolver.{incident_id.replace('-', '')}"

def _canonical_bytes(value: Any) -> bytes:
    if isinstance(value, float):
        raise LandingError("installed policy projection contains a float")
    if value is None or isinstance(value, (bool, int, str)):
        if isinstance(value, str) and unicodedata.normalize("NFC", value) != value:
            raise LandingError("installed policy projection contains non-NFC text")
        return json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    if isinstance(value, list):
        return b"[" + b",".join(_canonical_bytes(item) for item in value) + b"]"
    if isinstance(value, Mapping):
        if not all(isinstance(key, str) for key in value):
            raise LandingError("installed policy projection key is invalid")
        return b"{" + b",".join(
            _canonical_bytes(key) + b":" + _canonical_bytes(value[key]) for key in sorted(value)
        ) + b"}"
    raise LandingError("installed policy projection value is invalid")


def _status_transition(before: bytes, after: bytes, expected: str) -> bool:
    try:
        before_text = before.decode("utf-8")
        after_text = after.decode("utf-8")
    except UnicodeDecodeError:
        return False
    before_lines = before_text.splitlines(keepends=True)
    after_lines = after_text.splitlines(keepends=True)
    if len(before_lines) != len(after_lines):
        return False
    changed = 0
    in_frontmatter = False
    closed = False
    for old, new in zip(before_lines, after_lines, strict=True):
        old_value = old.rstrip("\r\n")
        new_value = new.rstrip("\r\n")
        if old_value == "---" and not in_frontmatter and not closed:
            in_frontmatter = True
        elif old_value == "---" and in_frontmatter:
            in_frontmatter = False
            closed = True
        if old == new:
            continue
        if not in_frontmatter:
            return False
        if old_value != f"status: {expected}" or new_value != "status: done":
            return False
        if old[len(old_value) :] != new[len(new_value) :]:
            return False
        changed += 1
    return closed and changed == 1


def _validate_projection(projection: Mapping[str, Any], repository_id: str, policy_digest: str) -> None:
    required = {
        "schema", "kind", "policy_version", "repository_id", "operator_repository_id",
        "policy_digest", "projection_digest", "issuer_namespaces", "merge_classes",
        "path_classes", "completion_tcb", "normal_templates",
    }
    if set(projection) != required:
        raise LandingError("installed policy projection shape is invalid")
    _schema(projection.get("schema"), "installed policy projection")
    if projection.get("kind") != "firth-authority-policy-projection":
        raise LandingError("installed policy projection is invalid")
    policy_version = projection.get("policy_version")
    if not isinstance(policy_version, int) or isinstance(policy_version, bool) or policy_version != 1:
        raise LandingError("installed policy version is unsupported")
    unsigned = dict(projection)
    projection_digest = _digest(unsigned.pop("projection_digest", None), "projection_digest")
    if hashlib.sha256(_canonical_bytes(unsigned)).hexdigest() != projection_digest:
        raise LandingError("installed policy projection digest mismatch")
    if projection.get("repository_id") != repository_id or projection.get("operator_repository_id") != "George-RD/georges-devops":
        raise LandingError("installed policy repository identity mismatch")
    if projection.get("policy_digest") != policy_digest:
        raise LandingError("installed policy digest mismatch")
    if projection.get("issuer_namespaces") != ["normal-iteration", "halted-recovery", "local-operator"]:
        raise LandingError("installed policy issuer namespaces mismatch")
    merge_classes = projection.get("merge_classes")
    if merge_classes != ["normal-auto", "resolver-auto", "auto-operator", "protected-human", "manual-root"]:
        raise LandingError("installed policy merge classes mismatch")
    completion = projection.get("completion_tcb")
    if not isinstance(completion, Mapping) or completion.get("exclusive_command") != "python3 tools/loop/coverage.py --run-gates" or completion.get("terminal_token") != "LOOP EXHAUSTED":
        raise LandingError("installed completion TCB projection mismatch")
    templates = projection.get("normal_templates")
    if not isinstance(templates, Mapping) or set(templates) != set(EXPECTED_NORMAL_TEMPLATE_FIELDS):
        raise LandingError("installed normal template set mismatch")
    for template_id, fields in EXPECTED_NORMAL_TEMPLATE_FIELDS.items():
        template = templates[template_id]
        if not isinstance(template, Mapping) or template.get("namespace") != "normal-iteration" or template.get("max_invocations") != 1 or template.get("retry") not in {"never", "reconcile-only"} or set(template.get("input_fields", [])) != fields:
            raise LandingError(f"installed template {template_id} mismatch")

def _validate_candidate_paths(
    projection: Mapping[str, Any], candidate_paths: Sequence[str], selected_todo: str | None
) -> None:
    path_classes = projection.get("path_classes")
    normal = path_classes.get("normal-auto") if isinstance(path_classes, Mapping) else None
    expected = {
        "repositories": ["firth"],
        "include": ["src/**", "meta/todos/todo.<selected-slug>.md"],
        "exclude": ["src/**/.gitmodules", "src/**/.gitattributes", "src/**/.gitconfig"],
        "approval": "exact-group-check",
    }
    if normal != expected:
        raise LandingError("installed normal-auto path policy mismatch")
    todo_path = f"meta/todos/todo.{selected_todo}.md" if selected_todo is not None else None
    for path in candidate_paths:
        parts = path.split("/")
        if (
            path.startswith("/")
            or "\\" in path
            or any(part in {"", ".", ".."} for part in parts)
            or unicodedata.normalize("NFC", path) != path
        ):
            raise LandingError(f"candidate path is not canonical: {path}")
        if path.startswith(RECEIPT_PATH_PREFIXES):
            raise LandingError("review or finaliser receipt path is inside the candidate tree")
        if path.startswith("src/"):
            if parts[-1] in {".gitmodules", ".gitattributes", ".gitconfig"}:
                raise LandingError(f"candidate path is excluded by normal-auto policy: {path}")
            continue
        if todo_path is not None and path == todo_path:
            continue
        raise LandingError(f"candidate path is outside normal-auto policy: {path}")


def _validate_finaliser(receipt: Mapping[str, Any], admission: Mapping[str, Any]) -> None:
    _schema(receipt.get("schema"), "finaliser receipt")
    expected = {
        "kind": "firth-finaliser-receipt",
        "namespace": "normal-iteration",
        "repository_id": admission["repository_id"],
        "policy_digest": admission["policy_digest"],
        "incident_id": admission["incident_id"],
        "head": admission["head_commit"],
        "head_tree": admission["head_tree"],
        "unit": admission["unit"],
        "branch": admission["branch"],
        "snapshot_digest": admission["snapshot_digest"],
        "model_terminal": True,
        "iteration_complete": False,
        "loop_exhausted": False,
    }
    for field, value in expected.items():
        if receipt.get(field) != value:
            raise LandingError(f"finaliser receipt {field} mismatch")
    _object_id(receipt.get("head"), "finaliser head")
    _object_id(receipt.get("head_tree"), "finaliser head_tree")
    worktree_id = _text(receipt.get("worktree_id"), "finaliser worktree_id")
    generation = receipt.get("generation")
    if not isinstance(generation, int) or isinstance(generation, bool) or generation < 1:
        raise LandingError("finaliser generation is invalid")
    finaliser_signature = _digest(receipt.get("observation_signature"), "finaliser observation_signature")
    state_receipt_id = _digest(receipt.get("state_receipt_id"), "state finaliser receipt_id")
    lease_epoch = receipt.get("lease_epoch")
    if not isinstance(lease_epoch, int) or isinstance(lease_epoch, bool) or lease_epoch < 2:
        raise LandingError("finaliser lease_epoch is invalid")
    receipts = receipt.get("receipts")
    if not isinstance(receipts, list) or len(receipts) != 4 or not all(
        isinstance(value, str) and value for value in receipts
    ):
        raise LandingError("finaliser transition receipts are incomplete")
    snapshot_artifact = _text(receipt.get("snapshot_artifact_id"), "snapshot_artifact_id")
    provenance = admission.get("snapshot_provenance")
    if (
        not isinstance(provenance, Mapping)
        or provenance.get("source") != "installed-state"
        or provenance.get("artifact_id") != snapshot_artifact
        or provenance.get("snapshot_digest") != admission["snapshot_digest"]
        or provenance.get("prepared_head") != admission["prepared_head"]
        or provenance.get("candidate_commit") != admission["head_commit"]
        or provenance.get("candidate_tree") != admission["head_tree"]
        or provenance.get("patch_hash") != admission["patch_hash"]
    ):
        raise LandingError("candidate commit is not bound to the installed finaliser snapshot")

    state = receipt.get("state_attestation")
    if (
        not isinstance(state, Mapping)
        or state.get("schema") != "firth.state-finaliser-receipt.v1"
        or state.get("source") != "installed-state"
    ):
        raise LandingError("installed state finaliser attestation is missing")
    state_expected = {
        "namespace": "normal-iteration",
        "repository_id": admission["repository_id"],
        "policy_digest": admission["policy_digest"],
        "incident_id": admission["incident_id"],
        "unit": admission["unit"],
        "branch": admission["branch"],
        "worktree_id": worktree_id,
        "head_commit": admission["head_commit"],
        "head_tree": admission["head_tree"],
        "lease_epoch": lease_epoch,
        "stage": "lease-acquired",
        "observation_generation": receipt.get("generation"),
        "observation_signature": finaliser_signature,
    }
    for field, value in state_expected.items():
        if state.get(field) != value:
            raise LandingError(f"state finaliser attestation {field} mismatch")
    if state.get("receipt_id") != state_receipt_id:
        raise LandingError("state finaliser attestation receipt mismatch")

    model = receipt.get("model_attestation")
    if (
        not isinstance(model, Mapping)
        or model.get("schema") != "firth.model-stop-attestation.v1"
        or model.get("source") != "installed-model"
    ):
        raise LandingError("installed model stop attestation is missing")
    model_expected = {
        "repository_id": admission["repository_id"],
        "policy_digest": admission["policy_digest"],
        "incident_id": admission["incident_id"],
        "unit": admission["unit"],
        "branch": admission["branch"],
        "worktree_id": worktree_id,
        "head": admission["prepared_head"],
        "lease_epoch": admission["prepared_lease_epoch"],
        "writer_present": False,
        "cgroup_stopped": True,
        "descendant_count": 0,
    }
    for field, value in model_expected.items():
        if model.get(field) != value:
            raise LandingError(f"model stop attestation {field} mismatch")
    _text(model.get("container_id"), "model attestation container_id")
    _text(model.get("cgroup_id"), "model attestation cgroup_id")
    if _digest(model.get("receipt_id"), "model stop attestation receipt_id") != receipts[1]:
        raise LandingError("model stop attestation receipt mismatch")
    _object_id(model.get("head"), "model attestation head")
    model_signature = _digest(model.get("observation_signature"), "model stop attestation signature")
    model_generation = model.get("observation_generation")
    if (
        not isinstance(model_generation, int)
        or isinstance(model_generation, bool)
        or model_generation < 1
        or model_generation >= generation
    ):
        raise LandingError("model stop attestation generation is invalid")

    worktree = receipt.get("worktree_attestation")
    if (
        not isinstance(worktree, Mapping)
        or worktree.get("schema") != "firth.worktree-lease-attestation.v1"
        or worktree.get("source") != "installed-worktree"
    ):
        raise LandingError("installed worktree lease attestation is missing")
    worktree_expected = {
        "repository_id": admission["repository_id"],
        "policy_digest": admission["policy_digest"],
        "incident_id": admission["incident_id"],
        "unit": admission["unit"],
        "branch": admission["branch"],
        "worktree_id": worktree_id,
        "head": admission["head_commit"],
        "head_tree": admission["head_tree"],
        "lease_epoch": lease_epoch,
        "lease_holder": "broker",
        "writer_present": False,
        "model_write_access": False,
        "broker_write_access": True,
    }
    for field, value in worktree_expected.items():
        if worktree.get(field) != value:
            raise LandingError(f"worktree lease attestation {field} mismatch")
    if _digest(worktree.get("receipt_id"), "worktree lease attestation receipt_id") != receipts[3]:
        raise LandingError("worktree lease attestation receipt mismatch")
    _object_id(worktree.get("head"), "worktree lease attestation head")
    _object_id(worktree.get("head_tree"), "worktree lease attestation head_tree")
    worktree_generation = worktree.get("observation_generation")
    worktree_signature = _digest(
        worktree.get("observation_signature"), "worktree lease attestation signature"
    )
    if worktree_generation != generation or worktree_signature != finaliser_signature:
        raise LandingError("worktree lease attestation generation or signature mismatch")

    snapshot = receipt.get("snapshot_attestation")
    if (
        not isinstance(snapshot, Mapping)
        or snapshot.get("schema") != "firth.stable-snapshot-attestation.v1"
        or snapshot.get("source") != "installed-state"
    ):
        raise LandingError("installed stable snapshot attestation is missing")
    snapshot_expected = {
        "repository_id": admission["repository_id"],
        "policy_digest": admission["policy_digest"],
        "incident_id": admission["incident_id"],
        "unit": admission["unit"],
        "branch": admission["branch"],
        "worktree_id": worktree_id,
        "head": admission["head_commit"],
        "head_tree": admission["head_tree"],
        "lease_epoch": lease_epoch,
        "snapshot_digest": admission["snapshot_digest"],
        "artifact_id": snapshot_artifact,
        "observation_generation": receipt.get("generation"),
        "observation_signature": finaliser_signature,
    }
    for field, value in snapshot_expected.items():
        if snapshot.get(field) != value:
            raise LandingError(f"stable snapshot attestation {field} mismatch")

def _validate_reviews(
    reviews: Sequence[Mapping[str, Any]], admission: Mapping[str, Any]
) -> None:
    if len(reviews) != 2:
        raise LandingError("exactly two external review receipts are required")
    identities: set[tuple[str, str]] = set()
    lenses: set[str] = set()
    for review in reviews:
        if not isinstance(review, Mapping):
            raise LandingError("review receipt is not an object")
        _schema(review.get("schema"), "review receipt")
        lens = review.get("lens")
        if lens not in {"correctness", "simplicity"} or lens in lenses:
            raise LandingError("review lenses must be correctness and simplicity exactly once")
        lenses.add(str(lens))
        identity = (
            _text(review.get("model_id"), "review model_id"),
            _text(review.get("session_id"), "review session_id"),
        )
        if identity in identities:
            raise LandingError("review identities must be distinct")
        identities.add(identity)
        expected = {
            "kind": "firth-exact-object-review",
            "repository_id": admission["repository_id"],
            "policy_digest": admission["policy_digest"],
            "ruleset_digest": admission["ruleset_digest"],
            "base_commit": admission["base_commit"],
            "base_tree": admission["base_tree"],
            "head_commit": admission["head_commit"],
            "head_tree": admission["head_tree"],
            "patch_hash": admission["patch_hash"],
            "incident_id": admission["incident_id"],
            "verdict": "accept",
        }
        for field, value in expected.items():
            if review.get(field) != value:
                raise LandingError(f"{lens} review {field} mismatch")
        attestation = review.get("review_attestation")
        if (
            not isinstance(attestation, Mapping)
            or attestation.get("schema") != "firth.review-attestation.v1"
            or attestation.get("source") != "installed-model-gateway"
        ):
            raise LandingError(f"{lens} installed reviewer attestation is missing")
        attestation_expected = {
            "model_id": identity[0],
            "session_id": identity[1],
            "lens": lens,
            **expected,
        }
        for field, value in attestation_expected.items():
            if attestation.get(field) != value:
                raise LandingError(f"{lens} reviewer attestation {field} mismatch")


def validate_landing(
    admission: Mapping[str, Any] | Any,
    projection: Mapping[str, Any] | Any,
    finaliser_receipt: Mapping[str, Any] | Any,
    reviews: Sequence[Mapping[str, Any]] | Any,
    base_todos: Mapping[str, bytes] | Any,
    candidate_todos: Mapping[str, bytes] | Any,
    candidate_paths: Sequence[str] | Any,
) -> dict[str, Any]:
    """Validate the complete normal-iteration landing contract."""

    if not all(isinstance(value, Mapping) for value in (admission, projection, finaliser_receipt)):
        raise LandingError("landing admission objects are malformed")
    if not isinstance(reviews, Sequence) or isinstance(reviews, (str, bytes)):
        raise LandingError("review receipts must be an array")
    if not isinstance(base_todos, Mapping) or not isinstance(candidate_todos, Mapping):
        raise LandingError("todo trees must be objects")
    if not isinstance(candidate_paths, Sequence) or isinstance(candidate_paths, (str, bytes)):
        raise LandingError("candidate paths must be an array")
    if not all(isinstance(path, str) and path for path in candidate_paths):
        raise LandingError("candidate path is invalid")
    _schema(admission.get("schema"), "landing admission")
    if admission.get("namespace") != "normal-iteration":
        raise LandingError("landing admission namespace is invalid")

    repository_id = _text(admission.get("repository_id"), "repository_id")
    policy_digest = _digest(admission.get("policy_digest"), "policy_digest")
    for field in ("ruleset_digest", "snapshot_digest", "patch_hash"):
        _digest(admission.get(field), field)
    for field in ("base_commit", "base_tree", "prepared_head", "head_commit", "head_tree"):
        _object_id(admission.get(field), field)
    prepared_lease_epoch = admission.get("prepared_lease_epoch")
    if (
        not isinstance(prepared_lease_epoch, int)
        or isinstance(prepared_lease_epoch, bool)
        or prepared_lease_epoch < 1
    ):
        raise LandingError("prepared lease epoch is invalid")
    unit = _text(admission.get("unit"), "unit")
    incident_id = _incident(admission.get("incident_id"))
    branch = _text(admission.get("branch"), "branch")
    if branch != _normal_branch(incident_id):
        raise LandingError("incident and branch mismatch")
    _validate_projection(projection, repository_id, policy_digest)

    merge_class = admission.get("merge_class")
    if merge_class not in {"normal-auto", "protected-human", "manual-root"}:
        raise LandingError("unknown merge class")
    if merge_class != "normal-auto":
        return {
            "schema": SCHEMA,
            "admitted": False,
            "result": "awaiting-protected-approval" if merge_class == "protected-human" else "awaiting-root-install",
            "merge_class": merge_class,
            "loop_exhausted": False,
        }

    _validate_finaliser(finaliser_receipt, admission)
    _validate_reviews(reviews, admission)

    selected_todo = admission.get("selected_todo")
    if selected_todo is None:
        if dict(base_todos) != dict(candidate_todos):
            raise LandingError("non-todo unit changed tracker bytes")
    else:
        selected_todo = _text(selected_todo, "selected_todo")
        if selected_todo != unit:
            raise LandingError("selected todo and prepared unit mismatch")
        expected_path = f"meta/todos/todo.{selected_todo}.md"
        if expected_path not in base_todos or expected_path not in candidate_todos:
            raise LandingError("selected todo is missing from one tree")
        if set(base_todos) != set(candidate_todos):
            raise LandingError("todo path set changed")
        expected_status = admission.get("selected_todo_expected_status")
        if expected_status not in {"open", "in_progress"}:
            raise LandingError("selected todo expected status is invalid")
        for path, before in base_todos.items():
            after = candidate_todos[path]
            if not isinstance(before, bytes) or not isinstance(after, bytes):
                raise LandingError("todo bytes must be byte strings")
            if path == expected_path:
                if not _status_transition(before, after, str(expected_status)):
                    raise LandingError("selected todo delta is not the sanctioned final status transition")
            elif before != after:
                raise LandingError(f"unselected todo changed: {path}")

    _validate_candidate_paths(projection, candidate_paths, selected_todo)

    return {
        "schema": SCHEMA,
        "admitted": True,
        "result": "merge-admissible",
        "merge_class": "normal-auto",
        "repository_id": repository_id,
        "policy_digest": policy_digest,
        "head_commit": admission["head_commit"],
        "head_tree": admission["head_tree"],
        "patch_hash": admission["patch_hash"],
        "reviews": ["correctness", "simplicity"],
        "finaliser_receipt": True,
        "selected_todo_final": selected_todo,
        "iteration_complete": False,
        "loop_exhausted": False,
    }
