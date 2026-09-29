"""Which fix would help most: counterfactual edits of run 8's stored answers.

For each failing first and round-1 answer (solutions-1, solutions-2) of the
counted samples, apply mechanical edits that model a candidate fix, then check
and score the edited answer. Also counts, per answer, how many words carry an
error of their own when each word is checked with every other word's body
replaced by a self-call. The edits are hand-written models of what an author
would do if a fix worked; the results are counterfactual and not scores.

    python3 eval/s7/runs/2026-09-29-haiku-4c379e0/fixes/measure.py [samples...]

measure.json was produced in a checkout of 4c379e0, the commit run 8 was
scored at. A later checker can report different first errors, so rerun it
there to reproduce the file.
"""
import json, re, subprocess, sys, tempfile, collections
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(ROOT / 'eval/s7'))
import harness  # noqa
from mvp_tasks import MVP
TASKS = {t.id: t for t in MVP}
RUN = HERE.parent
OUT = Path(tempfile.mkdtemp())
SAMPLES = tuple(int(x) for x in (sys.argv[1:] or ['2', '4', '5', '6']))

DEF = re.compile(r'(?ms)^:\s+(\S+)\s*(\((?:[^()]|\([^()]*\))*?--[^()]*\))(.*?)(;)[ \t]*$')


def words(src):
    return [dict(name=m[1], sig=m[2], body=m[3], span=m.span(), sigspan=m.span(2), bodyspan=m.span(3)) for m in DEF.finditer(src)]


def sig_inputs(sig):
    """[(name, type)] for a Firth signature `(forall ρ; ρ a:T^m b:U^m -- ...)`."""
    m = re.match(r'\(\s*forall[^;]*;\s*\S+\s*(.*?)--', sig, re.S)
    if not m:
        return None
    out = []
    for n, t in re.findall(r'([A-Za-z][\w-]*)\s*:\s*((?:Seq\s+)?\w+)', m[1]):
        out.append((n, t))
    return out


def real_sig(t):
    ins = ' '.join(f'{n}:{ty}^many' for n, ty in t.inputs)
    outs = ' '.join(f'{n}:{ty}^many' for n, ty in t.outputs)
    return f'(forall ρ; ρ {ins} -- ρ {outs})'


def splice(src, edits):
    for (a, b), s in sorted(edits, key=lambda e: -e[0][0]):
        src = src[:a] + s + src[b:]
    return src


# ---- candidate edits -------------------------------------------------------

def fix_main_sig(src, t):
    """A `main` whose stack effect is not a Firth signature gets the task's."""
    for w in words(src):
        if w['name'] == 'main' and sig_inputs(w['sig']) is None:
            return splice(src, [(w['sigspan'], real_sig(t))])
    return src


def bind_main(src, t):
    """A `main` without an opening `locals` that uses an input name gets one."""
    for w in words(src):
        if w['name'] != 'main' or re.match(r'\s*locals\b', w['body']):
            continue
        names = [n for n, _ in t.inputs]
        if any(re.search(rf'(?<![\w-]){re.escape(n)}(?![\w-])', w['body']) for n in names):
            return splice(src, [(w['bodyspan'], f"\n  locals {{ {' '.join(names)} }} {{{w['body']} }}")])
    return src


def order_locals(src, t):
    """An opening `locals` that names the word's inputs in another order is put in
    effect order, body unchanged (what the locals-order hint says to do)."""
    edits = []
    for w in words(src):
        ins = sig_inputs(w['sig'])
        m = re.match(r'(\s*locals\s*\{)([^}]*)\}', w['body'])
        if not ins or not m:
            continue
        names, want = m[2].split(), [n for n, _ in ins]
        if sorted(names) == sorted(want) and names != want:
            a = w['bodyspan'][0] + m.start(2)
            edits.append(((a, a + len(m[2])), ' ' + ' '.join(want) + ' '))
    return splice(src, edits)


def at_order(src, t):
    """`i xs prim seq-X.at` becomes `xs i prim seq-X.at` when the token next to
    `prim` is a Seq-typed input of the word and the one before it is not."""
    edits = []
    for w in words(src):
        ins = sig_inputs(w['sig']) or []
        seqs = {n for n, ty in ins if ty.startswith('Seq')}
        for m in re.finditer(r'(?<![\w-])([\w-]+)(\s+)([\w-]+)(\s+prim\s+seq-(?:int|bool)\.at)\b', w['body']):
            if m[3] in seqs and m[1] not in seqs and not m[1].isdigit():
                a = w['bodyspan'][0] + m.start()
                edits.append(((a, a + m.end(3) - m.start()), f'{m[3]}{m[2]}{m[1]}'))
    return splice(src, edits)


def strip_parens(src, t):
    """Parentheses inside a body are removed, keeping what they held."""
    edits = []
    for w in words(src):
        a = w['bodyspan'][0]
        for m in re.finditer(r'[()]', w['body']):
            edits.append(((a + m.start(), a + m.end()), ' '))
    return splice(src, edits)


def block_semicolon(src, t):
    """`;` closing a block inside a body (`] if;`) is removed."""
    return re.sub(r'\]\s*if;(?=\s*\})', '] if', src)


def prim_literal(src, t):
    """`prim 0` / `prim -1` (a literal after `prim`) becomes the literal."""
    return re.sub(r'\bprim\s+(-?\d+)\b', r'\1', src)


