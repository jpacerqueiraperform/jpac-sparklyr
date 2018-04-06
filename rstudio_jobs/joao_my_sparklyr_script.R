#library(Lahman)
#install.packages("sparklyr")
#spark_install(version = "1.6.0")
#install.packages("nycflights13", lib="1.0")
#install.packages("Lahman")
#install.packages("rsparkling")
#install.packages("DBI", lib="0.6.1")


#detach("package:rsparkling", unload = TRUE)
#if ("package:h2o" %in% search()) { detach("package:h2o", unload = TRUE) }
#if (isNamespaceLoaded("h2o")){ unloadNamespace("h2o") }
#remove.packages("h2o")
#install.packages("/home/oracle/Downloads/h2o-3.10.4.8/R/h2o_3.10.4.8.tar.gz",repos = NULL, type = "source")
#install.packages("h2o", type = "source", repos = "http://h2o-release.s3.amazonaws.com/h2o/rel-ueno/8/R")


# Launch Spark Session
options(rsparkling.sparklingwater.version = "1.6.8")
sc <- spark_connect(master = "yarn-client", version="1.6.2")
library(dplyr)

flights_tbl <- copy_to(sc, nycflights13::flights, "flights")
src_tbls(sc)
flights_tbl %>% filter(dep_delay == 2)

# delay calculations
delay <- flights_tbl %>% 
  group_by(tailnum) %>%
  summarise(count = n(), dist = mean(distance), delay = mean(arr_delay)) %>%
  filter(count > 20, dist < 2000, !is.na(delay)) %>%
  collect

# plot delays
library(ggplot2)
ggplot(delay, aes(dist, delay)) +
  geom_point(aes(size = count), alpha = 1/2) +
  geom_smooth() +
  scale_size_area(max_size = 2)

spark_disconnect(sc)

#src_tbls(sc)
#library(DBI)
#flights_preview <- dbGetQuery(sc, "SELECT * FROM flights LIMIT 10")
#spark_session(sc) %>% invoke("sql", "SELECT * FROM flights LIMIT 10")
#dbGetQuery(sc, "SELECT * FROM flights LIMIT 10")

### SPARK-ML Sample
library(dplyr)
# copy mtcars into spark
mtcars_tbl <- copy_to(sc, mtcars)
src_tbls(sc)
dbGetQuery(sc, "SELECT * FROM mtcars LIMIT 3")

# transform our data set, and then partition into 'training', 'test'
partitions <- mtcars_tbl %>%
  filter(hp >= 100) %>%
  mutate(cyl8 = cyl == 8) %>%
  sdf_partition(training = 0.5, test = 0.5, seed = 1099)

# fit a linear model to the training dataset
fit <- partitions$training %>%
  ml_linear_regression(response = "mpg", features = c("wt", "cyl", "hp"))

# fit summary of model
summary(fit)
# Inspect model
print(fit)



spark_disconnect(sc)

# Using H2O
library(sparklyr)
library(rsparkling)
library(h2o)
library(dplyr)

# Note:  As started, H2O is limited to the CRAN default of 2 CPUs.
#        Shut down and restart H2O as shown below to use all your CPUs.
# Init h20
h2o.init()
h2o.shutdown()
h2o.init(nthreads = 2, strict_version_check = FALSE )
h2o.clusterInfo()

#options(rsparkling.sparklingwater.version = "1.6.8")
#sc <- spark_connect(master = "yarn-client", version = "1.6.8")

h2o.clusterStatus()

options(rsparkling.sparklingwater.version = "2.1.0")
sc <- spark_connect(master = "local", version = "2.1.0")

mtcars_tbl <- copy_to(sc, mtcars, "mtcars")

src_tbls(sc)
dbGetQuery(sc, "SELECT * FROM mtcars LIMIT 3")

# transform our data set, and then partition into 'training', 'test'
#  with h2o.splitFrame() 
#partitions <- h2o.splitFrame(as_h2o_frame(mtcars_tbl), ratio =0.75,seed=1099)  #(as_h2o_frame(mtcars_tbl), 0.5)
partitions <- mtcars_tbl %>%
  filter(hp >= 30 && wt >= 2.200 ) %>%
  mutate(cyl4 = cyl == 4) %>%
  sdf_partition(training = 0.5, test = 0.5, seed = 1099)

# convert to h20_frame (uses the same underlying rdd)
training <- as_h2o_frame(sc, partitions$training,strict_version_check =FALSE)
test <- as_h2o_frame(sc, partitions$test, strict_version_check = TRUE)

# fit a linear model to the training dataset
glm_model <- h2o.glm(x = c("wt", "cyl", "hp"), 
                     y = "mpg", 
                     training_frame = training,
                    lambda_search = FALSE)



# inspect the model
print(glm_model)
summary(glm_model)
h2o.getVersion()


