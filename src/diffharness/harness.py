#!/usr/bin/env python3
"""Seeded, replayable differential execution of Firth's pure source profile."""
from __future__ import annotations

import argparse
import base64
import dataclasses
import hashlib
import json
import os
from pathlib import Path
import random
import selectors
import signal
import subprocess
import sys
import tempfile
import time
from typing import Any, Callable, Iterator

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "loop"))
import mvp_agent_gate as gate

VERSION = "firth-portable-diff-v1"
SCHEMA = "firth-differential-failure-v1"
MAX_INT = 2**63 - 1
MAX_OUTPUT = 4 * 1024 * 1024
MAX_ARTIFACT = 64 * 1024 * 1024
OPS = ("add", "double", "call", "qualified", "local", "quote-call",
       "quoted-value", "compose", "dip", "if", "nested", "swap")
SIGNATURE = "(forall ρ; ρ n:Int^many -- ρ result:Int^many)"


class HarnessError(Exception):
    """A configuration or replay error, not a passing differential result."""


def strict_json(text: str) -> Any:
    return json.loads(text, object_pairs_hook=gate._json_object,
                      parse_constant=gate._json_constant, parse_float=gate._json_float)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def bounded_int(value: Any, low: int, high: int, label: str) -> int:
    if type(value) is not int or not low <= value <= high:
        raise HarnessError(f"{label}: expected an integer from {low} to {high}")
    return value


@dataclasses.dataclass(frozen=True)
class Step:
    op: str
    a: int = 0
    b: int = 0
    flag: bool = False

    def validate(self) -> None:
        if self.op not in OPS or type(self.flag) is not bool:
            raise HarnessError("invalid generated step")
        bounded_int(self.a, 0, 100, "step.a")
        bounded_int(self.b, 0, 100, "step.b")

    def render(self, index: int) -> tuple[str, str]:
        a, b = self.a, self.b
        if self.op == "call":
            return f"bump{index}", f": bump{index} {SIGNATURE} {a} prim +;"
        if self.op == "qualified":
            return f"v{index}.bump", f"vocab v{index} {{ : bump {SIGNATURE} {a} prim +; }}"
        bodies = {
            "add": f"{a} prim +",
            "double": "dup prim +",
            "local": f"locals {{ n }} {{ n {a} prim + }}",
            "quote-call": f"[ {a} prim + ] call",
            "quoted-value": f"{a} quote call prim +",
            "compose": f"[ {a} prim + ] [ {b} prim + ] compose call",
            "dip": f"{a} [ dup prim + ] dip prim +",
            "if": f"{str(self.flag).lower()} [ {a} prim + ] [ {b} prim + ] if",
            "nested": f"[ [ {a} prim + ] call ] call",
            "swap": f"{a} swap prim +",
        }
        return bodies[self.op], ""


@dataclasses.dataclass(frozen=True)
class Case:
    seed: int
    index: int
    steps: tuple[Step, ...]
    value: int
    flag: bool
    prefix: tuple[int | bool, ...] = ()
    unused: bool = True
    fuel: int = 4096

    def validate(self) -> None:
        bounded_int(self.seed, 0, 2**64 - 1, "seed")
        bounded_int(self.index, 0, 1000000, "index")
        bounded_int(self.value, 0, 100, "input")
        bounded_int(self.fuel, 0, 100000, "fuel")
        if type(self.flag) is not bool or type(self.unused) is not bool:
            raise HarnessError("case flags must be Boolean")
        if len(self.steps) > 24 or len(self.prefix) > 4:
            raise HarnessError("case exceeds the generation bounds")
        for step in self.steps:
            step.validate()
        try:
            gate.initial_values(list(self.prefix))
        except gate.GateError as error:
            raise HarnessError(str(error)) from error

    @property
    def source(self) -> str:
        bodies, definitions = [], []
        for index, step in enumerate(self.steps):
            body, definition = step.render(index)
            bodies.append(body)
            if definition:
                definitions.append(definition)
        text = [": main (forall ρ; ρ n:Int^many flag:Bool^many -- ρ result:Int^many)",
                "  [ ] [ dup drop ] if", *("  " + body for body in bodies), ";"]
        text.extend(definitions)
        if self.unused:
            text.append(": unused ( -- result:Int^many ) 999;")
        return "\n".join(text) + "\n"

    @property
    def stack(self) -> list[int | bool]:
        return [*self.prefix, self.value, self.flag]

    @property
    def features(self) -> list[str]:
        return sorted({step.op for step in self.steps} | {f"external-if-{self.flag}"})

    @property
    def complexity(self) -> tuple[int, int, int, int]:
        return (int(self.unused), len(self.steps), len(self.prefix),
                self.value + int(self.flag) + sum(int(x) for x in self.prefix)
                + sum(s.a + s.b + int(s.flag) for s in self.steps))

    def payload(self) -> dict[str, Any]:
        return {"seed": self.seed, "index": self.index,
                "steps": [dataclasses.asdict(step) for step in self.steps],
                "value": self.value, "flag": self.flag, "prefix": list(self.prefix),
                "unused": self.unused, "fuel": self.fuel}

    @classmethod
    def from_payload(cls, data: Any) -> Case:
        if not isinstance(data, dict) or set(data) != {
                "seed", "index", "steps", "value", "flag", "prefix", "unused", "fuel"}:
            raise HarnessError("invalid case recipe fields")
        if not isinstance(data["steps"], list) or not isinstance(data["prefix"], list):
            raise HarnessError("invalid case recipe arrays")
        steps = []
        for item in data["steps"]:
            if not isinstance(item, dict) or set(item) != {"op", "a", "b", "flag"}:
                raise HarnessError("invalid step fields")
            if not isinstance(item["op"], str):
                raise HarnessError("invalid step operator")
            steps.append(Step(**item))
        case = cls(**{**data, "steps": tuple(steps), "prefix": tuple(data["prefix"])})
        case.validate()
        return case


