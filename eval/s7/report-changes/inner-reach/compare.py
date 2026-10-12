"""Compare first checker reports between two firthElaborate binaries."""
import json, subprocess, sys, glob, os, hashlib
from concurrent.futures import ThreadPoolExecutor
repo, main_bin, branch_bin, out = sys.argv[1:5]
sources = {}
for path in glob.glob(f"{repo}/eval/s7/**/solutions-*.json", recursive=True):
    data = json.load(open(path))
    for task, value in data.items():
        src = value if isinstance(value, str) else (value.get("source") if isinstance(value, dict) else None)
        if isinstance(src, str):
            sources.setdefault(src, f"{os.path.relpath(path, repo)}:{task}")
for path in glob.glob(f"{repo}/examples/**/*.firth", recursive=True) + glob.glob(f"{repo}/stdlib/**/*.firth", recursive=True):
    src = open(path).read()
    sources.setdefault(src, os.path.relpath(path, repo))
def run(binary, src):
    o = subprocess.run([binary], input=json.dumps({"request_id": "c", "source_path": "a.firth",
        "source_text": src, "language_version": "0.1", "gamma_version": "0.8"}),
        capture_output=True, text=True).stdout
    try:
        o = json.loads(o)
    except ValueError:
        return {"raw": o[:500]}
    if o.get("status") == "success":
        return {"ok": True}
    reports = []
    for d in o.get("diagnostics", []):
        body = d.get("body", d)
        p = body.get("message_params", {})
        reports.append({"code": body.get("code"), "line": body.get("location", {}).get("range", {}).get("start"),
                        "message": p.get("message"), "hint": p.get("hint")})
    return {"status": o.get("status"), "reports": reports}
def both(item):
    src, label = item
    return label, run(main_bin, src), run(branch_bin, src)
with ThreadPoolExecutor(16) as pool:
    results = list(pool.map(both, sources.items()))
changed = [(l, a, b) for l, a, b in results if a != b]
with open(out, "w") as f:
    f.write(f"sources {len(results)}, reports changed {len(changed)}\n")
    for l, a, b in sorted(changed, key=lambda t: t[0]):
        f.write(json.dumps({"source": l, "main": a, "branch": b}) + "\n")
print(len(results), len(changed))
