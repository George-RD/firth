"""Run 9 tables: passes per round, failures by the first diagnostic of the
visible example, answers whose feedback shows two or more errors, and jev
modes, over the counted samples 1, 2, 3 and 5. Run from this directory:
`python3 fixes/tabulate.py`."""
import json,re,collections,sys
S=[1,2,3,5]
def fam(e):
    if e is None: return None
    m=re.search(r'code: (firth\.[a-z.-]+)',e)
    if not m: return 'wrong answer or runtime fault'
    c=m[1]
    return 'firth.syntax.*' if c.startswith('firth.syntax.') else c
tab=collections.defaultdict(lambda: collections.Counter()); bys=collections.defaultdict(dict)
multi=collections.Counter(); failing=collections.Counter(); passed={}
nerr=collections.Counter()
for s in S+[4]:
  for n in (1,2,3):
    r=json.load(open(f'haiku-firth-{s}/results-{n}.json'))['tasks']
    p=0
    for tid,t in r.items():
      if all(c.get('pass') for c in t['cases']) and t['cases']: p+=1; continue
      vis=[c for c in t['cases'] if c.get('visible')][0]
      e=vis.get('error') or ''
      if s in S:
        f=fam(e) if e else 'wrong answer or runtime fault'
        tab[f][n]+=1; bys[(s,f)][n]=bys[(s,f)].get(n,0)+1
        failing[n]+=1
        m=re.match(r'The checker found (\d+) errors',e)
        if m and int(m[1])>=2: multi[n]+=1; nerr[int(m[1])]+=1
    passed[(s,n)]=p
print('passed',passed)
print('failing',dict(failing),'multi',dict(multi),'nerr',dict(nerr))
for f,c in sorted(tab.items(),key=lambda x:-sum(x[1].values())): print(f,[c[n] for n in (1,2,3)], {s:[bys[(s,f)].get(n,0) for n in (1,2,3)] for s in S})
for n in (1,3):
  tot=collections.Counter()
  for s in S: tot.update(json.load(open(f'haiku-firth-{s}/modes-{n}.json'))['counts'])
  print('jev',n,dict(tot))
# Tasks that passed after failing in the round before, by the feedback they
# got: its first code, and whether it showed two or more errors.
def st(s,n):
  r=json.load(open(f'haiku-firth-{s}/results-{n}.json'))['tasks'];o={}
  for tid,t in r.items():
    ok=bool(t['cases']) and all(c.get('pass') for c in t['cases'])
    e=[c for c in t['cases'] if c.get('visible')][0].get('error') or ''
    m=re.search(r'code: (firth\.[a-z.-]+)',e)
    k=re.match(r'The checker found (\d+) errors',e)
    o[tid]=(ok,(m[1] if m else 'wrong answer or runtime fault'),bool(k and int(k[1])>=2))
  return o
rep=collections.Counter(); regress=0
for s in S:
  for n in (1,2):
    a,b=st(s,n),st(s,n+1)
    for tid in a:
      if not a[tid][0] and b[tid][0]: rep[a[tid][1:]]+=1
      if a[tid][0] and not b[tid][0]: regress+=1
print('repaired',sum(rep.values()),'regressed',regress,rep.most_common())
