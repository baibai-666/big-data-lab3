import sys
from itertools import groupby

if sys.argv[1] == 'map':
    for line in sys.stdin:
        node, rank, links = line.rstrip('\n').split('\t')
        targets=links.split(',') if links else []
        print(node+'\tS\t'+links)
        for target in targets: print(target+'\tV\t'+repr(float(rank)/len(targets)))
else:
    n=int(sys.argv[2]); dangling=float(sys.argv[3])
    for node, rows in groupby(sys.stdin,lambda s:s.split('\t',1)[0]):
        total=0.0; links=None
        for line in rows:
            _,kind,value=line.rstrip('\n').split('\t',2)
            if kind=='S': links=value
            else: total+=float(value)
        assert links is not None, node
        print(f'{node}\t{(1-.85)/n+.85*(total+dangling/n):.17g}\t{links}')
