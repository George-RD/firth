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
  dispatch fails here rather than passing a weaker witness. The specification's
  claim that both `if` branches are taken is proved from the two execution
  traces: each host must select on both `true` and `false`, and every handler
  named inside a dispatch quotation must run on both hosts. A one-branch
  session is executed as a negative control and must fail that witness.
* *verified to a stated specification*: the specification states the declared
  word type of every definition, and the gate compares each one with the type
  the elaborator actually checked and the compiler rendered for the target.
  The compiled entry must be the specified entry, and every declared
  specification field must have been checked; an unread field fails the gate.
* *executed on the VM*: the program is compiled and run through
  `firth.vm-run.v1`, and its observation is compared with the Lean reference
  interpreter's, including the per-event trace comparison of the MVP gate,
  whose label is recorded (the dispatch quotations make it
  `unsupported-quotation-values`, which is neither failure nor agreement).
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

import mvp_agent_gate as gate

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

# The specification tables, every field of which must be read by a check.
TABLES = ("structure", "types", "behaviour", "cost")
# The word whose `if` selects a handler quotation.
DISPATCHER = "dispatch"
# The shipped session and the one-branch negative control that must fail.
SESSION_BODY = "0 true dispatch false dispatch true dispatch;"
ONE_BRANCH_BODY = "0 true dispatch true dispatch true dispatch;"


class GateError(Exception):
    """A deterministic gate violation."""


def fail(message: str) -> None:
    raise GateError(message)


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


class Tracked(dict):
    """A specification table that records which of its fields were read.

    A field the specification declares but no check reads is a claim the gate
    would be passing on prose alone, so `unread` must be empty at the end.
    """

    def __init__(self, values: dict[str, Any]) -> None:
        super().__init__(values)
        self.read: set[str] = set()

    def __getitem__(self, key: str) -> Any:
        self.read.add(key)
        return super().__getitem__(key)

    def get(self, key: str, default: Any = None) -> Any:
        self.read.add(key)
        return super().get(key, default)

    def unread(self) -> list[str]:
        return sorted(set(self) - self.read)


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
    for table in TABLES:
        if not isinstance(data.get(table), dict):
            fail(f"specification: missing [{table}]")
        data[table] = Tracked(data[table])
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