# Export Model as a Binary
h2o.saveModel(glm_model, path = "/home/oracle/h2omodels-glm")
# Export Model as a POJO with H2O
h2o.download_pojo(glm_model, path = "/home/oracle/h2omodels-glm")

# Export Model as a MOJO with H2O
h2o.download_mojo(glm_model, path = "/home/oracle/h2omodels-glm")


## Predict and plt from model
library(ggplot2)

# compute predicted values on our test dataset
pred <- h2o.predict(glm_model, newdata = test)
# convert from H2O Frame to Spark DataFrame
predicted <- as_spark_dataframe(sc, pred, strict_version_check = FALSE)

# extract the true 'mpg' values from our test dataset
actual <- partitions$test %>%
  select(mpg) %>%
  collect() %>%
  `[[`("mpg")

# produce a data.frame housing our predicted + actual 'mpg' values
data <- data.frame(
  predicted = predicted,
  actual    = actual
)
# a bug in data.frame does not set colnames properly; reset here 
names(data) <- c("predicted", "actual")

# plot predicted vs. actual values
ggplot(data, aes(x = actual, y = predicted)) +
  geom_abline(lty = "dashed", col = "red") +
  geom_point() +
  theme(plot.title = element_text(hjust = 0.5)) +
  coord_fixed(ratio = 1) +
  labs(
    x = "Actual Fuel Consumption",
    y = "Predicted Fuel Consumption",
    title = "Predicted vs. Actual Fuel Consumption"
  )

spark_disconnect(sc)



# Using H2O
library(sparklyr)
library(rsparkling)
library(h2o)
library(dplyr)


options(rsparkling.sparklingwater.version = "2.1.0")
sc <- spark_connect(master = "local", version = "2.1.0")

#IRIS Table
iris_tbl <- copy_to(sc, iris, "iris", overwrite = TRUE)
iris_tbl

#Convert to an H2O Frame:
iris_hf <- as_h2o_frame(sc, iris_tbl, strict_version_check = FALSE)

#K-Means Clustering
#Use H2O’s K-means clustering to partition a dataset into groups.
#K-means clustering partitions points into k groups, such that the sum of squares from points to the assigned
# cluster centers is minimized.
kmeans_model <- h2o.kmeans(training_frame = iris_hf, 
                           x = 3:4,
                           k = 3,
                           seed = 1)
# print the cluster centers
h2o.centers(kmeans_model)

# print the centroid statistics
h2o.centroid_stats(kmeans_model)
h2o.saveModel(kmeans_model, path = "/home/oracle/h2omodels-kmeans")
# Export Model as a POJO with H2O
h2o.download_pojo(kmeans_model, path = "/home/oracle/h2omodels-kmeans")
# Export Model as a MOJO with H2O
h2o.download_mojo(kmeans_model, path = "/home/oracle/h2omodels-kmeans")

spark_disconnect(sc)

# DeepLearning
library(dplyr)
h2o.shutdown()
h2o.init(nthreads = 1, strict_version_check = TRUE )
h2o.clusterInfo()

library(rsparkling)
library(sparklyr)
library(h2o)
library(dplyr)

options(rsparkling.sparklingwater.version = "2.1.0")
sc <- spark_connect(master= "local", version = "2.1.0")

mypath <- system.file("extdata", "prostate.csv", package = "h2o")
print(mypath)
## Manual copy of File
hdfs.ls("/user/oracle/")

prostate_df <- spark_read_csv(sc, "prostate","/user/oracle/prostate.csv")
head(prostate_df)

prostate_tbl <- copy_to(sc, prostate_df, "prostate_tbl", overwrite = TRUE)
prostate_tbl
head(prostate_tbl)

#Convert to an H2O Frame:
prostate_hf <- as_h2o_frame(sc, prostate_tbl, strict_version_check = FALSE)
splits <- h2o.splitFrame(prostate_hf, seed = 1099)

y <- "VOL"
#remove response and ID cols
x <- setdiff(names(prostate_hf), c("ID", y))

# Train a Deep Neural Network
dl_fit <- h2o.deeplearning(x = x, y = y,
                           training_frame = splits[[1]],
                           epochs = 15,
                           activation = "Rectifier",
                           hidden = c(10, 5, 10),
                           input_dropout_ratio = 0.7)

h2o.performance(dl_fit, newdata = splits[[2]])


pred_model_dl_fit <- h2o.predict(dl_fit, newdata = prostate_hf)

head(pred_model_dl_fit)
head(prostate_hf)

predicted_model_dl_fit <- as_spark_dataframe(sc, pred_model_dl_fit, strict_version_check = FALSE)

actual_prostate_df <- prostate_df %>%
  select(VOL) %>%
  collect() %>%
  `[[`("VOL")


# produce a data.frame housing our predicted + actual 'VOL' values of prostate_df
data <- data.frame(
  predicted = predicted_model_dl_fit,
  actual    = actual_prostate_df)

