# 实验三 HBase 与 PageRank

HBase Shell 和 Java API 操作，以及 Hadoop MapReduce、Spark 两种 PageRank 实现。

## 环境

- Ubuntu 22.04，Java 11，Python 3
- Hadoop 3.4.1：HDFS + YARN 单节点伪分布式
- HBase 2.5.10 Hadoop 3 版：ZooKeeper、Master、RegionServer
- Spark 3.5.3 Hadoop 3 版：独立 Master/Worker 集群

## 运行

把 Apache 官方二进制发行包解压到 `~/lab3-runtime/`，使 `run.sh` 中的三个 HOME 路径与实际目录一致。Java 路径也在脚本开头设置。需要空闲的 HDFS、YARN、ZooKeeper 和 Spark 默认端口。

```bash
bash run.sh
```

首次运行会创建 `~/lab3-state` 并格式化其中的新 NameNode 目录。该目录已经存在时脚本会退出，避免覆盖已有数据。HBase 示例操作仅接受 `lab3_` 前缀的表；重复运行 Java 示例会重新创建这些实验表。

## 文件

| 文件 | 内容 |
|---|---|
| HBaseLab.java | 建表、写入、查询、修改、删除、计数、列族操作及断言 |
| hbase-shell.rb | 对应的 HBase Shell 操作 |
| graph.txt | PageRank 输入，网页与出链之间为制表符 |
| pr_stream.py | Hadoop Streaming Mapper 和 Reducer |
| run_mr.py | 连续提交 10 个 YARN 作业，保存每轮结果 |
| pr_spark.py | Spark RDD 迭代实现 |
| verify.py | 独立高精度矩阵计算及逐轮结果校验 |
| setup_hadoop.sh | 创建本次实验的 HDFS 和 YARN 配置 |
| results/ | 实际日志、每轮 PR、最终输出和校验结果 |

## HBase 数据

Student 行键为姓名，列族 Info 保存基本信息，Score 保存各课程成绩。Course 行键为课程号；SC 行键为“学号_课程号”。原题 Mary 与 Lisi 的学号重复，结合选课表将 Mary 记为 2015002。三张表分别有 3、3、6 行。

`scanColumn` 扫描全部行后读取指定列，缺失列明确输出 `null`。`modifyData(table,row,column)` 从系统属性 `lab3.newValue` 读取新值，另提供带 value 参数的重载。

## PageRank 约定

输入包含 10 个网页，去重后 13 条边。A 的重复链接只计一次；I 仅出现在链接目标中；J 为孤立网页。初始 PR=1/N，阻尼系数为 0.85，悬挂网页的 PR 平均分给所有网页。两种实现都执行恰好 10 次迭代。

每轮公式为：`newPR(v)=(1-d)/N+d*(sumIncoming(v)+danglingMass/N)`。

最终按 PR 降序、网页名升序排列，输出 `(网页,PR)`，PR 保留 10 位小数。中间迭代不提前截断。

校验程序使用 50 位 Decimal 精度的转移矩阵作独立参考，逐轮检查网页集合、非负性、PR 总和及绝对误差；最后比较两个框架的格式化输出。

## 停止服务

实验后可执行 `bash stop.sh` 停止本次配置启动的服务，数据及运行记录会保留。
