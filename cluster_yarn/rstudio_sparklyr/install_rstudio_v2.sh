# export https_proxy=www-proxy.us.oracle.com:80
#cd /home/oracle/scripts

echo Update R Oracle Repo
cd /etc/yum.repos.d
wget http://public-yum.oracle.com/public-yum-ol6.repo

cd /home/analyticsdb/projects/r-studio/jpac-sparklyr/rstudio_sparklyr

echo Install R
yum remove -y R-3.2.0
#sudo -i yum install R-3.3.0
yum install -y R.x86_64

echo Retrieving RStudio
#wget https://download2.rstudio.org/rstudio-server-rhel-1.0.136-x86_64.rpm

echo Installing RStudio
yum install -y --nogpgcheck /home/analyticsdb/projects/r-studio/jpac-sparklyr/rstudio_sparklyr/rstudio-server-rhel-1.0.136-x86_64.rpm

echo Copying configuration files
cp /home/analyticsdb/projects/r-studio/jpac-sparklyr/rstudio_sparklyr/.Renviron /home/analyticsdb
chown analyticsdb:analyticsdb -R /home/analyticsdb

cp rserver.conf /etc/rstudio/
cp SessionHelp.R /usr/lib/rstudio-server/R/modules/SessionHelp.R 
chmod 644 /usr/lib/rstudio-server/R/modules/SessionHelp.R

R CMD javareconf
echo 'JAVA_HOME=/usr/java/default' >> /usr/lib64/R/etc/Renviron
#sudo sh -c "echo 'SPARK_HOME=/opt/cloudera/parcels/CDH/lib/spark/' >> /usr/lib64/R/etc/Renviron"
echo 'SPARK_HOME=/opt/cloudera/parcels/SPARK2/lib/spark2/' >> /usr/lib64/R/etc/Renviron

echo wget  nlopt-2.4.2.tar.gz
#wget http://ab-initio.mit.edu/nlopt/nlopt-2.4.2.tar.gz
#tar -xvf nlopt-2.4.2.tar.gz
cd nlopt-2.4.2
./configure && make && sudo make install
cd ..
cp Rlibrary.tar /home/analyticsdb
cd /home/analyticsdb
mkdir -p R/library
cd R/library/
tar -xvf ../../Rlibrary.tar
mkdir /home/analyticsdb/R/library
rsync -r /home/analyticsdb/R/library/u01/app/oracle/product/12.1.0.2/dbhome_1/R/library/ /usr/lib64/R/library
chown analyticsdb:analyticsdb -R /usr/lib64/R

chown analyticsdb:analyticsdb -R /usr/lib/rstudio-server

echo Restarting RStudio
/usr/lib/rstudio-server/bin/rstudio-server stop
/usr/lib/rstudio-server/bin/rstudio-server start

#echo Install Spark2.1 for R-Studio
#mkdir ~/spark
#cp ./setup-spark2.1.sh ~/spark
#cp ./make_condar_env.sh ~/spark
#cd ~/spark
#bash -x setup-spark2.1.sh

echo done !
