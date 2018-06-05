
## Hive UDF POJO Example

## Example - R-Studio SparklyR H20.ai  - Opta Gateway 

1. Generated Model from R-Studio s§ession in Spark and H20 Context for YARN in the bda cluster 
2. Model generation of R session https://stash.performgroup.com/projects/BDA/repos/bda_exadata_samples/browse/SAMPLE_IXPBDAOPTA01_TOOLS/jpac-sparklyr/rstudio_jobs/hive_udf_pojo_template/GBM_DeepLearning_Plotting_POJO_Export.R
3. Tutorial explained online https://github.com/h2oai/h2o-tutorials/blob/master/tutorials/hive_udf_template/hive_udf_pojo_template/pom.xml



## Hive UDF POJO Example - Tutorial Explained

This tutorial describes how to use a model created in H2O to create a Hive UDF (user-defined function) for scoring data.   While the fastest scoring typically results from ingesting data files in HDFS directly into H2O for scoring, there may be several motivations not to do so.  For example, the clusters used for model building may be research clusters, and the data to be scored may be on "production" clusters.  In other cases, the final data set to be scored may be too large to reasonably score in-memory.  To help with these kinds of cases, this document walks through how to take a scoring model from H2O, plug it into a template UDF project, and use it to score in Hive.  All the code needed for this walkthrough can be found in this repository branch.

## The Goal
The desired work flow for this task is:

