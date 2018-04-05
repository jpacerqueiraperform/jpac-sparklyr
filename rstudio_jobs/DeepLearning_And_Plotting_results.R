
# DeepLearning

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
                    col_sample_rate = c(0.1, 0.5, 1.0))

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

# best model in grid according to mse
gbm_gridperf1@model_ids[[1]]

gbm_model_gridperf1 <- h2o.getModel(gbm_gridperf1@model_ids[[1]])

pred_model_gridperf1 <- h2o.predict(gbm_model_gridperf1, newdata = prostate_hf)

head(pred_model_gridperf1)
head(prostate_hf)

predicted_model_gridperf1 <- as_spark_dataframe(sc, pred_model_gridperf1, strict_version_check = FALSE)

actual_prostate_df <- prostate_df %>%
  select(VOL) %>%
  collect() %>%
  `[[`("VOL")


# produce a data.frame housing our predicted + actual 'VOL' values of prostate_df
data <- data.frame(
  predicted = predicted_model_gridperf1,
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
    title = "CGRID-GBM-MSE_1 Predicted vs. Actual Prostate VOL" )


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
    title = "GBM-MSE_2 Predicted vs. Actual Prostate VOL" )


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
    title = "GBM-MAE_2_1 Predicted vs. Actual Prostate VOL"
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
    title = "GBM-MAE_2_2 Predicted vs. Actual Prostate VOL"
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
  coord_fixed(ratio = 2.0) +
  labs(
    x = "Actual Prostate VOL  ",
    y = "Predicted PROSTATE VOL  ",
    title = "GBM-MAE_2_80 Predicted vs. Actual Prostate VOL"
  )

spark_disconnect(sc)

