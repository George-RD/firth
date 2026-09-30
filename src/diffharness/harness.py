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

VERSION = "firth-portable-diff-v3"
SCHEMA = "firth-differential-failure-v1"
MIN_INT = -(2**63)
MAX_INT = 2**63 - 1
MAX_OUTPUT = 4 * 1024 * 1024
MAX_ARTIFACT = 64 * 1024 * 1024
OPS = ("add", "double", "call", "qualified", "local", "quote-call",
       "quoted-value", "compose", "dip", "if", "nested", "swap",
       "sub", "rsub", "mul", "div", "rdiv", "mod", "rmod", "less", "equal", "and",
       "at-most", "greater", "at-least")
# Fragments whose branch depends on comparing the value with the literal `a`.
COMPARISONS = ("less", "equal", "and", "at-most", "greater", "at-least")
# Operands are mostly small signed values; the rest sit at the portable edges,
# where overflow, `MIN div -1` and zero divisors live.
EDGES = (MIN_INT, MIN_INT + 1, -(2**32), -(2**31), -1, 0, 1, 2, 2**31, 2**32,
         MAX_INT - 1, MAX_INT)
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
        bounded_int(self.a, MIN_INT, MAX_INT, "step.a")
        bounded_int(self.b, MIN_INT, MAX_INT, "step.b")

    def render(self, index: int) -> tuple[str, str]:
        a, b = self.a, self.b
        if self.op == "call":
            return f"bump{index}", f": bump{index} {SIGNATURE} {a} prim +;"
        if self.op == "qualified":
            return f"v{index}.bump", f"vocab v{index} {{ : bump {SIGNATURE} {a} prim +; }}"
        flag = str(self.flag).lower()
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
            "sub": f"{a} prim -",
            "rsub": f"{a} swap prim -",
            "mul": f"{a} prim *",
            "div": f"{a} prim div",
            "rdiv": f"{a} swap prim div",
            "mod": f"{a} prim mod",
            "rmod": f"{a} swap prim mod",
            "less": f"dup {a} prim < [ {b} prim + ] [ {b} prim * ] if",
            "equal": f"dup {a} prim = {flag} prim or prim not [ {b} prim - ] [ {b} prim div ] if",
            "and": f"dup {a} swap prim < {flag} prim and [ {b} prim mod ] [ ] if",
            "at-most": f"dup {a} prim <= [ {b} prim + ] [ {b} prim - ] if",
            "greater": f"dup {a} swap prim > [ {b} prim + ] [ {b} prim * ] if",
            "at-least": f"dup {a} prim >= [ {b} prim * ] [ {b} prim + ] if",
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
        bounded_int(self.value, MIN_INT, MAX_INT, "input")
        bounded_int(self.fuel, 0, gate.MAX_FUEL, "fuel")
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
                abs(self.value) + int(self.flag) + sum(abs(int(x)) for x in self.prefix)
                + sum(abs(s.a) + abs(s.b) + int(s.flag) for s in self.steps))

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

    def operand() -> int:
        return rng.choice(EDGES) if rng.randrange(5) == 0 else rng.randrange(-50, 51)

    case = Case(seed, index, tuple(Step(op, operand(), operand(),
                                      bool(rng.getrandbits(1))) for op in ops),
                operand(), bool(index % 2),
                tuple(rng.choice((False, True, rng.randrange(101))) for _ in range(rng.randrange(3))),
                fuel=fuel)
    case = dataclasses.replace(case, steps=at_equal_values(case.steps, case.value, rng))
    case.validate()
    return case


def at_equal_values(steps: tuple[Step, ...], value: int, rng: random.Random) -> tuple[Step, ...]:
    """Set one comparison literal in four to the value it will be compared with.

    Independent operands almost never meet, and equal values are where `<`
    and `<=` (or `>` and `>=`) differ. The value reaching each step is the
    oracle's, on the reference's unbounded integers; once a step faults there,
    later steps are left as generated.
    """
    result, n = [], value
    for step in steps:
        if (n is not None and step.op in COMPARISONS and rng.randrange(4) == 0
                and MIN_INT <= n <= MAX_INT):
            step = dataclasses.replace(step, a=n)
        result.append(step)
        if n is not None:
            try:
                n = apply_step(step, n, False)
            except Fault:
                n = None
    return tuple(result)


