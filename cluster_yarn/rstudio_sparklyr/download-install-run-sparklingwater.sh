wget http://h2o-release.s3.amazonaws.com/sparkling-water/rel-2.1/27/sparkling-water-2.1.27.zip
unzip sparkling-water-2.1.27.zip
cd sparkling-water-2.1.27
cp sparkling-water-2.1.27/assembly/build/libs/sparkling-water-assembly_2.11-2.1.27-all.jar ~/spark/spark-2.1.0-bin-hadoop2.7/jars/
export SPARK_HOME=/opt/cloudera/parcels/SPARK2/lib/spark2/
bin/sparkling-shell --conf "spark.executor.memory=1g"
