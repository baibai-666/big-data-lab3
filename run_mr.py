import pathlib,subprocess,json,os
b=pathlib.Path(__file__).resolve().parent
out=b/'results';out.mkdir(exist_ok=True)
g={}
for line in (b/'graph.txt').read_text().splitlines():
    a,links=line.split('\t');g.setdefault(a,set()).update(filter(None,links.split(',')))
for node in set.union(set(g),*(v for v in g.values())):g.setdefault(node,set())
n=len(g)
state=''.join(f'{a}\t{1/n:.17g}\t{",".join(sorted(g[a]))}\n' for a in sorted(g))
(out/'initial.tsv').write_text(state)
def call(args):return subprocess.check_output(args,text=True)
root='/user/baibai/lab3-pr'
subprocess.run(['hdfs','dfs','-mkdir','-p',root],check=True)
subprocess.run(['hdfs','dfs','-put',str(out/'initial.tsv'),root+'/initial.tsv'],check=True)
subprocess.run(['hdfs','dfs','-put',str(b/'graph.txt'),root+'/graph.txt'],check=True)
history=[]
stream=os.environ['HADOOP_HOME']+'/share/hadoop/tools/lib/hadoop-streaming-3.4.1.jar'
for i in range(1,11):
    rows=[s.split('\t') for s in state.splitlines()]
    dangling=sum(float(r[1]) for r in rows if not r[2])
    dest=root+f'/iter{i:02d}'
    src=root+'/initial.tsv' if i==1 else root+f'/iter{i-1:02d}'
    cmd=['hadoop','jar',stream,'-D','mapreduce.job.name=lab3-pagerank-'+str(i),'-D','mapreduce.job.reduces=2','-files',str(b/'pr_stream.py'),'-input',src,'-output',dest,'-mapper','python3 pr_stream.py map','-reducer',f'python3 pr_stream.py reduce {n} {dangling:.17g}']
    with (out/f'mr-iteration-{i:02d}.log').open('w') as log:subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,check=True)
    state=call(['hdfs','dfs','-cat',dest+'/part-*'])
    (out/f'mr-{i:02d}.tsv').write_text(state)
    ranks={r[0]:float(r[1]) for r in (s.split('\t') for s in state.splitlines())}
    history.append(ranks);print('MR iteration',i,'nodes',len(ranks),'sum',sum(ranks.values()),flush=True)
(out/'mr-history.json').write_text(json.dumps(history,indent=2))
(out/'mr.txt').write_text(''.join(f'({a},{r:.10f})\n' for a,r in sorted(ranks.items(),key=lambda x:(-x[1],x[0]))))
