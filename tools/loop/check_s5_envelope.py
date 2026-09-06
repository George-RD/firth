#!/usr/bin/env python3
"""The pinned gate for PRD S5.

S5 asks for a non-trivial program written, verified to a stated specification,
and executed on the VM within a bounded cost envelope. This gate is the
executable form of that claim, and every clause of it is checked here rather
than asserted in prose:

* *written* and *non-trivial*: `examples/s5/protocol-handler.spec.toml`
  states the program's shape, and the gate checks the elaborated and compiled
  artefacts against it. A refactor that flattened the program into a
  straight-line sequence, inlined its handlers, or dropped its higher-order
  dispatch fails here rather than passing a weaker witness.
* *verified to a stated specification*: the specification states the declared
  word type of every definition, and the gate compares each one with the type
  the elaborator actually checked and the compiler rendered for the target.
* *executed on the VM*: the program is compiled and run through
  `firth.vm-run.v1`, and its observation is compared with the Lean reference
  interpreter's.
* *within a bounded cost envelope*: the VM's own charge must not exceed the
  stated envelope, and the kernel-comparable charge must equal the reference
  interpreter's exactly.

The gate is deterministic and is invoked by
`python3 tools/loop/coverage.py --run-gates`, which discards its output, so
every failure path returns a non-zero exit code.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

import tomllib

ROOT = Path(__file__).resolve().parents[2]
SPECIFICATION = ROOT / "examples" / "s5" / "protocol-handler.spec.toml"

GAMMA_VERSION = "0.1"
LANGUAGE_VERSION = "0.1"
TARGET_VERSION = "0.1"
TARGET_GAMMA_VERSION = 1

BUILD_TIMEOUT_SECONDS = 900
ADAPTER_TIMEOUT_SECONDS = 60

LEAN_ADAPTERS = ("firthElaborate", "firthCompile", "firthReferenceRun")
LEAN_BIN = ROOT / ".lake" / "build" / "bin"
VM_BINARY = ROOT / "src" / "runtime" / "vm" / "target" / "debug" / "firth-vm"


class GateError(Exception):
    """A deterministic gate violation."""


def fail(message: str) -> None:
    raise GateError(message)


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def run(command: list[str], *, cwd: Path, stdin: str | None, timeout: int) -> str:
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
    lake = shutil.which("lake")
    require(lake is not None, "toolchain: lake is not on PATH")
    cargo = shutil.which("cargo")
    require(cargo is not None, "toolchain: cargo is not on PATH")
    run([str(lake), "build", *LEAN_ADAPTERS], cwd=ROOT, stdin=None, timeout=BUILD_TIMEOUT_SECONDS)
    run(
        [str(cargo), "build", "--locked"],
        cwd=ROOT / "src" / "runtime" / "vm",
        stdin=None,
        timeout=BUILD_TIMEOUT_SECONDS,
    )


def adapter(command: list[str], request: dict[str, Any], cwd: Path, label: str) -> dict[str, Any]:
    output = run(command, cwd=cwd, stdin=json.dumps(request), timeout=ADAPTER_TIMEOUT_SECONDS)
    try:
        response = json.loads(output)
    except json.JSONDecodeError as error:
        fail(f"{label}: response is not JSON ({error})")
    if response.get("status") != "success":
        fail(f"{label}: status {response.get('status')!r}: {output.strip()[:400]}")
    return response


def load_specification() -> dict[str, Any]:
    if not SPECIFICATION.is_file():
        fail(f"specification: missing {SPECIFICATION.relative_to(ROOT)}")
    try:
        data = tomllib.loads(SPECIFICATION.read_text(encoding="utf-8"))
    except (OSError, tomllib.TOMLDecodeError) as error:
        fail(f"specification: invalid TOML ({error})")
    if data.get("specification_version") != 1:
        fail("specification_version: expected 1")
    for table in ("structure", "types", "behaviour", "cost"):
        if not isinstance(data.get(table), dict):
            fail(f"specification: missing [{table}]")
    source = data.get("source_path")
    if not isinstance(source, str) or Path(source).is_absolute():
        fail("source_path: expected a relative path")
    path = (ROOT / source).resolve()
    try:
        path.relative_to(ROOT)
    except ValueError:
        fail("source_path: path escapes the repository root")
    if not path.is_file():
        fail(f"source_path: missing {source}")
    data["_source"] = path
    return data


def check_structure(specification: dict[str, Any], elaboration: dict[str, Any]) -> None:
    """The program must still be the program the specification describes."""
    structure = specification["structure"]
    names = [word["name"] for word in elaboration["checked_words"]]
    require(
        names == structure["words"],
        f"structure.words: elaborated {names}, specified {structure['words']}",
    )
    require(
        structure["entry"] in names,
        f"structure.entry: unknown word {structure['entry']!r}",
    )

    programs = {item["word"]: item["program"] for item in elaboration["kernel_programs"]}
    quotations = sum(
        1
        for atom in programs[structure["entry"]] + programs["dispatch"]
        if atom.get("kind") == "quotation"
    )
    if structure.get("higher_order_dispatch"):
        require(quotations >= 2, "structure.higher_order_dispatch: no quotation is dispatched on")
        require(
            any(atom.get("kind") == "if" for atom in programs["dispatch"]),
            "structure.higher_order_dispatch: the dispatcher does not branch",
        )
    calls = sum(
        1
        for program in programs.values()
        for atom in flatten(program)
        if atom.get("kind") == "word"
    )
    require(
        calls == structure["dictionary_call_sites"],
        f"structure.dictionary_call_sites: found {calls}, specified "
        f"{structure['dictionary_call_sites']}",
    )


def flatten(program: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Every atom of a program, descending into quotation bodies."""
    atoms: list[dict[str, Any]] = []
    for atom in program:
        atoms.append(atom)
        if atom.get("kind") == "quotation":
            atoms.extend(flatten(atom["body"]))
    return atoms


