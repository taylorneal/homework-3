library(tidyverse)
library(rpart)
library(rpart.plot)
library(rsample) 
library(modelr)
library(randomForest)
library(gbm)


### Prob 2 ###
dengue <- read.csv("https://raw.githubusercontent.com/taylorneal/homework-3/master/data/dengue.csv", header = TRUE)

dengue$city = as.factor(dengue$city)
dengue$season = as.factor(dengue$season)
dengue$total_cases = as.numeric(dengue$total_cases)
dengue <- dengue[!is.na(dengue$tdtr_k),]
dengue <- subset(dengue, select = c(-4, -5, -6, -7))

set.seed(9)

dengue_split = initial_split(dengue, prop = 0.8)
dengue_train = training(dengue_split)
dengue_test = testing(dengue_split)

#cp_1se = function(my_tree) {
#  out = as.data.frame(my_tree$cptable)
#  thresh = min(out$xerror + out$xstd)
#  cp_opt = max(out$CP[out$xerror <= thresh])
#  cp_opt
#}

prune_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  prune(my_tree, cp = cp_opt)
}

load.tree = rpart(total_cases ~ city + season + tdtr_k + specific_humidity + precipitation_amt + max_air_temp_k, 
                  data = dengue_train, control = rpart.control(cp = 0.0001, minsplit = 5))

#plotcp(load.tree)
# rpart.plot(load.tree, digits = -5, type = 4, extra = 1)

#cp_1se(load.tree)
load.tree_pruned = prune_1se(load.tree)
rpart.plot(load.tree_pruned, digits = -5, type = 4, extra = 1)



#### Forest
load.forest = randomForest(total_cases ~ city + season + tdtr_k + specific_humidity + precipitation_amt + max_air_temp_k,
                           data = dengue_train, importance = TRUE, na.action = na.roughfix)

#plot(load.forest)

#modelr::rmse(load.tree_pruned, dengue_test)
#modelr::rmse(load.forest, dengue_test)


#### Boosting

boost = gbm(total_cases ~ city + season + tdtr_k + specific_humidity + precipitation_amt + max_air_temp_k, 
             data = dengue_train,
             interaction.depth = 4, n.trees = 500, shrinkage = .03)

#gbm.perf(boost)

modelr::rmse(load.tree_pruned, dengue_test)
modelr::rmse(load.forest, dengue_test)
modelr::rmse(boost, dengue_test)

partialPlot(load.forest, dengue_test, 'specific_humidity', las = 1)
partialPlot(load.forest, dengue_test, 'precipitation_amt', las = 1)
partialPlot(load.forest, dengue_test, 'max_air_temp_k', las = 1)

#plot(boost, 'specific_humidity')
#plot(boost, 'precipitation_amt')
#plot(boost, 'max_air_temp_k')


### Prob 4 ###
CA_housing <- read.csv("https://raw.githubusercontent.com/taylorneal/homework-3/master/data/CAhousing.csv", header = TRUE)

CA_housing = CA_housing %>% 
  mutate(group = 1, rooms_per_household = totalRooms / households,
         bedrooms_per_household = totalBedrooms / households, 
         avg_household = population / households)

#library(maps)
library(ggmap)
#library(sf)

states = map_data("state")
counties = map_data("county")
ca_map = subset(states, region == "california")
ca_counties = subset(counties, region == "california")

ca_base = ggplot(data = ca_map, mapping = aes(x = long, y = lat, group = group)) + 
  coord_fixed(1.3) + geom_polygon(color = "black", fill = "gray") + 
  theme_nothing() + 
  geom_polygon(data = ca_counties, fill = NA, color = "white") +
  geom_polygon(color = "black", fill = NA)

ca_base + geom_point(data = CA_housing, size = .75, mapping = 
                       aes(x = longitude, y = latitude, color = medianHouseValue)) + 
  scale_color_gradient(low = "cyan", high = "dark blue", labels = scales::label_comma()) + 
  theme(legend.position = "right", legend.title = element_text(), legend.text = element_text(size = 8))


#CA_as_sf <- st_as_sf(CA_housing, coords = c('longitude', 'latitude'))
#dist_matrix   <- st_distance(CA_as_sf, CA_as_sf)
#diag(dist_matrix) <- NA


CA_split = initial_split(CA_housing, prop = 0.8)
CA_train = training(CA_split)
CA_test = testing(CA_split)

lm_start = lm(medianHouseValue ~ housingMedianAge + medianIncome
              + rooms_per_household + bedrooms_per_household
              + avg_household + population, data = CA_train)

lm_step = step(lm_start, scope = ~(.)^2, trace = 0)

modelr::rmse(lm_step, CA_test)

ca.forest = randomForest(medianHouseValue ~ housingMedianAge + medianIncome
                         + rooms_per_household + bedrooms_per_household
                         + avg_household + population, mtry = 3, ntree = 200,
                           data = CA_train, importance = TRUE)

plot(ca.forest)
round(modelr::rmse(ca.forest, CA_test),2)

CA_housing$PredictedMedianValue = predict(ca.forest, CA_housing)

CA_housing = CA_housing %>% mutate(Residuals = medianHouseValue - PredictedMedianValue)

ca_base + geom_point(data = CA_housing, size = .75, mapping = 
                       aes(x = longitude, y = latitude, color = PredictedMedianValue)) + 
  scale_color_gradient(low = "cyan", high = "dark blue", labels = scales::label_comma()) + 
  theme(legend.position = "right", legend.title = element_text(), legend.text = element_text(size = 8))

ca_base + geom_point(data = CA_housing, size = 1, mapping = 
                       aes(x = longitude, y = latitude, color = Residuals)) + 
  scale_color_gradient2(low = "red", mid = "grey", high = "dark blue", labels = scales::label_comma()) + 
  theme(legend.position = "right", legend.title = element_text(), legend.text = element_text(size = 8))