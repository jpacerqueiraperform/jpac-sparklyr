#wget https://d3kbcqa49mib13.cloudfront.net/spark-1.6.2-bin-hadoop2.6.tgz
#tar -xvzf spark-1.6.2-bin-hadoop2.6.tgz
#wget http://d3kbcqa49mib13.cloudfront.net/spark-2.1.0-bin-hadoop2.7.tgz
#tar -xvzf spark-2.1.0-bin-hadoop2.7.tgz
#cd spark-2.1.0-bin-hadoop2.7
ls
cd ..
#wget  http://central.maven.org/maven2/ai/h2o/sparkling-water-core_2.11/2.1.27/sparkling-water-core_2.11-2.1.27.jar
cp sparkling-water-*_2.11-2.1.27.jar  spark-2.1.0-bin-hadoop2.7/jars
wget http://central.maven.org/maven2/no/priv/garshol/duke/duke/1.2/duke-1.2.jar
cp duke-1.2.jar spark-2.1.0-bin-hadoop2.7/jars
cp spark-2.1.0-bin-hadoop2.7/jars/*.jar /home/analyticsdb/.ivy2/jars
mv spark-2.1.0-bin-hadoop2.7 old-spark-2.1.0-bin-hadoop2.7
mkdir -p  /home/analyticsdb/.m2/repository/ai/h2o/sparkling-water-core_2.11/2.1.0/
cp spark-2.1.0-bin-hadoop2.7/jars/sparkling-water-*_2.11-2.1.27.jar /home/analyticsdb/.m2/repository/ai/h2o/sparkling-water-core_2.11/2.1.0/
mkdir -p /home/analyticsdb/.m2/repository/no/priv/garshol/duke/duke/1.2/duke-1.2.jar
cp spark-2.1.0-bin-hadoop2.7/jars/duke-1.2.jar /home/analyticsdb/.m2/repository/no/priv/garshol/duke/duke/1.2/duke-1.2.jar

ln -s /opt/cloudera/parcels/SPARK2/lib/spark2/ spark2
#ln -s /opt/cloudera/parcels/SPARK2/lib/spark2/ spark-2.1.0-bin-hadoop2.7
cd spark-2.1.0-bin-hadoop2.7
ln -s /opt/cloudera/parcels/SPARK2/lib lib
cd ..
ln -s /opt/cloudera/parcels/CDH/ CDH
cd ~
bash -x ~/spark/make_condar_env.sh 

echo done