def generate(seed: int, index: int, size: int = 6, fuel: int = 4096) -> Case:
    bounded_int(seed, 0, 2**64 - 1, "seed")
    bounded_int(index, 0, 1000000, "index")
    bounded_int(size, 1, 24, "size")
    rng = random.Random(int.from_bytes(hashlib.sha256(f"{VERSION}:{seed}:{index}".encode()).digest(), "big"))
    # One rotating feature provides a coverage floor; the remaining composition
    # and all operands vary by seed. Indexing does not consume earlier cases.
    ops = [OPS[index % len(OPS)]] + [rng.choice(OPS) for _ in range(rng.randrange(size))]
    case = Case(seed, index, tuple(Step(op, rng.randrange(51), rng.randrange(51),
                                      bool(rng.getrandbits(1))) for op in ops),
                rng.randrange(101), bool(index % 2),
                tuple(rng.choice((False, True, rng.randrange(101))) for _ in range(rng.randrange(3))),
                fuel=fuel)
    case.validate()
    return case


@dataclasses.dataclass
class Result:
    kind: str
    stage: str = "compare"
    detail: str = ""
    records: list[dict[str, Any]] = dataclasses.field(default_factory=list)
    traps: tuple[str | None, str | None] = (None, None)

    @property
    def signature(self) -> tuple[Any, ...]:
        return (self.kind, self.stage, *self.traps)


class AdapterError(Exception):
    def __init__(self, kind: str, record: dict[str, Any]):
        super().__init__(kind)
        self.kind, self.record = kind, record


