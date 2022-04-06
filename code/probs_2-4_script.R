library(tidyverse)
library(rpart)
library(rpart.plot)
library(rsample) 
library(modelr)
library(randomForest)
library(gbm)
library(ggmap)


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

### Prob 3 ###

grn_build <- read.csv("https://raw.githubusercontent.com/taylorneal/homework-3/master/data/greenbuildings.csv", 
                      header = TRUE)

grn_build = grn_build %>% 
  mutate(class = 'C', net_gas_cost = net * Gas_Costs,
         net_elec_cost = net * Electricity_Costs, 
         rev_per_sqft = Rent * leasing_rate / 100)

grn_build[grn_build$class_a == 1, 'class'] = 'A'
grn_build[grn_build$class_b == 1, 'class'] = 'B'
grn_build$class = factor(grn_build$class, levels = c('A', 'B', 'C'))
#grn_build$cluster = factor(grn_build$cluster)

#grn_build[rowSums(is.na(grn_build)) > 0, ]
grn_build = grn_build[!is.na(grn_build$empl_gr),]
grn_build = grn_build[!is.na(grn_build$rev_per_sqft),]
grn_build = grn_build[grn_build$rev_per_sqft != 0,]

grn_build = subset(grn_build, select = c(-1, -2, -5, -6, -10, -11, -12, -13, -15, -19, -21, -22)) # cluster is 2



cv_rmse3 = 1:10
cv_rmse4 = 1:10
cv_rmse5 = 1:10
cv_rmse4s = 1:10

for (k in 1:10)
{
  grn_split = initial_split(grn_build, prop = 0.8)
  grn_train = training(grn_split)
  grn_test = testing(grn_split)
  
  grn.forest = randomForest(rev_per_sqft ~ size + empl_gr + stories + age + renovated + 
                              green_rating + amenities + cd_total_07 + hd_total07 + 
                              Precipitation + City_Market_Rent + class + net_gas_cost + 
                              net_elec_cost, data = grn_train, mtry = 4, ntree = 500,
                            importance = TRUE)
  
  cv_rmse4s[k] = modelr::rmse(grn.forest, grn_test)
}

mean(cv_rmse3)
sd(cv_rmse3)
mean(cv_rmse4)
sd(cv_rmse4)
mean(cv_rmse5)
sd(cv_rmse5)
mean(cv_rmse4s)
sd(cv_rmse4s)

##### real stuff
grn_split = initial_split(grn_build, prop = 0.8)
grn_train = training(grn_split)
grn_test = testing(grn_split)

grn.forest = randomForest(rev_per_sqft ~ size + empl_gr + stories + age + renovated + 
                            green_rating + amenities + cd_total_07 + hd_total07 + 
                            Precipitation + City_Market_Rent + class + net_gas_cost + 
                            net_elec_cost, data = grn_train, mtry = 4, ntree = 500,
                         importance = TRUE)

plot(grn.forest)

varImpPlot(grn.forest)

partialPlot(grn.forest, grn_test, 'green_rating', las = 1)
partialPlot(grn.forest, grn_test, 'amenities', las = 1)

partialPlot(grn.forest, grn_test, 'size', las = 1)
partialPlot(grn.forest, grn_test, 'stories', las = 1)

yhat_test = predict(grn.forest, grn_test)
plot(yhat_test, grn.forest$rev_per_sqft)


modelr::rmse(grn.forest, grn_test)
