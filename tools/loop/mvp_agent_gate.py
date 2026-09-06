#!/usr/bin/env python3
"""The pinned MVP acceptance gate.

`dec.mvp-completion` clause 4, as amended by `dec.mvp-gate-provenance`, defines
the MVP as a working language an AI can use, via the agent guide, to build and
run basic applications. This gate is the executable half of that claim. It has
two jobs and fails closed on both.

Provenance. Before anything is executed it verifies
`tools/loop/mvp_agent_manifest.toml`: the guide and every pinned interface file
exists and hashes to the recorded digest, every application entry names a
source and a transcript that exist, each source hashes to its recorded digest,
and each transcript's recorded output hash equals the checked-in application's
own hash. A missing file, a stale hash, a malformed entry, or a manifest that
is not valid TOML stops the gate before a single adapter runs.

`dec.mvp-gate-provenance` clause 4 records the residual trust boundary in
writing: no gate can prove a transcript was not fabricated, since the loop is
itself a code model. What this half proves is byte-level drift detection, not
authorship.

Rebuild. Each manifest-listed application is then rebuilt in a scratch
workspace that holds only that application's source. The four pinned adapters
run against it in turn: elaborate, compile, run on the VM, and run on the Lean
reference interpreter. Terminal status, final stack and kernel-comparable cost are compared.
Trace lengths are bounded; full trace equivalence is not established. The
portable profile refuses effectful world observations.

The gate is deterministic: no clock, no randomness, no network, and a fixed
fuel budget. It is invoked by `python3 tools/loop/coverage.py --run-gates`,
which discards its output and kills it after a timeout, so every failure path
here also returns a non-zero exit code.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

import tomllib

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "tools" / "loop" / "mvp_agent_manifest.toml"
HASH = re.compile(r"^[0-9a-f]{64}$")

LANGUAGE_VERSION = "0.1"
GAMMA_VERSION = "0.1"
TARGET_VERSION = "0.1"
IMAGE_FORMAT_VERSION = 1
TARGET_GAMMA_VERSION = 1
FUEL = 4096

# A build must not outrun the coverage gate timeout, and an adapter that has
# not answered in a minute is a failure rather than something to wait out.
BUILD_TIMEOUT_SECONDS = 900
ADAPTER_TIMEOUT_SECONDS = 60

LEAN_ADAPTERS = ("firthElaborate", "firthCompile", "firthReferenceRun")
VM_BINARY = ROOT / "src" / "runtime" / "vm" / "target" / "debug" / "firth-vm"
LEAN_BIN = ROOT / ".lake" / "build" / "bin"


class GateError(Exception):
    """A deterministic gate violation."""


def fail(message: str) -> None:
    raise GateError(message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def manifest_path(value: Any, field: str) -> Path:
    """Resolves a manifest path, refusing anything that leaves the repository."""
    if not isinstance(value, str) or not value or Path(value).is_absolute():
        fail(f"{field}: expected a non-empty relative path")
    path = (ROOT / value).resolve()
    try:
        path.relative_to(ROOT)
    except ValueError:
        fail(f"{field}: path escapes the repository root")
    if not path.is_file():
        fail(f"{field}: missing file {value}")
    return path


def load_manifest() -> dict[str, Any]:
    try:
        return tomllib.loads(MANIFEST.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail("manifest: missing tools/loop/mvp_agent_manifest.toml")
    except (OSError, tomllib.TOMLDecodeError) as error:
        fail(f"manifest: invalid TOML ({error})")
    raise AssertionError("unreachable")


def verify_transcript(path: Path, entry: dict[str, Any], inputs: dict[str, Any]) -> None:
    """Bind the complete transcript, its declared inputs and the recorded source.

    This detects drift, not independent authorship. The latter cannot be proved
    from a transcript supplied by the same agent that supplied the program.
    """
    expected = entry.get("transcript_sha256")
    if not isinstance(expected, str) or not HASH.fullmatch(expected):
        fail("transcript_sha256: expected a lowercase SHA-256")
    if digest(path) != expected:
        fail("transcript_sha256: the transcript has drifted")
    text = path.read_bytes().decode("utf-8")
    parts = text.split("---\n", 2)
    if len(parts) != 3 or parts[0]:
        fail("transcript: missing frontmatter")
    metadata: dict[str, str] = {}
    for line in parts[1].splitlines():
        key, separator, value = line.partition(":")
        if not separator or key in metadata:
            fail("transcript: malformed or duplicate frontmatter field")
        metadata[key] = value.strip()
    if metadata.get("type") != "model-authorship-transcript":
        fail("transcript: wrong record type")
    if metadata.get("file") != entry["source_path"]:
        fail("transcript: records another source path")
    if metadata.get("output_sha256") != entry["source_sha256"]:
        fail("transcript: records an output that is not the checked-in source")
    sections = parts[2].split("## Model output\n")
    if len(sections) != 2:
        fail("transcript: expected one Model output section")
    recorded_inputs = re.findall(r"(?m)^- `([^`\n]+)`[ \t]*$", sections[0])
    if recorded_inputs != [inputs["guide_path"], *inputs["interface_paths"]]:
        fail("transcript: recorded inputs do not match the manifest")
    outputs = re.findall(r"(?ms)^```firth[ \t]*\n(.*?)^```[ \t]*$", sections[1])
    if len(outputs) != 1:
        fail("transcript: expected one Firth output block")
    if hashlib.sha256(outputs[0].encode("utf-8")).hexdigest() != entry["source_sha256"]:
        fail("transcript: model output bytes do not match the source")


def verify_provenance(data: dict[str, Any]) -> list[dict[str, str]]:
    """Verifies every pinned input and returns the application entries.

    Nothing is executed until this returns.
    """
    inputs = data.get("inputs")
    if not isinstance(inputs, dict):
        fail("inputs: expected a table")

    guide = manifest_path(data.get("guide_path"), "guide_path")
    if inputs.get("guide_path") != data.get("guide_path"):
        fail("inputs.guide_path: must equal guide_path")
    guide_hash = inputs.get("guide_sha256")
    if not isinstance(guide_hash, str) or not HASH.fullmatch(guide_hash):
        fail("inputs.guide_sha256: expected a lowercase SHA-256")
    if guide_hash != digest(guide):
        fail("inputs.guide_sha256: the guide has drifted from its pinned hash")

    interfaces = inputs.get("interface")
    if not isinstance(interfaces, list) or not interfaces:
        fail("inputs.interface: expected at least one table")
    listed = inputs.get("interface_paths")
    if not isinstance(listed, list) or not listed:
        fail("inputs.interface_paths: expected at least one path")
    seen: set[str] = set()
    for index, item in enumerate(interfaces):
        field = f"inputs.interface[{index}]"
        if not isinstance(item, dict):
            fail(f"{field}: expected a table")
        value = item.get("path")
        if value not in listed:
            fail(f"{field}.path: not listed in inputs.interface_paths")
        if value in seen:
            fail(f"{field}.path: duplicate interface path")
        seen.add(value)
        path = manifest_path(value, f"{field}.path")
        expected = item.get("sha256")
        if not isinstance(expected, str) or not HASH.fullmatch(expected):
            fail(f"{field}.sha256: expected a lowercase SHA-256")
        if expected != digest(path):
            fail(f"{field}.sha256: {value} has drifted from its pinned hash")
    if sorted(seen) != sorted(listed):
        fail("inputs.interface: paths must equal inputs.interface_paths")

    applications = data.get("applications")
    if not isinstance(applications, dict):
        fail("applications: expected a table")
    minimum = applications.get("minimum")
    if type(minimum) is not int or minimum < 3:
        fail("applications.minimum: expected an integer of at least 3")
    entries = applications.get("entries")
    if not isinstance(entries, list) or len(entries) < minimum:
        fail(f"applications.entries: expected at least {minimum} entries")

    verified: list[dict[str, str]] = []
    names: set[str] = set()
    for index, entry in enumerate(entries):
        field = f"applications.entries[{index}]"
        if not isinstance(entry, dict):
            fail(f"{field}: expected a table")
        for key in (
            "name",
            "source_path",
            "source_sha256",
            "transcript_path",
            "transcript_output_sha256",
        ):
            if key not in entry:
                fail(f"{field}.{key}: missing")
        name = entry["name"]
        if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", name):
            fail(f"{field}.name: expected a safe application name")
        if name in names:
            fail(f"{field}.name: duplicate application {name}")
        names.add(name)
        source = manifest_path(entry["source_path"], f"{field}.source_path")
        transcript = manifest_path(entry["transcript_path"], f"{field}.transcript_path")
        for key in ("source_sha256", "transcript_output_sha256"):
            if not isinstance(entry[key], str) or not HASH.fullmatch(entry[key]):
                fail(f"{field}.{key}: expected a lowercase SHA-256")
        actual = digest(source)
        if entry["source_sha256"] != actual:
            fail(f"{field}.source_sha256: {entry['source_path']} has drifted")
        if entry["transcript_output_sha256"] != actual:
            fail(
                f"{field}.transcript_output_sha256: the transcript records an output "
                f"that is not the checked-in {entry['source_path']}"
            )
        verify_transcript(transcript, entry, inputs)
        verified.append(
            {
                "name": name,
                "entry": entry.get("entry", name),
                "source_path": entry["source_path"],
                "source": str(source),
            }
        )
    return verified


def run(command: list[str], *, cwd: Path, stdin: str | None, timeout: int) -> str:
    """Runs one bounded subprocess, refusing anything but a clean exit."""
    try:
        completed = subprocess.run(
            command,
            cwd=cwd,
            input=stdin,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError:
        fail(f"toolchain: {command[0]} is not available")
    except subprocess.TimeoutExpired:
        fail(f"toolchain: {command[0]} did not answer within {timeout}s")
    if completed.returncode != 0:
        detail = (completed.stderr or completed.stdout).strip().splitlines()
        fail(f"{Path(command[0]).name}: exit {completed.returncode}: {detail[-1] if detail else ''}")
    return completed.stdout


def build_toolchain() -> None:
    """Builds the four pinned adapters.

    The gate refuses to run against a stale binary, so this is not optional.
    Both builds are incremental; a warm tree costs seconds.
    """
    lake = shutil.which("lake")
    if lake is None:
        fail("toolchain: lake is not on PATH")
    cargo = shutil.which("cargo")
    if cargo is None:
        fail("toolchain: cargo is not on PATH")
    run([lake, "build", *LEAN_ADAPTERS], cwd=ROOT, stdin=None, timeout=BUILD_TIMEOUT_SECONDS)
    run(
        [cargo, "build", "--locked"],
        cwd=ROOT / "src" / "runtime" / "vm",
        stdin=None,
        timeout=BUILD_TIMEOUT_SECONDS,
    )
    for name in LEAN_ADAPTERS:
        if not (LEAN_BIN / name).is_file():
            fail(f"toolchain: {name} was not built")
    if not VM_BINARY.is_file():
        fail("toolchain: firth-vm was not built")


def adapter(
    command: list[str], request: dict[str, Any], workspace: Path, label: str
) -> dict[str, Any]:
    output = run(
        command,
        cwd=workspace,
        stdin=json.dumps(request),
        timeout=ADAPTER_TIMEOUT_SECONDS,
    )
    try:
        response = json.loads(output)
    except json.JSONDecodeError as error:
        fail(f"{label}: response is not JSON ({error})")
    if not isinstance(response, dict):
        fail(f"{label}: response is not an object")
    if response.get("request_id") != request["request_id"]:
        fail(f"{label}: response does not echo the request id")
    return response


def expect_status(response: dict[str, Any], expected: str, label: str) -> None:
    if response.get("status") != expected:
        detail = response.get("compile_error") or response.get("diagnostics") or response
        fail(f"{label}: status {response.get('status')!r}, expected {expected!r}: {detail}")


def compare(reference: dict[str, Any], target: dict[str, Any], name: str,
            fuel: int = FUEL) -> None:
    """Compare terminal results and kernel costs; validate bounded traces.

    The two trace schemas differ. This does not assert trace equivalence or
    effectful equivalence: the portable adapter currently runs pure programs.
    """
    if reference.get("status") == "trap" and reference.get("trap") == "fuel-exhausted" \
            and target.get("status") == "trap" and target.get("trap") == "fuel-exhausted":
        # `[comparison] fuel_exhaustion = "bounded-fuel-inconclusive"`: a dual
        # exhaustion is never agreement, so it cannot pass the gate either.
        fail(f"{name}: both hosts exhausted the budget, which is inconclusive, not agreement")
    for side, observation in (("reference", reference), ("target", target)):
        required = {"status", "trap", "stack", "trace", "cost", "world_observation"}
        if not required.issubset(observation):
            fail(f"{name}: {side} observation is incomplete")
        if observation["status"] != "success" or observation["trap"] is not None:
            fail(f"{name}: {side} did not terminate successfully: {observation['trap']}")
        if not isinstance(observation["stack"], list):
            fail(f"{name}: {side} stack is not an array")
    if reference.get("status") != target.get("status"):
        fail(f"{name}: status {reference.get('status')!r} against {target.get('status')!r}")
    if reference.get("trap") != target.get("trap"):
        fail(f"{name}: trap {reference.get('trap')!r} against {target.get('trap')!r}")
    if reference.get("stack") != target.get("stack"):
        fail(
            f"{name}: residual stack {json.dumps(reference.get('stack'))} against "
            f"{json.dumps(target.get('stack'))}"
        )
    for side, observation in (("reference", reference), ("target", target)):
        trace = observation.get("trace")
        if not isinstance(trace, list):
            fail(f"{name}: {side} trace is not an array")
        if len(trace) > fuel:
            fail(f"{name}: {side} trace is not bounded by the fuel budget")
    reference_cost = reference.get("cost")
    target_cost = target.get("cost")
    if not isinstance(reference_cost, dict) or not isinstance(target_cost, dict):
        fail(f"{name}: a cost report is not an object")
    for side, report, keys in (
        ("reference", reference_cost, ("total", "steps")),
        ("target", target_cost, ("total", "kernel", "steps")),
    ):
        if any(type(report.get(key)) is not int or report[key] < 0 for key in keys):
            fail(f"{name}: {side} cost report is malformed")
    if target_cost["kernel"] > target_cost["total"]:
        fail(f"{name}: kernel cost exceeds target total")
    if reference_cost["total"] != target_cost["kernel"]:
        fail(
            f"{name}: cost {reference_cost.get('total')!r} against "
            f"{target_cost.get('kernel')!r} (target kernel cost)"
        )
    if reference["world_observation"] != {"ids": []} or target["world_observation"] != {"bytes": [0]}:
        fail(f"{name}: effectful observations are not supported by the portable comparison")


def initial_values(values: Any) -> list[dict[str, Any]]:
    """Encode portable input values once for both execution adapters."""
    if not isinstance(values, list):
        fail("initial stack: expected a JSON array")
    encoded = []
    for value in values:
        if type(value) is bool:
            kind = "bool"
        elif type(value) is int and 0 <= value <= 9223372036854775807:
            kind = "nat"
        else:
            fail("initial stack: use booleans or integers from 0 to 9223372036854775807")
        encoded.append({"kind": "literal", "literal": {"type": kind, "value": value}})
    return encoded


def checked_dictionary(elaboration: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Preserve evidence markers and bodies, including the root for recursion."""
    dictionary = {}
    for word in elaboration["checked_words"]:
        if not isinstance(word, dict) or not isinstance(word.get("name"), str) or not word["name"]:
            fail("elaborate: malformed checked word")
        name = word["name"]
        if name in dictionary:
            fail(f"elaborate: duplicate checked word {name}")
        if word.get("checking_state") != "checked" or word.get("proof_state") != "available":
            fail(f"elaborate: unavailable checking or proof for {name}")
        if not isinstance(word.get("program"), list):
            fail(f"elaborate: malformed program for {name}")
        dictionary[name] = {key: word[key] for key in ("checking_state", "proof_state", "program")}
    return dictionary


