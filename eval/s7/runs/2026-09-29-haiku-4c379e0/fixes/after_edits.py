"""Independent errors left after every edit, in the answers that still fail the checker.

Applies the `everything` candidate from measure.py to each failing answer
whose edited version still fails the checker (outcome not `pass` and not
`checks, wrong` in measure.json), then counts the words with an error of
their own, as measure.py does. Writes after_edits.json next to this file.
Like measure.py, run it in a checkout of 4c379e0.

    python3 eval/s7/runs/2026-09-29-haiku-4c379e0/fixes/after_edits.py
"""
import collections, json, sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.argv = sys.argv[:1]
sys.path.insert(0, str(HERE))
import measure as m  # noqa: E402

rows = [r for r in json.loads((HERE / 'measure.json').read_text())['rows']
        if r['candidate'] == 'everything' and r['outcome'] not in ('pass', 'checks, wrong')]


def count(r):
    src = json.loads((m.RUN / f"haiku-firth-{r['sample']}/solutions-{r['round']}.json").read_text())[r['task']]
    for f in m.CANDIDATES['everything']:
        src = f(src, m.TASKS[r['task']])
    return f"{r['sample']}/{r['round']}/{r['task']}", m.independent_errors(src)


with ThreadPoolExecutor(8) as ex:
    words = dict(ex.map(count, rows))
multi = {k: w for k, w in words.items() if w and len(w) >= 2}
summary = {'still_failing': len(words), 'two_or_more': len(multi),
           'by_sample': dict(collections.Counter(k.split('/')[0] for k in multi)),
           'codes_in_two_or_more': dict(collections.Counter(c for w in multi.values() for _, c in w).most_common())}
(HERE / 'after_edits.json').write_text(json.dumps({'summary': summary, 'words': words}, indent=1) + '\n')
print(json.dumps(summary))
