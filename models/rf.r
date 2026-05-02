library(tidyverse)
library(tidymodels)
library(ranger)
library(treeshap)
source("scripts/utils.R")

train_df <- read_csv("data/processed/train.csv")
tune_df <- read_csv("data/processed/tune.csv")
test_df <- read_csv("data/processed/test.csv")

predictors <- c("Economic Need Index", "% Poverty", 
                "% English Language Learners", "% Students with Disabilities")

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

best_params <- select_best(tune_res, metric = "rmse")
rf_final <- finalize_model(rf_tune, best_params)

rf_fit <- rf_final |>
  set_engine("ranger") |>
  fit(rf_recipe, data = train_df)

splits <- list(train = train_df, tune = tune_df, test = test_df)
rf_results <- evaluate_splits(rf_fit, splits, n_predictors = 4, model_name = "rf")
write_csv(rf_results, "data/model_data/rf_results.csv")

ranger_model <- extract_fit_engine(rf_fit)
unified_model <- ranger.unify(ranger_model, data = train_df[predictors])
treeshap_results <- treeshap(unified_model, x = test_df[predictors])

plot_feature_importance(treeshap_results)
plot_contribution(treeshap_results, obs = 1)