# a bug in data.frame does not set colnames properly; reset here 
names(data) <- c("predicted", "actual")

# plot predicted vs. actual values
ggplot(data, aes(x = actual, y = predicted)) +
  geom_abline(lty = "dashed", col = "red") +
  geom_point() +
  theme(plot.title = element_text(hjust = 0.3)) +
  coord_fixed(ratio = 3.0) +
  labs(
    x = "Actual Prostate VOL",
    y = "Predicted PROSTATE VOL",
    title = "DL-FIT Predicted vs. Actual Prostate VOL"
  )


# Cartesian Grid Search
# New Split
splits <- h2o.splitFrame(prostate_hf, seed = 1099)

y <- "VOL"
#remove response and ID cols
x <- setdiff(names(prostate_hf), c("ID", y))

# GBM hyperparamters
gbm_params1 <- list(learn_rate = c(0.01, 0.1),
                    max_depth = c(3, 5, 9),
                    sample_rate = c(0.8, 1.0),
                    col_sample_rate = c(0.2, 0.5, 1.0))

# Train and validate a grid of GBMs
gbm_grid1 <- h2o.grid("gbm", x = x, y = y,
                      grid_id = "gbm_grid1",
                      training_frame = splits[[1]],
                      validation_frame = splits[[1]],
                      ntrees = 100,
                      seed = 1099,
                      hyper_params = gbm_params1)

# Get the grid results, sorted by validation MSE
gbm_gridperf1 <- h2o.getGrid(grid_id = "gbm_grid1", 
                             sort_by = "mse", 
                             decreasing = FALSE)
# Print grid results
print(gbm_gridperf1)


# Random Grid Search
# GBM hyperparamters
gbm_params2 <- list(learn_rate = seq(0.01, 0.1, 0.01),
                    max_depth = seq(2, 10, 1),
                    sample_rate = seq(0.5, 1.0, 0.1),
                    col_sample_rate = seq(0.1, 1.0, 0.1))

search_criteria2 <- list(strategy = "RandomDiscrete", 
                         max_models = 80, max_runtime_secs = 500 )

y <- "VOL"
#remove response and ID cols
x <- setdiff(names(prostate_hf), c("ID", y))

# Train and validate a grid of GBMs
gbm_grid2 <- h2o.grid("gbm", x = x, y = y,
                      grid_id = "gbm_grid2",
                      training_frame = splits[[1]],
                      validation_frame = splits[[2]],
                      ntrees = 100,
                      seed = 1099,
                      hyper_params = gbm_params2,
                      search_criteria = search_criteria2)

print(gbm_grid2)

# Get the grid results, sorted by validation MSE
gbm_gridperf2 <- h2o.getGrid(grid_id = "gbm_grid2", 
                             sort_by = "mse", 
                             decreasing = FALSE)

## Invididual print until max model
gbm_gridperf2@summary_table[1,]
gbm_gridperf2@summary_table[2,]
gbm_gridperf2@summary_table[3,]
gbm_gridperf2@summary_table[240,]

gbm_gridperf2

# best model in grid according to mse
gbm_gridperf2@model_ids[[1]]

gbm_model_gridperf2 <- h2o.getModel(gbm_gridperf2@model_ids[[1]])

pred_model_gridperf <- h2o.predict(gbm_model_gridperf2, newdata = prostate_hf)

head(pred_model_gridperf)
head(prostate_hf)

predicted_model_gridperf <- as_spark_dataframe(sc, pred_model_gridperf, strict_version_check = FALSE)

actual_prostate_df <- prostate_df %>%
  select(VOL) %>%
  collect() %>%
  `[[`("VOL")


# produce a data.frame housing our predicted + actual 'VOL' values of prostate_df
data <- data.frame(
  predicted = predicted_model_gridperf,
  actual    = actual_prostate_df)

# a bug in data.frame does not set colnames properly; reset here 
names(data) <- c("predicted", "actual")

# plot predicted vs. actual values
ggplot(data, aes(x = actual, y = predicted)) +
  geom_abline(lty = "dashed", col = "red") +
  geom_point() +
  theme(plot.title = element_text(hjust = 0.8)) +
  coord_fixed(ratio = 3.5) +
  labs(
    x = "Actual Prostate VOL",
    y = "Predicted PROSTATE VOL",
    title = "GBM-MSE_1 Predicted vs. Actual Prostate VOL" )


# Get the grid results, sorted by validation residual_devianc
gbm_gridperf3 <- h2o.getGrid(grid_id = "gbm_grid2", 
                             sort_by = "residual_deviance", 
                             decreasing = FALSE)

## Invididual print until max model
gbm_gridperf3@summary_table[1,]
gbm_gridperf3@summary_table[2,]
gbm_gridperf3@summary_table[3,]
gbm_gridperf3@summary_table[200,]
## Same order in the GRID
gbm_gridperf3


