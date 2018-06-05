# Install basic Oracle R packages for ORAAH

unzip oraah-install-linux-x86_64-2.7.0.zip

#cp libOrdBlasLoader.so /usr/lib64/R/lib

echo Installing additional packages

Rscript --verbose install_base_ORAAH.R

cp /home/analyticsdb/projects/r-studio/jpac-sparklyr/ORAAH/ORAAH-2.7.0-install/mkl/* /usr/lib64/R/lib
cp /home/analyticsdb/projects/r-studio/jpac-sparklyr/ORAAH/ORAAH-2.7.0-install/lib/* /usr/lib64/R/lib
