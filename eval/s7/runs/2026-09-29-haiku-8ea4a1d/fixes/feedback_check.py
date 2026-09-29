"""Run 8's counted answers through the checker and harness feedback of the
current build: how many errors does each failing answer's feedback show?
Run from eval/s7: `python3 runs/2026-09-29-haiku-8ea4a1d/fixes/feedback_check.py OUT.json`."""
import collections, json, re, sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
sys.path.insert(0, '.')
import harness
from tasks import BY_ID
RUN = Path('runs/2026-09-29-haiku-4c379e0')
jobs = []
for s in (2, 4, 5, 6):
    for n in (1, 2, 3):
        f = RUN / f'haiku-firth-{s}/solutions-{n}.json'
        if not f.exists():
            continue
        for tid, src in json.loads(f.read_text()).items():
            jobs.append((s, n, tid, src))
first = jobs[0]
harness.warm_toolchain(first[3])
def one(j):
    s, n, tid, src = j
    t = BY_ID[tid]
    out = harness.run_firth(src, t.example, harness.fuel_for(t), harness.types(t))
    return j, out
with ThreadPoolExecutor(8) as ex:
    outs = list(ex.map(one, jobs))
hist = collections.Counter(); rows = []; words_ok = at_ok = 0; checker_failed = 0
for (s, n, tid, src), out in outs:
    if out['ok']:
        continue
    text = harness.readable(out['error'])
    m = re.match(r'The checker found (\d+) errors', text)
    k = int(m[1]) if m else (1 if text.startswith('code: ') or '\ncode: ' in text[:40] else 0)
    blocks = text.split('\n\nerror ')[1:] if m else [text]
    if k:
        checker_failed += 1
        words_ok += all('\nword: ' in b or b.startswith('word: ') for b in blocks)
        at_ok += all('\nat: line ' in b for b in blocks)
    hist[k] += 1
    rows.append({'sample': s, 'round': n, 'task': tid, 'errors': k, 'feedback': text})
print('failing answers', len(rows), 'errors shown per answer', dict(sorted(hist.items())))
print('checker refusals', checker_failed, 'every block has word:', words_ok, 'every block has at:', at_ok)
Path(sys.argv[1]).write_text(json.dumps(rows, indent=1))
