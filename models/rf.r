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

rf_workflow <- workflow() |>
  add_recipe(rf_recipe) |>
  add_model(rf_tune)

tune_res <- tune_grid(
  rf_workflow,
  resamples = folds,
  grid = rf_grid
)

best_params <- select_best(tune_res, metric = "rmse")

write_csv(best_params, "data/model_data/rf/rf_best_params.csv")

collect_metrics(tune_res) |>
  write_csv("data/model_data/rf/rf_tune_metrics.csv")

rf_final <- finalize_workflow(rf_workflow, best_params)
rf_fit <- fit(rf_final, data = train_df)

splits <- list(train = train_df, tune = tune_df, test = test_df)
rf_results <- evaluate_splits(rf_fit, splits, n_predictors = 4, model_name = "rf")
write_csv(rf_results, "data/model_data/rf/rf_results.csv")

ranger_model <- extract_fit_engine(rf_fit)

test_df_complete <- test_df |> drop_na(all_of(predictors))
train_df_complete <- train_df |> drop_na(all_of(predictors))
unified_model <- ranger.unify(ranger_model, data = train_df_complete[predictors])
treeshap_results <- treeshap(unified_model, x = test_df_complete[predictors])

p1 <- plot_feature_importance(treeshap_results)
p2 <- plot_contribution(treeshap_results, obs = 1)
ggsave("plots/rf_plots/shap_importance.png", p1)
ggsave("plots/rf_plots/shap_contribution.png", p2)