class Fault(Exception):
    """The expected primitive fault, with the operands left on the stack."""

    def __init__(self, operands: tuple[int, int]):
        super().__init__("primitive-fault")
        self.operands = operands


def primitive(name: str, left: int, right: int, portable: bool) -> int:
    """The documented meaning of an integer primitive, written independently.

    Division is Euclidean: the remainder is never negative. A zero divisor
    faults on both hosts. The reference's integers are unbounded; the portable
    VM faults when `+`, `-`, `*` or `div` leaves the signed 64-bit range.
    """
    if name in ("div", "mod"):
        if right == 0:
            raise Fault((left, right))
        remainder = left % abs(right)
        value = remainder if name == "mod" else (left - remainder) // right
    else:
        value = {"+": left + right, "-": left - right, "*": left * right}[name]
    if portable and not MIN_INT <= value <= MAX_INT:
        raise Fault((left, right))
    return value


def apply_step(step: Step, n: int, portable: bool) -> int:
    """What one generated fragment does to the value on top of the stack."""
    def p(name: str, left: int, right: int) -> int:
        return primitive(name, left, right, portable)
    a, b, op = step.a, step.b, step.op
    if op in ("add", "call", "qualified", "local", "quote-call", "quoted-value", "nested"):
        return p("+", n, a)
    if op == "double":
        return p("+", n, n)
    if op == "compose":
        return p("+", p("+", n, a), b)
    if op == "dip":
        return p("+", p("+", n, n), a)
    if op == "if":
        return p("+", n, a if step.flag else b)
    if op == "swap":
        return p("+", a, n)
    if op in ("sub", "mul", "div", "mod"):
        return p({"sub": "-", "mul": "*"}.get(op, op), n, a)
    if op in ("rsub", "rdiv", "rmod"):
        return p({"rsub": "-", "rdiv": "div", "rmod": "mod"}[op], a, n)
    if op == "less":
        return p("+", n, b) if n < a else p("*", n, b)
    if op == "equal":
        return p("-", n, b) if not (n == a or step.flag) else p("div", n, b)
    if op == "and":
        return p("mod", n, b) if a < n and step.flag else n
    if op == "at-most":
        return p("+", n, b) if n <= a else p("-", n, b)
    if op == "greater":
        return p("+", n, b) if a > n else p("*", n, b)
    if op == "at-least":
        return p("*", n, b) if n >= a else p("+", n, b)
    raise HarnessError(f"no expected meaning for {op}")


def expected(case: Case, portable: bool) -> tuple[str, list[int | bool]]:
    """The final status and stack the case must produce on one host.

    `main` first consumes the external flag with an `if` whose branches leave
    the stack alone, then each fragment rewrites the value above the prefix.
    A fault leaves the faulting primitive's two operands above the prefix.
    """
    n = case.value
    try:
        for step in case.steps:
            n = apply_step(step, n, portable)
    except Fault as fault:
        return "trap", [*case.prefix, *fault.operands]
    return "success", [*case.prefix, n]


def encode(values: list[int | bool]) -> list[dict[str, Any]]:
    return [{"kind": "literal", "literal": {"type": "bool" if type(v) is bool else "int", "value": v}}
            for v in values]


