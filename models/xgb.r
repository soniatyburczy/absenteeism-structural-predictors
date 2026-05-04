library(tidyverse)
library(tidymodels)
library(treeshap)
library(xgboost)
source("scripts/utils.R")

train_df <- read_csv("data/processed/train.csv")
tune_df <- read_csv("data/processed/tune.csv")
test_df <- read_csv("data/processed/test.csv")
test2_df <- read_csv("data/processed/2018_2019.csv")

predictors <- c("Economic Need Index", "% Poverty", 
                "% English Language Learners", "% Students with Disabilities")

folds <- vfold_cv(train_df, v = 5)

xgb_recipe <- recipe(`% Chronically Absent` ~ `Economic Need Index` + `% Poverty` + 
                      `% English Language Learners` + `% Students with Disabilities`, 
                      data = train_df)

xgb_tune <- boost_tree(
  trees = tune(),
  tree_depth = tune(),
  learn_rate = tune()
) |>
  set_engine("xgboost") |> 
  set_mode("regression")

xgb_grid <- grid_regular(
  trees(range = c(100, 1000)),
  tree_depth(range = c(3, 8)),
  learn_rate(range = c(-3, -1), trans = log10_trans()),
  levels = 4
)

xgb_workflow <- workflow() |>
  add_recipe(xgb_recipe) |>
  add_model(xgb_tune)

tune_res <- tune_grid(
  xgb_workflow,
  resamples = folds,
  grid = xgb_grid
)

best_params <- select_best(tune_res, metric = "rmse")

write_csv(best_params, "data/model_data/xgb/xgb_best_params.csv")

collect_metrics(tune_res) |>
  write_csv("data/model_data/xgb/xgb_tune_metrics.csv")

xgb_final <- finalize_workflow(xgb_workflow, best_params)
xgb_fit <- fit(xgb_final, data = train_df)

splits <- list(train = train_df, tune = tune_df, test = test_df, test2 = test2_df)
xgb_results <- evaluate_splits(xgb_fit, splits, n_predictors = 4, model_name = "xgb")
write_csv(xgb_results, "data/model_data/xgb/xgb_results.csv")

xgb_model <- extract_fit_engine(xgb_fit)
unified_model <- xgboost.unify(xgb_model, data = test_df[predictors])
treeshap_results <- treeshap(unified_model, x = test_df[predictors])

p1 <- plot_feature_importance(treeshap_results)
p2 <- plot_contribution(treeshap_results, obs = 1)

ggsave("plots/xgb_plots/shap_importance.png", p1)
ggsave("plots/xgb_plots/shap_contribution.png", p2)