def check_types(specification: dict[str, Any], target: dict[str, Any], names: list[str]) -> None:
    """Each declared word type must be the one the toolchain actually checked.

    The compiler mangles source names into the target `Name` grammar, so the
    two vectors are matched positionally: the compiler preserves the order the
    elaborator gave it, which `check_structure` has already pinned.
    """
    words = target["target_program"]["words"]
    require(
        len(words) == len(names),
        f"types: the compiler emitted {len(words)} words for {len(names)} definitions",
    )
    for name, word in zip(names, words):
        expected = specification["types"].get(name)
        require(expected is not None, f"types: no declared type for {name}")
        require(
            word["erased_word_type"] == expected,
            f"types.{name}: checked {word['erased_word_type']!r}, specified {expected!r}",
        )


def check_execution(
    specification: dict[str, Any], vm: dict[str, Any], reference: dict[str, Any]
) -> None:
    behaviour = specification["behaviour"]
    cost = specification["cost"]

    require(
        vm["stack"] == reference["stack"],
        f"execution: the VM left {json.dumps(vm['stack'])} and the reference "
        f"{json.dumps(reference['stack'])}",
    )
    require(vm["trap"] is None and reference["trap"] is None, "execution: a host trapped")
    require(
        len(vm["stack"]) == 1,
        f"behaviour.result: the session left {len(vm['stack'])} values, expected one",
    )
    literal = vm["stack"][0].get("literal", {})
    require(
        literal.get("value") == behaviour["result"],
        f"behaviour.result: got {literal.get('value')!r}, specified {behaviour['result']!r}",
    )

    require(
        vm["cost"]["kernel"] == reference["cost"]["total"],
        f"cost: the VM's kernel charge {vm['cost']['kernel']} does not equal the "
        f"reference charge {reference['cost']['total']}",
    )
    require(
        reference["cost"]["total"] == cost["kernel_cost"],
        f"cost.kernel_cost: measured {reference['cost']['total']}, specified {cost['kernel_cost']}",
    )
    require(
        vm["cost"]["total"] == cost["target_cost"],
        f"cost.target_cost: measured {vm['cost']['total']}, specified {cost['target_cost']}",
    )
    require(
        cost["target_cost"] <= cost["target_cost_envelope"],
        "cost: the stated target cost already exceeds the stated envelope",
    )
    require(
        vm["cost"]["total"] <= cost["target_cost_envelope"],
        f"cost: the execution charged {vm['cost']['total']}, outside the envelope "
        f"{cost['target_cost_envelope']}",
    )
    require(
        len(vm["trace"]) <= behaviour["fuel"],
        "execution: the VM trace is not bounded by the stated fuel budget",
    )
    # The VM charges exactly one administrative entry per dictionary call it
    # makes, so the gap between the two charges counts the calls the session
    # really made. A build that inlined the handlers would close that gap.
    made = vm["cost"]["total"] - vm["cost"]["kernel"]
    require(
        made == specification["structure"]["dictionary_calls_made"],
        f"structure.dictionary_calls_made: the session made {made} calls, specified "
        f"{specification['structure']['dictionary_calls_made']}",
    )


