library(tidyverse)
library(tidymodels)
library(ranger)
library(treeshap)
source("scripts/utils.R")

train_df <- read_csv("data/processed/train.csv")
tune_df <- read_csv("data/processed/tune.csv")
test_df <- read_csv("data/processed/test.csv")

predictors <- c("Economic Need Index", "% Poverty", "% English Language Learners", "% Students with Disabilities")

train_df <- train_df %>%
  mutate(
    `Economic Need Index` = if_else(is.na(`Economic Need Index`), NA_real_, pmin(`Economic Need Index`, 0.95)),
    `% Poverty` = if_else(is.na(`% Poverty`), NA_real_, pmin(`% Poverty`, 0.95))
  )

tune_df <- tune_df %>%
  mutate(
    `Economic Need Index` = if_else(is.na(`Economic Need Index`), NA_real_, pmin(`Economic Need Index`, 0.95)),
    `% Poverty` = if_else(is.na(`% Poverty`), NA_real_, pmin(`% Poverty`, 0.95))
  )

folds <- vfold_cv(train_df, v = 5)

rf_recipe <- recipe(`% Chronically Absent` ~ `Economic Need Index` + `% Poverty` + `% English Language Learners` + `% Students with Disabilities`, data = train_df)

rf_tune <- rand_forest(mtry = tune(), min_n = tune(), trees = 500) |> 
  set_engine("ranger") |> 
  set_mode("regression")

rf_grid <- grid_regular(
  mtry(range = c(1, 4)),
  min_n(range = c(2, 20)),
  levels = 5
)

rf_workflow <- workflow() |> 
  add_recipe(rf_recipe) |> 
  add_model(rf_tune)

tune_res <- tune_grid(
  rf_workflow,
  resamples = folds,
  grid = rf_grid
)

best_params <- select_best(tune_res, metric = "rmse")
write_csv(best_params, "data/model_data/rf/rf_clipped_best_params.csv")

rf_final <- finalize_workflow(rf_workflow, best_params)
rf_fit <- fit(rf_final, data = train_df)

splits <- list(train = train_df, tune = tune_df, test = test_df)
rf_results <- evaluate_splits(rf_fit, splits, n_predictors = 4, model_name = "rf_clipped")
write_csv(rf_results, "data/model_data/rf/rf_clipped_results.csv")

ranger_model <- extract_fit_engine(rf_fit)
test_df_complete <- test_df |> drop_na(all_of(predictors))

unified_model <- ranger.unify(ranger_model, data = train_df[predictors] |> drop_na())
treeshap_results <- treeshap(unified_model, x = test_df_complete[predictors])

p1 <- plot_feature_importance(treeshap_results)
ggsave("plots/rf_plots/shap_importance_clipped.png", p1)
