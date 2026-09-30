#!/usr/bin/env python3
"""Build and check run 12's two prompts (preregistration.md, "Design").

Usage, from eval/s7 of the checkout the run is pinned to:
  python3 runs/2026-09-30-check-tool/make_prompts.py          (writes arm-a/ and arm-b/prompt-firth.md)
  python3 runs/2026-09-30-check-tool/make_prompts.py --check  (checks the written prompts)
  python3 runs/2026-09-30-check-tool/make_prompts.py --self-test

Arm A's prompt is `harness.py prompt --lang firth --tier mvp --rounds 2` of
this checkout; arm B's is the same with `--check-tool`. --check fails unless
both are what the harness builds now, and arm B's differs from arm A's in
exactly one place: arm A's tool sentence, and nothing else, replaced by the
paragraph that offers `check`, which names this checkout's harness by
absolute path.
"""
import difflib
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
S7 = HERE.parents[1]
HARNESS = S7 / "harness.py"
ARM_A_TOOLS = ("Do not use any tool except reading this prompt file and writing your answer "
               "file, and do not use the internet. ")
ARM_B_TOOLS = "Do not use any tool except reading this prompt file, writing, reading and editing"


def harness_prompt(*extra):
    return subprocess.run([sys.executable, str(HARNESS), "prompt", "--lang", "firth", "--tier", "mvp",
                           "--rounds", "2", *extra], capture_output=True, text=True, check=True).stdout


def differences(a, b, harness=HARNESS):
    """Why arm B's prompt is not arm A's with only the tool paragraph changed."""
    blocks = [op for op in difflib.SequenceMatcher(None, a.split("\n"), b.split("\n"),
                                                   autojunk=False).get_opcodes() if op[0] != "equal"]
    if len(blocks) != 1:
        return [f"the prompts differ in {len(blocks)} places, want 1"]
    _, i1, i2, j1, j2 = blocks[0]
    old, new = a.split("\n")[i1:i2], "\n".join(b.split("\n")[j1:j2])
    problems = []
    if len(old) != 1 or not old[0].startswith(ARM_A_TOOLS):
        problems.append("the lines arm B replaces are not arm A's tool sentence")
    elif not new.startswith(ARM_B_TOOLS) or not new.endswith(old[0][len(ARM_A_TOOLS):]):
        problems.append("arm B changes more than the tool sentence")
    if f"python3 {harness} check --lang firth <your answer file>" not in new:
        problems.append(f"arm B's check command does not name {harness}")
    return problems


def check(a, b, fresh_a, fresh_b):
    problems = []
    if a != fresh_a:
        problems.append("arm A's prompt is not what harness.py builds in this checkout")
    if b != fresh_b:
        problems.append("arm B's prompt is not what harness.py --check-tool builds in this checkout")
    return problems + differences(a, b)


def self_test():
    a, b = harness_prompt(), harness_prompt("--check-tool")
    assert check(a, b, a, b) == [], check(a, b, a, b)
    # Planted: a word added elsewhere in arm B, a stale arm A, another harness
    # named in the command, and arm B's tool paragraph dropped.
    assert check(a, b.replace("# Tasks", "# Tasks (check them)"), a, b)
    assert check(a + "x", b, a, b)
    other = b.replace(str(HARNESS), "/elsewhere/eval/s7/harness.py")
    assert any("does not name" in p for p in differences(a, other))
    assert differences(a, a)
    print("self-test ok")


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    fresh_a, fresh_b = harness_prompt(), harness_prompt("--check-tool")
    pa, pb = HERE / "arm-a" / "prompt-firth.md", HERE / "arm-b" / "prompt-firth.md"
    if sys.argv[1:] != ["--check"]:
        for p, text in ((pa, fresh_a), (pb, fresh_b)):
            p.parent.mkdir(exist_ok=True)
            p.write_text(text)
    problems = check(pa.read_text(), pb.read_text(), fresh_a, fresh_b)
    for p in problems:
        print("FAIL:", p)
    if problems:
        sys.exit(1)
    print(f"ok: arm A {len(pa.read_text())} chars, arm B {len(pb.read_text())} chars, "
          f"check command {HARNESS}")


if __name__ == "__main__":
    main()
