"""Which AGENTS.md and CLAUDE.md an author sub-agent was shown, from its raw
log. Claude Code strips HTML comment lines before showing a memory file, so
each shown text is compared with the named git blobs after the same
stripping. Exits 1 if any shown file matches none of them. Usage:
`python3 seen_agents.py LOG REPO BLOB...`"""
import json, re, subprocess, sys
def norm(s):
    return "\n".join(l for l in s.splitlines() if not re.fullmatch(r"\s*<!--.*-->\s*", l)).strip()
log, repo, blobs = sys.argv[1], sys.argv[2], sys.argv[3:]
want = {b: norm(subprocess.run(["git", "-C", repo, "cat-file", "blob", b], capture_output=True,
                               text=True, check=True).stdout) for b in blobs}
seen = {}
def walk(x):
    if isinstance(x, dict):
        p, c = x.get('path'), x.get('content')
        if isinstance(p, str) and isinstance(c, str) and p.endswith(('AGENTS.md', 'CLAUDE.md')):
            m = [b for b, t in want.items() if t == norm(c)]
            seen.setdefault(p, set()).add(m[0] if m else "UNMATCHED")
        for v in x.values(): walk(v)
    elif isinstance(x, list):
        for v in x: walk(v)
for l in open(log):
    if l.strip(): walk(json.loads(l))
out = {p: sorted(b) for p, b in sorted(seen.items())}
print(json.dumps(out, indent=1))
sys.exit(1 if any("UNMATCHED" in b for b in out.values()) or not out else 0)
