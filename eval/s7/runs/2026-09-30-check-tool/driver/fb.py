import json,sys
a,n,r=sys.argv[1],sys.argv[2],int(sys.argv[3])
t=json.load(open('/home/user/firth-r12/eval/s7/runs/2026-09-30-check-tool/instructions-templates.json'))[a][r]
t=t.replace('{ARM}','arm-a' if a=='A' else 'arm-b').replace('{N}',n)
pre="The coordinator sent a message while you were working:\n"; post="\n\nAddress this before completing your current task."
assert t.startswith(pre) and t.endswith(post)
print(t[len(pre):-len(post)])
