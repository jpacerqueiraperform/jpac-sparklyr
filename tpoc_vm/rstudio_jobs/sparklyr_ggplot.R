# Launch Spark Session
sc <- spark_connect(master = "yarn-client", version="1.6.0")
library(dplyr)
iris_tbl <- copy_to(sc, iris)
flights_tbl <- copy_to(sc, nycflights13::flights, "flights")
src_tbls(sc)
flights_tbl %>% filter(dep_delay == 2)

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
#dbGetQuery(sc, "SELECT * FROM flights LIMIT 10")

#spark_disconnect(sc)
