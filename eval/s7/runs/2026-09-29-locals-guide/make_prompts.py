#!/usr/bin/env python3
"""Build and check run 11's two prompts (preregistration.md, "Design").

Usage, from eval/s7 of the checkout the run is pinned to:
  python3 runs/2026-09-29-locals-guide/make_prompts.py          (writes arm-a/ and arm-b/prompt-firth.md)
  python3 runs/2026-09-29-locals-guide/make_prompts.py --check  (checks the written prompts)
  python3 runs/2026-09-29-locals-guide/make_prompts.py --self-test

Arm A's prompt is `harness.py prompt --lang firth --tier mvp --rounds 2` of
this checkout, unchanged. Arm B's prompt is arm A's with `arm-b-paragraph.md`
inserted as a new paragraph after the one in `docs/getting-started.md` that
ends at ANCHOR, the paragraph that introduces `locals` and its input order.
--check fails unless arm A's prompt is what the harness builds now and arm
B's differs from it by exactly that insertion.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
S7 = HERE.parents[1]
PARAGRAPH = HERE / "arm-b-paragraph.md"
ANCHOR = "`firth.name.locals-order`: it would give `b` the value the effect calls `a`.\n"
DOC = '<document path="docs/getting-started.md">'


def harness_prompt():
    return subprocess.run([sys.executable, str(S7 / "harness.py"), "prompt", "--lang", "firth",
                           "--tier", "mvp", "--rounds", "2"], capture_output=True, text=True,
                          check=True).stdout


def insert(a, paragraph):
    """Arm B's prompt: `paragraph` after ANCHOR, which must occur exactly once,
    inside the getting-started document and at the end of a paragraph."""
    at = a.find(ANCHOR)
    if at < 0 or a.count(ANCHOR) != 1:
        raise ValueError(f"anchor found {a.count(ANCHOR)} times, want 1")
    start = a.find(DOC)
    if not 0 <= start < at or a.find("</document>", start) < at:
        raise ValueError("anchor is not inside docs/getting-started.md")
    end = at + len(ANCHOR)
    if a[end:end + 1] != "\n":
        raise ValueError("anchor does not end a paragraph")
    return a[:end] + "\n" + paragraph.rstrip("\n") + "\n" + a[end:]


def check(a, b, fresh, paragraph):
    problems = []
    if a != fresh:
        problems.append("arm A's prompt is not what harness.py builds in this checkout")
    if b != insert(a, paragraph):
        problems.append("arm B's prompt is not arm A's plus the paragraph at the anchor")
    return problems


def self_test():
    paragraph = PARAGRAPH.read_text()
    a = f"intro\n{DOC}\ntext\n{ANCHOR}\nnext paragraph\n</document>\nrest\n"
    b = insert(a, paragraph)
    assert check(a, b, a, paragraph) == []
    assert b.replace(paragraph.rstrip("\n") + "\n\n", "", 1) == a
    # Planted: one extra word in arm B, and a stale arm A.
    assert check(a, b.replace("Prefer", "Always prefer"), a, paragraph)
    assert check(a, b, a + "x", paragraph)
    # Planted: the anchor outside getting-started, twice, or mid-paragraph.
    for bad in (f"{ANCHOR}\n{DOC}\n</document>\n", a + ANCHOR,
                f"{DOC}\n{ANCHOR}more\n</document>\n"):
        try:
            insert(bad, paragraph)
        except ValueError:
            continue
        raise AssertionError(f"accepted a bad anchor: {bad!r}")
    print("self-test ok")


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    paragraph = PARAGRAPH.read_text()
    fresh = harness_prompt()
    pa, pb = HERE / "arm-a" / "prompt-firth.md", HERE / "arm-b" / "prompt-firth.md"
    if sys.argv[1:] != ["--check"]:
        for p in (pa, pb):
            p.parent.mkdir(exist_ok=True)
        pa.write_text(fresh)
        pb.write_text(insert(fresh, paragraph))
    problems = check(pa.read_text(), pb.read_text(), fresh, paragraph)
    for p in problems:
        print("FAIL:", p)
    if problems:
        sys.exit(1)
    print(f"ok: arm A {len(pa.read_text())} chars, arm B {len(pb.read_text())} chars")


if __name__ == "__main__":
    main()
