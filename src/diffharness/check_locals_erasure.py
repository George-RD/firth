#!/usr/bin/env python3
"""Differential test of `locals` erasure against un-erased locals semantics.

The elaborator erases `locals { a b } { ... }` into stack shuffles before the
checker sees the program, so a wrong shuffle that happens to type-check runs
and returns a wrong answer. This script generates random words that use
locals (nested blocks, repeated uses, uses inside quotations and `if`
branches, after `call`, `dip` and `compose`), runs each one through the whole
toolchain, and compares the result with a direct interpreter of the source in
which a local is a name bound to a value.

A generated program is built while it is executed on concrete inputs, so every
program runs without faults in the direct interpreter. The toolchain may
refuse a program only with a documented checker limit (`TOLERATED_REFUSALS`);
that is counted, not failed. Any other refusal of a generated program is a
failure, since every generated program runs, and a program the toolchain
accepts must give the same final stack.
"""
from __future__ import annotations

import argparse
import json
import random
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / "tools" / "loop"))

import mvp_agent_gate as gate  # noqa: E402

MAX_DEPTH = 7
# The checker limits a generated program may hit: a local used after a
# quotation whose stack effect is unknown, and a hidden local the checker
# cannot reach. Every other refusal is an erasure or checker regression.
TOLERATED_REFUSALS = ("firth.elaboration.untracked-local", "firth.elaboration.hidden-local")
NAMES = ["a", "b", "c", "d", "e"]


# Source items: ("lit", n) ("prim", op) ("atom", name) ("ref", name)
# ("quot", items) ("locals", names, items)


@dataclass
class Closure:
    items: list
    env: dict


@dataclass
class Composed:
    first: object
    second: object


@dataclass
class Constant:
    value: object


class Stuck(Exception):
    """The direct interpreter cannot run the program (it is not generated)."""


def run(items: list, stack: list, env: dict) -> None:
    for item in items:
        step(item, stack, env)


def pop(stack: list):
    if not stack:
        raise Stuck("underflow")
    return stack.pop()


def invoke(value, stack: list) -> None:
    if isinstance(value, Closure):
        run(value.items, stack, value.env)
    elif isinstance(value, Composed):
        invoke(value.first, stack)
        invoke(value.second, stack)
    elif isinstance(value, Constant):
        stack.append(value.value)
    else:
        raise Stuck("not a quotation")


def integer(value) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise Stuck("not an integer")
    return value


def step(item: tuple, stack: list, env: dict) -> None:
    kind = item[0]
    if kind == "lit":
        stack.append(item[1])
    elif kind == "ref":
        stack.append(env[item[1]])
    elif kind == "quot":
        stack.append(Closure(item[1], env))
    elif kind == "locals":
        names = item[1]
        if len(stack) < len(names):
            raise Stuck("underflow")
        values = stack[len(stack) - len(names):]
        del stack[len(stack) - len(names):]
        run(item[2], stack, {**env, **dict(zip(names, values))})
    elif kind == "prim":
        right, left = integer(pop(stack)), integer(pop(stack))
        stack.append({"+": left + right, "-": left - right, "*": left * right,
                      "<": left < right, "=": left == right, "<=": left <= right,
                      ">": left > right, ">=": left >= right}[item[1]])
    else:
        name = item[1]
        if name == "dup":
            value = pop(stack)
            stack += [value, value]
        elif name == "drop":
            pop(stack)
        elif name == "swap":
            top, below = pop(stack), pop(stack)
            stack += [top, below]
        elif name == "call":
            invoke(pop(stack), stack)
        elif name == "dip":
            quotation, kept = pop(stack), pop(stack)
            invoke(quotation, stack)
            stack.append(kept)
        elif name == "compose":
            second, first = pop(stack), pop(stack)
            stack.append(Composed(first, second))
        elif name == "quote":
            stack.append(Constant(pop(stack)))
        elif name == "if":
            otherwise, then, condition = pop(stack), pop(stack), pop(stack)
            if not isinstance(condition, bool):
                raise Stuck("not a boolean")
            invoke(then if condition else otherwise, stack)
        else:
            raise Stuck(name)


