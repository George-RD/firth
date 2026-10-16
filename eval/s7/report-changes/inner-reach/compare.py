"""Compare first checker reports between two firthElaborate binaries."""
import json, re, subprocess, sys, glob, os, hashlib
from concurrent.futures import ThreadPoolExecutor
repo, main_bin, branch_bin, out = sys.argv[1:5]
sources = {}
paths = {}  # source text -> repo-relative path, for files on disk
for path in glob.glob(f"{repo}/eval/s7/**/solutions-*.json", recursive=True):
    data = json.load(open(path))
    for task, value in data.items():
        src = value if isinstance(value, str) else (value.get("source") if isinstance(value, dict) else None)
        if isinstance(src, str):
            sources.setdefault(src, f"{os.path.relpath(path, repo)}:{task}")
for path in glob.glob(f"{repo}/examples/**/*.firth", recursive=True) + glob.glob(f"{repo}/stdlib/**/*.firth", recursive=True):
    src = open(path).read()
    sources.setdefault(src, os.path.relpath(path, repo))
    paths.setdefault(src, os.path.relpath(path, repo))
def imports_of(rel):
    """The repo-relative paths a file on disk imports, transitively."""
    seen, todo = [], [rel]
    while todo:
        here = todo.pop()
        for name in re.findall(r'^import "([^"]+)";', open(f"{repo}/{here}").read(), re.M):
            target = os.path.normpath(os.path.join(os.path.dirname(here), name))
            if target not in seen:
                seen.append(target)
                todo.append(target)
    return seen
def run(binary, src):
    # A binary that exits non-zero or prints no result must not count as a
    # report, or two crashes would compare equal: stop instead. A refused
    # program is a "failure" result with exit 0.
    # A file on disk keeps its repo-relative path and brings the files it
    # imports; an S7 answer is a single file.
    rel = paths.get(src, "a.firth")
    files = [{"source_path": f, "source_text": open(f"{repo}/{f}").read()}
             for f in (imports_of(rel) if rel in paths.values() else [])]
    done = subprocess.run([binary], input=json.dumps({"request_id": "c", "source_path": rel,
        "source_text": src, "files": files, "language_version": "0.1", "gamma_version": "0.8"}),
        capture_output=True, text=True)
    try:
        o = json.loads(done.stdout)
    except ValueError:
        o = None
    if done.returncode != 0 or not isinstance(o, dict) or o.get("status") not in ("success", "failure"):
        raise SystemExit(f"{binary} gave no result (exit {done.returncode}): {done.stderr[:500]}")
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
rows = []
for label, a, b in sorted(changed, key=lambda t: t[0]):
    if a.get("status") != b.get("status") or len(a.get("reports", [])) != len(b.get("reports", [])):
        rows.append({"source": label, "main": a, "branch": b})
        continue
    for x, y in zip(a["reports"], b["reports"]):
        if x != y:
            rows.append({"source": label, "code": x["code"], "at": x["line"],
                         "main": {"message": x["message"], "hint": x["hint"]},
                         "branch": {"message": y["message"], "hint": y["hint"]}}
                        if (x["code"], x["line"]) == (y["code"], y["line"]) else
                        {"source": label, "main": x, "branch": y})
with open(out, "w") as f:
    f.write(f"sources {len(results)}, reports changed {len(rows)}\n")
    for row in rows:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")
print(len(results), len(rows))
