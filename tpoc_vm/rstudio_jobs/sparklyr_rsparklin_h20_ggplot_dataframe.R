# Using H2O
library(sparklyr)
library(rsparkling)
library(h2o)
library(dplyr)

#options(rsparkling.sparklingwater.version = "1.6.8")
#sc <- spark_connect(master = "local", version = "1.6.2")  ##H2O forces to use yarn-client spark2.1.0.cloudera1

options(rsparkling.sparklingwater.version = "2.1.0")
sc <- spark_connect(master = "local", version = "2.1.0")

mtcars_tbl <- copy_to(sc, mtcars, "mtcars")
src_tbls(sc)
# transform our data set, and then partition into 'training', 'test'
#  with h2o.splitFrame() 
#partitions <- h2o.splitFrame(as_h2o_frame(mtcars_tbl), 0.5)
partitions <- mtcars_tbl %>%
  filter(hp >= 100) %>%
  mutate(cyl8 = cyl == 8) %>%
  sdf_partition(training = 0.5, test = 0.5, seed = 1099)

# convert to h20_frame (uses the same underlying rdd)
training <- as_h2o_frame(sc, partitions$training,strict_version_check =FALSE)
test <- as_h2o_frame(sc, partitions$test, strict_version_check = FALSE)

# fit a linear model to the training dataset
glm_model <- h2o.glm(x = c("wt", "cyl"), 
                     y = "mpg", 
                     training_frame = training,
                     lambda_search = TRUE)

# inspect the model
print(glm_model)
summary(glm_model)

# Export Model as a Binary
#h2o.saveModel(glm_model, path = "/home/oracle/h2omodels")

# Export Model as a POJO with H2O
#h2o.download_pojo(glm_model, path = "/home/oracle/h2omodels")

### Predict and plt from model
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

