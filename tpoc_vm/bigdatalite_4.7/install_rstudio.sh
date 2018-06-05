# export https_proxy=www-proxy.us.oracle.com:80
cd /home/oracle/scripts

echo Retrieving RStudio
wget https://download2.rstudio.org/rstudio-server-rhel-1.0.136-x86_64.rpm

echo Installing RStudio
sudo yum install -y --nogpgcheck rstudio-server-rhel-1.0.136-x86_64.rpm

#echo Copying configuration files
# cp ./.Renviron /home/oracle
sudo cp rserver.conf /etc/rstudio/
sudo cp SessionHelp.R /usr/lib/rstudio-server/R/modules/SessionHelp.R 
sudo chmod 644 /usr/lib/rstudio-server/R/modules/SessionHelp.R

echo Restarting RStudio
sudo /usr/lib/rstudio-server/bin/rstudio-server stop
sudo /usr/lib/rstudio-server/bin/rstudio-server start
