"""The Task record shared by every S7 task set."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Callable


@dataclass(frozen=True)
class Task:
    id: str
    description: str
    inputs: tuple[tuple[str, str], ...]   # (name, type), bottom to top
    outputs: tuple[tuple[str, str], ...]  # (name, type), bottom to top
    ref: Callable[..., tuple]
    example: tuple
    hidden: tuple[tuple, ...]
    needs: frozenset[str]

    def expected(self, args: tuple) -> list:
        return list(self.ref(*args))


def _t(id, description, inputs, outputs, ref, example, hidden, needs=("add",)):
    return Task(id, description, tuple(inputs), tuple(outputs), ref, tuple(example),
                tuple(tuple(h) for h in hidden), frozenset(needs))