# Get the grid results, sorted by validation MAE
gbm_gridperf4 <- h2o.getGrid(grid_id = "gbm_grid2", 
                             sort_by = "mae", 
                             decreasing = FALSE)

## Invididual print until max model
gbm_gridperf4@summary_table[1,]
gbm_gridperf4@summary_table[2,]
gbm_gridperf4@summary_table[3,]
gbm_gridperf4@summary_table[80,]
###  metric Mean Absolute Error MAE, probably a good metricfor this model.
gbm_gridperf4

# Pick second best model in grid according to mse
gbm_gridperf4@model_ids[[2]]

gbm_model_gridperf4 <- h2o.getModel(gbm_gridperf4@model_ids[[2]])

pred_model_gridperf4 <- h2o.predict(gbm_model_gridperf4, newdata = prostate_hf)

head(pred_model_gridperf4)
head(prostate_hf)

predicted_model_gridperf4 <- as_spark_dataframe(sc, pred_model_gridperf4, strict_version_check = FALSE)

actual_prostate_df <- prostate_df %>%
  select(VOL) %>%
  collect() %>%
  `[[`("VOL")


# produce a data.frame housing our predicted + actual 'VOL' values of prostate_df
data <- data.frame(
  predicted = predicted_model_gridperf4,
  actual    = actual_prostate_df)

# a bug in data.frame does not set colnames properly; reset here 
names(data) <- c("predicted", "actual")

# plot predicted vs. actual values
ggplot(data, aes(x = actual, y = predicted)) +
  geom_abline(lty = "dashed", col = "red") +
  geom_point() +
  theme(plot.title = element_text(hjust = 0.5)) +
  coord_fixed(ratio = 3.0) +
  labs(
    x = "Actual Prostate VOL",
    y = "Predicted PROSTATE VOL",
    title = "GBM-MAE_1 Predicted vs. Actual Prostate VOL"
  )


# Pick second best model in grid according to mse
gbm_gridperf4@model_ids[[2]]

gbm_model_gridperf4 <- h2o.getModel(gbm_gridperf4@model_ids[[2]])

pred_model_gridperf4 <- h2o.predict(gbm_model_gridperf4, newdata = prostate_hf)

head(pred_model_gridperf4)
head(prostate_hf)

predicted_model_gridperf4 <- as_spark_dataframe(sc, pred_model_gridperf4, strict_version_check = FALSE)

actual_prostate_df <- prostate_df %>%
  select(VOL) %>%
  collect() %>%
  `[[`("VOL")


# produce a data.frame housing our predicted + actual 'VOL' values of prostate_df
data <- data.frame(
  predicted = predicted_model_gridperf4,
  actual    = actual_prostate_df)

# a bug in data.frame does not set colnames properly; reset here 
names(data) <- c("predicted", "actual")

# plot predicted vs. actual values
ggplot(data, aes(x = actual, y = predicted)) +
  geom_abline(lty = "dashed", col = "red") +
  geom_point() +
  theme(plot.title = element_text(hjust = 0.5)) +
  coord_fixed(ratio = 3.0) +
  labs(
    x = "Actual Prostate VOL",
    y = "Predicted PROSTATE VOL",
    title = "GBM-MAE_2 Predicted vs. Actual Prostate VOL"
  )


# Pick 80th best model in grid according to mse
gbm_gridperf4@model_ids[[80]]

gbm_model_gridperf4_80 <- h2o.getModel(gbm_gridperf4@model_ids[[80]])

pred_model_gridperf4_80 <- h2o.predict(gbm_model_gridperf4_80, newdata = prostate_hf)

head(pred_model_gridperf4_80)
head(prostate_hf)

predicted_model_gridperf4_80 <- as_spark_dataframe(sc, pred_model_gridperf4_80, strict_version_check = FALSE)

actual_prostate_df <- prostate_df %>%
  select(VOL) %>%
  collect() %>%
  `[[`("VOL")


# produce a data.frame housing our predicted + actual 'VOL' values of prostate_df
data <- data.frame(
  predicted = predicted_model_gridperf4_80,
  actual    = actual_prostate_df)

# a bug in data.frame does not set colnames properly; reset here 
names(data) <- c("predicted", "actual")

# plot predicted vs. actual values
ggplot(data, aes(x = actual, y = predicted)) +
  geom_abline(lty = "dashed", col = "red") +
  geom_point() +
  theme(plot.title = element_text(hjust = 0.5)) +
  coord_fixed(ratio = 3.0) +
  labs(
    x = "Actual Prostate VOL  ",
    y = "Predicted PROSTATE VOL  ",
    title = "GBM-MAE_80 Predicted vs. Actual Prostate VOL"
  )

spark_disconnect(sc)