1. Load training and test data into H2O
2. Create several models in H2O
3. Export the best model as a [POJO](https://en.wikipedia.org/wiki/Plain_Old_Java_Object)
4. Compile the H2O model as a part of the UDF project
5. Copy the UDF to the cluster and load into Hive
6. Score with your UDF

For steps 1-3, we will give instructions scoring the data through R.  We will add a step between 4 and 5 to load some test data for this example.

## Requirements

This tutorial assumes the following:

1. Some familiarity with using H2O in R.  Getting started tutorials can be found [here](http://docs.0xdata.com/newuser/top.html).
2. The ability to compile Java code.  The repository provides a pom.xml file, so using Maven will be the simplest way to compile, but IntelliJ IDEA will also read in this file.  If another build system is preferred, it is left to the reader to figure out the compilation details.
3. A working Hive install to test the results.

## The Data

For this post, we will be using the H2O prostate cancer evaluation dataset prostate.csv

The goal of the analysis in this demo is to predict if the VOL of your prostate increases according to the evolution of your proteins in the blog level and your age and race conditions .  The columns we will be using are:

* AGE:  age


## Building the Model in R
No need to cut and paste code: the complete R script described below is part of this git repository (GBM-example.R).
### Load the training and test data into H2O
Since we are playing with a small data set for this example, we will start H2O locally and load the datasets:

## Building the Model in R
No need to cut and paste code: the complete R script described below is part of this git repository (GBM-example.R).
### Load the training and test data into H2O
Since we are playing with a small data set for this example, we will start H2O locally and load the datasets:

```r
#
# DeepLearning
library(dplyr)
library(sparklyr)
library(h2o)
options(rsparkling.sparklingwater.version = "2.1.27",rsparkling.sparklingwater.location = "/home/analyticsdb/spark/sparklingwater/sparkling-water-2.1.27/assembly/build/libs/sparkling-water-assembly_2.11-2.1.27-all.jar")
library(rsparkling)

ip <- as.data.frame(installed.packages()[,c(1,3:4)])
ip <- ip[is.na(ip$Priority),1:2,drop=FALSE]
print(ip, row.names=FALSE)
rownames(ip) <- NULL


h2o.shutdown()

# h2o port is redirected from 54321 to 54323 for spark mode=local
#
h2o.init(ip = "localhost", port = 54321, startH2O = TRUE,
         forceDL = FALSE, enable_assertions = TRUE, license = NULL,
         nthreads = 4, max_mem_size = NULL, min_mem_size = NULL,
         ice_root = tempdir(), strict_version_check = TRUE,
         proxy = NA_character_, https = FALSE, insecure = FALSE,
         username = NA_character_ , password = NA_character_ ,
         cookies = NA_character_, context_path = NA_character_ )

h2o.clusterInfo()
spark_home_dir()

# restart r session
#sessionInfo()
#options(rsparkling.sparklingwater.version = "1.6.2")
#spark_install(version = "1.6.2")
#spark_home_set(path="/home/analyticsdb/spark/spark-1.6.2-bin-hadoop2.6")
#sc <- spark_connect(master = "local", version = "1.6.2", config = list(sparklyr.log.console = TRUE))

# FIX FROM GITGUB : https://github.com/rstudio/sparklyr/issues/801
# FIX PROXY SERVER for SPARK2
#sessionInfo()
#devtools::install_github("rstudio/sparklyr")

# restart r session
sessionInfo()
# Match rsparkling with spark2.1 and H2O verison from https://github.com/h2oai/rsparkling/blob/master/README.md 
# Download from : http://h2o-release.s3.amazonaws.com/sparkling-water/rel-2.1/27/index.html 
# Wait for 15 minutes, might require even more.
# Load parameters from condaR zip

#spark_home_set(path="/home/analyticsdb/spark/spark-2.1.0-bin-hadoop2.7")

config <- spark_config()
spark_home <- "/home/analyticsdb/spark/spark-2.1.0-bin-hadoop2.7"
spark_version <- "2.1.0"
config$spark.driver.cores   <- 4
config$spark.executor.cores <- 1
config$spark.executor.memory <- "1G"
config[["spark.r.command"]] <- "/home/analyticsdb/spark/spark-2.1.0-bin-hadoop2.7/r_env.zip/r_env/bin/Rscript"
config[["spark.yarn.dist.archives"]] <- "/home/analyticsdb/spark/spark-2.1.0-bin-hadoop2.7/r_env.zip"
config$sparklyr.apply.env.R_HOME <- "./home/analyticsdb/spark/spark-2.1.0-bin-hadoop2.7/r_env.zip/r_env/lib/R"
config$sparklyr.apply.env.RHOME <- "./home/analyticsdb/spark/spark-2.1.0-bin-hadoop2.7/r_env.zip/r_env"
config$sparklyr.apply.env.R_SHARE_DIR <- "./home/analyticsdb/spark/spark-2.1.0-bin-hadoop2.7/r_env.zip/r_env/lib/R/share"
config$sparklyr.apply.env.R_INCLUDE_DIR <- "./home/analyticsdb/spark/spark-2.1.0-bin-hadoop2.7/r_env.zip/r_env/lib/R/include"
config$sparklyr.apply.env.LD_LIBRARY_PATH <- "/opt/cloudera/parcels/Anaconda/lib"
config$sparklyr.apply.env.PYTHONPATH <- "./home/analyticsdb/spark/spark-2.1.0-bin-hadoop2.7/r_env.zip/r_env/lib/python2.7/site/packages"
# Force Driver and host from gateway
config$spark.jars <- "file:/data/analyticsdb/spark/sparklingwater/sparkling-water-2.1.27/assembly/build/libs/sparkling-water-assembly_2.11-2.1.27-all.jar,file:/usr/lib64/R/library/sparklyr/java/sparklyr-2.1-2.11.jar"
config$spark.driver.host <- "10.12.61.19"
# ISSUE https://github.com/h2oai/sparkling-water/issues/32
config$spark.ext.h2o.topology.change.listener.enabled <- FALSE
config$sparklyr.gateway.start.timeout <- 900
### Enable visualization of detailed logs
#config$sparklyr.log.console <- TRUE
config$sparklyr.log.console <- FALSE

system.time(sc <- spark_connect(master = "yarn-client", app_name = "jpac-sparklyr", version = spark_version, config = config, spark_home=spark_home))
#system.time(sc <- spark_connect(master = "local", app_name = "jpac-sparklyr", version = spark_version , config = config, spark_home=spark_home))

spark_context(sc)
spark_context_config(sc)
h2o_context(sc)

#system.time( sc <- spark_connect(master = "local", version = "2.1.0")) 
mypath <- system.file("extdata", "prostate.csv", package = "h2o")
print(mypath)


### Not funtional in dplyr context :: DBI conflict ::  depends on DBI 0.3.1 for ORCH, but dplyr depends on DBI 1.0.0
### Manual copy of File 
### hdfs.ls("/user/analyticsdb")

prostate_df <- spark_read_csv(sc, "prostate","hdfs://bda-ns/user/analyticsdb/prostate.csv")
#prostate_df <- spark_read_csv(sc, "prostate","file:/usr/lib64/R/library/h2o/extdata/prostate.csv")

prostate_file <- read.csv("/usr/lib64/R/library/h2o/extdata/prostate.csv")


actual_prostate_df <- prostate_file %>%
  select(VOL) %>%
  collect() %>%
  `[[`("VOL")


head(prostate_df)
prostate_tbl <- copy_to(sc, prostate_df, "prostate_tbl", overwrite = TRUE)

prostate_tbl
head(prostate_tbl)

#Convert to an H2O Frame:
#prostate_hf <- as_h2o_frame(sc, prostate_tbl, strict_version_check = FALSE)
prostate_hf <- as.h2o(prostate_tbl)
splits <- h2o.splitFrame(prostate_hf, seed = 1099)

y <- "VOL"
#remove response and ID cols
x <- setdiff(names(prostate_hf), c("ID", y))

# Print Header of the Variables
x
```

### Creating several models in H2O
Now that the data has been prepared, let's build a set of models using [GBM](http://h2o-release.s3.amazonaws.com/h2o/rel-wolpert/8/docs-website/h2o-docs/index.html#Data%20Science%20Algorithms-GBM).  Here we will select the columns used as predictors and results, specify the validation data set, and then build a model.

```r
# ... with more rows
> head(prostate_tbl)
# Source:   lazy query [?? x 9]
# Database: spark_connection
     ID CAPSULE   AGE  RACE DPROS DCAPS   PSA   VOL GLEASON
  <int>   <int> <int> <int> <int> <int> <dbl> <dbl>   <int>
1     1       0    65     1     2     1  1.40   0.        6
2     2       0    72     1     3     2  6.70   0.        7
3     3       0    70     1     1     2  4.90   0.        6
4     4       0    76     2     2     1 51.2   20.0       7
5     5       0    69     1     1     1 12.3   55.9       6
6     6       1    71     1     3     2  3.30   0.        8
> prostate_hf <- as.h2o(prostate_tbl)
  |=======================================================================================================================| 100%
> splits <- h2o.splitFrame(prostate_hf, seed = 1099)
> y <- "VOL"
> x <- setdiff(names(prostate_hf), c("ID", y))
> x
[1] "CAPSULE" "AGE"     "RACE"    "DPROS"   "DCAPS"   "PSA"     "GLEASON"
> gbm_params1 <- list(learn_rate = c(0.01, 0.1),
+                     max_depth = c(3, 5, 9),
+                     sample_rate = c(0.8, 1.0),
+                     col_sample_rate = c(0.1, 0.5, 1.0))
> gbm_params1 <- list(learn_rate = c(0.01, 0.1),
+                     max_depth = c(3, 5, 9),
+                     sample_rate = c(0.8, 1.0),
+                     col_sample_rate = c(0.1, 0.5, 1.0))
> gbm_grid1 <- h2o.grid("gbm", x = x, y = y,
+                       grid_id = "gbm_grid1",
+                       training_frame = splits[[1]],
+                       validation_frame = splits[[1]],
+                       ntrees = 1000,
+                       seed = 1099,
+                       hyper_params = gbm_params1)
  |=======================================================================================================================| 100%
> gbm_gridperf1 <- h2o.getGrid(grid_id = "gbm_grid1", 
+                              sort_by = "mse", 
+                              decreasing = FALSE)
> print(gbm_gridperf1)
H2O Grid Details
================

Grid ID: gbm_grid1 
Used hyper parameters: 
  -  col_sample_rate 
  -  learn_rate 
  -  max_depth 
  -  sample_rate 
Number of models: 36 
Number of failed models: 0 

Hyper-Parameter Search Summary: ordered by increasing mse
  col_sample_rate learn_rate max_depth sample_rate          model_ids                mse
1             1.0        0.1         9         0.8 gbm_grid1_model_17  1.943019508483271
2             1.0        0.1         9         1.0 gbm_grid1_model_35  2.172765918697373
3             0.5        0.1         9         1.0 gbm_grid1_model_34 2.6525016645550252
4             0.5        0.1         9         0.8 gbm_grid1_model_16  5.171678224652261
5             1.0        0.1         5         0.8 gbm_grid1_model_11 10.259135979366368

---
   col_sample_rate learn_rate max_depth sample_rate          model_ids                mse
31             1.0       0.01         3         0.8  gbm_grid1_model_2  218.2248165576019
32             0.5       0.01         3         1.0 gbm_grid1_model_19 221.79011562366597
33             0.1       0.01         5         0.8  gbm_grid1_model_6 224.80079620350907
34             0.5       0.01         3         0.8  gbm_grid1_model_1   229.534191142793
35             0.1       0.01         3         1.0 gbm_grid1_model_18 251.33849199636327
36             0.1       0.01         3         0.8  gbm_grid1_model_0 256.78788585021573
> gbm_gridperf1@model_ids[[1]]
[1] "gbm_grid1_model_17"
> gbm_model_gridperf1 <- h2o.getModel(gbm_gridperf1@model_ids[[1]])
> 
```

### Model Can be used for scoring (h2o.predict function) and plot helps compare real values with predictions

```r
>
> gbm_gridperf1@model_ids[[1]]
[1] "gbm_grid1_model_17"
> gbm_model_gridperf1 <- h2o.getModel(gbm_gridperf1@model_ids[[1]])
> pred_model_gridperf1 <- h2o.predict(gbm_model_gridperf1, newdata = prostate_hf)
  |=======================================================================================================================| 100%
> head(pred_model_gridperf1)
     predict
1 -3.3140997
2  0.7430509
3  1.6688235
4 20.3889120
5 55.5612492
6 -0.6271192
>
> head(prostate_hf)
  ID CAPSULE AGE RACE DPROS DCAPS  PSA  VOL GLEASON
1  1       0  65    1     2     1  1.4  0.0       6
2  2       0  72    1     3     2  6.7  0.0       7
3  3       0  70    1     1     2  4.9  0.0       6
4  4       0  76    2     2     1 51.2 20.0       7
5  5       0  69    1     1     1 12.3 55.9       6
6  6       1  71    1     3     2  3.3  0.0       8
> predicted_model_gridperf1 <- as.data.frame(pred_model_gridperf1)
>
> predicted_model_gridperf1 <- as.data.frame(pred_model_gridperf1)
> prostate_file <- read.csv("/usr/lib64/R/library/h2o/extdata/prostate.csv")
> actual_prostate_df <- prostate_file %>%
+   select(VOL) %>%
+   collect() %>%
+   `[[`("VOL")
> data <- data.frame(
+     predicted = predicted_model_gridperf1,
+     actual    = actual_prostate_df)
> names(data) <- c("predicted", "actual")
> ggplot(data, aes(x = actual, y = predicted)) +
+   geom_abline(lty = "dashed", col = "red") +
+   geom_point() +
+   theme(plot.title = element_text(hjust = 0.8)) +
+   coord_fixed(ratio = 3.5) +
+   labs(
+     x = "Actual Prostate VOL",
+     y = "Predicted PROSTATE VOL",
+     title = "CGRID-GBM-MSE_1 Predicted vs. Actual Prostate VOL" )
>
```

### Export the best model as a POJO
From here, we can download this model as a Java [POJO](https://en.wikipedia.org/wiki/Plain_Old_Java_Object) to a local directory called `generated_model`.

```r
>
> tmpdir_model <- "h2omodels-v3-udf-pojo"
> dir.create(tmpdir_model)
> h2o.centroid_stats(gbm_model_gridperf1)
NULL
> h2o.saveModel(gbm_model_gridperf1, path = tmpdir_model)
[1] "/data/analyticsdb/h2omodels-v3-udf-pojo/gbm_grid1_model_17"
> h2o.download_pojo(gbm_model_gridperf1, path = tmpdir_model)
[1] "gbm_grid1_model_17.java"
> h2o.download_mojo(gbm_model_gridperf1, path = tmpdir_model)
[1] "gbm_grid1_model_17.zip"
> spark_disconnect(sc)
> 
```

## Compile the H2O model as a part of UDF project

All code for this section can be found in this git repository.  To simplify the build process, I have included a pom.xml file.  For Maven users, this will automatically grab the dependencies you need to compile.

To use the template:

1. Copy the Java from H2O into the project
2. Update the POJO to be part of the UDF package
3. Update the pom.xml to reflect your version of Hadoop and Hive
4. Compile

### Copy the java from H2O into the project

```bash
$ #!/usr/bin/env bash
$ scp analyticsdb@ixpbdaopta01.prod.ix.perform.local:~/h2omodels-v3-udf-pojo/h2o-genmodel.jar .
$ scp analyticsdb@ixpbdaopta01.prod.ix.perform.local:~/h2omodels-v3-udf-pojo/gbm_grid1_model_17.java .
$ mv  gbm_grid1_model_17.java GBMModel17.java
$ sed -i "s,gbm_grid1_model_17,GBMModel17,g" GBMModel17.java
$ # sed -i -e "1i\package ai.h2o.hive.udf;" GBMModel17.java
$ cp h2omodels-v3-udf-pojo/GBMModel17.java ../src/main/java/ai/h2o/hive/udf/GBMModel.java
```

### Update the POJO to Be a Part of the Same Package as the UDF ###

To the top of `GBMModel17.java`, add:

```Java
package ai.h2o.hive.udf;
```

### Update the pom.xml to Reflect Hadoop and Hive Versions ###

Get your version numbers using:

```bash
$ hadoop version
$ hive --version
```

And plug these into the `<properties>`  section of the `pom.xml` file.  Currently, the configuration is set for pulling the necessary dependencies for Hortonworks.  For other Hadoop distributions, you will also need to update the `<repositories>` section to reflect the respective repositories (a commented-out link to a Cloudera repository is included).

### Compile

> Caution:  This tutorial was written using Maven 3.0.4.  Older 2.x versions of Maven may not work.

```bash
$ mvn compile
$ mvn package
$ mvn -X clean install -Dmaven.test.skip=true
```

As with most Maven builds, the first run will probably seem like it is downloading the entire Internet.  It is just grabbing the needed compile dependencies.  In the end, this process should create the file `target/ScoreData-1.0-SNAPSHOT.jar`.

As a part of the build process, Maven is running a unit test on the code. If you are looking to use this template for your own models, you either need to modify the test to reflect your own data, or run Maven without the test (`mvn package -Dmaven.test.skip=true`).  

## Loading test data in Hive
Now load the same test data set into Hive.  This will allow us to score the data in Hive and verify that the results are the same as what we saw in H2O.

```bash
$ hadoop fs -mkdir -p  hdfs:///user/analyticsdb/H2O/PROSTATEData
$ hdfs dfs -copyFromLocal prostate.csv hdfs:///user/analyticsdb/H2O/PROSTATEData
$ hive
```

Here we mark the table as `EXTERNAL` so that Hive doesn't make a copy of the file needlessly.  We also tell Hive to ignore the first line, since it contains the column names.

```hive
> CREATE EXTERNAL TABLE prostate ( ID INT, CAPSULE INT, AGE INT, RACE INT, DPROS INT, DCAPS INT, PSA FLOAT, VOL FLOAT, GLEASON INT) COMMENT 'H2O.ai sample prostate table' ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE location '/user/analyticsdb/H2O/PROSTATEData' tblproperties ("skip.header.line.count"="1");
> ANALYZE TABLE prostate COMPUTE STATISTICS;
```


## Copy the UDF to the cluster and load into Hive
```bash
$ hadoop fs -mkdir -p  hdfs:///user/analyticsdb/H2O/UDFtest
$ hdfs dfs -copyFromLocal localjars/h2o-genmodel.jar                hdfs:///user/analyticsdb/H2O/UDFtest
$ hdfs dfs -copyFromLocal target/ScoreDataUDFGBM17-1.0-SNAPSHOT.jar hdfs:///user/analyticsdb/H2O/UDFtest
$ hive
```
Note that for correct class loading, you will need to load the h2o-model.jar before the ScoredData jar file.

```hive
> ADD JAR hdfs:///user/analyticsdb/H2O/UDFtest/GBM17lib/h2o-genmodel.jar;
> ADD JAR hdfs:///user/analyticsdb/H2O/UDFtest/GBM17lib/ScoreDataUDFGBM17-1.0-SNAPSHOT.jar;
> CREATE TEMPORARY FUNCTION scoredata AS 'ai.h2o.hive.udf.ScoreDataUDFGBM17';
> USE DEFAULT;
> SHOW TABLES;
> SELECT ID,CAPSULE,AGE,RACE,DPROS,DCAPS,PSA,GLEASON,VOL, scoredata(CAPSULE,AGE,RACE,DPROS,DCAPS,PSA,GLEASON) as PRED_VOL FROM prostate LIMIT 380;
```

Keep in mind that your UDF is only loaded in Hive for as long as you are using it.  If you `quit;` and then join Hive again, you will have to re-enter the last three lines.

## Score with your UDF
Now the moment we've been working towards:

```r
(IX Prod)[analyticsdb@ixpbdaopta01 ~]$ hive
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=512M; support was removed in 8.0
2018-05-31 15:43:18,733 WARN  [main] mapreduce.TableMapReduceUtil: The hbase-prefix-tree module jar containing PrefixTreeCodec is not present.  Continuing without it.
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=512M; support was removed in 8.0

Logging initialized using configuration in jar:file:/data/cloudera/parcels/CDH-5.9.0-1.cdh5.9.0.p0.21/jars/hive-common-1.1.0-cdh5.9.0.jar!/hive-log4j.properties
WARNING: Hive CLI is deprecated and migration to Beeline is recommended.
hive> ADD JAR hdfs:///user/analyticsdb/H2O/UDFtest/GBM17lib/h2o-genmodel.jar;
converting to local hdfs:///user/analyticsdb/H2O/UDFtest/GBM17lib/h2o-genmodel.jar
Added [/tmp/18707a5b-25c4-4e22-a64e-27b9d7b0fb11_resources/h2o-genmodel.jar] to class path
Added resources: [hdfs:///user/analyticsdb/H2O/UDFtest/GBM17lib/h2o-genmodel.jar]
hive> ADD JAR hdfs:///user/analyticsdb/H2O/UDFtest/GBM17lib/ScoreDataUDFGBM17-1.0-SNAPSHOT.jar;
converting to local hdfs:///user/analyticsdb/H2O/UDFtest/GBM17lib/ScoreDataUDFGBM17-1.0-SNAPSHOT.jar
Added [/tmp/18707a5b-25c4-4e22-a64e-27b9d7b0fb11_resources/ScoreDataUDFGBM17-1.0-SNAPSHOT.jar] to class path
Added resources: [hdfs:///user/analyticsdb/H2O/UDFtest/GBM17lib/ScoreDataUDFGBM17-1.0-SNAPSHOT.jar]
hive> CREATE TEMPORARY FUNCTION scoredata AS 'ai.h2o.hive.udf.ScoreDataUDFGBM17';
OK
Time taken: 1.557 seconds
hive> USE DEFAULT;
OK
Time taken: 0.041 seconds
hive> SHOW TABLES;
OK
airports
newonehundredcolstables
prostate
test_qa
Time taken: 0.295 seconds, Fetched: 4 row(s)
hive> 
hive> 
    > 
    > SELECT ID,CAPSULE,AGE,RACE,DPROS,DCAPS,PSA,GLEASON,VOL, scoredata(CAPSULE,AGE,RACE,DPROS,DCAPS,PSA,GLEASON) as PRED_VOL FROM prostate LIMIT 5;
Query ID = analyticsdb_20180531155656_7207489e-8600-41cb-84ba-a3e62d8c11e2
Total jobs = 1
Launching Job 1 out of 1
In order to change the average load for a reducer (in bytes):
  set hive.exec.reducers.bytes.per.reducer=<number>
In order to limit the maximum number of reducers:
  set hive.exec.reducers.max=<number>
In order to set a constant number of reducers:
  set mapreduce.job.reduces=<number>
Starting Spark Job = 822605a6-eda5-4dbe-ab3c-0a7d833111f9
2018-05-31 15:56:05,468	Stage-1_0: 1/1 Finished	
Status: Finished successfully in 1.01 seconds
OK
1	0	65	1	2	1	1.4	6	0.0	-3.314099675670086
2	0	72	1	3	2	6.7	7	0.0	0.7430508508514961
3	0	70	1	1	2	4.9	6	0.0	1.6688235471920692
4	0	76	2	2	1	51.2	7	20.0	20.38891199564393
5	0	69	1	1	1	12.3	6	55.9	55.56124922151873
Time taken: 1.202 seconds, Fetched: 5 row(s)
hive>

```


<a name="Limitations"></a>
## Limitations

This solution is fairly quick and easy to implement.  Once you've run through things once, going through steps 1-5 should be pretty painless.  There are, however, a few things to be desired here.

The major trade-off made in this template has been a more generic design over strong input checking.   To be applicable for any POJO, the code only checks that the user-supplied arguments have the correct count and they are all at least primitive types.  Stronger type checking could be done by generating Hive UDF code on a per-model basis.

Also, while the template isn't specific to any given model, it isn't completely flexible to the incoming data either.  If you used 12 of 19 fields as predictors (as in this example), then you must feed the scoredata() UDF only those 12 fields, and in the order that the POJO expects. This is fine for a small number of predictors, but can be messy for larger numbers of predictors.  Ideally, it would be nicer to say `SELECT scoredata(*) FROM prostate ;` and let the UDF pick out the relevant fields by name.  While the H2O POJO does have utility functions for this, Hive, on the other hand, doesn't provide UDF writers the names of the fields (as mentioned in [this](https://issues.apache.org/jira/browse/HIVE-3491) Hive feature request) from which the arguments originate.

Finally, as written, the UDF only returns a single prediction value.  The H2O POJO actually returns an array of float values.  The first value is the main prediction and the remaining values hold probability distributions for classifiers.  This code can easily be expanded to return all values if desired.

## A Look at the UDF Template

The template code starts with some basic annotations that define the nature of the UDF and display some simple help output when the user types `DESCRIBE scoredata` or `DESCRIBE EXTENDED scoredata`.
