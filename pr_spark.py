from pyspark import SparkContext
from operator import add
import sys,json,pathlib
sc=SparkContext(appName='lab3-pagerank');sc.setLogLevel('WARN')
def parse(s):
    a,rest=s.split('\t');return a,tuple(filter(None,rest.split(',')))
raw=sc.textFile(sys.argv[1]).map(parse)
nodes=raw.flatMap(lambda x:[x[0]]+list(x[1])).distinct().map(lambda a:(a,()))
edges=raw.reduceByKey(lambda a,b:tuple(set(a+b)))
links=nodes.leftOuterJoin(edges).mapValues(lambda x:tuple(sorted(set(x[1] or ())))).cache()
n=links.count();ranks=links.mapValues(lambda _:1/n).cache();history=[]
for i in range(10):
    joined=links.join(ranks).cache()
    dangling=joined.filter(lambda x:not x[1][0]).map(lambda x:x[1][1]).sum()
    sums=joined.flatMap(lambda x:((v,x[1][1]/len(x[1][0])) for v in x[1][0])).reduceByKey(add)
    new=links.leftOuterJoin(sums).mapValues(lambda x:(1-.85)/n+.85*((x[1] or 0)+dangling/n)).cache()
    values=dict(new.collect());history.append(values)
    print('SPARK iteration',i+1,'nodes',len(values),'sum',sum(values.values()),flush=True)
    joined.unpersist();ranks.unpersist();ranks=new
out=pathlib.Path(sys.argv[2]);out.mkdir(exist_ok=True)
(out/'spark-history.json').write_text(json.dumps(history,indent=2))
(out/'spark.txt').write_text(''.join(f'({a},{r:.10f})\n' for a,r in sorted(values.items(),key=lambda x:(-x[1],x[0]))))
sc.stop()
