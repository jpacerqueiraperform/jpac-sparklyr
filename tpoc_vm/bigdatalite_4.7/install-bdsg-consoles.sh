#!/bin/bash

# Configuring webserver for BDSG
export INSTALL_HOME="/home/oracle/scripts/bdsg"
#export INSTALL_HOME="/home/osg/configure-server/bdsg"
export ORACLE_SPATIAL="/u01/oracle-spatial-graph/"
#export ORACLE_SPATIAL="/opt/oracle/oracle-spatial-graph"
export TARGET=$ORACLE_SPATIAL/spatial
export WEB_SERVER="web-server"
export SERVER=$TARGET/$WEB_SERVER



echo ""
echo ""
echo INSTALL_HOME=$INSTALL_HOME
echo TARGET=$TARGET
echo SERVER=$SERVER
echo ""
 

echo "Check if we already have installed the server..."

if [ -d  "$SERVER" ]; then
	echo "Web server is already installed, overwrite?."
	read -p "Continue (y/n)? " choice

	case "$choice" in
		n|N ) exit 1;
	esac 
	rm -rf $SERVER
fi


# ---------- Installing Web Server ----------
echo "installing web server ..."

cd $TARGET
mkdir $WEB_SERVER
chmod 777 $WEB_SERVER
cd $WEB_SERVER
mkdir lib
cp $TARGET/configure-server/webserver.jar .
cp $TARGET/configure-server/server.properties .
cp $TARGET/configure-server/start-server.sh .
cp $ORACLE_SPATIAL/property_graph/lib/tomcat-embed-* ./lib

# check the  two possible paths
if ls  /usr/share/cmf/common_jars/jasper-compiler* 1> /dev/null 2>&1; then
    cp /usr/share/cmf/common_jars/jasper-compiler* ./lib
else
    cp /usr/lib/hadoop/lib/jasper-compiler* ./lib
fi

cp /usr/share/cmf/common_jars/ecj-4* ./lib
cp $TARGET/configure-server/lib/javax.el-3.0.0.jar $TARGET/configure-server/lib/jstl-1.2.jar ./lib



# ------ imageserver --------
echo ""
echo ""
echo "installing imageserver for rasters ..."
echo ""
unzip $TARGET/raster/console/imageserver.war -d $SERVER/imageserver
cd $SERVER/imageserver/WEB-INF/lib
cp $TARGET/raster/jlib/asm-3.1.jar .

#copy hadoop dependencies
if ls /usr/lib/hadoop/client/*.jar 1> /dev/null 2>&1; then
    cp /usr/lib/hadoop/client/*.jar .
else
    cp /opt/cloudera/parcels/CDH/lib/hadoop/client/*.jar .
fi

ls  jersey-core* | grep -v jersey-core-1.17.1.jar | xargs rm
#rm jersey-core-1.9.jar jersey-core.jar
rm servlet*
rm xercesImpl*
cp $ORACLE_SPATIAL/property_graph/lib/jackson-core-asl-1* .
cp $ORACLE_SPATIAL/property_graph/lib/jackson-mapper-asl-1* .
cp $INSTALL_HOME/conf.xml $SERVER/imageserver/WEB-INF/

# ------- Spatialviewer ---------
echo .
echo .
echo "installing spatialviewer for vectors..."
echo .
unzip $TARGET/vector/console/spatialviewer.war -d $SERVER/spatialviewer
cd $SERVER/spatialviewer/WEB-INF/lib/ 
#copy hadoop dependencies
if ls /usr/lib/hadoop/client/*.jar 1> /dev/null 2>&1; then
    cp /usr/lib/hadoop/client/*.jar .
else
    cp /opt/cloudera/parcels/CDH/lib/hadoop/client/*.jar .
fi

rm servlet*
rm xercesImpl*
cp $ORACLE_SPATIAL/property_graph/lib/jackson-core-asl-1* .
cp $ORACLE_SPATIAL/property_graph/lib/jackson-mapper-asl-1* .
cp $INSTALL_HOME/console-conf.xml $SERVER/spatialviewer/conf/


#-- set the right configuration to the actual cluster
fs=`hdfs getconf -confKey fs.defaultFS`
rmsa=`hdfs getconf -confKey yarn.resourcemanager.scheduler.address`
rma=`hdfs getconf -confKey yarn.resourcemanager.address`

echo $fs
echo $rmsa
echo $rma 

#cd $SERVER/spatialviewer/conf
#sed -i -e "s,"'${hdfs://default.file.system:8020}'",$fs,g" console-conf.xml
#sed -i -e "s/"'${yarn.resourcemanager.hostname:8030}'"/$rmsa/g" console-conf.xml
#sed -i -e "s/"'${yarn.resourcemanager.hostname:8032}'"/$rma/g" console-conf.xml

#cd $SERVER/imageserver/WEB-INF
#sed -i -e "s,"'${hdfs://default.file.system:8020}'",$fs,g" conf.xml
#sed -i -e "s/"'${yarn.resourcemanager.hostname:8030}'"/$rmsa/g" conf.xml
#sed -i -e "s/"'${yarn.resourcemanager.hostname:8032}'"/$rma/g" conf.xml



echo ""
echo "#######################################################"
echo ""
echo "To start the application: "
echo "  cd $SERVER"
echo "  ./start-server.sh"
echo ""
echo "Then, use the Big Data Spatial and Graph bookmarks in Firefox to use the tools."
echo ""
echo "######################################################"

#copy tweets
#hadoop fs -mkdir /user/oracle/bdsg
#hadoop fs -put $TARGET/vector/examples/data/tweets.json /user/oracle/bdsg/