def unread_fields(specification: dict[str, Any]) -> list[str]:
    """Every declared specification field no check has read."""
    return [
        f"{table}.{key}"
        for table in TABLES
        for key in specification[table].unread()
    ]


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
        for atom in programs[structure["entry"]] + programs[DISPATCHER]
        if atom.get("kind") == "quotation"
    )
    if structure.get("higher_order_dispatch"):
        require(quotations >= 2, "structure.higher_order_dispatch: no quotation is dispatched on")
        require(
            any(atom.get("kind") == "if" for atom in programs[DISPATCHER]),
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


def target_names(target: dict[str, Any], names: list[str]) -> dict[str, str]:
    """Map each source word to the compiler's mangled target name.

    The compiler mangles source names into the target `Name` grammar, so the
    two vectors are matched positionally: the compiler preserves the order the
    elaborator gave it, which `check_structure` has already pinned.
    """
    words = target["target_program"]["words"]
    require(
        len(words) == len(names),
        f"types: the compiler emitted {len(words)} words for {len(names)} definitions",
    )
    return {name: word["name"] for name, word in zip(names, words)}


def check_entry(specification: dict[str, Any], target: dict[str, Any], mangled: dict[str, str]) -> None:
    """The compiled entry must be the specified entry, not merely some word."""
    entry = specification["structure"]["entry"]
    compiled = target["target_program"]["entry"]
    require(
        compiled == mangled[entry],
        f"structure.entry: the compiler emitted entry {compiled!r}, the specification "
        f"names {entry!r} (target {mangled[entry]!r})",
    )


def check_types(specification: dict[str, Any], target: dict[str, Any], names: list[str]) -> None:
    """Each declared word type must be the one the toolchain actually checked."""
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


def dispatched_handlers(programs: dict[str, list[dict[str, Any]]]) -> list[str]:
    """Every word named inside the dispatcher's quotation bodies, in order."""
    handlers: list[str] = []
    for atom in programs[DISPATCHER]:
        if atom.get("kind") == "quotation":
            for inner in flatten(atom["body"]):
                if inner.get("kind") == "word" and inner["name"] not in handlers:
                    handlers.append(inner["name"])
    return handlers


def selected_condition(stack: list[Any], label: str) -> bool:
    """The Boolean an `if` step selects on: third from the top of its stack."""
    require(len(stack) >= 3, f"{label}: an if step has fewer than three values")
    condition = stack[-3]
    require(
        isinstance(condition, dict) and condition.get("kind") == "literal"
        and isinstance(condition.get("literal"), dict)
        and condition["literal"].get("type") == "bool"
        and type(condition["literal"].get("value")) is bool,
        f"{label}: an if step does not select on a Boolean literal",
    )
    return condition["literal"]["value"]


def check_branches(
    specification: dict[str, Any],
    elaboration: dict[str, Any],
    target: dict[str, Any],
    vm: dict[str, Any],
    reference: dict[str, Any],
    mangled: dict[str, str],
) -> dict[str, Any]:
    """Prove `structure.both_branches_taken` from the two execution traces.

    Both traces record the stack before each step. On the reference side an
    `if` step is an event whose residual program starts with the `if` atom;
    on the VM side it is an event of the dispatcher word at the index of its
    `IF` instruction. Each side must have selected on both `true` and
    `false`. Every handler word named inside a dispatch quotation must then
    appear as an executed word: as a `word` atom at the head of a reference
    event's program, and as the `word` of a VM trace event under its mangled
    target name. A session that only ever selects one branch fails here.
    """
    structure = specification["structure"]
    require(
        structure["both_branches_taken"] is True,
        "structure.both_branches_taken: the witness must declare both branches taken",
    )
    programs = {item["word"]: item["program"] for item in elaboration["kernel_programs"]}
    handlers = dispatched_handlers(programs)
    require(
        len(handlers) >= 2,
        "structure.both_branches_taken: the dispatcher names fewer than two handlers",
    )
    for handler in handlers:
        require(handler in mangled, f"structure.both_branches_taken: unknown handler {handler!r}")

    reference_conditions: set[bool] = set()
    reference_words: set[str] = set()
    for event in reference["trace"]:
        program = event["program"]
        if program and program[0] == {"kind": "if"}:
            reference_conditions.add(selected_condition(event["stack"], "reference trace"))
        if program and program[0].get("kind") == "word":
            reference_words.add(program[0]["name"])

    dispatcher = mangled[DISPATCHER]
    dispatcher_code = next(
        word["code"] for word in target["target_program"]["words"] if word["name"] == dispatcher
    )
    if_indices = {index for index, instruction in enumerate(dispatcher_code) if instruction["op"] == "if"}
    require(if_indices, "structure.both_branches_taken: the compiled dispatcher has no IF")
    vm_conditions: set[bool] = set()
    vm_words = {event["word"] for event in vm["trace"]}
    for event in vm["trace"]:
        if event["word"] == dispatcher and event["pc"] in if_indices:
            vm_conditions.add(selected_condition(event["stack"], "VM trace"))

    require(
        reference_conditions == {True, False},
        "structure.both_branches_taken: the reference selected only "
        f"{sorted(reference_conditions)} at its if steps",
    )
    require(
        vm_conditions == {True, False},
        f"structure.both_branches_taken: the VM selected only {sorted(vm_conditions)} at its if steps",
    )
    for handler in handlers:
        require(
            handler in reference_words,
            f"structure.both_branches_taken: the reference trace never unfolded {handler}",
        )
        require(
            mangled[handler] in vm_words,
            f"structure.both_branches_taken: the VM trace never entered {handler} "
            f"(target {mangled[handler]})",
        )
    return {
        "handlers": handlers,
        "reference_conditions": sorted(reference_conditions),
        "vm_conditions": sorted(vm_conditions),
    }


def check_execution(
    specification: dict[str, Any], vm: dict[str, Any], reference: dict[str, Any]
) -> str:
    """Terminal result, cost envelope and the per-event trace comparison."""
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
    # The same per-event comparison the MVP gate makes. The dispatch quotations
    # sit on intermediate stacks, so the expected label is the explicit
    # unsupported one, never a stack-for-stack agreement claim.
    try:
        return gate.compare_traces(reference, vm, "s5")
    except gate.GateError as error:
        fail(f"execution: {error}")
    raise AssertionError("unreachable")


def execute_session(
    workspace: Path, source_name: str, source_text: str, specification: dict[str, Any], label: str
) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any], dict[str, Any]]:
    """Elaborate, compile and run one session on both hosts."""
    elaboration = adapter(
        [str(LEAN_BIN / "firthElaborate")],
        {
            "request_id": label,
            "source_path": source_name,
            "source_text": source_text,
            "language_version": LANGUAGE_VERSION,
            "gamma_version": GAMMA_VERSION,
        },
        workspace,
        f"{label} elaborate",
    )
    target = adapter(
        [str(LEAN_BIN / "firthCompile")],
        {
            "request_id": label,
            "entry": specification["structure"]["entry"],
            "checked_words": elaboration["checked_words"],
            "erased_word_types": elaboration["erased_word_types"],
            "gamma_version": GAMMA_VERSION,
            "target_version": TARGET_VERSION,
        },
        workspace,
        f"{label} compile",
    )
    behaviour = specification["behaviour"]
    vm = adapter(
        [str(VM_BINARY), "vm-run"],
        {
            "request_id": label,
            "target_program": target["target_program"],
            "initial_stack": behaviour["initial_stack"],
            "image": {"image_version": 1, "gamma_version": TARGET_GAMMA_VERSION},
            "gamma_version": GAMMA_VERSION,
            "fuel": behaviour["fuel"],
        },
        workspace,
        f"{label} vm-run",
    )
    programs = {item["word"]: item["program"] for item in elaboration["kernel_programs"]}
    entry = specification["structure"]["entry"]
    reference = adapter(
        [str(LEAN_BIN / "firthReferenceRun")],
        {
            "request_id": label,
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
        f"{label} reference-run",
    )
    return elaboration, target, vm, reference


def one_branch_session(source_text: str) -> str:
    """The shipped source with a session that only ever selects `true`."""
    require(SESSION_BODY in source_text, "negative control: the shipped session body was not found")
    return source_text.replace(SESSION_BODY, ONE_BRANCH_BODY)


def main() -> int:
    try:
        specification = load_specification()
        build_toolchain()
        with tempfile.TemporaryDirectory(prefix="firth-s5-gate-") as directory:
            workspace = Path(directory)
            source_name = Path(specification["source_path"]).name
            scratch_source = workspace / source_name
            shutil.copyfile(specification["_source"], scratch_source)
            source_text = scratch_source.read_text(encoding="utf-8")

            elaboration, target, vm, reference = execute_session(
                workspace, source_name, source_text, specification, "s5"
            )
            check_structure(specification, elaboration)
            names = [word["name"] for word in elaboration["checked_words"]]
            mangled = target_names(target, names)
            check_entry(specification, target, mangled)
            check_types(specification, target, names)
            branches = check_branches(specification, elaboration, target, vm, reference, mangled)
            trace_comparison = check_execution(specification, vm, reference)

            # Negative control: the same program with a session that selects
            # only one branch must fail the branch witness, on real hosts.
            control = execute_session(
                workspace, source_name, one_branch_session(source_text), specification, "s5-one-branch"
            )
            control_mangled = target_names(control[1], [word["name"] for word in control[0]["checked_words"]])
            try:
                check_branches(specification, control[0], control[1], control[2], control[3], control_mangled)
            except GateError as error:
                require(
                    "both_branches_taken" in str(error),
                    f"negative control: the one-branch session failed for another reason: {error}",
                )
            else:
                fail("negative control: a one-branch session passed the both-branches witness")

        unread = unread_fields(specification)
        require(not unread, f"specification: declared fields never checked: {unread}")

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
                    "both_branches_taken": branches,
                    "trace_comparison": trace_comparison,
                    "negative_control": "one-branch-session-refused",
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
