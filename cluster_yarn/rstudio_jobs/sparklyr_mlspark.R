# Launch Spark Session
sc <- spark_connect(master = "yarn-client", version="1.6.0")
library(dplyr)
iris_tbl <- copy_to(sc, iris)
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

#src_tbls(sc)
#library(DBI)
#flights_preview <- dbGetQuery(sc, "SELECT * FROM flights LIMIT 10")
#spark_session(sc) %>% invoke("sql", "SELECT * FROM flights LIMIT 10")
#dbGetQuery(sc, "SELECT * FROM flights LIMIT 10"

### SPARK-ML Sample
library(dplyr)
# copy mtcars into spark
mtcars_tbl <- copy_to(sc, mtcars)
src_tbls(sc)

# transform our data set, and then partition into 'training', 'test'
partitions <- mtcars_tbl %>%
  filter(hp >= 100) %>%
  mutate(cyl8 = cyl == 8) %>%
  sdf_partition(training = 0.5, test = 0.5, seed = 1099)

# fit a linear model to the training dataset
fit <- partitions$training %>%
  ml_linear_regression(response = "mpg", features = c("wt", "cyl"))

# fit summary of model
summary(fit)
# Inspect model
print(fit)

spark_disconnect(sc)

# Using H2O
library(rsparkling)
library(h2o)
library(dplyr)
options(rsparkling.sparklingwater.version = "1.6.8")

sc <- spark_connect(master = "yarn-client", version = "1.6.0")
mtcars_tbl <- copy_to(sc, mtcars, "mtcars")

# transform our data set, and then partition into 'training', 'test'
partitions <- mtcars_tbl %>%
  filter(hp >= 100) %>%
  mutate(cyl8 = cyl == 8) %>%
  sdf_partition(training = 0.5, test = 0.5, seed = 1099)
# convert to h20_frame (uses the same underlying rdd)
training <- as_h2o_frame(sc, partitions$training, strict_version_check = FALSE)
test <- as_h2o_frame(sc, partitions$test, strict_version_check = FALSE)

# fit a linear model to the training dataset
fit <- h2o.glm(x = c("wt", "cyl"),
               y = "mpg",
               training_frame = training,
               lamda_search = TRUE)

# inspect the model
print(fit)

#spark_disconnect(sc)