@dataclasses.dataclass
class Result:
    kind: str
    stage: str = "compare"
    detail: str = ""
    records: list[dict[str, Any]] = dataclasses.field(default_factory=list)
    traps: tuple[str | None, str | None] = (None, None)
    # The per-event trace label of an agreement: `gate.TRACE_AGREED` when the
    # projected traces matched stack for stack, `gate.TRACE_PREFIX_AGREED` when
    # they matched up to the trace limit, `gate.TRACE_UNSUPPORTED` when
    # intermediate stacks held quotations and were not compared.
    trace_comparison: str | None = None

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
        # The reference's unbounded integers are wider than the portable Rust
        # profile. An overflow is explicit non-success, never an agreement.
        # Whether the VM should have faulted is the oracle's call (`judge`);
        # here the VM's run must be the reference's up to the fault.
        if traps == (None, "primitive-fault"):
            return overflow_prefix(reference, target, fuel)
        if traps == ("primitive-fault", "primitive-fault"):
            return both_faulted(reference, target, fuel)
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
            if not isinstance(observation["trace"], list) or len(observation["trace"]) > min(fuel, gate.MAX_TRACE_EVENTS):
                raise gate.GateError(f"{side}: invalid trace")
        if target["cost"]["kernel"] > target["cost"]["total"]:
            raise gate.GateError("target: kernel cost exceeds total")
    except gate.GateError as error:
        return Result("invalid-observation", detail=str(error))
    if reference["stack"] != target["stack"]:
        return Result("stack-mismatch")
    if reference["cost"]["total"] != target["cost"]["kernel"]:
        return Result("kernel-cost-mismatch")
    # The gate's comparison also aligns the two traces event by event; a
    # projected event whose charge or stack differs is its own failure class.
    try:
        trace_comparison = gate.compare(reference, target, "case", fuel)
    except gate.TraceMismatch as error:
        return Result("trace-mismatch", detail=str(error))
    except gate.GateError as error:
        return Result("invalid-observation", detail=str(error))
    return Result("agreement", trace_comparison=trace_comparison)


def both_faulted(reference: dict[str, Any], target: dict[str, Any], fuel: int) -> Result:
    """Both hosts faulted: compare them up to the fault as for a success.

    The stack at the fault alone cannot tell a fault at the right step from
    one at an earlier step that happens to leave the same operands, so the
    kernel cost and the traces are compared too, after the gate removes the
    VM's charge for the faulting instruction (`gate.without_faulting_step`).
    """
    traps = ("primitive-fault", "primitive-fault")
    if reference["stack"] != target["stack"]:
        return Result("stack-mismatch", traps=traps)
    try:
        lined_up = gate.without_faulting_step(target, "case")
        cost = reference["cost"]
        if not isinstance(cost, dict) or type(cost.get("total")) is not int:
            raise gate.GateError("reference: invalid cost")
    except gate.GateError as error:
        return Result("invalid-observation", detail=str(error), traps=traps)
    if cost["total"] != lined_up["cost"]["kernel"]:
        return Result("kernel-cost-mismatch", traps=traps)
    try:
        trace_comparison = gate.compare(reference, target, "case", fuel, expected_trap="primitive-fault")
    except gate.TraceMismatch as error:
        return Result("trace-mismatch", detail=str(error), traps=traps)
    except gate.GateError as error:
        return Result("invalid-observation", detail=str(error), traps=traps)
    return Result("runtime-trap", traps=traps, trace_comparison=trace_comparison)


def overflows(event: dict[str, Any]) -> bool:
    """Whether the reference's next step is a portable integer overflow.

    The step must apply `+`, `-`, `*` or `div` to the two integers on top of
    the stack, and its documented result must leave the signed 64-bit range.
    A VM that faults anywhere else, even with the same operands on its stack,
    has not overflowed.
    """
    program, stack = event.get("program"), event["stack"]
    if not isinstance(program, list) or not program or len(stack) < 2:
        return False
    head = program[0]
    if not isinstance(head, dict) or head.get("kind") != "prim" or head.get("name") not in ("+", "-", "*", "div"):
        return False
    operands = []
    for value in stack[-2:]:
        literal = value.get("literal") if isinstance(value, dict) and value.get("kind") == "literal" else None
        if not isinstance(literal, dict) or literal.get("type") != "int" or type(literal.get("value")) is not int:
            return False
        operands.append(literal["value"])
    try:
        primitive(head["name"], operands[0], operands[1], portable=True)
    except Fault:
        return operands[1] != 0 or head["name"] != "div"
    return False