def invoke(command: tuple[str, ...], request: dict[str, Any], cwd: Path,
           timeout: float = 15, output_limit: int = MAX_OUTPUT) -> dict[str, Any]:
    """Bound all pipes, including a child/descendant that never closes stdout."""
    if not isinstance(timeout, (int, float)) or not 0 < timeout <= 60:
        raise HarnessError("adapter timeout must be positive and at most 60 seconds")
    bounded_int(output_limit, 1, MAX_OUTPUT, "adapter output limit")
    record: dict[str, Any] = {"command": list(command), "request": request}
    data = memoryview(json.dumps(request).encode())
    chunks: dict[str, bytearray] = {"stdout": bytearray(), "stderr": bytearray()}
    problem = None
    try:
        child = subprocess.Popen(command, cwd=cwd, stdin=subprocess.PIPE,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                 start_new_session=True)
    except OSError as error:
        record["error"] = str(error)
        raise AdapterError("adapter-unavailable", record) from error
    deadline = time.monotonic() + timeout
    try:
        with selectors.DefaultSelector() as selector:
            for stream, label, events in ((child.stdin, "stdin", selectors.EVENT_WRITE),
                                          (child.stdout, "stdout", selectors.EVENT_READ),
                                          (child.stderr, "stderr", selectors.EVENT_READ)):
                os.set_blocking(stream.fileno(), False)
                selector.register(stream, events, label)
            while selector.get_map():
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    problem = "adapter-timeout"
                    break
                for key, _ in selector.select(remaining):
                    stream, label = key.fileobj, key.data
                    if label == "stdin":
                        try:
                            count = os.write(stream.fileno(), data[:65536])
                            data = data[count:]
                        except BrokenPipeError:
                            data = data[len(data):]
                        if not data:
                            selector.unregister(stream)
                            stream.close()
                    else:
                        chunk = os.read(stream.fileno(), 65536)
                        if not chunk:
                            selector.unregister(stream)
                            stream.close()
                        else:
                            room = max(0, output_limit - sum(len(v) for v in chunks.values()))
                            chunks[label].extend(chunk[:room])
                            if len(chunk) > room:
                                problem = "adapter-output-limit"
                                break
                if problem:
                    break
            if problem is None:
                try:
                    child.wait(timeout=max(0.001, deadline - time.monotonic()))
                except subprocess.TimeoutExpired:
                    problem = "adapter-timeout"
    finally:
        # A process group also covers descendants inheriting output handles.
        try:
            os.killpg(child.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        child.wait()
        for stream in (child.stdin, child.stdout, child.stderr):
            if not stream.closed:
                stream.close()
    record["exit_code"] = child.returncode
    for label, content in chunks.items():
        try:
            record[label] = content.decode("utf-8")
        except UnicodeError:
            record[label] = content.decode("utf-8", errors="replace")
            record[label + "_base64"] = base64.b64encode(content).decode("ascii")
            problem = problem or "adapter-invalid-utf8"
    if problem:
        record["error"] = problem
        raise AdapterError(problem, record)
    if child.returncode != 0:
        raise AdapterError("adapter-crash", record)
    try:
        response = strict_json(record["stdout"])
        if not isinstance(response, dict) or response.get("request_id") != request["request_id"]:
            raise ValueError("response must be an object echoing request_id")
        record["response"] = response
    except (ValueError, RecursionError) as error:
        record["error"] = str(error)
        raise AdapterError("adapter-protocol-error", record) from error
    return record


def compare(reference: Any, target: Any, fuel: int) -> Result:
    required = {"status", "trap", "stack", "trace", "cost", "world_observation"}
    for side, observation in (("reference", reference), ("target", target)):
        if not isinstance(observation, dict) or not required <= observation.keys():
            return Result("invalid-observation", detail=f"{side}: incomplete observation")
        status, trap = observation["status"], observation["trap"]
        if status not in ("success", "trap") or ((status == "success") != (trap is None)) \
                or (status == "trap" and (not isinstance(trap, str) or not trap)):
            return Result("invalid-observation", detail=f"{side}: malformed status/trap")
    traps = (reference["trap"], target["trap"])
    if traps == ("fuel-exhausted", "fuel-exhausted"):
        return Result("bounded-fuel-inconclusive", traps=traps)
    if "fuel-exhausted" in traps:
        return Result("fuel-asymmetry", traps=traps)
    if any(traps):
        # The reference's natural integers are wider than the portable Rust
        # profile. An overflow is explicit non-success, never an agreement.
        if traps == (None, "primitive-fault") and isinstance(reference["stack"], list) \
                and any(isinstance(v, dict) and isinstance(v.get("literal"), dict)
                        and v["literal"].get("type") == "nat"
                        and type(v["literal"].get("value")) is int
                        and v["literal"]["value"] > MAX_INT for v in reference["stack"]):
            return Result("portable-integer-overflow", traps=traps)
        return Result("runtime-trap" if traps[0] == traps[1] else "trap-mismatch", traps=traps)
    try:
        for side, observation in (("reference", reference), ("target", target)):
            gate.validate_portable_stack(observation["stack"], side)
        gate.validate_pure_world(reference["world_observation"], target["world_observation"], "case")
        # Validate costs and traces before giving a more specific mismatch code.
        for side, observation, keys in (("reference", reference, ("total", "steps")),
                                        ("target", target, ("total", "kernel", "steps"))):
            cost = observation["cost"]
            if not isinstance(cost, dict) or any(type(cost.get(k)) is not int or cost[k] < 0 for k in keys):
                raise gate.GateError(f"{side}: invalid cost")
            if not isinstance(observation["trace"], list) or len(observation["trace"]) > fuel:
                raise gate.GateError(f"{side}: invalid trace")
        if target["cost"]["kernel"] > target["cost"]["total"]:
            raise gate.GateError("target: kernel cost exceeds total")
    except gate.GateError as error:
        return Result("invalid-observation", detail=str(error))
    if reference["stack"] != target["stack"]:
        return Result("stack-mismatch")
    if reference["cost"]["total"] != target["cost"]["kernel"]:
        return Result("kernel-cost-mismatch")
    try:
        gate.compare(reference, target, "case", fuel)
    except gate.GateError as error:
        return Result("invalid-observation", detail=str(error))
    return Result("agreement")


class Executor:
    def __init__(self, commands: dict[str, tuple[str, ...]] | None = None,
                 timeout: float = 15, output_limit: int = MAX_OUTPUT):
        self.commands = commands or {
            "elaborate": (str(gate.LEAN_BIN / "firthElaborate"),),
            "compile": (str(gate.LEAN_BIN / "firthCompile"),),
            "reference": (str(gate.LEAN_BIN / "firthReferenceRun"),),
            "target": (str(gate.VM_BINARY), "vm-run"),
        }
        self.timeout, self.output_limit = timeout, output_limit

    def __call__(self, case: Case) -> Result:
        case.validate()
        records: list[dict[str, Any]] = []
        stage = "elaborate"
        with tempfile.TemporaryDirectory(prefix="firth-diff-") as directory:
            workspace = Path(directory)
            (workspace / "case.firth").write_text(case.source, encoding="utf-8")

            def call(name: str, request: dict[str, Any]) -> dict[str, Any]:
                nonlocal stage
                stage = name
                record = invoke(self.commands[name], {"request_id": "differential", **request},
                                workspace, self.timeout, self.output_limit)
                record["stage"] = name
                records.append(record)
                return record["response"]

            try:
                elaboration = call("elaborate", {"source_path": "case.firth", "source_text": case.source,
                    "language_version": gate.LANGUAGE_VERSION, "gamma_version": gate.GAMMA_VERSION})
                if elaboration.get("status") != "success":
                    return Result("elaboration-rejected", stage, records=records)
                for field in ("checked_words", "erased_word_types", "kernel_programs"):
                    if not isinstance(elaboration.get(field), list) or not elaboration[field]:
                        raise ValueError(f"elaborate: missing {field}")
                dictionary = gate.checked_dictionary(elaboration)
                initial = gate.initial_values(case.stack)
                gate.validate_initial_stack(elaboration, "main", initial)
                reference = call("reference", {"checked_kernel": {
                    **dictionary["main"], "gamma_version": gate.GAMMA_VERSION},
                    "initial_stack": initial, "dictionary": dictionary,
                    "gamma_version": gate.GAMMA_VERSION, "fuel": case.fuel})
                compilation = call("compile", {"entry": "main", "checked_words": elaboration["checked_words"],
                    "erased_word_types": elaboration["erased_word_types"],
                    "gamma_version": gate.GAMMA_VERSION, "target_version": gate.TARGET_VERSION,
                    "source": {"source_path": "case.firth", "source_text": case.source,
                               "language_version": gate.LANGUAGE_VERSION}})
                if compilation.get("status") != "success":
                    return Result("compiler-rejected", stage, records=records)
                target = call("target", {"target_program": compilation["target_program"],
                    "initial_stack": initial, "image": {"image_version": gate.IMAGE_FORMAT_VERSION,
                    "gamma_version": gate.TARGET_GAMMA_VERSION},
                    "gamma_version": gate.GAMMA_VERSION, "fuel": case.fuel})
                result = compare(reference, target, case.fuel)
                result.records = records
                return result
            except AdapterError as error:
                error.record["stage"] = stage
                records.append(error.record)
                return Result(error.kind, stage, records=records)
            except (gate.GateError, ValueError, TypeError, KeyError, IndexError, RecursionError) as error:
                return Result("adapter-schema-error", stage, str(error), records)


def reductions(case: Case) -> Iterator[Case]:
    if case.unused:
        yield dataclasses.replace(case, unused=False)
    for index in range(len(case.steps)):
        yield dataclasses.replace(case, steps=case.steps[:index] + case.steps[index + 1:])
    for index in range(len(case.prefix)):
        yield dataclasses.replace(case, prefix=case.prefix[:index] + case.prefix[index + 1:])
    for index, step in enumerate(case.steps):
        for field in ("a", "b", "flag"):
            value = getattr(step, field)
            for smaller in ((False,) if field == "flag" else (0, value // 2)):
                if smaller == value:
                    continue
                steps = list(case.steps)
                steps[index] = dataclasses.replace(step, **{field: smaller})
                yield dataclasses.replace(case, steps=tuple(steps))
    for value in (0, case.value // 2):
        if value != case.value:
            yield dataclasses.replace(case, value=value)
    if case.flag:
        yield dataclasses.replace(case, flag=False)


def shrink(case: Case, result: Result, execute: Callable[[Case], Result], budget: int) -> tuple[Case, Result, dict]:
    bounded_int(budget, 0, 256, "shrink budget")
    # Do not shrink a generator rejection into a smaller invalid program, nor
    # conflate a passing execution with a reproducer.
    if result.kind in ("agreement", "elaboration-rejected") or result.stage == "elaborate":
        return case, result, {"attempts": 0, "accepted": 0, "stop": "ineligible"}
    attempts, accepted = 0, 0
    signature = result.signature
    while True:
        changed = False
        for candidate in reductions(case):
            if candidate.complexity >= case.complexity:
                continue
            if attempts >= budget:
                return case, result, {"attempts": attempts, "accepted": accepted, "stop": "budget-exhausted"}
            attempts += 1
            candidate_result = execute(candidate)
            if candidate_result.signature == signature:
                case, result = candidate, candidate_result
                accepted += 1
                changed = True
                break
        if not changed:
            return case, result, {"attempts": attempts, "accepted": accepted, "stop": "fixed-point"}


def identities() -> dict[str, Any]:
    files = {
        "driver": Path(__file__), "portable-gate": ROOT / "tools/loop/mvp_agent_gate.py",
        "lean-toolchain": ROOT / "lean-toolchain", "rust-toolchain": ROOT / "rust-toolchain.toml",
        "lake-lock": ROOT / "lake-manifest.json", "cargo-lock": ROOT / "src/runtime/vm/Cargo.lock",
        **{name: gate.LEAN_BIN / name for name in gate.LEAN_ADAPTERS}, "vm": gate.VM_BINARY,
    }
    try:
        hashes = {name: sha256(path.read_bytes()) for name, path in files.items()}
        head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True,
                              text=True, timeout=5, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise HarnessError(f"cannot establish toolchain identities: {error}") from error
    return {"sha256": hashes, "git_revision": head.stdout.strip() if head.returncode == 0 else None,
            "python": sys.version.split()[0], "generator": VERSION}


def failure_record(case: Case, result: Result, toolchain: dict) -> dict[str, Any]:
    return {"schema": SCHEMA, "generator": VERSION, "case": case.payload(),
            "source": case.source, "source_sha256": sha256(case.source.encode()),
            "entry": "main", "initial_stack": case.stack, "features": case.features,
            "toolchain": toolchain, "result": {**dataclasses.asdict(result), "traps": list(result.traps)}}


def load_failure(path: Path) -> tuple[dict, Case]:
    with path.open("rb") as stream:
        data = stream.read(MAX_ARTIFACT + 1)
    if len(data) > MAX_ARTIFACT:
        raise HarnessError("failure artefact exceeds its size bound")
    record = strict_json(data.decode("utf-8"))
    if not isinstance(record, dict) or record.get("schema") != SCHEMA or record.get("generator") != VERSION:
        raise HarnessError("unsupported failure artefact schema/generator")
    case = Case.from_payload(record.get("case"))
    if record.get("source") != case.source or record.get("source_sha256") != sha256(case.source.encode()) \
            or record.get("entry") != "main" or record.get("initial_stack") != case.stack:
        raise HarnessError("failure source/input does not match the saved recipe")
    # JSON numeric equality must not make a Boolean input look like integer 1.
    if json.dumps(record["initial_stack"]) != json.dumps(case.stack):
        raise HarnessError("failure input types do not match the saved recipe")
    if not isinstance(record.get("toolchain"), dict) or not isinstance(record["toolchain"].get("sha256"), dict):
        raise HarnessError("missing toolchain identities")
    result = record.get("result")
    if not isinstance(result, dict) or not isinstance(result.get("kind"), str) \
            or not isinstance(result.get("stage"), str) \
            or not isinstance(result.get("traps"), list) or len(result["traps"]) != 2 \
            or any(trap is not None and not isinstance(trap, str) for trap in result["traps"]):
        raise HarnessError("invalid recorded failure signature")
    return record, case


def save_failure(directory: Path, name: str, record: dict) -> Path:
    directory.mkdir(parents=True, exist_ok=True)
    destination = directory / (name + ".json")
    # Exclusive creation preserves the original when rerunning the same seed.
    with destination.open("x", encoding="utf-8") as stream:
        json.dump(record, stream, sort_keys=True, indent=2, ensure_ascii=False)
        stream.write("\n")
    (directory / (name + ".firth")).write_text(record["source"], encoding="utf-8")
    return destination


def parser() -> argparse.ArgumentParser:
    cli = argparse.ArgumentParser(description=__doc__)
    commands = cli.add_subparsers(dest="command", required=True)
    run = commands.add_parser("run", help="build and execute a finite seeded matrix")
    run.add_argument("--seed", type=int, action="append")
    run.add_argument("--cases", type=int, default=24, help="cases per seed, 1 to 512")
    run.add_argument("--size", type=int, default=6, help="maximum generated fragments, 1 to 24")
    run.add_argument("--fuel", type=int, default=4096)
    for name in ("replay", "shrink"):
        command = commands.add_parser(name, help=f"{name} a saved failure using rebuilt local adapters")
        command.add_argument("artifact", type=Path)
        command.add_argument("--allow-toolchain-drift", action="store_true")
    for command in (run, *[commands.choices[name] for name in ("replay", "shrink")]):
        command.add_argument("--artifacts", type=Path, default=ROOT / ".firth-differential")
        command.add_argument("--shrink-steps", type=int, default=32)
    return cli


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        bounded_int(args.shrink_steps, 0, 256, "shrink budget")
        saved = None
        if args.command == "run":
            bounded_int(args.cases, 1, 512, "cases")
            seeds = list(dict.fromkeys(args.seed if args.seed is not None else [0, 1, 20260909]))
            if len(seeds) > 16:
                raise HarnessError("at most 16 seeds are supported per run")
            cases = [generate(seed, index, args.size, args.fuel) for seed in seeds for index in range(args.cases)]
        else:
            saved, case = load_failure(args.artifact)
            cases = [case]
        gate.build_toolchain()
        toolchain = identities()
        drift = saved is not None and saved["toolchain"] != toolchain
        if drift and not args.allow_toolchain_drift:
            raise HarnessError("toolchain identity changed; use --allow-toolchain-drift for an explicitly non-identical replay")
        execute = Executor()
        counts: dict[str, int] = {}
        coverage: dict[str, int] = {}
        artifacts = []
        replay_matches = None
        for case in cases:
            result = execute(case)
            if saved is not None:
                previous = saved["result"]
                replay_matches = result.signature == (previous["kind"], previous["stage"], *previous["traps"])
            counts[result.kind] = counts.get(result.kind, 0) + 1
            for feature in case.features:
                coverage[feature] = coverage.get(feature, 0) + 1
            if result.kind != "agreement" or args.command != "run":
                # Each run owns an exclusive directory; do not overwrite earlier evidence.
                args.artifacts.mkdir(parents=True, exist_ok=True)
                directory = Path(tempfile.mkdtemp(prefix=f"seed-{case.seed}-case-{case.index}-", dir=args.artifacts))
                record = failure_record(case, result, toolchain)
                record["toolchain_drift"] = drift
                record["replay_signature_matches"] = replay_matches
                original = save_failure(directory, "original", record)
                artifacts.append(str(original))
                if args.command != "replay" and result.kind != "agreement" and replay_matches is not False:
                    reduced, reduced_result, report = shrink(case, result, execute, args.shrink_steps)
                    record = failure_record(reduced, reduced_result, toolchain)
                    record["shrinking"] = report
                    record["original"] = "original.json"
                    record["toolchain_drift"] = drift
                    record["replay_signature_matches"] = replay_matches
                    artifacts.append(str(save_failure(directory, "reduced", record)))
        ok = counts.get("agreement", 0) == len(cases)
        summary = {"status": "ok" if ok else "failed", "command": args.command,
                   "cases": len(cases), "outcomes": counts, "generated_features": coverage,
                   "toolchain": toolchain, "toolchain_drift": drift, "artifacts": artifacts,
                   "replay_signature_matches": replay_matches,
                   "scope": "bounded pure source campaign; not compiler proof or sustained S2 evidence"}
        args.artifacts.mkdir(parents=True, exist_ok=True)
        # A unique summary also retains identities for an entirely successful run.
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", prefix="summary-", dir=args.artifacts,
                                         encoding="utf-8", delete=False) as stream:
            json.dump(summary, stream, sort_keys=True, indent=2)
            stream.write("\n")
        print(json.dumps(summary, sort_keys=True))
        return 0 if ok else 1
    except (HarnessError, gate.GateError, OSError, ValueError, RecursionError) as error:
        print(json.dumps({"status": "error", "error": str(error)}, sort_keys=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
