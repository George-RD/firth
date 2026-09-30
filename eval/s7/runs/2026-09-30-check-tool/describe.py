#!/usr/bin/env python3
"""Run 12 as it stopped: a description, not the pre-registered tests.

Usage, from eval/s7: python3 runs/2026-09-30-check-tool/describe.py

Run 12 stopped before either arm had 40 counted samples (departures.md), so
`analyse.py` refuses to run and there is no primary result. This prints what
was scored, sample by sample, and secondary 4's sums both with and without
the toolchain voids, as the write-up reports them. It computes no p-value:
the samples are too few and the arms were not started evenly (departures.md).
"""
import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("run12_analyse", HERE / "analyse.py")
run12 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(run12)


def scores(d):
    """Tasks passed by each scored answer, None where an answer was not scored."""
    return [run12.passed(d / f"results-{r}.json") if (d / f"results-{r}.json").is_file() else None
            for r in (1, 2, 3)]


def latest_sums(arm_dir, keep_toolchain):
    """Secondary 4's rule: samples by start order, rule voids scored on their
    latest answer; toolchain voids kept only when asked."""
    ds = [d for d in run12.samples(arm_dir)
          if keep_toolchain or run12.void_kind(d) != "toolchain"]
    return [(d.name, run12.last_passed(d)) for d in ds]


def main():
    for arm, path in run12.ARMS.items():
        print(f"arm {arm}")
        for d in run12.samples(path):
            kind = run12.void_kind(d) or "counted"
            shown = ", ".join("-" if x is None else str(x) for x in scores(d))
            print(f"  {d.name:15} {kind:9} passed by answer: {shown}")
    for keep in (False, True):
        label = "with" if keep else "without"
        print(f"\nSecondary 4 {label} toolchain voids (latest scored answer):")
        for arm, path in run12.ARMS.items():
            rows = latest_sums(path, keep)
            print(f"  arm {arm}: {len(rows)} samples, sum {sum(s for _, s in rows)}: "
                  + " ".join(str(s) for _, s in rows))


if __name__ == "__main__":
    main()