def overflow_prefix(reference: dict[str, Any], target: dict[str, Any], fuel: int) -> Result:
    """The VM overflowed where the unbounded reference ran on.

    Up to the VM's fault the two runs are the same computation, so the VM's
    kernel-charged trace, less its faulting instruction, must be a prefix of
    the reference's: the same charge at every step, the same stack wherever
    neither holds a quotation, and the VM's stack at the fault equal to the
    reference's stack before the same step, and that step must overflow
    (`overflows`). Its kernel cost must be the sum of the reference's charges
    over that prefix.
    """
    traps = (None, "primitive-fault")
    try:
        lined_up = gate.without_faulting_step(target, "case")
        gate.validate_trace(reference["trace"], gate.REFERENCE_EVENT_FIELDS, ("cost",), "case: reference")
        gate.validate_portable_stack(target["stack"], "target")
        gate.validate_pure_world(reference["world_observation"], target["world_observation"], "case")
        cost = reference["cost"]
        if not isinstance(cost, dict) or any(type(cost.get(k)) is not int or cost[k] < 0
                                             for k in ("total", "steps")):
            raise gate.GateError("reference: invalid cost")
    except gate.GateError as error:
        return Result("invalid-observation", detail=str(error), traps=traps)
    projected_reference = [event for event in reference["trace"] if event["cost"] > 0]
    projected_target = [event for event in lined_up["trace"] if event["kernel_cost"] > 0]
    if len(reference["trace"]) >= gate.MAX_TRACE_EVENTS \
            and len(projected_target) >= len(projected_reference):
        return Result("invalid-observation", traps=traps,
                      detail="reference trace cut before the VM's fault")
    if len(projected_target) >= len(projected_reference):
        return Result("trace-mismatch", traps=traps,
                      detail=f"VM faulted after {len(projected_target)} kernel steps; "
                             f"the reference ran only {len(projected_reference)}")
    for index, (left, right) in enumerate(zip(projected_reference, projected_target)):
        if left["cost"] != right["kernel_cost"]:
            return Result("trace-mismatch", traps=traps,
                          detail=f"trace event {index} charges {left['cost']} against {right['kernel_cost']}")
        if not gate.holds_quotation(left["stack"]) and not gate.holds_quotation(right["stack"]) \
                and left["stack"] != right["stack"]:
            return Result("trace-mismatch", traps=traps, detail=f"trace event {index} stack differs")
    at_fault = projected_reference[len(projected_target)]
    if not gate.holds_quotation(at_fault["stack"]) and at_fault["stack"] != target["stack"]:
        return Result("stack-mismatch", traps=traps,
                      detail="the VM's stack at the fault is not the reference's before that step")
    if not overflows(at_fault):
        return Result("trace-mismatch", traps=traps,
                      detail="the VM faulted on a step that does not leave the signed 64-bit range")
    if sum(event["cost"] for event in projected_reference[:len(projected_target)]) \
            != lined_up["cost"]["kernel"]:
        return Result("kernel-cost-mismatch", traps=traps)
    return Result("portable-integer-overflow", traps=traps)


# Outcomes that pass the campaign. The two expected classes are the documented
# difference between the unbounded reference and the portable VM, or a fault
# both must raise, and each counts only when both hosts match the oracle.
PASSING = ("agreement", "expected-trap", "expected-portable-overflow")
# Classes the oracle can refine. Fuel, cost, trace and malformed observations
# are outside its model and keep their own failure class.
ORACLE_CLASSES = ("agreement", "runtime-trap", "trap-mismatch", "portable-integer-overflow", "stack-mismatch")


