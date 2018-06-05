# Install sparkling sparklyr H2O
# List of packages
pkgs <-c("Lahman",
          "sparklyr",
          "nycflights13",
          "rsparkling")

install.packages(pkgs, dependencies=TRUE,
                 repos="http://cran.fhcrc.org",
                 lib="/u01/app/oracle/product/12.1.0.2/dbhome_1/R/library",
                 type="source")

detach("package:rsparkling", unload = TRUE)
if ("package:h2o" %in% search()) { detach("package:h2o", unload = TRUE) }
if (isNamespaceLoaded("h2o")){ unloadNamespace("h2o") }
remove.packages("h2o")

#install.packages("/home/oracle/Downloads/h2o-3.10.4.8/R/h2o_3.10.4.8.tar.gz",repos = NULL, type = "source")
install.packages("h2o",
                 repos = "http://h2o-release.s3.amazonaws.com/h2o/rel-ueno/8/R",
                 lib="/u01/app/oracle/product/12.1.0.2/dbhome_1/R/library",
                 type="source")