def forth_comments(src, t):
    """Model: `( ... -- ... )` inside a body is a comment. Counted, not scored:
    removing it from bodies only; signatures are left alone."""
    edits = []
    for w in words(src):
        a = w['bodyspan'][0]
        for m in re.finditer(r'\([^()]*--[^()]*\)', w['body']):
            edits.append(((a + m.start(), a + m.end()), ' '))
    return splice(src, edits)


PROMPT = [fix_main_sig, bind_main, order_locals, at_order, strip_parens]
CANDIDATES = {
    'main-signature': [fix_main_sig],
    'bind-main': [bind_main],
    'locals-order': [order_locals],
    'at-order': [at_order],
    'no-parens': [strip_parens],
    'prompt-all': PROMPT,
    'prim-literal': [prim_literal],
    'block-semicolon': [block_semicolon],
    'parse-diagnostic': [strip_parens, block_semicolon],
    'prompt-all+prim-literal': PROMPT + [prim_literal],
    'everything': [block_semicolon] + PROMPT + [prim_literal],
}

# ---- checking ----------------------------------------------------------------

PHASE = {'syntax': 0, 'name': 1, 'type': 2}


def check(src):
    with tempfile.NamedTemporaryFile('w', suffix='.firth', delete=False) as f:
        f.write(src)
    p = subprocess.run([sys.executable, str(ROOT / 'tools/loop/firth_run.py'), 'check', f.name],
                       cwd=ROOT, capture_output=True, text=True)
    Path(f.name).unlink()
    if p.returncode == 0:
        return None
    s = p.stderr + p.stdout
    code = re.search(r"'code': '([^']+)'", s)
    line = re.search(r"'start': \{'line': (\d+), 'column': (\d+)", s)
    return (code[1] if code else 'unknown', int(line[1]) if line else 0, int(line[2]) if line else 0)


def word_at(src, line):
    off = sum(len(l) + 1 for l in src.split('\n')[:line - 1])
    for w in words(src):
        if w['span'][0] <= off <= w['span'][1]:
            return w['name']
    return None


def independent_errors(src):
    """Check each word with every other word stubbed as a self-call; return the
    words that carry an error of their own."""
    ws = words(src)
    if not ws:
        return None
    bad = []
    for w in ws:
        stubbed = splice(src, [(o['bodyspan'], f"\n  {o['name']} ") for o in ws if o is not w])
        e = check(stubbed)
        if e and word_at(stubbed, e[1]) == w['name']:
            bad.append((w['name'], e[0]))
    return bad


def phase(code):
    return PHASE.get(code.split('.')[1], 2) if code and code.startswith('firth.') else 2


def main():
    rows = []           # one per (sample, round, task, candidate)
    indep = {}          # (sample, round, task) -> independent errors
    jobs = []
    for s in SAMPLES:
        for n in (1, 2):
            sol = json.load(open(RUN / f'haiku-firth-{s}/solutions-{n}.json'))
            res = json.load(open(RUN / f'haiku-firth-{s}/results-{n}.json'))['tasks']
            for task, src in sol.items():
                if res[task]['pass']:
                    continue
                jobs.append((s, n, task, src))
    def base(j):
        s, n, task, src = j
        return j, check(src), independent_errors(src)
    with ThreadPoolExecutor(8) as ex:
        basel = list(ex.map(base, jobs))
    edited = {}
    for (s, n, task, src), b, ind in basel:
        indep[f'{s}/{n}/{task}'] = {'first': b, 'words': ind}
        for cname, fs in CANDIDATES.items():
            e = src
            for f in fs:
                e = f(e, TASKS[task])
            edited[(cname, s, n, task)] = (src, e, b)
    todo = [(k, v) for k, v in edited.items() if v[1] != v[0]]
    def chk(kv):
        return kv[0], check(kv[1][1])
    with ThreadPoolExecutor(8) as ex:
        after = dict(ex.map(chk, todo))
    # score those that now pass the checker
    toscore = collections.defaultdict(dict)
    for k, a in after.items():
        if a is None:
            toscore[(k[0], k[1], k[2])][k[3]] = edited[k][1]
    passed = set()
    for (cname, s, n), sols in toscore.items():
        f = OUT / f'{cname}-{s}-{n}.json'
        json.dump(sols, open(f, 'w'), indent=1)
        r = subprocess.run([sys.executable, 'eval/s7/harness.py', 'score', '--lang', 'firth', '--tier', 'mvp', str(f),
                            '--label', 'cf', '--prompt-docs', 'x', '--jobs', '8'], cwd=ROOT, capture_output=True, text=True)
        rr = json.loads(r.stdout)['tasks']
        for t in sols:
            if rr[t]['pass']:
                passed.add((cname, s, n, t))
    for k, (src, e, b) in edited.items():
        cname, s, n, task = k
        if e == src:
            out = 'untouched'
        else:
            a = after[k]
            if k in passed:
                out = 'pass'
            elif a is None:
                out = 'checks, wrong'
            elif b and a[0] == b[0] and word_at(e, a[1]) == word_at(src, b[1]):
                out = 'same'
            elif b and phase(a[0]) < phase(b[0]):
                out = 'earlier'
            else:
                out = 'moved on'
        rows.append(dict(candidate=cname, sample=s, round=n, task=task, outcome=out,
                         before=b and b[0], after=None if e == src else (after[k] and after[k][0])))
    json.dump({'rows': rows, 'independent': indep}, open(HERE / 'measure.json', 'w'), indent=1)
    c = collections.defaultdict(collections.Counter)
    for r in rows:
        c[r['candidate']][r['outcome']] += 1
    for k, v in c.items():
        print(k, dict(v))


if __name__ == '__main__':
    main()