def judge(case: Case, reference: dict[str, Any], target: dict[str, Any], result: Result) -> Result:
    """Check each host against the expected meaning, not only against the other."""
    for side, observation, portable in (("reference", reference, False), ("target", target, True)):
        status, values = expected(case, portable)
        want = {"stack": encode(values), "status": status,
                "trap": None if status == "success" else "primitive-fault"}
        got = {key: observation.get(key) for key in want}
        # Serialised comparison, so a Boolean never equals the integer 1.
        if json.dumps(got, sort_keys=True) != json.dumps(want, sort_keys=True):
            return Result("oracle-mismatch", "oracle",
                          f"{side}: expected {json.dumps(want, sort_keys=True)}, observed {json.dumps(got, sort_keys=True)}",
                          traps=result.traps)
    if result.kind == "agreement":
        return result
    # Only a trap already compared up to the fault is promoted; a stack, cost
    # or trace difference keeps its own failure class.
    if result.kind == "runtime-trap" and result.traps == ("primitive-fault", "primitive-fault"):
        return Result("expected-trap", traps=result.traps, trace_comparison=result.trace_comparison)
    if result.kind == "portable-integer-overflow":
        return Result("expected-portable-overflow", traps=result.traps)
    return result


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
                if result.kind in ORACLE_CLASSES:
                    result = judge(case, reference, target, result)
                result.records = records
                return result
            except AdapterError as error:
                error.record["stage"] = stage
                records.append(error.record)
                return Result(error.kind, stage, records=records)
            except (gate.GateError, ValueError, TypeError, KeyError, IndexError, RecursionError) as error:
                return Result("adapter-schema-error", stage, str(error), records)


def half(value: int) -> int:
    """Halve towards zero, so a negative literal also shrinks."""
    return value // 2 if value >= 0 else -(-value // 2)


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
            for smaller in ((False,) if field == "flag" else (0, half(value))):
                if smaller == value:
                    continue
                steps = list(case.steps)
                steps[index] = dataclasses.replace(step, **{field: smaller})
                yield dataclasses.replace(case, steps=tuple(steps))
    for value in (0, half(case.value)):
        if value != case.value:
            yield dataclasses.replace(case, value=value)
    if case.flag:
        yield dataclasses.replace(case, flag=False)


def shrink(case: Case, result: Result, execute: Callable[[Case], Result], budget: int) -> tuple[Case, Result, dict]:
    bounded_int(budget, 0, 256, "shrink budget")
    # Do not shrink a generator rejection into a smaller invalid program, nor
    # conflate a passing execution with a reproducer.
    if result.kind in (*PASSING, "elaboration-rejected") or result.stage == "elaborate":
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
        trace_comparisons: dict[str, int] = {}
        artifacts = []
        replay_matches = None
        for case in cases:
            result = execute(case)
            if saved is not None:
                previous = saved["result"]
                replay_matches = result.signature == (previous["kind"], previous["stage"], *previous["traps"])
            counts[result.kind] = counts.get(result.kind, 0) + 1
            if result.trace_comparison is not None:
                trace_comparisons[result.trace_comparison] = trace_comparisons.get(result.trace_comparison, 0) + 1
            for feature in case.features:
                coverage[feature] = coverage.get(feature, 0) + 1
            if result.kind not in PASSING or args.command != "run":
                # Each run owns an exclusive directory; do not overwrite earlier evidence.
                args.artifacts.mkdir(parents=True, exist_ok=True)
                directory = Path(tempfile.mkdtemp(prefix=f"seed-{case.seed}-case-{case.index}-", dir=args.artifacts))
                record = failure_record(case, result, toolchain)
                record["toolchain_drift"] = drift
                record["replay_signature_matches"] = replay_matches
                original = save_failure(directory, "original", record)
                artifacts.append(str(original))
                if args.command != "replay" and result.kind not in PASSING and replay_matches is not False:
                    reduced, reduced_result, report = shrink(case, result, execute, args.shrink_steps)
                    record = failure_record(reduced, reduced_result, toolchain)
                    record["shrinking"] = report
                    record["original"] = "original.json"
                    record["toolchain_drift"] = drift
                    record["replay_signature_matches"] = replay_matches
                    artifacts.append(str(save_failure(directory, "reduced", record)))
        ok = sum(counts.get(kind, 0) for kind in PASSING) == len(cases)
        summary = {"status": "ok" if ok else "failed", "command": args.command,
                   "cases": len(cases), "outcomes": counts, "generated_features": coverage,
                   "trace_comparisons": trace_comparisons,
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
