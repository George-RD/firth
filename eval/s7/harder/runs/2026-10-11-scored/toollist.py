#!/usr/bin/env python3
"""Excerpt of the mid-run change to the session's tool list (Codex finding on
#245). context-seen.json records each known item only by kind and length; this
reads each author's raw session log and prints, for every author in
agent-ids.txt, the length of its deferred_tools_delta, skill_listing and
prompt_snapshot attachments (every one, in order) and a digest of each, then the deferred tools,
tool schemas and skills that differ between the first and last version seen.
The raw logs are this session's sub-agent transcripts, which are not
committed; toollist.txt is this script's output.
  toollist.py LOG_DIR > toollist.txt"""
import hashlib, json, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
KINDS = ("deferred_tools_delta", "skill_listing", "prompt_snapshot")


def items(log: Path) -> dict:
    out = {}
    for line in log.read_text().splitlines():
        o = json.loads(line)
        a = o.get("attachment") or {}
        if o.get("type") == "attachment" and a.get("type") in KINDS:
            out.setdefault(a["type"], []).append(a)
    return out


def names(a: dict) -> set:
    s = json.dumps(a)
    return set(re.findall(r'"name": "([^"]+)"', s)) | set(re.findall(r'"([A-Za-z_]+(?:__[A-Za-z0-9_\-]+)?)"', s)) \
        if a.get("type") != "skill_listing" else set(re.findall(r"^- (\S+?)(?=: | \()", a.get("content", ""), re.M))


def main():
    logs = Path(sys.argv[1])
    ids = [l.split()[:2] for l in (HERE / "agent-ids.txt").read_text().splitlines() if l.strip() and not l.startswith("#")]
    voids = {l.split()[0] for l in (HERE / "voids.txt").read_text().splitlines() if l.strip() and not l.startswith("#")}
    rows, versions = [], {}
    for name, agent in ids:
        its = items(logs / f"agent-{agent}.jsonl")
        t = json.loads((HERE / name / "transcript.json").read_text())["started"]
        sig = []
        for k in KINDS:
            for n, item in enumerate(its.get(k, []), 1):
                s = json.dumps(item, sort_keys=True)
                d = hashlib.sha256(s.encode()).hexdigest()[:12]
                sig.append(f"{k} {n} {len(s)} {d}")
                versions.setdefault((k, n), {}).setdefault(d, item)
        rows.append((t, name, "void" if name in voids else "kept", sig))
    for t, name, v, sig in sorted(rows):
        print(f"{t} {name} ({v}): " + "; ".join(sig))
    print()
    for (k, n) in sorted(versions):
        vs = list(versions[(k, n)].values())
        print(f"{k} {n}: {len(vs)} distinct versions")
        if len(vs) == 2:
            a, b = names(vs[0]), names(vs[1])
            print(f"  only in the first: {sorted(a - b)}")
            print(f"  only in the second: {sorted(b - a)}")


if __name__ == "__main__":
    main()
