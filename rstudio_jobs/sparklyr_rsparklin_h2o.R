# Using H2O
library(sparklyr)
library(rsparkling)
library(h2o)
library(dplyr)
options(rsparkling.sparklingwater.version = "1.6.8")

sc <- spark_connect(master = "local", version = "1.6.2")
mtcars_tbl <- copy_to(sc, mtcars, "mtcars")

# transform our data set, and then partition into 'training', 'test' with h2o.split
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
h2o.saveModel(glm_model, path = "/home/oracle/h2omodels-glm")

# Export Model as a POJO with H2O
h2o.download_pojo(glm_model, path = "/home/oracle/h2omodels-glm")

# Export Model as a MOJO with H2O
h2o.download_mojo(glm_model, path = "/home/oracle/h2omodels-glm")

spark_disconnect(sc)

