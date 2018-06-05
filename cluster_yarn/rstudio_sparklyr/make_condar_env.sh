# Install additional open-source R packages in a new distributed zip for sparklyr
rm -rf ~/spark/spark-2.1.0-bin-hadoop2.7/r_env
rm -rf  ~/spark/spark-2.1.0-bin-hadoop2.7/r_env.zip
mkdir -p ~/spark/spark-2.1.0-bin-hadoop2.7/r_env
/opt/cloudera/parcels/Anaconda-4.2.0/bin/python2.7 /opt/cloudera/parcels/Anaconda-4.2.0/bin/conda create -p ~/spark/spark-2.1.0-bin-hadoop2.7/r_env --copy -y -q r-essentials -c r
# [Option] If you need additional package you can install as follows:
# $ source activate r_env
# $ Rscript -e 'install.packages(c("awesome-package"), lib = /home/cdsw/r_env/lib/R/library, dependencies = TRUE, repos="https://cran.r-project.org")'
# $ source deactivate
sed -i "s,/home/analyticsdb/spark/spark-2.1.0-bin-hadoop2.7,./r_env.zip,g" ~/spark/spark-2.1.0-bin-hadoop2.7/r_env/bin/R 
zip -r ~/spark/spark-2.1.0-bin-hadoop2.7/r_env.zip ~/spark/spark-2.1.0-bin-hadoop2.7/r_env
