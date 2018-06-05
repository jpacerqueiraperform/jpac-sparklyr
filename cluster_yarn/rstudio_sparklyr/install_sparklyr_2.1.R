# Install sparkling sparklyr H2O

# List of packages
pkgs <-c("DBI",
          "dplyr",
          "sparklyr"
          ,"nycflights13",
          "rsparkling",
          "h2o")

install.packages(pkgs,dependencies=TRUE,
                 repos="http://cran.fhcrc.org",
                 lib="/usr/lib64/R/library",
                 type="source")


# Now we download, install, and initialize the H2O package for R. 
if ("package:rsparkling" %in% search()) { detach("package:rsparkling",  unload = TRUE) }
if ("package:h2o" %in% search()) { detach("package:h2o",  unload = TRUE) }
if (isNamespaceLoaded("h2o")){ unloadNamespace("h2o") }
remove.packages("h2o", lib="/usr/lib64/R/library")
install.packages("h2o", dependencies=TRUE , type = "source", lib="/usr/lib64/R/library" , repos = "https://h2o-release.s3.amazonaws.com/h2o/rel-wolpert/8/R")

install.packages("rsparkling",dependencies=TRUE,repos="http://cran.fhcrc.org",lib="/usr/lib64/R/library",type="source")
