source("scripts/utils.R")
library(tidyverse)

train_df <- read_csv("data/processed/train.csv")
tune_df <- read_csv("data/processed/tune.csv")
test_df <- read_csv("data/processed/test.csv")
splits <- list(train = train_df, tune = tune_df, test = test_df)
results <- list()

for (j in 1:10){
  mod <- lm(`% Chronically Absent` ~ poly(`Economic Need Index`, j, raw=TRUE) + 
  `% Poverty` + `% English Language Learners` + 
  `% Students with Disabilities`, data = train_df)
  
  results[[j]] <- evaluate_splits(mod, splits, n_predictors = j + 3, model_name = paste0("poly_", j))
}

poly_results <- dplyr::bind_rows(results)
write_csv(poly_results, "data/model_data/poly/poly_results.csv")

# Best degree (based on tune)
best_degree <- poly_results |>
  filter(split == "tune") |>
  slice_min(rmse, n = 1) |>
  pull(model) |>
  str_remove("poly_") |>
  as.integer()

best_test_result <- poly_results |>
  filter(split == "test", model == paste0("poly_", best_degree))

write_csv(best_test_result, "data/model_data/poly/poly_best_degree.csv")