def render(items: list) -> str:
    out = []
    for item in items:
        kind = item[0]
        if kind == "lit":
            out.append(str(item[1]))
        elif kind == "prim":
            out.append(f"prim {item[1]}")
        elif kind in ("atom", "ref"):
            out.append(item[1])
        elif kind == "quot":
            out.append(f"[ {render(item[1])} ]")
        else:
            out.append(f"locals {{ {' '.join(item[1])} }} {{ {render(item[2])} }}")
    return " ".join(part for part in out if part)


class Generator:
    """Builds a program while running it, choosing only steps that can run."""

    def __init__(self, rng: random.Random):
        self.rng = rng

    def sequence(self, stack: list, env: dict, budget: int, nesting: int) -> list:
        items: list = []
        for _ in range(self.rng.randint(1, budget)):
            chosen = self.choose(stack, env, nesting)
            if chosen is None:
                break
            for item in chosen:
                step(item, stack, env)
            items += chosen
        return items

    def body(self, stack: list, env: dict, nesting: int) -> list:
        """A quotation body generated on (and run against) `stack`."""
        return self.sequence(stack, env, 4, nesting + 1)

    def mutated(self, items: list) -> list:
        """Same shape and effect, different literals."""
        out = []
        for item in items:
            if item[0] == "lit":
                out.append(("lit", self.rng.randint(-9, 9)))
            elif item[0] == "quot":
                out.append(("quot", self.mutated(item[1])))
            elif item[0] == "locals":
                out.append(("locals", item[1], self.mutated(item[2])))
            else:
                out.append(item)
        return out

    def choose(self, stack: list, env: dict, nesting: int):
        ints = [isinstance(v, int) and not isinstance(v, bool) for v in stack]
        usable = len(stack)
        options = []
        if len(stack) < MAX_DEPTH:
            options += ["lit"] + (["ref"] * 4 if env else [])
        if usable >= 2 and ints[-1] and ints[-2]:
            options += ["arith", "compare"]
        if usable:
            options += ["dup", "drop"] if len(stack) < MAX_DEPTH else ["drop"]
        if usable >= 2:
            options.append("swap")
        if nesting < 3:
            options += ["call", "compose"]
            if usable:
                options += ["dip", "quote", "locals", "locals"]
            if usable and isinstance(stack[-1], bool):
                options += ["if", "if"]
            if len(stack) < MAX_DEPTH:
                options.append("stored")
        if not options:
            return None
        pick = self.rng.choice(options)
        rng = self.rng
        if pick == "lit":
            return [("lit", rng.randint(-9, 9))]
        if pick == "ref":
            return [("ref", rng.choice(sorted(env)))]
        if pick == "arith":
            return [("prim", rng.choice("+-*"))]
        if pick == "compare":
            return [("prim", rng.choice(["<", "=", "<=", ">", ">="]))]
        if pick in ("dup", "drop", "swap"):
            return [("atom", pick)]
        if pick == "call":
            trial = list(stack)
            return [("quot", self.body(trial, env, nesting)), ("atom", "call")]
        if pick == "dip":
            trial = list(stack[:-1])
            return [("quot", self.body(trial, env, nesting)), ("atom", "dip")]
        if pick == "compose":
            trial = list(stack)
            first = self.body(trial, env, nesting)
            second = self.body(trial, env, nesting)
            return [("quot", first), ("quot", second), ("atom", "compose"), ("atom", "call")]
        if pick == "quote":
            return [("atom", "quote"), ("atom", "call")]
        if pick == "if":
            trial = list(stack[:-1])
            then = self.body(trial, env, nesting)
            return [("quot", then), ("quot", self.mutated(then)), ("atom", "if")]
        if pick == "stored":
            # A quotation kept in a local and called later: its effect is not
            # known where it runs, so later uses of locals must be refused.
            trial = list(stack)
            inner = self.body(trial, env, nesting)
            name = rng.choice(NAMES)
            return [("quot", inner), ("locals", [name], [("ref", name), ("atom", "call")])]
        # A nested block binding the top values, possibly shadowing.
        count = rng.randint(1, min(3, usable))
        names = rng.sample(NAMES, count)
        trial = list(stack[:-count])
        inner_env = {**env, **dict(zip(names, stack[-count:]))}
        body = self.sequence(trial, inner_env, 5, nesting + 1)
        return [("locals", names, body)]


