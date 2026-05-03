library(tidyverse)

train_df <- read_csv("data/processed/train.csv")
tune_df <- read_csv("data/processed/tune.csv")
test_df <- read_csv("data/processed/test.csv")

predictors <- c("Economic Need Index", "% Poverty", 
                "% English Language Learners", "% Students with Disabilities")

# Train to Test
train_test <- map(predictors, ~ks.test(train_df[[.x]], test_df[[.x]])) |>
  set_names(predictors)

# Train to Tune
train_tune <- map(predictors, ~ks.test(train_df[[.x]], tune_df[[.x]])) |>
  set_names(predictors)

# Tune to Test
tune_test <- map(predictors, ~ks.test(tune_df[[.x]], test_df[[.x]])) |>
  set_names(predictors)

ks_to_df <- function(ks_results) {
  map_dfr(names(ks_results), ~tibble(
    predictor = .x,
    statistic = ks_results[[.x]]$statistic,
    p_value = ks_results[[.x]]$p.value
  ))
}

write_csv(ks_to_df(train_test), "data/diagnostics/ks_train_test.csv")
write_csv(ks_to_df(tune_test), "data/diagnostics/ks_train_tune.csv")
write_csv(ks_to_df(tune_test), "data/diagnostics/ks_tune_test.csv")