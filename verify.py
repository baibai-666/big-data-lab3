from pathlib import Path
from decimal import Decimal,getcontext
import json,re
getcontext().prec=50
b=Path(__file__).resolve().parent;o=b/'results';g={}
for line in (b/'graph.txt').read_text().splitlines():
 a,s=line.split('\t');g.setdefault(a,set()).update(filter(None,s.split(',')))
nodes=sorted(set(g)|{v for vs in g.values() for v in vs});n=len(nodes)
for a in nodes:g.setdefault(a,set())
# Dense transition matrix, independent of both distributed implementations.
d=Decimal('0.85');matrix=[]
for dest in nodes:
 matrix.append([(1-d)/n+d*(Decimal(1)/len(g[src]) if dest in g[src] else Decimal(0)) if g[src] else Decimal(1)/n for src in nodes])
r=[Decimal(1)/n]*n;expected=[]
for _ in range(10):r=[sum(matrix[i][j]*r[j] for j in range(n)) for i in range(n)];expected.append(dict(zip(nodes,map(float,r))))
errors={}
for name in ['mr','spark']:
 hist=json.loads((o/(name+'-history.json')).read_text());assert len(hist)==10
 errors[name]=[]
 for i,actual in enumerate(hist):
  assert set(actual)==set(nodes);assert abs(sum(actual.values())-1)<1e-12;assert all(v>=0 for v in actual.values())
  err=max(abs(actual[k]-expected[i][k]) for k in nodes);assert err<1e-12;errors[name].append(err)
 for line in (o/(name+'.txt')).read_text().splitlines():assert re.fullmatch(r'\([A-Z],0\.\d{10}\)',line)
 assert len((o/(name+'.txt')).read_text().splitlines())==n
 print('PASS',name,'10 iterations; nodes=',n,'max error=',max(errors[name]))
assert (o/'mr.txt').read_text()==(o/'spark.txt').read_text()
assert 'HBASE JAVA ALL CHECKS PASSED' in (o/'hbase-java.log').read_text()
assert 'ERROR:' not in (o/'hbase-shell.log').read_text()
summary={'iterations':10,'nodes':n,'edges':sum(map(len,g.values())),'dangling':[k for k in nodes if not g[k]],'max_error':{k:max(v) for k,v in errors.items()},'ranks':expected[-1],'hbase':'passed','format':'10 decimal places','mr_spark_equal':True}
(o/'verification.json').write_text(json.dumps(summary,indent=2))
print('PASS normalized rank sum, duplicate links, target-only I, isolated J, HBase Java/Shell, exact formatted output agreement')
print((o/'mr.txt').read_text())
