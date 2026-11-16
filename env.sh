export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME="$HOME/lab3-runtime/hadoop-3.4.1"
export HBASE_HOME="$HOME/lab3-runtime/hbase-2.5.10-hadoop3"
export SPARK_HOME="$HOME/lab3-runtime/spark-3.5.3-bin-hadoop3"
export LAB_STATE="$HOME/lab3-state"
export HADOOP_CONF_DIR="$LAB_STATE/conf" HADOOP_LOG_DIR="$LAB_STATE/logs" HADOOP_PID_DIR="$LAB_STATE/pids"
export HADOOP_COMMON_HOME="$HADOOP_HOME" HADOOP_HDFS_HOME="$HADOOP_HOME" HADOOP_YARN_HOME="$HADOOP_HOME" HADOOP_MAPRED_HOME="$HADOOP_HOME"
export HBASE_CONF_DIR="$LAB_STATE/hbase-conf" HBASE_LOG_DIR="$LAB_STATE/hbase-logs" HBASE_PID_DIR="$LAB_STATE/hbase-pids"
export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP=true
export PATH="$JAVA_HOME/bin:$HADOOP_HOME/bin:$HBASE_HOME/bin:$SPARK_HOME/bin:$PATH"
