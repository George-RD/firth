"""Count Forth-style stack comments in every kept Firth answer.

Scans every `solutions-*.json` under eval/s7/runs/ (every run, sample and
round) for `( ... -- ... )` inside a word body, which a rule accepting
Forth stack comments would change, and for word headers written Forth
style, without `forall`, which Firth already parses as signatures. Also
counts bodies that contain parentheses of any kind. Writes comments.json
next to this file.

    python3 eval/s7/runs/2026-09-29-haiku-4c379e0/fixes/count_comments.py
"""
import json, re
from pathlib import Path

HERE = Path(__file__).resolve().parent
RUNS = HERE.parents[1]
DEF = re.compile(r'(?ms)^:\s+(\S+)\s*(\((?:[^()]|\([^()]*\))*?--[^()]*\))(.*?)(;)[ \t]*$')
COMMENT = re.compile(r'\([^()]*--[^()]*\)')

out = {'files': 0, 'answers': 0, 'body_stack_comments': [], 'forth_style_headers': {}, 'bodies_with_parens': {}}
for f in sorted(RUNS.rglob('solutions-*.json')):
    rel = str(f.relative_to(RUNS))
    try:
        sols = json.loads(f.read_text())
    except ValueError:
        continue
    if not isinstance(sols, dict):
        continue
    out['files'] += 1
    for task, src in sols.items():
        if not isinstance(src, str) or ':' not in src:
            continue
        out['answers'] += 1
        for m in DEF.finditer(src):
            if 'forall' not in m[2]:
                out['forth_style_headers'][rel] = out['forth_style_headers'].get(rel, 0) + 1
            if '(' in m[3]:
                out['bodies_with_parens'][rel] = out['bodies_with_parens'].get(rel, 0) + 1
            for c in COMMENT.finditer(m[3]):
                out['body_stack_comments'].append({'file': rel, 'task': task, 'word': m[1], 'text': c[0]})
(HERE / 'comments.json').write_text(json.dumps(out, indent=1) + '\n')
print(out['files'], out['answers'], len(out['body_stack_comments']),
      sum(out['forth_style_headers'].values()), sum(out['bodies_with_parens'].values()))
