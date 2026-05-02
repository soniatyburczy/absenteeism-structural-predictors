library(tidyverse)
library(tidymodels)
library(ranger)
source("scripts/utils.R")

train_df <- read_csv("data/processed/train.csv")
tune_df <- read_csv("data/processed/tune.csv")
test_df <- read_csv("data/processed/test.csv")

folds <- vfold_cv(train_df, v = 5)
rf_recipe <- recipe(`% Chronically Absent` ~ `Economic Need Index` + `% Poverty` + 
`% English Language Learners` + `% Students with Disabilities`, data = train_df)

rf_tune <- rand_forest(mtry = tune(), min_n = tune(), trees = 500) |>
  set_engine("ranger") |>
  set_mode("regression")

rf_grid <- grid_regular(
  mtry(range = c(1, 4)),
  min_n(range = c(2, 20)),
  levels = 5
)

tune_res <- tune_grid(
  rf_tune,
  preprocessor = rf_recipe,
  resamples = folds,
  grid = rf_grid
)