def main() -> int:
    try:
        specification = load_specification()
        build_toolchain()
        with tempfile.TemporaryDirectory(prefix="firth-s5-gate-") as directory:
            workspace = Path(directory)
            source_name = Path(specification["source_path"]).name
            scratch_source = workspace / source_name
            shutil.copyfile(specification["_source"], scratch_source)

            elaboration = adapter(
                [str(LEAN_BIN / "firthElaborate")],
                {
                    "request_id": "s5",
                    "source_path": source_name,
                    "source_text": scratch_source.read_text(encoding="utf-8"),
                    "language_version": LANGUAGE_VERSION,
                    "gamma_version": GAMMA_VERSION,
                },
                workspace,
                "elaborate",
            )
            check_structure(specification, elaboration)
            names = [word["name"] for word in elaboration["checked_words"]]

            target = adapter(
                [str(LEAN_BIN / "firthCompile")],
                {
                    "request_id": "s5",
                    "entry": specification["structure"]["entry"],
                    "checked_words": elaboration["checked_words"],
                    "erased_word_types": elaboration["erased_word_types"],
                    "gamma_version": GAMMA_VERSION,
                    "target_version": TARGET_VERSION,
                },
                workspace,
                "compile",
            )
            check_types(specification, target, names)

            behaviour = specification["behaviour"]
            vm = adapter(
                [str(VM_BINARY), "vm-run"],
                {
                    "request_id": "s5",
                    "target_program": target["target_program"],
                    "initial_stack": behaviour["initial_stack"],
                    "image": {"image_version": 1, "gamma_version": TARGET_GAMMA_VERSION},
                    "gamma_version": GAMMA_VERSION,
                    "fuel": behaviour["fuel"],
                },
                workspace,
                "vm-run",
            )

            programs = {item["word"]: item["program"] for item in elaboration["kernel_programs"]}
            entry = specification["structure"]["entry"]
            reference = adapter(
                [str(LEAN_BIN / "firthReferenceRun")],
                {
                    "request_id": "s5",
                    "checked_kernel": {
                        "checking_state": "checked",
                        "proof_state": "available",
                        "gamma_version": GAMMA_VERSION,
                        "program": programs[entry],
                    },
                    "initial_stack": behaviour["initial_stack"],
                    "dictionary": {
                        name: {
                            "checking_state": "checked",
                            "proof_state": "available",
                            "program": program,
                        }
                        for name, program in programs.items()
                        if name != entry
                    },
                    "gamma_version": GAMMA_VERSION,
                    "fuel": behaviour["fuel"],
                },
                workspace,
                "reference-run",
            )
            check_execution(specification, vm, reference)

        print(
            json.dumps(
                {
                    "status": "ok",
                    "entry": target["target_program"]["entry"],
                    "words": len(names),
                    "result": specification["behaviour"]["result"],
                    "kernel_cost": vm["cost"]["kernel"],
                    "target_cost": vm["cost"]["total"],
                    "envelope": specification["cost"]["target_cost_envelope"],
                },
                sort_keys=True,
                separators=(",", ":"),
            )
        )
        return 0
    except (GateError, KeyError, TypeError, OSError, UnicodeError) as error:
        print(json.dumps({"status": "error", "error": str(error)}, sort_keys=True), file=sys.stderr)
        return 1


if __name__ == "__main__":
    os.environ.setdefault("LC_ALL", "C")
    raise SystemExit(main())