def validate_initial_stack(elaboration: dict[str, Any], entry: str,
                           stack: list[dict[str, Any]]) -> None:
    """Check external inputs against the selected word's erased boundary."""
    types = [item for item in elaboration["erased_word_types"] if item.get("word") == entry]
    if len(types) != 1:
        fail(f"entry {entry}: missing or ambiguous checked type")
    boundary = types[0]["type"]["input"]
    items = boundary["items"]
    if len(stack) < len(items) or (boundary["row"] is None and len(stack) != len(items)):
        fail(f"entry {entry}: initial stack does not match its declared input count")
    suffix = stack[len(stack) - len(items):] if items else []
    for expected, value in zip(items, suffix):
        actual = "Int" if value["literal"]["type"] == "nat" else "Bool"
        if expected != {"kind": "base", "name": actual, "usage": "many"}:
            fail(f"entry {entry}: initial stack type mismatch; expected {expected}, got {actual}")


def rebuild(entry: dict[str, Any], workspace: Path, *,
            stack: list[Any] | None = None, fuel: int = FUEL) -> dict[str, Any]:
    """Rebuilds one application in a workspace holding only its source."""
    name = entry["name"]
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", name):
        fail("application: unsafe scratch directory name")
    if type(fuel) is not int or not 0 <= fuel <= 100000:
        fail("fuel: expected an integer from 0 to 100000")
    initial_stack = initial_values([] if stack is None else stack)
    entry_word = entry.get("entry", name)
    scratch = workspace / name
    scratch.mkdir()
    source_name = Path(entry["source_path"]).name
    scratch_source = scratch / source_name
    shutil.copyfile(entry["source"], scratch_source)
    if sorted(item.name for item in scratch.iterdir()) != [source_name]:
        fail(f"{name}: the scratch workspace holds more than the application source")

    elaboration = adapter(
        [str(LEAN_BIN / "firthElaborate")],
        {
            "request_id": name,
            "source_path": source_name,
            "source_text": scratch_source.read_text(encoding="utf-8"),
            "language_version": LANGUAGE_VERSION,
            "gamma_version": GAMMA_VERSION,
        },
        scratch,
        f"{name} elaborate",
    )
    expect_status(elaboration, "success", f"{name} elaborate")
    for key in ("checked_words", "erased_word_types", "kernel_programs"):
        if not isinstance(elaboration.get(key), list) or not elaboration[key]:
            fail(f"{name} elaborate: {key} is empty")

    dictionary = checked_dictionary(elaboration)
    if not isinstance(entry_word, str) or entry_word not in dictionary:
        fail(f"entry: unknown checked word {entry_word!r}")
    validate_initial_stack(elaboration, entry_word, initial_stack)

    target_program = adapter(
        [str(LEAN_BIN / "firthCompile")],
        {
            "request_id": name,
            "entry": entry_word,
            "checked_words": elaboration["checked_words"],
            "erased_word_types": elaboration["erased_word_types"],
            "gamma_version": GAMMA_VERSION,
            "target_version": TARGET_VERSION,
        },
        scratch,
        f"{name} compile",
    )
    expect_status(target_program, "success", f"{name} compile")

    vm = adapter(
        [str(VM_BINARY), "vm-run"],
        {
            "request_id": name,
            "target_program": target_program["target_program"],
            "initial_stack": initial_stack,
            "image": {
                "image_version": 1,
                "gamma_version": TARGET_GAMMA_VERSION,
            },
            "gamma_version": GAMMA_VERSION,
            "fuel": fuel,
        },
        scratch,
        f"{name} vm-run",
    )
    expect_status(vm, "success", f"{name} vm-run")

    reference = adapter(
        [str(LEAN_BIN / "firthReferenceRun")],
        {
            "request_id": name,
            "checked_kernel": {
                **dictionary[entry_word],
                "gamma_version": GAMMA_VERSION,
            },
            "initial_stack": initial_stack,
            "dictionary": dictionary,
            "gamma_version": GAMMA_VERSION,
            "fuel": fuel,
        },
        scratch,
        f"{name} reference-run",
    )
    expect_status(reference, "success", f"{name} reference-run")

    compare(reference, vm, name, fuel)
    return {
        "name": name,
        "entry": entry_word,
        "target_entry": target_program["target_program"]["entry"],
        "words": len(target_program["target_program"]["words"]),
        "stack": vm["stack"],
        "cost": vm["cost"]["total"],
        "kernel_cost": vm["cost"]["kernel"],
        "fuel": fuel,
    }


def main() -> int:
    try:
        data = load_manifest()
        entries = verify_provenance(data)
        build_toolchain()
        with tempfile.TemporaryDirectory(prefix="firth-mvp-gate-") as directory:
            workspace = Path(directory)
            results = [rebuild(entry, workspace) for entry in entries]
        print(
            json.dumps(
                {
                    "status": "ok",
                    "applications": results,
                    "fuel": FUEL,
                    "manifest": "tools/loop/mvp_agent_manifest.toml",
                },
                sort_keys=True,
                separators=(",", ":"),
            )
        )
        return 0
    except (GateError, OSError, UnicodeError) as error:
        print(
            json.dumps({"status": "error", "error": str(error)}, sort_keys=True),
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    os.environ.setdefault("LC_ALL", "C")
    raise SystemExit(main())
