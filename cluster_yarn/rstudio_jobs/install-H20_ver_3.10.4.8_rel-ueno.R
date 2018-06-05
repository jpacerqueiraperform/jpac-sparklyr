
detach("package:rsparkling", unload = TRUE)
if ("package:h2o" %in% search()) { detach("package:h2o", unload = TRUE) }
if (isNamespaceLoaded("h2o")){ unloadNamespace("h2o") }
remove.packages("h2o", lib="/usr/lib64/R/lib" )
install.packages("h2o", type = "source", lib="/usr/lib64/R/lib" ,  repos = "https://h2o-release.s3.amazonaws.com/h2o/rel-rel-ueno/8/R")
