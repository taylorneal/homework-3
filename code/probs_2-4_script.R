library(tidyverse)
library(rpart)
library(rpart.plot)
library(rsample) 
library(modelr)
library(randomForest)
library(gbm)

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



### Forest
load.forest = randomForest(total_cases ~ city + season + tdtr_k + specific_humidity + precipitation_amt + max_air_temp_k,
                           data = dengue_train, importance = TRUE, na.action = na.roughfix)

#plot(load.forest)

#modelr::rmse(load.tree_pruned, dengue_test)
#modelr::rmse(load.forest, dengue_test)


### Boosting

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
