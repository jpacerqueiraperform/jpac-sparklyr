# export https_proxy=www-proxy.us.oracle.com:80
#cd /home/oracle/scripts

echo Update R Oracle Repo
sudo -i cd /etc/yum.repos.d
sudo -i wget http://public-yum.oracle.com/public-yum-ol6.repo

sudo -i cd /home/analyticsdb/projects/r-studio/jpac-sparklyr/rstudio_sparklyr

echo Install R

#sudo -i yum remove R-3.2.0
#sudo yum install R.x86_64

sudo -i yum remove R.x86_64
sudo -i yum install R.x86_64

echo Retrieving RStudio
#wget https://download2.rstudio.org/rstudio-server-rhel-1.0.136-x86_64.rpm

echo Installing RStudio
sudo -i yum remove -y --nogpgcheck /home/analyticsdb/projects/r-studio/jpac-sparklyr/rstudio_sparklyr/rstudio-server-rhel-1.0.136-x86_64.rpm
sudo -i yum install -y --nogpgcheck /home/analyticsdb/projects/r-studio/jpac-sparklyr/rstudio_sparklyr/rstudio-server-rhel-1.0.136-x86_64.rpm

echo Copying configuration files
sudo -i cp /home/analyticsdb/projects/r-studio/jpac-sparklyr/rstudio_sparklyr/.Renviron /home/analyticsdb
sudo -i chown analyticsdb:analyticsdb -R /home/analyticsdb

sudo -i cp rserver.conf /etc/rstudio/
sudo -i cp SessionHelp.R /usr/lib/rstudio-server/R/modules/SessionHelp.R 
sudo -i chmod 644 /usr/lib/rstudio-server/R/modules/SessionHelp.R

sudo -i R CMD javareconf
sudo sh -c "echo 'JAVA_HOME=/usr/java/default' >> /usr/lib64/R/etc/Renviron"
#sudo sh -c "echo 'SPARK_HOME=/opt/cloudera/parcels/CDH/lib/spark/' >> /usr/lib64/R/etc/Renviron"
sudo sh -c "echo 'SPARK_HOME=/opt/cloudera/parcels/SPARK2/lib/spark2/' >> /usr/lib64/R/etc/Renviron"

echo wget  nlopt-2.4.2.tar.gz 
#wget http://ab-initio.mit.edu/nlopt/nlopt-2.4.2.tar.gz
#tar -xvf nlopt-2.4.2.tar.gz
cd nlopt-2.4.2
./configure && make && sudo make install
cd ..
#cp R-ol6.8-spec.tar ~
#mkdir -p R
#cd R
#tar -xvf R-ol6.8-spec.tar
#sudo -i rsync -r /home/analyticsdb/R/usr/lib64/R/ /usr/lib64/R
#cp Rlibrary.tar ~
#cd ~
#mkdir -p R/library
#cd R/library/
#tar -xvf ../../Rlibrary.tar
#sudo -i rsync -r /home/analyticsdb/R/library/u01/app/oracle/product/12.1.0.2/dbhome_1/R/library/ /usr/lib64/R/library
#sudo -i chown analyticsdb:analyticsdb -R /usr/lib64/R

sudo -i chown analyticsdb:analyticsdb -R /usr/lib/rstudio-server

echo Restarting RStudio
sudo -i /usr/lib/rstudio-server/bin/rstudio-server stop
sudo -i /usr/lib/rstudio-server/bin/rstudio-server start

#echo Install Spark2.1 for R-Studio
#mkdir ~/spark
#cp ./setup-spark2.1.sh ~/spark
#cp ./make_condar_env.sh ~/spark
#bash -x ~/spark/setup-spark2.1.sh
#mkdir -p ~/spark/sparklingwater/
#cp ./download-install-run-sparklingwater.sh ~/spark/sparklingwater/
# bash -x ~/spark/sparklingwater/download-install-run-sparklingwater.sh

echo done !
