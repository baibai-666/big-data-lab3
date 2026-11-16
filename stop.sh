#!/bin/bash
set -u
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME="$HOME/lab3-runtime/hadoop-3.4.1"
export HBASE_HOME="$HOME/lab3-runtime/hbase-2.5.10-hadoop3"
export SPARK_HOME="$HOME/lab3-runtime/spark-3.5.3-bin-hadoop3"
export LAB_STATE="$HOME/lab3-state"
export HADOOP_CONF_DIR="$LAB_STATE/conf" HADOOP_LOG_DIR="$LAB_STATE/logs" HADOOP_PID_DIR="$LAB_STATE/pids"
export HBASE_CONF_DIR="$LAB_STATE/hbase-conf" HBASE_LOG_DIR="$LAB_STATE/hbase-logs" HBASE_PID_DIR="$LAB_STATE/hbase-pids"
export SPARK_LOG_DIR="$LAB_STATE/spark-logs" SPARK_PID_DIR="$LAB_STATE/spark-pids"
"$SPARK_HOME/sbin/stop-worker.sh"
"$SPARK_HOME/sbin/stop-master.sh"
for service in regionserver master zookeeper; do "$HBASE_HOME/bin/hbase-daemon.sh" stop "$service"; done
"$HADOOP_HOME/bin/yarn" --daemon stop nodemanager
"$HADOOP_HOME/bin/yarn" --daemon stop resourcemanager
"$HADOOP_HOME/bin/hdfs" --daemon stop datanode
"$HADOOP_HOME/bin/hdfs" --daemon stop namenode