def type_name(value) -> str | None:
    if isinstance(value, bool):
        return "Bool"
    if isinstance(value, int):
        return "Int"
    return None


def program(rng: random.Random, index: int) -> tuple[str, list, list, list] | None:
    arity = rng.randint(1, 3)
    inputs = [rng.randint(-9, 9) for _ in range(arity)]
    names = rng.sample(NAMES, arity)
    stack = list(inputs)
    env = dict(zip(names, inputs))
    try:
        body = Generator(rng).sequence([], env, 8, 0)
        items = [("locals", names, body)]
        stack = list(inputs)
        run(items, stack, {})
    except (Stuck, RecursionError):
        return None
    types = [type_name(value) for value in stack]
    if None in types or any(isinstance(v, int) and v > 2**62 for v in stack):
        return None
    word = f"w{index}"
    source = (
        f": {word}\n  (forall ρ; ρ "
        + " ".join(f"i{n}:Int^many" for n in range(arity))
        + " -- ρ "
        + " ".join(f"o{n}:{kind}^many" for n, kind in enumerate(types))
        + f")\n  {render(items)};\n"
    )
    return source, inputs, stack, items


def refusal_code(error: gate.GateError) -> str | None:
    text = str(error)
    marker = "'code': '"
    if marker not in text:
        return None
    return text.split(marker, 1)[1].split("'", 1)[0]


def main(argv: list[str] | None = None) -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--seed", type=int, action="append", default=None)
    cli.add_argument("--cases", type=int, default=100, help="programs per seed")
    cli.add_argument("--artifacts", type=Path, default=None,
                     help="directory to keep failing programs in")
    args = cli.parse_args(argv)
    seeds = args.seed or [0]
    gate.build_toolchain()
    counts = {"agreed": 0, "refused": 0, "mismatched": 0, "errored": 0}
    refusals: dict[str, int] = {}
    for seed in seeds:
        rng = random.Random(seed)
        made = 0
        attempts = 0
        while made < args.cases and attempts < args.cases * 50:
            attempts += 1
            generated = program(rng, made)
            if generated is None:
                continue
            made += 1
            source, inputs, expected, _ = generated
            label = f"seed {seed} case {made - 1}"
            with tempfile.TemporaryDirectory(prefix="firth-locals-") as directory:
                path = Path(directory) / "case.firth"
                path.write_text(source, encoding="utf-8")
                try:
                    observation = gate.rebuild(
                        {"name": "locals", "entry": f"w{made - 1}", "source": str(path),
                         "source_path": "case.firth"},
                        Path(directory), stack=inputs,
                    )
                except gate.GateError as error:
                    code = refusal_code(error)
                    if code in TOLERATED_REFUSALS:
                        counts["refused"] += 1
                        refusals[code] = refusals.get(code, 0) + 1
                    else:
                        counts["errored"] += 1
                        print(f"ERROR {label}: {str(error)[:400]}\n{source}")
                        keep(args.artifacts, label, source, inputs, expected, str(error))
                    continue
            actual = [value["literal"]["value"] for value in observation["stack"]]
            if actual != expected:
                counts["mismatched"] += 1
                print(f"MISMATCH {label}: inputs {inputs}, locals semantics {expected}, "
                      f"toolchain {actual}\n{source}")
                keep(args.artifacts, label, source, inputs, expected, actual)
            else:
                counts["agreed"] += 1
    print(json.dumps({"seeds": seeds, **counts, "refusals": refusals}, sort_keys=True))
    if counts["agreed"] == 0 or counts["agreed"] < counts["refused"]:
        print("most generated programs were refused; the test proves little")
        return 1
    return 1 if counts["mismatched"] or counts["errored"] else 0


def keep(directory: Path | None, label: str, source: str, inputs, expected, actual) -> None:
    if directory is None:
        return
    directory.mkdir(parents=True, exist_ok=True)
    name = label.replace(" ", "-")
    (directory / f"{name}.json").write_text(json.dumps(
        {"source": source, "inputs": inputs, "expected": expected, "actual": actual},
        indent=2, default=str), encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
