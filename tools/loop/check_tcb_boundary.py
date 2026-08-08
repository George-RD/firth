#!/usr/bin/env python3
"""Validate Firth's machine-readable trusted-computing-base boundary."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
import tomllib
from typing import Any

TRUSTED_IDS = {"lean-kernel", "smt-solver", "vm"}
REQUIRED_COMPONENT_IDS = frozenset(
    {
        "firth.language.kernel",
        "firth.language.surface",
        "firth.language.types",
        "firth.toolchain.elaborator",
        "firth.toolchain.elaborator.translator",
        "firth.toolchain.elaborator.cache",
        "firth.toolchain.interpreter",
        "firth.toolchain.compiler",
        "firth.toolchain.compiler.translator",
        "firth.toolchain.diffharness",
        "firth.toolchain.smt",
        "firth.toolchain.smt.translator",
        "firth.toolchain.agent",
        "firth.toolchain.agent.diagnostic",
        "firth.runtime.vm",
        "firth.runtime.image",
        "firth.runtime.patch",
        "firth.ecosystem.stdlib",
        "firth.ecosystem.lsp",
        "firth.ecosystem.specs",
        "firth.governance.loop",
    }
)
SMT_REQUIRED_TERMS = {"unsat", "pinned", "content-addressed", "lean", "rechecked"}
EXPECTED_SMT_CONDITION = (
    "Included only for an approved profile when the pinned solver returns unsat, "
    "the input and result are content-addressed, the translation-soundness bridge "
    "is checked by Lean, and the record is regenerated and rechecked."
)
EXPECTED_STAGES = {
    "lean-zero-admit": (
        "python3 tools/loop/check_zero_admit.py",
        frozenset({"lean-kernel"}),
        frozenset({"tools/loop/check_zero_admit.py", "src"}),
    ),
    "lean-build": (
        "lake build",
        frozenset({"lean-kernel"}),
        frozenset({"lakefile.toml", "lean-toolchain", "src"}),
    ),
    "lean-test-driver": (
        "lake test",
        frozenset({"lean-kernel"}),
        frozenset({"lakefile.toml", "src/agent/FirthAllTest.lean"}),
    ),
    "smt-boundary": (
        "lake exe smtBoundaryTest",
        frozenset({"lean-kernel"}),
        frozenset({"src/smt/Firth/SmtBoundary.lean", "src/smt/Firth/SmtBoundaryTest.lean"}),
    ),
    "vm-conformance": (
        "cargo test --locked --manifest-path src/runtime/vm/Cargo.toml",
        frozenset({"vm"}),
        frozenset({"src/runtime/vm/Cargo.toml", "src/runtime/vm/src"}),
    ),
    "vm-fixtures": (
        "tools/loop/check_kernel_fixtures.sh",
        frozenset({"lean-kernel", "vm"}),
        frozenset({"tools/loop/check_kernel_fixtures.sh", "src/runtime/vm/fixtures/kernel.tsv"}),
    ),
}
EXPECTED_SOURCE_SPEC = "specs/component-spec-boundaries.md"
EXPECTED_SOURCE_DECISION = "meta/decisions/tcb-boundary-inventory.md"
EXPECTED_OUTPUTS = {
    "firth.language.kernel": {"kernel-definitions-and-metatheory"},
    "firth.language.surface": {"checked-kernel-programs"},
    "firth.language.types": {"typed-stack-effects"},
    "firth.toolchain.elaborator": {
        "checked-kernel-terms-and-word-contracts",
        "refinement-specifications-and-discharge-records",
    },
    "firth.toolchain.elaborator.translator": {"sound-smt-formulas"},
    "firth.toolchain.elaborator.cache": {"rechecked-cached-discharge-records"},
    "firth.toolchain.interpreter": {"kernel-execution-traces-and-outcomes"},
    "firth.toolchain.compiler": {"target-code-and-lowering-evidence"},
    "firth.toolchain.compiler.translator": {"canonical-target-instructions"},
    "firth.toolchain.diffharness": {"reproducible-agreement-or-failure-artefacts"},
    "firth.toolchain.smt": {"discharge-records"},
    "firth.toolchain.smt.translator": {"normalised-verification-conditions-and-smt-lib"},
    "firth.toolchain.agent": {"typed-holes-and-signature-results"},
    "firth.toolchain.agent.diagnostic": {"validated-diagnostic-json"},
    "firth.runtime.vm": {"target-execution-and-image-boundary"},
    "firth.runtime.image": {"immutable-versioned-image-transitions"},
    "firth.runtime.patch": {"evidence-bound-image-replacements"},
    "firth.ecosystem.stdlib": {"elaborated-library-words-and-target-code"},
    "firth.ecosystem.lsp": {"validated-diagnostic-views"},
    "firth.ecosystem.specs": {"reimplementable-component-specifications"},
    "firth.governance.loop": {"gate-and-boundary-results"},
}
EXPECTED_REVALIDATORS = {
    "kernel-definitions-and-metatheory": {"lean-kernel"},
    "checked-kernel-programs": {"lean-kernel"},
    "typed-stack-effects": {"lean-kernel"},
    "checked-kernel-terms-and-word-contracts": {"lean-kernel"},
    "refinement-specifications-and-discharge-records": {"lean-kernel"},
    "sound-smt-formulas": {"lean-kernel"},
    "rechecked-cached-discharge-records": {"lean-kernel"},
    "kernel-execution-traces-and-outcomes": {"lean-kernel"},
    "target-code-and-lowering-evidence": {"vm"},
    "canonical-target-instructions": {"vm"},
    "reproducible-agreement-or-failure-artefacts": {"lean-kernel", "vm"},
    "discharge-records": {"lean-kernel"},
    "normalised-verification-conditions-and-smt-lib": {"lean-kernel"},
    "typed-holes-and-signature-results": {"lean-kernel"},
    "validated-diagnostic-json": {"lean-kernel"},
    "target-execution-and-image-boundary": {"vm"},
    "immutable-versioned-image-transitions": {"vm"},
    "evidence-bound-image-replacements": {"lean-kernel", "vm"},
    "elaborated-library-words-and-target-code": {"lean-kernel", "vm"},
    "validated-diagnostic-views": {"lean-kernel"},
    "reimplementable-component-specifications": {"lean-kernel", "vm"},
    "gate-and-boundary-results": {"lean-kernel", "vm"},
}
REQUIRED_SCHEMA = "firth.tcb-boundary"


def _as_list(value: Any, label: str, errors: list[str]) -> list[Any]:
    if not isinstance(value, list):
        errors.append(f"{label} must be an array")
        return []
    return value


def _repo_path(root: Path, value: Any) -> Path | None:
    if not isinstance(value, str) or not value:
        return None
    relative = Path(value)
    if relative.is_absolute() or ".." in relative.parts:
        return None
    root_resolved = root.resolve()
    candidate = (root_resolved / relative).resolve(strict=False)
    try:
        candidate.relative_to(root_resolved)
    except ValueError:
        return None
    return candidate

def _string_set(value: Any) -> set[str] | None:
    if not isinstance(value, list) or any(not isinstance(item, str) for item in value):
        return None
    return set(value)


def validate_manifest(manifest: dict[str, Any], root: Path) -> list[str]:
    errors: list[str] = []
    if manifest.get("schema") != REQUIRED_SCHEMA:
        errors.append(f"schema must be {REQUIRED_SCHEMA!r}")
    if type(manifest.get("version")) is not int or manifest["version"] != 1:
        errors.append("version must be 1")
    expected_sources = {
        "source_spec": EXPECTED_SOURCE_SPEC,
        "source_decision": EXPECTED_SOURCE_DECISION,
    }
    for field, expected in expected_sources.items():
        path_value = manifest.get(field)
        if path_value != expected:
            errors.append(f"{field} must be pinned to {expected}")
        source_path = _repo_path(root, path_value)
        if source_path is None:
            errors.append(f"{field} must be a safe repository-relative path")
        elif not source_path.is_file():
            errors.append(f"{field} does not exist: {path_value}")

    trusted_rows = _as_list(manifest.get("trusted_components"), "trusted_components", errors)
    trusted_by_id: dict[str, dict[str, Any]] = {}
    for index, row in enumerate(trusted_rows):
        if not isinstance(row, dict):
            errors.append(f"trusted_components[{index}] must be a table")
            continue
        identifier = row.get("id")
        if not isinstance(identifier, str) or not identifier:
            errors.append(f"trusted_components[{index}] has no id")
            continue
        if identifier in trusted_by_id:
            errors.append(f"duplicate trusted component: {identifier}")
        trusted_by_id[identifier] = row
        if not isinstance(row.get("condition"), str) or not row["condition"].strip():
            errors.append(f"trusted component has no condition: {identifier}")
    if set(trusted_by_id) != TRUSTED_IDS:
        errors.append(
            "trusted components must be exactly "
            + ", ".join(sorted(TRUSTED_IDS))
        )

    policy = manifest.get("smt_policy")
    if not isinstance(policy, dict):
        errors.append("smt_policy must be a table")
    else:
        raw_terms = policy.get("required_terms")
        policy_terms = (
            {term.lower() for term in raw_terms}
            if isinstance(raw_terms, list) and all(isinstance(term, str) for term in raw_terms)
            else None
        )
        if policy_terms != SMT_REQUIRED_TERMS:
            errors.append(
                "smt_policy.required_terms must be exactly "
                + ", ".join(sorted(SMT_REQUIRED_TERMS))
            )
        if trusted_by_id.get("smt-solver", {}).get("condition") != EXPECTED_SMT_CONDITION:
            errors.append("smt-solver condition is not pinned")
        excluded = _string_set(policy.get("excluded_results"))
        expected_excluded = {
            "sat",
            "unknown",
            "timeout",
            "resource-exhausted",
            "malformed",
            "crashed",
            "unchecked-unsat",
            "unsupported",
            "translation-failure",
        }
        if excluded != expected_excluded:
            errors.append("smt_policy.excluded_results is incomplete")
        if policy.get("accepted_result") != "unsat":
            errors.append("smt_policy.accepted_result must be unsat")
        if policy.get("solver_pinned") is not True:
            errors.append("smt_policy.solver_pinned must be true")
        if policy.get("record_content_addressed") is not True:
            errors.append("smt_policy.record_content_addressed must be true")
        if policy.get("translation_soundness_checked_by") != "lean-kernel":
            errors.append("smt_policy translation soundness must be checked by Lean")
        if policy.get("record_rechecked") is not True:
            errors.append("smt_policy.record_rechecked must be true")
        smt_row = trusted_by_id.get("smt-solver", {})
        if smt_row.get("conditional") is not True:
            errors.append("smt-solver must be conditional")
        if _string_set(smt_row.get("excluded_results")) != excluded:
            errors.append("smt-solver excluded_results must match smt_policy")

    stages = _as_list(manifest.get("stages"), "stages", errors)
    stage_by_id: dict[str, dict[str, Any]] = {}
    for index, row in enumerate(stages):
        if not isinstance(row, dict):
            errors.append(f"stages[{index}] must be a table")
            continue
        identifier = row.get("id")
        if not isinstance(identifier, str) or not identifier:
            errors.append(f"stages[{index}] has no id")
            continue
        if identifier in stage_by_id:
            errors.append(f"duplicate stage: {identifier}")
        stage_by_id[identifier] = row
        if not isinstance(row.get("command"), str) or not row["command"].strip():
            errors.append(f"stage has no command: {identifier}")
        checkers = _string_set(row.get("trusted_components"))
        if not checkers:
            errors.append(f"stage has no trusted components: {identifier}")
        elif not checkers <= TRUSTED_IDS:
            errors.append(f"stage has unknown trusted component: {identifier}")
        evidence_paths = row.get("evidence_paths")
        if not isinstance(evidence_paths, list) or not evidence_paths:
            errors.append(f"stage has no evidence paths: {identifier}")
        else:
            for evidence_path in evidence_paths:
                path = _repo_path(root, evidence_path)
                if path is None or not path.exists():
                    errors.append(f"stage evidence path missing: {identifier}: {evidence_path}")
        expected = EXPECTED_STAGES.get(identifier)
        if expected is None:
            errors.append(f"stage is not pinned: {identifier}")
        else:
            expected_command, expected_checkers, expected_paths = expected
            if row.get("command") != expected_command:
                errors.append(f"stage command is not pinned: {identifier}")
            if checkers != expected_checkers:
                errors.append(f"stage trusted components are not pinned: {identifier}")
            if _string_set(evidence_paths) != expected_paths:
                errors.append(f"stage evidence paths are not pinned: {identifier}")
    if set(stage_by_id) != set(EXPECTED_STAGES):
        missing_stages = sorted(set(EXPECTED_STAGES) - set(stage_by_id))
        extra_stages = sorted(set(stage_by_id) - set(EXPECTED_STAGES))
        if missing_stages:
            errors.append("missing required stages: " + ", ".join(missing_stages))
        if extra_stages:
            errors.append("unlisted stages: " + ", ".join(extra_stages))

    raw_required_ids = manifest.get("required_component_ids")
    required_ids = _string_set(raw_required_ids)
    if (
        required_ids != REQUIRED_COMPONENT_IDS
        or not isinstance(raw_required_ids, list)
        or len(raw_required_ids) != len(required_ids or ())
    ):
        errors.append("required_component_ids must match the pinned architecture inventory")

    components = _as_list(manifest.get("components"), "components", errors)
    component_by_id: dict[str, dict[str, Any]] = {}
    for index, component in enumerate(components):
        if not isinstance(component, dict):
            errors.append(f"components[{index}] must be a table")
            continue
        identifier = component.get("id")
        if not isinstance(identifier, str) or not identifier:
            errors.append(f"components[{index}] has no id")
            continue
        if identifier in component_by_id:
            errors.append(f"duplicate component: {identifier}")
        component_by_id[identifier] = component
        for field in ("module", "category", "status"):
            if not isinstance(component.get(field), str) or not component[field].strip():
                errors.append(f"component {identifier} has no {field}")
        trusted = component.get("trusted")
        if not isinstance(trusted, bool):
            errors.append(f"component {identifier}.trusted must be boolean")
            trusted = False
        if trusted:
            if identifier != "firth.runtime.vm" or component.get("trusted_component") != "vm":
                errors.append(f"only firth.runtime.vm may be the VM trusted component: {identifier}")
        elif "trusted_component" in component:
            errors.append(f"non-TCB component names a trusted boundary: {identifier}")

        outputs = component.get("outputs")
        outputs = _as_list(outputs, f"component {identifier}.outputs", errors)
        if not outputs:
            errors.append(f"component {identifier}.outputs must be non-empty")
        output_ids: set[str] = set()
        for output_index, output in enumerate(outputs):
            label = f"component {identifier}.outputs[{output_index}]"
            if not isinstance(output, dict):
                errors.append(f"{label} must be a table")
                continue
            output_id = output.get("id")
            if not isinstance(output_id, str) or not output_id:
                errors.append(f"{label} has no id")
            elif output_id in output_ids:
                errors.append(f"duplicate output in {identifier}: {output_id}")
            else:
                output_ids.add(output_id)
            accepted_set = _string_set(output.get("accepted_by"))
            if not accepted_set:
                errors.append(f"{label} has no trusted revalidator")
                accepted_set = set()
            elif not accepted_set <= TRUSTED_IDS:
                errors.append(f"{label} names an unknown trusted revalidator")
            expected_revalidators = EXPECTED_REVALIDATORS.get(output_id)
            if expected_revalidators is None or accepted_set != expected_revalidators:
                errors.append(f"{label} trusted revalidators are not pinned")
            evidence_set = _string_set(output.get("evidence"))
            if not evidence_set:
                errors.append(f"{label} has no evidence stages")
                evidence_set = set()
            for stage_id in evidence_set:
                stage = stage_by_id.get(stage_id)
                if stage is None:
                    errors.append(f"{label} names unknown evidence stage: {stage_id}")
            for checker in accepted_set:
                if not any(
                    checker in (_string_set(stage_by_id.get(stage_id, {}).get("trusted_components")) or set())
                    for stage_id in evidence_set
                ):
                    errors.append(f"{label} lacks evidence for trusted checker: {checker}")
            if "smt-solver" in accepted_set and not any(
                "smt-solver"
                in (_string_set(stage_by_id.get(stage_id, {}).get("trusted_components")) or set())
                for stage_id in evidence_set
            ):
                errors.append(f"{label} uses SMT without an SMT evidence stage")

        expected_output_ids = EXPECTED_OUTPUTS.get(identifier)
        if expected_output_ids is None or output_ids != expected_output_ids:
            missing_outputs = sorted((expected_output_ids or set()) - output_ids)
            extra_outputs = sorted(output_ids - (expected_output_ids or set()))
            if missing_outputs:
                errors.append(
                    f"missing required outputs for {identifier}: " + ", ".join(missing_outputs)
                )
            if extra_outputs:
                errors.append(
                    f"unlisted outputs for {identifier}: " + ", ".join(extra_outputs)
                )

    if set(component_by_id) != REQUIRED_COMPONENT_IDS:
        missing = sorted(REQUIRED_COMPONENT_IDS - set(component_by_id))
        extra = sorted(set(component_by_id) - REQUIRED_COMPONENT_IDS)
        if missing:
            errors.append("missing required components: " + ", ".join(missing))
        if extra:
            errors.append("unlisted components: " + ", ".join(extra))
    vm_component = component_by_id.get("firth.runtime.vm")
    if not isinstance(vm_component, dict) or vm_component.get("trusted") is not True:
        errors.append("firth.runtime.vm must be explicitly trusted")
    if not stage_by_id:
        errors.append("at least one verification stage is required")

    return errors


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open("rb") as handle:
        return tomllib.load(handle)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path("specs/tcb-boundary.toml"),
    )
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args(argv)
    try:
        manifest = load_manifest(args.manifest)
    except (OSError, tomllib.TOMLDecodeError) as error:
        print(f"tcb boundary check failed: {error}", file=sys.stderr)
        return 1
    errors = validate_manifest(manifest, args.root)
    if errors:
        print("tcb boundary check failed", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"tcb boundary check passed: {len(manifest['components'])} components, {len(manifest['stages'])} stages")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
