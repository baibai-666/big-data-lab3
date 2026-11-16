#!/usr/bin/env bash
set -euo pipefail
: "${JAVA_HOME:?Java 11 is required}"
: "${HADOOP_HOME:?Set HADOOP_HOME}"
: "${LAB_STATE:?Set a fresh lab state directory}"
[[ ! -e "$LAB_STATE" ]] || { echo "Refusing to format existing state: $LAB_STATE"; exit 1; }
mkdir -p "$LAB_STATE"
export HADOOP_CONF_DIR="$LAB_STATE/conf" HADOOP_LOG_DIR="$LAB_STATE/logs" HADOOP_PID_DIR="$LAB_STATE/pids"
mkdir -p "$HADOOP_CONF_DIR" "$HADOOP_LOG_DIR" "$HADOOP_PID_DIR"
cp -a "$HADOOP_HOME/etc/hadoop/." "$HADOOP_CONF_DIR/"
cat > "$HADOOP_CONF_DIR/hadoop-env.sh" <<EOF
export JAVA_HOME=$JAVA_HOME
export HADOOP_LOG_DIR=$HADOOP_LOG_DIR
export HADOOP_PID_DIR=$HADOOP_PID_DIR
export HADOOP_HEAPSIZE_MAX=512
EOF
cat > "$HADOOP_CONF_DIR/core-site.xml" <<'EOF'
<configuration>
 <property><name>fs.defaultFS</name><value>hdfs://localhost:9000</value></property>
</configuration>
EOF
cat > "$HADOOP_CONF_DIR/hdfs-site.xml" <<EOF
<configuration>
 <property><name>dfs.replication</name><value>1</value></property>
 <property><name>dfs.namenode.name.dir</name><value>file://$LAB_STATE/name</value></property>
 <property><name>dfs.datanode.data.dir</name><value>file://$LAB_STATE/data</value></property>
 <property><name>dfs.namenode.http-address</name><value>127.0.0.1:9870</value></property>
</configuration>
EOF
cat > "$HADOOP_CONF_DIR/mapred-site.xml" <<EOF
<configuration>
 <property><name>mapreduce.framework.name</name><value>yarn</value></property>
 <property><name>mapreduce.application.classpath</name><value>$HADOOP_HOME/share/hadoop/mapreduce/*,$HADOOP_HOME/share/hadoop/mapreduce/lib/*</value></property>
 <property><name>yarn.app.mapreduce.am.env</name><value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value></property>
 <property><name>mapreduce.map.env</name><value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value></property>
 <property><name>mapreduce.reduce.env</name><value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value></property>
 <property><name>mapreduce.map.memory.mb</name><value>512</value></property>
 <property><name>mapreduce.reduce.memory.mb</name><value>512</value></property>
 <property><name>mapreduce.map.java.opts</name><value>-Xmx384m</value></property>
 <property><name>mapreduce.reduce.java.opts</name><value>-Xmx384m</value></property>
 <property><name>yarn.app.mapreduce.am.resource.mb</name><value>768</value></property>
 <property><name>yarn.app.mapreduce.am.command-opts</name><value>-Xmx512m</value></property>
 <property><name>mapreduce.job.ubertask.enable</name><value>false</value></property>
</configuration>
EOF
cat > "$HADOOP_CONF_DIR/yarn-site.xml" <<EOF
<configuration>
 <property><name>yarn.resourcemanager.hostname</name><value>localhost</value></property>
 <property><name>yarn.nodemanager.hostname</name><value>localhost</value></property>
 <property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property>
 <property><name>yarn.nodemanager.env-whitelist</name><value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME,PATH,LANG,TZ</value></property>
 <property><name>yarn.nodemanager.resource.memory-mb</name><value>6144</value></property>
 <property><name>yarn.nodemanager.resource.cpu-vcores</name><value>4</value></property>
 <property><name>yarn.scheduler.minimum-allocation-mb</name><value>256</value></property>
 <property><name>yarn.scheduler.maximum-allocation-mb</name><value>2048</value></property>
 <property><name>yarn.nodemanager.vmem-check-enabled</name><value>false</value></property>
 <property><name>yarn.nodemanager.local-dirs</name><value>$LAB_STATE/nm-local</value></property>
 <property><name>yarn.nodemanager.log-dirs</name><value>$LAB_STATE/nm-logs</value></property>
</configuration>
EOF
hdfs namenode -format -nonInteractive
hdfs --daemon start namenode
hdfs --daemon start datanode
timeout 90 hdfs dfsadmin -safemode wait
for attempt in $(seq 1 30); do
  if hdfs dfsadmin -report | grep -q 'Live datanodes (1)'; then break; fi
  sleep 2
done
hdfs dfsadmin -report | grep 'Live datanodes (1)'
yarn --daemon start resourcemanager
yarn --daemon start nodemanager
for attempt in $(seq 1 45); do
  if yarn node -list 2>/dev/null | grep -q 'RUNNING'; then break; fi
  sleep 2
done
yarn node -list | tee results/yarn-nodes.txt
grep -q 'RUNNING' results/yarn-nodes.txt
jps | tee results/java-processes.txt
hdfs dfsadmin -report > results/hdfs-report.txt
echo 'HDFS AND YARN READY'
