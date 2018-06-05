# Install additional open-source R packages for HOL exercises
# Main packages are arules, arulesViz and forecast plus their dependencies


echo remove R library locks
rm -rf /usr/lib64/R/library/00LOCK-*

echo Installing additional packages

Rscript --verbose /home/analyticsdb/projects/r-studio/jpac-sparklyr/rstudio_sparklyr/install_sparklyr_2.1.R
