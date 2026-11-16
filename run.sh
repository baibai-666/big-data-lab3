#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME="$HOME/lab3-runtime/hadoop-3.4.1"
export HBASE_HOME="$HOME/lab3-runtime/hbase-2.5.10-hadoop3"
export SPARK_HOME="$HOME/lab3-runtime/spark-3.5.3-bin-hadoop3"
export LAB_STATE="$HOME/lab3-state"
export HADOOP_CONF_DIR="$LAB_STATE/conf" HADOOP_LOG_DIR="$LAB_STATE/logs" HADOOP_PID_DIR="$LAB_STATE/pids"
export HADOOP_COMMON_HOME="$HADOOP_HOME" HADOOP_HDFS_HOME="$HADOOP_HOME" HADOOP_YARN_HOME="$HADOOP_HOME" HADOOP_MAPRED_HOME="$HADOOP_HOME"
export PATH="$JAVA_HOME/bin:$HADOOP_HOME/bin:$HBASE_HOME/bin:$SPARK_HOME/bin:$PATH"
mkdir -p results build
bash setup_hadoop.sh > results/hadoop-setup.log 2>&1
export HBASE_CONF_DIR="$LAB_STATE/hbase-conf" HBASE_LOG_DIR="$LAB_STATE/hbase-logs" HBASE_PID_DIR="$LAB_STATE/hbase-pids"
mkdir -p "$HBASE_CONF_DIR" "$HBASE_LOG_DIR" "$HBASE_PID_DIR"
cp -a "$HBASE_HOME/conf/." "$HBASE_CONF_DIR/"
cat > "$HBASE_CONF_DIR/hbase-env.sh" <<EOF
export JAVA_HOME=$JAVA_HOME
export HBASE_HEAPSIZE=512
export HBASE_MANAGES_ZK=true
export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP=true
EOF
cat > "$HBASE_CONF_DIR/hbase-site.xml" <<EOF
<configuration>
<property><name>hbase.rootdir</name><value>hdfs://localhost:9000/hbase-lab3</value></property>
<property><name>hbase.cluster.distributed</name><value>true</value></property>
<property><name>hbase.zookeeper.quorum</name><value>localhost</value></property>
<property><name>hbase.zookeeper.property.dataDir</name><value>$LAB_STATE/zk</value></property>
<property><name>hbase.master.hostname</name><value>localhost</value></property>
<property><name>hbase.regionserver.hostname</name><value>localhost</value></property>
<property><name>hbase.wal.provider</name><value>filesystem</value></property>
</configuration>
EOF
"$HBASE_HOME/bin/hbase-daemon.sh" start zookeeper
for attempt in $(seq 1 60); do
 if (echo > /dev/tcp/localhost/2181) 2>/dev/null; then break; fi
 sleep 2
done
ss -lnt | grep 2181
"$HBASE_HOME/bin/hbase-daemon.sh" start master
"$HBASE_HOME/bin/hbase-daemon.sh" start regionserver
sleep 15
javac -encoding UTF-8 -cp "$(hbase classpath)" -d build HBaseLab.java
timeout 240 java -cp "build:$(hbase classpath)" HBaseLab > results/hbase-java.log 2>&1
hbase shell -n hbase-shell.rb > results/hbase-shell.log 2>&1
grep 'HBASE JAVA ALL CHECKS PASSED' results/hbase-java.log
! grep -E '^ERROR|ERROR:' results/hbase-shell.log
python3 run_mr.py | tee results/mr-progress.log
export SPARK_LOCAL_IP=127.0.0.1
export SPARK_LOG_DIR="$LAB_STATE/spark-logs" SPARK_PID_DIR="$LAB_STATE/spark-pids"
mkdir -p "$SPARK_LOG_DIR" "$SPARK_PID_DIR"
"$SPARK_HOME/sbin/start-master.sh" --host 127.0.0.1
"$SPARK_HOME/sbin/start-worker.sh" --cores 2 --memory 2g spark://127.0.0.1:7077
spark-submit --master spark://127.0.0.1:7077 --conf spark.driver.host=127.0.0.1 --executor-memory 1g --total-executor-cores 2 pr_spark.py hdfs://localhost:9000/user/baibai/lab3-pr/graph.txt results > results/spark.log 2>&1
python3 verify.py | tee results/verification.log
jps > results/java-processes.txt
yarn application -list -appStates FINISHED > results/yarn-applications.txt
{ date -Is;uname -a;java -version;hadoop version;free -h;nproc; } > results/environment.txt 2>&1
echo 'LAB3 ALL EXPERIMENTS PASSED'
